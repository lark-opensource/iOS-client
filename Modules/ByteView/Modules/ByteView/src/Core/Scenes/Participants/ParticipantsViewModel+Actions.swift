//
//  ParticipantsViewModel+Actions.swift
//  ByteView
//
//  Created by huangshun on 2019/8/3.
//

import Foundation
import RxSwift
import LarkLocalizations
import UniverseDesignIcon
import UIKit
import ByteViewCommon
import ByteViewNetwork
import ByteViewTracker
import ByteViewUI

/// 操作参会人点击来源
/// 更多按钮和ActionSheetVC的距离规则：除了各场景基础距离外，如果列表中只有1项，额外增加2pt
enum TapMeetingParticipantFromSource {
    /// 单流放大，基础距离4pt
    case singleRow
    /// 会中宫格流，基础距离2pt
    case commonGrid
    /// 共享场景宫格流，基础距离0pt
    case singleVideo
}

extension ParticipantsViewModel {

    private typealias I18n = BundleI18n.ByteView

    func tapShareView(sourceView: UIView) -> AlignPopoverViewController? {
        MeetingTracks.trackInviteInParticipantsClick()
        MeetingTracksV2.trackClickShareButton(isSharingContent: meeting.shareData.isSharingContent,
                                              isMinimized: false,
                                              isMore: false)

        if participantListState != .none, let text = participantListState.toastText {
            Toast.show(text)
            return nil
        }

        let copyLink: () -> Void = { [weak self] in
            guard let self = self else { return }
            if self.meeting.setting.isMeetingLocked {
                Toast.show(I18n.View_MV_MeetingLocked_Toast)
                return
            }
            ParticipantTracks.trackCopyMeetingInfo()
            MeetingTracksV2.trackCopyMeetingInfoClick()
            CopyMeetingInviteLinkAction.copy(meeting: self.meeting, token: .participantCopyMeetingContent)
        }
        let share: () -> Void = { [weak self] in
            guard let self = self else { return }
            ParticipantTracks.trackShare()
            self.shareViaCall()
        }

        let invitePhone: () -> Void = { [weak self] in
            guard let self = self else { return }
            MeetingTracksV2.trackInvitePhoneClick()
            self.inviteViaPhone()
        }

        let inviteSIP: () -> Void = { [weak self] in
            guard let self = self else { return }
            MeetingTracksV2.trackInviteSIPClick()
            self.inviteViaSIP()
        }

        let appearance = ActionSheetAppearance(backgroundColor: UIColor.ud.bgFloat,
                                               contentViewColor: UIColor.ud.bgFloat,
                                               separatorColor: UIColor.clear,
                                               modalBackgroundColor: UIColor.ud.bgMask,
                                               customTextHeight: 50.0,
                                               tableViewCornerRadius: 0.0)

        let actionSheetVC = ActionSheetController(appearance: appearance)
        actionSheetVC.modalPresentation = .alwaysPopover

        if meeting.setting.isShareCardEnabled {
            actionSheetVC.addAction(SheetAction(title: I18n.View_M_ShareToChat,
                                                titleFontConfig: VCFontConfig.bodyAssist,
                                                showBottomSeparator: false,
                                                sheetStyle: .iconAndLabel,
                                                handler: { _ in
                share()
            }))
        }
        if meeting.setting.isCopyLinkEnabled {
            actionSheetVC.addAction(SheetAction(title: I18n.View_M_CopyJoiningInfo,
                                                titleFontConfig: VCFontConfig.bodyAssist,
                                                showBottomSeparator: false,
                                                sheetStyle: .iconAndLabel,
                                                handler: { _ in
                copyLink()
            }))
        }
        if meeting.setting.showsPstn {
            actionSheetVC.addAction(SheetAction(title: I18n.View_M_InviteByPhone,
                                                titleFontConfig: VCFontConfig.bodyAssist,
                                                showBottomSeparator: false,
                                                sheetStyle: .iconAndLabel,
                                                handler: { _ in
                invitePhone()
            }))
        }
        if meeting.setting.showsSip {
            actionSheetVC.addAction(SheetAction(title: I18n.View_G_InviteBySIP,
                                                titleFontConfig: VCFontConfig.bodyAssist,
                                                showBottomSeparator: false,
                                                sheetStyle: .iconAndLabel,
                                                handler: { _ in
                inviteSIP()
            }))
        }

        let width = actionSheetVC.maxIntrinsicWidth
        let height = actionSheetVC.intrinsicHeight
        let anchor = AlignPopoverAnchor(sourceView: sourceView,
                                        alignmentType: .right,
                                        contentWidth: .fixed(width),
                                        contentHeight: height,
                                        contentInsets: UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 0),
                                        positionOffset: CGPoint(x: 0, y: 3),
                                        cornerRadius: 8.0,
                                        borderColor: UIColor.ud.lineBorderCard,
                                        dimmingColor: UIColor.clear,
                                        containerColor: UIColor.ud.bgFloat)

