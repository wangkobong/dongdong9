
import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("앱 설정")
                    .font(.largeTitle)
                    .padding()
                // TODO: 여기에 앱 관련 설정 UI를 추가합니다. (예: 로그아웃, 알림 설정 등)
                Spacer()
            }
            .navigationTitle("설정")
        }
    }
}
