# AI Document Master - Backend Architecture & API Specification

## 🏗️ System Architecture Overview

### High-Level Architecture
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flutter      │    │   Backend API   │    │   AI Services   │
│   Frontend     │◄──►│   (Node.js/     │◄──►│   (OCR, NLP,    │
│                 │    │    Express)     │    │    HWR)         │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌─────────────────┐
                       │   Database      │
                       │   (PostgreSQL)  │
                       └─────────────────┘
                              │
                              ▼
                       ┌─────────────────┐
                       │   File Storage  │
                       │   (AWS S3)      │
                       └─────────────────┘
```

### Technology Stack
- **Backend Framework**: Node.js + Express.js
- **Database**: PostgreSQL + Redis (caching)
- **File Storage**: AWS S3 / Google Cloud Storage
- **AI Services**: Google Cloud Vision API, OpenAI GPT-4, HuggingFace
- **Authentication**: JWT + Refresh Tokens
- **Real-time**: Socket.io for live updates
- **Queue System**: Bull.js for background processing
- **API Documentation**: Swagger/OpenAPI 3.0

## 🗄️ Database Schema

### Core Tables

#### 1. Users Table
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20) UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    role user_role NOT NULL DEFAULT 'student',
    institution_id UUID REFERENCES institutions(id),
    is_active BOOLEAN DEFAULT true,
    email_verified BOOLEAN DEFAULT false,
    phone_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TYPE user_role AS ENUM ('student', 'teacher', 'admin', 'super_admin');
```

#### 2. Documents Table
```sql
CREATE TABLE documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    file_name VARCHAR(255) NOT NULL,
    original_file_url TEXT NOT NULL,
    processed_file_url TEXT,
    file_type VARCHAR(50) NOT NULL,
    file_size BIGINT NOT NULL,
    mime_type VARCHAR(100),
    status document_status DEFAULT 'uploaded',
    language VARCHAR(10) DEFAULT 'en',
    total_pages INTEGER DEFAULT 0,
    processing_progress INTEGER DEFAULT 0,
    ocr_confidence DECIMAL(5,2),
    error_message TEXT,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP
);

CREATE TYPE document_status AS ENUM (
    'uploaded', 'processing', 'completed', 'failed', 'archived'
);
```

#### 3. Document Pages Table
```sql
CREATE TABLE document_pages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID NOT NULL REFERENCES documents(id),
    page_number INTEGER NOT NULL,
    image_url TEXT NOT NULL,
    ocr_text TEXT,
    ocr_confidence DECIMAL(5,2),
    handwriting_text TEXT,
    handwriting_confidence DECIMAL(5,2),
    layout_analysis JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### 4. Question Sets Table
```sql
CREATE TABLE question_sets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID REFERENCES documents(id),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    created_by UUID NOT NULL REFERENCES users(id),
    overall_difficulty question_difficulty DEFAULT 'medium',
    total_questions INTEGER DEFAULT 0,
    total_marks INTEGER DEFAULT 0,
    marks_distribution JSONB,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TYPE question_difficulty AS ENUM ('easy', 'medium', 'hard', 'expert');
```

#### 5. Questions Table
```sql
CREATE TABLE questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question_set_id UUID NOT NULL REFERENCES question_sets(id),
    question_text TEXT NOT NULL,
    question_type question_type NOT NULL,
    difficulty question_difficulty DEFAULT 'medium',
    options JSONB,
    correct_answer TEXT,
    explanation TEXT,
    confidence_score DECIMAL(5,2),
    source_text TEXT,
    source_page_number INTEGER,
    marks INTEGER DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TYPE question_type AS ENUM (
    'multiple_choice', 'true_false', 'fill_blank', 'short_answer', 'essay'
);
```

#### 6. Processing Jobs Table
```sql
CREATE TABLE processing_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID NOT NULL REFERENCES documents(id),
    job_type job_type NOT NULL,
    status job_status DEFAULT 'pending',
    priority INTEGER DEFAULT 5,
    progress INTEGER DEFAULT 0,
    result_data JSONB,
    error_message TEXT,
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TYPE job_type AS ENUM ('ocr', 'hwr', 'question_generation', 'summarization');
CREATE TYPE job_status AS ENUM ('pending', 'running', 'completed', 'failed', 'cancelled');
```

## 🔌 API Endpoints

### Base URL: `https://api.aidocumentmaster.com/v1`

### Authentication Endpoints

#### POST `/auth/register`
```json
{
    "email": "user@example.com",
    "password": "securePassword123",
    "firstName": "John",
    "lastName": "Doe",
    "phone": "+1234567890",
    "role": "teacher",
    "institutionId": "uuid-here"
}
```

