const express = require('express');
const { body, query } = require('express-validator');
const documentController = require('../controllers/documentController');
const auth = require('../middleware/auth');
const upload = require('../middleware/upload');

const router = express.Router();

// All routes require authentication
router.use(auth);

// Validation rules
const uploadValidation = [
  body('title').trim().isLength({ min: 1, max: 200 }).withMessage('Title must be between 1 and 200 characters'),
  body('description').optional().trim().isLength({ max: 1000 }).withMessage('Description must be less than 1000 characters'),
  body('language').optional().isIn(['en', 'hi', 'bn', 'te', 'ta', 'mr', 'gu', 'kn', 'ml', 'pa']).withMessage('Invalid language'),
  body('features').optional().isArray().withMessage('Features must be an array'),
  body('processingOptions').optional().isObject().withMessage('Processing options must be an object')
];

const updateValidation = [
  body('title').optional().trim().isLength({ min: 1, max: 200 }).withMessage('Title must be between 1 and 200 characters'),
  body('description').optional().trim().isLength({ max: 1000 }).withMessage('Description must be less than 1000 characters'),
  body('language').optional().isIn(['en', 'hi', 'bn', 'te', 'ta', 'mr', 'gu', 'kn', 'ml', 'pa']).withMessage('Invalid language'),
  body('metadata').optional().isObject().withMessage('Metadata must be an object')
];

const shareValidation = [
  body('userEmails').isArray({ min: 1 }).withMessage('At least one user email is required'),
  body('userEmails.*').isEmail().withMessage('Invalid email format'),
  body('permission').optional().isIn(['read', 'write', 'admin']).withMessage('Invalid permission'),
  body('expiresAt').optional().isISO8601().withMessage('Invalid expiry date')
];

// Document CRUD operations
router.get('/', [
  query('page').optional().isInt({ min: 1 }).withMessage('Page must be a positive integer'),
  query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('Limit must be between 1 and 100'),
  query('status').optional().isIn(['uploaded', 'processing', 'completed', 'failed']).withMessage('Invalid status'),
  query('type').optional().isIn(['pdf', 'image', 'word', 'excel', 'powerpoint', 'text', 'other']).withMessage('Invalid type'),
  query('search').optional().trim().isLength({ max: 100 }).withMessage('Search query too long')
], documentController.getDocuments);

router.post('/', upload.single('file'), uploadValidation, documentController.uploadDocument);

router.get('/shared', documentController.getSharedDocuments);

router.get('/:documentId', [
  query('documentId').isUUID().withMessage('Invalid document ID')
], documentController.getDocument);

router.put('/:documentId', [
  body('documentId').isUUID().withMessage('Invalid document ID')
], updateValidation, documentController.updateDocument);

router.delete('/:documentId', [
  body('documentId').isUUID().withMessage('Invalid document ID')
], documentController.deleteDocument);

// Document processing and status
router.get('/:documentId/status', documentController.getProcessingStatus);
router.get('/:documentId/pages', documentController.getDocumentPages);

// Document sharing
router.post('/:documentId/share', shareValidation, documentController.shareDocument);

module.exports = router;
