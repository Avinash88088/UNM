const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
const initializeFirebaseAdmin = () => {
  try {
    // Check if already initialized
    if (admin.apps.length > 0) {
      console.log('✅ Firebase Admin SDK already initialized');
      return admin.apps[0];
    }

    // For development mode, use default credentials
    if (process.env.NODE_ENV === 'development') {
      console.log('🔧 Development mode: Using default Firebase credentials');
      
      admin.initializeApp({
        projectId: process.env.FIREBASE_PROJECT_ID || 'universal-document-master',
        databaseURL: process.env.FIREBASE_DATABASE_URL || 'https://universal-document-master.firebaseio.com',
        storageBucket: process.env.FIREBASE_STORAGE_BUCKET || 'universal-document-master.appspot.com'
      });
      
      console.log('✅ Firebase Admin SDK initialized successfully in development mode');
      return admin.app();
    }

    // For production, use service account
    const serviceAccount = process.env.FIREBASE_SERVICE_ACCOUNT_KEY;
    
    if (serviceAccount) {
      try {
        const serviceAccountKey = JSON.parse(serviceAccount);
        admin.initializeApp({
          credential: admin.credential.cert(serviceAccountKey),
          databaseURL: process.env.FIREBASE_DATABASE_URL || `https://${process.env.FIREBASE_PROJECT_ID}.firebaseio.com`,
          storageBucket: process.env.FIREBASE_STORAGE_BUCKET || `${process.env.FIREBASE_PROJECT_ID}.appspot.com`
        });
        console.log('✅ Firebase Admin SDK initialized successfully with service account');
      } catch (parseError) {
        console.error('❌ Failed to parse Firebase service account key:', parseError);
        throw new Error('Invalid Firebase service account configuration');
      }
    } else {
      console.log('⚠️ No Firebase service account key found, using default credentials');
      admin.initializeApp({
        projectId: process.env.FIREBASE_PROJECT_ID || 'universal-document-master',
        databaseURL: process.env.FIREBASE_DATABASE_URL || 'https://universal-document-master.firebaseio.com',
        storageBucket: process.env.FIREBASE_STORAGE_BUCKET || 'universal-document-master.appspot.com'
      });
    }

    return admin.app();
  } catch (error) {
    console.error('❌ Firebase Admin SDK initialization failed:', error);
    
    // For development, continue without Firebase
    if (process.env.NODE_ENV === 'development') {
      console.log('⚠️ Continuing without Firebase in development mode');
      return null;
    }
    
    throw error;
  }
};

// Get Firestore instance
const getFirestore = () => {
  try {
    return admin.firestore();
  } catch (error) {
    console.warn('⚠️ Firestore not available:', error.message);
    return null;
  }
};

// Get Auth instance
const getAuth = () => {
  try {
    return admin.auth();
  } catch (error) {
    console.warn('⚠️ Firebase Auth not available:', error.message);
    return null;
  }
};

// Get Storage instance
const getStorage = () => {
  try {
    return admin.storage();
  } catch (error) {
    console.warn('⚠️ Firebase Storage not available:', error.message);
    return null;
  }
};

module.exports = {
  initializeFirebaseAdmin,
  getFirestore,
  getAuth,
  getStorage,
  admin
};

