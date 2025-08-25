import SwiftUI

struct HomeView: View {
    @EnvironmentObject var budgetViewModel: BudgetViewModel

    var body: some View {
        NavigationView {
            List {
                // MARK: - 요약 섹션
                Section {
                    VStack(alignment: .leading, spacing: 15) {
                        // 총수입
                        VStack(alignment: .leading) {
                            Text("총수입")
                                .font(.headline)
                                .foregroundColor(.gray)
                            Text(budgetViewModel.totalIncome, format: .currency(code: "KRW"))
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        
                        // 총 고정지출
                        VStack(alignment: .leading) {
                            Text("총 고정지출")
                                .font(.headline)
                                .foregroundColor(.gray)
                            Text(budgetViewModel.totalFixedExpenses, format: .currency(code: "KRW"))
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.red)
                        }
                        
                        Divider().padding(.vertical, 5)
                        
                        // 사용 가능 예산
                        VStack(alignment: .leading) {
                            Text("사용 가능 예산")
                                .font(.title)
                                .fontWeight(.bold)
                            Text(budgetViewModel.netBudget, format: .currency(code: "KRW"))
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.vertical)
                }
                
                // MARK: - 수입 내역 섹션
                Section(header: Text("수입 내역")) {
                    if budgetViewModel.incomeEntries.isEmpty {
                        Text("등록된 수입 내역이 없습니다.")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(budgetViewModel.incomeEntries) { income in
                            HStack {
                                Text(income.name)
                                Spacer()
                                Text(income.amount, format: .currency(code: "KRW"))
                            }
                        }
                    }
                }
                
                // MARK: - 고정 지출 섹션
                Section(header: Text("고정 지출 내역")) {
                    if budgetViewModel.fixedExpenses.isEmpty {
                        Text("등록된 고정 지출 내역이 없습니다.")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(budgetViewModel.fixedExpenses) { expense in
                            HStack {
                                Text(expense.name)
                                Spacer()
                                Text(expense.amount, format: .currency(code: "KRW"))
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("이번 달 예산 현황")
        }
    }
}

//struct HomeView_Previews: PreviewProvider {
//    static var previews: some View {
//        let authViewModel = AuthViewModel()
//        let budgetViewModel = BudgetViewModel(authViewModel: authViewModel)
//
//        // Preview를 위한 목업 데이터
//        budgetViewModel.incomeEntries = [
//            IncomeModel(id: "1", incomeId: "1", userId: "a", userName: "사용자 A", amount: 3500000, createdAt: .now),
//            IncomeModel(id: "2", incomeId: "2", userId: "b", userName: "사용자 B", amount: 4000000, createdAt: .now)
//        ]
//        budgetViewModel.fixedExpenses = [
//            FixedExpenseModel(id: "1", budgetId: "b1", name: "월세", amount: 1200000, createdAt: .now),
//            FixedExpenseModel(id: "2", budgetId: "b1", name: "통신비", amount: 150000, createdAt: .now)
//        ]
//
//        return HomeView()
//            .environmentObject(budgetViewModel)
//    }
//}
