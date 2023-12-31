//
//  TabType.swift
//  AnimatedTabBar
//
//  Created by KT on 2020/2/2.
//

import Foundation
import LarkTab
import LarkSetting

public enum TabType {
    case none
    /// 主导航
    case mainTab(Int)
    /// 快捷导航
    case quickTab(Int)
    /// 本地支持的一方应用
    case locoal(Int)
    /// 最近使用
    case recentUsed(Int)
    /// iPad临时区
    case temporaryTab(Int)
}

public extension AnimatedTabBarController {

    /// 查询 Tab 对应的 TabType，作为兼容性解决方案，后续会随 TabType 一并删掉
    func tabType(of tab: Tab, in style: TabbarStyle? = nil) -> TabType {
        let style = style ?? self.tabbarStyle
        let bottomData: TabBarGroupItems
        let edgeData: TabBarGroupItems
        if !self.crmodeUnifiedDataDisable {
            bottomData = self.allTabBarItems.iPhone
            edgeData = self.allTabBarItems.iPad
        } else {
            bottomData = self.allTabBarItems.bottom
            edgeData = self.allTabBarItems.edge
        }
        switch style {
        case .bottom:
            if let index = bottomData.main.firstIndex(where: { $0.tab == tab }) {
                return .mainTab(index)
            }
            if let index = bottomData.quick.firstIndex(where: { $0.tab == tab}) {
                return .quickTab(index)
            }
        case .edge:
            if let index = edgeData.main.firstIndex(where: { $0.tab == tab }) {
                return .mainTab(index)
            }
            if let index = edgeData.quick.firstIndex(where: { $0.tab == tab }) {
                return .quickTab(index)
            }
            if let index = self.temporaryTabs.firstIndex(where: { $0.tab == tab }) {
                return .temporaryTab(index)
            }
        }
        return .none
    }
}

public enum AnimatedTabBarFeatureKey: String {
    /// 添加应用入口
    case navigationAddlinkEnable = "lark.navigation.addlink.superapp"


    public var key: FeatureGatingManager.Key {
        FeatureGatingManager.Key(stringLiteral: rawValue)
    }
}
