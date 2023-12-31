//
//  SpaceHomeViewController+Onboarding.swift
//  SKECM
//
//  Created by Weston Wu on 2020/12/2.
//

import Foundation
import SKFoundation
import SKCommon
import SKResource
import SKUIKit

// MARK: - OnboardingDelegate
extension SpaceHomeViewController: OnboardingDelegate {
    public func onboardingDidAppear(_ id: OnboardingID) {
        showingOnboarding = true
    }

    public func onboardingAcknowledge(_ id: OnboardingID) {
        let action = onboardingAcknowledgedBlocks[id]
        action?()
        showingOnboarding = false
        reloadData()
    }

    public func onboardingSkip(_ id: OnboardingID) {
        showingOnboarding = false
        reloadData()
    }
}

extension SpaceHomeViewController: OnboardingFlowDataSources {
    public func onboardingType(of id: OnboardingID) -> OnboardingType {
        switch id {
        case .spaceHomeNewbieNavigation,
             .spaceHomeNewbieCreateDocument,
             .spaceHomeNewbieCreateTemplate,
             .spaceHomeCloudDrive:
            return .flow
        case .spaceHomeNewShareSpace:
            return .text
        default:
            fatalError("记得明确新引导类型")
        }
    }

    public func onboardingTapBubbleOutsideBehavior(of id: OnboardingID) -> OnboardingStyle.TapBubbleOutsideBehavior {
        switch id {
        case .spaceHomeNewbieNavigation,
             .spaceHomeNewbieCreateDocument,
             .spaceHomeNewbieCreateTemplate,
             .spaceHomeCloudDrive:
            return .nothing
        default:
            return .disappearAndPenetrate
        }
    }

    public func onboardingHostViewController(for id: OnboardingID) -> UIViewController {
        onboardingHostViewControllers[id]!
    }

    public func onboardingTitle(for id: OnboardingID) -> String? {
        switch id {
        case .spaceHomeNewShareSpace:
            return BundleI18n.SKResource.CreationMobile_ECM_ShareWithMe_Tab
        case .spaceHomeCloudDrive:
            return BundleI18n.SKResource.LarkCCM_NewCM_Onboarding_Drive_Title
        default:
            return nil
        }
    }


    public func onboardingHint(for id: OnboardingID) -> String {
        onboardingHints[id] ?? ""
    }

    public func onboardingIndex(for id: OnboardingID) -> String? {
        onboardingIndexes[id]
    }

    public func onboardingSkipText(for id: OnboardingID) -> String? {
        switch id {
        case .spaceHomeNewbieCreateTemplate, .spaceHomeNewShareSpace, .spaceHomeCloudDrive:
            return nil
        default:
            return BundleI18n.SKResource.Doc_Facade_Skip
        }
    }

    public func onboardingAckText(for id: OnboardingID) -> String {
        switch id {
        case .spaceHomeNewbieCreateTemplate, .spaceHomeNewShareSpace:
            return BundleI18n.SKResource.Onboarding_Got_It
        case .spaceHomeCloudDrive:
            return BundleI18n.SKResource.LarkCCM_CM_Drive_Onbd_GotIt_Mob
        default:
            return BundleI18n.SKResource.Doc_Facade_Next
        }
    }

    public func onboardingTargetRect(for id: OnboardingID) -> CGRect {
        onboardingTargetRects[id] ?? .zero
    }

    public func onboardingHollowStyle(for id: OnboardingID) -> OnboardingStyle.Hollow {
        return .roundedRect(8)
    }

    public func onboardingBleeding(for id: OnboardingID) -> CGFloat {
        switch id {
        case .spaceHomeNewbieNavigation:
            return 0
        case .spaceHomeNewbieCreateDocument:
            return 0
        case .spaceHomeNewbieCreateTemplate:
            return 0
        default:
            return 4
        }
    }

    public func onboardingArrowDirection(for id: OnboardingID) -> OnboardingStyle.ArrowDirection {
        switch id {
        case .spaceHomeNewbieNavigation:
            return .targetBottomEdge
        case .spaceHomeNewbieCreateDocument:
            return .targetTopEdge
        case .spaceHomeNewbieCreateTemplate:
            return .targetTopEdge
        case .spaceHomeNewShareSpace:
            return .targetBottomEdge
        case .spaceHomeCloudDrive:
            return .targetBottomEdge
        default:
            return .targetTopEdge
        }
    }
    
    public func onboardingImage(for id: OnboardingID) -> UIImage? {
        switch id {
        case .spaceHomeCloudDrive:
            guard SKDisplay.pad, view.isMyWindowRegularSize() else {
                return nil
            }
            return BundleResources.SKResource.Space.Home.new_home_ipad_cloud_driver_onboarding
        default:
            return nil
        }
    }
}
