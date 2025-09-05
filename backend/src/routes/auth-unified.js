const express = require('express');
const { body } = require('express-validator');
const authController = require('../controllers/authController-unified');
const { authenticateToken } = require('../middleware/auth-simple');
const router = express.Router();

// Validation middleware
const loginValidation = [
  body('email')
    .isEmail()
    .normalizeEmail()
    .withMessage('Please enter a valid email address'),
  body('password')
    .isLength({ min: 6 })
    .withMessage('Password must be at least 6 characters long')
];

const registerValidation = [
  body('name')
    .trim()
    .isLength({ min: 2, max: 50 })
    .withMessage('Name must be between 2 and 50 characters'),
  body('email')
    .isEmail()
    .normalizeEmail()
    .withMessage('Please enter a valid email address'),
  body('password')
    .isLength({ min: 6 })
    .withMessage('Password must be at least 6 characters long'),
  body('institution')
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage('Institution name must be less than 100 characters')
];

const firebaseValidation = [
  body('idToken')
    .notEmpty()
    .withMessage('Firebase ID token is required')
];

// Public routes (no authentication required)
router.post('/register', registerValidation, authController.register);
router.post('/login', loginValidation, authController.login);
router.post('/firebase', firebaseValidation, authController.verifyFirebaseToken);
router.post('/refresh', authController.refreshToken);

// Protected routes (authentication required)
router.get('/me', authenticateToken, authController.getCurrentUser);
router.post('/logout', authenticateToken, authController.logout);

// Development routes (remove in production)
router.get('/test-users', authController.getTestUsers);

module.exports = router;
