const express = require('express');
const { body, query } = require('express-validator');
const aiController = require('../controllers/aiController');
const auth = require('../middleware/auth');

const router = express.Router();

// All routes require authentication
router.use(auth);

// Validation rules
const processDocumentValidation = [
  body('documentId').isUUID().withMessage('Invalid document ID'),
  body('features').optional().isArray().withMessage('Features must be an array'),
  body('features.*').optional().isIn(['ocr', 'hwr', 'text_extraction', 'language_detection']).withMessage('Invalid feature'),
  body('options').optional().isObject().withMessage('Options must be an object')
];

const questionGenerationValidation = [
  body('documentId').isUUID().withMessage('Invalid document ID'),
  body('count').optional().isInt({ min: 1, max: 50 }).withMessage('Count must be between 1 and 50'),
  body('difficulty').optional().isIn(['easy', 'medium', 'hard']).withMessage('Invalid difficulty level'),
  body('types').optional().isArray().withMessage('Types must be an array'),
  body('types.*').optional().isIn(['mcq', 'short_answer', 'long_answer', 'true_false']).withMessage('Invalid question type'),
  body('language').optional().isIn(['en', 'hi', 'bn', 'te', 'ta', 'mr', 'gu', 'kn', 'ml', 'pa']).withMessage('Invalid language')
];

const processingHistoryValidation = [
  query('page').optional().isInt({ min: 1 }).withMessage('Page must be a positive integer'),
  query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('Limit must be between 1 and 100'),
  query('status').optional().isIn(['queued', 'processing', 'completed', 'failed']).withMessage('Invalid status')
];

// AI Processing routes
router.post('/process', processDocumentValidation, aiController.processDocument);

// Question Generation routes
router.post('/questions', questionGenerationValidation, aiController.generateQuestions);

// Processing Status and History
router.get('/status/:jobId', aiController.getProcessingStatus);
router.get('/history', processingHistoryValidation, aiController.getProcessingHistory);

module.exports = router;
