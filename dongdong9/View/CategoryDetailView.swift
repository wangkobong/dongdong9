
import SwiftUI

struct CategoryDetailView: View {
    // ObservedObject가 아닌 let으로 받습니다. CategoryModel은 struct입니다.
    let category: CategoryModel

    var body: some View {
        List {
            Section(header: Text("하위 카테고리")) {
                ForEach(category.subCategory, id: \.categoryId) { subCategory in
                    Text(subCategory.categoryName)
                }
            }
        }
        .navigationTitle(category.categoryName)
        // 하위 카테고리 추가 기능은 추후 구현이 필요하므로 우선 제거합니다.
    }
}

struct CategoryDetailView_Previews: PreviewProvider {
    static var previews: some View {
        // Preview도 새로운 CategoryModel을 사용하도록 수정합니다.
        let sampleCategory = CategoryModel(categoryName: "식비", description: "", spendingMoney: 0, subCategory: [
            CategoryModel(categoryName: "점심", description: "", spendingMoney: 0, subCategory: []),
            CategoryModel(categoryName: "저녁", description: "", spendingMoney: 0, subCategory: [])
        ])
        
        NavigationView {
            CategoryDetailView(category: sampleCategory)
        }
    }
}
