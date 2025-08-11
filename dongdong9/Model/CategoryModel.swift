//
//  CategoryModel.swift
//  dongdong9
//
//  Created by sungyeon kim on 8/11/25.
//

import Foundation

struct CategoryModel: Codable {
    var categoryId: String = UUID().uuidString
    let categoryName: String
    let description: String
    let spendingMoney: Int
    let subCategory: [CategoryModel]
    var createdAt: Int = Int(Date().timeIntervalSince1970)
    var updatedAt: Int?
}

