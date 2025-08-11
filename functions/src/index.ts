
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

            // ✅ 고유한 초대 코드 생성
      const inviteCode = await generateUniqueInviteCode();
      console.log(`Generated invite code: ${inviteCode}`);
      
      const budgetData = {
        userIds: [userId],
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        inviteCode: inviteCode,
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

// 초대 코드 생성 함수 (Functions 파일 최상단에 추가)
function generateInviteCode(): string {
  const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let result = '';
  for (let i = 0; i < 6; i++) {
    result += characters.charAt(Math.floor(Math.random() * characters.length));
  }
  return result;
}

// 초대 코드 중복 체크 함수
async function generateUniqueInviteCode(): Promise<string> {
  let inviteCode: string;
  let isUnique = false;
  let attempts = 0;
  const maxAttempts = 10; // 무한 루프 방지
  
  do {
    inviteCode = generateInviteCode();
    
    // 기존 초대 코드와 중복 체크
    const existingBudget = await db.collection("budgets")
      .where("inviteCode", "==", inviteCode)
      .limit(1)
      .get();
    
    isUnique = existingBudget.empty;
    attempts++;
    
    if (attempts >= maxAttempts) {
      throw new Error("Failed to generate unique invite code after multiple attempts");
    }
  } while (!isUnique);
  
  return inviteCode;
}

// --- 함수 3: 카테고리 추가 (호출 가능 함수) ---
/**
 * 클라이언트에서 호출하여 특정 가계부에 새로운 카테고리를 추가합니다.
 */
export const addCategory = functions.https.onCall(async (data: any, context: any) => {
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

  // onUserCreate를 참고하여 중첩 데이터 구조 확인
  let categoryData = data;
  // 만약 data가 wrapper 객체라면
  if (data && data.data && typeof data.data === 'object') {
    categoryData = data.data;
    console.log('Using nested data.data as categoryData');
  }

  console.log('Final categoryData:', categoryData);
  console.log('Final categoryData keys:', categoryData ? Object.keys(categoryData) : 'categoryData is null');

  // budgetId와 categoryName이 데이터에 포함되어 있는지 확인합니다.
  const { categoryId, categoryName, description, spendingMoney, subCategory, createdAt } = categoryData;
  if (!categoryId || !categoryName) {
    console.error('Validation failed: budgetId or categoryName is missing.');
    console.error('budgetId:', categoryId);
    console.error('categoryName:', categoryName);
    throw new functions.https.HttpsError(
      'invalid-argument',
      'The function must be called with "budgetId" and "categoryName" arguments.'
    );
  }

  try {
    const categoryRef = db.collection('categories').doc(categoryId);

    // 새 카테고리 문서 생성
    const newCategoryData = {
      id: categoryId,
      name: categoryName,
      description: description || "",
      spendingMoney: spendingMoney || 0,
      subCategory: subCategory || [],
      createdAt: createdAt,
      updatedAt: createdAt,
    };

    await categoryRef.set(newCategoryData);

    console.log(`✅ Successfully added category ${categoryId}`);
    console.log('--- addCategory END ---');


    return {
      status: 'success',
      categoryId: categoryId,
      message: 'Category added successfully',
    };
  } catch (error) {
    console.error('❌ Error adding category:', error);
    console.log('--- addCategory END (with error) ---');
    if (error instanceof functions.https.HttpsError) {
        throw error;
    }
    throw new functions.https.HttpsError(
      'internal',
      'An error occurred while adding the category.'
    );
  }
});