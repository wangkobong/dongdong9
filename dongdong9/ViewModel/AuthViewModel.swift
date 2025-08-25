import SwiftUI
import FirebaseAuth
import Firebase
import GoogleSignIn
import AuthenticationServices
import FirebaseFirestore

struct OAuthUserData {
    var oauthId: String = ""
    var idToken: String = ""
    var givenName: String = ""
}

class AuthViewModel: ObservableObject {
    @Published var userSession: User?
    @Published var oauthUserData = OAuthUserData()
    @Published var errorMessage: String?
    @Published var givenName: String?
    @Published var isLoading = false
    @Published var isAuthCheckComplete = false
    @Published var hasBudget = false
    @Published var budgetId: String?
    @Published var isBudgetStatusChecked = false
    @Published var shouldReauthenticate: Bool = false
    @Published var incomes: [String: Double] = [:] // 소득 데이터

    private let authRepository: AuthRepository
    private var budgetListener: ListenerRegistration? // Firestore 리스너

    init(authRepository: AuthRepository = AuthRepository()) {
        self.authRepository = authRepository
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            self.userSession = user
            if let user = user {
                self.isBudgetStatusChecked = false
                self.attachBudgetListener(userId: user.uid)
            } else {
                self.detachBudgetListener() // 로그아웃 시 리스너 분리
                self.hasBudget = false
                self.budgetId = nil
                self.incomes = [:]
                self.isBudgetStatusChecked = true
            }
            if !self.isAuthCheckComplete {
                self.isAuthCheckComplete = true
            }
        }
    }

    deinit {
        detachBudgetListener()
    }

    func resetReauthenticationFlag() {
        self.shouldReauthenticate = false
    }

    func attachBudgetListener(userId: String) {
        detachBudgetListener() // 기존 리스너가 있다면 중복 방지를 위해 분리
        let db = Firestore.firestore()
        let query = db.collection("budgets").whereField("userIds", arrayContains: userId)

        self.budgetListener = query.addSnapshotListener { [weak self] (querySnapshot, error) in
            guard let self = self else { return }
            if let error = error {
                print("Error listening for budget documents: \(error)")
                self.hasBudget = false
                self.budgetId = nil
                self.incomes = [:]
                self.isBudgetStatusChecked = true
                return
            }

            if let document = querySnapshot?.documents.first {
                self.hasBudget = true
                self.budgetId = document.documentID
                if let incomesData = document.data()["incomes"] as? [String: Double] {
                    self.incomes = incomesData
                } else {
                    self.incomes = [:]
                }
            } else {
                self.hasBudget = false
                self.budgetId = nil
                self.incomes = [:]
            }
            self.isBudgetStatusChecked = true
        }
    }

    private func detachBudgetListener() {
        budgetListener?.remove()
        budgetListener = nil
    }

    @MainActor
    func signInWithGoogle() {
        self.isLoading = true

        guard let clientID = FirebaseApp.app()?.options.clientID else {
            print("Error: Firebase clientID not found.")
            self.errorMessage = "Firebase clientID not found."
            self.isLoading = false
            return
        }

        guard let presentingViewController = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController else {
            print("Error: Could not find top view controller.")
            self.errorMessage = "Could not find top view controller."
            self.isLoading = false
            return
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { [weak self] result, error in
            guard let self = self else { return }

            if let error = error {
                print("Google Sign-In error: \(error.localizedDescription)")
                self.errorMessage = "Google 로그인 중 오류가 발생했습니다."
                self.isLoading = false
                return
            }

            guard let user = result?.user, let idToken = user.idToken?.tokenString else {
                self.errorMessage = "Google 사용자 정보를 가져오는데 실패했습니다."
                self.isLoading = false
                return
            }

            let accessToken = user.accessToken.tokenString
            let firebaseCredential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)

            Auth.auth().signIn(with: firebaseCredential) { authResult, firebaseError in
                if let firebaseError = firebaseError {
                    print("Firebase Google 로그인 실패: \(firebaseError.localizedDescription)")
                    self.errorMessage = "Firebase 로그인에 실패했습니다."
                    self.isLoading = false
                    return
                }

                guard let firebaseUser = authResult?.user else {
                    print("Firebase 로그인 성공했으나 Firebase 유저 정보 없음")
                    self.errorMessage = "Firebase 사용자 정보를 확인하는데 실패했습니다."
                    self.isLoading = false
                    return
                }
                
                print("🎉 Firebase Google 로그인 성공!")
                Task {
                    try await FirebaseService.shared.createUser(user: firebaseUser)
                }
                self.isLoading = false
            }
        }
    }

    private func saveUserToFirestore(user: User) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(user.uid)

        userRef.getDocument { [weak self] (document, error) in
            guard let self = self else { return }
            if let error = error {
                print("Error fetching user document: \(error.localizedDescription)")
                return
            }

            if document?.exists == false {
                // User document does not exist, create it with createdAt and lastLoginAt
                let userData: [String: Any] = [
                    "uid": user.uid,
                    "email": user.email ?? "",
                    "displayName": user.displayName ?? "",
                    "photoURL": user.photoURL?.absoluteString ?? "",
                    "createdAt": FieldValue.serverTimestamp(),
                    "lastLoginAt": FieldValue.serverTimestamp()
                ]
                userRef.setData(userData) { [weak self] error in
                    guard let self = self else { return }
                    if let error = error {
                        print("Error creating user in Firestore: \(error.localizedDescription)")
                    } else {
                        print("New user data successfully saved in Firestore.")
                    }
                }
            } else {
                // User document exists, update only relevant fields (e.g., lastLoginAt)
                let updateData: [String: Any] = [
                    "email": user.email ?? "",
                    "displayName": user.displayName ?? "",
                    "photoURL": user.photoURL?.absoluteString ?? "",
                    "lastLoginAt": FieldValue.serverTimestamp()
                ]
                userRef.updateData(updateData) { [weak self] error in
                    guard let self = self else { return }
                    if let error = error {
                        print("Error updating user in Firestore: \(error.localizedDescription)")
                    } else {
                        print("Existing user data successfully updated in Firestore.")
                    }
                }
            }
        }
    }
    
    func signInWithApple() async throws {
         let nonce = String.randomNonceString()
         let appleIDProvider = ASAuthorizationAppleIDProvider()
         let request = appleIDProvider.createRequest()
         request.requestedScopes = [.fullName, .email]
         request.nonce = nonce.sha256()
         
         return try await withCheckedThrowingContinuation { continuation in
             DispatchQueue.main.async {
                 let authorizationController = ASAuthorizationController(authorizationRequests: [request])
                 let delegate = SignInWithAppleDelegate { result, error in
                     if let error = error {
                         continuation.resume(throwing: error)
                         return
                     }
                     
                     guard let result = result,
                           let appleIDCredential = result.credential as? ASAuthorizationAppleIDCredential,
                           let appleIDToken = appleIDCredential.identityToken,
                           let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                         continuation.resume(throwing: NSError(domain: "", code: -1,
                             userInfo: [NSLocalizedDescriptionKey: "Unable to fetch identity token"]))
                         return
                     }
                     
                     let credential = OAuthProvider.credential(
                         providerID: AuthProviderID.apple,
                         idToken: idTokenString,
                         rawNonce: nonce,
                         accessToken: nil // 선택적 파라미터
                     )
                     
                     Task {
                         do {
                             let authResult = try await Auth.auth().signIn(with: credential)
                             let user = authResult.user
                             self.saveUserToFirestore(user: user)
                             continuation.resume(returning: ())
                         } catch let signInError as NSError {
                             print("Firebase sign in error: \(signInError.localizedDescription)")
                             continuation.resume(throwing: signInError)
                         } catch {
                             print("Unexpected error: \(error.localizedDescription)")
                             continuation.resume(throwing: error)
                         }
                     }
                 }
                 
                 authorizationController.delegate = delegate
                 authorizationController.presentationContextProvider = delegate
                 objc_setAssociatedObject(authorizationController, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN)
                 
                 authorizationController.performRequests()
             }
         }
    }
    

    func signOut() async {
        detachBudgetListener()
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            print("Successfully signed out.")
            self.hasBudget = false
            self.budgetId = nil
            self.incomes = [:]
            self.isBudgetStatusChecked = false
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
            self.errorMessage = "로그아웃에 실패했습니다."
        }
    }

    @MainActor
    func deleteAccount() async {
        guard let user = Auth.auth().currentUser else {
            self.errorMessage = "로그인된 사용자가 없습니다."
            return
        }

        self.isLoading = true
        defer { self.isLoading = false } // 함수 종료 시 항상 실행

        let userId = user.uid
        let db = Firestore.firestore()

        do {
            // 1. Firestore users 컬렉션에서 사용자 문서 삭제
            try await db.collection("users").document(userId).delete()
            print("Firestore user document deleted.")

            // 2. 사용자가 속한 모든 budgets 문서에서 userId 제거
            let budgetQuerySnapshot = try await db.collection("budgets").whereField("userIds", arrayContains: userId).getDocuments()
            for document in budgetQuerySnapshot.documents {
                let budgetRef = db.collection("budgets").document(document.documentID)
                var userIds = document.data()["userIds"] as? [String] ?? []
                userIds.removeAll(where: { $0 == userId })

                if userIds.isEmpty {
                    // 가계부에 더 이상 사용자가 없으면 가계부 문서 자체를 삭제
                    try await budgetRef.delete()
                    print("Budget document \(document.documentID) deleted as no users remain.")
                } else {
                    // 사용자가 남아있으면 userIds 배열 업데이트
                    try await budgetRef.updateData(["userIds": userIds])
                    print("User \(userId) removed from budget \(document.documentID).")
                }
            }

            // 3. Firebase Authentication에서 사용자 삭제
            try await user.delete()
            print("Firebase Auth user deleted.")

            // 모든 삭제 성공 후 로그아웃 처리
            await signOut()
            self.errorMessage = nil // 성공 시 에러 메시지 초기화
            self.shouldReauthenticate = false // 성공 시 플래그 리셋

        } catch let error as NSError {
            print("Error deleting account: \(error.localizedDescription)")
            if error.code == AuthErrorCode.requiresRecentLogin.rawValue {
                print("Firebase Auth Error: User requires recent login for account deletion.")
                self.errorMessage = "보안을 위해 재로그인이 필요합니다. 다시 로그인 후 시도해주세요."
                self.shouldReauthenticate = true // 재인증 필요 플래그 설정
                await signOut()
            } else {
                self.errorMessage = "회원 탈퇴 중 오류가 발생했습니다: \(error.localizedDescription)"
                self.shouldReauthenticate = false // 그 외 에러 시 플래그 리셋
            } 
        }
    }
    
    private class SignInWithAppleDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
        private let completion: (ASAuthorization?, Error?) -> Void
        
        init(completion: @escaping (ASAuthorization?, Error?) -> Void) {
            self.completion = completion
        }
        
        func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = scene.windows.first else {
                fatalError("No window found")
            }
            return window
        }
        
        func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
            completion(authorization, nil)
        }
        
        func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
            completion(nil, error)
        }
    }
}