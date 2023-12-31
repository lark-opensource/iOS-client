//
//  MockFeedGuideDependency.swift
//  LarkFeed-Unit-Tests
//
//  Created by 白镜吾 on 2023/11/3.
//

import Foundation
import LarkContainer
import LarkGuideUI
@testable import LarkFeed

final class MockFeedGuideDependency: FeedGuideDependency {

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    var userResolver: UserResolver

    func checkShouldShowGuide(key: String) -> Bool { false }
    /// 是否显示切租户引导
    func needShowGuide(key: String) -> Bool { false }
    /// 已经显示过引导了
    func didShowGuide(key: String) {}
    /// 是否显示新引导
    func needShowNewGuide(key: String) -> Bool { false }
    /// 上报显示新引导
    func didShowNewGuide(key: String) {}
    /// 展示气泡
    func showBubbleGuideIfNeeded(guideKey: String,
                                 bubbleType: BubbleType,
                                 viewTapHandler: GuideViewTapHandler?,
                                 dismissHandler: TaskDismissHandler?,
                                 didAppearHandler: TaskDidAppearHandler?,
                                 willAppearHandler: TaskWillAppearHandler?) {}
    /// 展示气泡
    func showBubbleGuideIfNeeded(guideKey: String,
                                 bubbleType: BubbleType,
                                 isMock: Bool?,
                                 dismissHandler: TaskDismissHandler?) {}
    /// 关闭当前在展示的Guide（气泡、弹窗等，将引导UI从当前视图中移除）
    func closeCurrentGuideUIIfNeeded() {}
}