#### POST `/auth/login`
```json
{
    "email": "user@example.com",
    "password": "securePassword123"
}
```

#### POST `/auth/refresh`
```json
{
    "refreshToken": "refresh-token-here"
}
```

### Document Management Endpoints

#### POST `/documents/upload`
```json
{
    "file": "multipart/form-data",
    "compressionProfile": "standard",
    "features": ["ocr", "hwr", "question_generation"],
    "language": "en",
    "priority": "normal"
}
```

#### GET `/documents`
Query Parameters:
- `page`: 1
- `limit`: 20
- `status`: "completed"
- `type`: "pdf"
- `language`: "en"

#### GET `/documents/:id`
Returns complete document with pages and processing status

#### PUT `/documents/:id`
```json
{
    "fileName": "Updated Name",
    "language": "hi",
    "metadata": {
        "subject": "Mathematics",
        "grade": "10th"
    }
}
```

### AI Processing Endpoints

#### POST `/ai/process-document`
```json
{
    "documentId": "uuid-here",
    "features": ["ocr", "hwr"],
    "language": "en",
    "priority": "high"
}
```

#### POST `/ai/generate-questions`
```json
{
    "documentId": "uuid-here",
    "questionCount": 20,
    "difficulty": "medium",
    "types": ["multiple_choice", "short_answer"],
    "subject": "Mathematics",
    "grade": "10th"
}
```

#### POST `/ai/summarize`
```json
{
    "documentId": "uuid-here",
    "summaryLength": "medium",
    "focusAreas": ["key_concepts", "important_formulas"]
}
```

### Question Management Endpoints

#### GET `/question-sets`
Query Parameters:
- `documentId`: "uuid-here"
- `difficulty`: "medium"
- `createdBy`: "uuid-here"

#### POST `/question-sets`
```json
{
    "documentId": "uuid-here",
    "title": "Chapter 1 Quiz",
    "description": "Questions based on Chapter 1 content",
    "overallDifficulty": "medium",
    "questions": [
        {
            "questionText": "What is the formula for area of circle?",
            "type": "multiple_choice",
            "difficulty": "easy",
            "options": ["πr²", "2πr", "πd", "2πd"],
            "correctAnswer": "πr²",
            "marks": 2
        }
    ]
}
```

### Batch Processing Endpoints

#### POST `/batch/upload`
```json
{
    "files": ["multipart/form-data"],
    "batchName": "Semester 1 Documents",
    "compressionProfile": "standard",
    "features": ["ocr", "hwr"],
    "priority": "normal"
}
```

#### GET `/batch/:id/status`
Returns batch processing status and individual document progress

## 🤖 AI Service Integration

### 1. OCR Service (Google Cloud Vision API)
```javascript
// OCR Processing
async function processOCR(imageBuffer, language = 'en') {
    const vision = require('@google-cloud/vision');
    const client = new vision.ImageAnnotatorClient();
    
    const request = {
        image: { content: imageBuffer },
        features: [
            { type: 'TEXT_DETECTION' },
            { type: 'DOCUMENT_TEXT_DETECTION' }
        ],
        imageContext: {
            languageHints: [language]
        }
    };
    
    const [result] = await client.annotateImage(request);
    return {
        text: result.fullTextAnnotation.text,
        confidence: calculateConfidence(result.textAnnotations),
        blocks: result.textAnnotations
    };
}
```

### 2. Handwriting Recognition (Custom ML Model + Google Cloud)
```javascript
// Handwriting Recognition
async function processHandwriting(imageBuffer, language = 'en') {
    // Try Google Cloud first
    try {
        const result = await processOCR(imageBuffer, language);
        if (result.confidence > 0.8) {
            return result;
        }
    } catch (error) {
        console.log('Google Cloud OCR failed, trying custom model');
    }
    
    // Fallback to custom ML model
    return await customHandwritingModel.predict(imageBuffer, language);
}
```

### 3. Question Generation (OpenAI GPT-4)
```javascript
// Question Generation
async function generateQuestions(documentText, config) {
    const openai = require('openai');
    const client = new openai.OpenAI();
    
    const prompt = `
    Generate ${config.questionCount} questions based on the following text:
    
    Text: ${documentText}
    
    Requirements:
    - Difficulty: ${config.difficulty}
    - Types: ${config.types.join(', ')}
    - Subject: ${config.subject}
    - Grade: ${config.grade}
    
    Format each question as JSON with:
    - questionText
    - type
    - difficulty
    - options (for multiple choice)
    - correctAnswer
    - explanation
    - marks
    `;
    
    const completion = await client.chat.completions.create({
        model: "gpt-4",
        messages: [{ role: "user", content: prompt }],
        temperature: 0.7,
        max_tokens: 2000
    });
    
    return JSON.parse(completion.choices[0].message.content);
}
```

