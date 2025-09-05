const jwt = require('jsonwebtoken');
const { AppError, asyncHandler } = require('./errorHandler');

// Verify JWT token (simplified version)
const authenticateToken = asyncHandler(async (req, res, next) => {
    try {
        const authHeader = req.headers.authorization;
        const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

        if (!token) {
            throw new AppError('Access token required', 401);
        }

        // Verify token
        const decoded = jwt.verify(token, process.env.JWT_SECRET || 'fallback-secret');
        
        // Add user to request object (simplified)
        req.user = {
            userId: decoded.userId,
            email: decoded.email,
            role: decoded.role
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

// Verify refresh token (simplified version)
const authenticateRefreshToken = asyncHandler(async (req, res, next) => {
    try {
        const { refreshToken } = req.body;

        if (!refreshToken) {
            throw new AppError('Refresh token required', 400);
        }

        // Verify refresh token
        const decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET || 'fallback-refresh-secret');
        
        // Add user info to request (simplified)
        req.user = {
            userId: decoded.userId
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

// Check if user has required role
const requireRole = (requiredRole) => {
    return (req, res, next) => {
        if (!req.user) {
            return next(new AppError('Authentication required', 401));
        }

        if (req.user.role !== requiredRole) {
            return next(new AppError('Insufficient permissions', 403));
        }

        next();
    };
};

// Check if user has any of the required roles
const requireAnyRole = (requiredRoles) => {
    return (req, res, next) => {
        if (!req.user) {
            return next(new AppError('Authentication required', 401));
        }

        if (!requiredRoles.includes(req.user.role)) {
            return next(new AppError('Insufficient permissions', 403));
        }

        next();
    };
};

// Check if user is authenticated (no specific role required)
const isAuthenticated = (req, res, next) => {
    if (!req.user) {
        return next(new AppError('Authentication required', 401));
    }
    next();
};

module.exports = {
    authenticateToken,
    authenticateRefreshToken,
    requireRole,
    requireAnyRole,
    isAuthenticated,
    // Alias for backward compatibility
    auth: authenticateToken
};

