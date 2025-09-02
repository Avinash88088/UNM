const redis = require('redis');
const logger = require('../utils/logger');

let redisClient;

const connectRedis = async () => {
    try {
        redisClient = redis.createClient({
            socket: {
                host: process.env.REDIS_HOST || 'localhost',
                port: process.env.REDIS_PORT || 6379,
            },
            password: process.env.REDIS_PASSWORD || undefined,
            database: process.env.REDIS_DB || 0,
        });

        redisClient.on('error', (err) => {
            logger.error('Redis Client Error:', err);
        });

        redisClient.on('connect', () => {
            logger.info('✅ Redis connected successfully');
        });

        redisClient.on('ready', () => {
            logger.info('✅ Redis ready to accept commands');
        });

        redisClient.on('end', () => {
            logger.info('Redis connection ended');
        });

        await redisClient.connect();
        return redisClient;
    } catch (error) {
        logger.error('❌ Redis connection failed:', error.message);
        // Don't exit process for Redis connection failure
        // Redis is not critical for basic functionality
        return null;
    }
};

const getRedisClient = () => {
    if (!redisClient) {
        throw new Error('Redis not connected. Call connectRedis() first.');
    }
    return redisClient;
};

const closeRedis = async () => {
    if (redisClient) {
        await redisClient.quit();
        logger.info('Redis connection closed');
    }
};

// Graceful shutdown
process.on('SIGINT', async () => {
    await closeRedis();
});

process.on('SIGTERM', async () => {
    await closeRedis();
});

module.exports = {
    connectRedis,
    getRedisClient,
    closeRedis
};
