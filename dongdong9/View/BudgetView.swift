
import SwiftUI

struct BudgetView: View {
    @EnvironmentObject var authViewModel: AuthViewModel // AddCategoryView에 넘겨주기 위해 추가
    @EnvironmentObject var budgetViewModel: BudgetViewModel
    @State private var showingAddCategory = false
    @State private var showingAddFixedExpense = false // 고정 지출 추가를 위한 State

    var body: some View {
        NavigationView {
            List {
                // 고정 지출 섹션
                Section(header:
                    HStack {
                        Text("고정 지출")
                        Spacer()
                        Button(action: { showingAddFixedExpense.toggle() }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.accentColor)
                        }
                    }
                ) {
                    ForEach(budgetViewModel.fixedExpenses, id: \.fixedExpenseId) { expense in
                        HStack {
                            Text(expense.name)
                            Spacer()
                            Text(expense.amount, format: .currency(code: "KRW"))
                        }
                    }
                    // .onDelete(perform: budgetViewModel.removeFixedExpense) // 삭제 기능은 추후 구현
                }

                Section(header: Text("지출 카테고리")) {
                    ForEach(budgetViewModel.categories, id: \.categoryId) { category in // id: \.categoryId 제거
                        NavigationLink(destination: CategoryDetailView(category: category)) {
                            Text(category.categoryName)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("예산 관리")
            .navigationBarItems(trailing: Button(action: {
                showingAddCategory.toggle()
            }) {
                Text("카테고리 추가")
            })
            .sheet(isPresented: $showingAddCategory) {
                AddCategoryView()
                    .environmentObject(authViewModel)
                    .environmentObject(budgetViewModel)
            }
            .sheet(isPresented: $showingAddFixedExpense) { // 고정 지출 추가 시트
                AddFixedExpenseView()
                    .environmentObject(authViewModel)
                    .environmentObject(budgetViewModel)
            }
        }
    }
}

struct BudgetView_Previews: PreviewProvider {
    static var previews: some View {
        let authViewModel = AuthViewModel()
        let budgetViewModel = BudgetViewModel(authViewModel: authViewModel)

        BudgetView()
            .environmentObject(authViewModel)
            .environmentObject(budgetViewModel)
    }
}
