//
//  UIFont+Calendar.swift
//  Calendar
//
//  Created by zhuchao on 2017/12/28.
//  Copyright © 2017年 EE. All rights reserved.
//

import UIKit
import UniverseDesignFont
extension UIFont: CalendarExtensionCompatible {
    public func sizeOfString(string: String,
                      lineBreakMode: NSLineBreakMode,
                      constrainedToWidth width: Double) -> CGSize {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = lineBreakMode
        let attributes = [NSAttributedString.Key.font: self,
                          NSAttributedString.Key.paragraphStyle: paragraphStyle]
        let attString = NSAttributedString(string: string, attributes: attributes)
        let framesetter = CTFramesetterCreateWithAttributedString(attString)
        return CTFramesetterSuggestFrameSizeWithConstraints(
            framesetter,
            CFRange(location: 0, length: 0),
            nil,
            CGSize(width: width, height: .greatestFiniteMagnitude),
            nil
        )
    }
}

extension CalendarExtension where BaseType == UIFont {
    public static func regularFont(ofSize size: CGFloat) -> UIFont {
        return UDFont.systemFont(ofSize: size)
    }

    public static func mediumFont(ofSize size: CGFloat) -> UIFont {
        return UDFont.systemFont(ofSize: size, weight: .medium)
    }

    public static func semiboldFont(ofSize size: CGFloat) -> UIFont {
        return UDFont.systemFont(ofSize: size, weight: .semibold)
    }

    public static func dinBoldFont(ofSize size: CGFloat,
                                   replacedSize: CGFloat? = nil) -> UIFont {
        let targetSize: CGFloat
        if UDFontAppearance.isCustomFont, let replacedSize = replacedSize {
            targetSize = replacedSize
        } else {
            targetSize = size
        }
        // 西文字体开关
        if UDFontAppearance.isCustomFont {
            let monospacedDigitSystemFont = monospacedDigitMediumFont(ofSize: targetSize)
            return monospacedDigitSystemFont
        }
        guard let font = UIFont(name: "DINAlternate-Bold", size: targetSize) else {
            assertionFailureLog()
            return UIFont.systemFont(ofSize: targetSize)
        }
        return font
    }

    // 等宽circular字体
    public static func monospacedDigitMediumFont(ofSize size: CGFloat) -> UIFont {
        UDFont.monospacedDigitSystemFont(ofSize: size, weight: .medium)
    }

    public static func font(ofSize size: CGFloat) -> UIFont {
        return regularFont(ofSize: size)
    }
}
