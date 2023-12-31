//
//  URL+Lark.swift
//  Lark
//
//  Created by 齐鸿烨 on 2017/6/7.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkCompatible

/*
 private func computeThumbWidth(width: Float) -> Int {
     let thumbWidthList: [Float] = [241, 321, 481, 641, 961]
     var resultWidth: Float = 0
     switch width {
     case 0..<thumbWidthList[0]:
         resultWidth = thumbWidthList[0]
     case thumbWidthList[0]..<thumbWidthList[1]:
         resultWidth = thumbWidthList[1]
     case thumbWidthList[1]..<thumbWidthList[2]:
         resultWidth = thumbWidthList[2]
     case thumbWidthList[2]..<thumbWidthList[3]:
         resultWidth = thumbWidthList[3]
     default:
         resultWidth = thumbWidthList[4]
     }
     return Int(resultWidth - 1)
 }*/

extension URL: LarkFoundationExtensionCompatible {}

let emailRegex = try? NSRegularExpression(
    pattern: "^[+a-zA-Z0-9_.!#$%&'*\\/=?^`{|}~-]+@([a-zA-Z0-9-]+\\.)+[a-zA-Z0-9]{2,63}$",
    options: NSRegularExpression.Options.caseInsensitive
)

let ipv4Regex = try? NSRegularExpression(
    pattern: #"^((\d|([1-9]\d)|(1\d\d)|(2[0-4]\d)|(25[0-5]))\.){3}(\d|([1-9]\d)|(1\d\d)|(2[0-4]\d)|(25[0-5]))$"#,
    options: NSRegularExpression.Options.caseInsensitive
)

public extension LarkFoundationExtension where BaseType == URL {
    /*
     public func convertToLarge(width: Float = 0) -> URL {
         if width == 0 {
             return base
         }
         let urlStr = base.absoluteString.replacingOccurrences(
             of: "thumb",
             with: "large/w\(computeThumbWidth(width: width))")
         return URL(string: urlStr) ?? self.base
     }*/

    fileprivate var components: URLComponents? {
        return URLComponents(url: self.base, resolvingAgainstBaseURL: false)
    }

    /// 清除了参数的URL
    var cleanURL: URL? {
        guard var components = components else {
            return self.base
        }
        components.queryItems = nil
        return components.url
    }

    var queryDictionary: [String: String] {
        var results = [String: String]()
        if let items = components?.queryItems {
            for item in items {
                results[item.name] = item.value
            }
        }

        return results
    }

    func addQueryDictionary(_ dic: [String: String]) -> URL? {
        return updateQueryDictionary(dic)
    }

    /// 更新URL参数
    ///
    /// - Parameter dic: 如果有对应Key则更新，没有则添加
    /// - Returns: 新的URL
    func updateQueryDictionary(_ dic: [String: String]) -> URL? {
        guard var components = components else {
            return self.base
        }
        var items = components.queryItems ?? [URLQueryItem]()

        for (key, value) in dic {
            if let item = items.first(where: { $0.name == key }) {
                items.lf_remove(object: item)
            }
            items.append(URLQueryItem(name: key, value: value))
        }

        components.queryItems = items
        return components.url
    }

    func removeQueryKeys(_ keys: [String]) -> URL? {
        guard var components = components else {
            return self.base
        }
        let items = components.queryItems?.filter { !keys.contains($0.name) }
        components.queryItems = items?.isEmpty == true ? nil : items
        return components.url
    }

    /// 如果不知道scheme或者scheme不合规范，则转换成http(s)协议url。
    ///
    /// - Returns: URL
    // TODO: rename toHttpUrl for common function name @longweiwei
    func toHttpUrl() -> URL? {
        let newUrl = self.base.absoluteString
        /// scheme not nil
        if let scheme = self.base.scheme {
            if scheme.isEmpty {
                return URL(string: "http\(newUrl)")
            }
            if let ipv4Regex = ipv4Regex, !ipv4Regex.matches(scheme).isEmpty {
                return URL(string: "http://\(newUrl)")
            }
            return self.base
        }
        /// scheme nil
        if let emailRegex = emailRegex {
            var matchUrl = newUrl
            matchUrl = emailRegex.stringByReplacingMatches(
                in: newUrl,
                options: NSRegularExpression.MatchingOptions(rawValue: 0),
                range: NSRange(location: 0, length: newUrl.count),
                withTemplate: "mailto:\(newUrl)"
            )
            if newUrl != matchUrl {
                return URL(string: matchUrl)
            }
        }
        if newUrl.starts(with: "//") {
            return URL(string: "http:\(newUrl)")
        }
        if newUrl.starts(with: "/") {
            return URL(string: "http:/\(newUrl)")
        }
        return URL(string: "http://\(newUrl)")
    }

    func appendPercentEncodedQuery(_ dict: [String: Any]) -> URL {
        guard var components = URLComponents(url: self.base, resolvingAgainstBaseURL: false) else {
            return self.base
        }

        if #available(iOS 11.0, *) {
            var items = components.percentEncodedQueryItems ?? []
            items = items.filter { item in
                !dict.contains(where: { key, _ -> Bool in
                    item.name == key
                })
            }
            dict.forEach { key, value in
                let item = URLQueryItem(
                    name: key,
                    value: "\(value)".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
                )
                items.append(item)
            }
            if items.isEmpty {
                components.percentEncodedQueryItems = nil
            } else {
                components.percentEncodedQueryItems = items
            }
        } else {
            var items = components.queryItems ?? []
            items = items.filter { item in
                !dict.contains(where: { key, _ -> Bool in
                    item.name == key
                })
            }
            if items.isEmpty {
                components.queryItems = nil
            } else {
                components.queryItems = items
            }
            let query = dict.map {
                let value = "\($0.value)".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
                return "\($0.key)=\(value)"
            }.joined(separator: "&")

            var percentEncodedQuery = components.percentEncodedQuery ?? ""
            if percentEncodedQuery.isEmpty {
                percentEncodedQuery = query
            } else {
                percentEncodedQuery += "&\(query)"
            }

            components.percentEncodedQuery = percentEncodedQuery
        }

        return components.url ?? self.base
    }
}
