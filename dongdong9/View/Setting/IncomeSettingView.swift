import SwiftUI

struct IncomeSettingView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var budgetViewModel: BudgetViewModel
    
    @State private var incomeString: String = ""
    @Environment(\.presentationMode) var presentationMode

    // 숫자를 통화 형식으로 변환해주는 Formatter
    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()

    var body: some View {
        VStack(spacing: 20) {
            Text("나의 월 소득을 입력해주세요.")
                .font(.headline)
                .padding(.top, 30)

            HStack {
                TextField("소득 금액", text: $incomeString)
                    .keyboardType(.numberPad)
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(10)
                    .font(.title2)
                    .multilineTextAlignment(.trailing)
                Text("원")
                    .font(.title2)
            }
            .padding(.horizontal)

            Button(action: saveIncome) {
                Text("저장하기")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(10)
            }
            .padding(.horizontal)

            Spacer()
        }
        .navigationTitle("소득 설정")
        .onAppear(perform: loadCurrentUserIncome)
        .onChange(of: incomeString) { newValue in
            // 사용자가 입력할 때마다 3자리마다 콤마를 찍어줌
            let filtered = newValue.filter { "0123456789".contains($0) }
            if let number = Int(filtered) {
                incomeString = currencyFormatter.string(from: NSNumber(value: number)) ?? ""
            } else {
                incomeString = ""
            }
        }
    }

    private func loadCurrentUserIncome() {
        guard let userId = authViewModel.userSession?.uid else { return }
        let currentUserIncome = budgetViewModel.incomes[userId] ?? 0
        if currentUserIncome > 0 {
            incomeString = currencyFormatter.string(from: NSNumber(value: currentUserIncome)) ?? ""
        }
    }

    private func saveIncome() {
        // 콤마 제거 후 Double로 변환
        let numberString = incomeString.replacingOccurrences(of: ",", with: "")
        guard let incomeValue = Double(numberString), incomeValue >= 0 else {
            print("Invalid income value")
            // TODO: 사용자에게 유효하지 않은 값이라는 알림 표시
            return
        }
        let name = authViewModel.userSession?.displayName ?? ""
        budgetViewModel.updateMyIncome(income: incomeValue, name: name)
        presentationMode.wrappedValue.dismiss() // 저장 후 화면 닫기
    }
}

struct IncomeSettingView_Previews: PreviewProvider {
    static var previews: some View {
        // Preview를 위한 목업 데이터 설정
        let authViewModel = AuthViewModel()
        let budgetViewModel = BudgetViewModel(authViewModel: authViewModel)

        // 참고: SwiftUI 프리뷰에서는 실제 FirebaseAuth.User 객체를 생성할 수 없으므로,
        // 로그인된 상태나 소득이 미리 입력된 상태를 완벽히 재현하기 어렵습니다.
        // 뷰의 기본 레이아웃을 확인하는 용도로 사용합니다.

        return NavigationView {
            IncomeSettingView()
                .environmentObject(authViewModel)
                .environmentObject(budgetViewModel)
        }
    }
}
