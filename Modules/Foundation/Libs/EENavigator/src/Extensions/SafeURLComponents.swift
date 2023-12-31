//
//  SafeURLComponents.swift
//  EENavigator
//
//  Created by 7Up on 2022/6/7.
//

import Foundation

/// ** SafeURLComponents: 用于解决 iOS 16 的 URLComponents 的问题 **
///
/// 在 iOS 16 环境中，无 schema 的 `URL` 转 `URLComponents` 后，
/// `URLComponents#url` 和 `URLComponents#string` 中的 `/` 前缀会被吞噬掉，即：
/// URL("//client/feed/home")，转 `URLComponents` 后，再转回 url 会变成
/// URL("client/feed/home")
struct SafeURLComponents {
    private let originUrl: URL
    private var inner: URLComponents

    init?(url: URL, resolvingAgainstBaseURL resolve: Bool) {
        guard let comps = URLComponents(url: url, resolvingAgainstBaseURL: resolve) else {
            return nil
        }
        self.inner = comps
        self.originUrl = url
    }

    /// 修复条件：
    /// - 在 iOS 16 环境下
    /// - 转 `URLComponents` 后无 schema，这又分两种情况：
    ///     - 原先就没有 scheme，譬如：`//client/feed/home`
    ///     - 原有 scheme，转 `URLComponents` 后被 clear 掉了
    /// 修复逻辑：
    /// - 和原始 url 比较，如果 `/` 少了，则补上
    var url: URL? {
        guard let real = inner.url else {
            return nil
        }
        guard #available(iOS 16.0, *) else {
            return real
        }
        guard real.scheme == nil || real.scheme == "" else {
            return real
        }

        let refUrl: URL
        if let oldScheme = originUrl.scheme, !oldScheme.isEmpty {
            refUrl = originUrl.removeScheme()
        } else if originUrl.absoluteString.hasPrefix("/") {
            refUrl = originUrl
        } else {
            return real
        }
        // 统计斜杠前缀的数量
        let countSlash = { (string: String) -> Int in
            var count = 0
            for char in string {
                if char == "/" {
                    count += 1
                } else {
                    break
                }
            }
            return count
        }
        let missingSlashCount = countSlash(refUrl.absoluteString) - countSlash(real.absoluteString)
        guard missingSlashCount > 0 else {
            return real
        }
        let prefix = String(repeating: "/", count: missingSlashCount)
        return URL(string: prefix + real.absoluteString) ?? real
    }

    var string: String? {
        guard let real = inner.string else {
            return nil
        }
        guard #available(iOS 16.0, *) else {
            return real
        }
        return self.url?.absoluteString
    }

    var scheme: String? {
        get { inner.scheme }
        set { inner.scheme = newValue }
    }

    var host: String? {
        get { inner.host }
        set { inner.host = newValue }
    }

    var query: String? {
        get { inner.query }
        set { inner.query = newValue }
    }

    var queryItems: [URLQueryItem]? {
        get { inner.queryItems }
        set { inner.queryItems = newValue }
    }

    var fragment: String? {
        get { inner.fragment }
        set { inner.fragment = newValue }
    }

}
