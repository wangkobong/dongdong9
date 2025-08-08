
import SwiftUI

struct JoinBudgetView: View {
    @State private var inviteCode = ""
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var budgetViewModel: BudgetViewModel

    var body: some View {
        VStack(spacing: 20) {
            Text("초대코드 입력")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 50)

            TextField("초대코드를 입력하세요", text: $inviteCode)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button(action: {
                if let userId = authViewModel.userSession?.uid {
                    budgetViewModel.joinBudgetWithInviteCode(inviteCode: inviteCode, userId: userId, authViewModel: authViewModel)
                }
            }) {
                Text("참여하기")
                    .modifier(MainButtonModifier())
            }
        }
        .padding()
    }
}

struct JoinBudgetView_Previews: PreviewProvider {
    static var previews: some View {
        let authViewModel = AuthViewModel()
        let budgetViewModel = BudgetViewModel(authViewModel: authViewModel)

        JoinBudgetView()
            .environmentObject(authViewModel)
            .environmentObject(budgetViewModel)
    }
}
