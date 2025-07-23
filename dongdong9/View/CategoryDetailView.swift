
import SwiftUI

struct CategoryDetailView: View {
    @ObservedObject var category: ExpenseCategory
    @EnvironmentObject var budgetViewModel: BudgetViewModel
    @State private var showingAddSubCategory = false

    var body: some View {
        List {
            Section(header: Text("하위 카테고리")) {
                ForEach(category.subcategories) { subCategory in
                    Text(subCategory.name)
                }
                .onDelete(perform: deleteSubCategory)
            }
        }
        .navigationTitle(category.name)
        .navigationBarItems(trailing: Button(action: {
            showingAddSubCategory.toggle()
        }) {
            Image(systemName: "plus")
        })
        .sheet(isPresented: $showingAddSubCategory) {
            AddCategoryView(parentCategory: category)
                .environmentObject(budgetViewModel)
        }
    }

    private func deleteSubCategory(at offsets: IndexSet) {
        category.subcategories.remove(atOffsets: offsets)
    }
}
