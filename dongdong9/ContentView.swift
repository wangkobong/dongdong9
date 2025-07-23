import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        Group {
            if authViewModel.isAuthCheckComplete {
                if authViewModel.userSession != nil {
                    // TODO: 여기에 InvitationView 또는 MainTabView를 보여주는 로직 추가
                    MainTabView()
                } else {
                    LoginView()
                }
            } else {
                // 인증 상태 확인 중 로딩 인디케이터 표시
                ProgressView("인증 확인 중...")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthViewModel()) // Preview를 위해 가짜 뷰모델 주입
    }
}
