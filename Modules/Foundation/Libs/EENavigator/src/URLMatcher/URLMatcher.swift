//
//  URLMatcher.swift
//  EENavigator
//
//  Created by liuwanlin on 2018/9/7.
//

import Foundation

let star = "*"

let preloadQueue = DispatchQueue(label: "router.preload")

protocol URLMatcher {
    func match(url: URL) -> MatchResult
}
