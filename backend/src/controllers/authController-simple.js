const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { validationResult } = require('express-validator');

class AuthController {
  constructor() {
    // In-memory storage for testing
    this.users = new Map();
    this.sessions = new Map();
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
      if (this.users.has(email)) {
        return res.status(409).json({
          success: false,
          message: 'User with this email already exists'
        });
      }

      // Hash password
      const saltRounds = parseInt(process.env.BCRYPT_SALT_ROUNDS) || 12;
      const hashedPassword = await bcrypt.hash(password, saltRounds);

      // Create user
      const userId = Date.now().toString();
      const user = {
        id: userId,
        name,
        email,
        password_hash: hashedPassword,
        role: 'student',
        institution_id,
        created_at: new Date(),
        updated_at: new Date()
      };

      this.users.set(email, user);

      // Generate tokens
      const accessToken = jwt.sign(
        { userId: user.id, email: user.email, role: user.role },
        process.env.JWT_SECRET || 'fallback-secret',
        { expiresIn: process.env.JWT_EXPIRES_IN || '15m' }
      );

      const refreshToken = jwt.sign(
        { userId: user.id, tokenVersion: 0 },
        process.env.JWT_REFRESH_SECRET || 'fallback-refresh-secret',
        { expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d' }
      );

      // Store refresh token
      this.sessions.set(userId, {
        refresh_token: refreshToken,
        expires_at: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
      });

      console.log(`User registered successfully: ${user.email}`, { userId: user.id });

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
      console.error('Registration failed:', error);
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
      const user = this.users.get(email);
      if (!user) {
        return res.status(401).json({
          success: false,
          message: 'Invalid email or password'
        });
      }

      // Verify password
      const isValidPassword = await bcrypt.compare(password, user.password_hash);
      if (!isValidPassword) {
        return res.status(401).json({
          success: false,
          message: 'Invalid email or password'
        });
      }

      // Generate tokens
      const accessToken = jwt.sign(
        { userId: user.id, email: user.email, role: user.role },
        process.env.JWT_SECRET || 'fallback-secret',
        { expiresIn: process.env.JWT_EXPIRES_IN || '15m' }
      );

      const refreshToken = jwt.sign(
        { userId: user.id, tokenVersion: 0 },
        process.env.JWT_REFRESH_SECRET || 'fallback-refresh-secret',
        { expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d' }
      );

      // Store refresh token
      this.sessions.set(user.id, {
        refresh_token: refreshToken,
        expires_at: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
      });

      console.log(`User logged in successfully: ${user.email}`, { userId: user.id });

      res.json({
        success: true,
        message: 'Login successful',
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
      console.error('Login failed:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  // Refresh token
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
      const decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET || 'fallback-refresh-secret');
      
      // Check if session exists
      const session = this.sessions.get(decoded.userId);
      if (!session || session.refresh_token !== refreshToken) {
        return res.status(401).json({
          success: false,
          message: 'Invalid refresh token'
        });
      }

      // Check if session is expired
      if (new Date() > session.expires_at) {
        this.sessions.delete(decoded.userId);
        return res.status(401).json({
          success: false,
          message: 'Refresh token expired'
        });
      }

      // Find user
      let user = null;
      for (const [email, u] of this.users) {
        if (u.id === decoded.userId) {
          user = u;
          break;
        }
      }

      if (!user) {
        return res.status(401).json({
          success: false,
          message: 'User not found'
        });
      }

      // Generate new access token
      const newAccessToken = jwt.sign(
        { userId: user.id, email: user.email, role: user.role },
        process.env.JWT_SECRET || 'fallback-secret',
        { expiresIn: process.env.JWT_EXPIRES_IN || '15m' }
      );

      res.json({
        success: true,
        message: 'Token refreshed successfully',
        accessToken: newAccessToken
      });

    } catch (error) {
      console.error('Token refresh failed:', error);
      res.status(401).json({
        success: false,
        message: 'Invalid refresh token'
      });
    }
  }

  // Get current user
  async getCurrentUser(req, res) {
    try {
      const userId = req.user.userId;
      
      // Find user
      let user = null;
      for (const [email, u] of this.users) {
        if (u.id === userId) {
          user = u;
          break;
        }
      }

      if (!user) {
        return res.status(404).json({
          success: false,
          message: 'User not found'
        });
      }

      res.json({
        success: true,
        user: {
          id: user.id,
          name: user.name,
          email: user.email,
          role: user.role,
          institution_id: user.institution_id,
          created_at: user.created_at,
          updated_at: user.updated_at
        }
      });

    } catch (error) {
      console.error('Get current user failed:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  // Change password
  async changePassword(req, res) {
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

      const { currentPassword, newPassword } = req.body;
      const userId = req.user.userId;

      // Find user
      let user = null;
      for (const [email, u] of this.users) {
        if (u.id === userId) {
          user = u;
          break;
        }
      }

      if (!user) {
        return res.status(404).json({
          success: false,
          message: 'User not found'
        });
      }

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
      const hashedPassword = await bcrypt.hash(newPassword, saltRounds);

      // Update password
      user.password_hash = hashedPassword;
      user.updated_at = new Date();

      console.log(`Password changed successfully for user: ${user.email}`);

      res.json({
        success: true,
        message: 'Password changed successfully'
      });

    } catch (error) {
      console.error('Change password failed:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  // Logout
  async logout(req, res) {
    try {
      const userId = req.user.userId;

      // Remove session
      this.sessions.delete(userId);

      console.log(`User logged out: ${userId}`);

      res.json({
        success: true,
        message: 'Logout successful'
      });

    } catch (error) {
      console.error('Logout failed:', error);
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
      
      // Find user
      let user = null;
      for (const [email, u] of this.users) {
        if (u.id === userId) {
          user = u;
          break;
        }
      }

      if (!user) {
        return res.status(404).json({
          success: false,
          message: 'User not found'
        });
      }

      // Return basic permissions based on role
      const permissions = {
        canUploadDocuments: true,
        canProcessImages: true,
        canGenerateQuestions: true,
        canManageBatchJobs: user.role === 'admin' || user.role === 'teacher',
        canAccessAdminPanel: user.role === 'admin',
        canManageUsers: user.role === 'admin'
      };

      res.json({
        success: true,
        permissions
      });

    } catch (error) {
      console.error('Get user permissions failed:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }
}

module.exports = new AuthController();

