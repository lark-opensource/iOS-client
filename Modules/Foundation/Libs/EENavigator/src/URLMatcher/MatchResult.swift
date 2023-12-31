//
//  MatchResult.swift
//  EENavigator
//
//  Created by liuwanlin on 2018/9/9.
//

import Foundation

struct MatchResult {
    var matched: Bool = false
    var params: [String: String] = [:]
    var groups: [String?] = []
    var url: String = ""

    init() {}
}
