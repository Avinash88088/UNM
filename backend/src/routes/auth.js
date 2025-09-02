const express = require('express');
const rateLimit = require('express-rate-limit');
const { body, validationResult } = require('express-validator');
const { getPool } = require('../database/connection');
const { getRedisClient } = require('../database/redis');
const { 
    authenticateToken, 
    authenticateRefreshToken, 
    generateTokens, 
    hashPassword, 
    comparePassword,
    authRateLimit 
} = require('../middleware/auth');
const { AppError, asyncHandler } = require('../middleware/errorHandler');
const logger = require('../utils/logger');

const router = express.Router();

// Apply rate limiting to all auth routes
router.use(rateLimit(authRateLimit));

/**
 * @swagger
 * /auth/register:
 *   post:
 *     summary: Register a new user
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *               - password
 *               - firstName
 *               - lastName
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *               password:
 *                 type: string
 *                 minLength: 8
 *               firstName:
 *                 type: string
 *               lastName:
 *                 type: string
 *               phone:
 *                 type: string
 *               role:
 *                 type: string
 *                 enum: [student, teacher]
 *                 default: student
 *               institutionId:
 *                 type: string
 *                 format: uuid
 *     responses:
 *       201:
 *         description: User registered successfully
 *       400:
 *         description: Validation error
 *       409:
 *         description: User already exists
 */
router.post('/register', [
    body('email').isEmail().normalizeEmail(),
    body('password').isLength({ min: 8 }).withMessage('Password must be at least 8 characters long'),
    body('firstName').trim().isLength({ min: 2, max: 100 }),
    body('lastName').trim().isLength({ min: 2, max: 100 }),
    body('phone').optional().isMobilePhone(),
    body('role').optional().isIn(['student', 'teacher']),
    body('institutionId').optional().isUUID()
], asyncHandler(async (req, res) => {
    // Check validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        throw new AppError(`Validation failed: ${errors.array().map(e => e.msg).join(', ')}`, 400);
    }

    const { email, password, firstName, lastName, phone, role = 'student', institutionId } = req.body;

    const pool = getPool();

    // Check if user already exists
    const existingUser = await pool.query(
        'SELECT id FROM users WHERE email = $1',
        [email]
    );

    if (existingUser.rows.length > 0) {
        throw new AppError('User with this email already exists', 409);
    }

    // Check if phone is already taken
    if (phone) {
        const existingPhone = await pool.query(
            'SELECT id FROM users WHERE phone = $1',
            [phone]
        );

        if (existingPhone.rows.length > 0) {
            throw new AppError('User with this phone number already exists', 409);
        }
    }

    // Hash password
    const passwordHash = await hashPassword(password);

    // Create user
    const result = await pool.query(
        `INSERT INTO users (email, password_hash, first_name, last_name, phone, role, institution_id)
         VALUES ($1, $2, $3, $4, $5, $6, $7)
         RETURNING id, email, first_name, last_name, role, institution_id, created_at`,
        [email, passwordHash, firstName, lastName, phone, role, institutionId]
    );

    const user = result.rows[0];

    logger.api(`New user registered: ${email}`, {
        userId: user.id,
        role: user.role,
        institutionId: user.institution_id
    });

    res.status(201).json({
        success: true,
        message: 'User registered successfully',
        data: {
            user: {
                id: user.id,
                email: user.email,
                firstName: user.first_name,
                lastName: user.last_name,
                role: user.role,
                institutionId: user.institution_id,
                createdAt: user.created_at
            }
        }
    });
}));

/**
 * @swagger
 * /auth/login:
 *   post:
 *     summary: Login user
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *               - password
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *               password:
 *                 type: string
 *     responses:
 *       200:
 *         description: Login successful
 *       401:
 *         description: Invalid credentials
 */
router.post('/login', [
    body('email').isEmail().normalizeEmail(),
    body('password').notEmpty()
], asyncHandler(async (req, res) => {
    // Check validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        throw new AppError(`Validation failed: ${errors.array().map(e => e.msg).join(', ')}`, 400);
    }

    const { email, password } = req.body;

    const pool = getPool();

    // Get user with password hash
    const result = await pool.query(
        `SELECT u.id, u.email, u.password_hash, u.first_name, u.last_name, u.role, 
                u.institution_id, u.is_active, u.email_verified
         FROM users u
         WHERE u.email = $1`,
        [email]
    );

    if (result.rows.length === 0) {
        throw new AppError('Invalid email or password', 401);
    }

    const user = result.rows[0];

    // Check if user is active
    if (!user.is_active) {
        throw new AppError('Account is deactivated. Please contact administrator.', 401);
    }

    // Check if email is verified
    if (!user.email_verified) {
        throw new AppError('Please verify your email before logging in', 401);
    }

    // Verify password
    const isPasswordValid = await comparePassword(password, user.password_hash);
    if (!isPasswordValid) {
        throw new AppError('Invalid email or password', 401);
    }

    // Generate tokens
    const { accessToken, refreshToken } = generateTokens(user.id);

    // Store refresh token in database
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7); // 7 days from now

    await pool.query(
        `INSERT INTO user_sessions (user_id, refresh_token_hash, expires_at, device_info, ip_address)
         VALUES ($1, $2, $3, $4, $5)`,
        [
            user.id,
            refreshToken,
            expiresAt,
            JSON.stringify({
                userAgent: req.get('User-Agent'),
                platform: req.get('Sec-Ch-Ua-Platform')
            }),
            req.ip
        ]
    );

    // Update last login
    await pool.query(
        'UPDATE users SET last_login = CURRENT_TIMESTAMP WHERE id = $1',
        [user.id]
    );

    logger.api(`User logged in: ${email}`, {
        userId: user.id,
        role: user.role,
        ip: req.ip
    });

    res.json({
        success: true,
        message: 'Login successful',
        data: {
            user: {
                id: user.id,
                email: user.email,
                firstName: user.first_name,
                lastName: user.last_name,
                role: user.role,
                institutionId: user.institution_id
            },
            tokens: {
                accessToken,
                refreshToken,
                expiresIn: 15 * 60 // 15 minutes in seconds
            }
        }
    });
}));

