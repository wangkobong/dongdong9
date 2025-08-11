//
//  CategoryModel.swift
//  dongdong9
//
//  Created by sungyeon kim on 8/11/25.
//

import Foundation

struct CategoryModel: Codable {
    var categoryId: String = UUID().uuidString
    var budgetId: String = ""
    let categoryName: String
    let description: String
    let spendingMoney: Int
    let subCategory: [CategoryModel]
    var createdAt: Date = Date()  // Int → Date로 변경
    var updatedAt: Date?          // Int → Date로 변경
}

