//
//  ConveniencePSTN.swift
//  ByteView
//
//  Created by wulv on 2021/11/5.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import UniverseDesignIcon
import UIKit
import ByteViewCommon
import ByteViewNetwork
import ByteViewTracker
import ByteViewUI
import ByteViewSetting

enum PSTNCallAction {
    case vcCall
    case pstnCall(phone: String?)
}

extension PSTNCallAction {
    var trackEvent: String {
        switch self {
        case .vcCall:
            return "audio_video_call"
        case .pstnCall:
            return "phone_call"
        }
    }
}

extension Participant.OfflineReason {
    var trackFeedback: String? {
        switch self {
        case .refuse: return "reject"
        case .ringTimeout: return "no_answer"
        default: return "none"
        }
    }
}

struct ConveniencePSTN {

    /// 缓存用户电话号码请求结果
    static private var userPhoneResponses: [String: Result<GetTargetUserPhoneNumberResponse, Swift.Error>] = [:]

    struct Error {
        /// 用于日志输出
        let description: String
    }

    static func log(_ s: String) {
        // @wulv 建议列表扩容后日志太多，暂时下掉
//        Logger.meeting.debug("convenience pstn " + s)
    }

    /// 是否有快捷电话邀请入口
    static func enableInviteParticipant(_ target: Participant,
                                        local: Participant?,
                                        featureManager: MeetingSettingManager, meetingTenantId: String?, meetingSubType: MeetingSubType? = nil) -> Bool {
        if checkEnable(featureManager: featureManager, targetUserType: target.user.type,
                       targetParticipant: target, localParticipant: local, meetingTenantId: meetingTenantId, meetingSubType: meetingSubType) {
            return true
        }
        return false
    }

    /// 是否有快捷电话邀请入口
    static func enableInviteParticipant(_ target: ByteviewUser,
                                        local: Participant?,
                                        crossTenant: Bool,
                                        featureManager: MeetingSettingManager,
                                        meetingTenantId: String?) -> Bool {
        if checkEnable(featureManager: featureManager, targetUserType: target.type,
                       localParticipant: local, isCrossTenant: crossTenant, meetingTenantId: meetingTenantId) {
            return true
        }
        return false
    }

    /// pstn用户是否是快捷电话入会
    static func isConvenience(_ info: PSTNInfo) -> Bool {
        return isConvenience(bindId: info.bindId, bindType: info.bindType)
    }

    /// pstn用户是否是快捷电话入会
    static func isConvenience(bindId: String, bindType: PSTNInfo.BindType) -> Bool {
        return bindType == .lark && !bindId.isEmpty
    }

    /// 展示呼叫选项Action Sheet
    static func showCallActions(service: MeetingBasicService,
                                from sourceView: UIView, userId: String, animated: Bool = true, useCache: Bool = false,
                                completion: ((UIViewController?, Swift.Error?) -> Void)? = nil,
                                selected: @escaping (PSTNCallAction) -> Void) {
        if let sender = sourceView as? UIControl {
            sender.isUserInteractionEnabled = false
        }

        let showBlock: (Result<GetTargetUserPhoneNumberResponse, Swift.Error>) -> Void = { res in
            let padStyle = Display.pad && (VCScene.rootTraitCollection?.isRegular ?? true)
            let insets = padStyle ? UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0) : .zero
            // nolint-next-line: magic number
            let height: CGFloat = padStyle ? 50 : 52
            let appearance = ActionSheetAppearance(backgroundColor: padStyle ? UIColor.ud.bgFloat : UIColor.ud.bgBody,
                                                   titleColor: UIColor.ud.textPlaceholder,
                                                   separatorColor: padStyle ? UIColor.clear : UIColor.ud.lineDividerDefault,
                                                   customTextHeight: height,
                                                   tableViewInsets: insets,
                                                   contentAlignment: padStyle ? .left : .center)
            let actionSheet = ActionSheetController(appearance: appearance)
            // nolint-next-line: magic number
            let titleConfig = VCFontConfig(fontSize: padStyle ? 14 : 17, lineHeight: 24, fontWeight: .regular)
            let icon = UDIcon.getIconByKey(.callVideoOutlined, iconColor: UIColor.ud.iconN1)
            let videoCallAction = SheetAction(title: I18n.View_G_AudioVideoCall_HoverChoice,
                                              titleFontConfig: titleConfig,
                                              icon: icon,
                                              sheetStyle: .iconAndLabel,
                                              handler: { _ in
                selected(.vcCall)
            })
            actionSheet.addAction(videoCallAction)

            let phone = res.value?.phoneNumber
            let displayPhone = res.value?.displayPhoneNumber
            let phoneCallAction: SheetAction = getPhoneCallAction(phoneNumber: displayPhone,
                                                                  titleConfig: titleConfig, padStyle: padStyle) {
                selected(.pstnCall(phone: phone))
            }
            actionSheet.addAction(phoneCallAction)

            let cancelAction = SheetAction(title: I18n.View_G_CancelButton,
                                           titleFontConfig: titleConfig,
                                           sheetStyle: .cancel,
                                           handler: { _ in })
            actionSheet.addAction(cancelAction)
            // nolint-next-line: magic number
            actionSheet.regularPopoverWidth = max(actionSheet.maxIntrinsicWidth, 132)
            var bounds = sourceView.bounds
            bounds.origin.y -= 4
            bounds.size.height += 4 * 2

            let shouldHideTitle = padStyle && (actionSheet.modalPresentation == .popover)
            actionSheet.shouldHideTitle = shouldHideTitle
            actionSheet.modalPresentation = .popover

            let preferredContentSize = CGSize(width: actionSheet.padContentSizeWithoutTitle.width,
                                              height: 2 * height + insets.top + insets.bottom)
            let popoverConfig = DynamicModalPopoverConfig(sourceView: sourceView,
                                                          sourceRect: bounds,
                                                          backgroundColor: appearance.backgroundColor,
                                                          popoverSize: preferredContentSize,
                                                          permittedArrowDirections: [.up, .down])
            let regularConfig = DynamicModalConfig(presentationStyle: .popover, popoverConfig: popoverConfig, backgroundColor: .clear)
            let compactConfig = DynamicModalConfig(presentationStyle: .pan)
            // TODO: @huangtao.ht 线上RC切换时有bug
            service.router.presentDynamicModal(actionSheet, regularConfig: regularConfig, compactConfig: compactConfig,
                                              animated: animated, completion: completion)
            if let sender = sourceView as? UIControl {
                sender.isUserInteractionEnabled = true
            }
        }

