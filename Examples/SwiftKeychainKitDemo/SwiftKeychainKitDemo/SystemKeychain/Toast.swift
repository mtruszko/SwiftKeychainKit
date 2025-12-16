import SwiftUI

struct Toast: Identifiable, Equatable {
    enum Kind: Equatable { case success, info, error }
    let id = UUID()
    let kind: Kind
    let message: String
}

struct ToastBanner: View {
    let toast: Toast

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: iconName)
                .foregroundStyle(iconColor)

            Text(toast.message)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }

    private var iconName: String {
        switch toast.kind {
        case .success: "checkmark.circle.fill"
        case .info: "info.circle.fill"
        case .error: "xmark.circle.fill"
        }
    }

    private var iconColor: Color {
        switch toast.kind {
        case .success: .green
        case .info: .blue
        case .error: .red
        }
    }
}
