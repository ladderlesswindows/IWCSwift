import SwiftUI

enum IWCTheme {

    // MARK: - Backgrounds
    static let bg      = Color(hex: "080C12")
    static let bgCard  = Color(hex: "0E1A28")
    static let bgRaise = Color(hex: "162436")
    static let bgGlass = Color.white.opacity(0.04)

    // MARK: - Semantic Accents
    static let teal     = Color(hex: "00C4E8")
    static let tealDim  = Color(hex: "082D42")
    static let green    = Color(hex: "00D97E")
    static let greenDim = Color(hex: "052A1A")
    static let amber    = Color(hex: "FFB020")
    static let amberDim = Color(hex: "2E1F00")
    static let coral    = Color(hex: "FF5C5C")
    static let gold     = Color(hex: "D4A017")

    // MARK: - Text
    static let textPrimary   = Color.white
    static let textSecondary = Color.white.opacity(0.5)
    static let textTertiary  = Color.white.opacity(0.22)

    // MARK: - Borders
    static let border       = Color.white.opacity(0.07)
    static let borderAccent = Color(hex: "00C4E8").opacity(0.18)
    static let borderGold   = Color(hex: "D4A017").opacity(0.25)

    // MARK: - Video
    static let videoFadeTop = LinearGradient(
        colors: [Color(hex: "080C12"), Color(hex: "080C12").opacity(0.6), .clear],
        startPoint: .top, endPoint: .bottom
    )
    static let videoFadeBottom = LinearGradient(
        colors: [.clear, Color(hex: "080C12").opacity(0.8), Color(hex: "080C12")],
        startPoint: .top, endPoint: .bottom
    )
    static let videoBg = Color(hex: "080C12")

    // MARK: - Typography
    enum Font {
        static func hero(_ size: CGFloat = 48) -> SwiftUI.Font {
            .system(size: size, weight: .bold, design: .monospaced)
        }
        static func title(_ size: CGFloat = 22) -> SwiftUI.Font { .system(size: size, weight: .bold) }
        static func body(_ size: CGFloat = 15) -> SwiftUI.Font  { .system(size: size, weight: .regular) }
        static func label(_ size: CGFloat = 10) -> SwiftUI.Font { .system(size: size, weight: .black) }
        static func mono(_ size: CGFloat = 16) -> SwiftUI.Font  { .system(size: size, weight: .semibold, design: .monospaced) }
    }

    // MARK: - Spacing & Radius
    enum Space {
        static let xs: CGFloat = 4;  static let sm: CGFloat = 8
        static let md: CGFloat = 16; static let lg: CGFloat = 24; static let xl: CGFloat = 40
    }
    enum Radius {
        static let sm: CGFloat = 10; static let md: CGFloat = 16
        static let lg: CGFloat = 22; static let pill: CGFloat = 100
    }
}

// MARK: - Card modifier

extension View {
    func iwcCard(accent: Color = IWCTheme.border, radius: CGFloat = IWCTheme.Radius.md) -> some View {
        self
            .background(IWCTheme.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: radius))
            .overlay(RoundedRectangle(cornerRadius: radius).stroke(accent, lineWidth: 1))
    }
}

// MARK: - Micro label

struct IWCLabel: View {
    let text: String
    var color: Color = IWCTheme.textTertiary
    var body: some View {
        Text(text)
            .font(IWCTheme.Font.label())
            .tracking(2)
            .foregroundColor(color)
    }
}