        if useCache, let res = userPhoneResponses[userId] {
            showBlock(res)
        } else {
            service.httpClient.getResponse(GetTargetUserPhoneNumberRequest(userId: userId)) { res in
                Util.runInMainThread {
                    showBlock(res)
                    userPhoneResponses[userId] = res
                }
            }
        }
    }

    private static func getPhoneCallAction(phoneNumber: String?, titleConfig: VCFontConfig,
                                           padStyle: Bool, action: @escaping () -> Void) -> SheetAction {
        let icon = UDIcon.getIconByKey(.officephoneOutlined, iconColor: UIColor.ud.iconN1)
        var phoneCallAction: SheetAction
        if let phone = phoneNumber, !phone.isEmpty {
            // disable-lint: magic number
            let contentConfig = VCFontConfig(fontSize: padStyle ? 12 : 14, lineHeight: 20, fontWeight: .regular)
            phoneCallAction = SheetAction(title: I18n.View_G_PhoneCall_HoverChoice,
                                          titleFontConfig: titleConfig,
                                          titleMargin: UIEdgeInsets(top: 12, left: 12, bottom: 4, right: 12),
                                          titleHeight: 24,
                                          content: phone,
                                          contentColor: UIColor.ud.textPlaceholder,
                                          contentFontConfig: contentConfig,
                                          contentMargin: UIEdgeInsets(top: 4, left: 12, bottom: 12, right: 12),
                                          contentHeight: 20,
                                          icon: icon,
                                          sheetStyle: .withContent) { _ in
                action()
            }
            // enable-lint: magic number
        } else {
            phoneCallAction = SheetAction(title: I18n.View_G_PhoneCall_HoverChoice,
                                          titleFontConfig: titleConfig,
                                          icon: icon,
                                          sheetStyle: .iconAndLabel) { _ in
                action()
            }
        }
        return phoneCallAction
    }

    /// 是否可以快捷电话邀请(当tartgetUser不含租户信息时，必须传isCrossTenant）
    private static func checkEnable(featureManager: MeetingSettingManager, targetUserType: ParticipantType, targetParticipant: Participant? = nil,
                                    localParticipant: Participant? = nil, isCrossTenant: Bool? = nil, meetingTenantId: String?, meetingSubType: MeetingSubType? = nil) -> Bool {
        var checkers: [ConveniencePSTNCheck] = [
            ConveniencePSTNCheckSetting(featureManager: featureManager),
            ConveniencePSTNCheckType(targetUserType: targetUserType),
            ConveniencePSTNCheckTenant(isCrossTenant: isCrossTenant, targetParticipant: targetParticipant, localParticipant: localParticipant, meetingTenantId: meetingTenantId)
        ]
        if let subType = meetingSubType, let role = targetParticipant?.meetingRole {
            checkers.append(ConveniencePSTNCheckRole(meetingSubType: subType, targetUserRole: role))
        }
        checkers = checkers.sorted(by: { $0.priority.rawValue < $1.priority.rawValue })

        var can = true
        for checker in checkers {
            let (canInvite, error) = checker.checkEnable()
            if !canInvite {
                log("\(error)")
                can = false
                break
            }
        }
        return can
    }
}
