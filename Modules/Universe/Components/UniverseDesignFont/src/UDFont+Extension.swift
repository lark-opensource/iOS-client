//
//  UDFont+Extension.swift
//  UniverseDesignFont
//
//  Created by Hayden on 2021/4/29.
//

import Foundation
import UniverseDesignTheme
import UIKit

// MARK: Protocol definition

/// UniverseDesign font with specified transformer.
public protocol UDFontFamily {

    /// Return a **TITLE0** font instance at specific zooming system.
    static func title0(_ transformer: UDZoom.Transformer) -> UIFont
    /// Return a **TITLE1** font instance at specific zooming system.
    static func title1(_ transformer: UDZoom.Transformer) -> UIFont
    /// Return a **TITLE2** font instance at specific zooming system.
    static func title2(_ transformer: UDZoom.Transformer) -> UIFont
    /// Return a **TITLE3** font instance at specific zooming system.
    static func title3(_ transformer: UDZoom.Transformer) -> UIFont
    /// Return a **TITLE4** font instance at specific zooming system.
    static func title4(_ transformer: UDZoom.Transformer) -> UIFont
    /// Return a **HEADLINE** font instance at specific zooming system.
    static func headline(_ transformer: UDZoom.Transformer) -> UIFont
    /// Return a **BODY0** font instance at specific zooming system.
    static func body0(_ transformer: UDZoom.Transformer) -> UIFont
    /// Return a **BODY1** font instance at specific zooming system.
    static func body1(_ transformer: UDZoom.Transformer) -> UIFont
    /// Return a **BODY2** font instance at specific zooming system.
    static func body2(_ transformer: UDZoom.Transformer) -> UIFont
    /// Return a **CAPTION0** font instance at specific zooming system.
    static func caption0(_ transformer: UDZoom.Transformer) -> UIFont
    /// Return a **CAPTION1** font instance at specific zooming system.
    static func caption1(_ transformer: UDZoom.Transformer) -> UIFont
    /// Return a **CAPTION2** font instance at specific zooming system.
    static func caption2(_ transformer: UDZoom.Transformer) -> UIFont
    /// Return a **CAPTION3** font instance at specific zooming system.
    static func caption3(_ transformer: UDZoom.Transformer) -> UIFont
}

/// UniverseDesign font with specified transformer.
public extension UDFontFamily {

    /// Return a **TITLE0** font instance at specific zooming system.
    static func title0(_ transformer: UDZoom.Transformer) -> UIFont {
        return UDFont.getTitle0(for: transformer.mapper(UDZoom.currentZoom))
    }

    /// Return a **TITLE1** font instance at specific zooming system.
    static func title1(_ transformer: UDZoom.Transformer) -> UIFont {
        return UDFont.getTitle1(for: transformer.mapper(UDZoom.currentZoom))
    }

    /// Return a **TITLE2** font instance at specific zooming system.
    static func title2(_ transformer: UDZoom.Transformer) -> UIFont {
        return UDFont.getTitle2(for: transformer.mapper(UDZoom.currentZoom))
    }

    /// Return a **TITLE3** font instance at specific zooming system.
    static func title3(_ transformer: UDZoom.Transformer) -> UIFont {
        return UDFont.getTitle3(for: transformer.mapper(UDZoom.currentZoom))
    }

    /// Return a **TITLE4** font instance at specific zooming system.
    static func title4(_ transformer: UDZoom.Transformer) -> UIFont {
        return UDFont.getTitle4(for: transformer.mapper(UDZoom.currentZoom))
    }

    /// Return a **HEADLINE** font instance at specific zooming system.
    static func headline(_ transformer: UDZoom.Transformer) -> UIFont {
        return UDFont.getHeadline(for: transformer.mapper(UDZoom.currentZoom))
    }

    /// Return a **BODY0** font instance at specific zooming system.
    static func body0(_ transformer: UDZoom.Transformer) -> UIFont {
        return UDFont.getBody0(for: transformer.mapper(UDZoom.currentZoom))
    }

    /// Return a **BODY1** font instance at specific zooming system.
    static func body1(_ transformer: UDZoom.Transformer) -> UIFont {
        return UDFont.getBody1(for: transformer.mapper(UDZoom.currentZoom))
    }

