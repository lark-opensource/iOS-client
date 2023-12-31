//
//  UDFont.swift
//  UniverseDesignFont
//
//  Created by Hayden on 2021/4/29.
//

import Foundation
import UIKit
import UniverseDesignTheme

/// Define all fonts used in Universe Design.
public enum UDFont {

    public static var tracker: UDTrackerDependency?

    private init() {
        fatalError("UDFont is a namespace and can not be initialized.")
    }

    private struct FontCacheKey: Hashable, Equatable {
        var size: CGFloat
        var weight: UIFont.Weight
    }

    private static var fontCache: [FontCacheKey: UIFont] = [:]

    private static func getFont(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
        guard UDZoom.isCacheEnabled else {
            return .systemFont(ofSize: size, weight: weight)
        }
        let key = FontCacheKey(size: size, weight: weight)
        // TODO: Multi-thread protection.
        if let font = fontCache[key] {
            return font
        } else {
            let font = UIFont.systemFont(ofSize: size, weight: weight)
            fontCache[key] = font
            return font
        }
    }

    /// Font for #title0# in specified app zoom level.
    public static func getTitle0(for zoomLevel: UDZoom) -> UIFont {
        return FontType.title0.uiFont(forZoom: zoomLevel)
    }

    /// Font for #title1# in specified app zoom level.
    public static func getTitle1(for zoomLevel: UDZoom) -> UIFont {
        return FontType.title1.uiFont(forZoom: zoomLevel)
    }

    /// Font for #title2# in specified app zoom level.
    public static func getTitle2(for zoomLevel: UDZoom) -> UIFont {
        return FontType.title2.uiFont(forZoom: zoomLevel)
    }

    /// Font for #title3# in specified app zoom level.
    public static func getTitle3(for zoomLevel: UDZoom) -> UIFont {
        return FontType.title3.uiFont(forZoom: zoomLevel)
    }

    /// Font for #title4# in specified app zoom level.
    public static func getTitle4(for zoomLevel: UDZoom) -> UIFont {
        return FontType.title4.uiFont(forZoom: zoomLevel)
    }

    /// Font for #headline# in specified app zoom level.
    public static func getHeadline(for zoomLevel: UDZoom) -> UIFont {
        return FontType.headline.uiFont(forZoom: zoomLevel)
    }

    /// Font for #body0# in specified app zoom level.
    public static func getBody0(for zoomLevel: UDZoom) -> UIFont {
        return FontType.body0.uiFont(forZoom: zoomLevel)
    }

    /// Font for #body1# in specified app zoom level.
    public static func getBody1(for zoomLevel: UDZoom) -> UIFont {
        return FontType.body1.uiFont(forZoom: zoomLevel)
    }

    /// Font for #body2# in specified app zoom level.
    public static func getBody2(for zoomLevel: UDZoom) -> UIFont {
        return FontType.body2.uiFont(forZoom: zoomLevel)
    }

    /// Font for #caption0# in specified app zoom level.
    public static func getCaption0(for zoomLevel: UDZoom) -> UIFont {
        return FontType.caption0.uiFont(forZoom: zoomLevel)
    }

    /// Font for #caption1# in specified app zoom level.
    public static func getCaption1(for zoomLevel: UDZoom) -> UIFont {
        return FontType.caption1.uiFont(forZoom: zoomLevel)
    }

    /// Font for #caption2# in specified app zoom level.
    public static func getCaption2(for zoomLevel: UDZoom) -> UIFont {
        return FontType.caption2.uiFont(forZoom: zoomLevel)
    }

    /// Font for #caption3# in specified app zoom level.
    public static func getCaption3(for zoomLevel: UDZoom) -> UIFont {
        return FontType.caption3.uiFont(forZoom: zoomLevel)
    }

    static let fontSizesToRowHeights: [CGFloat: CGFloat] = [
        9:  12,     // factor: 1.333333333
        10: 14,     // factor: 1.4
        11: 16,     // factor: 1.454545455
        12: 18,     // factor: 1.5
        13: 20,     // factor: 1.538461538
        14: 20,     // factor: 1.428571429
        15: 22,     // factor: 1.466666667
        16: 22,     // factor: 1.375
        17: 24,     // factor: 1.411764706
        18: 26,     // factor: 1.444444444
        20: 28,     // factor: 1.4
        22: 30,     // factor: 1.363636364
        24: 32,     // factor: 1.333333333
        26: 34,     // factor: 1.307692308
        28: 38,     // factor: 1.357142857
        30: 40,     // factor: 1.333333333
        32: 44,     // factor: 1.375
        34: 46,     // factor: 1.352941176
        36: 48,     // factor: 1.333333333
        40: 54      // factor: 1.35
    ]

