const functions = require('firebase-functions');
import * as admin from "firebase-admin";
import { onCall, HttpsError } from 'firebase-functions/v2/https';

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

  let categoryData = data;

    // 만약 data가 wrapper 객체라면
    if (data && data.data && typeof data.data === 'object') {
      categoryData = data.data;
      console.log('Using nested data.data as categoryData');
    }

    console.log('Final categoryData:', categoryData);
    console.log('Final categoryData keys:', categoryData ? Object.keys(categoryData) : 'categoryData is null');

  // budgetId와 categoryName이 데이터에 포함되어 있는지 확인합니다.
  const { budgetId, categoryName, description, spendingMoney, subCategory } = categoryData;
  if (!budgetId || !categoryName) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'The function must be called with "budgetId" and "categoryName" arguments.'
    );
  }

  try {
    const budgetRef = db.collection('budgets').doc(budgetId);
    const categoryCollectionRef = budgetRef.collection('categories');

    // 새 카테고리 문서 생성
    const newCategoryRef = categoryCollectionRef.doc();
    const newCategoryData = {
      categoryId: newCategoryRef.id,
      budgetId: budgetId, // budgetId 필드 추가
      categoryName: categoryName,
      description: description || "",
      spendingMoney: spendingMoney || 0,
      subCategory: subCategory || [],
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await newCategoryRef.set(newCategoryData);

    console.log(`✅ Successfully added category ${newCategoryRef.id} to budget ${budgetId}`);

    return {
      status: 'success',
      categoryId: newCategoryRef.id,
      message: 'Category added successfully',
    };
  } catch (error) {
    console.error('❌ Error adding category:', error);
    if (error instanceof functions.https.HttpsError) {
        throw error;
    }
    throw new functions.https.HttpsError(
      'internal',
      'An error occurred while adding the category.'
    );
  }
});

// --- 함수 4: 고정 지출 추가 (호출 가능 함수) ---
/**
 * 클라이언트에서 호출하여 특정 가계부에 새로운 고정 지출을 추가합니다.
 */
