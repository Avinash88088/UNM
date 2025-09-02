const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const { getPool } = require('../database/connection');
const { getRedisClient } = require('../database/redis');
const { AppError, asyncHandler } = require('./errorHandler');
const logger = require('../utils/logger');

// Verify JWT token
const authenticateToken = asyncHandler(async (req, res, next) => {
    try {
        const authHeader = req.headers.authorization;
        const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

        if (!token) {
            throw new AppError('Access token required', 401);
        }

        // Verify token
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        
        // Check if token is blacklisted (logout)
        const redisClient = getRedisClient();
        if (redisClient) {
            const isBlacklisted = await redisClient.get(`blacklist:${token}`);
            if (isBlacklisted) {
                throw new AppError('Token has been revoked', 401);
            }
        }

        // Get user from database
        const pool = getPool();
        const userResult = await pool.query(
            'SELECT id, email, first_name, last_name, role, is_active, institution_id FROM users WHERE id = $1',
            [decoded.userId]
        );

        if (userResult.rows.length === 0) {
            throw new AppError('User not found', 401);
        }

        const user = userResult.rows[0];

        if (!user.is_active) {
            throw new AppError('User account is deactivated', 401);
        }

        // Add user to request object
        req.user = {
            id: user.id,
            email: user.email,
            firstName: user.first_name,
            lastName: user.last_name,
            role: user.role,
            institutionId: user.institution_id
        };

        next();
    } catch (error) {
        if (error.name === 'JsonWebTokenError') {
            next(new AppError('Invalid token', 401));
        } else if (error.name === 'TokenExpiredError') {
            next(new AppError('Token expired', 401));
        } else {
            next(error);
        }
    }
});

// Verify refresh token
const authenticateRefreshToken = asyncHandler(async (req, res, next) => {
    try {
        const { refreshToken } = req.body;

        if (!refreshToken) {
            throw new AppError('Refresh token required', 400);
        }

        // Verify refresh token
        const decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);
        
        // Check if refresh token exists in database
        const pool = getPool();
        const sessionResult = await pool.query(
            'SELECT us.*, u.is_active FROM user_sessions us JOIN users u ON us.user_id = u.id WHERE us.refresh_token_hash = $1 AND us.expires_at > NOW()',
            [refreshToken]
        );

        if (sessionResult.rows.length === 0) {
            throw new AppError('Invalid refresh token', 401);
        }

        const session = sessionResult.rows[0];

        if (!session.is_active) {
            throw new AppError('User account is deactivated', 401);
        }

        // Add user info to request
        req.user = {
            id: session.user_id,
            sessionId: session.id
        };

        next();
    } catch (error) {
        if (error.name === 'JsonWebTokenError') {
            next(new AppError('Invalid refresh token', 401));
        } else if (error.name === 'TokenExpiredError') {
            next(new AppError('Refresh token expired', 401));
        } else {
            next(error);
        }
    }
});

// Role-based access control
const authorize = (...roles) => {
    return (req, res, next) => {
        if (!req.user) {
            return next(new AppError('Authentication required', 401));
        }

        if (!roles.includes(req.user.role)) {
            logger.security(`Unauthorized access attempt by user ${req.user.id} with role ${req.user.role}`, {
                userId: req.user.id,
                userRole: req.user.role,
                requiredRoles: roles,
                endpoint: req.originalUrl
            });
            return next(new AppError('Insufficient permissions', 403));
        }

        next();
    };
};

// Permission-based access control
const checkPermission = (requiredPermission) => {
    return (req, res, next) => {
        if (!req.user) {
            return next(new AppError('Authentication required', 401));
        }

        // Get user permissions based on role
        const userPermissions = getUserPermissions(req.user.role);
        
        if (!userPermissions.includes(requiredPermission)) {
            logger.security(`Permission denied for user ${req.user.id}`, {
                userId: req.user.id,
                userRole: req.user.role,
                requiredPermission,
                endpoint: req.originalUrl
            });
            return next(new AppError('Insufficient permissions', 403));
        }

        next();
    };
};

