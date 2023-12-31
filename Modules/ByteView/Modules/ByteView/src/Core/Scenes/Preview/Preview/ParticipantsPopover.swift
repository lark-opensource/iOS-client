//
//  ParticipantsPopover.swift
//  ByteView
//
//  Created by chenyizhuo on 2021/3/1.
//

import Foundation
import UniverseDesignColor
import ByteViewCommon
import ByteViewNetwork
import ByteViewSetting
import ByteViewUI

final class ParticipantsPopover: NSObject {
    private typealias CommonLayout = PreviewParticipantCell.Layout
    private typealias PopoverLayout = PreviewParticipantCell.PopoverLayout

    private weak var participantVC: PreviewParticipantsViewController?
    // 唤起popover可能引发较大计算量，故使用该变量阻止节流
    private var canPopoverShow = true
    // nolint-next-line: magic number
    private let maxCellCount: CGFloat = Display.pad ? 6.5 : 5
    private let cellHeight: CGFloat = 64

    let service: MeetingBasicService
    init(service: MeetingBasicService) {
        self.service = service
    }

    func showParticipantsList(participants: [PreviewParticipant], isInterview: Bool, isWebinar: Bool, sourceView: UIView, offset: CGFloat = 0, from: UIViewController?, animated: Bool = true) {
        guard canPopoverShow else { return }
        // regular采用present（popover必须由present方式弹出）、compact采用push方式弹出
        var params = PreviewParticipantParams(participants: participants, isPopover: true, isInterview: isInterview, isWebinar: isWebinar)
        let vm = PreviewParticipantsViewModel(params: params, service: service)
        let vc = PreviewParticipantsViewController(viewModel: vm)

        if VCScene.isRegular {
                // 比较耗时，防止过频点击
            self.canPopoverShow = false
            let participantsPopoverSize = calParticipantsPopoverSize(participants: participants, isInterview: isInterview)
            self.canPopoverShow = true
            vc.modalPresentationStyle = .popover
            vc.preferredContentSize = participantsPopoverSize
            let sourceRect = CGRect(x: 0, y: 0, width: sourceView.bounds.width, height: sourceView.bounds.height + offset)
            vc.popoverPresentationController?.sourceRect = sourceRect
            vc.popoverPresentationController?.sourceView = sourceView
            vc.popoverPresentationController?.permittedArrowDirections = .up
            vc.popoverPresentationController?.delegate = self
            if let from = from {
                service.router.present(vc, from: from, animated: animated)
            } else {
                service.larkRouter.present(vc, animated: animated)
            }
        } else {
            params.isPopover = false
            if let from = from {
                service.router.push(vc, from: from, animated: animated)
            } else {
                service.larkRouter.push(vc, animated: animated)
            }
        }
        participantVC = vc
    }

    func resetParticipantsPopover() -> Bool {
        guard let vc = participantVC else { return false }
        vc.dismissSelf()
        return true
    }

    private func calParticipantsPopoverSize(participants: [PreviewParticipant], isInterview: Bool) -> CGSize {
        let sponsorText = I18n.View_M_OrganizerLabel
        let lineHight: CGFloat = 20
        let sponsorInset = CommonLayout.sponsorInset * 2
        let sponsorWidth = sponsorText.vc.boundingWidth(height: lineHight, font: CommonLayout.sponsorFont) + sponsorInset
        let externalLabel = I18n.View_G_ExternalLabel
        let externalInset = CommonLayout.externalInset * 2
        let externalWidth = externalLabel.vc.boundingWidth(height: lineHight, font: CommonLayout.externalFont) + externalInset

        // 关联标签 fg 命中，且有外部标签，默认宽度为 320，其他情况动态计算
        let isRelationTagEnabled = service.setting.isRelationTagEnabled
        let defaultMaxWidth = 320.0

        // 计算规则：实际宽度 <= 320 时自适应
        var maxWidth: CGFloat = 0
        // 模拟器1000个数据计算耗时：0.05s左右
        let startTime = Date().timeIntervalSince1970
        PreviewMeetingViewModel.logger.info("start calculating popover size; participants count:\(participants.count), fg:\(isRelationTagEnabled)")

        var externalTagCount = 0
        let accountInfo = service.accountInfo
        for item in participants {
            let nameHeight = PopoverLayout.nameHeight
            let nameWidth = item.userName.vc.boundingWidth(height: nameHeight, font: PopoverLayout.nameFont)
            var width = CommonLayout.avatarLeftOffset
                + PopoverLayout.avatarSize
                + PopoverLayout.nameLeftOffset
                + nameWidth
                + CommonLayout.cellRightOffset

            if item.isLarkGuest {
                if isInterview {
                    width += I18n.View_G_CandidateBracket.vc.boundingWidth(height: nameHeight, font: PopoverLayout.nameFont)
                } else {
                    width += I18n.View_M_GuestParentheses.vc.boundingWidth(height: nameHeight, font: PopoverLayout.nameFont)
                }
            }

            var number = 0
            if item.showDevice {
                number += 1
                width += CommonLayout.deviceSize
            }
            if item.isSponsor {
                number += 1
                width += sponsorWidth
            }
            if PreviewParticipantsViewModel.isExternalParticipant(item, accountInfo: accountInfo) {
                externalTagCount += 1
                number += 1
                width += externalWidth
            }
            if number > 0 {
                width += CommonLayout.tagLeftOffset
                width += (CommonLayout.tagSpacing * CGFloat((number - 1)))
            }
            width += 5

            maxWidth = max(maxWidth, width)
            if width >= defaultMaxWidth {
                break
            }
        }
        let cellCount: CGFloat = min(CGFloat(participants.count), maxCellCount)
        let sizeWidth: CGFloat
        if isRelationTagEnabled && externalTagCount > 0 {
            sizeWidth = defaultMaxWidth
        } else {
            sizeWidth = CGFloat.minimum(maxWidth, defaultMaxWidth)
        }
        let size = CGSize(width: sizeWidth, height: CGFloat(cellCount * cellHeight + 4 * 2))

        let endTime = Date().timeIntervalSince1970
        PreviewMeetingViewModel.logger.info("end calculating popover size; time:\(endTime - startTime); result:\(size)")

        return size
    }
}

extension ParticipantsPopover: UIPopoverPresentationControllerDelegate {
    func prepareForPopoverPresentation(_ popoverPresentationController: UIPopoverPresentationController) {
        popoverPresentationController.containerView?.layer.ud.setShadowColor(UIColor.ud.N1000.withAlphaComponent(0.3) & UIColor.ud.staticBlack.withAlphaComponent(0.8))
        popoverPresentationController.containerView?.layer.shadowRadius = 100
        popoverPresentationController.containerView?.layer.shadowOffset = CGSize(width: 0, height: 10)
        popoverPresentationController.containerView?.layer.shadowOpacity = 1
        popoverPresentationController.containerView?.backgroundColor = UIColor.clear
    }
}