## 🔄 Background Processing

### Queue System (Bull.js)
```javascript
// Queue Configuration
const Queue = require('bull');
const redis = require('redis');

// Document Processing Queue
const documentQueue = new Queue('document-processing', {
    redis: {
        host: process.env.REDIS_HOST,
        port: process.env.REDIS_PORT,
        password: process.env.REDIS_PASSWORD
    }
});

// Question Generation Queue
const questionQueue = new Queue('question-generation', {
    redis: {
        host: process.env.REDIS_HOST,
        port: process.env.REDIS_PORT,
        password: process.env.REDIS_PASSWORD
    }
});

// Process Documents
documentQueue.process(async (job) => {
    const { documentId, features } = job.data;
    
    try {
        // Update status to processing
        await updateDocumentStatus(documentId, 'processing');
        
        // Process each feature
        for (const feature of features) {
            switch (feature) {
                case 'ocr':
                    await processOCRFeature(documentId);
                    break;
                case 'hwr':
                    await processHWRFeature(documentId);
                    break;
                case 'question_generation':
                    await processQuestionGeneration(documentId);
                    break;
            }
        }
        
        // Update status to completed
        await updateDocumentStatus(documentId, 'completed');
        
    } catch (error) {
        await updateDocumentStatus(documentId, 'failed', error.message);
        throw error;
    }
});
```

## 🔐 Security & Authentication

### JWT Token Structure
```javascript
// Access Token (15 minutes)
const accessToken = jwt.sign(
    {
        userId: user.id,
        email: user.email,
        role: user.role,
        permissions: user.permissions
    },
    process.env.JWT_SECRET,
    { expiresIn: '15m' }
);

// Refresh Token (7 days)
const refreshToken = jwt.sign(
    {
        userId: user.id,
        tokenVersion: user.tokenVersion
    },
    process.env.JWT_REFRESH_SECRET,
    { expiresIn: '7d' }
);
```

### Role-Based Access Control (RBAC)
```javascript
// Permission Middleware
const checkPermission = (requiredPermission) => {
    return (req, res, next) => {
        const userPermissions = req.user.permissions;
        
        if (!userPermissions.includes(requiredPermission)) {
            return res.status(403).json({
                error: 'Insufficient permissions',
                required: requiredPermission,
                current: userPermissions
            });
        }
        
        next();
    };
};

// Usage Example
app.post('/admin/users', 
    authenticateToken, 
    checkPermission('user:create'),
    createUser
);
```

## 📱 Real-time Updates

### Socket.io Integration
```javascript
// Socket.io Setup
const io = require('socket.io')(server, {
    cors: {
        origin: process.env.FRONTEND_URL,
        methods: ["GET", "POST"]
    }
});

// Authentication Middleware
io.use(async (socket, next) => {
    try {
        const token = socket.handshake.auth.token;
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        socket.userId = decoded.userId;
        socket.userRole = decoded.role;
        next();
    } catch (error) {
        next(new Error('Authentication error'));
    }
});

// Document Processing Updates
io.on('connection', (socket) => {
    socket.on('join-document', (documentId) => {
        socket.join(`document:${documentId}`);
    });
    
    socket.on('leave-document', (documentId) => {
        socket.leave(`document:${documentId}`);
    });
});

// Emit processing updates
function emitProcessingUpdate(documentId, progress, status) {
    io.to(`document:${documentId}`).emit('processing-update', {
        documentId,
        progress,
        status,
        timestamp: new Date()
    });
}
```

## 🚀 Deployment & Infrastructure

### Environment Configuration
```bash
# Production Environment Variables
NODE_ENV=production
PORT=3000
DATABASE_URL=postgresql://user:pass@host:5432/db
REDIS_HOST=redis-host
REDIS_PORT=6379
REDIS_PASSWORD=redis-password
JWT_SECRET=super-secret-jwt-key
JWT_REFRESH_SECRET=super-secret-refresh-key
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_REGION=us-east-1
AWS_S3_BUCKET=document-storage-bucket
GOOGLE_CLOUD_PROJECT_ID=your-project-id
GOOGLE_CLOUD_KEY_FILE=path/to/key.json
OPENAI_API_KEY=your-openai-key
```

### Docker Configuration
```dockerfile
# Dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

EXPOSE 3000

CMD ["npm", "start"]
```

```yaml
# docker-compose.yml
version: '3.8'
services:
  api:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgresql://postgres:password@postgres:5432/udm
      - REDIS_HOST=redis
    depends_on:
      - postgres
      - redis
  
  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: udm
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password
    volumes:
      - postgres_data:/var/lib/postgresql/data
  
  redis:
    image: redis:7-alpine
    command: redis-server --requirepass password
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
```

