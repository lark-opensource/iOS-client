//
//  TabbarItemTapProtocol.swift
//  AnimatedTabBar
//
//  Created by KT on 2020/1/29.
//

import Foundation

public protocol TabbarItemTapProtocol {
    func onTabbarItemDoubleTap()
    func onTabbarItemTap(_ isSameTab: Bool)
    func onTabbarItemLongPress()
}

extension TabbarItemTapProtocol {
    public func onTabbarItemDoubleTap() {}
    public func onTabbarItemTap(_ isSameTab: Bool) {}
    public func onTabbarItemLongPress() {}
}