        MeetingTracks.trackShowInviteInParticipants()
        return AlignPopoverManager.shared.present(viewController: actionSheetVC, anchor: anchor)
    }

    func tapMuteAllViewMoreButton(sourceView: UIView) -> AlignPopoverViewController {
        let appearance = ActionSheetAppearance(backgroundColor: UIColor.ud.bgBody,
                                               contentViewColor: UIColor.ud.bgBody,
                                               separatorColor: UIColor.clear,
                                               modalBackgroundColor: UIColor.ud.bgMask,
                                               customTextHeight: 50.0,
                                               tableViewCornerRadius: 0.0)

        let actionSheetVC = ActionSheetController(appearance: appearance)
        actionSheetVC.modalPresentation = .alwaysPopover
        actionSheetVC.addAction(SheetAction(title: I18n.View_G_AskAllToUnmute_Button,
                                            titleFontConfig: VCFontConfig.bodyAssist,
                                            showBottomSeparator: false,
                                            handler: { [weak self] _ in
                                                if let self = self {
                                                    BreakoutRoomTracksV2.muteAll(self.meeting, isMute: false)
                                                    self.unMuteAll()
                                                }
                                            }))
        actionSheetVC.addAction(SheetAction(title: I18n.View_M_ReclaimHost,
                                            titleFontConfig: VCFontConfig.bodyAssist,
                                            showBottomSeparator: false,
                                            handler: { [weak self] _ in
                                                self?.reclaimHost()
                                            }))

        let height = actionSheetVC.intrinsicHeight
        let anchor = AlignPopoverAnchor(sourceView: sourceView,
                                        highlightSourceView: true,
                                        arrowDirection: .down,
                                        contentWidth: .equalToSourceView,
                                        contentHeight: height,
                                        contentInsets: UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 0),
                                        positionOffset: CGPoint(x: 0, y: -4),
                                        cornerRadius: 8.0,
                                        borderColor: UIColor.ud.lineBorderCard,
                                        dimmingColor: UIColor.clear,
                                        containerColor: UIColor.ud.bgBody)
        return AlignPopoverManager.shared.present(viewController: actionSheetVC, anchor: anchor)
    }
}

extension ParticipantsViewModel: MeetingNoticeListener {

    func removeFromLobby(_ model: LobbyParticipantCellModel, completion: (() -> Void)? = nil) {
        guard let displayName = model.displayName else {
            // 信息未拉取到
            Self.logger.info("userInfo is nil")
            return
        }
        removeFromLobby(name: displayName, users: [model.lobbyParticipant], completion: completion)
    }

