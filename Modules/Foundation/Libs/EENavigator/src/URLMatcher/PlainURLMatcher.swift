//
//  PlainURLMatcher.swift
//  EENavigator
//
//  Created by liuwanlin on 2019/1/2.
//

import Foundation

final class PlainURLMatcher: URLMatcher {
    private let pattern: String

    init(pattern: String) {
        self.pattern = pattern.trimTrailingSlash
    }

    func match(url: URL) -> MatchResult {
        let urlString = url.withoutQueryAndFragment.trimTrailingSlash
        var result = MatchResult()
        if urlString == pattern {
            result.matched = true
            result.url = urlString
        }
        return result
    }
}
