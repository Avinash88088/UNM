const axios = require('axios');

const BASE_URL = 'http://localhost:3000';

async function testAllEndpoints() {
  console.log('🧪 Testing Complete AI Document Master API...\n');

  try {
    // Test 1: Health Check
    console.log('1️⃣ Testing Health Endpoint...');
    const healthResponse = await axios.get(`${BASE_URL}/health`);
    console.log('✅ Health Check:', healthResponse.data.message);
    console.log(`📊 Environment: ${healthResponse.data.environment}`);
    console.log(`🔑 Gemini: ${healthResponse.data.services.gemini}`);
    console.log(`🤖 OpenAI: ${healthResponse.data.services.openai}`);
    console.log(`🔥 Firebase: ${healthResponse.data.services.firebase}\n`);

    // Test 2: AI Test Endpoint
    console.log('2️⃣ Testing AI Test Endpoint...');
    const aiTestResponse = await axios.post(`${BASE_URL}/api/ai/test`);
    console.log('✅ AI Test:', aiTestResponse.data.message);
    console.log(`🔑 Gemini Status: ${aiTestResponse.data.gemini_key}\n`);

    // Test 3: Question Generation
    console.log('3️⃣ Testing Question Generation...');
    const questionResponse = await axios.post(`${BASE_URL}/api/ai/generate-questions`, {
      documentContent: 'Artificial Intelligence (AI) is transforming document processing. AI can extract text from images, recognize handwriting, and generate intelligent questions from content. Machine learning algorithms process vast amounts of data to identify patterns and make predictions.',
      count: 3,
      difficulty: 'medium',
      questionTypes: ['multiple_choice', 'short_answer']
    });
    
    console.log('✅ Question Generation:', questionResponse.data.message);
    console.log(`📝 Generated ${questionResponse.data.questions.length} questions`);
    console.log(`🔑 Source: ${questionResponse.data.source}`);
    console.log(`⏱️ Processing Time: ${questionResponse.data.processing_time || 'N/A'}ms\n`);

    // Test 4: Document Summary
    console.log('4️⃣ Testing Document Summary...');
    const summaryResponse = await axios.post(`${BASE_URL}/api/ai/generate-summary`, {
      documentContent: 'Machine learning algorithms can process vast amounts of data to identify patterns and make predictions. This technology is revolutionizing industries from healthcare to finance. AI systems can now understand natural language, process images, and make decisions with human-like accuracy.',
      summaryType: 'technical',
      maxLength: 100
    });
    
    console.log('✅ Document Summary:', summaryResponse.data.message);
    console.log(`📄 Summary: ${summaryResponse.data.summary.substring(0, 100)}...`);
    console.log(`🔑 Source: ${summaryResponse.data.source}`);
    console.log(`⏱️ Processing Time: ${summaryResponse.data.processing_time || 'N/A'}ms\n`);

    // Test 5: OCR Processing
    console.log('5️⃣ Testing OCR Processing...');
    const ocrResponse = await axios.post(`${BASE_URL}/api/ai/ocr`, {
      imageUrl: 'sample_image_data',
      language: 'en'
    });
    
    console.log('✅ OCR Processing:', ocrResponse.data.message);
    console.log(`📝 Extracted Text: ${ocrResponse.data.result.text.substring(0, 50)}...`);
    console.log(`🔑 Source: ${ocrResponse.data.result.source}`);
    console.log(`⏱️ Processing Time: ${ocrResponse.data.result.processing_time || 'N/A'}ms\n`);

    // Test 6: Handwriting Recognition
    console.log('6️⃣ Testing Handwriting Recognition...');
    const hwrResponse = await axios.post(`${BASE_URL}/api/ai/handwriting`, {
      imageUrl: 'sample_handwritten_image',
      language: 'en'
    });
    
    console.log('✅ Handwriting Recognition:', hwrResponse.data.message);
    console.log(`📝 Recognized Text: ${hwrResponse.data.result.text}`);
    console.log(`🔑 Source: ${hwrResponse.data.result.source}`);
    console.log(`⏱️ Processing Time: ${hwrResponse.data.result.processing_time || 'N/A'}ms\n`);

    console.log('🎉 All AI endpoints tested successfully!');
    console.log('\n📋 Complete Summary:');
    console.log('✅ Health endpoint working');
    console.log('✅ AI test endpoint working');
    console.log('✅ Question generation working');
    console.log('✅ Document summary working');
    console.log('✅ OCR processing working');
    console.log('✅ Handwriting recognition working');
    console.log(`🔑 Gemini API: ${healthResponse.data.services.gemini}`);
    console.log(`🤖 OpenAI API: ${healthResponse.data.services.openai}`);
    console.log(`🔥 Firebase: ${healthResponse.data.services.firebase}`);
    
  } catch (error) {
    console.error('❌ Test failed:', error.message);
    
    if (error.response) {
      console.error('📊 Response Status:', error.response.status);
      console.error('📄 Response Data:', error.response.data);
    }
    
    if (error.code === 'ECONNREFUSED') {
      console.log('💡 Tip: Make sure the server is running on port 3000');
      console.log('💡 Run: node src/server-complete.js');
    }
  }
}

// Run test
console.log('🚀 Starting Complete AI Integration Test...\n');
testAllEndpoints();
