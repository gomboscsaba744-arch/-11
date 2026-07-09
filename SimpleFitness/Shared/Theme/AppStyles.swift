import SwiftUI

public struct CardStyleModifier: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .background(AppColors.cardBackground)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

public extension View {
    func standardCardStyle() -> some View {
        modifier(CardStyleModifier())
    }
}
