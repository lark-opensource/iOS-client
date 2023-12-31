//
//  FontStyleConfig.swift
//  LarkRichTextCore
//
//  Created by liluobin on 2021/9/7.
//

import Foundation
import UIKit

public final class FontStyleConfig {
    public static let italicAttributedKey = NSAttributedString.Key(rawValue: "italic")
    public static let italicAttributedValue = "italic"
    public static let boldAttributedKey = NSAttributedString.Key(rawValue: "bold")
    public static let boldAttributedValue = "bold"
    public static let underlineAttributedKey = NSAttributedString.Key(rawValue: "underline")
    public static let underlineAttributedValue = NSNumber(value: NSUnderlineStyle.single.rawValue)
    public static let strikethroughAttributedKey = NSAttributedString.Key(rawValue: "strikethrough")
    public static let strikethroughAttributedValue = NSNumber(value: NSUnderlineStyle.single.rawValue)
    public static var underlineStyle: Int { NSUnderlineStyle.single.rawValue }
    public static var strikethroughStyle: Int { 1 }

    public static var fontStyleKeys: [NSAttributedString.Key] {
        return [italicAttributedKey, boldAttributedKey, FontStyleConfig.underlineAttributedKey, FontStyleConfig.strikethroughAttributedKey]
    }
}

public final class AIFontStyleConfig {
    public static var smartCorrectAttribuedKey = NSAttributedString.Key(rawValue: "smartCorrect")
    public static var smartCorrectAttribuedValue = NSNumber(value: NSUnderlineStyle.thick.rawValue)

    public static var lingoHighlightAttributedKey = NSAttributedString.Key(rawValue: "lingoHighlight")
    public static var lingoHighlightAttributedValue = NSNumber(value: NSUnderlineStyle.single.rawValue | NSUnderlineStyle.patternDot.rawValue)
}
