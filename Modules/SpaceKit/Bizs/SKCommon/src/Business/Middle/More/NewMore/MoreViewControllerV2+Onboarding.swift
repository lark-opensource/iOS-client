//
//  MoreViewControllerV2+Onboarding.swift
//  SKCommon
//
//  Created by lizechuang on 2021/3/14.
//

import SKFoundation
import SKResource

public struct MoreOnboardingConfig {
    public var id: OnboardingID
    public var currentIndex: Int?
    public var totalCount: Int?
    public var isLast: Bool?
    public var nextID: String?
    public var shouldCheckDependencies: Bool?

    public init(id: OnboardingID,
                currentIndex: Int? = nil,
                totalCount: Int? = nil,
                isLast: Bool? = nil,
                nextID: String? = nil,
                shouldCheckDependencies: Bool? = nil) {
        self.id = id
    }
}

extension MoreOnboardingConfig {
    // OnboardingID < - > DocsType
    // 约定过一次只能显示一个Onboarding
    func onboardingMoreItemType() -> MoreItemType? {
        switch id {
        case .docWidescreenModeIntroSecond:
            return MoreItemType.widescreenModeSwitch
        default:
            return nil
        }
    }
}

/// OnBoardingAction
extension MoreViewControllerV2: OnboardingDelegate {

    func needToDisplayOnboarding() {
        guard let onboardingConfig = viewModel.onboardingConfig else {
            return
        }
        let id = onboardingConfig.id
        switch onboardingType(of: id) {
        case .flow: OnboardingManager.shared.showFlowOnboarding(id: id, delegate: self, dataSource: self)
        default: return
        }
    }

    private func fail(_ id: OnboardingID) {
        viewModel.showOnboardingEndCall.onNext((action: id.rawValue, success: false))
    }

    public func onboardingAcknowledge(_ id: OnboardingID) {
        viewModel.showOnboardingEndCall.onNext((action: id.rawValue, success: true))
    }

    public func onboardingManagerRejectedThisTime(_ id: OnboardingID) {
        DocsLogger.onboardingInfo("有人设置了不允许播放任何引导，所以 \(id) 播放失败")
        fail(id)
    }

    public func onboardingDisabledInMinaConfiguration(for id: OnboardingID) {
        DocsLogger.onboardingInfo("管理员设置了不播放 \(id)")
        fail(id)
    }

    public func onboardingAlreadyFinished(_ id: OnboardingID) {
        DocsLogger.onboardingInfo("\(id) 已经播放过了")
        onboardingAcknowledge(id)
    }

    public func onboardingMaterialNotEnough(for id: OnboardingID) {
        DocsLogger.onboardingError("未能提供完整的引导依赖物料，无法播放 \(id)！")
        fail(id)
    }
}

extension MoreViewControllerV2: OnboardingFlowDataSources {

    public func onboardingType(of id: OnboardingID) -> OnboardingType {
        switch id {
        case .docWidescreenModeIntroSecond: return .flow
        default: fatalError("不应该走到这里")
        }
    }

    public func onboardingHostViewController(for id: OnboardingID) -> UIViewController {
        guard let currentWindow = view.window else { return self }
        return OnboardingManager.shared.generateFullScreenWindow(uponCurrentWindow: currentWindow).rootViewController!
    }

    public func onboardingIndex(for id: OnboardingID) -> String? {
        guard let onboardingConfig = viewModel.onboardingConfig,
            let currentIndex = onboardingConfig.currentIndex,
            let totalCount = onboardingConfig.totalCount else {
            return nil
        }
        return "\(currentIndex)/\(totalCount)"
    }

    public func onboardingSkipText(for id: OnboardingID) -> String? {
        return nil
    }

    public func onboardingAckText(for id: OnboardingID) -> String {
        return BundleI18n.SKResource.Onboarding_Got_It
    }

    public func title(for id: OnboardingID) -> String? {
        switch id {
        case .docWidescreenModeIntroSecond:
            return BundleI18n.SKResource.CreationMobile_Docs_More_FullWidth_Tooltip_Title2
        default:
            return nil
        }
    }

    public func onboardingHint(for id: OnboardingID) -> String {
        switch id {
        case .docWidescreenModeIntroSecond:
            return BundleI18n.SKResource.CreationMobile_Docs_More_FullWidth_Tooltip_Content2
        default:
            return ""
        }
    }

    public func onboardingTargetRect(for id: OnboardingID) -> CGRect {
        switch id {
        case .docWidescreenModeIntroSecond:
            return moreView.obtainOnboardingCellInfo() ?? .zero
        default:
            return .zero
        }
    }

    public func onboardingArrowDirection(for id: OnboardingID) -> OnboardingStyle.ArrowDirection {
        switch id {
        case .docWidescreenModeIntroSecond:
            return view.isMyWindowCompactSize() ? .targetTopEdge : .targetLeadingEdge
        default:
            return .targetTopEdge
        }
    }

    public func bleeding(for id: OnboardingID) -> CGFloat {
        return 0
    }

}