    /// Return a **BODY2** font instance at specific zooming system.
    static func body2(_ transformer: UDZoom.Transformer) -> UIFont {
        return UDFont.getBody2(for: transformer.mapper(UDZoom.currentZoom))
    }

    /// Return a **CAPTION0** font instance at specific zooming system.
    static func caption0(_ transformer: UDZoom.Transformer) -> UIFont {
        return UDFont.getCaption0(for: transformer.mapper(UDZoom.currentZoom))
    }

    /// Return a **CAPTION1** font instance at specific zooming system.
    static func caption1(_ transformer: UDZoom.Transformer) -> UIFont {
        return UDFont.getCaption1(for: transformer.mapper(UDZoom.currentZoom))
    }

    /// Return a **CAPTION2** font instance at specific zooming system.
    static func caption2(_ transformer: UDZoom.Transformer) -> UIFont {
        return UDFont.getCaption2(for: transformer.mapper(UDZoom.currentZoom))
    }

    /// Return a **CAPTION3** font instance at specific zooming system.
    static func caption3(_ transformer: UDZoom.Transformer) -> UIFont {
        return UDFont.getCaption3(for: transformer.mapper(UDZoom.currentZoom))
    }
}

/// UniverseDesign font with specified transformer.
public protocol UDFontFamilyDefault {

    /// Return a **TITLE0** font instance at specific zooming system.
    static var title0: UIFont { get }
    /// Return a **TITLE1** font instance at specific zooming system.
    static var title1: UIFont { get }
    /// Return a **TITLE2** font instance at specific zooming system.
    static var title2: UIFont { get }
    /// Return a **TITLE3** font instance at specific zooming system.
    static var title3: UIFont { get }
    /// Return a **TITLE4** font instance at specific zooming system.
    static var title4: UIFont { get }
    /// Return a **HEADLINE** font instance at specific zooming system.
    static var headline: UIFont { get }
    /// Return a **BODY0** font instance at specific zooming system.
    static var body0: UIFont { get }
    /// Return a **BODY1** font instance at specific zooming system.
    static var body1: UIFont { get }
    /// Return a **BODY2** font instance at specific zooming system.
    static var body2: UIFont { get }
    /// Return a **CAPTION0** font instance at specific zooming system.
    static var caption0: UIFont { get }
    /// Return a **CAPTION1** font instance at specific zooming system.
    static var caption1: UIFont { get }
    /// Return a **CAPTION2** font instance at specific zooming system.
    static var caption2: UIFont { get }
    /// Return a **CAPTION3** font instance at specific zooming system.
    static var caption3: UIFont { get }
}

public extension UDFontFamilyDefault where Self: UDFontFamily {
    /// *26pt*, *semibold* at normal level.
    static var title0: UIFont { return title0(.s6) }
    /// *24pt*, *semibold* at normal level.
    static var title1: UIFont { return title1(.s6) }
    /// *20pt*, *medium* at normal level.
    static var title2: UIFont { return title2(.s6) }
    /// *17pt*, *medium* at normal level.
    static var title3: UIFont { return title3(.s6) }
    /// *17pt*, *regular* at normal level.
    static var title4: UIFont { return title4(.s6) }
    /// *16pt*, *medium* at normal level.
    static var headline: UIFont { return headline(.s6) }
    /// *16pt*, *regular* at normal level.
    static var body0: UIFont { return body0(.s6) }
    /// *14pt*, *medium* at normal level.
    static var body1: UIFont { return body1(.s6) }
    /// *14pt*, *regular* at normal level.
    static var body2: UIFont { return body2(.s6) }
    /// *12pt*, *medium* at normal level.
    static var caption0: UIFont { return caption0(.s6) }
    /// *12pt*, *regular* at normal level.
    static var caption1: UIFont { return caption1(.s6) }
    /// *10pt*, *medium* at normal level.
    static var caption2: UIFont { return caption2(.s6) }
    /// *10pt*, *regular* at normal level.
    static var caption3: UIFont { return caption3(.s6) }
}

extension UDFont: UDFontFamily, UDFontFamilyDefault {

    /// DIN font with given size.
    public static func dinBoldFont(ofSize size: CGFloat) -> UIFont {
        guard let font = UIFont(name: "DINAlternate-Bold", size: size) else {
            return UIFont.systemFont(ofSize: size)
        }
        return font
    }
}

