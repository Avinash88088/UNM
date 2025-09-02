# AI Document Master - Backend API

This is the backend API server for the AI Document Master application, built with Node.js, Express.js, PostgreSQL, and Redis.

## 🚀 Features

- **Authentication & Authorization**: JWT-based authentication with role-based access control
- **Document Management**: Upload, process, and manage documents with OCR and handwriting recognition
- **AI Integration**: Google Cloud Vision API for OCR, OpenAI GPT-4 for question generation
- **Real-time Updates**: Socket.io for live processing updates
- **Background Processing**: Bull.js queues for document processing jobs
- **File Storage**: AWS S3 integration for scalable file storage
- **Multi-language Support**: Support for multiple languages including Hindi and English
- **Batch Processing**: Handle multiple document uploads efficiently
- **Security**: Rate limiting, input validation, and security headers

## 🏗️ Architecture

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

## 🛠️ Technology Stack

- **Runtime**: Node.js 18+
- **Framework**: Express.js
- **Database**: PostgreSQL 15+
- **Cache**: Redis 7+
- **Queue System**: Bull.js
- **Real-time**: Socket.io
- **Authentication**: JWT + Refresh Tokens
- **File Upload**: Multer
- **Validation**: Express-validator
- **Logging**: Winston
- **Documentation**: Swagger/OpenAPI 3.0
- **Containerization**: Docker & Docker Compose

## 📋 Prerequisites

- Node.js 18+ and npm
- Docker and Docker Compose
- PostgreSQL 15+ (if running locally)
- Redis 7+ (if running locally)
- AWS S3 bucket (for file storage)
- Google Cloud Vision API credentials
- OpenAI API key

## 🚀 Quick Start

### 1. Clone and Setup

```bash
# Clone the repository
git clone <repository-url>
cd backend

# Install dependencies
npm install

# Copy environment file
cp env.example .env
```

### 2. Environment Configuration

Edit `.env` file with your configuration:

```bash
# Server Configuration
NODE_ENV=development
PORT=3000
FRONTEND_URL=http://localhost:50000

# Database Configuration
DATABASE_URL=postgresql://postgres:password@localhost:5432/udm
DB_HOST=localhost
DB_PORT=5432
DB_NAME=udm
DB_USER=postgres
DB_PASSWORD=password

# Redis Configuration
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=
REDIS_DB=0

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key
JWT_REFRESH_SECRET=your-super-secret-refresh-key
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d

# AWS S3 Configuration
AWS_ACCESS_KEY_ID=your-aws-access-key
AWS_SECRET_ACCESS_KEY=your-aws-secret-key
AWS_REGION=us-east-1
AWS_S3_BUCKET=your-s3-bucket-name

# Google Cloud Vision API
GOOGLE_CLOUD_PROJECT_ID=your-project-id
GOOGLE_CLOUD_KEY_FILE=path/to/key.json

# OpenAI Configuration
OPENAI_API_KEY=your-openai-api-key
OPENAI_MODEL=gpt-4
```

### 3. Using Docker (Recommended)

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f api

# Stop services
docker-compose down
```

### 4. Manual Setup

```bash
# Start PostgreSQL
# (Install and start PostgreSQL locally)

# Start Redis
# (Install and start Redis locally)

# Run database migrations
npm run db:migrate

# Start the server
npm run dev
```

## 📊 API Endpoints

### Base URL: `http://localhost:3000/api/v1`

### Authentication
- `POST /auth/register` - User registration
- `POST /auth/login` - User login
- `POST /auth/refresh` - Refresh access token
- `POST /auth/logout` - User logout
- `GET /auth/me` - Get current user profile
- `POST /auth/change-password` - Change password

### Documents
- `POST /documents/upload` - Upload document
- `GET /documents` - List documents
- `GET /documents/:id` - Get document details
- `PUT /documents/:id` - Update document
- `DELETE /documents/:id` - Delete document

### AI Processing
- `POST /ai/process-document` - Process document with AI
- `POST /ai/generate-questions` - Generate questions from document
- `POST /ai/summarize` - Summarize document

### Questions
- `GET /question-sets` - List question sets
- `POST /question-sets` - Create question set
- `GET /question-sets/:id` - Get question set details
- `PUT /question-sets/:id` - Update question set
- `DELETE /question-sets/:id` - Delete question set

### Batch Processing
- `POST /batch/upload` - Upload multiple documents
- `GET /batch/:id/status` - Get batch processing status

### Admin
- `GET /admin/users` - List users (admin only)
- `POST /admin/users` - Create user (admin only)
- `PUT /admin/users/:id` - Update user (admin only)
- `DELETE /admin/users/:id` - Delete user (admin only)

## 🔐 Authentication

The API uses JWT (JSON Web Tokens) for authentication:

1. **Login** to get access and refresh tokens
2. **Include** `Authorization: Bearer <access_token>` in request headers
3. **Refresh** access token when it expires using refresh token

### Role-Based Access Control

- **Student**: Read own documents, upload documents, answer questions
- **Teacher**: All student permissions + create/edit question sets, batch processing
- **Admin**: All teacher permissions + manage institution users
- **Super Admin**: Full system access

