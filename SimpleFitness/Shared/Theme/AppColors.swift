import SwiftUI
#if os(iOS)
import UIKit
#endif

public struct AppColors {
    public static let primaryText = Color.primary
    public static let secondaryText = Color.secondary
    
    public static let accentBlue = Color.blue
    public static let actionGreen = Color.green
    public static let dangerRed = Color.red
    
    public static let glassCardBackground = Color("GlassCardBackground", bundle: nil)
}

#if os(iOS)
extension AppColors {
    public static let background = Color(uiColor: .systemGroupedBackground)
    public static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
    public static let pillBackground = Color(uiColor: .tertiarySystemFill)
    
    public static var adaptiveCardBackground: Color {
        return Color(UIColor(dynamicProvider: { trait in
            trait.userInterfaceStyle == .dark ? UIColor(white: 0.13, alpha: 0.88) : UIColor(white: 1.0, alpha: 0.82)
        }))
    }
    
    public static var adaptiveGlassBorder: Color {
        return Color(UIColor(dynamicProvider: { trait in
            trait.userInterfaceStyle == .dark ? UIColor(white: 1.0, alpha: 0.14) : UIColor(white: 1.0, alpha: 0.9)
        }))
    }
    
    public static var adaptiveSurfaceHighlight: Color {
        return Color(UIColor(dynamicProvider: { trait in
            trait.userInterfaceStyle == .dark ? UIColor(white: 0.22, alpha: 0.8) : UIColor(white: 1.0, alpha: 0.95)
        }))
    }
    
    public static var adaptivePillBackground: Color {
        return Color(UIColor(dynamicProvider: { trait in
            trait.userInterfaceStyle == .dark ? UIColor(white: 1.0, alpha: 0.12) : UIColor(red: 0.94, green: 0.94, blue: 0.96, alpha: 1.0)
        }))
    }
    
    public static var adaptiveCardShadow: Color {
        return Color(UIColor(dynamicProvider: { trait in
            trait.userInterfaceStyle == .dark ? UIColor(white: 0.0, alpha: 0.45) : UIColor(white: 0.0, alpha: 0.06)
        }))
    }
}
#elseif os(watchOS)
extension AppColors {
    public static var isWatchLightMode: Bool {
        return UserDefaults.standard.string(forKey: "appThemeMode") == "light"
    }
    
    public static var background: Color {
        return isWatchLightMode ? Color(red: 0.95, green: 0.96, blue: 0.98) : Color.black
    }
    
    public static var cardBackground: Color {
        return isWatchLightMode ? Color.white : Color(red: 0.14, green: 0.14, blue: 0.17)
    }
    
    public static var pillBackground: Color {
        return isWatchLightMode ? Color(white: 0.9) : Color(white: 0.2)
    }
    
    public static var adaptiveCardBackground: Color {
        return isWatchLightMode ? Color(white: 1.0, opacity: 0.94) : Color(red: 0.14, green: 0.14, blue: 0.17, opacity: 0.84)
    }
    
    public static var adaptiveGlassBorder: Color {
        return isWatchLightMode ? Color(red: 1.0, green: 0.6, blue: 0.0, opacity: 0.22) : Color(red: 1.0, green: 0.7, blue: 0.3, opacity: 0.28)
    }
    
    public static var adaptiveSurfaceHighlight: Color {
        return isWatchLightMode ? Color.white : Color(white: 0.26, opacity: 0.85)
    }
    
    public static var adaptivePillBackground: Color {
        return isWatchLightMode ? Color(white: 0.88) : Color(white: 1.0, opacity: 0.15)
    }
    
    public static var adaptiveCardShadow: Color {
        return isWatchLightMode ? Color(white: 0.0, opacity: 0.08) : Color(white: 0.0, opacity: 0.45)
    }
}
#else
extension AppColors {
    public static let background = Color(nsColor: .windowBackgroundColor)
    public static let cardBackground = Color(nsColor: .controlBackgroundColor)
    public static let pillBackground = Color(nsColor: .unemphasizedSelectedTextBackgroundColor)
    
    public static var adaptiveCardBackground: Color { return cardBackground }
    public static var adaptiveGlassBorder: Color { return Color.white.opacity(0.2) }
    public static var adaptiveSurfaceHighlight: Color { return Color.white }
    public static var adaptivePillBackground: Color { return pillBackground }
    public static var adaptiveCardShadow: Color { return Color.black.opacity(0.1) }
}
#endif

public enum AppThemeMode: String, CaseIterable, Identifiable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .system: return "跟随系统"
        case .light: return "浅色模式"
        case .dark: return "深色模式"
        }
    }
    
    public var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
    
    public var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
