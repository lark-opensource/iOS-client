//
//  String+Calendar.swift
//  Calendar
//
//  Created by jiayi zou on 2018/5/29.
//  Copyright © 2018年 EE. All rights reserved.
//

import UIKit
import Foundation
import LarkTimeFormatUtils
import UniverseDesignColor
import UniverseDesignTheme
import UniverseDesignFont

public func getTimeString(startDateTS: Int64,
                   endDateTS: Int64,
                   isAllDayEvent: Bool,
                   isInOneLine: Bool = false,
                   is12HourStyle: Bool) -> String {
    return getTimeString(startDate: Date(timeIntervalSince1970: TimeInterval(startDateTS)),
                         endDate: Date(timeIntervalSince1970: TimeInterval(endDateTS)),
                         isAllDayEvent: isAllDayEvent,
                         isInOneLine: isInOneLine,
                         is12HourStyle: is12HourStyle)
}

public func getTimeDescription(startDate: Date,
                               endDate: Date,
                               isAllDayEvent: Bool,
                               isInOneLine: Bool = false,
                               is12HourStyle: Bool) -> String {
    // 使用设备时区
    let customOptions = Options(
        timeZone: TimeZone.current,
        is12HourStyle: is12HourStyle,
        timePrecisionType: .minute,
        datePrecisionType: .day,
        dateStatusType: .absolute,
        shouldRemoveTrailingZeros: false
    )
    return CalendarTimeFormatter.formatFullDateTimeRange(
        startFrom: startDate,
        endAt: endDate,
        isAllDayEvent: isAllDayEvent,
        shouldTextInOneLine: isInOneLine,
        with: customOptions
    )
}

public func getTimeString(startDate: Date,
                   endDate: Date,
                   isAllDayEvent: Bool,
                   isInOneLine: Bool = false,
                   is12HourStyle: Bool) -> String {
    return getTimeDescription(startDate: startDate,
                              endDate: endDate,
                              isAllDayEvent: isAllDayEvent,
                              isInOneLine: isInOneLine,
                              is12HourStyle: is12HourStyle)
}

extension String {
    private static let monthNumberRegex = try? NSRegularExpression(pattern: "\\d+")

    public func attributedMonthString() -> NSAttributedString {
        let font = UDFontAppearance.isCustomFont ? UIFont.cd.monospacedDigitMediumFont(ofSize: 20) : UIFont.cd.semiboldFont(ofSize: 24)
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.ud.N900,
            .font: font]
        let result = NSMutableAttributedString(string: self, attributes: attributes)
        guard let regex = String.monthNumberRegex else { return result }
        let matches = regex.matches(in: self, range: NSRange(self.startIndex..., in: self))
        guard !matches.isEmpty else { return result }
        let numberfont = UIFont.cd.dinBoldFont(ofSize: 24, replacedSize: 20)
        matches.forEach { (match) in
            result.addAttribute(.font, value: numberfont, range: match.range)
        }
        return result
    }

    public func width(with font: UIFont) -> CGFloat {
        let rect = (self as NSString).boundingRect(
            with: CGSize(width: CGFloat(MAXFLOAT), height: font.pointSize + 10),
            options: .usesLineFragmentOrigin,
            attributes: [NSAttributedString.Key.font: font], context: nil)
        return ceil(rect.width)
    }

    public func attributedText(with font: UIFont,
                        color: UIColor,
                        hasStrikethrough: Bool = false,
                        strikethroughColor: UIColor = UIColor.ud.N500,
                        lineBreakMode: NSLineBreakMode = .byTruncatingTail) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = lineBreakMode
        paragraphStyle.maximumLineHeight = font.lineHeight
        var attributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle: paragraphStyle,
            .foregroundColor: color,
            .font: font]
        if hasStrikethrough {
            attributes[.strikethroughStyle] = NSNumber(value: 1) as Any
            attributes[.strikethroughColor] = strikethroughColor as Any
        }
        return NSAttributedString(string: self, attributes: attributes)
    }

    public func isEmailAddress() -> Bool {
        let emailRegex = #"^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF]+\.)+[a-zA-Z\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF]{2,}))$"#
        let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailTest.evaluate(with: self)
    }

    public func decodeHtml() -> String {
        let characters = [
                   "&amp;": "&",
                   "&#38;": "&",
                   "&lt;": "<",
                   "&#60;": "<",
                   "&gt;": ">",
                   "&#62;": ">",
                   "&quot;": "\"",
                   "&#34;": "\"",
                   "&apos;": "'",
                   "&#39;": "'",
                   "&#x27;": "\'",
                   "&#x2F;": "/",
                   "&nbsp;": " ",
                   "&#160;": " "
               ]
       var str = self
       for (escaped, unescaped) in characters {
           str = str.replacingOccurrences(of: escaped, with: unescaped, options: NSString.CompareOptions.literal, range: nil)
       }
       return str
    }
}

extension Optional where Wrapped == String {

    // 字符串非空，nil值返回false
    public var isNotEmpty: Bool {
        return !isEmpty
    }

    // nil值返回true
    public var isEmpty: Bool {
        switch self {
        case .none: return true
        case let .some(value): return value.isEmpty
        }
    }
}
