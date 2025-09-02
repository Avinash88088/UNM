const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { validationResult } = require('express-validator');
const { getPool } = require('../database/connection');
const logger = require('../utils/logger');

class AuthController {
  constructor() {
    this.pool = getPool();
  }

  // User registration
  async register(req, res) {
    try {
      // Validate input
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          success: false,
          message: 'Validation failed',
          errors: errors.array()
        });
      }

      const { name, email, password, institution_id } = req.body;

      // Check if user already exists
      const existingUser = await this.pool.query(
        'SELECT id FROM users WHERE email = $1',
        [email]
      );

      if (existingUser.rows.length > 0) {
        return res.status(409).json({
          success: false,
          message: 'User with this email already exists'
        });
      }

      // Hash password
      const saltRounds = parseInt(process.env.BCRYPT_SALT_ROUNDS) || 12;
      const hashedPassword = await bcrypt.hash(password, saltRounds);

      // Create user
      const newUser = await this.pool.query(
        `INSERT INTO users (name, email, password_hash, role, institution_id, created_at, updated_at)
         VALUES ($1, $2, $3, $4, $5, NOW(), NOW())
         RETURNING id, name, email, role, institution_id, created_at, updated_at`,
        [name, email, hashedPassword, 'student', institution_id]
      );

      const user = newUser.rows[0];

      // Generate tokens
      const accessToken = jwt.sign(
        { userId: user.id, email: user.email, role: user.role },
        process.env.JWT_SECRET,
        { expiresIn: process.env.JWT_EXPIRES_IN || '15m' }
      );

      const refreshToken = jwt.sign(
        { userId: user.id, tokenVersion: 0 },
        process.env.JWT_REFRESH_SECRET,
        { expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d' }
      );

      // Store refresh token
      await this.pool.query(
        'INSERT INTO user_sessions (user_id, refresh_token, expires_at) VALUES ($1, $2, $3)',
        [user.id, refreshToken, new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)]
      );

      logger.info(`User registered successfully: ${user.email}`, { userId: user.id });

      res.status(201).json({
        success: true,
        message: 'User registered successfully',
        user: {
          id: user.id,
          name: user.name,
          email: user.email,
          role: user.role,
          institution_id: user.institution_id,
          created_at: user.created_at,
          updated_at: user.updated_at
        },
        accessToken,
        refreshToken
      });

    } catch (error) {
      logger.error('Registration failed:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  // User login
  async login(req, res) {
    try {
      // Validate input
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          success: false,
          message: 'Validation failed',
          errors: errors.array()
        });
      }

      const { email, password } = req.body;

      // Find user
      const userResult = await this.pool.query(
        `SELECT u.id, u.name, u.email, u.password_hash, u.role, u.institution_id, u.created_at, u.updated_at,
                i.name as institution_name
         FROM users u
         LEFT JOIN institutions i ON u.institution_id = i.id
         WHERE u.email = $1`,
        [email]
      );

      if (userResult.rows.length === 0) {
        return res.status(401).json({
          success: false,
          message: 'Invalid credentials'
        });
      }

      const user = userResult.rows[0];

      // Verify password
      const isValidPassword = await bcrypt.compare(password, user.password_hash);
      if (!isValidPassword) {
        return res.status(401).json({
          success: false,
          message: 'Invalid credentials'
        });
      }

      // Generate tokens
      const accessToken = jwt.sign(
        { userId: user.id, email: user.email, role: user.role },
        process.env.JWT_SECRET,
        { expiresIn: process.env.JWT_EXPIRES_IN || '15m' }
      );

      const refreshToken = jwt.sign(
        { userId: user.id, tokenVersion: 0 },
        process.env.JWT_REFRESH_SECRET,
        { expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d' }
      );

      // Store refresh token
      await this.pool.query(
        'INSERT INTO user_sessions (user_id, refresh_token, expires_at) VALUES ($1, $2, $3)',
        [user.id, refreshToken, new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)]
      );

      // Update last login
      await this.pool.query(
        'UPDATE users SET last_login = NOW() WHERE id = $1',
        [user.id]
      );

      logger.info(`User logged in successfully: ${user.email}`, { userId: user.id });

      res.json({
        success: true,
        message: 'Login successful',
        user: {
          id: user.id,
          name: user.name,
          email: user.email,
          role: user.role,
          institution_id: user.institution_id,
          institution_name: user.institution_name,
          created_at: user.created_at,
          updated_at: user.updated_at
        },
        accessToken,
        refreshToken
      });

    } catch (error) {
      logger.error('Login failed:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  // Refresh access token
  async refreshToken(req, res) {
    try {
      const { refreshToken } = req.body;

      if (!refreshToken) {
        return res.status(400).json({
          success: false,
          message: 'Refresh token is required'
        });
      }

      // Verify refresh token
      const decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);

      // Check if token exists in database
      const sessionResult = await this.pool.query(
        'SELECT * FROM user_sessions WHERE refresh_token = $1 AND expires_at > NOW()',
        [refreshToken]
      );

      if (sessionResult.rows.length === 0) {
        return res.status(401).json({
          success: false,
          message: 'Invalid refresh token'
        });
      }

      // Get user info
      const userResult = await this.pool.query(
        'SELECT id, email, role FROM users WHERE id = $1',
        [decoded.userId]
      );

      if (userResult.rows.length === 0) {
        return res.status(401).json({
          success: false,
          message: 'User not found'
        });
      }

      const user = userResult.rows[0];

      // Generate new access token
      const newAccessToken = jwt.sign(
        { userId: user.id, email: user.email, role: user.role },
        process.env.JWT_SECRET,
        { expiresIn: process.env.JWT_EXPIRES_IN || '15m' }
      );

      logger.info(`Token refreshed for user: ${user.email}`, { userId: user.id });

      res.json({
        success: true,
        message: 'Token refreshed successfully',
        accessToken: newAccessToken
      });

    } catch (error) {
      if (error.name === 'JsonWebTokenError') {
        return res.status(401).json({
          success: false,
          message: 'Invalid refresh token'
        });
      }

      if (error.name === 'TokenExpiredError') {
        return res.status(401).json({
          success: false,
          message: 'Refresh token expired'
        });
      }

      logger.error('Token refresh failed:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  // Get current user
  async getCurrentUser(req, res) {
    try {
      const userId = req.user.userId;

      const userResult = await this.pool.query(
        `SELECT u.id, u.name, u.email, u.role, u.institution_id, u.created_at, u.updated_at,
                i.name as institution_name
         FROM users u
         LEFT JOIN institutions i ON u.institution_id = i.id
         WHERE u.id = $1`,
        [userId]
      );

      if (userResult.rows.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'User not found'
        });
      }

      const user = userResult.rows[0];

      res.json({
        success: true,
        user: {
          id: user.id,
          name: user.name,
          email: user.email,
          role: user.role,
          institution_id: user.institution_id,
          institution_name: user.institution_name,
          created_at: user.created_at,
          updated_at: user.updated_at
        }
      });

    } catch (error) {
      logger.error('Get current user failed:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  // Change password
  async changePassword(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          success: false,
          message: 'Validation failed',
          errors: errors.array()
        });
      }

      const { currentPassword, newPassword } = req.body;
      const userId = req.user.userId;

      // Get current password hash
      const userResult = await this.pool.query(
        'SELECT password_hash FROM users WHERE id = $1',
        [userId]
      );

      if (userResult.rows.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'User not found'
        });
      }

      const user = userResult.rows[0];

      // Verify current password
      const isValidPassword = await bcrypt.compare(currentPassword, user.password_hash);
      if (!isValidPassword) {
        return res.status(401).json({
          success: false,
          message: 'Current password is incorrect'
        });
      }

      // Hash new password
      const saltRounds = parseInt(process.env.BCRYPT_SALT_ROUNDS) || 12;
      const newHashedPassword = await bcrypt.hash(newPassword, saltRounds);

      // Update password
      await this.pool.query(
        'UPDATE users SET password_hash = $1, updated_at = NOW() WHERE id = $2',
        [newHashedPassword, userId]
      );

      // Invalidate all refresh tokens for this user
      await this.pool.query(
        'DELETE FROM user_sessions WHERE user_id = $1',
        [userId]
      );

      logger.info(`Password changed for user ID: ${userId}`);

      res.json({
        success: true,
        message: 'Password changed successfully'
      });

    } catch (error) {
      logger.error('Change password failed:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  // Logout user
  async logout(req, res) {
    try {
      const { refreshToken } = req.body;
      const userId = req.user.userId;

      if (refreshToken) {
        // Remove specific refresh token
        await this.pool.query(
          'DELETE FROM user_sessions WHERE refresh_token = $1 AND user_id = $2',
          [refreshToken, userId]
        );
      } else {
        // Remove all refresh tokens for user
        await this.pool.query(
          'DELETE FROM user_sessions WHERE user_id = $1',
          [userId]
        );
      }

      logger.info(`User logged out: ${userId}`);

      res.json({
        success: true,
        message: 'Logout successful'
      });

    } catch (error) {
      logger.error('Logout failed:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  // Get user permissions
  async getUserPermissions(req, res) {
    try {
      const userId = req.user.userId;

      const userResult = await this.pool.query(
        'SELECT role FROM users WHERE id = $1',
        [userId]
      );

      if (userResult.rows.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'User not found'
        });
      }

      const user = userResult.rows[0];
      const permissions = this.getPermissionsByRole(user.role);

      res.json({
        success: true,
        permissions
      });

    } catch (error) {
      logger.error('Get user permissions failed:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  // Helper method to get permissions by role
  getPermissionsByRole(role) {
    const permissions = {
      super_admin: [
        'users:read', 'users:write', 'users:delete',
        'documents:read', 'documents:write', 'documents:delete',
        'ai:process', 'admin:access', 'institutions:manage'
      ],
      admin: [
        'users:read', 'users:write',
        'documents:read', 'documents:write', 'documents:delete',
        'ai:process', 'institutions:manage'
      ],
      teacher: [
        'documents:read', 'documents:write',
        'ai:process', 'questions:read', 'questions:write',
        'students:read'
      ],
      student: [
        'documents:read', 'ai:process', 'questions:read'
      ]
    };

    return permissions[role] || ['documents:read'];
  }
}

module.exports = new AuthController();
