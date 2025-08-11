
import SwiftUI

struct AddCategoryView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var budgetViewModel: BudgetViewModel // categoryViewModel을 budgetViewModel로 변경

    
    @State private var categoryName: String = ""
    // var parentCategory: ExpenseCategory? // 삭제된 모델을 참조하므로 우선 주석 처리

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("카테고리 정보")) {
                    TextField("카테고리 이름", text: $categoryName)
                }
            }
            .navigationTitle("새 카테고리") // parentCategory가 없으므로 타이틀 간소화
            .navigationBarItems(leading: Button("취소") {
                presentationMode.wrappedValue.dismiss()
            }, trailing: Button("저장") {
                print("categoryName: \(categoryName)")
                print("budgetId: \(authViewModel.budgetId)")
                if !categoryName.isEmpty, let budgetId = authViewModel.budgetId {
                    var category = CategoryModel(
                                                 categoryName: categoryName,
                                                 description: "",
                                                 spendingMoney: 0,
                                                 subCategory: [])
                    category.budgetId = budgetId // budgetId 설정
                    
                    // Task 블록으로 비동기 함수 호출
                    Task {
                        // budgetViewModel의 함수를 호출하도록 변경
                        await budgetViewModel.addCategory(category)
                        // UI 업데이트는 메인 스레드에서
                        await MainActor.run {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            })
        }
    }
}

struct AddCategoryView_Previews: PreviewProvider {
    static var previews: some View {
        let authViewModel = AuthViewModel()
        let budgetViewModel = BudgetViewModel(authViewModel: authViewModel)

        AddCategoryView()
            .environmentObject(authViewModel)
            .environmentObject(budgetViewModel)
    }
}
