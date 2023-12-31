//
// Created by duanxiaochen.7 on 2021/2/5.
// Affiliated with SKBrowser.
//
// Description: 群公告相关的 Onboarding 代理方法实现

import SKUIKit
import SKCommon
import SKFoundation
import SKResource
import RxSwift
import Lottie


// - MARK: Delegates
extension AnnouncementViewController: OnboardingDelegate {

    public func onboardingManagerRejectedThisTime(_ id: OnboardingID) {
        DocsLogger.onboardingInfo("有人设置了不允许播放任何引导，所以 \(id) 播放失败")
        editor.jsServiceManager.callFunction(DocsJSCallBack.notifyGuideFinish,
                                             params: ["action": id.rawValue, "status": "failed"],
                                             completion: nil)
    }

    public func onboardingDisabledInMinaConfiguration(for id: OnboardingID) {
        DocsLogger.onboardingInfo("管理员设置了不播放 \(id)")
        editor.jsServiceManager.callFunction(DocsJSCallBack.notifyGuideFinish,
                                             params: ["action": id.rawValue, "status": "failed"],
                                             completion: nil)
    }

    public func onboardingAlreadyFinished(_ id: OnboardingID) {
        DocsLogger.onboardingInfo("\(id) 已经播放过了")
        editor.jsServiceManager.callFunction(DocsJSCallBack.notifyGuideFinish,
                                             params: ["action": id.rawValue, "status": "success"],
                                             completion: nil)
    }

    public func onboardingDependenciesUnfinished(for id: OnboardingID) {
        DocsLogger.onboardingInfo("由于依赖的引导序列 \(onboardingDependencies(for: id)) 未全部完成播放，无法播放 \(id)")
        editor.jsServiceManager.callFunction(DocsJSCallBack.notifyGuideFinish,
                                             params: ["action": id.rawValue, "status": "failed"],
                                             completion: nil)
    }

    public func onboardingMaterialNotEnough(for id: OnboardingID) {
        skAssertionFailure("未能提供完整的引导依赖物料，无法播放 \(id)！")
        editor.jsServiceManager.callFunction(DocsJSCallBack.notifyGuideFinish,
                                             params: ["action": id.rawValue, "status": "failed"],
                                             completion: nil)
    }

    public func onboardingWindowSizeWillChange(for id: OnboardingID) -> OnboardingStyle.DisappearBehavior {
        DocsLogger.onboardingInfo("在播放引导 \(id) 的时候 window 发生了尺寸变化，acknowledge 了")
        return .acknowledge
    }

    public func onboardingTargetViewDidDisappear(for id: OnboardingID) -> OnboardingStyle.DisappearBehavior {
        DocsLogger.onboardingInfo("在播放引导 \(id) 的时候目标 view 消失了，acknowledge 了")
        return .acknowledge
    }

    public func onboardingAcknowledge(_ id: OnboardingID) {
        if onboardingIsLast[id] == true {
            OnboardingManager.shared.setTemporarilyRejectsUpcomingOnboardings()
        }
        editor.jsServiceManager.callFunction(DocsJSCallBack.notifyGuideFinish,
                                             params: ["action": id.rawValue, "status": "success"],
                                             completion: nil)
    }

    public func onboardingSkip(_ id: OnboardingID) {
        editor.jsServiceManager.callFunction(DocsJSCallBack.notifyGuideFinish,
                                             params: ["action": id.rawValue, "status": "skipped"],
                                             completion: nil)
    }
}

// - MARK: Data Sources

extension AnnouncementViewController: OnboardingDataSource {

    public func onboardingType(of id: OnboardingID) -> OnboardingType {
        guard let type = onboardingTypes[id] else {
            fatalError("小傻瓜，是不是忘了配引导类型了？")
        }
        return type
    }

    public func onboardingIsAsynchronous(for id: OnboardingID) -> Bool {
        false
    }

    public func onboardingSupportedInterfaceOrientations(for id: OnboardingID) -> UIInterfaceOrientationMask {
        if SKDisplay.pad { return [.all] }
        return [.portrait]
    }

    public func onboardingDisappearStyle(of id: OnboardingID) -> OnboardingStyle.DisappearStyle {
        return .immediatelyAfterUserInteraction
    }

    public func onboardingHostViewController(for id: OnboardingID) -> UIViewController {
        return self
    }

    public func onboardingImage(for id: OnboardingID) -> UIImage? {
        return nil
    }

    public func onboardingLottieView(for id: OnboardingID) -> LOTAnimationView? {
        return nil
    }

    public func onboardingTitle(for id: OnboardingID) -> String? {
        return onboardingTitles[id]
    }

    public func onboardingHint(for id: OnboardingID) -> String {
        return onboardingHints[id] ?? ""
    }

    public func onboardingTargetRect(for id: OnboardingID) -> CGRect {
        switch id {
        case .docGroupAnnouncementIntro:
            onboardingTargetRects[id] = navigationBar.titleLabel.convert(navigationBar.titleLabel.bounds, to: view)
        case .docGroupAnnouncementAutoSave:
            onboardingTargetRects[id] = navigationBar.trailingButtons.first?.convert(navigationBar.trailingButtons.first?.bounds ?? .zero, to: view)
        default: ()
        }
        return onboardingTargetRects[id] ?? .zero
    }

    public func onboardingArrowDirection(for id: OnboardingID) -> OnboardingStyle.ArrowDirection {
        return onboardingArrowDirections[id] ?? .targetTopEdge
    }

    public func onboardingShouldCheckDependencies(for id: OnboardingID) -> Bool {
        return onboardingShouldCheckDependenciesMap[id] ?? true
    }

    public func onboardingDependencies(for id: OnboardingID) -> [OnboardingID] {
        return onboardingDependenciesMap[id] ?? []
    }

    public func onboardingNextID(for id: OnboardingID) -> OnboardingID? {
        return onboardingNextIDs[id]
    }
}
