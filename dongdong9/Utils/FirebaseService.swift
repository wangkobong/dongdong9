
import Foundation
import FirebaseFunctions

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
    private lazy var functions = Functions.functions() // Functions 인스턴스
    
    // private 생성자로 외부에서 직접 인스턴스를 생성하는 것을 방지합니다.
    private init() {}
    
    // MARK: - Public Methods
    
    /**
     서버에 배포된 'createBudget' 함수를 호출합니다.
     성공 시, 생성된 가계부의 ID(String)를 반환합니다.
     - Throws: 함수 호출 실패 또는 서버로부터 에러 응답을 받을 경우 에러를 던집니다.
     */
    func createBudget() async throws -> String {
        do {
            // 'createBudget' 함수를 호출하고 응답을 기다립니다.
            let result = try await functions.httpsCallable("createBudget").call()
            
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
    
    /**
     테스트용 'helloWorld' 함수를 호출합니다.
     */
    func helloWorld() async throws -> String {
        let result = try await functions.httpsCallable("helloWorld").call()
        guard let data = result.data as? [String: Any],
              let message = data["message"] as? String else {
            throw FirebaseServiceError.invalidResponse
        }
        return message
    }
}
