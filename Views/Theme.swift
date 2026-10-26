import SwiftUI

enum WellnessTheme {
    static let welcomeBackground = Color(red: 0.97, green: 0.97, blue: 0.93)
    static let muted = Color(red: 0.39, green: 0.45, blue: 0.40)
    static let ink = Color(red: 0.13, green: 0.24, blue: 0.22)
    static let accent = Color(red: 0.19, green: 0.37, blue: 0.31)
    static let background = Color(uiColor: .systemGroupedBackground)
    static let card = Color(uiColor: .secondarySystemGroupedBackground)
}

extension Persona {
    var tint: Color {
        switch self {
        case .teacup: return Color(red: 0.19, green: 0.37, blue: 0.31)
        case .basket: return Color(red: 0.46, green: 0.28, blue: 0.34)
        case .boomerang: return Color(red: 0.43, green: 0.31, blue: 0.11)
        case .lantern: return Color(red: 0.51, green: 0.26, blue: 0.15)
        }
    }

    var surface: Color {
        switch self {
        case .teacup: return Color(red: 0.88, green: 0.94, blue: 0.89)
        case .basket: return Color(red: 0.96, green: 0.90, blue: 0.92)
        case .boomerang: return Color(red: 0.98, green: 0.94, blue: 0.81)
        case .lantern: return Color(red: 0.98, green: 0.89, blue: 0.81)
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 54)
            .foregroundStyle(.white)
            .background(WellnessTheme.accent.opacity(isEnabled ? (configuration.isPressed ? 0.8 : 1) : 0.4))
            .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

struct SupportCaption: View {
    var body: some View {
        Text("A companion for everyday moments.\nHuman support is always an option.")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }
}
