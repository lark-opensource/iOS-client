//
//  BlockURLMatcher.swift
//  EENavigator
//
//  Created by liuwanlin on 2018/10/26.
//

import Foundation

public typealias MatchBlock = (URL) -> Bool

final class BlockURLMatcher: URLMatcher {
    private let matchBlock: MatchBlock

    init(matchBlock: @escaping MatchBlock) {
        self.matchBlock = matchBlock
    }

    func match(url: URL) -> MatchResult {
        var result = MatchResult()
        result.matched = self.matchBlock(url)
        result.url = url.absoluteString
        return result
    }
}