export const addFixedExpense = functions.https.onCall(async (data: any, context: any) => {
  console.log('=== FULL DEBUG INFO (addFixedExpense) ===');
  console.log('typeof data:', typeof data);
  console.log('data:', data);
  console.log('data keys:', data ? Object.keys(data) : 'data is null/undefined');

  // 혹시 data가 다른 구조일 가능성 체크 (addCategory 참고)
  if (data && data.data) {
    console.log('Found nested data.data:', data.data);
    console.log('data.data keys:', Object.keys(data.data));
  }

  // context도 체크
  console.log('context keys:', context ? Object.keys(context) : 'context is null');
  console.log('===========================');

  let fixedExpenseData = data;
  // 만약 data가 wrapper 객체라면 (addCategory 참고)
  if (data && data.data && typeof data.data === 'object') {
    fixedExpenseData = data.data;
    console.log('Using nested data.data as fixedExpenseData');
  }

  console.log('Final fixedExpenseData:', fixedExpenseData);
  console.log('Final fixedExpenseData keys:', fixedExpenseData ? Object.keys(fixedExpenseData) : 'fixedExpenseData is null');

  // 데이터 유효성 검사
  const { budgetId, name, amount } = fixedExpenseData; // Use fixedExpenseData here
  if (!budgetId || !name || amount === undefined) {
    console.error('Validation failed: budgetId, name, or amount is missing.');
    console.error('budgetId:', budgetId);
    console.error('name:', name);
    console.error('amount:', amount);
    throw new functions.https.HttpsError(
      'invalid-argument',
      'The function must be called with "budgetId", "name", and "amount" arguments.'
    );
  }

  try {
    const budgetRef = db.collection('budgets').doc(budgetId);
    const fixedExpensesCollectionRef = budgetRef.collection('fixedExpenses');

    // 새 고정 지출 문서 생성
    const newFixedExpenseRef = fixedExpensesCollectionRef.doc();
    const newFixedExpenseData = {
      fixedExpenseId: newFixedExpenseRef.id, // FixedExpenseModel에 맞게 fixedExpenseId 추가
      budgetId: budgetId,
      name: name,
      amount: amount,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await newFixedExpenseRef.set(newFixedExpenseData);

    console.log(`✅ Successfully added fixed expense ${newFixedExpenseRef.id} to budget ${budgetId}`);

    return {
      status: 'success',
      fixedExpenseId: newFixedExpenseRef.id,
      message: 'Fixed expense added successfully',
    };
  } catch (error) {
    console.error('❌ Error adding fixed expense:', error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError(
      'internal',
      'An error occurred while adding the fixed expense.'
    );
  }
});


export const updateUserIncome = onCall(async (request) => {
  console.log('=== FULL DEBUG INFO (updateUserIncome) V2 ===');
  console.log('Request timestamp:', new Date().toISOString());
  console.log('typeof request.data:', typeof request.data);
  console.log('request.data:', JSON.stringify(request.data, null, 2));
  console.log('typeof request.auth:', typeof request.auth);
  console.log('request.auth:', request.auth);
  console.log('request.auth?.uid:', request.auth?.uid);
  console.log('request.rawRequest exists:', !!request.rawRequest);
  console.log('request.rawRequest?.headers:', request.rawRequest?.headers);
  console.log('Authorization header:', request.rawRequest?.headers?.authorization ? 'Present' : 'Missing');
  console.log('Content-Type header:', request.rawRequest?.headers?.['content-type']);
  console.log('User-Agent header:', request.rawRequest?.headers?.['user-agent']);
  console.log('===========================');

  // 1. 인증 확인 (2세대에서는 request.auth 사용)
  if (!request.auth || !request.auth.uid) {
    console.log('❌ Authentication failed - no auth context or uid');
    throw new HttpsError(
      'unauthenticated',
      'The function must be called while authenticated.'
    );
  }

  // 2. 실제 사용할 데이터 결정 (2세대에서는 request.data 사용)
  let actualData = request.data;
  if (request.data && request.data.data && typeof request.data.data === 'object') {
    actualData = request.data.data;
    console.log('Using nested data.data as actualData');
  }

  console.log('Final actualData:', actualData);
  console.log('Final actualData keys:', actualData ? Object.keys(actualData) : 'actualData is null');

  // 3. 데이터 유효성 검사
  const { budgetId, income, name } = actualData;
   
  if (!budgetId || typeof budgetId !== 'string') {
    console.log('❌ Invalid budgetId:', budgetId, 'type:', typeof budgetId);
    throw new HttpsError(
      'invalid-argument',
      'budgetId must be a non-empty string.'
    );
  }

  if (typeof income !== 'number' || isNaN(income)) {
    console.log('❌ Invalid income:', income, 'type:', typeof income);
    throw new HttpsError(
      'invalid-argument',
      'income must be a valid number.'
    );
  }

  if (!name || typeof name !== 'string') {
    console.log('❌ Invalid name:', name, 'type:', typeof name);
    throw new HttpsError(
      'invalid-argument',
      'name must be a non-empty string.'
    );
  }

  const uid = request.auth.uid;
  console.log(`Processing request: uid=${uid}, budgetId=${budgetId}, income=${income}, name=${name}`);


  try {
    const budgetRef = db.collection('budgets').doc(budgetId);
    const incomesRef = budgetRef.collection('Icomes');

    // 새 고정 지출 문서 생성
    const newincomesRef = incomesRef.doc();
    const newincomesRefeData = {
      newIncomeId: uid, // FixedExpenseModel에 맞게 fixedExpenseId 추가
      budgetId: budgetId,
      name: name,
      amount: income,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await newincomesRef.set(newincomesRefeData)

    console.log(`✅ Successfully added new Income ${newincomesRef.id} to budget ${uid}`);

    return {
      status: 'success',
      fixedExpenseId: newincomesRef.id,
      message: 'Fixed expense added successfully',
    };
  } catch (error) {
    console.error('❌ Error adding fixed expense:', error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError(
      'internal',
      'An error occurred while adding the fixed expense.'
    );
  }

});