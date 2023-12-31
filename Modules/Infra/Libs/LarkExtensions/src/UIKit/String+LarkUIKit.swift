//
//  String+LarkUIKit.swift
//  LarkUIKit
//
//  Created by zhuchao on 2017/3/22.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import LarkCompatible
import UniverseDesignColor
import UniverseDesignTheme

extension String: LarkUIKitExtensionCompatible {}

public extension LarkUIKitExtension where BaseType == String {
    func stringWithHighlight(
        highlightText: String,
        pinyinOfString: String? = nil,
        highlightColor: UIColor = UIColor.ud.colorfulBlue,
        normalColor: UIColor = UIColor.ud.staticBlack) -> NSMutableAttributedString {
        let lowerStr = self.base.lowercased()
        let lowerHighlightText = highlightText.lowercased()
        let resultAttr = NSMutableAttributedString(
            string: self.base,
            attributes: [NSAttributedString.Key.foregroundColor: normalColor]
        )
        let pinyin = pinyinOfString ?? lowerStr.lf.transformToPinyin()

        let results = PinYinMatcher.fullMatch(in: lowerStr, of: lowerHighlightText, extra: ["pinyin": pinyin])
        results.forEach { arg in
            let (_, range) = arg
            resultAttr.addAttribute(
                NSAttributedString.Key.foregroundColor,
                value: highlightColor,
                range: lowerStr.lf.rangeToNSRange(from: range))
        }

        return resultAttr
    }

    func width(font: UIFont, height: CGFloat = 15) -> CGFloat {
        let rect = NSString(string: self.base).boundingRect(
            with: CGSize(width: CGFloat(MAXFLOAT), height: height),
            options: .usesLineFragmentOrigin,
            attributes: [NSAttributedString.Key.font: font], context: nil)
        return ceil(rect.width)
    }

    func height(font: UIFont, width: CGFloat) -> CGFloat {
        let rect = NSString(string: self.base).boundingRect(
            with: CGSize(width: width, height: CGFloat(MAXFLOAT)),
            options: .usesLineFragmentOrigin,
            attributes: [NSAttributedString.Key.font: font], context: nil)
        return ceil(rect.height)
    }

    func height(font: UIFont, width: CGFloat, maxHeight: CGFloat) -> CGFloat {
        let rect = NSString(string: self.base).boundingRect(
            with: CGSize(width: width, height: CGFloat(MAXFLOAT)),
            options: .usesLineFragmentOrigin,
            attributes: [NSAttributedString.Key.font: font], context: nil)
        return ceil(rect.height) > maxHeight ? maxHeight : ceil(rect.height)
    }

    func transformToExecutableScript() -> String {
        var script = self.base.trimmingCharacters(in: .newlines)

        // NOTE: 亲测 newlines 无法去掉以下的换行符
        let NSNewLineCharacter = "\u{000a}"
        let NSLineSeparatorCharacter = "\u{2028}"
        let NSParagraphSeparatorCharacter = "\u{2029}"
        script = script.replacingOccurrences(of: NSNewLineCharacter, with: "")
        script = script.replacingOccurrences(of: NSLineSeparatorCharacter, with: "")
        script = script.replacingOccurrences(of: NSParagraphSeparatorCharacter, with: "")
        return script
    }
}
