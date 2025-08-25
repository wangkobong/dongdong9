import Foundation
import Combine
import Firebase
import FirebaseFirestore

class BudgetViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var incomes: [String: Double] = [:]
    @Published var categories: [CategoryModel] = []
    @Published var fixedExpenses: [FixedExpenseModel] = []
    @Published var budgetId: String? {
        didSet {
            Task {
                await fetchCategories()
                await fetchFixedExpenses()
            }
        }
    }

    private var db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    private var categoryListener: ListenerRegistration?
    private var fixedExpenseListener: ListenerRegistration?

    init(authViewModel: AuthViewModel) {
        // AuthViewModel로부터 budgetId와 incomes를 구독합니다.
        authViewModel.$budgetId
            .receive(on: DispatchQueue.main)
            .assign(to: \.budgetId, on: self)
            .store(in: &cancellables)

        authViewModel.$incomes
            .receive(on: DispatchQueue.main)
            .assign(to: \.incomes, on: self)
            .store(in: &cancellables)
    }
    
    deinit {
        categoryListener?.remove()
        fixedExpenseListener?.remove()
    }

    // MARK: - Computed Properties
    var totalIncome: Double {
        incomes.values.reduce(0, +)
    }

    var netBudget: Double {
        totalIncome // Simplified
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
    
    func addCategory(_ category: CategoryModel) async {
        print("카테고리: \(category)")
        do {
            _ = try await FirebaseService.shared.addCategory(category: category)
        } catch {
            print("카테고리 추가 실패: \(error)")
        }
    }
    
    @MainActor
    func fetchCategories() {
        categoryListener?.remove()
        
        guard let budgetId = budgetId, !budgetId.isEmpty else {
            self.categories = []
            return
        }
        
        categoryListener = db.collection("budgets").document(budgetId).collection("categories")
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching categories: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    print("No category documents found")
                    return
                }
                
                self.categories = documents.compactMap { document -> CategoryModel? in
                    do {
                        return try document.data(as: CategoryModel.self)
                    } catch {
                        print("Error decoding category document \(document.documentID): \(error)")
                        return nil
                    }
                }
            }
    }

    func addFixedExpense(_ fixedExpense: FixedExpenseModel) async {
        print("고정 지출 추가: \(fixedExpense)")
        do {
            _ = try await FirebaseService.shared.addFixedExpense(fixedExpense: fixedExpense)
        } catch {
            print("고정 지출 추가 실패: \(error)")
        }
    }

    @MainActor
    func fetchFixedExpenses() {
        fixedExpenseListener?.remove()

        guard let budgetId = budgetId, !budgetId.isEmpty else {
            self.fixedExpenses = []
            return
        }

        fixedExpenseListener = db.collection("budgets").document(budgetId).collection("fixedExpenses")
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("Error fetching fixed expenses: \(error.localizedDescription)")
                    return
                }

                guard let documents = querySnapshot?.documents else {
                    print("No fixed expense documents found")
                    return
                }

                self.fixedExpenses = documents.compactMap { document -> FixedExpenseModel? in
                    do {
                        return try document.data(as: FixedExpenseModel.self)
                    } catch {
                        print("Error decoding fixed expense document \(document.documentID): \(error)")
                        return nil
                    }
                }
            }
    }

    func joinBudgetWithInviteCode(inviteCode: String, userId: String, authViewModel: AuthViewModel) {
        // TODO: 초대 코드로 가계부에 참여하는 Firestore 로직 구현
        print("Joining budget with invite code: \(inviteCode)")
        authViewModel.hasBudget = true
    }

    func updateMyIncome(income: Double) {
        guard let budgetId = budgetId else {
            print("Error: budgetId is nil. Cannot update income.")
            return
        }

        Task {
            do {
                try await FirebaseService.shared.updateUserIncome(budgetId: budgetId, income: income)
                print("Successfully requested income update.")
            } catch {
                print("Error updating income: \(error.localizedDescription)")
            }
        }
    }
}