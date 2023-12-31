//
//  AppCenterTrackUtil.swift
//  Pods
//
//  Created by yin on 2018/8/5.
//

import Foundation
import LKCommonsLogging
import LarkLocalizations
import RustPB
import Swinject
import LarkOPInterface
import LarkWorkplaceModel

/// 工作台使用的工具类，但是目前第三方业务页面也在使用这个类，下一步就是进行分离
enum WorkplaceTool {
    static var appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"

    /// 获取图片URL的方法（后期优化到一个统一的地方）
    /// - Parameter key: 后端给的key
    /// - Parameter widthIn: 宽度
    /// - Parameter heightIn: 高度
    /// - Parameter type: 类型？
    /// - Parameter scaleIn: 蛤？
    static func avatarURLWith(
        key: String,
        width widthIn: Int?,
        height heightIn: Int?,
        type: String? = nil,
        scale scaleIn: Float? = nil
    ) -> String {
        guard var width = widthIn, var height = heightIn, width > 0, height > 0 else {
            return "\(key)~noop.\(type ?? "image")"
        }
        var scale: Float = 2.0
        if scaleIn == nil {
            scale = Float(UIScreen.main.scale)
        }
        width = Int(Float(width) * scale)
        height = Int(Float(height) * scale)
        return "\(key)~\(width)x\(height).\(type ?? "image")"
    }

    /// 国际化语言（适配后台逻辑，国际化Key统一使用小写）目前只有中英日 ⚠️
    static func curLanguage() -> String {
        return LanguageManager.currentLanguage.rawValue.lowercased()
    }

    /// 获取时区，单位是分钟
    static func currentTimeZoneOffset() -> Int {
        return -TimeZone.current.secondsFromGMT() / 60
    }

    static func attributedText(
        text: String,
        withHitTerms terms: [String],
        highlightColor: UIColor
    ) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: text)
        terms.forEach { (term) in
            var searchRange = NSRange(location: 0, length: text.count)
            // 和产品同学沟通，为了提高匹配效率，一个hitTerm最多匹配2次
            let maxSearchTime = 2
            var searchTime = 0
            while searchRange.location < text.count, searchTime < maxSearchTime {
                searchTime += 1
                let foundRange = (text as NSString).range(of: term, options: [.caseInsensitive], range: searchRange)
                if foundRange.location != NSNotFound {
                    attributedString.addAttribute(
                        .foregroundColor,
                        value: highlightColor,
                        range: foundRange
                    )
                    searchRange.location = foundRange.location + foundRange.length
                    searchRange.length = text.count - searchRange.location
                } else {
                    break
                }
            }
        }
        return attributedString
    }

    static func isItemValid(item: WPAppItem, dependency: WPDependency?) -> Bool {
        guard let nativeKey = item.nativeAppKey, !nativeKey.isEmpty else {
            return true
        }
        return dependency?.internalNavigator.isInTabs(for: nativeKey) ?? false
    }
}

protocol NotificationName {
    var name: Notification.Name { get }
}

extension RawRepresentable where RawValue == String, Self: NotificationName {
    var name: Notification.Name {
        return Notification.Name(self.rawValue)
    }
}

enum WorkplaceViewControllerNotifiction: String, NotificationName {
	case vcDidAppear = "WorkplaceViewControllerDidAppear"
	case vcDidDisappear = "WorkplaceViewControllerDidDisappear"
}

extension String {
    func possibleURL() -> URL? {
        if let url = URL(string: self) {
            return url
        }
        if let urlEncode = self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            return URL(string: urlEncode)
        }
        return nil
    }
}
