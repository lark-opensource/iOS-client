//
//  CATimeFormatterUI.swift
//  Calendar
//
//  Created by jiayi zou on 2018/11/6.
//  Copyright © 2018 EE. All rights reserved.
//

import UIKit
import Foundation
import CalendarFoundation
import LarkTimeFormatUtils

final class CATimeFormatterLabel: CopyableLabel {
    private var originTimeString = ""
    private var showTimeString = "" {
        didSet {
            let paraph = NSMutableParagraphStyle()
            paraph.lineSpacing = 4
            let attributes = [NSAttributedString.Key.paragraphStyle: paraph]
            self.attributedText = NSAttributedString(string: showTimeString,
                                                     attributes: attributes)
        }
    }

    func setTimeString(startTime: Date,
                       endTime: Date,
                       isAllday: Bool,
                       is12HourStyle: Bool) {
        // 使用设备时区
        let customOptions = Options(
            timeZone: TimeZone.current,
            is12HourStyle: is12HourStyle,
            timePrecisionType: .minute,
            datePrecisionType: .day,
            dateStatusType: .absolute,
            shouldRemoveTrailingZeros: false
        )

        originTimeString = CalendarTimeFormatter.formatFullDateTimeRange(
            startFrom: startTime,
            endAt: endTime,
            isAllDayEvent: isAllday,
            with: customOptions
        )
        self.showTimeString = originTimeString
        self.layoutIfNeeded()
    }

    init(isOneLine: Bool, isCopyable: Bool = false, didShowCopy: (() -> Void)? = nil) {
        super.init(isCopyable: isCopyable, didShowCopy: didShowCopy)
        if isOneLine {
            self.numberOfLines = 1
            self.lineBreakMode = .byTruncatingTail
        } else {
            self.numberOfLines = 0
            self.lineBreakMode = .byWordWrapping
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard self.frame.width > 0 else {
            return
        }
        let newText = wrappingBySpace(labelLength: intrinsicContentSize.width)
        if self.showTimeString != newText {
            self.showTimeString = newText
        }
    }

    private func wrappingBySpace(labelLength: CGFloat) -> String {
        func widthAfterNewString(originalWidth: CGFloat,
                                 newString: String) -> CGFloat {
            let attributes = [NSAttributedString.Key.font: self.font]
            let newStringWidth = (newString as NSString).size(withAttributes: attributes as [NSAttributedString.Key: Any]).width
            return originalWidth + newStringWidth
        }

        let subStrings = self.originTimeString.split(separator: " ")
        var newText = ""
        var newLineText = ""
        var newLineWidth: CGFloat = 0
        for subString in subStrings {
            var sub = String(subString)
            if newLineText.isEmpty {
                // 新一行直接加，避免出现空行
                if sub.first == "\n" {
                    sub.removeFirst()
                }
                newLineText += sub
                if sub.last == "\n" {
                    // 后面不用加词了，直接break即可
                    newText += newLineText
                    newLineText = ""
                    newLineWidth = 0
                } else {
                    newLineWidth = widthAfterNewString(originalWidth: 0, newString: newLineText)
                }
            } else {
                let subWithSpace = " " + sub
                if widthAfterNewString(originalWidth: newLineWidth, newString: subWithSpace) > labelLength || sub.first == "\n" {
                    // 不能加了，加了就爆了
                    newLineText += "\n"
                    newText += newLineText
                    if sub.first == "\n" {
                        sub.removeFirst()
                    }
                    newLineText = sub
                    newLineWidth = widthAfterNewString(originalWidth: 0, newString: sub)
                } else {
                    // 还能加，继续加
                    if sub.last == "\n" {
                        // 后面不用加词了
                        newLineText += subWithSpace
                        newText += newLineText
                        newLineText = ""
                        newLineWidth = 0
                    } else {
                        newLineText += subWithSpace
                        newLineWidth = widthAfterNewString(originalWidth: 0, newString: newLineText)
                    }
                }
            }
        }
        newText += newLineText
        return newText
    }
}
