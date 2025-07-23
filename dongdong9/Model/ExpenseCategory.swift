
import Foundation

class ExpenseCategory: Identifiable, ObservableObject, Hashable {
    // Hashable and Equatable conformance for use in collections
    static func == (lhs: ExpenseCategory, rhs: ExpenseCategory) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    let id = UUID()
    @Published var name: String
    @Published var subcategories: [ExpenseCategory]

    init(name: String, subcategories: [ExpenseCategory] = []) {
        self.name = name
        self.subcategories = subcategories
    }
}
