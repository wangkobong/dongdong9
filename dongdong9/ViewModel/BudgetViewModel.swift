import Foundation
import Combine
import Firebase
import FirebaseFirestore

class BudgetViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var incomeEntries: [IncomeModel] = []
    @Published var fixedExpenses: [FixedExpenseModel] = []
    @Published var categories: [CategoryModel] = []
    @Published var budgetId: String? {
        didSet {
            Task {
                // AuthViewModel에서 이미 데이터를 가져오므로, fetchCategories만 호출합니다.
                await fetchCategories()
            }
        }
    }

    private var db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    private var categoryListener: ListenerRegistration?

    init(authViewModel: AuthViewModel) {
        // AuthViewModel로부터 데이터 스트림을 구독합니다.
        authViewModel.$budgetId
            .receive(on: DispatchQueue.main)
            .assign(to: \.budgetId, on: self)
            .store(in: &cancellables)

        authViewModel.$incomeEntries
            .receive(on: DispatchQueue.main)
            .assign(to: \.incomeEntries, on: self)
            .store(in: &cancellables)
            
        authViewModel.$fixedExpenseEntries
            .receive(on: DispatchQueue.main)
            .assign(to: \.fixedExpenses, on: self)
            .store(in: &cancellables)
    }
    
    deinit {
        categoryListener?.remove()
    }

    // MARK: - Computed Properties
    var totalIncome: Double {
        // 각 사용자의 가장 최신 소득만 합산합니다.
        // incomeEntries는 AuthViewModel에서 이미 최신순으로 정렬되어 있습니다.
        var latestIncomes: [String: Double] = [:]
        for entry in incomeEntries {
            if latestIncomes[entry.newIncomeId] == nil {
                latestIncomes[entry.newIncomeId] = entry.amount
            }
        }
        return latestIncomes.values.reduce(0, +)
    }
    
    var totalFixedExpenses: Double {
        fixedExpenses.reduce(0) { $0 + $1.amount }
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

    // fetchFixedExpenses()는 이제 AuthViewModel에서 처리하므로 삭제합니다.

    func joinBudgetWithInviteCode(inviteCode: String, userId: String, authViewModel: AuthViewModel) {
        // TODO: 초대 코드로 가계부에 참여하는 Firestore 로직 구현
        print("Joining budget with invite code: \(inviteCode)")
        authViewModel.hasBudget = true
    }

    func updateMyIncome(income: Double, name: String) {
        guard let budgetId = budgetId else {
            print("Error: budgetId is nil. Cannot update income.")
            return
        }

        Task {
            do {
                try await FirebaseService.shared.updateUserIncome(budgetId: budgetId, income: income, name: name)
                print("Successfully requested income update.")
            } catch {
                print("Error updating income: \(error.localizedDescription)")
            }
        }
    }
}
