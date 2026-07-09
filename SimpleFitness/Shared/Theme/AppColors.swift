import SwiftUI

public struct AppColors {
#if os(iOS)
    public static let background = Color(uiColor: .systemGroupedBackground)
    public static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
    public static let pillBackground = Color(uiColor: .tertiarySystemFill)
#else
    public static let background = Color(nsColor: .windowBackgroundColor)
    public static let cardBackground = Color(nsColor: .controlBackgroundColor)
    public static let pillBackground = Color(nsColor: .unemphasizedSelectedTextBackgroundColor)
#endif

    public static let primaryText = Color.primary
    public static let secondaryText = Color.secondary
    
    public static let accentBlue = Color.blue
    public static let actionGreen = Color.green
    public static let dangerRed = Color.red
}