## 📁 File Upload

### Supported Formats
- **Documents**: PDF, DOC, DOCX
- **Images**: JPG, JPEG, PNG, TIFF
- **Max Size**: 100MB per file

### Upload Process
1. File validation and virus scanning
2. Compression and optimization
3. Upload to S3 storage
4. AI processing (OCR, HWR, question generation)
5. Real-time progress updates via WebSocket

## 🤖 AI Services Integration

### OCR (Optical Character Recognition)
- **Service**: Google Cloud Vision API
- **Features**: Text extraction, layout analysis, confidence scoring
- **Languages**: English, Hindi, and other supported languages

### Handwriting Recognition
- **Primary**: Google Cloud Vision API
- **Fallback**: Custom ML models for better accuracy
- **Features**: Handwritten text extraction, confidence scoring

### Question Generation
- **Service**: OpenAI GPT-4
- **Features**: Multiple question types, difficulty levels, explanations
- **Customization**: Subject-specific, grade-appropriate questions

## 🗄️ Database Schema

The application uses PostgreSQL with the following main tables:

- **users**: User accounts and profiles
- **documents**: Document metadata and processing status
- **document_pages**: Individual page data and OCR results
- **question_sets**: Collections of questions
- **questions**: Individual questions with metadata
- **processing_jobs**: Background job tracking
- **user_sessions**: Refresh token management

## 🔄 Background Processing

### Queue System
- **Bull.js** for job management
- **Redis** as queue backend
- **Priority-based** job processing
- **Retry mechanism** for failed jobs
- **Progress tracking** and real-time updates

### Job Types
- **OCR Processing**: Extract text from images
- **Handwriting Recognition**: Process handwritten content
- **Question Generation**: Create questions from content
- **Document Summarization**: Generate summaries

## 📱 Real-time Features

### WebSocket Events
- **Document Processing Updates**: Real-time progress
- **Job Status Changes**: Immediate notifications
- **User Activity**: Live collaboration features

### Socket Authentication
- JWT token validation
- User session management
- Room-based subscriptions

## 🧪 Testing

```bash
# Run all tests
npm test

# Run tests in watch mode
npm run test:watch

# Run specific test file
npm test -- --testNamePattern="User Registration"

# Generate coverage report
npm run test:coverage
```

## 📚 API Documentation

### Swagger UI
Access the interactive API documentation at:
```
http://localhost:3000/api-docs
```

### OpenAPI Specification
Download the OpenAPI 3.0 specification:
```
http://localhost:3000/api-docs/swagger.json
```

## 🐳 Docker Commands

### Development
```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Restart specific service
docker-compose restart api

# Stop all services
docker-compose down
```

### Production
```bash
# Start production services
docker-compose --profile production up -d

# Scale API service
docker-compose up -d --scale api=3
```

### Database Management
```bash
# Access PostgreSQL
docker-compose exec postgres psql -U postgres -d udm

# Access Redis CLI
docker-compose exec redis redis-cli

# pgAdmin (Database GUI)
# http://localhost:5050
# Email: admin@aidocumentmaster.com
# Password: admin123

# Redis Commander (Redis GUI)
# http://localhost:8081
```

## 📊 Monitoring & Logging

### Health Checks
- **API Health**: `GET /health`
- **Database**: Connection status
- **Redis**: Cache service status
- **External Services**: AI service availability

### Logging
- **Winston** for structured logging
- **File rotation** and compression
- **Log levels**: error, warn, info, debug
- **Request logging** with user context

### Performance Monitoring
- **Response time** tracking
- **Database query** performance
- **Memory usage** monitoring
- **Queue performance** metrics

## 🔒 Security Features

- **JWT Authentication** with refresh tokens
- **Rate Limiting** to prevent abuse
- **Input Validation** and sanitization
- **CORS** configuration
- **Security Headers** (Helmet.js)
- **SQL Injection** prevention
- **XSS Protection**
- **CSRF Protection**

## 🚀 Deployment

### Production Environment
```bash
# Set production environment
NODE_ENV=production

# Use production Docker Compose
docker-compose --profile production up -d

# Set up SSL certificates
# Configure reverse proxy (Nginx)
# Set up monitoring and alerting
```

### Environment Variables
```bash
# Production overrides
NODE_ENV=production
PORT=3000
FRONTEND_URL=https://yourdomain.com
DATABASE_URL=postgresql://user:pass@host:5432/db
REDIS_HOST=your-redis-host
JWT_SECRET=your-production-secret
AWS_S3_BUCKET=your-production-bucket
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Documentation**: [API Docs](http://localhost:3000/api-docs)
- **Issues**: GitHub Issues
- **Email**: support@aidocumentmaster.com

## 🔄 Development Workflow

### Code Style
```bash
# Lint code
npm run lint

# Fix linting issues
npm run lint:fix
```

### Database Migrations
```bash
# Create new migration
npm run db:migrate:create -- --name add_user_preferences

# Run migrations
npm run db:migrate

# Seed database
npm run db:seed
```

### Hot Reload
```bash
# Development mode with nodemon
npm run dev

# Production mode
npm start
```

---

**Happy Coding! 🚀**
