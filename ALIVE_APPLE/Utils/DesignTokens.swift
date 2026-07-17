import SwiftUI

/// Design tokens from Docs/UI_MOCKUPS.md — single source for dark product look
enum AliveTokens {
    // Backgrounds
    static let bgDeepest = Color(red: 0.051, green: 0.051, blue: 0.051)      // #0D0D0D
    static let bgCard = Color(red: 0.102, green: 0.102, blue: 0.102)          // #1A1A1A
    static let bgElevated = Color(red: 0.141, green: 0.141, blue: 0.141)      // #242424
    static let bgHover = Color(red: 0.180, green: 0.180, blue: 0.180)         // #2E2E2E
    
    // Text
    static let textPrimary = Color.white
    static let textSecondary = Color(red: 0.60, green: 0.60, blue: 0.60)      // ~#999
    static let textTertiary = Color(red: 0.53, green: 0.53, blue: 0.53)       // ~#888 (readable)
    
    // Accents (match RoutingTier)
    static let accentFast = Color(red: 0.298, green: 0.686, blue: 0.314)      // #4CAF50
    static let accentModerate = Color(red: 1.0, green: 0.596, blue: 0.0)      // #FF9800
    static let accentPro = Color(red: 0.129, green: 0.588, blue: 0.953)       // #2196F3
    static let accentError = Color(red: 0.957, green: 0.263, blue: 0.212)     // #F44336
    
    static let border = Color(red: 0.20, green: 0.20, blue: 0.20)             // #333
    static let codeBg = Color(red: 0.118, green: 0.118, blue: 0.118)          // #1E1E1E
    
    // Spacing
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
}