    private func removeFromLobby(name: String, users: [LobbyParticipant], completion: (() -> Void)? = nil) {
        ByteViewDialog.Builder()
            .title(I18n.View_M_RemoveParticipantFromLobby(name))
            .message(nil)
            .leftTitle(I18n.View_G_CancelButton)
            .rightTitle(I18n.View_G_ConfirmButton)
            .rightHandler({ [weak self] _ in
                guard let self = self else { return }
                if self.isWebinar {
                    let paneCount = self.lobbySectionModel?.realItems.count ?? 0
                    let attendeeCount = self.attendeeDataSource.first(where: { $0.itemType == .lobby })?.realItems.count ?? 0
                    LobbyTracks.trackWebinarRemoveLobby(paneCount: paneCount, attendeeCount: attendeeCount, fromAttendee: users.first?.participantMeetingRole == .webinarAttendee)
                } else {
                    LobbyTracks.trackRemoveLobby()
                }
                let request = VCManageApprovalRequest(meetingId: self.meeting.meetingId,
                                                      breakoutRoomId: self.meeting.setting.breakoutRoomId,
                                                      approvalType: .meetinglobby,
                                                      approvalAction: .reject,
                                                      users: users.map({ $0.user }))
                self.httpClient.send(request)
                completion?()
            })
            .needAutoDismiss(true)
            .show()
    }

    func admitInLobby(_ lobbyParticipant: LobbyParticipant) {
        guard !lobbyParticipant.isInApproval else { return }
        let request = VCManageApprovalRequest(meetingId: meeting.meetingId,
                                              breakoutRoomId: meeting.setting.breakoutRoomId,
                                              approvalType: .meetinglobby,
                                              approvalAction: .pass,
                                              users: [lobbyParticipant.user])
        httpClient.send(request)
    }