// Get user permissions based on role
const getUserPermissions = (role) => {
    const permissions = {
        student: [
            'document:read:own',
            'document:upload:own',
            'question:read:public',
            'question:answer:own'
        ],
        teacher: [
            'document:read:own',
            'document:upload:own',
            'document:share:own',
            'question:read:own',
            'question:create:own',
            'question:edit:own',
            'question:delete:own',
            'batch:create:own',
            'batch:read:own'
        ],
        admin: [
            'document:read:all',
            'document:upload:own',
            'document:share:own',
            'question:read:all',
            'question:create:own',
            'question:edit:own',
            'question:delete:own',
            'batch:create:own',
            'batch:read:all',
            'user:read:institution',
            'user:create:institution',
            'user:edit:institution',
            'user:deactivate:institution'
        ],
        super_admin: [
            'document:read:all',
            'document:upload:own',
            'document:share:own',
            'question:read:all',
            'question:create:own',
            'question:edit:own',
            'question:delete:own',
            'batch:create:own',
            'batch:read:all',
            'user:read:all',
            'user:create:all',
            'user:edit:all',
            'user:delete:all',
            'institution:create:all',
            'institution:edit:all',
            'institution:delete:all',
            'system:admin:all'
        ]
    };

    return permissions[role] || [];
};

// Check if user owns the resource
const checkOwnership = (resourceType) => {
    return asyncHandler(async (req, res, next) => {
        if (!req.user) {
            return next(new AppError('Authentication required', 401));
        }

        const resourceId = req.params.id || req.params.documentId || req.params.questionSetId;
        
        if (!resourceId) {
            return next(new AppError('Resource ID required', 400));
        }

        const pool = getPool();
        let ownershipQuery;
        let queryParams;

        switch (resourceType) {
            case 'document':
                ownershipQuery = 'SELECT user_id FROM documents WHERE id = $1';
                queryParams = [resourceId];
                break;
            case 'questionSet':
                ownershipQuery = 'SELECT created_by FROM question_sets WHERE id = $1';
                queryParams = [resourceId];
                break;
            case 'question':
                ownershipQuery = `
                    SELECT qs.created_by 
                    FROM questions q 
                    JOIN question_sets qs ON q.question_set_id = qs.id 
                    WHERE q.id = $1
                `;
                queryParams = [resourceId];
                break;
            case 'batch':
                ownershipQuery = 'SELECT created_by FROM batch_jobs WHERE id = $1';
                queryParams = [resourceId];
                break;
            default:
                return next(new AppError('Invalid resource type', 400));
        }

        const result = await pool.query(ownershipQuery, queryParams);

        if (result.rows.length === 0) {
            return next(new AppError('Resource not found', 404));
        }

        const resource = result.rows[0];
        const ownerId = resource.user_id || resource.created_by;

        // Allow access if user owns the resource or is admin/super_admin
        if (ownerId === req.user.id || ['admin', 'super_admin'].includes(req.user.role)) {
            next();
        } else {
            logger.security(`Ownership check failed for user ${req.user.id}`, {
                userId: req.user.id,
                userRole: req.user.role,
                resourceType,
                resourceId,
                ownerId
            });
            return next(new AppError('Access denied', 403));
        }
    });
};

// Rate limiting for authentication endpoints
const authRateLimit = {
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 5, // limit each IP to 5 requests per windowMs
    message: {
        error: 'Too many authentication attempts, please try again later.'
    },
    standardHeaders: true,
    legacyHeaders: false,
};

// Generate JWT tokens
const generateTokens = (userId) => {
    const accessToken = jwt.sign(
        { userId },
        process.env.JWT_SECRET,
        { expiresIn: process.env.JWT_EXPIRES_IN || '15m' }
    );

    const refreshToken = jwt.sign(
        { userId },
        process.env.JWT_REFRESH_SECRET,
        { expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d' }
    );

    return { accessToken, refreshToken };
};

// Hash password
const hashPassword = async (password) => {
    const saltRounds = parseInt(process.env.BCRYPT_SALT_ROUNDS) || 12;
    return await bcrypt.hash(password, saltRounds);
};

// Compare password
const comparePassword = async (password, hash) => {
    return await bcrypt.compare(password, hash);
};

// Logout (blacklist token)
const logout = asyncHandler(async (req, res) => {
    const token = req.headers.authorization?.split(' ')[1];
    
    if (token) {
        const redisClient = getRedisClient();
        if (redisClient) {
            // Blacklist the access token
            const decoded = jwt.decode(token);
            const expiresIn = decoded.exp - Math.floor(Date.now() / 1000);
            
            if (expiresIn > 0) {
                await redisClient.setEx(`blacklist:${token}`, expiresIn, 'true');
            }
        }
    }

    // Remove refresh token from database
    if (req.user?.sessionId) {
        const pool = getPool();
        await pool.query(
            'DELETE FROM user_sessions WHERE id = $1',
            [req.user.sessionId]
        );
    }

    res.json({
        success: true,
        message: 'Logged out successfully'
    });
});

module.exports = {
    authenticateToken,
    authenticateRefreshToken,
    authorize,
    checkPermission,
    checkOwnership,
    generateTokens,
    hashPassword,
    comparePassword,
    logout,
    authRateLimit
};
