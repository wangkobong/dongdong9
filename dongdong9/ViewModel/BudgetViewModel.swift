
import Foundation
import Combine

class BudgetViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var husbandIncome: Double = 0
    @Published var wifeIncome: Double = 0
    @Published var categories: [ExpenseCategory] = []
    @Published var fixedExpenses: [FixedExpense] = []

    // MARK: - Computed Properties
    var grossBudget: Double {
        husbandIncome + wifeIncome
    }
    
    var totalFixedExpenses: Double {
        fixedExpenses.map { $0.amount }.reduce(0, +)
    }

    var netBudget: Double {
        grossBudget - totalFixedExpenses
    }

    // MARK: - Methods
    func addCategory(name: String, parent: ExpenseCategory? = nil) {
        let newCategory = ExpenseCategory(name: name)
        if let parent = parent,
           let parentIndex = categories.firstIndex(where: { $0.id == parent.id }) {
            categories[parentIndex].subcategories.append(newCategory)
        } else {
            categories.append(newCategory)
        }
    }

    func addFixedExpense(name: String, amount: Double) {
        let newExpense = FixedExpense(name: name, amount: amount)
        fixedExpenses.append(newExpense)
    }
    
    func removeFixedExpense(at offsets: IndexSet) {
        fixedExpenses.remove(atOffsets: offsets)
    }
}
