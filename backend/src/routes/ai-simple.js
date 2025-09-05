const express = require('express');
const auth = require('../middleware/auth-simple');
const aiController = require('../controllers/aiController-enhanced');

const router = express.Router();

// Mock data for testing
const mockQuestions = [
  {
    id: '1',
    question: 'What is the main topic of this document?',
    answer: 'The main topic is artificial intelligence and machine learning.',
    type: 'multiple_choice',
    options: ['AI', 'Machine Learning', 'Data Science', 'Programming'],
    correct_answer: 0,
    difficulty: 'easy',
    document_id: '1'
  },
  {
    id: '2',
    question: 'Which algorithm is commonly used for classification?',
    answer: 'Support Vector Machine (SVM) is commonly used for classification.',
    type: 'short_answer',
    difficulty: 'medium',
    document_id: '1'
  }
];

// Generate questions from document using AI
router.post('/generate-questions', aiController.generateQuestions);

// Get questions for document
router.get('/questions/:documentId', (req, res) => {
  try {
    const documentId = req.params.documentId;
    
    const questions = mockQuestions.filter(q => q.document_id === documentId);
    
    res.json({
      success: true,
      questions,
      total: questions.length
    });
  } catch (error) {
    console.error('Get questions failed:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Process image with OCR using AI
router.post('/ocr', aiController.processImageOCR);

// Process handwriting
router.post('/handwriting', (req, res) => {
  try {
    const { imageUrl, language = 'en' } = req.body;
    
    // Mock handwriting recognition
    const handwritingResult = {
      text: 'This is handwritten text that has been recognized.',
      confidence: 0.87,
      language,
      processing_time: 2.1,
      words: 8,
      characters: 45
    };
    
    res.json({
      success: true,
      message: 'Handwriting recognition completed',
      result: handwritingResult
    });
  } catch (error) {
    console.error('Handwriting recognition failed:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Image enhancement using AI
router.post('/enhance-image', aiController.enhanceImage);

// Generate document summary using AI
router.post('/generate-summary', aiController.generateSummary);

module.exports = router;
