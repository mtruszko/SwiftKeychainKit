import SwiftUI

struct LoadingButtonLabel: View {
    let isLoading: Bool
    let title: String
    let systemImage: String
    let progressTint: Color

    var body: some View {
        ZStack {
            ProgressView()
                .tint(progressTint)
                .opacity(isLoading ? 1 : 0)

            Label(title, systemImage: systemImage)
                .opacity(isLoading ? 0 : 1)
        }
    }
}

