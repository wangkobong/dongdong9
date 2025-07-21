
import SwiftUI

struct LoginView: View {
    @Binding var isLoggedIn: Bool

    var body: some View {
        VStack(spacing: 20) {
            Text("DongDong9")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 50)

            Button(action: {
                // TODO: Implement Google Login
                isLoggedIn = true
            }) {
                HStack {
                    Image(systemName: "g.circle.fill")
                        .font(.title)
                    Text("Google로 로그인")
                        .fontWeight(.semibold)
                }
                .frame(minWidth: 0, maxWidth: .infinity)
                .padding()
                .foregroundColor(.white)
                .background(Color.red)
                .cornerRadius(40)
            }

            Button(action: {
                // TODO: Implement Apple Login
                isLoggedIn = true
            }) {
                HStack {
                    Image(systemName: "applelogo")
                        .font(.title)
                    Text("Apple로 로그인")
                        .fontWeight(.semibold)
                }
                .frame(minWidth: 0, maxWidth: .infinity)
                .padding()
                .foregroundColor(.white)
                .background(Color.black)
                .cornerRadius(40)
            }
        }
        .padding()
    }
}