    func shareViaCall() {
        if meeting.setting.isMeetingLocked {
            Toast.show(I18n.View_MV_MeetingLocked_Toast)
            return
        }
        MeetingTracks.trackShowInviteTabShare()
        if let vc = self.router.topMost {
            // pageSheet弹出的视图系统方向主要取决于底部VC ，所以理论样式一定要支持所有方向，iOS 15及以下暂时强制转成竖屏
            if #unavailable(iOS 16.0) {
                UIDevice.updateDeviceOrientationForViewScene(nil, to: .portrait, animated: true)
            }
            self.service.messenger.shareMeetingCard(meetingId: meetingId, from: vc, source: .participants) { [weak self] in
                return self?.meeting.setting.isMeetingLocked != true
            }
        }
    }

    func inviteViaPhone() {
        if participantListState != .none, let text = participantListState.toastText {
            Toast.show(text)
            return
        }
        MeetingTracks.trackShowInviteTabPhone()

        if setting.canInvitePstn {
            let viewModel = PSTNInviteViewModel(meeting: self.meeting)
            let viewController = PSTNInviteViewController(viewModel: viewModel)
            router.presentDynamicModal(viewController,
                                              regularConfig: .init(presentationStyle: .formSheet, needNavigation: true),
                                              compactConfig: .init(presentationStyle: .pageSheet, needNavigation: true))
        } else {
            let viewController = PSTNOpenInviteViewController(meeting: self.meeting)
            router.presentDynamicModal(viewController,
                                              regularConfig: .init(presentationStyle: .formSheet, needNavigation: true),
                                              compactConfig: .init(presentationStyle: .pageSheet, needNavigation: true))
        }
    }

    func inviteViaSIP() {
        if participantListState != .none, let text = participantListState.toastText {
            Toast.show(text)
            return
        }
        MeetingTracks.trackShowInviteTabSIP()
        //let viewModel = SIPInviteViewModel(meetingID: self.meeting.meetingId)
        //let viewController = SIPInviteViewController(viewModel: viewModel)
        let vm = SIPDialViewModel(meeting: self.meeting)
        let vc = SIPDialAggViewController(viewModel: vm)
        router.presentDynamicModal(vc,
                                   regularConfig: .init(presentationStyle: .formSheet, needNavigation: true),
                                   compactConfig: .init(presentationStyle: .pageSheet, needNavigation: true))
    }

    func createInMeetCellModel(_ participant: Participant, duplicatedParticipantIds: Set<String>, hasCohostAuthority: Bool, hostEnabled: Bool) -> InMeetParticipantCellModel {
        let model = InMeetParticipantCellModel.create(with: participant,
                                                      userInfo: nil,
                                                      meeting: meeting,
                                                      hasCohostAuthority: hasCohostAuthority,
                                                      hostEnabled: hostEnabled,
                                                      isDuplicated: duplicatedParticipantIds.contains(participant.user.id),
                                                      magicShareDocument: magicShareDocument)
        return model
    }

    func createInvitedCellModel(_ participant: Participant, hasCohostAuthority: Bool, meetingSubType: MeetingSubType) -> InvitedParticipantCellModel {
        let model = InvitedParticipantCellModel.create(with: participant,
                                                       userInfo: nil,
                                                       meeting: meeting,
                                                       hasCohostAuthority: hasCohostAuthority,
                                                       meetingSubType: meetingSubType)
        return model
    }

    func createLobbyCellModel(_ lobbyParticipant: LobbyParticipant, showRoomInfo: Bool) -> LobbyParticipantCellModel {
        let model = LobbyParticipantCellModel.create(with: lobbyParticipant,
                                                     userInfo: nil,
                                                     showRoomInfo: showRoomInfo,
                                                     meeting: meeting)
        return model
    }

    func createSearchCellModel(_ searchBox: ParticipantSearchBox, duplicatedParticipantIds: Set<String>, hasCohostAuthority: Bool, hostEnabled: Bool, meetingSubType: MeetingSubType) -> SearchParticipantCellModel {
        let  model = SearchParticipantCellModel.create(with: searchBox,
                                                       meeting: meeting,
                                                       hasCohostAuthority: hasCohostAuthority,
                                                       hostEnabled: hostEnabled,
                                                       meetingSubType: meetingSubType,
                                                       duplicatedParticipantIds: duplicatedParticipantIds,
                                                       magicShareDocument: magicShareDocument)
        return model
    }

    func tapInMeetingParticipantCell(sourceView: UIView, participant: Participant, displayName: String, originalName: String, source: ParticipantActionSource) {
        if let vc = actionService.actionVC(participant: participant, info: .init(displayName: displayName, originalName: originalName), source: source) {
            if let cellView = sourceView as? BaseParticipantCell {
                var sourceView: UIView
                var bounds: CGRect
                // 首先尝试在cell被点击的point处弹出popover
                if let hitPoint = cellView.hitPoint {
                    sourceView = cellView
                    bounds = CGRect(x: hitPoint.x - 1, y: hitPoint.y - 1, width: 2, height: 2)
                    // 只能使用一次
                    cellView.hitPoint = nil
                } else {
                    if let inMeetCell = cellView as? InMeetParticipantCell {
                        // 若hitPoint为空（获取失败），则默认在麦克风icon处弹出
                        sourceView = inMeetCell.microphoneIcon
                    } else if let searchCell = cellView as? SearchParticipantCell {
                        sourceView = searchCell.eventButton
                    } else {
                        sourceView = cellView
                    }
                    let originBounds = sourceView.bounds
                    bounds = CGRect(x: originBounds.minX - 4,
                                    y: originBounds.minY - 4,
                                    width: originBounds.width + 8,
                                    height: originBounds.height + 8)
                }
                let margins = ParticipantActionViewController.Layout.popoverLayoutMargins
                let config = DynamicModalPopoverConfig(sourceView: sourceView,
                                                       sourceRect: bounds,
                                                       backgroundColor: .ud.bgFloat,
                                                       popoverSize: .zero,
                                                       popoverLayoutMargins: .init(edges: margins))
                presentUsingDynamicModal(vc, popoverConfig: config)
            }
        }
    }

    func manipulateOtherSearchParticipants(cellView: SearchParticipantCell,
                                           searchCellModel: SearchParticipantCellModel,
                                           manipulateCompletion: (() -> Void)? = nil) {
        let searchBox = searchCellModel.searchBox

        // 点击inviting user cell
        let tapInvitingUser: (() -> ParticipantActionViewController?) = { [weak self] in
            guard let self = self else { return nil }
            guard let participant = searchBox.participant, let name = searchBox.name else { return nil }
            // 确保有权限操作
            guard self.meeting.setting.canCancelInvite || (self.meeting.account == participant.inviter) else {
                return nil
            }

            let displayName = participant.settings.nickname.isEmpty ? name : participant.settings.nickname
            return self.actionService.actionVC(participant: participant, info: .init(displayName: displayName, originalName: displayName), source: .invitee, dataCallBack: {_, _ in manipulateCompletion?() })
        }

        // 操作等候室用户
        let tapWaitingUser: (() -> ParticipantActionViewController?) = { [weak self] in
            // 确保有权限操作
            guard let self = self,
                  self.meeting.setting.canOperateLobbyParticipant,
                  let lobbyParticipant = searchBox.lobbyParticipant,
                  let displayName = searchCellModel.displayName else {
                return nil
            }
            return self.actionService.actionVC(participant: .init(meetingId: "", id: "", type: .unknown, deviceId: "", interactiveId: ""),
                                               lobbyParticipant: lobbyParticipant,
                                               info: .init(displayName: displayName, originalName: displayName),
                                               source: .lobby,
                                               dataCallBack: { [weak self] (type, dict) in
                guard let self = self else { return }
                switch type {
                case .lobbyAdmit:
                    BreakoutRoomTracksV2.admitLobby(self.meeting)
                    LobbyTracks.trackAdmitedWaitingParticipantOfLobby(userID: lobbyParticipant.user.id,
                                                                      deviceID: lobbyParticipant.user.deviceId,
                                                                      isSearch: true,
                                                                      meeting: self.meeting)
                    if self.isWebinar {
                        let paneCount = self.lobbySectionModel?.realItems.count ?? 0
                        let attendeeCount = self.attendeeDataSource.first(where: { $0.itemType == .lobby })?.realItems.count ?? 0
                        LobbyTracks.trackWebinarAdmitLobby(paneCount: paneCount, attendeeCount: attendeeCount, fromAttendee: lobbyParticipant.participantMeetingRole == .webinarAttendee)
                    } else {
                        LobbyTracks.trackAdmitLobby()
                    }
                    ParticipantTracks.trackCoreManipulation(isSelf: false,
                                                            description: "lobby - " + I18n.View_M_AdmitButton,
                                                            uid: lobbyParticipant.user.id,
                                                            did: lobbyParticipant.user.deviceId)
                case .lobbyRemove:
                    if dict["action"] as? String == "confirm" {
                        if self.isWebinar {
                            let paneCount = self.lobbySectionModel?.realItems.count ?? 0
                            let attendeeCount = self.attendeeDataSource.first(where: { $0.itemType == .lobby })?.realItems.count ?? 0
                            LobbyTracks.trackWebinarRemoveLobby(paneCount: paneCount, attendeeCount: attendeeCount, fromAttendee: lobbyParticipant.participantMeetingRole == .webinarAttendee)
                        } else {
                            LobbyTracks.trackRemoveLobby()
                        }
                    }
                default: break
                }
                manipulateCompletion?()
            })
        }

        var actionVC: ParticipantActionViewController?
        switch searchBox.state {
        case .inviting:
            actionVC = tapInvitingUser()
        case .waiting:
            actionVC = tapWaitingUser()
        default:
            return
        }

        guard let actionVC = actionVC else { return }

        var sourceView: UIView
        var bounds: CGRect
        // 首先尝试在cell被点击的point处弹出popover
        if let hitPoint = cellView.hitPoint {
            sourceView = cellView
            bounds = CGRect(x: hitPoint.x - 1, y: hitPoint.y - 1, width: 2, height: 2)
            // 只能使用一次
            cellView.hitPoint = nil
        } else {
            sourceView = cellView.eventButton
            let originBounds = cellView.eventButton.bounds
            bounds = CGRect(x: originBounds.minX - 4,
                            y: originBounds.minY - 4,
                    width: originBounds.width + 8,
                    height: originBounds.height + 8)
        }
        let config = DynamicModalPopoverConfig(sourceView: sourceView,
                                               sourceRect: bounds,
                                               backgroundColor: .ud.bgFloat,
                                               popoverSize: .zero)
        presentUsingDynamicModal(actionVC, popoverConfig: config)
    }

    func transionToApplyCoordinationAuthPage(_ user: SearchedUser) {
        ByteViewDialog.Builder()
            .id(.onewayContact)
            .title(I18n.View_M_AddContactNow)
            .message(I18n.View_G_AddToContactsDialogContent(user.name))
            .leftTitle(I18n.View_G_CancelButton)
            .rightTitle(I18n.View_G_Send)
            .rightHandler({ [weak self] _ in
                if let self = self {
                    let vm = PermissionApplyViewModel(userId: user.id, meeting: self.meeting)
                    let vc = PermissionApplyViewController(viewModel: vm)
                    self.router.push(vc)
                }
            })
            .show()
    }

    private func presentUsingDynamicModal(_ vc: ParticipantActionViewController,
                                          popoverConfig: DynamicModalPopoverConfig) {
        let regularConfig = DynamicModalConfig(presentationStyle: .popover, popoverConfig: popoverConfig, backgroundColor: .clear)
        router.presentDynamicModal(vc, regularConfig: regularConfig, compactConfig: .init(presentationStyle: .pan))
    }

    private func canInvite(_ item: ParticipantSearchBox, autoHandleError: Bool = true) -> Bool {
        if let item = item as? ParticipantSearchUserBox {
            if item.user.isCollaborationTypeLimited {
                // 自己屏蔽或者被对方屏蔽
                if autoHandleError {
                    if item.user.collaborationType == .blocked || item.user.collaborationType == .beBlocked {
                        let message = item.user.collaborationType == .blocked ?
                        I18n.View_G_NoPermissionsToCallBlocked :
                        I18n.View_G_NoPermissionsToCall
                        Toast.show(message)
                    } else if item.user.collaborationType == .requestNeeded {
                        // 需要申请
                        transionToApplyCoordinationAuthPage(item.user)
                    }
                }
                return false
            } else {
                if item.disable {
                    if let message = item.disabledMessage, autoHandleError {
                        Toast.show(message)
                    }
                    return false
                }
                return true
            }
        } else {
            if item.disable {
                if let message = item.disabledMessage, autoHandleError {
                    Toast.show(message)
                }
                return false
            }
            return true
        }
    }
}

