//
//  IncomeModel.swift
//  dongdong9
//
//  Created by sungyeon kim on 8/25/25.
//

import Foundation
import FirebaseFirestore
//import FirebaseFirestoreSwift

struct IncomeModel: Codable, Identifiable, Hashable {
    @DocumentID var id: String? // Firestore 문서 ID를 자동으로 매핑
    let newIncomeId: String
    let budgetId: String
    let name: String
    let amount: Double
    let updatedAt: Timestamp
    let createdAt: Timestamp
}
