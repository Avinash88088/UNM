const express = require('express');
const { body } = require('express-validator');
const authController = require('../controllers/authController-simple');
const auth = require('../middleware/auth-simple');

const router = express.Router();

// Validation rules
const registerValidation = [
  body('name').trim().isLength({ min: 2, max: 50 }).withMessage('Name must be between 2 and 50 characters'),
  body('email').isEmail().normalizeEmail().withMessage('Must be a valid email'),
  body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
  body('institution_id').optional().isUUID().withMessage('Invalid institution ID')
];

const loginValidation = [
  body('email').isEmail().normalizeEmail().withMessage('Must be a valid email'),
  body('password').notEmpty().withMessage('Password is required')
];

const changePasswordValidation = [
  body('currentPassword').notEmpty().withMessage('Current password is required'),
  body('newPassword').isLength({ min: 6 }).withMessage('New password must be at least 6 characters')
];

// Public routes (no authentication required)
router.post('/register', registerValidation, authController.register);
router.post('/login', loginValidation, authController.login);
router.post('/refresh', authController.refreshToken);

// Protected routes (authentication required)
router.get('/me', auth, authController.getCurrentUser);
router.post('/change-password', auth, changePasswordValidation, authController.changePassword);
router.post('/logout', auth, authController.logout);
router.get('/permissions', auth, authController.getUserPermissions);

module.exports = router;
