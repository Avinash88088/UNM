# 🚀 AI Document Master (UDM) - Universal Document Management System

[![Flutter](https://img.shields.io/badge/Flutter-3.16+-blue.svg)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.0+-blue.svg)](https://dart.dev/)
[![Node.js](https://img.shields.io/badge/Node.js-18+-green.svg)](https://nodejs.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-14+-blue.svg)](https://www.postgresql.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> **AI-powered document processing, OCR, handwriting recognition, and intelligent question generation system**

## 🌟 Overview

AI Document Master (UDM) is a comprehensive document management system that combines Flutter's cross-platform capabilities with advanced AI services. The system processes documents using OCR, handwriting recognition, and generates intelligent questions for educational and business applications.

## ✨ Features

### 📱 **Frontend (Flutter)**
- **Cross-platform Support**: iOS, Android, Web, Desktop
- **Modern UI/UX**: Material Design 3 with light/dark themes
- **Document Management**: Upload, view, organize documents
- **Real-time Processing**: Live updates on document processing status
- **Offline Support**: Basic offline functionality with caching
- **Multi-language**: Hindi, English, and regional script support

### 🤖 **AI Services**
- **OCR (Optical Character Recognition)**: Extract text from images/PDFs
- **Handwriting Recognition (HWR)**: Convert handwritten text to digital
- **Question Generation**: AI-powered question creation from documents
- **Smart Summarization**: Intelligent document summarization
- **Language Processing**: Multi-language text analysis

### 🔧 **Backend (Node.js)**
- **RESTful API**: Comprehensive API endpoints
- **Real-time Communication**: WebSocket support with Socket.io
- **Background Processing**: Queue-based job processing
- **File Storage**: AWS S3/Google Cloud Storage integration
- **Database**: PostgreSQL with Redis caching
- **Authentication**: JWT-based security with RBAC

### 📊 **Advanced Features**
- **Batch Processing**: Multiple document upload and processing
- **Auto-marking System**: AI-powered answer evaluation
- **Collaboration Tools**: Real-time document sharing and editing
- **Analytics Dashboard**: Processing statistics and insights
- **Role-based Access**: Institution and user management

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flutter App  │    │   Node.js API   │    │   AI Services   │
│   (Frontend)   │◄──►│   (Backend)     │◄──►│   (External)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Mobile/Web    │    │   PostgreSQL    │    │ Google Cloud    │
│   Platforms     │    │   + Redis       │    │ Vision API      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🚀 Quick Start

### Prerequisites
- Flutter 3.16+
- Node.js 18+
- PostgreSQL 14+
- Redis 6+
- Docker & Docker Compose (optional)

### Frontend Setup
```bash
# Clone the repository
git clone https://github.com/yourusername/ai-document-master.git
cd ai-document-master

# Install Flutter dependencies
flutter pub get

# Run the app
flutter run
```

### Backend Setup
```bash
# Navigate to backend directory
cd backend

# Install dependencies
npm install

# Set up environment variables
cp .env.example .env
# Edit .env with your configuration

# Start the server
npm run dev
```

### Docker Setup (Recommended)
```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

## 📁 Project Structure

```
ai-document-master/
├── lib/                    # Flutter source code
│   ├── models/            # Data models
│   ├── screens/           # UI screens
│   ├── widgets/           # Reusable widgets
│   ├── services/          # API services
│   ├── providers/         # State management
│   └── utils/             # Utilities and constants
├── backend/               # Node.js backend
│   ├── src/               # Source code
│   │   ├── routes/        # API routes
│   │   ├── middleware/    # Middleware functions
│   │   ├── database/      # Database connections
│   │   └── utils/         # Utility functions
│   ├── Dockerfile         # Docker configuration
│   └── docker-compose.yml # Service orchestration
├── docs/                  # Documentation
├── android/               # Android-specific files
├── ios/                   # iOS-specific files
└── web/                   # Web-specific files
```

## 🔌 API Endpoints

### Authentication
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `POST /api/auth/refresh` - Refresh token
- `POST /api/auth/logout` - User logout

### Documents
- `GET /api/documents` - List documents
- `POST /api/documents` - Upload document
- `GET /api/documents/:id` - Get document details
- `PUT /api/documents/:id` - Update document
- `DELETE /api/documents/:id` - Delete document

### AI Services
- `POST /api/ai/ocr` - OCR processing
- `POST /api/ai/hwr` - Handwriting recognition
- `POST /api/ai/questions` - Generate questions
- `POST /api/ai/summarize` - Document summarization

### Questions
- `GET /api/questions` - List question sets
- `POST /api/questions` - Create question set
- `GET /api/questions/:id` - Get question set
- `PUT /api/questions/:id` - Update question set

## 🛠️ Technology Stack

### Frontend
- **Framework**: Flutter 3.16+
- **Language**: Dart 3.0+
- **State Management**: Provider
- **UI Components**: Material Design 3
- **HTTP Client**: http package
- **WebSocket**: socket_io_client

### Backend
- **Runtime**: Node.js 18+
- **Framework**: Express.js
- **Database**: PostgreSQL 14+
- **Cache**: Redis 6+
- **Authentication**: JWT + bcrypt
- **File Upload**: Multer
- **Queue**: Bull.js
- **Real-time**: Socket.io

### AI Services
- **OCR**: Google Cloud Vision API
- **Language Model**: OpenAI GPT-4
- **NLP**: HuggingFace Transformers
- **File Processing**: pdf-parse, sharp

### DevOps
- **Containerization**: Docker & Docker Compose
- **API Documentation**: Swagger/OpenAPI 3.0
- **Logging**: Winston
- **Validation**: Joi, express-validator
- **Security**: Helmet, CORS, Rate Limiting

## 🔐 Security Features

- **JWT Authentication**: Secure token-based authentication
- **Role-based Access Control (RBAC)**: Granular permission system
- **Input Validation**: Comprehensive request validation
- **Rate Limiting**: API abuse prevention
- **CORS Protection**: Cross-origin request security
- **Helmet Security**: HTTP header security
- **Password Hashing**: bcrypt with salt rounds

## 📊 Database Schema

The system uses PostgreSQL with the following main tables:
- **Users**: User accounts and profiles
- **Institutions**: Educational/business organizations
- **Documents**: Document metadata and content
- **Document Pages**: Individual page information
- **Question Sets**: Collections of questions
- **Questions**: Individual question data
- **Processing Jobs**: Background job tracking
- **User Sessions**: Active user sessions

## 🚀 Deployment

### Production Deployment
```bash
# Build Flutter web
flutter build web

# Build Docker images
docker-compose -f docker-compose.prod.yml build

# Deploy to production
docker-compose -f docker-compose.prod.yml up -d
```

### Environment Variables
Key environment variables for production:
- `NODE_ENV=production`
- `DATABASE_URL`
- `JWT_SECRET`
- `AWS_ACCESS_KEY_ID`
- `GOOGLE_CLOUD_PROJECT_ID`
- `OPENAI_API_KEY`

## 🧪 Testing

### Frontend Testing
```bash
# Run unit tests
flutter test

# Run widget tests
flutter test test/widget_test.dart

# Run integration tests
flutter test integration_test/
```

### Backend Testing
```bash
# Run tests
npm test

# Run with coverage
npm run test:coverage

# Run specific test file
npm test -- --testNamePattern="auth"
```

## 📈 Performance Optimization

- **Image Compression**: Automatic image optimization
- **Lazy Loading**: Progressive document loading
- **Caching**: Redis-based caching strategy
- **Background Processing**: Queue-based job processing
- **Database Indexing**: Optimized query performance
- **CDN Integration**: Static asset delivery

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Workflow
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Flutter Team**: For the amazing cross-platform framework
- **Node.js Community**: For the robust backend ecosystem
- **AI Service Providers**: Google Cloud Vision, OpenAI, HuggingFace
- **Open Source Contributors**: All the packages and libraries used

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/ai-document-master/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/ai-document-master/discussions)
- **Email**: support@aidocumentmaster.com

## 🌟 Star History

[![Star History Chart](https://api.star-history.com/svg?repos=yourusername/ai-document-master&type=Date)](https://star-history.com/#yourusername/ai-document-master&Date)

---

**Made with ❤️ by the AI Document Master Team**

*Empowering education and business through intelligent document processing*
