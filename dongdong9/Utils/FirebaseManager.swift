//
//  FirebaseManager.swift
//  dongdong9
//
//  Created by sungyeon kim on 7/24/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class FirebaseManager {
    
    let db = Firestore.firestore()
    
    func checkIfNewUser(completion: @escaping (Bool, Error?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(false, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user is logged in"]))
            return
        }
        
        let userRef = db.collection("Users").document(user.uid)
        
        userRef.getDocument { (document, error) in
            if let error = error {
                completion(false, error)
                return
            }
            
            if document?.exists == true {
                // 기존 유저
                completion(false, nil)
            } else {
                // 첫 로그인
                completion(true, nil)
            }
        }
    }
    
    func saveUserToFirestore(user: User, completion: @escaping (Error?) -> Void) {
            let userRef = db.collection("Users").document(user.uid)
            let userData: [String: Any] = [
                "userID": user.uid,
                "email": user.email ?? "",
                "displayName": user.displayName ?? "",
                "createdAt": FieldValue.serverTimestamp(),
                "fcmToken": "",
                "providerId": user.providerID,
                // 필요한 추가 필드
            ]
        

            userRef.setData(userData) { error in
                completion(error)
            }
        }
    
    
}
