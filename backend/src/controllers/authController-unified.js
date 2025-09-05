const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { validationResult } = require('express-validator');
const admin = require('firebase-admin');
const logger = require('../utils/logger');

class UnifiedAuthController {
  constructor() {
    // In-memory storage for testing (replace with database in production)
    this.users = new Map();
    this.sessions = new Map();
    
    // Initialize with test users
    this._initializeTestUsers();
  }

  // Initialize test users for development
  _initializeTestUsers() {
    const testUsers = [
      {
        id: '1',
        name: 'Test User',
        email: 'test@example.com',
        password: 'password123',
        role: 'user',
        institution: 'Test Institution'
      },
      {
        id: '2',
        name: 'Admin User',
        email: 'admin@example.com',
        password: 'admin123',
        role: 'admin',
        institution: 'Test Institution'
      }
    ];

    testUsers.forEach(user => {
      this.users.set(user.email, {
        ...user,
        password_hash: bcrypt.hashSync(user.password, 12)
      });
    });

    logger.info(`Initialized ${testUsers.length} test users for development`);
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

      const { name, email, password, institution } = req.body;

      // Check if user already exists
      if (this.users.has(email)) {
        return res.status(409).json({
          success: false,
          message: 'User with this email already exists'
        });
      }

      // Hash password
      const passwordHash = await bcrypt.hash(password, 12);

      // Create user
      const userId = Date.now().toString();
      const newUser = {
        id: userId,
        name,
        email,
        password_hash: passwordHash,
        role: 'user',
        institution: institution || 'Default Institution',
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      };

      this.users.set(email, newUser);

      logger.info(`User registered successfully: ${email}`);

      res.status(201).json({
        success: true,
        message: 'User registered successfully',
        user: {
          id: newUser.id,
          name: newUser.name,
          email: newUser.email,
          role: newUser.role,
          institution: newUser.institution
        }
      });
    } catch (error) {
      logger.error('Registration error:', error);
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
        { 
          userId: user.id, 
          email: user.email, 
          role: user.role 
        },
        process.env.JWT_SECRET || 'fallback-secret',
        { expiresIn: process.env.JWT_EXPIRES_IN || '15m' }
      );

      const refreshToken = jwt.sign(
        { 
          userId: user.id, 
          tokenVersion: 0 
        },
        process.env.JWT_REFRESH_SECRET || 'fallback-refresh-secret',
        { expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d' }
      );

      // Store refresh token
      this.sessions.set(user.id, {
        refresh_token: refreshToken,
        expires_at: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
      });

      logger.info(`User logged in successfully: ${user.email}`, { userId: user.id });

      res.json({
        success: true,
        message: 'Login successful',
        user: {
          id: user.id,
          name: user.name,
          email: user.email,
          role: user.role,
          institution: user.institution
        },
        tokens: {
          accessToken,
          refreshToken
        }
      });
    } catch (error) {
      logger.error('Login error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  // Firebase token verification
  async verifyFirebaseToken(req, res) {
    try {
      const { idToken } = req.body;

      if (!idToken) {
        return res.status(400).json({
          success: false,
          message: 'Firebase ID token required'
        });
      }

      try {
        // Verify Firebase token
        const decodedToken = await admin.auth().verifyIdToken(idToken);
        
        // Check if user exists in our system
        let user = this.users.get(decodedToken.email);
        
        if (!user) {
          // Create user if they don't exist (Firebase first-time login)
          const userId = Date.now().toString();
          user = {
            id: userId,
            name: decodedToken.name || decodedToken.email.split('@')[0],
            email: decodedToken.email,
            password_hash: null, // Firebase users don't have passwords
            role: 'user',
            institution: 'Firebase User',
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString()
          };
          
          this.users.set(decodedToken.email, user);
          logger.info(`Firebase user created: ${decodedToken.email}`);
        }

        // Generate our JWT tokens
        const accessToken = jwt.sign(
          { 
            userId: user.id, 
            email: user.email, 
            role: user.role 
          },
          process.env.JWT_SECRET || 'fallback-secret',
          { expiresIn: process.env.JWT_EXPIRES_IN || '15m' }
        );

        const refreshToken = jwt.sign(
          { 
            userId: user.id, 
            tokenVersion: 0 
          },
          process.env.JWT_REFRESH_SECRET || 'fallback-refresh-secret',
          { expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d' }
        );

        // Store refresh token
        this.sessions.set(user.id, {
          refresh_token: refreshToken,
          expires_at: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
        });

        logger.info(`Firebase user authenticated: ${user.email}`);

        res.json({
          success: true,
          message: 'Firebase authentication successful',
          user: {
            id: user.id,
            name: user.name,
            email: user.email,
            role: user.role,
            institution: user.institution
          },
          tokens: {
            accessToken,
            refreshToken
          }
        });

      } catch (firebaseError) {
        logger.error('Firebase token verification failed:', firebaseError);
        return res.status(401).json({
          success: false,
          message: 'Invalid Firebase token'
        });
      }

    } catch (error) {
      logger.error('Firebase authentication error:', error);
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
          message: 'Refresh token required'
        });
      }

      // Verify refresh token
      const decoded = jwt.verify(
        refreshToken, 
        process.env.JWT_REFRESH_SECRET || 'fallback-refresh-secret'
      );

      // Check if session exists
      const session = this.sessions.get(decoded.userId);
      if (!session || session.refresh_token !== refreshToken) {
        return res.status(401).json({
          success: false,
          message: 'Invalid refresh token'
        });
      }

      // Check if session expired
      if (new Date() > session.expires_at) {
        this.sessions.delete(decoded.userId);
        return res.status(401).json({
          success: false,
          message: 'Refresh token expired'
        });
      }

      // Get user
      const user = Array.from(this.users.values()).find(u => u.id === decoded.userId);
      if (!user) {
        return res.status(401).json({
          success: false,
          message: 'User not found'
        });
      }

      // Generate new access token
      const newAccessToken = jwt.sign(
        { 
          userId: user.id, 
          email: user.email, 
          role: user.role 
        },
        process.env.JWT_SECRET || 'fallback-secret',
        { expiresIn: process.env.JWT_EXPIRES_IN || '15m' }
      );

      logger.info(`Token refreshed for user: ${user.email}`);

      res.json({
        success: true,
        message: 'Token refreshed successfully',
        accessToken: newAccessToken
      });

    } catch (error) {
      logger.error('Token refresh error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  // Get current user
  async getCurrentUser(req, res) {
    try {
      // User is already attached by auth middleware
      const user = req.user;

      res.json({
        success: true,
        user: {
          id: user.id,
          name: user.name,
          email: user.email,
          role: user.role,
          institution: user.institution
        }
      });
    } catch (error) {
      logger.error('Get current user error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  // Logout
  async logout(req, res) {
    try {
      const userId = req.user.id;

      // Remove session
      this.sessions.delete(userId);

      logger.info(`User logged out: ${req.user.email}`);

      res.json({
        success: true,
        message: 'Logout successful'
      });
    } catch (error) {
      logger.error('Logout error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  // Get test users (for development)
  async getTestUsers(req, res) {
    try {
      const users = Array.from(this.users.values()).map(user => ({
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        institution: user.institution
      }));

      res.json({
        success: true,
        users
      });
    } catch (error) {
      logger.error('Get test users error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }
}

module.exports = new UnifiedAuthController();
