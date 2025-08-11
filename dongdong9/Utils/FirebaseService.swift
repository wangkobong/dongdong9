
import Foundation
import FirebaseFunctions
import FirebaseAuth
import FirebaseFirestore


// Firebase Functions 호출 시 발생할 수 있는 커스텀 에러
enum FirebaseServiceError: Error {
    case invalidResponse // 서버로부터 받은 응답이 예상과 다를 때
    case dataDecodingError // 데이터 디코딩 실패
}

/**
 Firebase Functions와의 모든 통신을 담당하는 서비스 클래스입니다.
 싱글톤으로 구현되어 앱 전체에서 하나의 인스턴스를 공유합니다.
*/
class FirebaseService {
    
    // MARK: - Singleton Instance
    static let shared = FirebaseService()
    
    // MARK: - Properties
    let functions = Functions.functions(region: "us-central1")

    // private 생성자로 외부에서 직접 인스턴스를 생성하는 것을 방지합니다.
    private init() {}
    
    // MARK: - Public Methods
    
    /**
     서버에 배포된 'createBudget' 함수를 호출합니다.
     성공 시, 생성된 가계부의 ID(String)를 반환합니다.
     - Throws: 함수 호출 실패 또는 서버로부터 에러 응답을 받을 경우 에러를 던집니다.
     */
    func createBudget(userId: String) async throws -> String {
        do {
            
            let userInfo: [String: Any] = [
                "userID": userId,
            ]

            print("Sending userInfo: \(userInfo)")
            // 'createBudget' 함수를 호출하고 응답을 기다립니다.
            let result = try await functions.httpsCallable("createBudget").call(userInfo)
            
            // 반환된 데이터가 예상된 형식인지 확인합니다.
            guard let data = result.data as? [String: Any],
                  let status = data["status"] as? String, status == "success",
                  let budgetId = data["budgetId"] as? String else {
                // 형식이 맞지 않으면 커스텀 에러를 던집니다.
                throw FirebaseServiceError.invalidResponse
            }
            
            // 성공적으로 budgetId를 반환합니다.
            return budgetId
            
        } catch {
            // HTTPSCallableError 등 Firebase에서 발생한 에러를 그대로 다시 던지거나,
            // 필요에 따라 커스텀 에러로 감싸서 처리할 수 있습니다.
            print("FirebaseService Error - createBudget: \(error.localizedDescription)")
            throw error
        }
    }
    
    func createUser(user: User) async throws -> Void {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(user.uid)

        let document = try await userRef.getDocument()

        if document.exists == false {
            let currentTime = ISO8601DateFormatter().string(from: Date())

            let userInfo: [String: Any] = [
                "userID": user.uid,
                "email": user.email ?? "",
                "displayName": user.displayName ?? "",
                "profileImageUrl": user.photoURL?.absoluteString ?? ""
            ]

            print("Sending userInfo: \(userInfo)")


            // Firebase Function 'onUserCreate' 호출 (Auth 트리거이므로 직접 호출은 불필요할 수 있음. 확인 필요)
            // 만약 이 함수가 Auth 트리거가 아닌 일반 Callable Function이라면 아래 코드를 사용.
            // 현재 구조상 Auth 트리거이므로 이 부분은 주석 처리하거나 제거하는 것이 맞을 수 있습니다.
            do {
                let result = try await functions.httpsCallable("onUserCreate").call(userInfo)
                print("onUserCreate result: \(result.data)")

            } catch {
                print("에러: \(error)")
            }
//            print("onUserCreate result: \(result)")
//             guard let data = result.data as? [String: Any],
//                   let status = data["status"] as? String, status == "success",
//                   let userId = data["userId"] as? String else {
//                 throw FirebaseServiceError.invalidResponse
//             }

        } else {
            // User document exists, update only relevant fields (e.g., lastLoginAt)
            let updateData: [String: Any] = [
                "email": user.email ?? "",
                "displayName": user.displayName ?? "",
                "photoURL": user.photoURL?.absoluteString ?? "",
                "lastLoginAt": FieldValue.serverTimestamp()
            ]
            try await userRef.updateData(updateData)
            print("Existing user data successfully updated in Firestore.")
        }
    }

    func addCategory(category: CategoryModel) async throws -> String {
        let data: [String: Any] = [
            "budgetId": category.budgetId,
            "categoryName": category.categoryName,
            "description": category.description,
            "spendingMoney": category.spendingMoney,
            "subCategory": [] // 서브카테고리는 현재 지원하지 않으므로 빈 배열로 보냅니다.
        ]

        do {
            let result = try await functions.httpsCallable("addCategory").call(data)
            guard let resultData = result.data as? [String: Any],
                  let status = resultData["status"] as? String, status == "success",
                  let categoryId = resultData["categoryId"] as? String else {
                throw FirebaseServiceError.invalidResponse
            }
            return categoryId
        } catch {
            print("FirebaseService Error - addCategory: \(error.localizedDescription)")
            throw error
        }
    }

    func addFixedExpense(fixedExpense: FixedExpenseModel) async throws -> String {
        // FixedExpenseModel을 딕셔너리로 변환 (Firestore에 저장할 수 있도록)
        // Codable을 사용하므로 JSONEncoder를 통해 변환
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601 // Date 타입을 ISO8601 문자열로 인코딩

        guard let data = try? encoder.encode(fixedExpense) else {
            throw FirebaseServiceError.dataDecodingError
        }
        
        guard let dictionary = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            throw FirebaseServiceError.dataDecodingError
        }

        do {
            let result = try await functions.httpsCallable("addFixedExpense").call(dictionary)
            guard let resultData = result.data as? [String: Any],
                  let status = resultData["status"] as? String, status == "success",
                  let fixedExpenseId = resultData["fixedExpenseId"] as? String else {
                throw FirebaseServiceError.invalidResponse
            }
            return fixedExpenseId
        } catch {
            print("FirebaseService Error - addFixedExpense: \(error.localizedDescription)")
            throw error
        }
    }
}
