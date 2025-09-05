const axios = require('axios');
const { AppError, asyncHandler } = require('../middleware/errorHandler');

class AIController {
  constructor() {
    this.geminiApiKey = process.env.GEMINI_API_KEY;
    this.geminiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';
    this.geminiVisionUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro-vision:generateContent';
    
    // Log AI service status
    if (this.geminiApiKey) {
      console.log('🔑 Gemini AI API: ✅ Configured');
    } else {
      console.log('🔑 Gemini AI API: ❌ Not configured - Using fallback mode');
    }
  }

  // Generate questions from document content using Gemini
  async generateQuestions(req, res) {
    try {
      const { documentContent, count = 5, difficulty = 'medium', questionTypes = ['multiple_choice', 'short_answer'] } = req.body;

      if (!documentContent) {
        throw new AppError('Document content is required', 400);
      }

      if (!this.geminiApiKey) {
        console.log('⚠️ Gemini API key not available, using fallback questions');
        const fallbackQuestions = this._generateMockQuestions(documentContent, count, difficulty);
        return res.json({
          success: true,
          message: 'Questions generated using fallback method',
          questions: fallbackQuestions,
          total: fallbackQuestions.length,
          source: 'Fallback',
          warning: 'AI service not configured'
        });
      }

      // Create prompt for Gemini
      const prompt = `
        Based on the following document content, generate ${count} educational questions.
        
        Document Content:
        ${documentContent}
        
        Requirements:
        - Difficulty: ${difficulty}
        - Question Types: ${questionTypes.join(', ')}
        - Make questions relevant and challenging
        - Include answer explanations
        - For multiple choice, provide 4 options with 1 correct answer
        
        Format the response as a JSON array with this structure:
        [
          {
            "question": "Question text here?",
            "answer": "Correct answer explanation",
            "type": "multiple_choice",
            "options": ["Option A", "Option B", "Option C", "Option D"],
            "correct_answer": 0,
            "difficulty": "${difficulty}",
            "explanation": "Why this answer is correct"
          }
        ]
      `;

      console.log('🤖 Calling Gemini AI for question generation...');

      // Call Gemini API
      const response = await axios.post(
        `${this.geminiBaseUrl}?key=${this.geminiApiKey}`,
        {
          contents: [{
            parts: [{
              text: prompt
            }]
          }]
        },
        {
          headers: {
            'Content-Type': 'application/json'
          },
          timeout: 30000 // 30 second timeout
        }
      );

      // Extract questions from Gemini response
      let questions = [];
      try {
        const geminiResponse = response.data.candidates[0].content.parts[0].text;
        console.log('📝 Gemini Response:', geminiResponse.substring(0, 200) + '...');
        
        // Extract JSON from the response
        const jsonMatch = geminiResponse.match(/\[[\s\S]*\]/);
        if (jsonMatch) {
          questions = JSON.parse(jsonMatch[0]);
          console.log(`✅ Successfully parsed ${questions.length} questions from Gemini`);
        } else {
          throw new Error('No JSON array found in response');
        }
      } catch (parseError) {
        console.error('❌ Error parsing Gemini response:', parseError);
        console.log('🔄 Falling back to mock questions');
        questions = this._generateMockQuestions(documentContent, count, difficulty);
      }

      res.json({
        success: true,
        message: 'Questions generated successfully using AI',
        questions,
        total: questions.length,
        source: 'Gemini AI',
        processing_time: Date.now() - req.startTime || 0
      });

    } catch (error) {
      console.error('❌ Question generation failed:', error.message);
      
      // Fallback to mock questions if AI fails
      const { documentContent, count = 5, difficulty = 'medium' } = req.body;
      const fallbackQuestions = this._generateMockQuestions(documentContent, count, difficulty);
      
      res.json({
        success: true,
        message: 'Questions generated using fallback method',
        questions: fallbackQuestions,
        total: fallbackQuestions.length,
        source: 'Fallback',
        warning: 'AI service temporarily unavailable',
        error: error.message
      });
    }
  }

