//
//  UIFont+Extension.swift
//  UniverseDesignFont
//
//  Created by 白镜吾 on 2023/3/23.
//

import UIKit

public extension UIFont {
    /// Get the font with regular weight
    var regular: UIFont { return withWeight(.regular) }

    /// Get the font with medium weight
    var medium: UIFont { return withWeight(.medium) }

    /// Get the font with semibold weight
    var semibold: UIFont { return withWeight(.semibold) }

    /// Get the font with bold weight
    var bold: UIFont { return withWeight(.bold) }

    /// Get the font with italic
    var italic: UIFont { return withItalic() }

    /// Get the font with boldItalic
    var boldItalic: UIFont {
        if UDFontAppearance.isCustomFont {
            return self.withWeight(.medium).italic
        } else {
            return self.withTraits(.traitBold, .traitItalic)
        }
    }

    var isBold: Bool {
        get {
            if UDFontAppearance.isCustomFont {
                return objc_getAssociatedObject(self, &AssociatedKeys.isBoldFontKey) as? Bool ?? false
            } else {
                return fontDescriptor.symbolicTraits.contains(.traitBold)
            }
        }
        set {
            guard UDFontAppearance.isCustomFont, newValue != isBold else { return }
            objc_setAssociatedObject(self, &AssociatedKeys.isBoldFontKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    var isItalic: Bool {
        get {
            if UDFontAppearance.isCustomFont {
                return objc_getAssociatedObject(self, &AssociatedKeys.isItalicFontKey) as? Bool ?? false
            } else {
                return fontDescriptor.symbolicTraits.contains(.traitItalic)
            }
        }
        set {
            guard UDFontAppearance.isCustomFont, newValue != isItalic else { return }
            objc_setAssociatedObject(self, &AssociatedKeys.isItalicFontKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    private struct AssociatedKeys {
        static var isBoldFontKey = "FontIsInBold"
        static var isItalicFontKey = "FontIsInItalic"
    }
}

public extension UDFont {

    // convenience methods to create system fonts
    static func systemFont(ofSize fontSize: CGFloat) -> UIFont {
        guard let customFont = UIFont.ud.customFont(ofSize: fontSize) else {
            return UIFont.systemFont(ofSize: fontSize)
        }
        return customFont
    }

    // convenience methods to create system fonts
    static func boldSystemFont(ofSize fontSize: CGFloat) -> UIFont {
        guard let customFont = UIFont.ud.customFont(ofSize: fontSize)?.medium else {
            return UIFont.boldSystemFont(ofSize: fontSize)
        }
        return customFont
    }

    // convenience methods to create system fonts
    static func italicSystemFont(ofSize fontSize: CGFloat) -> UIFont {
        guard let customFont = UIFont.ud.customFont(ofSize: fontSize)?.italic else {
            return UIFont.italicSystemFont(ofSize: fontSize)
        }
        return customFont
    }

    // convenience methods to create system fonts
    static func systemFont(ofSize fontSize: CGFloat, weight: UIFont.Weight) -> UIFont {
        guard let customFont = UIFont.ud.customFont(ofSize: fontSize, weight: weight) else {
            return UIFont.systemFont(ofSize: fontSize, weight: weight)
        }
        return customFont
    }

    // convenience methods to change to mono digit
    static func monospacedDigitSystemFont(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
        return UDFont.systemFont(ofSize: size, weight: weight).withMonospacedNumbers()
    }
}