public extension UDComponentsExtension where BaseType == UIFont {
    /// DIN font with given size.
    static func dinBoldFont(ofSize size: CGFloat) -> UIFont {
        return UDFont.dinBoldFont(ofSize: size)
    }

    // convenience methods to create system fonts
    class func systemFont(ofSize fontSize: CGFloat) -> UIFont {
        return UDFont.systemFont(ofSize: fontSize)
    }

    // convenience methods to create system fonts
    class func boldSystemFont(ofSize fontSize: CGFloat) -> UIFont {
        return UDFont.boldSystemFont(ofSize: fontSize)
    }

    // convenience methods to create system fonts
    class func italicSystemFont(ofSize fontSize: CGFloat) -> UIFont {
        return UDFont.italicSystemFont(ofSize: fontSize)
    }

    // convenience methods to create system fonts
    class func systemFont(ofSize fontSize: CGFloat, weight: UIFont.Weight) -> UIFont {
        return UDFont.systemFont(ofSize: fontSize, weight: weight)
    }

    // convenience methods to change to mono digit
    static func monospacedDigitSystemFont(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
        return UDFont.systemFont(ofSize: size, weight: weight).withMonospacedNumbers()
    }

    static func registerFont(withFilenameString filenameString: String, bundle: Bundle) {
        guard let pathForResourceString = bundle.path(forResource: filenameString, ofType: nil) else {
            UDFont.tracker?.logger(component: .UDFont, loggerType: .error, msg: "registerFont Error: Invalid filenameString \(filenameString)")
            return
        }
        // lint:disable:next lark_storage_check - 从 Bundle 读取，不涉及加解密，无需接入统一存储
        guard let fontData = NSData(contentsOfFile: pathForResourceString) else {
            UDFont.tracker?.logger(component: .UDFont, loggerType: .error, msg: "registerFont Error: Failed to read file, pathForResourceString: \(pathForResourceString)")
            return
        }
        guard let dataProvider = CGDataProvider(data: fontData) else {
            UDFont.tracker?.logger(component: .UDFont, loggerType: .error, msg: "registerFont Error: Invalid data provider, fontData: \(fontData.description)")
            return
        }
        guard let font = CGFont(dataProvider) else {
            UDFont.tracker?.logger(component: .UDFont, loggerType: .error, msg: "registerFont Error: Invalid font data, font is inValid")
            return
        }
        var errorRef: Unmanaged<CFError>?
        if (CTFontManagerRegisterGraphicsFont(font, &errorRef) == false) {
            if let error = errorRef?.takeRetainedValue() {
                UDFont.tracker?.logger(component: .UDFont, loggerType: .error, msg: "registerFont errorRef: \(error)")
            } else {
                UDFont.tracker?.logger(component: .UDFont, loggerType: .error, msg: "registerFont errorRef is nil")
            }
        }
    }
}

extension UDComponentsExtension: UDFontFamily, UDFontFamilyDefault where BaseType == UIFont {
    /// Whether the font file is registered
    private static var isCustomFontRegistered = false

    static func customFont(ofSize size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont? {
        guard let customFontInfo = UDFontAppearance.customFontInfo else {
            isCustomFontRegistered = false
            return nil
        }

        if !isCustomFontRegistered {
            UIFont.ud.registerFont(withFilenameString: customFontInfo.regularFilePath, bundle: customFontInfo.bundle)
            UIFont.ud.registerFont(withFilenameString: customFontInfo.mediumFilePath, bundle: customFontInfo.bundle)
            UIFont.ud.registerFont(withFilenameString: customFontInfo.semiBoldFilePath, bundle: customFontInfo.bundle)
            UIFont.ud.registerFont(withFilenameString: customFontInfo.boldFilePath, bundle: customFontInfo.bundle)
            isCustomFontRegistered = true
        }

        guard let font = UIFont(name: customFontInfo.customFontName, size: size) else { return nil }

        // 临时修复方案，修复 pointSize 为 0 时，无法生效
        if size <= 0 {
            var minumFontSize: CGFloat = 0.01
            // pointSize 小于等于 0 为非法值，自定义字体兜底为 Helvetica 时，无法设置 pointSize 为 0。
            return font.withWeight(weight).withSize(minumFontSize)
        } else {
            return font.withWeight(weight)
        }
    }
}