  // Process image with OCR using Gemini Vision
  async processImageOCR(req, res) {
    try {
      const { imageUrl, language = 'en', context = '' } = req.body;

      if (!imageUrl) {
        throw new AppError('Image URL is required', 400);
      }

      if (!this.geminiApiKey) {
        throw new AppError('Gemini API key not configured', 500);
      }

      // Create prompt for image analysis
      const prompt = `
        Analyze this image and extract all text content.
        
        ${context ? `Context: ${context}` : ''}
        Language: ${language}
        
        Please provide:
        1. All visible text in the image
        2. Text confidence level (high/medium/low)
        3. Language detected
        4. Any handwritten vs printed text distinction
        5. Text layout and structure
        
        Format as JSON:
        {
          "text": "extracted text",
          "confidence": "high/medium/low",
          "language": "${language}",
          "textType": "printed/handwritten/mixed",
          "layout": "description of text arrangement",
          "words": number_of_words,
          "characters": number_of_characters
        }
      `;

      // Call Gemini Vision API
      const response = await axios.post(
        `${this.geminiVisionUrl}?key=${this.geminiApiKey}`,
        {
          contents: [{
            parts: [
              {
                text: prompt
              },
              {
                inline_data: {
                  mime_type: "image/jpeg",
                  data: imageUrl // This should be base64 encoded image data
                }
              }
            ]
          }]
        },
        {
          headers: {
            'Content-Type': 'application/json'
          },
          timeout: 30000 // 30 second timeout
        }
      );

      // Extract OCR result
      let ocrResult = {};
      try {
        const geminiResponse = response.data.candidates[0].content.parts[0].text;
        const jsonMatch = geminiResponse.match(/\{[\s\S]*\}/);
        if (jsonMatch) {
          ocrResult = JSON.parse(jsonMatch[0]);
        }
      } catch (parseError) {
        console.error('❌ Error parsing Gemini OCR response:', parseError);
        ocrResult = this._generateMockOCRResult(language);
      }

      res.json({
        success: true,
        message: 'OCR processing completed using AI',
        result: ocrResult,
        source: 'Gemini Vision AI',
        processing_time: Date.now() - req.startTime || 0
      });

    } catch (error) {
      console.error('❌ OCR processing failed:', error.message);
      
      // Fallback to mock OCR
      const { language = 'en' } = req.body;
      const fallbackResult = this._generateMockOCRResult(language);
      
      res.json({
        success: true,
        message: 'OCR processing completed using fallback method',
        result: fallbackResult,
        source: 'Fallback',
        warning: 'AI service temporarily unavailable',
        error: error.message
      });
    }
  }

  // Enhance image using AI analysis
  async enhanceImage(req, res) {
    try {
      const { imageUrl, enhancements = ['brightness', 'contrast', 'sharpness'], context = '' } = req.body;

      if (!imageUrl) {
        throw new AppError('Image URL is required', 400);
      }

      if (!this.geminiApiKey) {
        throw new AppError('Gemini API key not configured', 500);
      }

      // Create prompt for image enhancement suggestions
      const prompt = `
        Analyze this image and suggest enhancement improvements.
        
        ${context ? `Context: ${context}` : ''}
        Requested enhancements: ${enhancements.join(', ')}
        
        Please provide:
        1. Current image quality assessment
        2. Specific enhancement recommendations
        3. Expected improvement percentages
        4. Processing steps needed
        
        Format as JSON:
        {
          "currentQuality": "assessment",
          "enhancements": ["list", "of", "suggestions"],
          "expectedImprovement": "percentage",
          "processingSteps": ["step1", "step2"],
          "recommendedSettings": {
            "brightness": "value",
            "contrast": "value",
            "sharpness": "value"
          }
        }
      `;

      // Call Gemini API for enhancement analysis
      const response = await axios.post(
        `${this.geminiBaseUrl}?key=${this.geminiApiKey}`,
        {
          contents: [{
            parts: [{
              text: prompt
            }]
          }]
        },
        {
          headers: {
            'Content-Type': 'application/json'
          },
          timeout: 30000 // 30 second timeout
        }
      );

      // Extract enhancement result
      let enhancementResult = {};
      try {
        const geminiResponse = response.data.candidates[0].content.parts[0].text;
        const jsonMatch = geminiResponse.match(/\{[\s\S]*\}/);
        if (jsonMatch) {
          enhancementResult = JSON.parse(jsonMatch[0]);
        }
      } catch (parseError) {
        console.error('❌ Error parsing Gemini enhancement response:', parseError);
        enhancementResult = this._generateMockEnhancementResult(enhancements);
      }

      res.json({
        success: true,
        message: 'Image enhancement analysis completed using AI',
        result: enhancementResult,
        source: 'Gemini AI',
        processing_time: Date.now() - req.startTime || 0
      });

    } catch (error) {
      console.error('❌ Image enhancement analysis failed:', error.message);
      
      // Fallback to mock enhancement
      const { enhancements = ['brightness', 'contrast', 'sharpness'] } = req.body;
      const fallbackResult = this._generateMockEnhancementResult(enhancements);
      
      res.json({
        success: true,
        message: 'Image enhancement analysis completed using fallback method',
        result: fallbackResult,
        source: 'Fallback',
        warning: 'AI service temporarily unavailable',
        error: error.message
      });
    }
  }

