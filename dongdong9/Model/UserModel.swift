//
//  UserModel.swift
//  dongdong9
//
//  Created by sungyeon kim on 7/24/25.
//

import Foundation

struct UserModel: Codable {
    let createdAt: String
    let updatedAt: String
    let email: String
    let fcmToken: String?
    let nickname: String
    let phoneNumber: String?
    let provider: String
    let providerId: String
    let profileImageUrl: String?
    let userID: String
}
