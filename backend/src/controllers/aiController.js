const { validationResult } = require('express-validator');
const { getPool } = require('../database/connection');
const logger = require('../utils/logger');
const { v4: uuidv4 } = require('uuid');

class AIController {
  constructor() {
    this.pool = getPool();
  }

  // Process document with AI services
  async processDocument(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          success: false,
          message: 'Validation failed',
          errors: errors.array()
        });
      }

      const { documentId, features, options } = req.body;
      const userId = req.user.userId;

      // Verify document ownership
      const documentResult = await this.pool.query(
        'SELECT * FROM documents WHERE id = $1 AND user_id = $2',
        [documentId, userId]
      );

      if (documentResult.rows.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'Document not found'
        });
      }

      const document = documentResult.rows[0];

      // Create processing job
      const jobId = uuidv4();
      const jobResult = await this.pool.query(
        `INSERT INTO processing_jobs (
          id, document_id, user_id, features, options, status, created_at, updated_at
        ) VALUES ($1, $2, $3, $4, $5, $6, NOW(), NOW())
        RETURNING *`,
        [
          jobId,
          documentId,
          userId,
          features || ['ocr'],
          options ? JSON.stringify(options) : '{}',
          'queued'
        ]
      );

      // Update document status
      await this.pool.query(
        'UPDATE documents SET status = $1, processing_progress = $2 WHERE id = $3',
        ['processing', 0, documentId]
      );

      // Start background processing
      this.startProcessing(jobId, documentId, features, options);

      logger.info(`AI processing started: ${jobId}`, { 
        userId, 
        documentId, 
        features,
        jobId 
      });

      res.json({
        success: true,
        message: 'Document processing started',
        jobId,
        status: 'queued'
      });

    } catch (error) {
      logger.error('AI processing failed:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  // Generate questions from document
  async generateQuestions(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          success: false,
          message: 'Validation failed',
          errors: errors.array()
        });
      }

      const { documentId, count, difficulty, types, language } = req.body;
      const userId = req.user.userId;

      // Verify document ownership
      const documentResult = await this.pool.query(
        'SELECT * FROM documents WHERE id = $1 AND user_id = $2',
        [documentId, userId]
      );

      if (documentResult.rows.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'Document not found'
        });
      }

      const document = documentResult.rows[0];

      // Check if document has been processed
      if (document.status !== 'completed') {
        return res.status(400).json({
          success: false,
          message: 'Document must be fully processed before generating questions'
        });
      }

      // Create question generation job
      const jobId = uuidv4();
      await this.pool.query(
        `INSERT INTO processing_jobs (
          id, document_id, user_id, job_type, features, options, status, created_at, updated_at
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, NOW(), NOW())`,
        [
          jobId,
          documentId,
          userId,
          'question_generation',
          ['question_generation'],
          JSON.stringify({
            count: count || 10,
            difficulty: difficulty || 'medium',
            types: types || ['mcq', 'short_answer'],
            language: language || 'en'
          }),
          'queued'
        ]
      );

      // Start question generation
      this.generateQuestionsFromDocument(jobId, documentId, {
        count: count || 10,
        difficulty: difficulty || 'medium',
        types: types || ['mcq', 'short_answer'],
        language: language || 'en'
      });

      logger.info(`Question generation started: ${jobId}`, { 
        userId, 
        documentId, 
        jobId,
        options: { count, difficulty, types, language }
      });

      res.json({
        success: true,
        message: 'Question generation started',
        jobId,
        status: 'queued'
      });

    } catch (error) {
      logger.error('Question generation failed:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  // Get processing status
  async getProcessingStatus(req, res) {
    try {
      const { jobId } = req.params;
      const userId = req.user.userId;

      const jobResult = await this.pool.query(
        `SELECT j.*, d.title as document_title
         FROM processing_jobs j
         JOIN documents d ON j.document_id = d.id
         WHERE j.id = $1 AND j.user_id = $2`,
        [jobId, userId]
      );

      if (jobResult.rows.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'Job not found'
        });
      }

      const job = jobResult.rows[0];

      res.json({
        success: true,
        job: {
          id: job.id,
          status: job.status,
          progress: job.progress || 0,
          result: job.result ? JSON.parse(job.result) : null,
          error: job.error_message,
          created_at: job.created_at,
          updated_at: job.updated_at,
          document_title: job.document_title
        }
      });

    } catch (error) {
      logger.error('Get processing status failed:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  // Get AI processing history
  async getProcessingHistory(req, res) {
    try {
      const userId = req.user.userId;
      const { page = 1, limit = 20, status } = req.query;

      let query = `
        SELECT j.*, d.title as document_title, d.type as document_type
        FROM processing_jobs j
        JOIN documents d ON j.document_id = d.id
        WHERE j.user_id = $1
      `;

      const queryParams = [userId];
      let paramCount = 1;

      if (status) {
        paramCount++;
        query += ` AND j.status = $${paramCount}`;
        queryParams.push(status);
      }

      // Add pagination
      const offset = (page - 1) * limit;
      paramCount++;
      query += ` ORDER BY j.created_at DESC LIMIT $${paramCount} OFFSET $${paramCount + 1}`;
      queryParams.push(limit, offset);

      const jobsResult = await this.pool.query(query, queryParams);

      // Get total count
      let countQuery = `
        SELECT COUNT(*) as total
        FROM processing_jobs j
        WHERE j.user_id = $1
      `;
      const countParams = [userId];

      if (status) {
        countQuery += ` AND j.status = $2`;
        countParams.push(status);
      }

      const countResult = await this.pool.query(countQuery, countParams);
      const total = parseInt(countResult.rows[0].total);

      res.json({
        success: true,
        jobs: jobsResult.rows.map(job => ({
          id: job.id,
          status: job.status,
          job_type: job.job_type,
          progress: job.progress || 0,
          document_title: job.document_title,
          document_type: job.document_type,
          created_at: job.created_at,
          updated_at: job.updated_at
        })),
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total,
          pages: Math.ceil(total / limit)
        }
      });

    } catch (error) {
      logger.error('Get processing history failed:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  // Start background processing
  async startProcessing(jobId, documentId, features, options) {
    try {
      // Update job status to processing
      await this.pool.query(
        'UPDATE processing_jobs SET status = $1, updated_at = NOW() WHERE id = $2',
        ['processing', jobId]
      );

      // Simulate processing steps
      const processingSteps = this.getProcessingSteps(features);
      let currentProgress = 0;

      for (const step of processingSteps) {
        // Update progress
        currentProgress += step.progress;
        await this.pool.query(
          'UPDATE processing_jobs SET progress = $1, updated_at = NOW() WHERE id = $2',
          [currentProgress, jobId]
        );

        // Simulate processing time
        await this.sleep(step.duration);

        // Update document progress
        await this.pool.query(
          'UPDATE documents SET processing_progress = $1 WHERE id = $2',
          [currentProgress, documentId]
        );
      }

      // Mark job as completed
      await this.pool.query(
        'UPDATE processing_jobs SET status = $1, result = $2, updated_at = NOW() WHERE id = $2',
        ['completed', JSON.stringify({ message: 'Processing completed successfully' }), jobId]
      );

      // Update document status
      await this.pool.query(
        'UPDATE documents SET status = $1, processing_progress = $2, updated_at = NOW() WHERE id = $3',
        ['completed', 100, documentId]
      );

      logger.info(`Processing completed: ${jobId}`, { jobId, documentId });

    } catch (error) {
      logger.error(`Processing failed: ${jobId}`, error);
      
      // Update job status to failed
      await this.pool.query(
        'UPDATE processing_jobs SET status = $1, error_message = $2, updated_at = NOW() WHERE id = $3',
        ['failed', error.message, jobId]
      );

      // Update document status
      await this.pool.query(
        'UPDATE documents SET status = $1, error_message = $2, updated_at = NOW() WHERE id = $3',
        ['failed', error.message, documentId]
      );
    }
  }

  // Generate questions from document
  async generateQuestionsFromDocument(jobId, documentId, options) {
    try {
      // Update job status to processing
      await this.pool.query(
        'UPDATE processing_jobs SET status = $1, updated_at = NOW() WHERE id = $2',
        ['processing', jobId]
      );

      // Simulate question generation
      await this.sleep(2000); // 2 seconds

      // Generate sample questions
      const questions = this.generateSampleQuestions(options);

      // Store questions in database
      for (const question of questions) {
        await this.pool.query(
          `INSERT INTO questions (
            document_id, question_text, question_type, difficulty, options, correct_answer,
            explanation, language, created_at
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW())`,
          [
            documentId,
            question.question_text,
            question.question_type,
            question.difficulty,
            JSON.stringify(question.options),
            question.correct_answer,
            question.explanation,
            question.language
          ]
        );
      }

      // Mark job as completed
      await this.pool.query(
        'UPDATE processing_jobs SET status = $1, result = $2, updated_at = NOW() WHERE id = $3',
        ['completed', JSON.stringify({ questions_generated: questions.length }), jobId]
      );

      logger.info(`Question generation completed: ${jobId}`, { 
        jobId, 
        documentId, 
        questionsGenerated: questions.length 
      });

    } catch (error) {
      logger.error(`Question generation failed: ${jobId}`, error);
      
      // Update job status to failed
      await this.pool.query(
        'UPDATE processing_jobs SET status = $1, error_message = $2, updated_at = NOW() WHERE id = $3',
        ['failed', error.message, jobId]
      );
    }
  }

  // Get processing steps based on features
  getProcessingSteps(features) {
    const steps = [];
    
    if (features.includes('ocr')) {
      steps.push({ name: 'OCR Processing', progress: 30, duration: 1000 });
    }
    
    if (features.includes('hwr')) {
      steps.push({ name: 'Handwriting Recognition', progress: 25, duration: 1500 });
    }
    
    if (features.includes('text_extraction')) {
      steps.push({ name: 'Text Extraction', progress: 20, duration: 800 });
    }
    
    if (features.includes('language_detection')) {
      steps.push({ name: 'Language Detection', progress: 15, duration: 500 });
    }
    
    steps.push({ name: 'Final Processing', progress: 10, duration: 700 });
    
    return steps;
  }

  // Generate sample questions
  generateSampleQuestions(options) {
    const questions = [];
    const { count, difficulty, types, language } = options;

    for (let i = 0; i < count; i++) {
      const questionType = types[Math.floor(Math.random() * types.length)];
      
      if (questionType === 'mcq') {
        questions.push({
          question_text: `Sample MCQ question ${i + 1}?`,
          question_type: 'mcq',
          difficulty: difficulty,
          options: [
            'Option A',
            'Option B', 
            'Option C',
            'Option D'
          ],
          correct_answer: 'Option A',
          explanation: 'This is the correct answer because...',
          language: language
        });
      } else if (questionType === 'short_answer') {
        questions.push({
          question_text: `Sample short answer question ${i + 1}?`,
          question_type: 'short_answer',
          difficulty: difficulty,
          options: [],
          correct_answer: 'Sample answer',
          explanation: 'This is the expected answer...',
          language: language
        });
      }
    }

    return questions;
  }

  // Utility method for sleep
  sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}

module.exports = new AIController();