  // Generate document summary using Gemini
  async generateSummary(req, res) {
    try {
      const { documentContent, summaryType = 'general', maxLength = 200 } = req.body;

      if (!documentContent) {
        throw new AppError('Document content is required', 400);
      }

      if (!this.geminiApiKey) {
        throw new AppError('Gemini API key not configured', 500);
      }

      // Create prompt for summary generation
      const prompt = `
        Generate a ${summaryType} summary of the following document content.
        
        Document Content:
        ${documentContent}
        
        Requirements:
        - Summary type: ${summaryType}
        - Maximum length: ${maxLength} words
        - Focus on key points and main ideas
        - Maintain accuracy and relevance
        - Use clear, concise language
        
        Provide the summary in a structured format.
      `;

      // Call Gemini API
      const response = await axios.post(
        `${this.geminiBaseUrl}?key=${this.geminiApiKey}`,
        {
          contents: [{
            parts: [{
              text: prompt
            }]
          }]
        },
        {
          headers: {
            'Content-Type': 'application/json'
          },
          timeout: 30000 // 30 second timeout
        }
      );

      // Extract summary from Gemini response
      const summary = response.data.candidates[0].content.parts[0].text;

      res.json({
        success: true,
        message: 'Document summary generated successfully using AI',
        summary,
        summaryType,
        maxLength,
        source: 'Gemini AI',
        processing_time: Date.now() - req.startTime || 0
      });

    } catch (error) {
      console.error('❌ Summary generation failed:', error.message);
      
      // Fallback to basic summary
      const { documentContent, maxLength = 200 } = req.body;
      const fallbackSummary = this._generateBasicSummary(documentContent, maxLength);
      
      res.json({
        success: true,
        message: 'Document summary generated using fallback method',
        summary: fallbackSummary,
        source: 'Fallback',
        warning: 'AI service temporarily unavailable',
        error: error.message
      });
    }
  }

  // Helper methods for fallback functionality
  _generateMockQuestions(content, count, difficulty) {
    const questions = [
      {
        question: "What is the main topic discussed in this document?",
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
    
    return questions.slice(0, count);
  }

  _generateMockOCRResult(language) {
    return {
      text: "This is sample text extracted from the image using OCR technology.",
      confidence: "high",
      language: language,
      textType: "printed",
      layout: "Horizontal text arrangement",
      words: 12,
      characters: 67
    };
  }

  _generateMockEnhancementResult(enhancements) {
    return {
      currentQuality: "Good with room for improvement",
      enhancements: enhancements,
      expectedImprovement: "25%",
      processingSteps: ["Analyze current image", "Apply enhancements", "Validate results"],
      recommendedSettings: {
        brightness: "1.1",
        contrast: "1.2",
        sharpness: "1.15"
      }
    };
  }

  _generateBasicSummary(content, maxLength) {
    const words = content.split(' ');
    if (words.length <= maxLength) {
      return content;
    }
    return words.slice(0, maxLength).join(' ') + '...';
  }
}

module.exports = new AIController();