// MARK: - Button Actions
extension ParticipantsViewModel {

    func admitAllForLobby(forAttendee: Bool = false) {
        BreakoutRoomTracksV2.admitAllLobby(meeting)
        LobbyTracks.trackAdmiteAllWaitingParticipantsOfLobby(meeting)
        if isWebinar {
            let paneCount = lobbySectionModel?.realItems.count ?? 0
            let attendeeCount = attendeeDataSource.first(where: { $0.itemType == .lobby })?.realItems.count ?? 0
            LobbyTracks.trackWebinarAdmitAllLobby(paneCount: paneCount, attendeeCount: attendeeCount, fromAttendee: forAttendee)
        } else {
            LobbyTracks.trackAdmitAllLobby()
        }
        let request = VCManageApprovalRequest(meetingId: meeting.meetingId, breakoutRoomId: meeting.setting.breakoutRoomId,
                                              approvalType: .meetinglobby, approvalAction: .allPass, users: [])
        httpClient.send(request)
    }

    func admitLobby(with lobbyParticipant: LobbyParticipant) {
        BreakoutRoomTracksV2.admitLobby(meeting)
        LobbyTracks.trackAdmitedWaitingParticipantOfLobby(userID: lobbyParticipant.user.id,
                                                          deviceID: lobbyParticipant.user.deviceId,
                                                          isSearch: false,
                                                          meeting: meeting)
        if isWebinar {
            let paneCount = lobbySectionModel?.realItems.count ?? 0
            let attendeeCount = attendeeDataSource.first(where: { $0.itemType == .lobby })?.realItems.count ?? 0
            LobbyTracks.trackWebinarAdmitLobby(paneCount: paneCount, attendeeCount: attendeeCount, fromAttendee: lobbyParticipant.participantMeetingRole == .webinarAttendee)
        } else {
            LobbyTracks.trackAdmitLobby()
        }
        ParticipantTracks.trackCoreManipulation(isSelf: false,
                                                description: "lobby - Admit",
                                                uid: lobbyParticipant.user.id,
                                                did: lobbyParticipant.user.deviceId)
        admitInLobby(lobbyParticipant)
    }

