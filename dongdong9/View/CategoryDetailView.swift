
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

struct CategoryDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleCategory = ExpenseCategory(name: "식비", subcategories: [
            ExpenseCategory(name: "점심"),
            ExpenseCategory(name: "저녁")
        ])
        
        NavigationView {
            CategoryDetailView(category: sampleCategory)
                .environmentObject(BudgetViewModel())
        }
    }
}
