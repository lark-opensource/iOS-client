import Foundation
@objc
public enum LKThemeMode: Int {
    case dark, light
}

@objcMembers
public class LKTheme: NSObject {
    public static var mode: LKThemeMode = .light
    public static let themeDidChange: String = "LKKAThemeDidChange"
}
