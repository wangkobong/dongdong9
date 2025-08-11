
import Foundation

struct FixedExpenseModel: Codable {
    let fixedExpenseId: String // 고정 지출의 고유 ID
    let budgetId: String // 이 고정 지출이 속한 가계부 ID
    let name: String // 고정 지출 항목 이름 (예: 월세, 통신비)
    let amount: Double // 금액
    let createdAt: Date // 생성일
    var updatedAt: Date? // 수정일

    // 새로운 고정 지출 생성 시 사용될 초기화
    init(fixedExpenseId: String = UUID().uuidString, budgetId: String, name: String, amount: Double, createdAt: Date = Date(), updatedAt: Date? = nil) {
        self.fixedExpenseId = fixedExpenseId
        self.budgetId = budgetId
        self.name = name
        self.amount = amount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
