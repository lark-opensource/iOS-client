//
//  WidgetTrackingTool.swift
//  LarkWidget
//
//  Created by Hayden Wang on 2022/4/22.
//

import Foundation
import WidgetKit

// MARK: - URL Parsing

/// 用于处理 Widget 点击事件的埋点问题。
///
/// iOS 小组件的点击事件都是 URL 跳转，无法从 Widget 进程中捕获点击事件。因此需要将埋点参数写入到 URL 的参数中，
/// 在主 App 的 `openURL` 回调中，识别 Widget 点击时间，解析出埋点参数，在主 App 进行埋点上报。
public enum WidgetTrackingTool {

    public static var paramsKey: String { "widget_url_params" }

    /// 将埋点参数编码后写入 Widget 的跳转 URL 中
    static func createURL(_ url: URL, trackParams: [String: Any]? = nil) -> URL {
        // 检查埋点参数合法性
        guard let params = trackParams, !params.isEmpty else { return url }
        // 将埋点参数序列化为 JSON String，并进行 URL 编码
        guard let serilizedParams = params.toJSONString() else { return url }
        // 将序列化后的埋点参数作为一个参数添加到 url 后面
        return url.appendingQueryParameters([
            paramsKey: serilizedParams
        ])
    }

    /// 将埋点参数编码后写入 Widget 的跳转 URL 中
    static func createURL(_ applink: String, trackParams: [String: Any]? = nil) -> URL? {
        // AppLink String 转为 URL
        guard let url = URL(string: applink) else { return nil }
        return createURL(url, trackParams: trackParams)
    }

    /// 从 Widget 的跳转 URL 中解析出埋点参数
    public static func parseParams(_ url: URL) -> [String: Any]? {
        // 从 Widget URL 中通过 key 解析出序列化的参数
        guard let serilizedParams = url.queryParameters?[paramsKey] else { return nil }
        // 反序列化得到埋点参数集
        return serilizedParams.toJSONDictionary() as? [String: Any]
    }
}

extension URL {

    /// 解析 URL 中的所有参数
    var queryParameters: [String: String]? {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false),
            let queryItems = components.queryItems else { return nil }

        var items: [String: String] = [:]

        for queryItem in queryItems {
            items[queryItem.name] = queryItem.value
        }

        return items
    }

    /// 向 URL 追加埋点参数
    func appendingQueryParameters(_ parameters: [String: String]) -> URL {
        guard var urlComponents = URLComponents(url: self, resolvingAgainstBaseURL: true) else { return self }
        urlComponents.queryItems = (urlComponents.queryItems ?? []) + parameters
            .map { URLQueryItem(name: $0, value: $1) }
        return urlComponents.url ?? self
    }
}

// MARK: - Params Serilization

fileprivate extension Dictionary {
    /// 埋点参数序列化
    func toJSONString() -> String? {
        if let jsonData = try? JSONSerialization.data(withJSONObject: self, options: []) {
            return String(data: jsonData, encoding: .utf8)?.urlEncoded()
        }
        return nil
    }
}

fileprivate extension String {

    func toJSONDictionary() -> Any? {
        if let jsonData = self.urlDecoded().data(using: .utf8),
           let dictionary = try? JSONSerialization.jsonObject(with: jsonData, options: .mutableLeaves) {
            return dictionary
        }
        return nil
    }
}

// MARK: - URL Encoding

/// URL 编解码
fileprivate extension String {

    /// 将原始的url编码为合法的 url
    ///
    /// Swift3 新增的 `addingPercentEncoding` 方法实现了编码功能，将指定的字符集使用 "%" 代替。
    func urlEncoded() -> String {
        let encodeUrlString = self.addingPercentEncoding(withAllowedCharacters:
            .urlQueryAllowed)
        return encodeUrlString ?? ""
    }

    // 将编码后的url转换回原始的 url
    func urlDecoded() -> String {
        return self.removingPercentEncoding ?? ""
    }
}

// MARK: - Widget Size

@available(iOS 14.0, *)
public extension WidgetFamily {

    var trackName: String {
        switch self {
        case .systemSmall:      	return "s"
        case .systemMedium:     	return "m"
        case .systemLarge:          return "l"
        case .systemExtraLarge:     return "xl"
        case .accessoryCircular:    return "ac"
        case .accessoryRectangular: return "ar"
        case .accessoryInline:      return "ai"
        @unknown default:           return "\(self)"
        }
    }
    
    var isLockScreenWidget: Bool {
        switch self {
        case .accessoryCircular, .accessoryRectangular, .accessoryInline:
            return true
        case .systemSmall, .systemMedium, .systemLarge, .systemExtraLarge:
            return false
        @unknown default:
            return false
        }
    }
    
    var lockScreenWidget: String {
        isLockScreenWidget ? "true" : "false"
    }
}

extension String {

    /// 数据脱敏
    func desensitized() -> String {
        var desensitizedString = self
        if desensitizedString.count <= 4 {
            desensitizedString = "******"
        } else {
            desensitizedString.replaceSubrange(
                String.Index(utf16Offset: 2, in: desensitizedString)..<String.Index(utf16Offset: count - 2, in: desensitizedString),
                with: "******"
            )
        }
        return desensitizedString
    }
}