    /// The row height of specific font size in fxxking FIGMA system.
    static func figmaHeightFor(fontSize: CGFloat) -> CGFloat {
        if let rowHeight = fontSizesToRowHeights[fontSize] {
            return rowHeight
        } else {
            return ceil(fontSize * 1.4)
        }
    }
}

public extension UDFont {

    /*
     Since Lark 4.0+, font naming has been changed:
         old title          ->      new title0
         old heading1       ->      new title1
         old heading2       ->      new title2
         old heading3       ->      new title3
         old subheading     ->      new title4
         old body0          ->      new headline
         old body1          ->      new body0
         old body2          ->      new body1
         old body3          ->      new body2
         old caption1       ->      new caption0
         old caption2       ->      new caption1
         old caption3       ->      new caption2
         old caption4       ->      new caption3
     */

    /// All font type used in figma design.
    ///
    /// For more detail:
    /// - [UX design](https://www.figma.com/file/yKYkojv3iksFanzpDW2xL9/Font--Zoom?node-id=192%3A200041)
    /// - [PR document](https://bytedance.feishu.cn/docs/doccn12RsYiA8ounW5Uqq6mrLAg#I8Qw3N)
    enum FontType: String, CaseIterable {
        case title0
        case title1
        case title2
        case title3
        case title4
        case headline
        case body0
        case body1
        case body2
        case caption0
        case caption1
        case caption2
        case caption3

        /// Return practical font type for specific zoom level.
        public func uiFont(forZoom zoom: UDZoom) -> UIFont {
            switch zoom {
            case .small1:   return uiFontForSmall1
            case .normal:   return uiFontForNormal
            case .large1:   return uiFontForLarge1
            case .large2:   return uiFontForLarge2
            case .large3:   return uiFontForLarge3
            case .large4:   return uiFontForLarge4
            }
        }
    }
}

internal extension UDFont.FontType {

    /// Font dictionary for small1 zoom level.
    private var uiFontForSmall1: UIFont {
        switch self {
        case .title0:   return UDFont.getFont(ofSize: 24, weight: .semibold)
        case .title1:   return UDFont.getFont(ofSize: 22, weight: .semibold)
        case .title2:   return UDFont.getFont(ofSize: 18, weight: .medium)
        case .title3:   return UDFont.getFont(ofSize: 16, weight: .medium)
        case .title4:   return UDFont.getFont(ofSize: 16, weight: .regular)
        case .headline: return UDFont.getFont(ofSize: 15, weight: .medium)
        case .body0:    return UDFont.getFont(ofSize: 15, weight: .regular)
        case .body1:    return UDFont.getFont(ofSize: 13, weight: .medium)
        case .body2:    return UDFont.getFont(ofSize: 13, weight: .regular)
        case .caption0: return UDFont.getFont(ofSize: 11, weight: .medium)
        case .caption1: return UDFont.getFont(ofSize: 11, weight: .regular)
        case .caption2: return UDFont.getFont(ofSize: 9, weight: .medium)
        case .caption3: return UDFont.getFont(ofSize: 9, weight: .regular)
        }
    }

    /// Font dictionary for normal zoom level.
    private var uiFontForNormal: UIFont {
        switch self {
        case .title0:   return UDFont.getFont(ofSize: 26, weight: .semibold)
        case .title1:   return UDFont.getFont(ofSize: 24, weight: .semibold)
        case .title2:   return UDFont.getFont(ofSize: 20, weight: .medium)
        case .title3:   return UDFont.getFont(ofSize: 17, weight: .medium)
        case .title4:   return UDFont.getFont(ofSize: 17, weight: .regular)
        case .headline: return UDFont.getFont(ofSize: 16, weight: .medium)
        case .body0:    return UDFont.getFont(ofSize: 16, weight: .regular)
        case .body1:    return UDFont.getFont(ofSize: 14, weight: .medium)
        case .body2:    return UDFont.getFont(ofSize: 14, weight: .regular)
        case .caption0: return UDFont.getFont(ofSize: 12, weight: .medium)
        case .caption1: return UDFont.getFont(ofSize: 12, weight: .regular)
        case .caption2: return UDFont.getFont(ofSize: 10, weight: .medium)
        case .caption3: return UDFont.getFont(ofSize: 10, weight: .regular)
        }
    }

