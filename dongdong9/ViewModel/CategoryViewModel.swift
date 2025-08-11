//
//  CategoryViewModel.swift
//  dongdong9
//
//  Created by sungyeon kim on 8/8/25.
//

import Foundation
import Combine

class CategoryViewModel: ObservableObject {
    @Published var categories: [CategoryModel] = []
    
    func addCategory(_ category: CategoryModel) async {
        print("카테고리: \(category)")
        do {
            print("do 성공")
            try await  FirebaseService.shared.addCategory(category: category)
        } catch {
            print("카테고리 추가 실패: \(error)")
        }
    }
    
    
    
    
}
