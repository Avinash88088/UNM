const axios = require('axios');

const BASE_URL = 'http://localhost:3000';

// Test AI endpoints
async function testAIEndpoints() {
  console.log('🧪 Testing AI Endpoints...\n');

  try {
    // Test 1: Question Generation
    console.log('1️⃣ Testing Question Generation...');
    const questionResponse = await axios.post(`${BASE_URL}/api/ai/generate-questions`, {
      documentContent: 'Artificial Intelligence (AI) is transforming the way we process documents. AI can extract text from images, recognize handwriting, and generate intelligent questions from content.',
      count: 3,
      difficulty: 'medium',
      questionTypes: ['multiple_choice', 'short_answer']
    });
    
    console.log('✅ Question Generation:', questionResponse.data.message);
    console.log(`📝 Generated ${questionResponse.data.questions.length} questions`);
    console.log(`🔑 Source: ${questionResponse.data.source}\n`);

    // Test 2: Document Summary
    console.log('2️⃣ Testing Document Summary...');
    const summaryResponse = await axios.post(`${BASE_URL}/api/ai/generate-summary`, {
      documentContent: 'Machine learning algorithms can process vast amounts of data to identify patterns and make predictions. This technology is revolutionizing industries from healthcare to finance.',
      summaryType: 'technical',
      maxLength: 100
    });
    
    console.log('✅ Document Summary:', summaryResponse.data.message);
    console.log(`📄 Summary: ${summaryResponse.data.summary.substring(0, 100)}...`);
    console.log(`🔑 Source: ${summaryResponse.data.source}\n`);

    // Test 3: Image Enhancement Analysis
    console.log('3️⃣ Testing Image Enhancement Analysis...');
    const enhancementResponse = await axios.post(`${BASE_URL}/api/ai/enhance-image`, {
      imageUrl: 'sample_image_data',
      enhancements: ['brightness', 'contrast', 'sharpness'],
      context: 'Document image for OCR processing'
    });
    
    console.log('✅ Image Enhancement:', enhancementResponse.data.message);
    console.log(`🔧 Enhancements: ${enhancementResponse.data.result.enhancements.join(', ')}`);
    console.log(`🔑 Source: ${enhancementResponse.data.source}\n`);

    console.log('🎉 All AI endpoints tested successfully!');
    
  } catch (error) {
    console.error('❌ Test failed:', error.response?.data || error.message);
    
    if (error.response?.status === 401) {
      console.log('💡 Tip: Authentication required. Make sure to include valid JWT token.');
    }
  }
}

// Test health endpoint
async function testHealth() {
  try {
    const response = await axios.get(`${BASE_URL}/health`);
    console.log('🏥 Health Check:', response.data.message);
    console.log(`📊 Environment: ${response.data.environment}`);
    console.log(`🕐 Timestamp: ${response.data.timestamp}\n`);
  } catch (error) {
    console.error('❌ Health check failed:', error.message);
  }
}

// Run tests
async function runTests() {
  console.log('🚀 Starting AI Integration Tests...\n');
  
  await testHealth();
  await testAIEndpoints();
  
  console.log('\n✨ Testing completed!');
}

// Run if called directly
if (require.main === module) {
  runTests().catch(console.error);
}

module.exports = { testAIEndpoints, testHealth };
