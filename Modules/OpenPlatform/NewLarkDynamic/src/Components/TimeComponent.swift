//
//  LDTimeComponent.swift
//  NewLarkDynamic
//
//  Created by qihongye on 2019/6/23.
//

import Foundation
import AsyncComponent
import LarkModel
import ECOInfra
import LKCommonsLogging
import WidgetKit
import UniverseDesignColor
import LarkFeatureGating
import LarkSetting

fileprivate struct FormatFixSettingKey: Codable {
    var fixTimeStyle:[String:[String:String]]
}

internal let messsageCardOutOfRangeText = "\u{2026}"

class LDTimeComponentFactory: ComponentFactory {
    override var tag: RichTextElement.Tag {
        return .time
    }

    lazy var moment = Moment()

    override func create<C: LDContext>(
        richtext: RichText,
        element: RichTextElement,
        elementId: String,
        children: [RichTextElement],
        style: LDStyle,
        context: C?,
        translateLocale: Locale? = nil) -> ComponentWithSubContext<C, C> {
        guard element.property.time.hasFormatType else {
            let props = RichLabelProps()
            moment.date = Date(timeIntervalSince1970: TimeInterval(element.property.time.millisecondSince1970 / 1000))
            moment.locale = context?.locale ?? .en_US
            props.font = style.font
            var textColor = (style.getColor() ?? (UIColor.ud.N900 & UIColor.ud.rgb(0xF0F0F0))).withContext(context: context)
            let attrbuties = attributedBuilder(style: style,
                                               lineBreakMode: .byWordWrapping,
                                               context: context,
                                               textColorCustom: textColor)
            var text = moment.format(element.property.time.format)
            props.attributedText = NSAttributedString(string: text, attributes: attrbuties)
            props.outOfRangeText = NSAttributedString(string: messsageCardOutOfRangeText, attributes: attrbuties)
            props.key = context?.getCopyabelComponentKey()
            return TextComponent<C>(props: props, style: style, context: context)
        }
        var content = getFormatTime(formatType: element.property.time.formatType,
                                                           timestamp: element.property.time.millisecondSince1970,
                                                           translateLocale: translateLocale,
                                                           context: context) ?? ""
        let props = AnchorComponentProps(context: context)
        let contentLength = NSString(string: content).length
        var textColor = (style.getColor() ?? (UIColor.ud.N900 & UIColor.ud.rgb(0xF0F0F0))).withContext(context: context)
        if element.property.time.hasLink,
           let url = URL(string: element.property.time.link) {
                props.rangeLinkMap = [NSRange(location: 0, length: contentLength): url]
                textColor = UIColor.ud.textLinkNormal.withContext(context: context)
        }
        style.color = textColor
        style.underlineColor = (style.getUnderlineColor() ?? textColor).withContext(context: context)
        style.strikethroughColor = (style.getStrikethroughColor() ?? textColor).withContext(context: context)
        /// 开放平台 非 Office 场景，暂时逃逸
        // swiftlint:disable ban_linebreak_byChar
        let attrbuties = attributedBuilder(style: style, lineBreakMode: .byCharWrapping, context: context)
        // swiftlint:enable ban_linebreak_byChar
        props.attributedText = NSAttributedString(string: content, attributes: attrbuties)
        props.outOfRangeText = NSAttributedString(string: messsageCardOutOfRangeText, attributes: attrbuties)
        props.textColor = textColor
        props.content = content
        props.font = style.font
        props.key = context?.getCopyabelComponentKey()
        return AnchorComponent2<C>(props: props, style: style, context: context)

    }
}

class Moment {
    private let formatter = DateFormatter()
    private let gmtPlaceHolder = "\u{FFFF}"

    var date: Date
    var locale: Locale
    init(timeSince1970: TimeInterval = Date().timeIntervalSince1970, locale: Locale = Locale.current) {
        self.date = Date(timeIntervalSince1970: timeSince1970)
        self.locale = locale
    }

    func locale(_ locale: Locale) -> Self {
        self.locale = locale
        return self
    }

    func format(_ formatStr: String) -> String {
        self.formatter.dateFormat = translateFormatStr(formatStr: formatStr)
        self.formatter.locale = self.locale
        self.formatter.timeZone = TimeZone.current
        let n: Int = self.formatter.timeZone.secondsFromGMT() / 3_600
        return self.formatter.string(from: self.date)
            .replacingOccurrences(of: gmtPlaceHolder, with: "GMT\(n >= 0 ? "+" : "-")\(n)")
    }

