const logger = require('../utils/logger');

// Custom error class
class AppError extends Error {
    constructor(message, statusCode, isOperational = true) {
        super(message);
        this.statusCode = statusCode;
        this.isOperational = isOperational;
        this.status = `${statusCode}`.startsWith('4') ? 'fail' : 'error';
        
        Error.captureStackTrace(this, this.constructor);
    }
}

// Error handler middleware
const errorHandler = (err, req, res, next) => {
    let error = { ...err };
    error.message = err.message;

    // Log error
    logger.errorWithContext(err, {
        url: req.url,
        method: req.method,
        userId: req.user?.id || 'anonymous',
        ip: req.ip
    });

    // Mongoose bad ObjectId
    if (err.name === 'CastError') {
        const message = 'Resource not found';
        error = new AppError(message, 404);
    }

    // Mongoose duplicate key
    if (err.code === 11000) {
        const field = Object.keys(err.keyValue)[0];
        const message = `Duplicate field value: ${field}. Please use another value.`;
        error = new AppError(message, 400);
    }

    // Mongoose validation error
    if (err.name === 'ValidationError') {
        const message = Object.values(err.errors).map(val => val.message).join(', ');
        error = new AppError(message, 400);
    }

    // JWT errors
    if (err.name === 'JsonWebTokenError') {
        const message = 'Invalid token. Please log in again.';
        error = new AppError(message, 401);
    }

    if (err.name === 'TokenExpiredError') {
        const message = 'Token expired. Please log in again.';
        error = new AppError(message, 401);
    }

    // File upload errors
    if (err.code === 'LIMIT_FILE_SIZE') {
        const message = 'File too large. Please upload a smaller file.';
        error = new AppError(message, 400);
    }

    if (err.code === 'LIMIT_UNEXPECTED_FILE') {
        const message = 'Unexpected file field.';
        error = new AppError(message, 400);
    }

    // AWS S3 errors
    if (err.code === 'NoSuchBucket') {
        const message = 'Storage bucket not found.';
        error = new AppError(message, 500);
    }

    if (err.code === 'AccessDenied') {
        const message = 'Access denied to storage.';
        error = new AppError(message, 500);
    }

    // AI service errors
    if (err.code === 'AI_SERVICE_ERROR') {
        const message = 'AI service temporarily unavailable.';
        error = new AppError(message, 503);
    }

    // Database connection errors
    if (err.code === 'ECONNREFUSED') {
        const message = 'Database connection failed.';
        error = new AppError(message, 503);
    }

    // Redis connection errors
    if (err.code === 'ECONNREFUSED' && err.syscall === 'connect') {
        const message = 'Cache service unavailable.';
        error = new AppError(message, 503);
    }

    // Default error
    const statusCode = error.statusCode || 500;
    const message = error.message || 'Internal Server Error';

    // Development error response
    if (process.env.NODE_ENV === 'development') {
        res.status(statusCode).json({
            success: false,
            error: {
                message,
                statusCode,
                stack: err.stack,
                details: error
            }
        });
    } else {
        // Production error response
        if (error.isOperational) {
            res.status(statusCode).json({
                success: false,
                error: {
                    message,
                    statusCode
                }
            });
        } else {
            // Programming or unknown errors
            logger.error('Programming error:', err);
            res.status(500).json({
                success: false,
                error: {
                    message: 'Something went wrong',
                    statusCode: 500
                }
            });
        }
    }
};

// Async error wrapper
const asyncHandler = (fn) => {
    return (req, res, next) => {
        Promise.resolve(fn(req, res, next)).catch(next);
    };
};

// Not found middleware
const notFound = (req, res, next) => {
    const error = new AppError(`Route ${req.originalUrl} not found`, 404);
    next(error);
};

// Validation error handler
const handleValidationError = (err) => {
    const errors = Object.values(err.errors).map(el => el.message);
    const message = `Invalid input data. ${errors.join('. ')}`;
    return new AppError(message, 400);
};

// Cast error handler
const handleCastError = (err) => {
    const message = `Invalid ${err.path}: ${err.value}`;
    return new AppError(message, 400);
};

// Duplicate key error handler
const handleDuplicateKeyError = (err) => {
    const value = err.errmsg.match(/(["'])(\\?.)*?\1/)[0];
    const message = `Duplicate field value: ${value}. Please use another value.`;
    return new AppError(message, 400);
};

// JWT error handler
const handleJWTError = () => {
    return new AppError('Invalid token. Please log in again.', 401);
};

// JWT expired error handler
const handleJWTExpiredError = () => {
    return new AppError('Token expired. Please log in again.', 401);
};

// Request timing middleware
const requestTimer = (req, res, next) => {
  req.startTime = Date.now();
  next();
};

module.exports = {
    AppError,
    errorHandler,
    asyncHandler,
    notFound,
    handleValidationError,
    handleCastError,
    handleDuplicateKeyError,
    handleJWTError,
    handleJWTExpiredError,
    requestTimer
};
