//
//  CustomTextViewPasteManager.swift
//  LarkBaseKeyboard
//
//  Created by liluobin on 2023/7/20.
//

import UIKit
import EditTextView
import LarkEMM
import LarkSensitivityControl
import LarkFeatureGating
import LarkAppLinkSDK
import LarkContainer

public protocol CustomTextViewPasteManagerProtocol: AnyObject {
    func handlerPasteStrForTextView(_ textView: BaseEditTextView, attributes: [NSAttributedString.Key: Any]) -> Bool
}

public class URLHanderEntity {

    var canHanderBlock: ((String) -> Bool)?

    var handerBlock: ((String, Bool, [NSAttributedString.Key: Any]) -> NSAttributedString)?

    public init(canHanderBlock: ((String) -> Bool)?, handerBlock: ((String, Bool, [NSAttributedString.Key: Any]) -> NSAttributedString)?) {
        self.canHanderBlock = canHanderBlock
        self.handerBlock = handerBlock
    }
}

public class CustomHanderEntity {

    var handerBlock: ((String, [NSAttributedString.Key: Any]) -> NSAttributedString)?
    var matchedRangeBlock: ((String) -> [NSRange])?

    public init(matchedRangeBlock: ((String) -> [NSRange])?,
         handerBlock: ((String, [NSAttributedString.Key: Any]) -> NSAttributedString)?) {
        self.handerBlock = handerBlock
        self.matchedRangeBlock = matchedRangeBlock
    }
}

/// 优先遍历
public enum CustomURLType {

    case entityNum(URLHanderEntity)
    case linkUrl(URLHanderEntity)

    func value() -> URLHanderEntity {
        switch self {
        case .entityNum(let uRLHanderEntity):
            return uRLHanderEntity
        case .linkUrl(let uRLHanderEntity):
            return uRLHanderEntity
        }
    }
    var rawValue: Int {
        switch self {
        case .linkUrl(_):
            return 0
        case .entityNum(_):
            return 1
        }
    }
}

/// 支持解析的类型
public enum CustomPasteHanderType {
    case none
    case url(CustomURLType)
    case emoji(CustomHanderEntity)

    /// rawValue越大 优先级越高
    var rawValue: Int {
        switch self {
        case .none:
            return 0
        case .emoji(_):
            return 1
        case .url(_):
            return 2
        }
    }

    func defaultValue() -> CustomHanderEntity? {
        switch self {
        case .none:
            return nil
        case .url(_):
            return nil
        case .emoji(let customHanderEntity):
            return customHanderEntity
        }
    }

    func urlValue() -> URLHanderEntity? {
        switch self {
        case .url(let customURLType):
            return customURLType.value()
        default:
            return nil
        }
    }

    func getMatchedRangeFor(str: String) -> [NSRange]? {
        return self.defaultValue()?.matchedRangeBlock?(str)
    }

}

public class CustomTextViewPasteManager: CustomTextViewPasteManagerProtocol {

    struct RangeInfo {
        let range: NSRange
        var type: CustomPasteHanderType
    }

    public static let specialURLRegexp = AnchorTransformer.isURLRegexp
    public static let generalURLRegexp = (try? NSRegularExpression(pattern: AnchorTransformer.URL_REG, options: .caseInsensitive)) ?? NSRegularExpression()

    let token: String

    weak var textView: LarkEditTextView?

    init(token: String) {
        self.token = token
    }

