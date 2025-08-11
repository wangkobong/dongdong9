
import SwiftUI

struct AddCategoryView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var budgetViewModel: BudgetViewModel
    @EnvironmentObject var categoryViewModel: CategoryViewModel

    
    @State private var categoryName: String = ""
    var parentCategory: ExpenseCategory? // 상위 카테고리를 받을 변수

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("카테고리 정보")) {
                    TextField("카테고리 이름", text: $categoryName)
                }
            }
            .navigationTitle(parentCategory == nil ? "새 대카테고리" : "새 하위 카테고리")
            .navigationBarItems(leading: Button("취소") {
                presentationMode.wrappedValue.dismiss()
            }, trailing: Button("저장") {
                if !categoryName.isEmpty {
                    let category = CategoryModel(
                                                 categoryName: categoryName,
                                                 description: "",
                                                 spendingMoney: 0,
                                                 subCategory: [])
                    // Task 블록으로 비동기 함수 호출
                    Task {
                        await categoryViewModel.addCategory(category)
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
            .environmentObject(budgetViewModel)
    }
}
