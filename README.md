# 🚀 AI Document Master (UDM) - Universal Document Management System

[![Flutter](https://img.shields.io/badge/Flutter-3.16+-blue.svg)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.0+-blue.svg)](https://dart.dev/)
[![Node.js](https://img.shields.io/badge/Node.js-18+-green.svg)](https://nodejs.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-14+-blue.svg)](https://www.postgresql.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Status](https://img.shields.io/badge/Status-Production%20Ready-green.svg)](https://github.com/Avinash88088/UNM)

> **🎉 COMPLETELY REDESIGNED! Modern dark theme, fully functional UI, and production-ready AI document processing system**

## 🌟 Overview

AI Document Master (UDM) is a **completely redesigned** document management system featuring a **modern dark theme**, **smooth animations**, and **fully functional UI**. The app combines Flutter's cross-platform capabilities with advanced AI services for OCR, handwriting recognition, and intelligent question generation.

### ✨ **Latest Updates (v2.0)**
- 🎨 **Complete UI Redesign** with modern dark theme
- 🚀 **Fully Functional Home Screen** with all navigation working
- 💫 **Smooth Animations** and gradient backgrounds
- 🔧 **All Compilation Errors Fixed** - production ready
- 📱 **Responsive Design** that works on all screen sizes
- 🎯 **Professional UX** with Material Design 3

## ✨ Features

### 📱 **Frontend (Flutter) - COMPLETELY REDESIGNED**
- **🎨 Modern Dark Theme**: Professional gradient UI with smooth animations
- **🏠 Functional Home Screen**: Complete redesign with 6 action buttons, 3 quick actions, 9 document cards
- **📱 Responsive Design**: Works perfectly on all screen sizes
- **💫 Smooth Animations**: Fade, slide, and scale animations throughout
- **🔧 All Navigation Working**: Every button properly connected and functional
- **🎯 Professional UX**: Material Design 3 with custom dark theme system
- **📊 Document Management**: Upload, view, organize documents with beautiful UI
- **⚡ Real-time Processing**: Live updates on document processing status
- **🌐 Multi-language**: Hindi, English, and regional script support

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
git clone https://github.com/Avinash88088/UNM.git
cd UNM

# Install Flutter dependencies
flutter pub get

# Run the app (Android)
flutter run

# Run the app (Web)
flutter run -d chrome

# Run the app (Windows - if configured)
flutter run -d windows
```

### 🎯 **App Status**
- ✅ **Successfully running** on Android device
- ✅ **Firebase authentication** working
- ✅ **All features functional** and connected
- ✅ **Professional UI/UX** with modern design
- ✅ **No compilation errors** - production ready

## 🎨 **New UI Features (v2.0)**

### 🏠 **Home Screen Redesign**
- **Gradient Header**: Beautiful blue-purple gradient with welcome message and profile avatar
- **Action Grid (6 buttons)**: Profile, Messages, Documents, Upload, Analytics, AI Tools
- **Quick Actions (3 buttons)**: OCR Process, Upload Doc, AI Generate with arrow indicators
- **Document Library (9 cards)**: Recent Docs, Tables, AI Network, Settings, Desktop, Analytics, Reports, Archive, More
- **Bottom Navigation (6 tabs)**: Home, Docs, Grid, Search, Settings, Menu

### 🎨 **Design System**
- **DarkTheme Class**: Comprehensive theme system with professional color palette
- **Gradient Backgrounds**: Beautiful gradients throughout the UI
- **Shadow Effects**: Subtle shadows for depth and elevation
- **Smooth Animations**: Fade, slide, and scale animations
- **Responsive Layout**: Works on all screen sizes
- **Material Design 3**: Modern design principles

### 🔧 **Technical Improvements**
- **Fixed All Errors**: No compilation issues
- **AppStrings Constants**: Centralized string management
- **Question Model**: Proper enums and properties
- **Error Handling**: Try-catch blocks throughout
- **Performance**: Optimized animations and layout

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
UNM/
├── lib/                           # Flutter source code
│   ├── models/                   # Data models
│   │   ├── user.dart            # User model
│   │   └── question_model.dart   # Question model with enums
│   ├── screens/                  # UI screens
│   │   ├── home_screen.dart     # 🆕 Redesigned home screen
│   │   ├── splash_screen.dart   # 🆕 Custom splash screen
│   │   ├── upload_screen.dart   # Document upload screen
│   │   ├── document_results_screen.dart # 🆕 Results display
│   │   ├── theme_customization_screen.dart # 🆕 Theme settings
│   │   └── auth/
│   │       └── login_screen_premium.dart # Premium login screen
│   ├── widgets/                  # Reusable widgets
│   │   ├── custom_button.dart   # Custom button widget
│   │   ├── custom_text_field.dart # Custom text field
│   │   └── loading_overlay.dart # 🆕 Loading overlay
│   ├── services/                 # API services
│   │   ├── api_client.dart      # HTTP client
│   │   ├── auth_service.dart    # Authentication service
│   │   ├── document_service.dart # Document management
│   │   ├── advanced_ocr_service.dart # OCR processing
│   │   ├── image_processing_service.dart # Image processing
│   │   └── socket_service.dart  # WebSocket service
│   ├── providers/                # State management
│   │   ├── app_provider.dart    # Main app provider
│   │   ├── auth_provider.dart   # 🆕 Auth provider
│   │   └── theme_provider.dart  # 🆕 Theme provider
│   └── utils/                    # Utilities and constants
│       ├── app_theme.dart       # App theme configuration
│       ├── dark_theme.dart      # 🆕 Dark theme system
│       ├── constants.dart       # App constants and strings
│       └── validators.dart      # 🆕 Input validators
├── backend/                      # Node.js backend
│   ├── src/                      # Source code
│   │   ├── routes/              # API routes
│   │   ├── middleware/          # Middleware functions
│   │   ├── controllers/         # API controllers
│   │   ├── config/              # Configuration files
│   │   └── utils/               # Utility functions
│   ├── package.json             # Dependencies
│   └── .env.example             # Environment variables
├── assets/                       # 🆕 App assets
│   └── images/                  # Images and icons
├── android/                      # Android-specific files
│   └── app/src/main/res/        # Android resources
├── ios/                          # iOS-specific files
└── web/                          # Web-specific files
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

- **Repository**: [GitHub Repository](https://github.com/Avinash88088/UNM)
- **Issues**: [GitHub Issues](https://github.com/Avinash88088/UNM/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Avinash88088/UNM/discussions)
- **Email**: support@aidocumentmaster.com

## 🌟 Star History

[![Star History Chart](https://api.star-history.com/svg?repos=Avinash88088/UNM&type=Date)](https://star-history.com/#Avinash88088/UNM&Date)

---

**Made with ❤️ by the AI Document Master Team**

*Empowering education and business through intelligent document processing*