## 📊 Monitoring & Logging

### Health Checks
```javascript
// Health Check Endpoint
app.get('/health', async (req, res) => {
    try {
        // Check database connection
        await db.query('SELECT 1');
        
        // Check Redis connection
        await redis.ping();
        
        res.json({
            status: 'healthy',
            timestamp: new Date(),
            uptime: process.uptime(),
            memory: process.memoryUsage(),
            database: 'connected',
            redis: 'connected'
        });
    } catch (error) {
        res.status(503).json({
            status: 'unhealthy',
            error: error.message,
            timestamp: new Date()
        });
    }
});
```

### Logging (Winston)
```javascript
const winston = require('winston');

const logger = winston.createLogger({
    level: 'info',
    format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.errors({ stack: true }),
        winston.format.json()
    ),
    defaultMeta: { service: 'ai-document-master' },
    transports: [
        new winston.transports.File({ filename: 'error.log', level: 'error' }),
        new winston.transports.File({ filename: 'combined.log' })
    ]
});

if (process.env.NODE_ENV !== 'production') {
    logger.add(new winston.transports.Console({
        format: winston.format.simple()
    }));
}
```

## 🔄 API Integration with Flutter

### HTTP Client Setup
```dart
// lib/services/api_client.dart
class ApiClient {
  static const String baseUrl = 'https://api.aidocumentmaster.com/v1';
  static const Duration timeout = Duration(seconds: 30);
  
  late final http.Client _client;
  late final String? _accessToken;
  
  ApiClient({String? accessToken}) : _accessToken = accessToken {
    _client = http.Client();
  }
  
  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (_accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    
    return headers;
  }
  
  Future<http.Response> get(String endpoint) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    return await _client.get(uri, headers: _headers).timeout(timeout);
  }
  
  Future<http.Response> post(String endpoint, {Object? body}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    return await _client.post(
      uri,
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    ).timeout(timeout);
  }
  
  // Add PUT, DELETE methods...
}
```

### Document Service
```dart
// lib/services/document_service.dart
class DocumentService {
  final ApiClient _apiClient;
  
  DocumentService({required ApiClient apiClient}) : _apiClient = apiClient;
  
  Future<List<Document>> getDocuments({
    int page = 1,
    int limit = 20,
    String? status,
    String? type,
    String? language,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    
    if (status != null) queryParams['status'] = status;
    if (type != null) queryParams['type'] = type;
    if (language != null) queryParams['language'] = language;
    
    final queryString = Uri(queryParameters: queryParams).query;
    final response = await _apiClient.get('/documents?$queryString');
    
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body)['data'];
      return data.map((json) => Document.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load documents');
    }
  }
  
  Future<Document> uploadDocument({
    required File file,
    required String compressionProfile,
    required List<String> features,
    String language = 'en',
    String priority = 'normal',
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiClient.baseUrl}/documents/upload'),
    );
    
    request.headers['Authorization'] = 'Bearer ${_apiClient._accessToken}';
    request.fields['compressionProfile'] = compressionProfile;
    request.fields['features'] = features.join(',');
    request.fields['language'] = language;
    request.fields['priority'] = priority;
    
    request.files.add(
      await http.MultipartFile.fromPath('file', file.path),
    );
    
    final response = await request.send();
    final responseData = await response.stream.bytesToString();
    
    if (response.statusCode == 201) {
      return Document.fromJson(jsonDecode(responseData));
    } else {
      throw Exception('Upload failed: ${jsonDecode(responseData)['error']}');
    }
  }
}
```

## 🎯 Next Steps & Implementation Priority

### Phase 1: Core Backend (Week 1-2)
1. **Setup Node.js + Express server**
2. **Database schema creation & migrations**
3. **Basic CRUD operations for documents & users**
4. **JWT authentication system**
5. **File upload to S3**

### Phase 2: AI Integration (Week 3-4)
1. **Google Cloud Vision API integration**
2. **OpenAI GPT-4 integration for question generation**
3. **Background processing queues**
4. **Real-time progress updates**

### Phase 3: Advanced Features (Week 5-6)
1. **Batch processing system**
2. **Multi-language support**
3. **Advanced question types**
4. **Performance optimization**

### Phase 4: Testing & Deployment (Week 7-8)
1. **Unit & integration tests**
2. **API documentation**
3. **Docker containerization**
4. **Production deployment**

This backend architecture provides a solid foundation for your AI Document Master application, with scalable design patterns and modern best practices. Would you like me to start implementing any specific part of this backend system?
