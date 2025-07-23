import SwiftUI
import FirebaseAuth
import Firebase
import GoogleSignIn
import AuthenticationServices

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
    private let authRepository: AuthRepository

    init(authRepository: AuthRepository = AuthRepository()) {
        self.authRepository = authRepository
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.userSession = user
            if let self = self, !self.isAuthCheckComplete {
                self.isAuthCheckComplete = true
            }
        }
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

                print("🎉 Firebase Google 로그인 성공! UID: \(firebaseUser.uid)")
                self.checkUserInfo()
                self.isLoading = false
            }
        }
    }

    @MainActor
    func signInWithApple2() {
        self.isLoading = true
        self.errorMessage = nil

        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
//        authorizationController.delegate = self
//        authorizationController.presentationContextProvider = self
//        authorizationController.performRequests()
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
                             try await Auth.auth().signIn(with: credential)
                             
                             let authResult = try await Auth.auth().signIn(with: credential)
                             let user = authResult.user
                             
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
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            print("Successfully signed out.")
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
            self.errorMessage = "로그아웃에 실패했습니다."
        }
    }
    
    func checkUserInfo() {
        if GIDSignIn.sharedInstance.currentUser != nil {//현재 사용자가 로그인되어 있는지 확인
            let user = GIDSignIn.sharedInstance.currentUser
            guard let user = user else {
                return
            }
            oauthUserData.givenName = user.profile?.givenName ?? "" //사용자의 이름
            oauthUserData.oauthId = user.userID ?? "" //사용자의 고유 ID
            oauthUserData.idToken = user.idToken?.tokenString ?? ""//사용자의 ID 토큰
            
//            print("결과: \(oauthUserData)")

        } else {
            self.errorMessage = "error: Not Logged In"
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

//extension AuthViewModel: ASAuthorizationControllerDelegate {
//    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
//        self.isLoading = false
//        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
//            guard let appleIDToken = appleIDCredential.identityToken else {
//                print("Unable to fetch identity token")
//                self.errorMessage = "Apple 로그인 토큰을 가져오는데 실패했습니다."
//                return
//            }
//            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
//                print("Unable to serialize token string from data.")
//                self.errorMessage = "Apple 로그인 토큰을 변환하는데 실패했습니다."
//                return
//            }
//
//            let firebaseCredential = OAuthProvider.credential(withProviderID: "apple.com",
//                                                                idToken: idTokenString,
//                                                                rawNonce: nil) // Nonce is not strictly required for Firebase if not using custom backend
//
//            Auth.auth().signIn(with: firebaseCredential) { [weak self] authResult, error in
//                guard let self = self else { return }
//                self.isLoading = false // Set isLoading to false after Firebase sign-in attempt
//                if let error = error {
//                    print("Firebase Apple 로그인 실패: \(error.localizedDescription)")
//                    self.errorMessage = "Firebase Apple 로그인에 실패했습니다."
//                    return
//                }
//                print("🎉 Firebase Apple 로그인 성공! UID: \(authResult?.user.uid ?? "")")
//                self.checkUserInfo()
//            }
//        }
//    }
//
//    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
//        self.isLoading = false
//        print("Apple Sign-In error: \(error.localizedDescription)")
//        if let authorizationError = error as? ASAuthorizationError {
//            if authorizationError.code == .canceled {
//                self.errorMessage = "Apple 로그인이 취소되었습니다."
//            } else {
//                self.errorMessage = "Apple 로그인 중 오류가 발생했습니다: \(authorizationError.localizedDescription)"
//            }
//        } else {
//            self.errorMessage = "알 수 없는 Apple 로그인 오류가 발생했습니다."
//        }
//    }
//}

//extension AuthViewModel: ASAuthorizationControllerPresentationContextProviding {
//    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
//        return UIApplication.shared.connectedScenes
//            .filter({$0.activationState == .foregroundActive})
//            .map({$0 as? UIWindowScene})
//            .compactMap({$0})
//            .first?.windows.first ?? UIWindow()
//    }
//}
