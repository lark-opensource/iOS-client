//
//  KeyboardStringTrimTool.swift
//  LarkKeyboardView
//
//  Created by liluobin on 2023/3/10.
//

import UIKit

public class KeyboardStringTrimTool {

    public static func trimTailString(text: String, set: CharacterSet) -> String {
        let invertedSet = set.inverted
        let range: NSRange = (text as NSString).rangeOfCharacter(from: invertedSet, options: .backwards)
        let location = 0
        let length = (range.length > 0 ? NSMaxRange(range) : text.count) - location
        let newText = (text as NSString).substring(with: NSRange(location: location, length: length))
        return newText
    }

    public static func trimTailAttributedString(attr: NSAttributedString, set: CharacterSet) -> NSAttributedString {
        let invertedSet = set.inverted
        let modifyAttributeText = NSMutableAttributedString(attributedString: attr)
        let range: NSRange = (attr.string as NSString).rangeOfCharacter(from: invertedSet, options: .backwards)

        let location = 0
        let length = (range.length > 0 ? NSMaxRange(range) : modifyAttributeText.string.count) - location
        let newText = modifyAttributeText.attributedSubstring(from: NSRange(location: location, length: length))
        return newText
    }
}
