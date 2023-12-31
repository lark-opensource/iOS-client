//
//  LKLabel+LarkUIKit.swift
//  LarkUIKit
//
//  Created by chengzhipeng-bytedance on 2018/3/19.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import UIKit
import Foundation
import LarkCompatible
import UniverseDesignColor
import UniverseDesignTheme

public let DataCheckDetector = try? NSDataDetector(
    types: NSTextCheckingResult.CheckingType.link.rawValue
        + NSTextCheckingResult.CheckingType.phoneNumber.rawValue
)

public let NumberCheckDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.phoneNumber.rawValue)

extension LarkUIKitExtension where BaseType == LKLabel {
    @discardableResult
    public func setProps(fontSize: CGFloat = 12, numberOfLine: Int = 0, textColor: UIColor = UIColor.ud.N900) -> BaseType {
        let label = self.base
        label.font = UIFont.systemFont(ofSize: fontSize)
        label.numberOfLines = numberOfLine
        label.textColor = textColor
        label.textAlignment = .left
        label.backgroundColor = UIColor.clear
        label.lineBreakMode = .byWordWrapping
        label.isUserInteractionEnabled = true

        label.textCheckingDetecotor = NumberCheckDetector

        label.translatesAutoresizingMaskIntoConstraints = false

        label.linkAttributes = [
            NSAttributedString.Key(rawValue: kCTForegroundColorAttributeName as String): UIColor.ud.colorfulBlue.cgColor
        ]
        label.activeLinkAttributes = [
            LKBackgroundColorAttributeName: UIColor(white: 0, alpha: 0.1)
        ]

        return label
    }

    @discardableResult
    public func setProps(boldFontSize: CGFloat = 12,
                  numberOfLine: Int = 0,
                  textColor: UIColor = UIColor.ud.N900) -> BaseType {
        self.setProps(fontSize: boldFontSize, numberOfLine: numberOfLine, textColor: textColor)
        self.base.font = UIFont.systemFont(ofSize: boldFontSize, weight: .medium)
        return self.base
    }

    public class func basicAttribute(
        foregroundColor: UIColor,
        atMeBackground: UIColor? = nil,
        lineSpacing: CGFloat = 2,
        font: UIFont = UIFont.systemFont(ofSize: 16),
        lineBreakMode: NSLineBreakMode = .byWordWrapping
        ) -> [NSAttributedString.Key: Any] {
        var attributes: [NSAttributedString.Key: Any] = [:]

        if atMeBackground != nil {
            attributes[LKAtAttributeName] = atMeBackground!
        }

        attributes[.foregroundColor] = foregroundColor
        attributes[.font] = font

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .natural
        paragraphStyle.lineSpacing = lineSpacing
        paragraphStyle.lineBreakMode = lineBreakMode
        paragraphStyle.lineHeightMultiple = 0
        paragraphStyle.maximumLineHeight = 0
        paragraphStyle.minimumLineHeight = font.pointSize + 2

        attributes[.paragraphStyle] = paragraphStyle
        return attributes
    }

    public class func genAtMeAttributedText(
        atMeAttrStr: NSAttributedString,
        bgColor: UIColor
    ) -> NSAttributedString {
        let ctline = CTLineCreateWithAttributedString(atMeAttrStr)
        let runDelegate = LKTextRun.createCTRunDelegate(
            LKTextLine.getLineDetail(line: ctline),
            dealloc: { (pointer) in
                pointer.deallocate()
            },
            getAscent: { (pointer) -> CGFloat in
                return pointer.assumingMemoryBound(to: LKLineDetail.self).pointee.ascent + 1
            },
            getDescent: { (pointer) -> CGFloat in
                return pointer.assumingMemoryBound(to: LKLineDetail.self).pointee.descent + 1
            },
            getWidth: { (pointer) -> CGFloat in
                let lineDetail = pointer.assumingMemoryBound(to: LKLineDetail.self).pointee
                return lineDetail.width + (lineDetail.ascent + lineDetail.descent) / 2
            }
        )
        let attrStr = NSAttributedString(
            string: LKLabelAttachmentPlaceHolderStr,
            attributes: [
                CTRunDelegateAttributeName: runDelegate,
                LKAtBackgroungColorAttributeName: bgColor,
                LKAtStrAttributeName: atMeAttrStr
            ]
        )
        return attrStr
    }

    public class func genOutOfRangeText(
        foregroundColor: UIColor = UIColor.ud.colorfulBlue,
        font: UIFont = UIFont.systemFont(ofSize: 14),
        text: String
    ) -> NSAttributedString {
        return NSAttributedString(
            string: text,
            attributes: [
                .foregroundColor: foregroundColor,
                .font: font
            ]
        )
    }
}
