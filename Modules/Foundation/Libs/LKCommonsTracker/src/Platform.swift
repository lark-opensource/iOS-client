//
//  Platform.swift
//  LKCommonsTracker
//
//  Created by 李晨 on 2019/3/25.
//

import Foundation

public struct Platform: Hashable {
    public static let slardar: Platform = Platform(key: "slardar")
    public static let tea: Platform = Platform(key: "tea")

    public let key: String
    public init(key: String) {
        self.key = key
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.key)
    }
}
