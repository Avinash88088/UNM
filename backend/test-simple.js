const axios = require('axios');

const BASE_URL = 'http://localhost:3000';

async function testEndpoints() {
  console.log('🧪 Testing AI Document Master API...\n');

  try {
    // Test 1: Health Check
    console.log('1️⃣ Testing Health Endpoint...');
    const healthResponse = await axios.get(`${BASE_URL}/health`);
    console.log('✅ Health Check:', healthResponse.data.message);
    console.log(`📊 Environment: ${healthResponse.data.environment}`);
    console.log(`🕐 Timestamp: ${healthResponse.data.timestamp}\n`);

    // Test 2: AI Test Endpoint
    console.log('2️⃣ Testing AI Test Endpoint...');
    const aiTestResponse = await axios.post(`${BASE_URL}/api/ai/test`);
    console.log('✅ AI Test:', aiTestResponse.data.message);
    console.log(`🔑 Gemini Status: ${aiTestResponse.data.gemini_key}\n`);

    // Test 3: Question Generation
    console.log('3️⃣ Testing Question Generation...');
    const questionResponse = await axios.post(`${BASE_URL}/api/ai/generate-questions`, {
      documentContent: 'Artificial Intelligence (AI) is transforming document processing. AI can extract text from images, recognize handwriting, and generate intelligent questions from content.',
      count: 2,
      difficulty: 'medium'
    });
    
    console.log('✅ Question Generation:', questionResponse.data.message);
    console.log(`📝 Generated ${questionResponse.data.questions.length} questions`);
    console.log(`🔑 Source: ${questionResponse.data.source}`);
    console.log(`🤖 Gemini Status: ${questionResponse.data.gemini_status}\n`);

    console.log('🎉 All endpoints tested successfully!');
    console.log('\n📋 Summary:');
    console.log('✅ Health endpoint working');
    console.log('✅ AI test endpoint working');
    console.log('✅ Question generation working');
    console.log(`🔑 Gemini API: ${questionResponse.data.gemini_status}`);
    
  } catch (error) {
    console.error('❌ Test failed:', error.message);
    
    if (error.response) {
      console.error('📊 Response Status:', error.response.status);
      console.error('📄 Response Data:', error.response.data);
    }
    
    if (error.code === 'ECONNREFUSED') {
      console.log('💡 Tip: Make sure the server is running on port 3000');
      console.log('💡 Run: node src/server-simple-working.js');
    }
  }
}

// Run test
testEndpoints();
