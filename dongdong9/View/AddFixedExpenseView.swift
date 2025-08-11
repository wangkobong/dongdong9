import SwiftUI

struct AddFixedExpenseView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var budgetViewModel: BudgetViewModel

    @State private var name: String = ""
    @State private var amount: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("고정 지출 정보")) {
                    TextField("항목 이름 (예: 월세, 통신비)", text: $name)
                    TextField("금액", text: $amount)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("새 고정 지출")
            .navigationBarItems(leading: Button("취소") {
                presentationMode.wrappedValue.dismiss()
            }, trailing: Button("저장") {
                if !name.isEmpty, let amountDouble = Double(amount), let budgetId = authViewModel.budgetId {
                    let fixedExpense = FixedExpenseModel(
                        budgetId: budgetId,
                        name: name,
                        amount: amountDouble
                    )
                    Task {
                        await budgetViewModel.addFixedExpense(fixedExpense)
                        await MainActor.run {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            })
        }
    }
}

struct AddFixedExpenseView_Previews: PreviewProvider {
    static var previews: some View {
        let authViewModel = AuthViewModel()
        let budgetViewModel = BudgetViewModel(authViewModel: authViewModel)

        AddFixedExpenseView()
            .environmentObject(authViewModel)
            .environmentObject(budgetViewModel)
    }
}