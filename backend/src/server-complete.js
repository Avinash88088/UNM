// Load environment variables
require('dotenv').config();

const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
const logger = require('./utils/logger');

// Import routes
const aiRoutes = require('./routes/ai-simple');
const authRoutes = require('./routes/auth-unified');

// Import middleware
const { authenticateToken } = require('./middleware/auth-simple');

// Import AI controller for status check
const aiController = require('./controllers/aiController-enhanced');

const app = express();
const PORT = process.env.PORT || 3000;

// Request timing middleware
app.use((req, res, next) => {
  req.startTime = Date.now();
  next();
});

// Security middleware
app.use(helmet());
app.use(cors({
  origin: process.env.FRONTEND_URL || 'http://localhost:50000',
  credentials: true
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.'
});
app.use('/api/', limiter);

// Body parsing middleware
app.use(compression());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Health check endpoint
app.get('/health', (req, res) => {
  const responseTime = Date.now() - req.startTime;
  
  res.json({
    message: 'AI Document Master API is running',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    responseTime: `${responseTime}ms`,
    environment: process.env.NODE_ENV || 'development',
    services: {
      gemini: aiController.geminiApiKey ? '✅ Configured' : '❌ Not Configured',
      openai: process.env.OPENAI_API_KEY ? '✅ Configured' : '❌ Not Configured',
      firebase: process.env.FIREBASE_SERVICE_ACCOUNT_KEY ? '✅ Configured' : '🟡 Development Mode'
    }
  });
});

// AI test endpoint
app.post('/api/ai/test', (req, res) => {
  res.json({
    message: 'AI services status',
    gemini_key: aiController.geminiApiKey ? '✅ Configured' : '❌ Not Configured',
    openai_key: process.env.OPENAI_API_KEY ? '✅ Configured' : '❌ Not Configured',
    firebase_key: process.env.FIREBASE_SERVICE_ACCOUNT_KEY ? '✅ Configured' : '🟡 Development Mode'
  });
});

// API routes
app.use('/api/ai', aiRoutes);
app.use('/api/auth', authRoutes);

// Protected route example
app.get('/api/protected', authenticateToken, (req, res) => {
  res.json({
    message: 'This is a protected route',
    user: req.user,
    timestamp: new Date().toISOString()
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    message: `Route ${req.originalUrl} not found`
  });
});

// Error handling middleware
app.use((error, req, res, next) => {
  const responseTime = Date.now() - req.startTime;
  
  logger.error('Unhandled error:', {
    error: error.message,
    stack: error.stack,
    url: req.url,
    method: req.method,
    responseTime: `${responseTime}ms`
  });

  res.status(error.status || 500).json({
    success: false,
    message: error.message || 'Internal server error',
    ...(process.env.NODE_ENV === 'development' && { stack: error.stack })
  });
});

// Start server
app.listen(PORT, () => {
  logger.info(`🚀 Server running on port ${PORT}`);
  logger.info(`🌐 Environment: ${process.env.NODE_ENV || 'development'}`);
  logger.info(`🔑 Gemini API: ${aiController.geminiApiKey ? '✅ Configured' : '❌ Not Configured'}`);
  logger.info(`🤖 OpenAI API: ${process.env.OPENAI_API_KEY ? '✅ Configured' : '❌ Not Configured'}`);
  logger.info(`🔥 Firebase: ${process.env.FIREBASE_SERVICE_ACCOUNT_KEY ? '✅ Configured' : '🟡 Development Mode'}`);
  
  console.log('\n📋 Available Endpoints:');
  console.log('   GET  /health                    - Health check');
  console.log('   POST /api/ai/test               - AI services test');
  console.log('   POST /api/ai/generate-questions - Generate questions');
  console.log('   POST /api/ai/generate-summary   - Generate summary');
  console.log('   POST /api/ai/ocr                - OCR processing');
  console.log('   POST /api/ai/handwriting        - Handwriting recognition');
  console.log('   POST /api/auth/register         - User registration');
  console.log('   POST /api/auth/login            - User login');
  console.log('   POST /api/auth/firebase         - Firebase authentication');
  console.log('   POST /api/auth/refresh          - Refresh token');
  console.log('   GET  /api/auth/me               - Get current user');
  console.log('   POST /api/auth/logout           - User logout');
  console.log('   GET  /api/auth/test-users       - Get test users (dev)');
  console.log('   GET  /api/protected             - Protected route example');
  console.log('');
});

module.exports = app;