    func convertToInvitePSTN(with model: InvitedParticipantCellModel) {
        guard let displayName = model.displayName else {
            // 信息未拉取到
            Self.logger.info("userInfo is nil")
            return
        }
        // 先取消音视频呼叫，再呼叫pstn
        cancelInviteUser(participant: model.participant)
        meeting.participant.invitePSTN(userId: model.participant.user.id, name: displayName)
        ParticipantTracks.trackConvertToInvitePSTN(suggestionCount: suggestionDataSource.count)
    }

    func cancelInvited(with model: InvitedParticipantCellModel) {
        ParticipantTracks.trackCancelCalling(participant: model.participant, isSearch: false)
        cancelInviteUser(participant: model.participant)
        ParticipantTracks.trackCoreManipulation(isSelf: false,
                                                description: "CancelCalling",
                                                participant: model.participant)
        ParticipantTracks.trackCancelInvite(isConveniencePSTN: model.isConveniencePSTN, suggestionCount: suggestionDataSource.count)
    }

    func cancelInviteUser(participant: Participant) {
        httpClient.meeting.cancelInviteUser(participant.user, meetingId: meetingId, role: meetingRole)
    }

    func cancelAllInvited(forAttendee: Bool = false) {
        let dataSource = forAttendee ? attendeeDataSource : participantDataSource
        let ringings: [ByteviewUser]? = dataSource.first(where: { $0.itemType == .invite })?.realItems.compactMap({ item in
            if let cellModel = item as? InvitedParticipantCellModel,
               cellModel.participant.status == .ringing {
                return ByteviewUser(id: cellModel.participant.user.id,
                                    type: cellModel.participant.type, deviceId: "0")
            }
            return nil
        })

        VCTracker.post(name: .vc_meeting_onthecall_click, params: [.click: "calling_cancel_all",
                                                                   .suggestionNum: suggestionDataSource.count,
                                                                   "cancel_num": ringings?.count])

        guard let users = ringings, !users.isEmpty else { return }
        var request = UpdateVideoChatRequest(meetingId: meetingId, action: .cancel, interactiveId: nil, role: self.meetingRole, leaveWithSyncRoom: nil)
        request.users = users
        meeting.httpClient.send(request)
    }

