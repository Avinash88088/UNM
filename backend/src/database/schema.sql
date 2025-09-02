-- AI Document Master Database Schema
-- PostgreSQL 15+

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create custom types
CREATE TYPE user_role AS ENUM ('student', 'teacher', 'admin', 'super_admin');
CREATE TYPE document_status AS ENUM ('uploaded', 'processing', 'completed', 'failed', 'archived');
CREATE TYPE question_type AS ENUM ('multiple_choice', 'true_false', 'fill_blank', 'short_answer', 'essay');
CREATE TYPE question_difficulty AS ENUM ('easy', 'medium', 'hard', 'expert');
CREATE TYPE job_type AS ENUM ('ocr', 'hwr', 'question_generation', 'summarization');
CREATE TYPE job_status AS ENUM ('pending', 'running', 'completed', 'failed', 'cancelled');

-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20) UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    role user_role NOT NULL DEFAULT 'student',
    institution_id UUID,
    is_active BOOLEAN DEFAULT true,
    email_verified BOOLEAN DEFAULT false,
    phone_verified BOOLEAN DEFAULT false,
    avatar_url TEXT,
    preferences JSONB DEFAULT '{}',
    last_login TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Institutions table
CREATE TABLE institutions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    type VARCHAR(100),
    address TEXT,
    contact_email VARCHAR(255),
    contact_phone VARCHAR(20),
    website TEXT,
    logo_url TEXT,
    settings JSONB DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Add foreign key constraint for institutions
ALTER TABLE users ADD CONSTRAINT fk_users_institution 
    FOREIGN KEY (institution_id) REFERENCES institutions(id) ON DELETE SET NULL;

-- Documents table
CREATE TABLE documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
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
    metadata JSONB DEFAULT '{}',
    tags TEXT[],
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP
);

-- Document pages table
CREATE TABLE document_pages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    page_number INTEGER NOT NULL,
    image_url TEXT NOT NULL,
    thumbnail_url TEXT,
    ocr_text TEXT,
    ocr_confidence DECIMAL(5,2),
    handwriting_text TEXT,
    handwriting_confidence DECIMAL(5,2),
    layout_analysis JSONB DEFAULT '{}',
    word_coordinates JSONB DEFAULT '[]',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(document_id, page_number)
);

-- Question sets table
CREATE TABLE question_sets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    document_id UUID REFERENCES documents(id) ON DELETE SET NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    overall_difficulty question_difficulty DEFAULT 'medium',
    total_questions INTEGER DEFAULT 0,
    total_marks INTEGER DEFAULT 0,
    marks_distribution JSONB DEFAULT '{}',
    subject VARCHAR(100),
    grade VARCHAR(50),
    tags TEXT[],
    metadata JSONB DEFAULT '{}',
    is_public BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Questions table
CREATE TABLE questions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    question_set_id UUID NOT NULL REFERENCES question_sets(id) ON DELETE CASCADE,
    question_text TEXT NOT NULL,
    question_type question_type NOT NULL,
    difficulty question_difficulty DEFAULT 'medium',
    options JSONB DEFAULT '[]',
    correct_answer TEXT,
    explanation TEXT,
    confidence_score DECIMAL(5,2),
    source_text TEXT,
    source_page_number INTEGER,
    marks INTEGER DEFAULT 1,
    tags TEXT[],
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Processing jobs table
CREATE TABLE processing_jobs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    job_type job_type NOT NULL,
    status job_status DEFAULT 'pending',
    priority INTEGER DEFAULT 5,
    progress INTEGER DEFAULT 0,
    result_data JSONB DEFAULT '{}',
    error_message TEXT,
    retry_count INTEGER DEFAULT 0,
    max_retries INTEGER DEFAULT 3,
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- User sessions table
CREATE TABLE user_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    refresh_token_hash VARCHAR(255) NOT NULL,
    device_info JSONB DEFAULT '{}',
    ip_address INET,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Document sharing table
CREATE TABLE document_sharing (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    shared_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    shared_with UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    permission VARCHAR(50) DEFAULT 'read', -- read, write, admin
    expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(document_id, shared_with)
);

