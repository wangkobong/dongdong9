
const functions = require('firebase-functions');
import * as admin from "firebase-admin";

// Firebase Admin SDK 초기화
admin.initializeApp();
const db = admin.firestore();

// --- 함수 1: 신규 사용자 자동 생성 (Auth 트리거) ---
/**
 * Firebase Authentication에 새로운 사용자가 생성될 때마다 실행됩니다.
 * Firestore의 'users' 컬렉션에 해당 사용자의 프로필 문서를 자동으로 생성합니다.
 */
export const onUserCreate = functions.https.onCall(async (data: any, context: any) => {
  console.log('=== FULL DEBUG INFO ===');
  console.log('typeof data:', typeof data);
  console.log('data:', data);
  console.log('data keys:', data ? Object.keys(data) : 'data is null/undefined');
  
  // 혹시 data가 다른 구조일 가능성 체크
  if (data && data.data) {
    console.log('Found nested data.data:', data.data);
    console.log('data.data keys:', Object.keys(data.data));
  }
  
  // context도 체크
  console.log('context keys:', context ? Object.keys(context) : 'context is null');
  console.log('===========================');

  // 실제 userInfo 찾기
  let userInfo = data;
  
  // 만약 data가 wrapper 객체라면
  if (data && data.data && typeof data.data === 'object') {
    userInfo = data.data;
    console.log('Using nested data.data as userInfo');
  }
  
  console.log('Final userInfo:', userInfo);
  console.log('Final userInfo keys:', userInfo ? Object.keys(userInfo) : 'userInfo is null');
  
  if (!userInfo) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'No data received',
      { 
        originalData: data,
        dataType: typeof data,
        contextKeys: context ? Object.keys(context) : null
      }
    );
  }
  
  const userId = userInfo.userID || userInfo.uid;
  console.log('Extracted userId:', userId);
  
  if (!userId) {
    console.log('❌ Missing userID. userInfo structure:', userInfo);
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Missing userID',
      { 
        receivedKeys: Object.keys(userInfo),
        userInfo: userInfo,
        originalData: data
      }
    );
  }
  
  // 나머지 코드는 동일...
  const userRef = db.collection("users").doc(userId);
  
  const newUser = {
    userID: userId,
    email: userInfo.email || "",
    displayName: userInfo.displayName || "",
    profileImageUrl: userInfo.profileImageUrl || "",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    lastLoginAt: admin.firestore.FieldValue.serverTimestamp(),
  };
  
  try {
    await userRef.set(newUser);
    console.log(`✅ Successfully created user document for ${userId}`);
    
    return {
      status: "success",
      userID: userId,
      message: "User document created successfully"
    };
  } catch (error) {
    console.error(`❌ Error creating user document:`, error);
    throw new functions.https.HttpsError(
      'internal',
      'An error occurred while creating the user.',
      { errorMessage: String(error) }
    );
  }
});


// --- 함수 2: 가계부 생성 (호출 가능 함수) ---
/**
 * 클라이언트에서 호출하여 새로운 가계부를 생성합니다.
 * 인증된 사용자의 ID를 사용하여 'budgets' 컬렉션에 새 문서를 만듭니다.
 */
export const createBudget = functions.https.onCall(async (data: any, context: any) => {
  console.log('=== FULL DEBUG INFO ===');
  console.log('typeof data:', typeof data);
  console.log('data:', data);
  console.log('data keys:', data ? Object.keys(data) : 'data is null/undefined');
  
  // 혹시 data가 다른 구조일 가능성 체크
  if (data && data.data) {
    console.log('Found nested data.data:', data.data);
    console.log('data.data keys:', Object.keys(data.data));
  }
  
  // context도 체크
  console.log('context keys:', context ? Object.keys(context) : 'context is null');
  console.log('===========================');

  // 실제 userInfo 찾기
  let userInfo = data;
  
  // 만약 data가 wrapper 객체라면
  if (data && data.data && typeof data.data === 'object') {
    userInfo = data.data;
    console.log('Using nested data.data as userInfo');
  }
  
  console.log('Final userInfo:', userInfo);
  console.log('Final userInfo keys:', userInfo ? Object.keys(userInfo) : 'userInfo is null');
  
  if (!userInfo) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'No data received',
      { 
        originalData: data,
        dataType: typeof data,
        contextKeys: context ? Object.keys(context) : null
      }
    );
  }
  
  const userId = userInfo.userID || userInfo.uid;
  console.log('Extracted userId:', userId);
  
  if (!userId) {
    console.log('❌ Missing userID. userInfo structure:', userInfo);
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Missing userID',
      { 
        receivedKeys: Object.keys(userInfo),
        userInfo: userInfo,
        originalData: data
      }
    );
  }

  try {
    const newBudgetId = await db.runTransaction(async (transaction) => {
      const userRef = db.collection("users").doc(userId);
      const userDoc = await transaction.get(userRef);

      if (!userDoc.exists) {
        throw new functions.https.HttpsError("not-found", "User document not found.");
      }
      
      if (userDoc.data()?.budgetId) {
        throw new functions.https.HttpsError("already-exists", "User already has a budget.");
      }

      const newBudgetRef = db.collection("budgets").doc();
      const budgetData = {
        userIds: [userId],
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      };
      transaction.set(newBudgetRef, budgetData);

      transaction.update(userRef, {
        budgetId: newBudgetRef.id,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });

      return newBudgetRef.id;
    });

    console.log(`✅ Successfully created budget ${newBudgetId} for user ${userId}`);
    
    return { 
      status: "success", 
      budgetId: newBudgetId 
    };

  } catch (error) {
    console.error("❌ Transaction failed:", error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError(
      "internal",
      "An error occurred while creating the budget."
    );
  }
});