    func downAllHands(forAttendee: Bool = false) {
        ByteViewDialog.Builder()
            .id(.downAllHands)
            .title(I18n.View_G_SurePutAllDown)
            .leftTitle(I18n.View_G_CancelTurnOff)
            .leftHandler({ _ in
                //埋点
                VCTracker.post(name: .vc_meeting_onthecall_popup_click
                , params: [
                    .click: "cancel",
                    .content: "all_hands_down"
                ])
            })
            .rightTitle(I18n.View_G_Window_Confirm_Button)
            .rightHandler({ [weak self] _ in
                guard let self = self else { return }
                let action: HostManageAction = forAttendee ? .webinarPutDownAllAttendeeHands : .setConditionEmojiAllHandsDown
                let request = HostManageRequest(action: action, meetingId: self.meeting.meetingId)
                self.httpClient.send(request)
                VCTracker.post(name: .vc_meeting_onthecall_popup_click
                , params: [
                    .click: "confirm",
                    .content: "all_hands_down"
                ])
            })
            .show()
    }

    func jumpToUserProfile(participantId: ParticipantId, isLarkGuest: Bool) {
        if meeting.setting.isBrowseUserProfileEnabled, !isLarkGuest, let userId = participantId.larkUserId {
            ParticipantTracks.trackJumpToProfile(userId: userId, deviceId: participantId.deviceId)
            InMeetUserProfileAction.show(userId: userId, meeting: meeting)
        }
    }

