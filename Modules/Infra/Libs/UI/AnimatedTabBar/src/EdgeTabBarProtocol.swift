//
//  EdgeTabBarProtocol.swift
//  AnimatedTabBar
//
//  Created by 李晨 on 2020/6/7.
//

import UIKit
import Foundation
import LarkTab
import RxSwift

public enum EdgeTabBarLayoutStyle {
    case horizontal
    case vertical

    public var height: CGFloat {
        switch self {
        case .horizontal:
            return 44
        case .vertical:
            return 64
        }
    }

    public var width: CGFloat {
        switch self {
        case .horizontal:
            let horizontal: CGFloat = 240
            return horizontal
        case .vertical:
            return 76
        }
    }

    public static let maxViewWidth: CGFloat = 1000
}

/// 侧边 Tabbar 协议
public protocol EdgeTabBarProtocol: UIView {

    /// tabbar 宽度
    var tabbarWidth: CGFloat { get }
    /// tabbar布局方式
    var tabbarLayoutStyle: EdgeTabBarLayoutStyle { get set }
    /// tabbar mainTab，由 animationTabbar 设置
    var mainTabItems: [AbstractTabBarItem] { get set }
    /// tabbar quickTab，由 animationTabbar 设置
    var hiddenTabItems: [AbstractTabBarItem] { get set }
    ///
    var temporaryTabItems: [AbstractTabBarItem] { get set }
    /// 需要使用 weak 标记， 由 animationTabbar 设置
    var delegate: EdgeTabBarDelegate? { get set }

    /// 需要使用 weak 标记
    var refreshEdgeBarDelegate: EdgeTabBarRefreshDelegate? { get set }
    var showRefreshTabIcon: Bool { get set }
    var refreshTabItem: UIView? { get }

    var moreItem: AbstractTabBarItem? { get set }

    /// 通过index切换main tab
    /// index: start from 0
    func switchMainTab(to index: Int)

    /// 刷下 Tabbar，由于 tabBarItem 存在自定义 tab icon 的情况，多个 tabbar 的场景需要切换 superView
    /// 此方法内需要重新添加 custom icon
    func refreshTabbarCustomView()

    /// 快捷键打开 More
    func openMoreFromKeyCommand()

    func addAvatar(_ container: UIView)

    func addFocus(_ container: UIView)

    func addSearchEntrenceOnPad()

    func removeSearchEntrenceOnPad()

    func removeFocus()

    func tabWindowRect(for index: Int) -> CGRect?

    func selectedTab(_ tab: Tab)
}

/// EdgeTabbar 代理方法
public protocol EdgeTabBarDelegate: AnyObject {
    func edgeTabBar(_ edgeTabBar: EdgeTabBarProtocol, didSelectItem item: AbstractTabBarItem)
    func edgeTabBar(_ edgeTabBar: EdgeTabBarProtocol, removeTemporaryItems items: [AbstractTabBarItem])
    func edgeTabBarDidReorderItem(main: [RankItem], hidden: [RankItem], temporary: [AbstractTabBarItem])
    func edgeTabBarMoreItemsDidChange(_ edgeTabBar: EdgeTabBarProtocol, moreItems: [AbstractTabBarItem])
    func reopenTab()
    func hasCloseTab() -> Bool
    func searchItemTapped()
    // 更新tab->tabBarItem的映射数据源，当临时区向固定区提升的时候需要更新这个映射关系
    func edgeTabBarUpdateTabBarItem(tab: Tab, tabBarItem: AbstractTabBarItem)
}

public protocol EdgeTabBarRefreshDelegate: AnyObject {
    func edgeTabBarRefreshItemDidClick(_ edgeTabBar: EdgeTabBarProtocol)
}

extension EdgeTabBarRefreshDelegate {
    func edgeTabBarRefreshItemDidClick(_ edgeTabBar: EdgeTabBarProtocol) {}
}

public protocol EdgeTabBarDataSource: AnyObject {
    func itemsOfMainTab(in edgeTabBar: EdgeTabBarProtocol) -> [AbstractTabBarItem]
    func itemsOfTemporary(in edgeTabBar: EdgeTabBarProtocol) -> [AbstractTabBarItem]
    func itemOfMore(in edgeTabBar: EdgeTabBarProtocol) -> AbstractTabBarItem
}
