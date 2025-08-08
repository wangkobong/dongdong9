import SwiftUI

struct ContentView: View {
    @StateObject private var authViewModel: AuthViewModel
    @StateObject private var budgetViewModel: BudgetViewModel

    init() {
        let authVm = AuthViewModel()
        _authViewModel = StateObject(wrappedValue: authVm)
        _budgetViewModel = StateObject(wrappedValue: BudgetViewModel(authViewModel: authVm))
    }

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
        .environmentObject(authViewModel)
        .environmentObject(budgetViewModel)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
