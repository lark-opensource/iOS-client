//
//  RegExpURLMatcher.swift
//  EENavigator
//
//  Created by liuwanlin on 2018/9/9.
//

import Foundation
import EEAtomic

final class RegExpURLMatcher: URLMatcher {

    // lazy load once
    @SafeLazy
    private var regex: NSRegularExpression?

    init(regExpPattern: String, immediate: Bool = false) {
        _regex = SafeLazy {
            guard let regExp = try? NSRegularExpression(pattern: regExpPattern) else {
                assertionFailure("Cann't parse [\(regExpPattern)] into regular expression")
                return nil
            }
            return regExp
        }

        if immediate {
            self.load()
        } else {
            preloadQueue.async {
                self.load()
            }
        }
    }

    func load() {
        _ = regex
    }

    func match(url: URL) -> MatchResult {
        guard let regExp = self.regex else {
            return MatchResult()
        }

        let urlString = url.absoluteString

        // Empty url, return default result
        if urlString.isEmpty {
            return MatchResult()
        }

        let range = NSRange(location: 0, length: urlString.count)
        guard let match = regExp.firstMatch(in: urlString, range: range) else {
            return MatchResult()
        }

        var result = MatchResult()
        result.matched = true
        result.url = NSString(string: urlString).substring(with: match.range(at: 0))
        result.groups.append(result.url)
        for idx in 1..<match.numberOfRanges {
            let range = match.range(at: idx)
            if range.location == NSNotFound {
                result.groups.append(nil)
                continue
            }
            let matchedStr = NSString(string: urlString).substring(with: range)
            result.groups.append(matchedStr)
        }

        return result
    }
}
