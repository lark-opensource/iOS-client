//
//  TabBarConfig.swift
//  AnimatedTabBar
//
//  Created by bytedance on 2020/12/10.
//

import Foundation

public struct TabBarConfig {
    public var maxBottomTab: Int
    public var minBottomTab: Int
    public var translucent: Bool

    public init(minBottomTab: Int, maxBottomTab: Int, translucent: Bool = false) {
        self.minBottomTab = minBottomTab
        self.maxBottomTab = maxBottomTab
        self.translucent = translucent
    }

    static var `default` = TabBarConfig(
        minBottomTab: 1,
        maxBottomTab: 5,
        translucent: false
    )
}
