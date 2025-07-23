import SwiftUI
import FirebaseAuth
import Firebase
import GoogleSignIn

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

    func signOut() async {
//        self.isLoading = true
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            print("Successfully signed out.")
//            try await Task.sleep(nanoseconds: 500_000_000) // 0.5초 지연
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
            self.errorMessage = "로그아웃에 실패했습니다."
        }
//        self.isLoading = false
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
}
