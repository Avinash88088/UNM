// Load environment variables
require('dotenv').config();

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');

const app = express();

// Basic middleware
app.use(helmet());
app.use(cors({
  origin: process.env.FRONTEND_URL || "http://localhost:50000",
  credentials: true
}));
app.use(compression());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    success: true,
    message: 'AI Document Master API is running',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development',
    version: '1.0.0'
  });
});

// AI test endpoint
app.post('/api/ai/test', (req, res) => {
  res.json({
    success: true,
    message: 'AI endpoint working!',
    timestamp: new Date().toISOString(),
    gemini_key: process.env.GEMINI_API_KEY ? '✅ Configured' : '❌ Not configured'
  });
});

// Question generation endpoint
app.post('/api/ai/generate-questions', (req, res) => {
  const { documentContent, count = 3, difficulty = 'medium' } = req.body;
  
  if (!documentContent) {
    return res.status(400).json({
      success: false,
      message: 'Document content is required'
    });
  }

  // Mock questions for now
  const questions = [
    {
      question: "What is the main topic of this document?",
      answer: "The main topic is document analysis and AI processing.",
      type: "multiple_choice",
      options: ["AI Processing", "Document Analysis", "Text Recognition", "Image Enhancement"],
      correct_answer: 1,
      difficulty: difficulty,
      explanation: "The document primarily focuses on analyzing and processing documents."
    },
    {
      question: "Which technology is used for text extraction from images?",
      answer: "OCR (Optical Character Recognition) is used for text extraction.",
      type: "short_answer",
      difficulty: difficulty,
      explanation: "OCR technology converts image-based text into machine-readable text."
    }
  ];

  res.json({
    success: true,
    message: 'Questions generated successfully',
    questions: questions.slice(0, count),
    total: Math.min(count, questions.length),
    source: 'Mock Data',
    gemini_status: process.env.GEMINI_API_KEY ? '✅ Ready' : '❌ Not configured'
  });
});

// Start server
const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`🚀 AI Document Master API server running on port ${PORT}`);
  console.log(`📚 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🔗 Health check: http://localhost:${PORT}/health`);
  
  // Log AI service status
  if (process.env.GEMINI_API_KEY) {
    console.log('🔑 Gemini AI API: ✅ Configured');
  } else {
    console.log('🔑 Gemini AI API: ❌ Not configured');
  }
  
  if (process.env.OPENAI_API_KEY) {
    console.log('🤖 OpenAI API: ✅ Configured');
  } else {
    console.log('🤖 OpenAI API: ❌ Not configured');
  }
  
  console.log('🔥 Firebase: 🟡 Development Mode (Optional)');
  console.log('✨ Server ready for AI integration testing!');
});

module.exports = app;
