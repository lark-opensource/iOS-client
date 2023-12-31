//
//  Options.swift
//  EENavigator
//
//  Created by liuwanlin on 2018/9/7.
//

import Foundation

struct Options: OptionSet {
    let rawValue: UInt

    init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    static let strict = Options(rawValue: 1)
    static let end = Options(rawValue: 2)
    static let `default`: Options = [.end]
}