    private func translateFormatStr(formatStr: String) -> String {
        var dateFormat = formatStr
        if let range = formatStr.range(of: "GMT") {
            dateFormat.replaceSubrange(range, with: self.gmtPlaceHolder)
        }
        for label in ["DDDD", "DDD", "DD", "D"] {
            if let range = formatStr.range(of: label) {
                dateFormat.replaceSubrange(range, with: label.lowercased())
                break
            }
        }
        for label in ["dddd", "ddd", "dd", "d"] where dateFormat.contains(label) {
            if let range = formatStr.range(of: label) {
                dateFormat.replaceSubrange(range, with: String(repeating: "E", count: label.count))
                break
            }
        }
        return dateFormat
    }
}

class TimeComponentSettingHelper {

    struct MessagecardTimeFormatI18nConfig: Codable {
        var localeLanguageFormatPc: [String:[String:String]]
        var localeLanguageFormatMobile: [String:[String:String]]
        var translateFormatPc: [String:[String:String]]
        var translateFormatMobile: [String:[String:String]]
    }

    @Setting(key: UserSettingKey.make(userKeyLiteral: "messagecard_time_format_i18n_config"))
   static var timeSettings: MessagecardTimeFormatI18nConfig?

   static let defaultSettings = ["date_num": "yyyy-MM-dd",
                           "date_short": "MMM d",
                           "date": "MMM d, yyyy",
                           "week": "EEEE",
                           "week_short": "EEE",
                           "time_12": "h:mm a",
                           "time": "HH:mm",
                           "time_sec_12": "h:mm:ss a",
                           "time_sec": "HH:mm:ss",
                           "timezone": "\'GMT\'ZZZZZ"]

    //使用setting获取format
    static func getFormat(isTranslate: Bool, originFormatType: String, language: String, is24HourTime: Bool) -> String? {
        let type  = convertTo12HourFormatType( originFormat: originFormatType, is24HourTime: is24HourTime)
        var formatSetting = isTranslate ? timeSettings?.translateFormatMobile: timeSettings?.localeLanguageFormatMobile

        guard let formatTypes = formatSetting?[language] else {
            cardlog.error("get setting failed, isTranslate: \(isTranslate) originFormatType:\(originFormatType) language: \(language) is24HourTime:\(is24HourTime)")
            return defaultSettings[type] ?? defaultSettings[originFormatType]
        }
            return formatTypes[type] ?? formatTypes[originFormatType]
    }
    //根据当前配置的是否24小时制，使用不同的formatType
    static func convertTo12HourFormatType(originFormat: String, is24HourTime: Bool)-> String{
        let time12Hour = "_12"
        return  is24HourTime ? originFormat : (originFormat + time12Hour)
    }
}

public func getFormatTime(formatType: String, timestamp: Int64, translateLocale: Locale?, context: LDContext?) -> String? {
    guard let context = context else {
        cardlog.error("context is nil ")
        return nil
    }
    var formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .iso8601)
    formatter.locale = context.locale
    formatter.timeZone = TimeZone.current
    var language = context.locale.languageIdentifier
    let date = Date(timeIntervalSince1970: TimeInterval(timestamp / 1000))
    var isTranslate = false
    //下发的locale不为nil，则为走翻译的locale
    if let translateLocale = translateLocale {
        language =  translateLocale.languageIdentifier
        formatter.locale = translateLocale
        isTranslate = true
    }
    var formatstr = TimeComponentSettingHelper.getFormat(isTranslate: isTranslate,
                                                         originFormatType: formatType,
                                                         language: language,
                                                         is24HourTime: context.is24HourTime)
    guard let formatstr = formatstr else {
        return nil
    }
    formatter.dateFormat = formatstr
    return fixFormatStyle(formatter.string(from: date), locale: formatter.locale)
}

//兼容format输出样式问题
 func fixFormatStyle(_ str:String, locale:Locale) ->String {
    var str = str

     @Setting(key: UserSettingKey.make(userKeyLiteral: "messagecard_time_format_iOS_fix"))
    var settings: FormatFixSettingKey?

    if let settings = settings,
       let setting = settings.fixTimeStyle[locale.identifier] {
        for (needReplaceStr,targetStr) in setting {
            str = str.replacingOccurrences(of: needReplaceStr, with: targetStr)
        }
    }
    return str
}