    /// Font dictionary for large1 zoom level.
    private var uiFontForLarge1: UIFont {
        switch self {
        case .title0:   return UDFont.getFont(ofSize: 28, weight: .semibold)
        case .title1:   return UDFont.getFont(ofSize: 26, weight: .semibold)
        case .title2:   return UDFont.getFont(ofSize: 22, weight: .medium)
        case .title3:   return UDFont.getFont(ofSize: 18, weight: .medium)
        case .title4:   return UDFont.getFont(ofSize: 18, weight: .regular)
        case .headline: return UDFont.getFont(ofSize: 17, weight: .medium)
        case .body0:    return UDFont.getFont(ofSize: 17, weight: .regular)
        case .body1:    return UDFont.getFont(ofSize: 15, weight: .medium)
        case .body2:    return UDFont.getFont(ofSize: 15, weight: .regular)
        case .caption0: return UDFont.getFont(ofSize: 13, weight: .medium)
        case .caption1: return UDFont.getFont(ofSize: 13, weight: .regular)
        case .caption2: return UDFont.getFont(ofSize: 11, weight: .medium)
        case .caption3: return UDFont.getFont(ofSize: 11, weight: .regular)
        }
    }

    /// Font dictionary for large2 zoom level.
    private var uiFontForLarge2: UIFont {
        switch self {
        case .title0:   return UDFont.getFont(ofSize: 30, weight: .semibold)
        case .title1:   return UDFont.getFont(ofSize: 28, weight: .semibold)
        case .title2:   return UDFont.getFont(ofSize: 24, weight: .medium)
        case .title3:   return UDFont.getFont(ofSize: 20, weight: .medium)
        case .title4:   return UDFont.getFont(ofSize: 20, weight: .regular)
        case .headline: return UDFont.getFont(ofSize: 18, weight: .medium)
        case .body0:    return UDFont.getFont(ofSize: 18, weight: .regular)
        case .body1:    return UDFont.getFont(ofSize: 16, weight: .medium)
        case .body2:    return UDFont.getFont(ofSize: 16, weight: .regular)
        case .caption0: return UDFont.getFont(ofSize: 14, weight: .medium)
        case .caption1: return UDFont.getFont(ofSize: 14, weight: .regular)
        case .caption2: return UDFont.getFont(ofSize: 12, weight: .medium)
        case .caption3: return UDFont.getFont(ofSize: 12, weight: .regular)
        }
    }

    /// Font dictionary for large3 zoom level.
    private var uiFontForLarge3: UIFont {
        switch self {
        case .title0:   return UDFont.getFont(ofSize: 34, weight: .semibold)
        case .title1:   return UDFont.getFont(ofSize: 32, weight: .semibold)
        case .title2:   return UDFont.getFont(ofSize: 28, weight: .medium)
        case .title3:   return UDFont.getFont(ofSize: 24, weight: .medium)
        case .title4:   return UDFont.getFont(ofSize: 24, weight: .regular)
        case .headline: return UDFont.getFont(ofSize: 20, weight: .medium)
        case .body0:    return UDFont.getFont(ofSize: 20, weight: .regular)
        case .body1:    return UDFont.getFont(ofSize: 18, weight: .medium)
        case .body2:    return UDFont.getFont(ofSize: 18, weight: .regular)
        case .caption0: return UDFont.getFont(ofSize: 15, weight: .medium)
        case .caption1: return UDFont.getFont(ofSize: 15, weight: .regular)
        case .caption2: return UDFont.getFont(ofSize: 13, weight: .medium)
        case .caption3: return UDFont.getFont(ofSize: 13, weight: .regular)
        }
    }

    /// Font dictionary for large4 zoom level.
    private var uiFontForLarge4: UIFont {
        switch self {
        case .title0:   return UDFont.getFont(ofSize: 40, weight: .semibold)
        case .title1:   return UDFont.getFont(ofSize: 36, weight: .semibold)
        case .title2:   return UDFont.getFont(ofSize: 32, weight: .medium)
        case .title3:   return UDFont.getFont(ofSize: 28, weight: .medium)
        case .title4:   return UDFont.getFont(ofSize: 28, weight: .regular)
        case .headline: return UDFont.getFont(ofSize: 24, weight: .medium)
        case .body0:    return UDFont.getFont(ofSize: 24, weight: .regular)
        case .body1:    return UDFont.getFont(ofSize: 20, weight: .medium)
        case .body2:    return UDFont.getFont(ofSize: 20, weight: .regular)
        case .caption0: return UDFont.getFont(ofSize: 16, weight: .medium)
        case .caption1: return UDFont.getFont(ofSize: 16, weight: .regular)
        case .caption2: return UDFont.getFont(ofSize: 14, weight: .medium)
        case .caption3: return UDFont.getFont(ofSize: 14, weight: .regular)
        }
    }
}
