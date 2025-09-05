const express = require('express');
const auth = require('../middleware/auth-simple');

const router = express.Router();

// Mock data for testing
const mockDocuments = [
  {
    id: '1',
    name: 'Sample Document 1',
    type: 'pdf',
    size: 1024000,
    uploaded_at: new Date(),
    status: 'processed',
    user_id: '1'
  },
  {
    id: '2',
    name: 'Sample Document 2',
    type: 'jpg',
    size: 512000,
    uploaded_at: new Date(),
    status: 'processing',
    user_id: '1'
  }
];

// Get all documents for user
router.get('/', auth, (req, res) => {
  try {
    const userId = req.user.userId;
    const userDocuments = mockDocuments.filter(doc => doc.user_id === userId);
    
    res.json({
      success: true,
      documents: userDocuments,
      total: userDocuments.length
    });
  } catch (error) {
    console.error('Get documents failed:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Get document by ID
router.get('/:id', auth, (req, res) => {
  try {
    const documentId = req.params.id;
    const userId = req.user.userId;
    
    const document = mockDocuments.find(doc => doc.id === documentId && doc.user_id === userId);
    
    if (!document) {
      return res.status(404).json({
        success: false,
        message: 'Document not found'
      });
    }
    
    res.json({
      success: true,
      document
    });
  } catch (error) {
    console.error('Get document failed:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Upload document (mock)
router.post('/upload', auth, (req, res) => {
  try {
    const { name, type, size } = req.body;
    const userId = req.user.userId;
    
    const newDocument = {
      id: Date.now().toString(),
      name,
      type,
      size: parseInt(size) || 0,
      uploaded_at: new Date(),
      status: 'uploaded',
      user_id: userId
    };
    
    mockDocuments.push(newDocument);
    
    res.status(201).json({
      success: true,
      message: 'Document uploaded successfully',
      document: newDocument
    });
  } catch (error) {
    console.error('Upload document failed:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Delete document
router.delete('/:id', auth, (req, res) => {
  try {
    const documentId = req.params.id;
    const userId = req.user.userId;
    
    const documentIndex = mockDocuments.findIndex(doc => doc.id === documentId && doc.user_id === userId);
    
    if (documentIndex === -1) {
      return res.status(404).json({
        success: false,
        message: 'Document not found'
      });
    }
    
    mockDocuments.splice(documentIndex, 1);
    
    res.json({
      success: true,
      message: 'Document deleted successfully'
    });
  } catch (error) {
    console.error('Delete document failed:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

module.exports = router;
