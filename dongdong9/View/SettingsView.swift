
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var budgetViewModel: BudgetViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingLogoutAlert = false
    @State private var showingDeleteAccountAlert = false // 회원탈퇴 확인 팝업을 위한 상태 변수

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("설정")) {
                    NavigationLink(destination: IncomeSettingView()) {
                        Text("소득설정")
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
                    
                    Button(action: {
                        showingDeleteAccountAlert = true // 회원탈퇴 버튼 클릭 시 팝업 표시
                    }) {
                        Text("회원탈퇴")
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
            .alert("회원탈퇴", isPresented: $showingDeleteAccountAlert) { // 회원탈퇴 확인 팝업
                Button("취소", role: .cancel) { }
                Button("탈퇴", role: .destructive) {
                    Task {
                        await authViewModel.deleteAccount()
                    }
                }
            } message: {
                Text("정말로 계정을 탈퇴하시겠습니까? 모든 데이터가 삭제됩니다.")
            }
        }
        .loadingSpinner(isLoading: $authViewModel.isLoading)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        let authViewModel = AuthViewModel()
        let budgetViewModel = BudgetViewModel(authViewModel: authViewModel)

        SettingsView()
            .environmentObject(budgetViewModel)
            .environmentObject(authViewModel)
    }
}
