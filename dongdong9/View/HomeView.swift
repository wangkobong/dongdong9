
import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("월별 예산 현황")
                    .font(.largeTitle)
                    .padding()
                // TODO: 여기에 월별 예산 현황을 보여주는 UI를 추가합니다.
                Spacer()
            }
            .navigationTitle("홈")
        }
    }
}
