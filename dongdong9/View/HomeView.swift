
import SwiftUI

struct HomeView: View {
    @EnvironmentObject var budgetViewModel: BudgetViewModel

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 25) {
                // 총수입
                VStack(alignment: .leading) {
                    Text("총수입")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Text(budgetViewModel.totalIncome, format: .currency(code: "KRW"))
                        .font(.title2)
                        .fontWeight(.semibold)
                }

                // 고정 지출
                VStack(alignment: .leading) {
                    Text("고정 지출")
                        .font(.headline)
                        .foregroundColor(.gray)

                }

                Divider()

                // 사용 가능 예산
                VStack(alignment: .leading) {
                    Text("사용 가능 예산")
                        .font(.title)
                        .fontWeight(.bold)
                    Text(budgetViewModel.netBudget, format: .currency(code: "KRW"))
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("이번 달 예산 현황")
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        let authViewModel = AuthViewModel()
        let budgetViewModel = BudgetViewModel(authViewModel: authViewModel)

        HomeView()
            .environmentObject(budgetViewModel)
    }
}
