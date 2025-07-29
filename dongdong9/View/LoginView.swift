
import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingAlert = false
    @State private var alertMessage = ""
    var isReauthenticating: Bool = false // 새 매개변수

    var body: some View {
        VStack(spacing: 20) {
            Text("DongDong9")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 50)

            if isReauthenticating {
                Text("계정 삭제를 위해 재로그인이 필요합니다.")
                    .font(.headline)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 20)
            }

            Button(action: {
                authViewModel.signInWithGoogle()
            }) {
                HStack {
                    Image(systemName: "g.circle.fill")
                        .font(.title)
                    Text("Google로 로그인")
                        .fontWeight(.semibold)
                }
                .frame(minWidth: 0, maxWidth: .infinity)
                .padding()
                .foregroundColor(.white)
                .background(Color.red)
                .cornerRadius(40)
            }

            Button(action: {
                Task {
                    do {
                        try await authViewModel.signInWithApple()
                    } catch {
                        print("Apple 로그인 오류: \(error.localizedDescription)")
                        // 필요 시 사용자에게 오류를 표시하는 로직 추가
                    }
                }
            }) {
                HStack {
                    Image(systemName: "applelogo")
                        .font(.title)
                    Text("Apple로 로그인")
                        .fontWeight(.semibold)
                }
                .frame(minWidth: 0, maxWidth: .infinity)
                .padding()
                .foregroundColor(.white)
                .background(Color.black)
                .cornerRadius(40)
            }
        }
        .padding()
        .alert("로그인 오류", isPresented: $showingAlert) {
            Button("확인") { }
        } message: {
            Text(alertMessage)
        }
        .loadingSpinner(isLoading: $authViewModel.isLoading)
        .onChange(of: authViewModel.errorMessage) { errorMessage in
            if let errorMessage = errorMessage {
                self.alertMessage = errorMessage
                self.showingAlert = true
            }
        }
        .onChange(of: authViewModel.userSession) { userSession in
            if isReauthenticating && userSession != nil {
                // 재인증 성공 후 계정 삭제 재시도
                Task {
                    await authViewModel.deleteAccount()
                    authViewModel.resetReauthenticationFlag() // 플래그 리셋
                }
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(isReauthenticating: false) // Preview를 위해 매개변수 추가
            .environmentObject(AuthViewModel())
    }
}
