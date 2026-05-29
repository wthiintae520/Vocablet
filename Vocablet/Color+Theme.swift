import SwiftUI

extension Color {
    static let lilyBackground = Color(red: 0.98, green: 0.98, blue: 0.97)
    static let lilyCard = Color.white
    static let lilyAccent = Color(red: 0.722, green: 0.831, blue: 0.910)   // #B8D4E8 folder-H
    static let lilyPeach = Color(red: 0.96, green: 0.90, blue: 0.83)
    static let lilyText = Color(red: 0.361, green: 0.333, blue: 0.322)    // #5C5552 warm charcoal
    static let lilySecondaryText = Color(red: 0.54, green: 0.54, blue: 0.54)
    static let lilyBorder = Color(red: 0.92, green: 0.92, blue: 0.90)

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 200, 200, 200)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

enum LilyPalette {
    static let folderColors = [
        "#7EC8A4", "#A8C8E8", "#F4A8C0", "#F4D4A0",
        "#C4B4E8", "#A8D8B0", "#F4B8A0", "#B8D4E8"
    ]
    static let folderIcons = [
        "folder.fill", "book.fill", "star.fill", "heart.fill",
        "graduationcap.fill", "briefcase.fill", "globe", "pencil"
    ]
}

struct LilyCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.lilyCard)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

extension View {
    func lilyCard() -> some View { modifier(LilyCardStyle()) }
}
