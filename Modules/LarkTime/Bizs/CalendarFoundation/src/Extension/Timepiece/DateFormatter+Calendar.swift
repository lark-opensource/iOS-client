//
//  DateFormatter+Calendar.swift
//  Calendar
//
//  Created by jiayi zou on 2018/3/15.
//  Copyright © 2018年 EE. All rights reserved.
//

import Foundation
import LarkLocalizations

extension DateFormatter {
  public func setCurrentLocale() {
        self.locale = currentLocale()
    }

    public static func calendarFormatter(with dateFormat: String,
                                  isFor12Hour: Bool,
                                  removeSymbol: Bool = false) -> DateFormatter {
        var identifier = LanguageManager.currentLanguage.localeIdentifier
        if !LanguageManager.supportLanguages.contains(LanguageManager.currentLanguage) {
            identifier = Lang.en_US.localeIdentifier
        }
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        formatter.locale = Locale(identifier: identifier)

        let twentyFourFormat = BundleI18n.Calendar.Calendar_StandardTime_TwentyFourHourWithMinute
        if !isFor12Hour { return formatter }
        if !dateFormat.contains(twentyFourFormat) { return formatter }

        let dateFormatString = removeSymbol ? BundleI18n.Calendar.Calendar_StandardTime_TwelveHourMinuteFormatWithoutMeridiemIndicator : BundleI18n.Calendar.Calendar_StandardTime_TwelveHourMinuteFormatWithMeridiemIndicator
        formatter.dateFormat = dateFormat.replacingOccurrences(of: twentyFourFormat, with: dateFormatString)
        return formatter
    }
}

extension NumberFormatter {
  public func setCurrentLocale() {
        self.locale = currentLocale()
    }
}

private func currentLocale() -> Locale {
    let locale = Locale(identifier: LanguageManager.currentLanguage.localeIdentifier)
    return locale
}

extension Date {
  public func string(with dateFormat: String,
                isFor12Hour: Bool = false,
                trimTailingZeros: Bool = false,
                tailingClock: String? = nil,
                removeSymbol: Bool = false,
                closure: ((DateFormatter) -> Void)? = nil) -> String {
        let format = trimTailingZeros ? BundleI18n.Calendar.Calendar_StandardTime_TwelveHourOnTheHourWithMeridiemIndicator : dateFormat
        let formatter = DateFormatter.calendarFormatter(with: dateFormat,
                                                        isFor12Hour: isFor12Hour,
                                                        removeSymbol: removeSymbol)
        closure?(formatter)
        return formatter.string(from: self)
    }
}
