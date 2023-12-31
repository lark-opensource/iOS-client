//
//  FeedGuideDependencyImpl.swift
//  LarkFeedPlugin
//
//  Created by liuxianyu on 2022/11/14.
//
import Foundation
import LarkFeed
import LarkContainer
import RxSwift
import Swinject
import Homeric
import LarkGuide
import LarkGuideUI

public final class FeedGuideDependencyImpl: FeedGuideDependency {
    public let userResolver: UserResolver

    public init(resolver: UserResolver) {
        self.userResolver = resolver
    }

    // MARK: LarkGuide
    /// 是否显示新引导
    public func checkShouldShowGuide(key: String) -> Bool {
        return (try? self.userResolver.resolve(assert: NewGuideService.self))?.checkShouldShowGuide(key: key) ?? true
    }
    /// 是否显示切租户引导
    public func needShowGuide(key: String) -> Bool {
        return (try? self.userResolver.resolve(assert: GuideService.self))?.needShowGuide(key: key) ?? true
    }
    /// 已经显示过引导了
    public func didShowGuide(key: String) {
        (try? self.userResolver.resolve(assert: GuideService.self))?.didShowGuide(key: key)
    }
    /// 是否显示新引导
    public func needShowNewGuide(key: String) -> Bool {
        return (try? self.userResolver.resolve(assert: NewGuideService.self))?.checkShouldShowGuide(key: key) ?? true
    }
    /// 上报显示新引导
    public func didShowNewGuide(key: String) {
        (try? self.userResolver.resolve(assert: NewGuideService.self))?.didShowedGuide(guideKey: key)
    }
    /// 展示气泡
    public func showBubbleGuideIfNeeded(guideKey: String,
                                        bubbleType: BubbleType,
                                        viewTapHandler: GuideViewTapHandler?,
                                        dismissHandler: TaskDismissHandler?,
                                        didAppearHandler: TaskDidAppearHandler?,
                                        willAppearHandler: TaskWillAppearHandler?) {
        let guideService = try? self.userResolver.resolve(assert: NewGuideService.self)
        guideService?.showBubbleGuideIfNeeded(
            guideKey: guideKey,
            bubbleType: bubbleType,
            viewTapHandler: viewTapHandler,
            dismissHandler: dismissHandler,
            didAppearHandler: didAppearHandler,
            willAppearHandler: willAppearHandler)
    }
    /// 展示气泡
    public func showBubbleGuideIfNeeded(guideKey: String,
                                        bubbleType: BubbleType,
                                        isMock: Bool?,
                                        dismissHandler: TaskDismissHandler?) {
        let guideService = try? self.userResolver.resolve(assert: NewGuideService.self)
        guideService?.showBubbleGuideIfNeeded(guideKey: guideKey,
                                              bubbleType: bubbleType,
                                              isMock: isMock,
                                              dismissHandler: dismissHandler)
    }
    /// 关闭当前在展示的Guide（气泡、弹窗等，将引导UI从当前视图中移除）
    public func closeCurrentGuideUIIfNeeded() {
        (try? self.userResolver.resolve(assert: NewGuideService.self))?.closeCurrentGuideUIIfNeeded()
    }
}
