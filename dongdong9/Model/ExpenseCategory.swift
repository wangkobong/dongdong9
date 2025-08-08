
import Foundation

class ExpenseCategory: Identifiable, ObservableObject, Hashable {
    // Hashable and Equatable conformance for use in collections
    static func == (lhs: ExpenseCategory, rhs: ExpenseCategory) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    let id: String
    @Published var name: String
    @Published var subcategories: [ExpenseCategory]
    @Published var parentCategoryId: String?

    init(id: String = UUID().uuidString, name: String, parentCategoryId: String? = nil, subcategories: [ExpenseCategory] = []) {
        self.id = id
        self.name = name
        self.parentCategoryId = parentCategoryId
        self.subcategories = subcategories
    }
}
