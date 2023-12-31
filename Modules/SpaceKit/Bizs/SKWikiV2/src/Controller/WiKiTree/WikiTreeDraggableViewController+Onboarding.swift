//
//  WikiTreeDraggableViewController+Onboarding.swift
//  SpaceKit
//
//  Created by 邱沛 on 2019/12/6.
//

import SKCommon
import SKFoundation
import SKResource

extension WikiTreeDraggableViewController: OnboardingDelegate {

    func onboardingAcknowledge(_ id: OnboardingID) {
        switch id {
        case .wikiNewbieSwipeLeft:
            treeView.tableView.setEditing(false, animated: true)
        default:
            spaceAssertionFailure("not register onboardingID in wiki draggable tree!")
        }
    }
    
    func onboardingTargetViewDidDisappear(for id: OnboardingID) -> OnboardingStyle.DisappearBehavior {
        return .acknowledge
    }
    
    func onboardingSwipeDisappearCallBack(_ id: OnboardingID, sender: UIPanGestureRecognizer) {
        self.treeView.swipDidChange(sender)
    }
}

extension WikiTreeDraggableViewController: OnboardingFlowDataSources {

    public func onboardingType(of id: OnboardingID) -> OnboardingType {
        switch id {
        case .wikiNewbieSwipeLeft: return .flow
        default: fatalError("not register onboardingID in wiki draggable tree!")
        }
    }

    public func onboardingHostViewController(for id: OnboardingID) -> UIViewController {
        guard let window = self.view.window,
              let rootVC = OnboardingManager.shared.generateFullScreenWindow(uponCurrentWindow: window).rootViewController else {
            return self
        }
        return rootVC
    }

    func onboardingIndex(for id: OnboardingID) -> String? {
        return "2/2"
    }

    func onboardingSkipText(for id: OnboardingID) -> String? {
        return nil
    }

    func onboardingAckText(for id: OnboardingID) -> String {
        switch id {
        case .wikiNewbieSwipeLeft:
            return BundleI18n.SKResource.Onboarding_Got_It
        default:
            fatalError("not register onboardingID in wiki draggable tree!")
        }
    }

    func onboardingHint(for id: OnboardingID) -> String {
        switch id {
        case .wikiNewbieSwipeLeft:
            return BundleI18n.SKResource.Doc_Wiki_OnBoarding_TreeLeftSwipe
        default:
            fatalError("not register onboardingID in wiki draggable tree!")
        }
    }

    func onboardingTargetRect(for id: OnboardingID) -> CGRect {
        switch id {
        case .wikiNewbieSwipeLeft:
            return self.swipeLeftOnboardingRect
        default:
            fatalError("not register onboardingID in wiki draggable tree!")
        }
    }

    public func onboardingArrowDirection(for id: OnboardingID) -> OnboardingStyle.ArrowDirection {
        return .targetTopEdge
    }
    
    func onboardingIsAsynchronous(for id: OnboardingID) -> Bool {
        return false
    }
    
    func onboardingTapBubbleOutsideBehavior(of id: OnboardingID) -> OnboardingStyle.TapBubbleOutsideBehavior {
        switch onboardingType(of: id) {
        case .text: return .disappearAndPenetrate
        case .flow: return .disappearWithoutPenetration
        case .card: return .nothing
        }
    }
}
