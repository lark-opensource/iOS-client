//
//  ParticipantsPopover.swift
//  ByteView
//
//  Created by chenyizhuo on 2021/3/1.
//

import UIKit
import ByteViewCommon
import ByteViewNetwork
import ByteViewUI
import UniverseDesignColor

class ParticipantsPopover: NSObject {
    private(set) weak var participantVC: UIViewController?

    var didSelectCellCallback: ((PreviewParticipant, UIViewController?) -> Void)?
    private var isPopover = false
    let viewModel: MeetTabViewModel
    init(viewModel: MeetTabViewModel) {
        self.viewModel = viewModel
        super.init()
    }

    func showParticipantsList(participants: [PreviewParticipant], isInterview: Bool, isWebinar: Bool, from: UIViewController, animated: Bool = true) {
        // regular采用present（popover必须由present方式弹出）、compact采用push方式弹出
        var body = TabPreviewParticipantsBody(participants: participants, isPopover: false, isInterview: isInterview, isWebinar: isWebinar, selectCellAction: didSelectCellCallback)
        if from.traitCollection.horizontalSizeClass == .regular {
            body.isPopover = true
            guard let vc = viewModel.router?.previewParticipantsViewController(body: body) else {
                return
            }
            from.presentDynamicModal(vc,
                                     regularConfig: .init(presentationStyle: .formSheet, needNavigation: true),
                                     compactConfig: .init(presentationStyle: .pageSheet, needNavigation: true))
            participantVC = vc
            isPopover = true
        } else {
            guard let vc = viewModel.router?.previewParticipantsViewController(body: body) else {
                return
            }
            from.presentDynamicModal(vc,
                                     regularConfig: .init(presentationStyle: .formSheet, needNavigation: true),
                                     compactConfig: .init(presentationStyle: .pageSheet, needNavigation: true))
            participantVC = vc
            isPopover = false
        }
    }

    func resetParticipantsPopover() -> Bool {
        guard let vc = participantVC else { return false }
        if isPopover {
            vc.view.alpha = 0
            vc.dismiss(animated: false)
        } else {
            vc.navigationController?.popViewController(animated: false)
        }
        return true
    }

    // 修改布局需要同步修改popoverSize计算逻辑(PreviewMeetingViewController+Participants)
    struct PopoverLayout {
        static let avatarSize: CGFloat = 32
        static let nameLeftOffset: CGFloat = 8
        static let nameHeight: CGFloat = 20
        static let nameFont: UIFont = UIFont.systemFont(ofSize: 14)
    }

    struct Layout {
        static let avatarLeftOffset: CGFloat = 16
        static let deviceSize: CGFloat = 16
        static let tagLeftOffset: CGFloat = 8
        static let tagSpacing: CGFloat = 6
        static let cellRightOffset: CGFloat = 16

        static let sponsorFont: UIFont = UIFont.systemFont(ofSize: 12, weight: .medium)
        static let sponsorText: String = I18n.View_M_OrganizerLabel
        static let sponsorInset: CGFloat = 4

        static let externalFont: UIFont = UIFont.systemFont(ofSize: 12.0, weight: .medium)
        static let externalText: String = I18n.View_G_ExternalLabel
        static let externalInset: CGFloat = 4
    }
}

extension PreviewParticipant {
    func isExternal(account: AccountInfo?) -> Bool {
        guard let localParticipant = account else { return false }
        if self.userId == localParticipant.userId { // 自己
            return false
        }
        if localParticipant.tenantTag != .standard { // 自己是小 B 用户，则不关注 external
            return false
        }
        if self.isLarkGuest {
            return false
        }
        // 当前用户租户 ID 未知
        if self.tenantId == "" || self.tenantId == "-1" {
            return false
        }
        if participantType == .larkUser || participantType == .room || participantType == .neoUser || participantType == .neoGuestUser || participantType == .standaloneVcUser {
            return self.tenantId != localParticipant.tenantId
        } else {
            return false
        }
    }
}

extension ParticipantsPopover: UIPopoverPresentationControllerDelegate {
    func prepareForPopoverPresentation(_ popoverPresentationController: UIPopoverPresentationController) {
        popoverPresentationController.containerView?.layer.ud.setShadowColor(UIColor.ud.N1000.dynamicColor.withAlphaComponent(0.3) & UIColor.ud.staticBlack.withAlphaComponent(0.8))
        popoverPresentationController.containerView?.layer.shadowRadius = 100
        popoverPresentationController.containerView?.layer.shadowOffset = CGSize(width: 0, height: 10)
        popoverPresentationController.containerView?.layer.shadowOpacity = 1
        popoverPresentationController.containerView?.backgroundColor = UIColor.clear
    }
}
