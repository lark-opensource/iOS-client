//
//  AIQuickLaunchBarInterface.swift
//  LarkQuickLaunchInterface
//
//  Created by ByteDance on 2023/5/26.
//

import Foundation

/// 抽象AIQuickLaunchBar协议
public protocol MyAIQuickLaunchBarInterface: UIView {
    /// 动画生命周期相关代理
    var delegate: QuickLaunchBarDelegate? { set get }

    /// 展示/隐藏骨架图, 骨架UI闪烁效果
    func setSkeletonDrawingHidden(_ isHidden: Bool)

    /// 更新AIItem显隐状态
    func setAIItemEnable(_ isEnable: Bool)

    /// QuickLaunchBar高度,
    /// 此高度不包含安全区高度
    var launchBarHeight: CGFloat { get }

    /// 更新Items
    func reloadByItems(_ items: [QuickLaunchBarItem])

    /// 更新指定位置的Item
    func reloadItem(_ item: QuickLaunchBarItem, at index: Int)

    ///  下面两个方法用于控制滚动隐藏效果，如果不调用则不会出现滚动LaunchBar隐藏效果
    ///  容器将要开始滚动
    func containerWillBeginDragging(_ scrollView: UIScrollView)

    ///  容器开始滚动
    func containerDidScroll(_ scrollView: UIScrollView)
}
