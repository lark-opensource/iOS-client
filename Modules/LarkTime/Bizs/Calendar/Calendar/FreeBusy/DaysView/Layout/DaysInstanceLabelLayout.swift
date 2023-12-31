//
//  DaysInstanceLabelLayout.swift
//  Calendar
//
//  Created by zhouyuan on 2019/1/14.
//  Copyright © 2019 EE. All rights reserved.
//

import UIKit
import Foundation
import CalendarFoundation

struct LabelStyle {
    let attributedText: NSAttributedString?
    let frame: CGRect
}

final class DaysInstanceLabelLayout {

    private let titleFont = UIFont.cd.mediumFont(ofSize: 14)
    private let subTitleFont = UIFont.cd.regularFont(ofSize: 12)

    /// 会议室、地点的显示最小宽度，小于这个不显示  AllDayEventLabel 需要同步更改
    private let subTitleMinWidth: CGFloat = 100.0

    let clippingParagraphStyle: (_ font: UIFont) -> NSMutableParagraphStyle = {
        return { (font) in
            return DaysInstanceLabelLayout.paragraphStyle(font, .byClipping)
        }
    }()

    let wordWrappingParagraphStyle: (_ font: UIFont) -> NSMutableParagraphStyle = {
        return { (font) in
            return DaysInstanceLabelLayout.paragraphStyle(font, .byWordWrapping)
        }
    }()

    static let paragraphStyle: (UIFont, NSLineBreakMode) -> NSMutableParagraphStyle = {
        return { (font, lineBreakMode)  in
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.maximumLineHeight = font.lineHeight
            paragraphStyle.lineBreakMode = lineBreakMode
            return paragraphStyle
        }
    }()

    func getLabelStyle(frame: CGRect,
                       content: DaysInstanceViewContent) -> (LabelStyle, LabelStyle?) {
        let textColor = content.hasStrikethrough ? UIColor.ud.textPlaceholder : content.foregroundColor
        let titleAttributedText = content.titleText.attributedText(
            with: titleFont,
            color: textColor,
            hasStrikethrough: content.hasStrikethrough,
            lineBreakMode: .byWordWrapping
        )
        let subTitleText = content.locationText ?? ""
        let subTitleAttributedText = subTitleText.attributedText(
            with: subTitleFont,
            color: textColor,
            hasStrikethrough: content.hasStrikethrough,
            lineBreakMode: .byWordWrapping
        )

        return calculationLabelStyle(
            frame: frame,
            titleAttributedText: titleAttributedText,
            subTitleAttributedText: subTitleAttributedText
        )
    }

