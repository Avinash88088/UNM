const winston = require('winston');
const path = require('path');
const fs = require('fs');

// Create logs directory if it doesn't exist
const logsDir = process.env.LOG_FILE_PATH || './logs';
if (!fs.existsSync(logsDir)) {
    fs.mkdirSync(logsDir, { recursive: true });
}

// Define log format
const logFormat = winston.format.combine(
    winston.format.timestamp({
        format: 'YYYY-MM-DD HH:mm:ss'
    }),
    winston.format.errors({ stack: true }),
    winston.format.json()
);

// Define console format for development
const consoleFormat = winston.format.combine(
    winston.format.colorize(),
    winston.format.timestamp({
        format: 'HH:mm:ss'
    }),
    winston.format.printf(({ timestamp, level, message, ...meta }) => {
        let log = `${timestamp} [${level}]: ${message}`;
        if (Object.keys(meta).length > 0) {
            log += ` ${JSON.stringify(meta)}`;
        }
        return log;
    })
);

// Create logger instance
const logger = winston.createLogger({
    level: process.env.LOG_LEVEL || 'info',
    format: logFormat,
    defaultMeta: { 
        service: 'ai-document-master',
        environment: process.env.NODE_ENV || 'development'
    },
    transports: [
        // Error log file
        new winston.transports.File({
            filename: path.join(logsDir, 'error.log'),
            level: 'error',
            maxsize: 5242880, // 5MB
            maxFiles: 5,
        }),
        // Combined log file
        new winston.transports.File({
            filename: path.join(logsDir, 'combined.log'),
            maxsize: 5242880, // 5MB
            maxFiles: 5,
        }),
        // Access log file
        new winston.transports.File({
            filename: path.join(logsDir, 'access.log'),
            level: 'info',
            maxsize: 5242880, // 5MB
            maxFiles: 5,
        })
    ],
    exceptionHandlers: [
        new winston.transports.File({
            filename: path.join(logsDir, 'exceptions.log')
        })
    ],
    rejectionHandlers: [
        new winston.transports.File({
            filename: path.join(logsDir, 'rejections.log')
        })
    ]
});

// Add console transport for development
if (process.env.NODE_ENV !== 'production') {
    logger.add(new winston.transports.Console({
        format: consoleFormat
    }));
}

// Create a stream object for Morgan HTTP logging
logger.stream = {
    write: (message) => {
        logger.info(message.trim());
    }
};

// Helper methods for different log levels
logger.startup = (message, meta = {}) => {
    logger.info(`🚀 ${message}`, { ...meta, type: 'startup' });
};

logger.database = (message, meta = {}) => {
    logger.info(`🗄️ ${message}`, { ...meta, type: 'database' });
};

logger.api = (message, meta = {}) => {
    logger.info(`🔌 ${message}`, { ...meta, type: 'api' });
};

logger.ai = (message, meta = {}) => {
    logger.info(`🤖 ${message}`, { ...meta, type: 'ai' });
};

logger.security = (message, meta = {}) => {
    logger.warn(`🔒 ${message}`, { ...meta, type: 'security' });
};

logger.performance = (message, meta = {}) => {
    logger.info(`⚡ ${message}`, { ...meta, type: 'performance' });
};

// Error logging with context
logger.errorWithContext = (error, context = {}) => {
    logger.error(error.message, {
        stack: error.stack,
        name: error.name,
        context,
        type: 'error'
    });
};

// Request logging
logger.logRequest = (req, res, responseTime) => {
    const logData = {
        method: req.method,
        url: req.url,
        statusCode: res.statusCode,
        responseTime: `${responseTime}ms`,
        userAgent: req.get('User-Agent'),
        ip: req.ip,
        userId: req.user?.id || 'anonymous'
    };

    if (res.statusCode >= 400) {
        logger.warn('HTTP Request', logData);
    } else {
        logger.api('HTTP Request', logData);
    }
};

module.exports = logger;
