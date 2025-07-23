
import SwiftUI

struct AddFixedExpenseView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var budgetViewModel: BudgetViewModel
    
    @State private var name: String = ""
    @State private var amount: Double = 0

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("고정 지출 정보")) {
                    TextField("항목 이름 (예: 월세)", text: $name)
                    TextField("금액", value: $amount, format: .currency(code: "KRW"))
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("새 고정 지출")
            .navigationBarItems(leading: Button("취소") {
                presentationMode.wrappedValue.dismiss()
            }, trailing: Button("저장") {
                if !name.isEmpty && amount > 0 {
                    budgetViewModel.addFixedExpense(name: name, amount: amount)
                    presentationMode.wrappedValue.dismiss()
                }
            })
        }
    }
}