/**
 * @swagger
 * /auth/refresh:
 *   post:
 *     summary: Refresh access token
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - refreshToken
 *             properties:
 *               refreshToken:
 *                 type: string
 *     responses:
 *       200:
 *         description: Token refreshed successfully
 *       401:
 *         description: Invalid refresh token
 */
router.post('/refresh', authenticateRefreshToken, asyncHandler(async (req, res) => {
    const { user } = req;

    // Generate new tokens
    const { accessToken, refreshToken } = generateTokens(user.id);

    // Update refresh token in database
    const pool = getPool();
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7); // 7 days from now

    await pool.query(
        `UPDATE user_sessions 
         SET refresh_token_hash = $1, expires_at = $2, updated_at = CURRENT_TIMESTAMP
         WHERE id = $3`,
        [refreshToken, expiresAt, user.sessionId]
    );

    logger.api(`Token refreshed for user: ${user.id}`);

    res.json({
        success: true,
        message: 'Token refreshed successfully',
        data: {
            tokens: {
                accessToken,
                refreshToken,
                expiresIn: 15 * 60 // 15 minutes in seconds
            }
        }
    });
}));

/**
 * @swagger
 * /auth/logout:
 *   post:
 *     summary: Logout user
 *     tags: [Authentication]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Logout successful
 */
router.post('/logout', authenticateToken, asyncHandler(async (req, res) => {
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
    const pool = getPool();
    await pool.query(
        'DELETE FROM user_sessions WHERE user_id = $1',
        [req.user.id]
    );

    logger.api(`User logged out: ${req.user.email}`, {
        userId: req.user.id
    });

    res.json({
        success: true,
        message: 'Logout successful'
    });
}));

/**
 * @swagger
 * /auth/me:
 *   get:
 *     summary: Get current user profile
 *     tags: [Authentication]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: User profile retrieved successfully
 */
router.get('/me', authenticateToken, asyncHandler(async (req, res) => {
    const pool = getPool();

    const result = await pool.query(
        `SELECT u.id, u.email, u.first_name, u.last_name, u.role, u.institution_id,
                u.avatar_url, u.preferences, u.last_login, u.created_at,
                i.name as institution_name, i.type as institution_type
         FROM users u
         LEFT JOIN institutions i ON u.institution_id = i.id
         WHERE u.id = $1`,
        [req.user.id]
    );

    if (result.rows.length === 0) {
        throw new AppError('User not found', 404);
    }

    const user = result.rows[0];

    res.json({
        success: true,
        data: {
            user: {
                id: user.id,
                email: user.email,
                firstName: user.first_name,
                lastName: user.last_name,
                role: user.role,
                institutionId: user.institution_id,
                institutionName: user.institution_name,
                institutionType: user.institution_type,
                avatarUrl: user.avatar_url,
                preferences: user.preferences,
                lastLogin: user.last_login,
                createdAt: user.created_at
            }
        }
    });
}));

/**
 * @swagger
 * /auth/change-password:
 *   post:
 *     summary: Change user password
 *     tags: [Authentication]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - currentPassword
 *               - newPassword
 *             properties:
 *               currentPassword:
 *                 type: string
 *               newPassword:
 *                 type: string
 *                 minLength: 8
 *     responses:
 *       200:
 *         description: Password changed successfully
 *       400:
 *         description: Invalid current password
 */
router.post('/change-password', [
    authenticateToken,
    body('currentPassword').notEmpty(),
    body('newPassword').isLength({ min: 8 }).withMessage('New password must be at least 8 characters long')
], asyncHandler(async (req, res) => {
    // Check validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        throw new AppError(`Validation failed: ${errors.array().map(e => e.msg).join(', ')}`, 400);
    }

    const { currentPassword, newPassword } = req.body;

    const pool = getPool();

    // Get current password hash
    const result = await pool.query(
        'SELECT password_hash FROM users WHERE id = $1',
        [req.user.id]
    );

    if (result.rows.length === 0) {
        throw new AppError('User not found', 404);
    }

    const user = result.rows[0];

    // Verify current password
    const isCurrentPasswordValid = await comparePassword(currentPassword, user.password_hash);
    if (!isCurrentPasswordValid) {
        throw new AppError('Current password is incorrect', 400);
    }

    // Hash new password
    const newPasswordHash = await hashPassword(newPassword);

    // Update password
    await pool.query(
        'UPDATE users SET password_hash = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2',
        [newPasswordHash, req.user.id]
    );

    // Invalidate all existing sessions
    await pool.query(
        'DELETE FROM user_sessions WHERE user_id = $1',
        [req.user.id]
    );

    logger.security(`Password changed for user: ${req.user.email}`, {
        userId: req.user.id
    });

    res.json({
        success: true,
        message: 'Password changed successfully. Please login again with your new password.'
    });
}));

module.exports = router;
