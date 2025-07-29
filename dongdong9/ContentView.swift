import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        Group {
            if authViewModel.shouldReauthenticate {
                LoginView(isReauthenticating: true)
            } else if authViewModel.isAuthCheckComplete && authViewModel.isBudgetStatusChecked {
                if authViewModel.userSession != nil {
                    if authViewModel.hasBudget {
                        MainTabView()
                    } else {
                        BudgetChoiceView()
                    }
                } else {
                    LoginView()
                }
            } else {
                ProgressView("데이터 로딩 중...")
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