    private func calculationLabelStyle(
        frame: CGRect,
        titleAttributedText: NSAttributedString,
        subTitleAttributedText: NSAttributedString) -> (LabelStyle, LabelStyle?) {

        let padding: CGFloat = 6.0
        let textWidth = frame.width - padding * 2 // 左右间距6
        let title = NSAttributedString(attributedString: titleAttributedText)
        let titleSize = title.cd.sizeOfString(constrainedToWidth: textWidth)
        let titleHeight = titleSize.height

        let subTitle = NSAttributedString(attributedString: subTitleAttributedText)
        let subTitleHeight = subTitle.cd.sizeOfString(constrainedToWidth: textWidth).height
        var titleFrame = CGRect.zero
        var subTitleFrame = CGRect.zero
        titleFrame.origin = CGPoint(x: padding, y: 3)
        let titleFontHeight = titleFont.lineHeight
        let subTitleFontHeight = subTitleFont.lineHeight

        let titleAttr = NSMutableAttributedString(attributedString: titleAttributedText)
        let subtitleAttr = NSMutableAttributedString(attributedString: subTitleAttributedText)

        /// 只能显示一行
        if frame.height < 42.5 {
            /// 只有一行则右间距为 0
            titleFrame.size = CGSize(width: textWidth + padding, height: titleSize.height)
            titleAttr.addAttribute(
                NSAttributedString.Key.paragraphStyle,
                value: clippingParagraphStyle(titleFont),
                range: NSRange(location: 0, length: titleAttributedText.string.count)
            )
            var subTitleStyle: LabelStyle?
            if textWidth - titleSize.width > subTitleMinWidth {
                titleFrame.size = CGSize(width: titleSize.width, height: titleSize.height)
                subtitleAttr.addAttribute(
                    NSAttributedString.Key.paragraphStyle,
                    value: clippingParagraphStyle(subTitleFont),
                    range: NSRange(location: 0, length: subTitleAttributedText.string.count)
                )
                subTitleFrame.origin = CGPoint(x: titleFrame.maxX + padding,
                                               y: titleFrame.minY + 1.4)
                subTitleFrame.size = CGSize(width: textWidth - titleSize.width,
                                            height: subTitleFontHeight)
                subTitleStyle = LabelStyle(attributedText: subtitleAttr, frame: subTitleFrame)
            }
            return (LabelStyle(attributedText: titleAttr, frame: titleFrame), subTitleStyle)
        }

        // title 不能完全显示
        if frame.height - subTitleHeight - 6 < 5 + titleHeight {
            let minTitleHeight = max(frame.height - subTitleHeight - 6, titleFontHeight)
            let titleLineCount = Int(minTitleHeight / titleFontHeight)
            titleFrame.size = CGSize(
                width: textWidth + padding,
                height: CGFloat(titleLineCount) * titleFontHeight
            )

            let titleParagraphStyle = titleLineCount == 1 ?
                clippingParagraphStyle(titleFont) : wordWrappingParagraphStyle(titleFont)
            titleAttr.addAttribute(
                NSAttributedString.Key.paragraphStyle,
                value: titleParagraphStyle,
                range: NSRange(location: 0, length: titleAttributedText.string.count)
            )

            subTitleFrame.origin = CGPoint(
                x: padding,
                y: titleFrame.maxY + 2.0
            )

            let subTitleShowHeight = frame.height - minTitleHeight - 6
            let subTitleLineCount = Int(subTitleShowHeight / subTitleFontHeight)
            let rightPadding = subTitleLineCount > 1 ? 0.0 : padding
            subTitleFrame.size = CGSize(width: textWidth + rightPadding,
                                        height: subTitleShowHeight)

            let subTitleParagraphStyle = subTitleLineCount == 1 ?
                clippingParagraphStyle(subTitleFont) : wordWrappingParagraphStyle(subTitleFont)
            subtitleAttr.addAttribute(
                NSAttributedString.Key.paragraphStyle,
                value: subTitleParagraphStyle,
                range: NSRange(location: 0, length: subtitleAttr.string.count)
            )
            return (LabelStyle(attributedText: titleAttr, frame: titleFrame),
                    LabelStyle(attributedText: subtitleAttr, frame: subTitleFrame))
        }

        // title 和 subTile 都能完全显示
        titleAttr.addAttribute(
            NSAttributedString.Key.paragraphStyle,
            value: wordWrappingParagraphStyle(titleFont),
            range: NSRange(location: 0, length: titleAttr.string.count)
        )
        subtitleAttr.addAttribute(
            NSAttributedString.Key.paragraphStyle,
            value: wordWrappingParagraphStyle(subTitleFont),
            range: NSRange(location: 0, length: subtitleAttr.string.count)
        )
        titleFrame.size = CGSize(width: textWidth,
                                 height: titleHeight)
        subTitleFrame.origin = CGPoint(x: padding, y: titleFrame.maxY)
        subTitleFrame.size = CGSize(width: textWidth,
                                    height: subTitleHeight)
        return (LabelStyle(attributedText: titleAttr, frame: titleFrame),
                LabelStyle(attributedText: subtitleAttr, frame: subTitleFrame))
    }
}
