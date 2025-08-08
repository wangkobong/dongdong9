
import Foundation
import Combine
import Firebase

class BudgetViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var totalIncome: Double = 0
    @Published var categories: [ExpenseCategory] = []
    @Published var fixedExpenses: [FixedExpense] = []
    @Published var budgetId: String? // 생성된 가계부 ID

    private var db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()

    init(authViewModel: AuthViewModel) {
        authViewModel.$budgetId
            .receive(on: DispatchQueue.main)
            .assign(to: \.budgetId, on: self)
            .store(in: &cancellables)
    }

    // MARK: - Computed Properties
    var totalFixedExpenses: Double {
        fixedExpenses.map { $0.amount }.reduce(0, +)
    }

    var netBudget: Double {
        totalIncome - totalFixedExpenses
    }

    // MARK: - Methods
    func createBudget(userId: String, authViewModel: AuthViewModel) {
        Task {
            do {
                let newBudgetId = try await FirebaseService.shared.createBudget(userId: userId)
                DispatchQueue.main.async {
                    self.budgetId = newBudgetId
                    authViewModel.hasBudget = true
                    print("Budget document added with ID: \(newBudgetId)")
                }
            } catch {
                print("Error creating budget: \(error.localizedDescription)")
            }
        }
    }

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

    func joinBudgetWithInviteCode(inviteCode: String, userId: String, authViewModel: AuthViewModel) {
        // TODO: 초대 코드로 가계부에 참여하는 Firestore 로직 구현
        print("Joining budget with invite code: \(inviteCode)")
        // 임시로 가계부가 있는 것으로 처리
        authViewModel.hasBudget = true
    }
}
