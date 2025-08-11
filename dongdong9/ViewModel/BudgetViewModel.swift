
import Foundation
import Combine
import Firebase
import FirebaseFirestore

class BudgetViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var totalIncome: Double = 0
    @Published var categories: [CategoryModel] = [] // 통합된 CategoryModel 사용
    @Published var budgetId: String? {
        didSet {
            // MainActor에서 실행되도록 Task로 감싸줍니다.
            Task {
                await fetchCategories()
            }
        }
    }

    private var db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    private var categoryListener: ListenerRegistration? // 실시간 리스너를 관리하기 위한 변수

    init(authViewModel: AuthViewModel) {
        // AuthViewModel로부터 budgetId를 구독합니다.
        authViewModel.$budgetId
            .receive(on: DispatchQueue.main)
            .assign(to: \.budgetId, on: self)
            .store(in: &cancellables)
    }
    
    deinit {
        // ViewModel이 메모리에서 해제될 때 리스너도 함께 제거합니다.
        categoryListener?.remove()
    }

    // MARK: - Computed Properties
    // FixedExpense 관련 로직 제거
    var netBudget: Double {
        totalIncome
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
    
    // CategoryViewModel에서 가져온 함수
    func addCategory(_ category: CategoryModel) async {
        print("카테고리: \(category)")
        do {
            // FirebaseService를 통해 카테고리를 추가합니다.
            // fetchCategories의 스냅샷 리스너가 변경을 감지하여 자동으로 UI를 업데이트합니다.
            _ = try await FirebaseService.shared.addCategory(category: category)
        } catch {
            print("카테고리 추가 실패: \(error)")
        }
    }
    
    // 카테고리를 실시간으로 가져오는 함수
    @MainActor
    func fetchCategories() {
        // 기존 리스너가 있다면 제거하여 중복 실행을 방지합니다.
        print(#function)
        categoryListener?.remove()
        
        guard let budgetId = budgetId, !budgetId.isEmpty else {
            print("Budget ID is not available, cannot fetch categories.")
            self.categories = [] // budgetId가 없으면 카테고리 목록을 비웁니다.
            return
        }
        
        print("Fetching categories for budgetId: \(budgetId)")
        // addSnapshotListener를 사용하여 Firestore의 변경사항을 실시간으로 감지합니다.
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
                
                // 🔍 각 문서의 실제 데이터 출력
                for document in documents {
                    print("📄 Document ID: \(document.documentID)")
                    print("📄 Document Data: \(document.data())")
                    print("---")
                }
                
                // Firestore 문서를 CategoryModel 객체로 디코딩합니다.
                self.categories = documents.compactMap { document -> CategoryModel? in
                    do {
                        print("🔄 Trying to decode document: \(document.documentID)")
                        print("🔄 Raw data: \(document.data())")
                        
                        return try document.data(as: CategoryModel.self)
                    } catch {
                        print("Error decoding category document \(document.documentID): \(error)")
                        return nil
                    }
                }
                print("✅ Successfully fetched \(self.categories.count) categories.")
            }
    }

    func joinBudgetWithInviteCode(inviteCode: String, userId: String, authViewModel: AuthViewModel) {
        // TODO: 초대 코드로 가계부에 참여하는 Firestore 로직 구현
        print("Joining budget with invite code: \(inviteCode)")
        // 임시로 가계부가 있는 것으로 처리
        authViewModel.hasBudget = true
    }
}
