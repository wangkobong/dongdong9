
import SwiftUI

struct BudgetView: View {
    @EnvironmentObject var authViewModel: AuthViewModel // AddCategoryView에 넘겨주기 위해 추가
    @EnvironmentObject var budgetViewModel: BudgetViewModel
    @State private var showingAddCategory = false

    var body: some View {
        NavigationView {
            List {
                // 고정 지출 섹션 완전 삭제
                
                Section(header: Text("지출 카테고리")) {
                    // 이제 budgetViewModel.categories는 [CategoryModel] 타입입니다.
                    ForEach(budgetViewModel.categories, id: \.categoryId) { category in
                        NavigationLink(destination: CategoryDetailView(category: category)) {
                            Text(category.categoryName)
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
                // AddCategoryView에 authViewModel도 넘겨줍니다.
                AddCategoryView()
                    .environmentObject(authViewModel)
                    .environmentObject(budgetViewModel)
            }
            // 고정 지출 추가 시트 삭제
        }
    }
}

struct BudgetView_Previews: PreviewProvider {
    static var previews: some View {
        let authViewModel = AuthViewModel()
        let budgetViewModel = BudgetViewModel(authViewModel: authViewModel)

        BudgetView()
            .environmentObject(authViewModel)
            .environmentObject(budgetViewModel)
    }
}
