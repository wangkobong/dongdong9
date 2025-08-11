
import SwiftUI

struct BudgetView: View {
    @EnvironmentObject var budgetViewModel: BudgetViewModel
    @EnvironmentObject var categoryViewModel: CategoryViewModel
    @State private var showingAddCategory = false
    @State private var showingAddFixedExpense = false

    var body: some View {
        NavigationView {
            List {
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
                    ForEach(budgetViewModel.fixedExpenses) { expense in
                        HStack {
                            Text(expense.name)
                            Spacer()
                            Text(expense.amount, format: .currency(code: "KRW"))
                        }
                    }
                    .onDelete(perform: budgetViewModel.removeFixedExpense)
                }
                
                Section(header: Text("지출 카테고리")) {
                    ForEach(budgetViewModel.categories) { category in
                        NavigationLink(destination: CategoryDetailView(category: category).environmentObject(budgetViewModel)) {
                            Text(category.name)
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
                    .environmentObject(budgetViewModel)
                    .environmentObject(categoryViewModel)
            }
            .sheet(isPresented: $showingAddFixedExpense) {
                AddFixedExpenseView()
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
            .environmentObject(budgetViewModel)
    }
}
