//
//  WikiContainerViewController+Onboarding.swift
//  SpaceKit
//
//  Created by 邱沛 on 2019/12/17.
//

import SKCommon
import SKResource
import SKFoundation
import UniverseDesignIcon

extension WikiContainerViewController: OnboardingFlowDataSources {

    public func onboardingType(of id: OnboardingID) -> OnboardingType {
        switch id {
        case .wikiNewbiePageTree: return .flow
        default: fatalError("不应该走到这里")
        }
    }

    public func onboardingHostViewController(for id: OnboardingID) -> UIViewController {
        return self
    }

    func onboardingIndex(for id: OnboardingID) -> String? {
        return "1/2"
    }

    func onboardingHollowStyle(for id: OnboardingID) -> OnboardingStyle.Hollow {
        return .circle
    }

    func onboardingHint(for id: OnboardingID) -> String {
        return BundleI18n.SKResource.Doc_Wiki_Tree_Guidebubble
    }

    func onboardingNextID(for id: OnboardingID) -> OnboardingID? {
        return .wikiNewbieSwipeLeft
    }

    func onboardingTargetRect(for id: OnboardingID) -> CGRect {
        guard let frame = getLeftBarButtonFrame(by: .tree) else {
            spaceAssertionFailure("cannot get targetPoint for icon_tool_tree_nor")
            return .zero
        }
        return frame
    }

    public func onboardingArrowDirection(for id: OnboardingID) -> OnboardingStyle.ArrowDirection {
        return .targetBottomEdge
    }

    func onboardingTapBubbleOutsideBehavior(of id: OnboardingID) -> OnboardingStyle.TapBubbleOutsideBehavior {
        return .disappearAndPenetrate
    }
}

extension WikiContainerViewController: OnboardingDelegate {

    public func onboardingDidTapBubbleOutside(for id: OnboardingID) -> OnboardingStyle.DisappearBehavior {
        return .proceed
    }

    // 点击下一步
    func onboardingAcknowledge(_ id: OnboardingID) {
        viewModel.input.showWikiTreeAction.onNext(())
    }

    // 点击跳过引导
    func onboardingSkip(_ id: OnboardingID) {
        OnboardingManager.shared.markFinished(for: [.wikiNewbieSwipeLeft])
    }
}
