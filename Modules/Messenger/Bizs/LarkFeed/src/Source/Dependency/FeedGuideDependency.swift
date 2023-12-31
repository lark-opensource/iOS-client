//
//  FeedGuideDependency.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/11/14.
//

import Foundation
import LarkGuideUI
import LarkContainer

public typealias TaskDidAppearHandler = ((_ guideKey: String) -> Void)
public typealias TaskDismissHandler = (() -> Void)
public typealias TaskWillAppearHandler = ((_ guideKey: String) -> Void)

/// Feed引导功能的依赖
public protocol FeedGuideDependency: UserResolverWrapper {
    // MARK: LarkGuide
    /// 是否显示新引导
    func checkShouldShowGuide(key: String) -> Bool
    /// 是否显示切租户引导
    func needShowGuide(key: String) -> Bool
    /// 已经显示过引导了
    func didShowGuide(key: String)
    /// 是否显示新引导
    func needShowNewGuide(key: String) -> Bool
    /// 上报显示新引导
    func didShowNewGuide(key: String)
    /// 展示气泡
    func showBubbleGuideIfNeeded(guideKey: String,
                                 bubbleType: BubbleType,
                                 viewTapHandler: GuideViewTapHandler?,
                                 dismissHandler: TaskDismissHandler?,
                                 didAppearHandler: TaskDidAppearHandler?,
                                 willAppearHandler: TaskWillAppearHandler?)
    /// 展示气泡
    func showBubbleGuideIfNeeded(guideKey: String,
                                 bubbleType: BubbleType,
                                 isMock: Bool?,
                                 dismissHandler: TaskDismissHandler?)
    /// 关闭当前在展示的Guide（气泡、弹窗等，将引导UI从当前视图中移除）
    func closeCurrentGuideUIIfNeeded()
}
