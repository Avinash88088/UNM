const { validationResult } = require('express-validator');
const { getPool } = require('../database/connection');
const logger = require('../utils/logger');
const { v4: uuidv4 } = require('uuid');
const path = require('path');
const fs = require('fs').promises;

class DocumentController {
  constructor() {
    this.pool = getPool();
  }

  // Get all documents for current user
  async getDocuments(req, res) {
    try {
      const userId = req.user.userId;
      const { page = 1, limit = 20, status, type, search } = req.query;

      let query = `
        SELECT d.id, d.title, d.description, d.status, d.type, d.language, 
               d.page_count, d.file_size, d.ocr_confidence, d.created_at, d.updated_at,
               u.name as uploaded_by, i.name as institution_name
        FROM documents d
        LEFT JOIN users u ON d.user_id = u.id
        LEFT JOIN institutions i ON d.institution_id = i.id
        WHERE d.user_id = $1
      `;

      const queryParams = [userId];
      let paramCount = 1;

      if (status) {
        paramCount++;
        query += ` AND d.status = $${paramCount}`;
        queryParams.push(status);
      }

      if (type) {
        paramCount++;
        query += ` AND d.type = $${paramCount}`;
        queryParams.push(type);
      }

      if (search) {
        paramCount++;
        query += ` AND (d.title ILIKE $${paramCount} OR d.description ILIKE $${paramCount})`;
        queryParams.push(`%${search}%`);
      }

      // Add pagination
      const offset = (page - 1) * limit;
      paramCount++;
      query += ` ORDER BY d.created_at DESC LIMIT $${paramCount} OFFSET $${paramCount + 1}`;
      queryParams.push(limit, offset);

      const documentsResult = await this.pool.query(query, queryParams);

      // Get total count for pagination
      let countQuery = `
        SELECT COUNT(*) as total
        FROM documents d
        WHERE d.user_id = $1
      `;
      const countParams = [userId];

      if (status) {
        countQuery += ` AND d.status = $2`;
        countParams.push(status);
      }

      if (type) {
        countQuery += ` AND d.type = $${countParams.length + 1}`;
        countParams.push(type);
      }

      if (search) {
        countQuery += ` AND (d.title ILIKE $${countParams.length + 1} OR d.description ILIKE $${countParams.length + 1})`;
        countParams.push(`%${search}%`);
      }

      const countResult = await this.pool.query(countQuery, countParams);
      const total = parseInt(countResult.rows[0].total);

      res.json({
        success: true,
        documents: documentsResult.rows,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total,
          pages: Math.ceil(total / limit)
        }
      });

    } catch (error) {
      logger.error('Get documents failed:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  // Get a specific document by ID
  async getDocument(req, res) {
    try {
      const { documentId } = req.params;
      const userId = req.user.userId;

      const documentResult = await this.pool.query(
        `SELECT d.*, u.name as uploaded_by, i.name as institution_name
         FROM documents d
         LEFT JOIN users u ON d.user_id = u.id
         LEFT JOIN institutions i ON d.institution_id = i.id
         WHERE d.id = $1 AND d.user_id = $2`,
        [documentId, userId]
      );

      if (documentResult.rows.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'Document not found'
        });
      }

      const document = documentResult.rows[0];

      // Get document pages if they exist
      const pagesResult = await this.pool.query(
        'SELECT * FROM document_pages WHERE document_id = $1 ORDER BY page_number',
        [documentId]
      );

      document.pages = pagesResult.rows;

      res.json({
        success: true,
        document
      });

    } catch (error) {
      logger.error('Get document failed:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  // Upload a new document
  async uploadDocument(req, res) {
    try {
      if (!req.file) {
        return res.status(400).json({
          success: false,
          message: 'No file uploaded'
        });
      }

      const { title, description, language, features, processingOptions } = req.body;
      const userId = req.user.userId;

      // Get user's institution
      const userResult = await this.pool.query(
        'SELECT institution_id FROM users WHERE id = $1',
        [userId]
      );

      if (userResult.rows.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'User not found'
        });
      }

      const institutionId = userResult.rows[0].institution_id;

      // Generate unique filename
      const fileExtension = path.extname(req.file.originalname);
      const fileName = `${uuidv4()}${fileExtension}`;
      const filePath = path.join(process.env.UPLOAD_PATH || 'uploads', fileName);

      // Move file to uploads directory
      await fs.rename(req.file.path, filePath);

      // Get file stats
      const fileStats = await fs.stat(filePath);
      const fileSize = fileStats.size;

      // Determine document type based on file extension
      const documentType = this.getDocumentType(fileExtension);

      // Create document record
      const documentResult = await this.pool.query(
        `INSERT INTO documents (
          title, description, language, type, status, file_path, file_size, 
          original_filename, user_id, institution_id, features, processing_options,
          created_at, updated_at
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, NOW(), NOW())
        RETURNING *`,
        [
          title,
          description || '',
          language || 'en',
          documentType,
          'uploaded',
          filePath,
          fileSize,
          req.file.originalname,
          userId,
          institutionId,
          features ? features.split(',') : ['ocr'],
          processingOptions ? JSON.parse(processingOptions) : {}
        ]
      );

      const document = documentResult.rows[0];

      // If features include OCR, start processing
      if (features && features.includes('ocr')) {
        // This would trigger background processing
        // For now, we'll just update the status
        await this.pool.query(
          'UPDATE documents SET status = $1 WHERE id = $2',
          ['processing', document.id]
        );
      }

      logger.info(`Document uploaded successfully: ${document.id}`, { 
        userId, 
        documentId: document.id,
        fileName: req.file.originalname 
      });

      res.status(201).json({
        success: true,
        message: 'Document uploaded successfully',
        document: {
          id: document.id,
          title: document.title,
          description: document.description,
          status: document.status,
          type: document.type,
          language: document.language,
          file_size: document.file_size,
          created_at: document.created_at,
          updated_at: document.updated_at
        }
      });

    } catch (error) {
      logger.error('Document upload failed:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  // Update document metadata
  async updateDocument(req, res) {
    try {
      const { documentId } = req.params;
      const userId = req.user.userId;
      const { title, description, language, metadata } = req.body;

      // Check if document exists and belongs to user
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

      // Build update query dynamically
      const updateFields = [];
      const updateValues = [];
      let paramCount = 0;

      if (title !== undefined) {
        paramCount++;
        updateFields.push(`title = $${paramCount}`);
        updateValues.push(title);
      }

      if (description !== undefined) {
        paramCount++;
        updateFields.push(`description = $${paramCount}`);
        updateValues.push(description);
      }

      if (language !== undefined) {
        paramCount++;
        updateFields.push(`language = $${paramCount}`);
        updateValues.push(language);
      }

      if (metadata !== undefined) {
        paramCount++;
        updateFields.push(`metadata = $${paramCount}`);
        updateValues.push(JSON.stringify(metadata));
      }

      if (updateFields.length === 0) {
        return res.status(400).json({
          success: false,
          message: 'No fields to update'
        });
      }

      // Add updated_at and document ID to values
      paramCount++;
      updateFields.push(`updated_at = NOW()`);
      updateValues.push(documentId);

      const updateQuery = `
        UPDATE documents 
        SET ${updateFields.join(', ')}
        WHERE id = $${paramCount}
        RETURNING *
      `;

      const updatedDocument = await this.pool.query(updateQuery, updateValues);

      logger.info(`Document updated: ${documentId}`, { userId, documentId });

      res.json({
        success: true,
        message: 'Document updated successfully',
        document: updatedDocument.rows[0]
      });

    } catch (error) {
      logger.error('Document update failed:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  // Delete a document
  async deleteDocument(req, res) {
    try {
      const { documentId } = req.params;
      const userId = req.user.userId;

      // Check if document exists and belongs to user
      const documentResult = await this.pool.query(
        'SELECT file_path FROM documents WHERE id = $1 AND user_id = $2',
        [documentId, userId]
      );

      if (documentResult.rows.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'Document not found'
        });
      }

      const document = documentResult.rows[0];

      // Delete file from filesystem
      try {
        await fs.unlink(document.file_path);
      } catch (fileError) {
        logger.warn(`Failed to delete file: ${document.file_path}`, fileError);
        // Continue with database deletion even if file deletion fails
      }

      // Delete document pages
      await this.pool.query(
        'DELETE FROM document_pages WHERE document_id = $1',
        [documentId]
      );

      // Delete document
      await this.pool.query(
        'DELETE FROM documents WHERE id = $1',
        [documentId]
      );

      logger.info(`Document deleted: ${documentId}`, { userId, documentId });

      res.json({
        success: true,
        message: 'Document deleted successfully'
      });

    } catch (error) {
      logger.error('Document deletion failed:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  // Get document processing status
  async getProcessingStatus(req, res) {
    try {
      const { documentId } = req.params;
      const userId = req.user.userId;

      const documentResult = await this.pool.query(
        'SELECT status, processing_progress, error_message FROM documents WHERE id = $1 AND user_id = $2',
        [documentId, userId]
      );

      if (documentResult.rows.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'Document not found'
        });
      }

      const document = documentResult.rows[0];

      res.json({
        success: true,
        status: document.status,
        progress: document.processing_progress || 0,
        error: document.error_message || null
      });

    } catch (error) {
      logger.error('Get processing status failed:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  // Get document pages
  async getDocumentPages(req, res) {
    try {
      const { documentId } = req.params;
      const userId = req.user.userId;

      // Verify document ownership
      const documentResult = await this.pool.query(
        'SELECT id FROM documents WHERE id = $1 AND user_id = $2',
        [documentId, userId]
      );

      if (documentResult.rows.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'Document not found'
        });
      }

      const pagesResult = await this.pool.query(
        'SELECT * FROM document_pages WHERE document_id = $1 ORDER BY page_number',
        [documentId]
      );

      res.json({
        success: true,
        pages: pagesResult.rows
      });

    } catch (error) {
      logger.error('Get document pages failed:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  // Get shared documents
  async getSharedDocuments(req, res) {
    try {
      const userId = req.user.userId;

      const sharedDocumentsResult = await this.pool.query(
        `SELECT d.*, u.name as owner_name, i.name as institution_name
         FROM documents d
         JOIN document_sharing ds ON d.id = ds.document_id
         JOIN users u ON d.user_id = u.id
         LEFT JOIN institutions i ON d.institution_id = i.id
         WHERE ds.shared_with_user_id = $1 AND ds.expires_at > NOW()
         ORDER BY d.created_at DESC`,
        [userId]
      );

      res.json({
        success: true,
        documents: sharedDocumentsResult.rows
      });

    } catch (error) {
      logger.error('Get shared documents failed:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  // Share document with other users
  async shareDocument(req, res) {
    try {
      const { documentId } = req.params;
      const userId = req.user.userId;
      const { userEmails, permission, expiresAt } = req.body;

      // Verify document ownership
      const documentResult = await this.pool.query(
        'SELECT id FROM documents WHERE id = $1 AND user_id = $2',
        [documentId, userId]
      );

      if (documentResult.rows.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'Document not found'
        });
      }

      // Find users by email
      const usersResult = await this.pool.query(
        'SELECT id FROM users WHERE email = ANY($1)',
        [userEmails]
      );

      if (usersResult.rows.length === 0) {
        return res.status(400).json({
          success: false,
          message: 'No valid users found'
        });
      }

      // Create sharing records
      const sharingValues = usersResult.rows.map(user => [
        documentId,
        user.id,
        userId,
        permission || 'read',
        expiresAt ? new Date(expiresAt) : new Date(Date.now() + 30 * 24 * 60 * 60 * 1000) // 30 days default
      ]);

      await this.pool.query(
        `INSERT INTO document_sharing (
          document_id, shared_with_user_id, shared_by_user_id, permission, expires_at
        ) VALUES ${sharingValues.map((_, index) => 
          `($${index * 5 + 1}, $${index * 5 + 2}, $${index * 5 + 3}, $${index * 5 + 4}, $${index * 5 + 5})`
        ).join(', ')}`,
        sharingValues.flat()
      );

      logger.info(`Document shared: ${documentId}`, { 
        userId, 
        documentId, 
        sharedWith: usersResult.rows.length 
      });

      res.json({
        success: true,
        message: `Document shared with ${usersResult.rows.length} users`
      });

    } catch (error) {
      logger.error('Share document failed:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  // Helper method to determine document type
  getDocumentType(fileExtension) {
    const extension = fileExtension.toLowerCase();
    
    if (['.pdf'].includes(extension)) return 'pdf';
    if (['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.tiff'].includes(extension)) return 'image';
    if (['.doc', '.docx'].includes(extension)) return 'word';
    if (['.xls', '.xlsx'].includes(extension)) return 'excel';
    if (['.ppt', '.pptx'].includes(extension)) return 'powerpoint';
    if (['.txt', '.rtf'].includes(extension)) return 'text';
    
    return 'other';
  }
}

module.exports = new DocumentController();
