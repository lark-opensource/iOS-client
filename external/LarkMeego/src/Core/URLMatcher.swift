//
//  URLMatcher.swift
//  LarkMeego
//
//  Created by shizhengyu on 2022/6/7.
//

import Foundation
import LarkContainer
import LarkMeegoInterface
import LarkMeegoLogger
import UIKit

private enum Agreement {
    static let forceWebview = "force_webview"
    // https://bytedance.feishu.cn/wiki/wikcnpV5OUHZXaDeCa6zPzwVElb
    enum QueryValidation {
        static let pathPattern = "path_pattern"
        static let queryKeys = "query_keys"
    }
}

struct QueryRequired {
    let patternRegex: NSRegularExpression
    let requiredQuerys: [String]
}

final class MeegoURLMatcher {
    private(set) var hosts: [String] = []
    private(set) var pathPatternRegexes: [NSRegularExpression] = []
    private(set) var homePatternRegexes: [NSRegularExpression] = []
    private(set) var meegoUrlPatternRegex: NSRegularExpression?
    private(set) var queryRequireds: [QueryRequired] = []

    func update(
        with hosts: [String],
        patterns: [String],
        homePatterns: [String],
        queryRequireds: [[String: Any]]
    ) {
        let start = CACurrentMediaTime()
        self.hosts = hosts
        self.pathPatternRegexes = patterns.compactMap { try? NSRegularExpression(pattern: $0) }
        self.homePatternRegexes = homePatterns.compactMap { try? NSRegularExpression(pattern: $0) }
        self.meegoUrlPatternRegex = try? NSRegularExpression(
            pattern: "(http|https)://(\(hosts.joined(separator: "|"))).*"
        )
        self.queryRequireds = queryRequireds.compactMap({ requiredInfo in
            if let pathPattern = requiredInfo[Agreement.QueryValidation.pathPattern] as? String,
               !pathPattern.isEmpty,
               let queryKeys = requiredInfo[Agreement.QueryValidation.queryKeys] as? [String],
               !queryKeys.isEmpty,
               let regex = try? NSRegularExpression(pattern: pathPattern) {
                return QueryRequired(patternRegex: regex, requiredQuerys: queryKeys)
            }
            return nil
        })
        MeegoLogger.debug("create meego route regex, cost: \(gap(with: start)) us")
    }

    func hasMatch(url: URL) -> Bool {
        return hasAnyMatch(urls: [url])
    }

    func hasAnyMatch(urls: [URL]) -> Bool {
        let start = CACurrentMediaTime()
        let matched = matchedUrls(with: urls)
        if matched.isEmpty {
            MeegoLogger.debug("match meego urls failed, urls: \(urls.map { $0.absoluteString }), cost: \(gap(with: start)) us")
            return false
        }
        MeegoLogger.debug("match meego urls success, matchedUrls: \(matched.map { $0.absoluteString }), cost: \(gap(with: start)) us")
        return true
    }

    func matchedUrls(with urls: [URL]) -> [URL] {
        guard !urls.isEmpty,
              !hosts.isEmpty,
              !pathPatternRegexes.isEmpty,
              urls.contains(where: { url in
                  return ["http", "https"].contains(url.scheme) && hosts.first { url.host == $0 } != nil
              }) else {
            return []
        }

        let matched = urls.filter { url in
            return pathPatternRegexes.first { regExp in
                // https://bytedance.feishu.cn/docx/doxcn6VKjJT0oiozxQSLW7e6jFZ
                let range = NSRange(location: 0, length: url.path.utf16.count)
                return
                (regExp.firstMatch(in: url.path, range: range) != nil)
                &&
                // 需要额外检查 query 中是否带有强制使用 webview 打开的约定标记
                !(url.urlParameters?[Agreement.forceWebview]?.toBool() ?? false)
                &&
                // 需要额外检查 queryRequired 信息，校验匹配上的 url 是否携带要求的 query
                validateRequired(url)
            } != nil
        }

        return matched
    }

    func matchedUrls(by opCardJsonStr: String) -> [URL] {
        let urls = meegoUrlPatternRegex?.matches(opCardJsonStr).compactMap { URL(string: $0) } ?? []
        return matchedUrls(with: urls)
    }

    func hasMatchHome(url: URL) -> Bool {
        let urlRange = NSRange(location: 0, length: url.absoluteString.utf16.count)
        guard meegoUrlPatternRegex?.firstMatch(in: url.absoluteString, range: urlRange) != nil else {
            return false
        }
        let pathRange = NSRange(location: 0, length: url.path.utf16.count)
        return homePatternRegexes.first { regExp in
            return regExp.firstMatch(in: url.path, range: pathRange) != nil
        } != nil
    }
}

private extension MeegoURLMatcher {
    func validateRequired(_ url: URL) -> Bool {
        if queryRequireds.isEmpty {
            return true
        }
        for requiredInfo in queryRequireds {
            let range = NSRange(location: 0, length: url.path.utf16.count)
            if requiredInfo.patternRegex.firstMatch(in: url.path, range: range) != nil {
                if requiredInfo.requiredQuerys.isEmpty {
                    continue
                }
                guard let urlParameters = url.urlParameters else {
                    return false
                }
                let urlQuerys = Array(urlParameters.keys)
                if let notSatisfied = requiredInfo.requiredQuerys.first { query in
                    return !urlQuerys.contains(query)
                } {
                    return false
                }
            }
        }
        return true
    }

    // 返回单位：微秒
    func gap(with start: CFTimeInterval) -> Int64 {
        return Int64(round((CACurrentMediaTime() - start) * 1000 * 1000))
    }
}
