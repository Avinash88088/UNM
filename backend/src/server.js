// Load environment variables
require('dotenv').config();

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const compression = require('compression');
const morgan = require('morgan');
const path = require('path');

// Import middleware
const errorHandler = require('./middleware/errorHandler');
const { handleUploadError } = require('./middleware/upload');

// Import routes
const authRoutes = require('./routes/auth-simple');
const documentRoutes = require('./routes/documents-simple');
const aiRoutes = require('./routes/ai-simple');

// Import services
const { initializeFirebaseAdmin } = require('./config/firebase-admin');
const logger = require('./utils/logger');

// Import Socket.io
const { createServer } = require('http');
const { Server } = require('socket.io');

const app = express();
const server = createServer(app);

// Initialize Socket.io
const io = new Server(server, {
  cors: {
    origin: process.env.FRONTEND_URL || "http://localhost:3000",
    methods: ["GET", "POST"]
  }
});

// Security middleware
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
    },
  },
}));

// CORS configuration
app.use(cors({
  origin: process.env.FRONTEND_URL || "http://localhost:3000",
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: {
    success: false,
    message: 'Too many requests from this IP, please try again later.'
  },
  standardHeaders: true,
  legacyHeaders: false,
});

app.use('/api/', limiter);

// More strict rate limiting for auth routes
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // limit each IP to 5 requests per windowMs
  message: {
    success: false,
    message: 'Too many authentication attempts, please try again later.'
  },
  standardHeaders: true,
  legacyHeaders: false,
});

app.use('/api/auth/', authLimiter);

// Compression middleware
app.use(compression());

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Logging middleware
if (process.env.NODE_ENV === 'development') {
  app.use(morgan('dev'));
} else {
  app.use(morgan('combined'));
}

// Static file serving
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));
app.use('/public', express.static(path.join(__dirname, '../public')));

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    success: true,
    message: 'AI Document Master API is running',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development',
    version: process.env.npm_package_version || '1.0.0'
  });
});

// API routes
app.use('/api/auth', authRoutes);
app.use('/api/documents', documentRoutes);
app.use('/api/ai', aiRoutes);

// Handle upload errors
app.use(handleUploadError);

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    message: `Route ${req.originalUrl} not found`
  });
});

// Error handling middleware (must be last)
app.use(errorHandler);

// Socket.io connection handling
io.on('connection', (socket) => {
  logger.info(`Socket connected: ${socket.id}`);

  // Join user's personal room
  socket.on('join-user-room', (data) => {
    if (data.userId) {
      socket.join(`user-${data.userId}`);
      logger.info(`User ${data.userId} joined personal room`);
    }
  });

  // Join document room
  socket.on('join-document', (data) => {
    if (data.documentId) {
      socket.join(`document-${data.documentId}`);
      logger.info(`Socket ${socket.id} joined document room: ${data.documentId}`);
    }
  });

  // Leave document room
  socket.on('leave-document', (data) => {
    if (data.documentId) {
      socket.leave(`document-${data.documentId}`);
      logger.info(`Socket ${socket.id} left document room: ${data.documentId}`);
    }
  });

  // Handle document processing updates
  socket.on('request-document-status', (data) => {
    // This would typically query the database and emit back
    socket.emit('processing-update', {
      documentId: data.documentId,
      status: 'processing',
      progress: 50
    });
  });

  // Handle disconnection
  socket.on('disconnect', () => {
    logger.info(`Socket disconnected: ${socket.id}`);
  });

  // Handle errors
  socket.on('error', (error) => {
    logger.error(`Socket error: ${error.message}`);
  });
});

// Graceful shutdown
const gracefulShutdown = (signal) => {
  logger.info(`Received ${signal}. Starting graceful shutdown...`);
  
  server.close(() => {
    logger.info('HTTP server closed');
    process.exit(0);
  });

  // Force close after 30 seconds
  setTimeout(() => {
    logger.error('Could not close connections in time, forcefully shutting down');
    process.exit(1);
  }, 30000);
};

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

// Initialize services and start server
const startServer = async () => {
  try {
    // Initialize Firebase Admin SDK (optional in development)
    try {
      await initializeFirebaseAdmin();
      logger.info('Firebase Admin SDK initialized successfully');
    } catch (firebaseError) {
      if (process.env.NODE_ENV === 'development') {
        logger.warn('Firebase initialization failed, continuing in development mode');
      } else {
        throw firebaseError;
      }
    }

    // Start server
    const PORT = process.env.PORT || 3000;
    server.listen(PORT, () => {
      logger.info(`🚀 AI Document Master API server running on port ${PORT}`);
      logger.info(`📚 Environment: ${process.env.NODE_ENV || 'development'}`);
      logger.info(`🔗 Health check: http://localhost:${PORT}/health`);
      logger.info(`📖 API Documentation: http://localhost:${PORT}/api-docs`);
      
      // Log AI service status
      if (process.env.GEMINI_API_KEY) {
        logger.info('🔑 Gemini AI API: ✅ Configured');
      } else {
        logger.warn('🔑 Gemini AI API: ❌ Not configured');
      }
      
      if (process.env.OPENAI_API_KEY) {
        logger.info('🤖 OpenAI API: ✅ Configured');
      } else {
        logger.warn('🤖 OpenAI API: ❌ Not configured');
      }
      
      if (process.env.GOOGLE_CLOUD_PROJECT_ID) {
        logger.info('👁️ Google Cloud Vision: ✅ Configured');
      } else {
        logger.warn('👁️ Google Cloud Vision: ❌ Not configured');
      }
      
      logger.info(`🔥 Firebase: ${process.env.NODE_ENV === 'development' ? '🟡 Development Mode' : '✅ Production Mode'}`);
    });

  } catch (error) {
    logger.error('Failed to start server:', error);
    process.exit(1);
  }
};

// Start the server
startServer();

module.exports = { app, server, io };
