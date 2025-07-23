
import SwiftUI

struct LoadingSpinnerModifier: ViewModifier {
    @Binding var isLoading: Bool

    func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(isLoading)

            if isLoading {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5, anchor: .center)
            }
        }
    }
}

extension View {
    func loadingSpinner(isLoading: Binding<Bool>) -> some View {
        self.modifier(LoadingSpinnerModifier(isLoading: isLoading))
    }
}
