
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var budgetViewModel: BudgetViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingLogoutAlert = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("설정")) {
                    HStack {
                        Text("소득설정")
                        Spacer()

                    }
                    HStack {
                        Text("초대 코드")
                        Spacer()

                    }
                }
                
                Section(header: Text("앱 설정")) {
                    Button(action: {
                        showingLogoutAlert = true
                    }) {
                        Text("로그아웃")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("설정")
            .alert("로그아웃", isPresented: $showingLogoutAlert) {
                Button("취소", role: .cancel) { }
                Button("로그아웃", role: .destructive) {
                    Task {
                        await authViewModel.signOut()
                    }
                }
            } message: {
                Text("정말로 로그아웃 하시겠습니까?")
            }
        }
        .loadingSpinner(isLoading: $authViewModel.isLoading)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(BudgetViewModel())
            .environmentObject(AuthViewModel())
    }
}
