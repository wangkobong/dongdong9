
import SwiftUI

struct BudgetChoiceView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var budgetViewModel: BudgetViewModel

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("가계부를 시작해 보세요")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 50)

                Button(action: {
                    if let userId = authViewModel.userSession?.uid {
                        budgetViewModel.createBudget(userId: userId, authViewModel: authViewModel)
                    }
                }) {
                    Text("가계부 생성하기")
                        .modifier(MainButtonModifier())
                }

                NavigationLink(destination: JoinBudgetView()) {
                    Text("초대코드로 참여하기")
                        .modifier(MainButtonModifier())
                }
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
}

struct MainButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .cornerRadius(10)
    }
}

struct BudgetChoiceView_Previews: PreviewProvider {
    static var previews: some View {
        // 실제 앱 실행 시에는 ContentView에서 BudgetViewModel이 생성되어 주입됩니다.
        // 프리뷰에서는 AuthViewModel의 목 인스턴스를 사용하여 BudgetViewModel을 생성합니다.
        let authViewModel = AuthViewModel()
        let budgetViewModel = BudgetViewModel(authViewModel: authViewModel)
        
        BudgetChoiceView()
            .environmentObject(authViewModel)
            .environmentObject(budgetViewModel)
    }
}
