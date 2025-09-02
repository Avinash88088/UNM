const { Pool } = require('pg');
const logger = require('../utils/logger');

let pool;

const createPool = () => {
    const config = {
        user: process.env.DB_USER || 'postgres',
        host: process.env.DB_HOST || 'localhost',
        database: process.env.DB_NAME || 'udm',
        password: process.env.DB_PASSWORD || 'password',
        port: process.env.DB_PORT || 5432,
        ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
        max: 20, // Maximum number of clients in the pool
        idleTimeoutMillis: 30000, // Close idle clients after 30 seconds
        connectionTimeoutMillis: 2000, // Return an error after 2 seconds if connection could not be established
    };

    return new Pool(config);
};

const connectDB = async () => {
    try {
        if (!pool) {
            pool = createPool();
        }

        // Test the connection
        const client = await pool.connect();
        logger.info('✅ PostgreSQL database connected successfully');
        client.release();

        // Handle pool errors
        pool.on('error', (err) => {
            logger.error('Unexpected error on idle client', err);
            process.exit(-1);
        });

        return pool;
    } catch (error) {
        logger.error('❌ Database connection failed:', error.message);
        process.exit(1);
    }
};

const getPool = () => {
    if (!pool) {
        throw new Error('Database not connected. Call connectDB() first.');
    }
    return pool;
};

const closeDB = async () => {
    if (pool) {
        await pool.end();
        logger.info('Database connection closed');
    }
};

// Graceful shutdown
process.on('SIGINT', async () => {
    await closeDB();
    process.exit(0);
});

process.on('SIGTERM', async () => {
    await closeDB();
    process.exit(0);
});

module.exports = {
    connectDB,
    getPool,
    closeDB
};