    func muteAll() {
        meeting.microphone.muteAll(true)
        UserActionTracks.trackRequestAllMicAction(isOn: false)
    }

    func unMuteAll() {
        if meeting.participant.currentRoom.count > meeting.setting.maxSoftRtcNormalMode {
            Toast.showOnVCScene(I18n.View_M_CanNotUnmuteAll)
        } else {
            meeting.microphone.muteAll(false)
        }
        UserActionTracks.trackRequestAllMicAction(isOn: true)
    }

    func reclaimHost() {
        ParticipantTracks.trackParticipantAction(.cancelHost,
                                                 isFromGridView: false,
                                                 isSharing: meeting.shareData.isSharingContent == true)
        guard meeting.participant.find(in: .global, { $0.meetingRole == .host }) != nil else { return }
        Self.requestReclaimHost(meeting: meeting)
    }

    func searchCallMore(with model: SearchParticipantCellModel, sender: UIButton, selectComplet: @escaping (() -> Void)) {
        if participantListState != .none, let text = participantListState.toastText {
            Toast.show(text)
            return
        }

        ConveniencePSTN.showCallActions(service: meeting.service, from: sender, userId: model.searchBox.id) { [weak self] action in
            guard let self = self else { return }
            selectComplet()
            VCTracker.post(name: .vc_meeting_onthecall_click,
                                  params: [.click: action.trackEvent,
                                           .location: "search_result"])
            switch action {
            case .vcCall:
                if self.canInvite(model.searchBox) {
                    if let address = model.searchBox.roomItem?.sipAddress {
                        // sip
                        self.meeting.participant.inviteUsers(pstnInfos: [PSTNInfo(sipAddress: address)])
                    } else if model.searchBox.type == .room {
                        // room
                        self.meeting.participant.inviteUsers(roomIds: [model.searchBox.id])
                    } else {
                        // user
                        self.meeting.participant.inviteUsers(userIds: [model.searchBox.id])
                    }
                }
            case .pstnCall(let phone):
                self.meeting.participant.invitePSTN(userId: model.searchBox.id, name: model.originalName, mainAddress: phone)
            }
        }
    }

    func searchCall(with item: ParticipantSearchBox) {
        ParticipantTracks.trackInviteFromSearchList(userId: item.id)
        if participantListState != .none, let text = participantListState.toastText {
            Toast.show(text)
            return
        }
        if canInvite(item) {
            if let address = item.roomItem?.sipAddress {
                meeting.participant.inviteUsers(pstnInfos: [PSTNInfo(sipAddress: address)])
            } else if item.type == .room {
                meeting.participant.inviteUsers(roomIds: [item.id])
            } else {
                meeting.participant.inviteUsers(userIds: [item.id])
            }
        }
    }
}

extension ParticipantsViewModel {
    static func showReclaimHostAlert(meeting: InMeetMeeting) {
        ByteViewDialog.Builder()
            .id(.reclaimHostWhenBreakoutRoom)
            .title(I18n.View_G_ReclaimHostQuestion)
            .message(I18n.View_G_BreakoutRoomsNotSupportedOnMobile)
            .leftTitle(I18n.View_G_CancelButton)
            .rightTitle(I18n.View_M_ReclaimHost)
            .rightHandler({ [weak meeting] _ in
                guard let meeting = meeting else { return }
                Self.requestReclaimHost(meeting: meeting)
            })
            .show()
    }

    static func requestReclaimHost(meeting: InMeetMeeting) {
        guard let host = meeting.participant.find(in: .global, { $0.meetingRole == .host }) else { return }
        CohostTracks.trackReclaimHostAuthority(user: host.user, isSearch: false)
        meeting.httpClient.send(ReclaimHostRequest(meetingId: meeting.meetingId)) { result in
            if result.isSuccess {
                Toast.show(I18n.View_M_HostMadeYouNewHost)
            }
        }
    }
}