-- Batch processing table
CREATE TABLE batch_jobs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    batch_name VARCHAR(255) NOT NULL,
    created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    total_files INTEGER DEFAULT 0,
    processed_files INTEGER DEFAULT 0,
    failed_files INTEGER DEFAULT 0,
    status job_status DEFAULT 'pending',
    progress INTEGER DEFAULT 0,
    settings JSONB DEFAULT '{}',
    error_summary JSONB DEFAULT '[]',
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Batch files table
CREATE TABLE batch_files (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    batch_id UUID NOT NULL REFERENCES batch_jobs(id) ON DELETE CASCADE,
    document_id UUID REFERENCES documents(id) ON DELETE SET NULL,
    original_filename VARCHAR(255) NOT NULL,
    status document_status DEFAULT 'uploaded',
    error_message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_institution ON users(institution_id);
CREATE INDEX idx_users_created_at ON users(created_at);

CREATE INDEX idx_documents_user_id ON documents(user_id);
CREATE INDEX idx_documents_status ON documents(status);
CREATE INDEX idx_documents_language ON documents(language);
CREATE INDEX idx_documents_created_at ON documents(created_at);
CREATE INDEX idx_documents_file_type ON documents(file_type);

CREATE INDEX idx_document_pages_document_id ON document_pages(document_id);
CREATE INDEX idx_document_pages_page_number ON document_pages(page_number);

CREATE INDEX idx_question_sets_document_id ON question_sets(document_id);
CREATE INDEX idx_question_sets_created_by ON question_sets(created_by);
CREATE INDEX idx_question_sets_difficulty ON question_sets(overall_difficulty);
CREATE INDEX idx_question_sets_subject ON question_sets(subject);

CREATE INDEX idx_questions_question_set_id ON questions(question_set_id);
CREATE INDEX idx_questions_type ON questions(question_type);
CREATE INDEX idx_questions_difficulty ON questions(difficulty);

CREATE INDEX idx_processing_jobs_document_id ON processing_jobs(document_id);
CREATE INDEX idx_processing_jobs_status ON processing_jobs(status);
CREATE INDEX idx_processing_jobs_type ON processing_jobs(job_type);
CREATE INDEX idx_processing_jobs_priority ON processing_jobs(priority);

CREATE INDEX idx_user_sessions_user_id ON user_sessions(user_id);
CREATE INDEX idx_user_sessions_refresh_token ON user_sessions(refresh_token_hash);
CREATE INDEX idx_user_sessions_expires_at ON user_sessions(expires_at);

CREATE INDEX idx_document_sharing_document_id ON document_sharing(document_id);
CREATE INDEX idx_document_sharing_shared_with ON document_sharing(shared_with);

CREATE INDEX idx_batch_jobs_created_by ON batch_jobs(created_by);
CREATE INDEX idx_batch_jobs_status ON batch_jobs(status);
CREATE INDEX idx_batch_jobs_created_at ON batch_jobs(created_at);

CREATE INDEX idx_batch_files_batch_id ON batch_files(batch_id);
CREATE INDEX idx_batch_files_status ON batch_files(status);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply updated_at trigger to relevant tables
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_documents_updated_at BEFORE UPDATE ON documents
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_question_sets_updated_at BEFORE UPDATE ON question_sets
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_batch_jobs_updated_at BEFORE UPDATE ON batch_jobs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create full-text search indexes
CREATE INDEX idx_documents_fts ON documents USING gin(to_tsvector('english', file_name || ' ' || COALESCE(metadata::text, '')));
CREATE INDEX idx_questions_fts ON questions USING gin(to_tsvector('english', question_text || ' ' || COALESCE(explanation, '')));

-- Insert default super admin user (password: admin123)
INSERT INTO users (email, password_hash, first_name, last_name, role, is_active, email_verified) 
VALUES ('admin@aidocumentmaster.com', '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4J/vHhHwqG', 'Super', 'Admin', 'super_admin', true, true);

-- Insert default institution
INSERT INTO institutions (name, type, contact_email, is_active) 
VALUES ('AI Document Master', 'organization', 'admin@aidocumentmaster.com', true);

-- Update admin user with institution
UPDATE users SET institution_id = (SELECT id FROM institutions LIMIT 1) WHERE email = 'admin@aidocumentmaster.com';