    public func handlerPasteStrForTextView(_ textView: BaseEditTextView, attributes: [NSAttributedString.Key: Any]) -> Bool {
        let config = PasteboardConfig(token: Token(token))
        guard let str = SCPasteboard.general(config).string, !str.isEmpty else { return false }
        /// 1 需要解析的类型
        var ranges: [RangeInfo] = []
        var urlTypes: [CustomURLType] = []
        let subHandlers: [CustomSubInteractionHandler] = textView.interactionHandler.subHandlers.compactMap { handler in
            return (handler as? CustomSubInteractionHandler)
        }
        subHandlers.forEach { hander in
            switch hander.handerPasteTextType {
            case .url(let type):
                urlTypes.append(type)
            default:
                let subRanges = hander.handerPasteTextType.getMatchedRangeFor(str: str) ?? []
                ranges.append(contentsOf: subRanges.map({ RangeInfo(range: $0, type: hander.handerPasteTextType) }))
            }
        }
        var isAnchor = false
        if !urlTypes.isEmpty {
            urlTypes = urlTypes.sorted(by: { type1, type2 in
                return type1.rawValue > type2.rawValue
            })
            var urlRanges: [NSRange] = []
            if Self.specialURLRegexp.numberOfMatches(in: str, range: NSRange(location: 0, length: str.utf16.count)) > 0 {
                urlRanges = [NSRange(location: 0, length: str.utf16.count)]
                isAnchor = true
            } else {
                urlRanges = Self.generalURLRegexp.matches(in: str, range: NSRange(location: 0, length: str.utf16.count)).map { res in
                    return res.range
                }
            }

            urlRanges.forEach { range in
                let subStr = (str as NSString).substring(with: range)
                if let value = urlTypes.first(where: { type in
                    return type.value().canHanderBlock?(subStr) ?? false
                }) {
                    ranges.append(RangeInfo(range: range, type: .url(value)))
                }
            }
        }

        if ranges.isEmpty { return false }
        /// 2 根据正在排序的结果，进项排序（主线程处理)
        ranges = ranges.sorted { range1, range2 in
            return range1.range.location < range2.range.location
        }
        var handlerRanges: [RangeInfo] = []
        /// 3 出现重叠之后，根据枚举的优先级进排序，丢弃低优的
        for (idx, info) in ranges.enumerated() {
            if idx + 1 < ranges.count {
                let nextRangeInfo = ranges[idx + 1]
                if nextRangeInfo.range.intersection(info.range) != nil {
                    handlerRanges.append(nextRangeInfo.type.rawValue > info.type.rawValue ? nextRangeInfo : info)
                } else {
                    handlerRanges.append(info)
                }
            } else {
                handlerRanges.append(info)
            }
        }
        /// 4 handlerRanges的倒序遍历，交给底层的每个inputhander替换，生成对应的结果，进行拼接
        let muattr = NSMutableAttributedString(string: str, attributes: attributes)
        handlerRanges.reversed().forEach { info in
            let subStr = (str as NSString).substring(with: info.range)
            var attr: NSAttributedString?
            if let res = info.type.urlValue()?.handerBlock?(subStr, isAnchor, attributes) {
                attr = res
            } else {
                attr = info.type.defaultValue()?.handerBlock?(subStr, attributes)
            }
            if let attr = attr {
                muattr.replaceCharacters(in: info.range, with: attr)
            }
        }
        let selectedRange = textView.selectedRange
        let text = NSMutableAttributedString(attributedString: textView.attributedText)
        text.replaceCharacters(in: selectedRange, with: muattr)
        let range = NSRange(location: selectedRange.location + muattr.length,
                            length: 0)
        textView.attributedText = text
        textView.selectedRange = range
        textView.scrollRangeToVisible(range)
        return true
    }
}

public final class URLInputManager {

    public enum URLType {
        case entityNum  // 含有entityNum的链接
        case normal     // 普通url链接
        case unknown    // 未知类型，比如字符串为空
    }

    public static func checkURLType(_ urlStr: String) -> URLType {
        guard !urlStr.isEmpty else { return .unknown }
        guard AnchorTransformer.isURL(url: urlStr),
              let url = try? URL.forceCreateURL(string: urlStr) else {
            return .unknown
        }
        if AppLinkInternalConfig().appLinkService.isAppLink(url), Self.entityNumber(urlStr) != nil {
            return .entityNum
        }
        return .normal
    }

    public static func entityNumber(_ urlStr: String) -> String? {
        if let range = urlStr.range(of: Self.EntityNumKey) {
            let num = String(urlStr[range.upperBound...])
            if let exp = try? NSRegularExpression(pattern: Self.EntityNumPattern, options: .caseInsensitive),
               exp.numberOfMatches(in: num, range: NSRange(location: 0, length: num.utf16.count)) > 0 {
                return num
            }
        }
        return nil
    }

    // EntityNum用于切割的key
    private static let EntityNumKey = "suite_entity_num="
    private static let EntityNumPattern = "^[a-zA-Z]\\d{4,}$"
    // 为了调用appLinkService接口而定义的内部文件
    private final class AppLinkInternalConfig {

        @InjectedLazy var appLinkService: AppLinkService

        init() { }
    }
}
