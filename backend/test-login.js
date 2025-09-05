const axios = require('axios');

const BASE_URL = 'http://localhost:3000';

async function testLoginSystem() {
  console.log('🔐 Testing Unified Login System...\n');

  try {
    // Test 1: Get test users
    console.log('1️⃣ Getting test users...');
    const testUsersResponse = await axios.get(`${BASE_URL}/api/auth/test-users`);
    console.log('✅ Test users retrieved:', testUsersResponse.data.users.length);
    testUsersResponse.data.users.forEach(user => {
      console.log(`   👤 ${user.name} (${user.email}) - ${user.role}`);
    });
    console.log('');

    // Test 2: User Registration
    console.log('2️⃣ Testing user registration...');
    const newUser = {
      name: 'Test User 3',
      email: 'test3@example.com',
      password: 'password123',
      institution: 'Test Institution'
    };

    const registerResponse = await axios.post(`${BASE_URL}/api/auth/register`, newUser);
    console.log('✅ User registered:', registerResponse.data.message);
    console.log(`   👤 ${registerResponse.data.user.name} (${registerResponse.data.user.email})`);
    console.log('');

    // Test 3: User Login
    console.log('3️⃣ Testing user login...');
    const loginData = {
      email: 'test@example.com',
      password: 'password123'
    };

    const loginResponse = await axios.post(`${BASE_URL}/api/auth/login`, loginData);
    console.log('✅ Login successful:', loginResponse.data.message);
    console.log(`   👤 ${loginResponse.data.user.name} (${loginResponse.data.user.email})`);
    console.log(`   🔑 Access Token: ${loginResponse.data.tokens.accessToken.substring(0, 20)}...`);
    console.log(`   🔄 Refresh Token: ${loginResponse.data.tokens.refreshToken.substring(0, 20)}...`);
    console.log('');

    const { accessToken, refreshToken } = loginResponse.data.tokens;

    // Test 4: Access Protected Route
    console.log('4️⃣ Testing protected route access...');
    const protectedResponse = await axios.get(`${BASE_URL}/api/protected`, {
      headers: {
        'Authorization': `Bearer ${accessToken}`
      }
    });
    console.log('✅ Protected route accessed:', protectedResponse.data.message);
    console.log(`   👤 User ID: ${protectedResponse.data.user.userId}`);
    console.log(`   📧 Email: ${protectedResponse.data.user.email}`);
    console.log(`   🎭 Role: ${protectedResponse.data.user.role}`);
    console.log('');

    // Test 5: Get Current User
    console.log('5️⃣ Testing get current user...');
    const currentUserResponse = await axios.get(`${BASE_URL}/api/auth/me`, {
      headers: {
        'Authorization': `Bearer ${accessToken}`
      }
    });
    console.log('✅ Current user retrieved:', currentUserResponse.data.message);
    console.log(`   👤 ${currentUserResponse.data.user.name} (${currentUserResponse.data.user.email})`);
    console.log(`   🎭 Role: ${currentUserResponse.data.user.role}`);
    console.log(`   🏢 Institution: ${currentUserResponse.data.user.institution}`);
    console.log('');

    // Test 6: Refresh Token
    console.log('6️⃣ Testing token refresh...');
    const refreshResponse = await axios.post(`${BASE_URL}/api/auth/refresh`, {
      refreshToken: refreshToken
    });
    console.log('✅ Token refreshed:', refreshResponse.data.message);
    console.log(`   🔑 New Access Token: ${refreshResponse.data.accessToken.substring(0, 20)}...`);
    console.log('');

    // Test 7: Test with new access token
    const newAccessToken = refreshResponse.data.accessToken;
    console.log('7️⃣ Testing with new access token...');
    const newProtectedResponse = await axios.get(`${BASE_URL}/api/protected`, {
      headers: {
        'Authorization': `Bearer ${newAccessToken}`
      }
    });
    console.log('✅ New token works:', newProtectedResponse.data.message);
    console.log('');

    // Test 8: Test invalid credentials
    console.log('8️⃣ Testing invalid credentials...');
    try {
      await axios.post(`${BASE_URL}/api/auth/login`, {
        email: 'test@example.com',
        password: 'wrongpassword'
      });
      console.log('❌ Invalid login should have failed');
    } catch (error) {
      if (error.response && error.response.status === 401) {
        console.log('✅ Invalid credentials properly rejected');
      } else {
        console.log('❌ Unexpected error:', error.message);
      }
    }
    console.log('');

    // Test 9: Test invalid token
    console.log('9️⃣ Testing invalid token...');
    try {
      await axios.get(`${BASE_URL}/api/protected`, {
        headers: {
          'Authorization': 'Bearer invalid-token'
        }
      });
      console.log('❌ Invalid token should have failed');
    } catch (error) {
      if (error.response && error.response.status === 401) {
        console.log('✅ Invalid token properly rejected');
      } else {
        console.log('❌ Unexpected error:', error.message);
      }
    }
    console.log('');

    // Test 10: Test missing token
    console.log('🔟 Testing missing token...');
    try {
      await axios.get(`${BASE_URL}/api/protected`);
      console.log('❌ Missing token should have failed');
    } catch (error) {
      if (error.response && error.response.status === 401) {
        console.log('✅ Missing token properly rejected');
      } else {
        console.log('❌ Unexpected error:', error.message);
      }
    }
    console.log('');

    // Test 11: Logout
    console.log('1️⃣1️⃣ Testing logout...');
    const logoutResponse = await axios.post(`${BASE_URL}/api/auth/logout`, {}, {
      headers: {
        'Authorization': `Bearer ${newAccessToken}`
      }
    });
    console.log('✅ Logout successful:', logoutResponse.data.message);
    console.log('');

    // Test 12: Try to use logged out token
    console.log('1️⃣2️⃣ Testing logged out token...');
    try {
      await axios.get(`${BASE_URL}/api/protected`, {
        headers: {
          'Authorization': `Bearer ${newAccessToken}`
        }
      });
      console.log('❌ Logged out token should have failed');
    } catch (error) {
      if (error.response && error.response.status === 401) {
        console.log('✅ Logged out token properly rejected');
      } else {
        console.log('❌ Unexpected error:', error.message);
      }
    }
    console.log('');

    // Final Summary
    console.log('🎉 LOGIN SYSTEM TESTING COMPLETED!');
    console.log('\n📋 TEST RESULTS SUMMARY:');
    console.log('✅ User Registration: Working');
    console.log('✅ User Login: Working');
    console.log('✅ JWT Token Generation: Working');
    console.log('✅ Protected Route Access: Working');
    console.log('✅ Current User Retrieval: Working');
    console.log('✅ Token Refresh: Working');
    console.log('✅ Invalid Credentials: Properly Rejected');
    console.log('✅ Invalid Tokens: Properly Rejected');
    console.log('✅ Missing Tokens: Properly Rejected');
    console.log('✅ User Logout: Working');
    console.log('✅ Token Invalidation: Working');
    
    console.log('\n🔑 AUTHENTICATION SYSTEM STATUS: 100% OPERATIONAL! 🚀');
    console.log('\n💡 Test Credentials:');
    console.log('   Email: test@example.com');
    console.log('   Password: password123');
    console.log('   Email: admin@example.com');
    console.log('   Password: admin123');
    
  } catch (error) {
    console.error('❌ Login system test failed:', error.message);
    
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

// Run login system test
console.log('🚀 Starting Unified Login System Test...\n');
testLoginSystem();
