//
//  PathPatternURLMatcher.swift
//  EENavigator
//
//  Created by liuwanlin on 2018/9/9.
//

import Foundation
import EEAtomic

final class PathPatternURLMatcher: URLMatcher {

    // lazy load once
    private var regex: NSRegularExpression? {
        lazyWrapper.value.0
    }
    private var keys: [String] {
        lazyWrapper.value.1
    }
    private let lazyWrapper: SafeLazy<(NSRegularExpression?, [String])>

    private let fastStar: Bool

    init(pattern: String, options: Options = .default, immediate: Bool = false) {
        self.lazyWrapper = SafeLazy {
            return tokensToRegExp(tokens: pattern.parse(), options: options)
        }
        self.fastStar = pattern == star

        if immediate {
            self.load()
        } else {
            preloadQueue.async {
                self.load()
            }
        }
    }

    func load() {
        _ = lazyWrapper.value
    }

    // Parameters in query aren't included
    // Only match parameters in path
    func match(url: URL) -> MatchResult {
        let urlString = url.withoutQueryAndFragment

        // Empty url, return default result
        if urlString.isEmpty {
            return MatchResult()
        }

        // FastStar match all
        if fastStar {
            var result = MatchResult()
            result.matched = true
            result.url = urlString
            return result
        }

        // Match the whole url
        // No matches, return default result
        let range = NSRange(location: 0, length: urlString.count)
        guard let regex, let match = regex.firstMatch(in: urlString, range: range) else {
            return MatchResult()
        }

        var result = MatchResult()
        result.matched = true
        result.url = NSString(string: urlString).substring(with: match.range(at: 0))
        result.groups.append(result.url)
        for idx in 1..<match.numberOfRanges {
            let key = self.keys[idx - 1]
            let range = match.range(at: idx)
            if range.location == NSNotFound {
                continue
            }
            let matchedStr = NSString(string: urlString).substring(with: match.range(at: idx))
            result.groups.append(matchedStr)
            if let val = matchedStr.removingPercentEncoding {
                result.params[key] = val
            }
        }

        return result
    }
}
