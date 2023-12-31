//
//  InMeetAttentionComponent.swift
//  ByteView
//
//  Created by kiri on 2021/4/6.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RichLabel
import ByteViewCommon
import ByteViewNetwork
import ByteViewUI

/// 处理等候室和举手的提醒，依据tips的LayoutGuide对齐
final class InMeetAttentionComponent: InMeetViewComponent {
    // 等候室提醒 top offset和tipView保持一致
    weak var attention: AttentionView?
    weak var micHandsUpAttention: AttentionView?
    weak var cameraHandsUpAttention: AttentionView?
    weak var localRecordHandsUpAttention: AttentionView?
    weak var breakoutRoomAttention: AttentionView?
    weak var container: InMeetViewContainer?
    let lobby: InMeetLobbyViewModel
    let handsUp: InMeetHandsUpViewModel
    let breakoutRoomManager: BreakoutRoomManager
    let resolver: InMeetViewModelResolver
    let meeting: InMeetMeeting
    private let tipsGuideToken: MeetingLayoutGuideToken
    init(container: InMeetViewContainer, viewModel: InMeetViewModel, layoutContext: VCLayoutContext) {
        self.lobby = viewModel.resolver.resolve(InMeetLobbyViewModel.self)!
        self.handsUp = viewModel.resolver.resolve(InMeetHandsUpViewModel.self)!
        self.breakoutRoomManager = viewModel.resolver.resolve(BreakoutRoomManager.self)!
        self.resolver = viewModel.resolver
        self.container = container
        self.meeting = viewModel.meeting
        self.tipsGuideToken = container.layoutContainer.requestLayoutGuideFactory({ ctx in
            let query: InMeetLayoutGuideQuery
            if Display.phone && ctx.isLandscapeOrientation {
                query = InMeetOrderedLayoutGuideQuery(topAnchor: .top, bottomAnchor: .bottom, specificInsets: [.top: 6.0])
            } else {
                query = InMeetOrderedLayoutGuideQuery(topAnchor: .topSafeArea, bottomAnchor: .bottomSafeArea, specificInsets: [.topSafeArea: 6.0])
            }
            return query
        })
        lobby.addObserver(self)
        handsUp.addObserver(self)
        breakoutRoomManager.hostControl.addListener(self)
        resolver.viewContext.fullScreenDetector?.registerWhiteListClass(LKLabel.self)
    }

    var componentIdentifier: InMeetViewComponentIdentifier {
        .attention
    }

    func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        self.updateAttentionLayout(self.attention)
        self.updateAttentionLayout(self.micHandsUpAttention)
        self.updateAttentionLayout(self.cameraHandsUpAttention)
        self.updateAttentionLayout(self.localRecordHandsUpAttention)
        self.updateAttentionLayout(self.breakoutRoomAttention)
    }

    func containerDidFirstAppear(container: InMeetViewContainer) {
        shouldShowLobbyAttention(lobby.attention)
        shouldShowHandsUpAttention(handsUp.micHandsUpData.attention, handsupType: .mic)
        shouldShowHandsUpAttention(handsUp.cameraHandsUpData.attention, handsupType: .camera)
        shouldShowHandsUpAttention(handsUp.localRecordHandsUpData.attention, handsupType: .localRecord)
    }

    private func updateAttentionLayout(_ attention: AttentionView?) {
        guard let attention = attention, attention.superview != nil,
              let container = self.container else {
            return
        }
        let tipsGuide = tipsGuideToken.layoutGuide
        let traitCollection = VCScene.rootTraitCollection ?? container.traitCollection
        var width = CGFloat(300)
        var offset = CGFloat(12)
        let horizontalSizeClass = traitCollection.horizontalSizeClass
        if Display.phone || horizontalSizeClass == .compact {
            let minWidth = min(VCScene.bounds.width, VCScene.bounds.height)
            width = minWidth - offset * 2.0
            offset = (VCScene.bounds.width - width) / 2
        }
        attention.updateButtonAxis(maxWidth: width)
        attention.snp.remakeConstraints { (make) in
            make.top.equalTo(tipsGuide)
            make.width.equalTo(width)
            make.right.equalTo(-offset)
        }
    }

    private func showAttentionView(_ attention: AttentionView?) {
        if let attention = attention {
            container?.addContent(attention, level: .attention)
            attention.superview?.bringSubviewToFront(attention)
        }
    }
}

extension InMeetAttentionComponent: InMeetLobbyViewModelObserver {
    func shouldShowLobbyAttention(_ attention: LobbyAttention) {
        Util.runInMainThread { [weak self] in
            switch attention.state {
            case .none:
                self?.attention?.dismiss()
            case let .participant(lobbyParticipant, name):
                self?.showAttentionForUser(lobbyParticipant, name: name)
            case let .participants(count, onlyAttendee):
                self?.showAttentionForNum(count, onlyAttendee: onlyAttendee)
            }
        }
    }

    private func showAttentionForUser(_ lobbyParticipant: LobbyParticipant, name: String) {
        BreakoutRoomTracksV2.lobbyAttention(lobby.meeting)
        let user = lobbyParticipant.user
        let role = lobbyParticipant.participantMeetingRole
        let profileId = lobbyParticipant.participantId.larkUserId
        let isLarkGuest = lobbyParticipant.isLarkGuest
        let viewLobby: (() -> Void) = { [weak self] in
            guard let self = self else { return }
            BreakoutRoomTracksV2.lobbyAttentionDetail(self.lobby.meeting)
            LobbyTracks.trackAttentionAppearOfLobby(self.lobby.meeting)
            self.startParticipants(role == .webinarAttendee ? .attendee : .normal)
        }
        let admit: (() -> Void) = { [weak self] in
            guard let `self` = self else { return }
            BreakoutRoomTracksV2.lobbyAttentionAdmit(self.lobby.meeting)
            LobbyTracks.trackAttentionAdmitOfLobby(userID: user.id, deviceID: user.deviceId, meeting: self.lobby.meeting)
            self.lobby.admitUsersInLobby([user]) { [weak self] (result) in
                if result.isSuccess {
                    self?.lobby.closeAttention()
                }
            }
        }
        let beforeClose: (() -> Void) = { [weak self] in
            guard let self = self else { return }
            BreakoutRoomTracksV2.lobbyAttentionClose(self.lobby.meeting)
            LobbyTracks.trackAttentionClosedOfLobby(self.lobby.meeting)
            self.lobby.closeAttention()
        }
        let title = I18n.View_M_NameEnteredLobby(name)
        let attributedTitle = NSMutableAttributedString(string: title, config: .h3, textColor: UIColor.ud.textTitle)
        var titleLink: LKTextLink?
        let range = title.range(of: name)
        if let range = range {
            let location = title.utf16.distance(from: title.startIndex, to: range.lowerBound) // emoji 得用utf16
            let length = title.utf16.distance(from: range.lowerBound, to: range.upperBound)
            let nameRange = NSRange(location: location, length: length)
            let attributes = [NSAttributedString.Key.foregroundColor: UIColor.ud.textTitle,
                              NSAttributedString.Key.backgroundColor: UIColor.ud.bgFloat]
            // 点击name跳转到详情页
            titleLink = LKTextLink(range: nameRange, type: .link, attributes: attributes)
            titleLink?.linkTapBlock = { [weak self] (_, _) in
                guard let self = self else { return }
                self.jumpToUserProfile(profileId: profileId, isLarkGuest: isLarkGuest)
                BreakoutRoomTracksV2.lobbyAttentionProfile(self.lobby.meeting)
                LobbyTracks.trackAttentionProfileOfLobby(userID: user.id, deviceID: user.deviceId, meeting: self.lobby.meeting)
            }
        }
        let viewLobbyText = I18n.View_M_ViewLobby
        let admitText = I18n.View_M_AdmitButton
        if attention == nil {
            let attention = AttentionView(attributedTitle: attributedTitle,
                                          titleLink: titleLink,
                                          actions: AttentionAction(name: viewLobbyText, handler: viewLobby),
                                          AttentionAction(name: admitText, handler: admit),
                                          beforeClose: beforeClose)
            showAttentionView(attention)
            updateAttentionLayout(attention)
            self.attention = attention
        } else {
            attention?.update(attributedTitle: attributedTitle,
                              titleLink: titleLink,
                              actions: AttentionAction(name: viewLobbyText, handler: viewLobby),
                              AttentionAction(name: admitText, handler: admit),
                              beforeClose: beforeClose)
            showAttentionView(attention)
            updateAttentionLayout(attention)
        }
    }

    private func showAttentionForNum(_ num: Int, onlyAttendee: Bool) {
        BreakoutRoomTracksV2.lobbyAttention(lobby.meeting)
        let viewLobby: (() -> Void) = { [weak self] in
            guard let self = self else { return }
            BreakoutRoomTracksV2.lobbyAttentionDetail(self.lobby.meeting)
            LobbyTracks.trackAttentionAppearOfLobby(self.lobby.meeting)
            self.startParticipants(onlyAttendee ? .attendee : .normal)
        }
        let beforeClose: (() -> Void) = { [weak self] in
            guard let self = self else { return }
            BreakoutRoomTracksV2.lobbyAttentionClose(self.lobby.meeting)
            LobbyTracks.trackAttentionClosedOfLobby(self.lobby.meeting)
            self.lobby.closeAttention()
        }
        let title = I18n.View_M_NumberPeopleEnteredLobby(num)
        let attributedTitle = NSMutableAttributedString(string: title, config: .h3, textColor: UIColor.ud.textTitle)
        let viewLobbyText = I18n.View_M_ViewLobby
        if attention == nil {
            let attention = AttentionView(attributedTitle: attributedTitle,
                                          actions: AttentionAction(name: viewLobbyText, handler: viewLobby),
                                          beforeClose: beforeClose)
            showAttentionView(attention)
            updateAttentionLayout(attention)
            self.attention = attention
        } else {
            attention?.update(attributedTitle: attributedTitle,
                              actions: AttentionAction(name: viewLobbyText, handler: viewLobby),
                              beforeClose: beforeClose)
            showAttentionView(attention)
            updateAttentionLayout(attention)
        }
    }
}

extension InMeetAttentionComponent: InMeetHandsUpViewModelObserver {
    func shouldShowHandsUpAttention(_ attention: HandsUpAttention, handsupType: HandsUpType) {
        Util.runInMainThread { [weak self] in
            switch attention {
            case .none:
                if handsupType == .mic {
                    self?.micHandsUpAttention?.dismiss()
                } else if handsupType == .camera {
                    self?.cameraHandsUpAttention?.dismiss()
                } else {
                    self?.localRecordHandsUpAttention?.dismiss()
                }
            case let .participant(participant, name):
                self?.showHandsUpAttentionForParticipant(participant, name: name, handsupType: handsupType)
            case .participants(let count):
                self?.showHandsUpAttentionForNum(count, handsupType: handsupType)
            }
        }
    }

    private func showHandsUpAttentionForParticipant(_ participant: Participant, name: String, handsupType: HandsUpType) {
        HandsUpTracks.trackAttentionAppearOfHandsUp(count: 1, meeting: handsUp.meeting)
        HandsUpTracksV2.trackHandsUpPopup(handsUpType: handsupType, requestNum: 1)
        let viewDetail: (() -> Void) = { [weak self] in
            guard let self = self else { return }
            HandsUpTracks.trackAttentionDetailOfHandsUp(count: 1, meeting: self.handsUp.meeting)
            HandsUpTracksV2.trackClickHeadsUpRequestPopup(action: .viewDetails, handsUpType: handsupType, requestNum: 1)
            self.startParticipants(.none)
        }
        let unMute: (() -> Void) = { [weak self] in
            guard let `self` = self else { return }
            HandsUpTracks.trackAttentionPassOfHandsUp(user: participant.user,
                                                      count: 1,
                                                      meeting: self.handsUp.meeting)
            HandsUpTracksV2.trackClickHeadsUpRequestPopup(action: .unmute, handsUpType: handsupType, requestNum: 1)
            self.handsUp.passHandsUpOfParticipant(participant, handsupType: handsupType, completion: { [weak self] _ in
                self?.handsUp.closeAttention(handsupType: handsupType)
            })
        }
        let beforeClose: (() -> Void) = { [weak self] in
            guard let `self` = self else { return }
            HandsUpTracks.trackAttentionClosedOfHandsUp(count: 1, meeting: self.handsUp.meeting)
            HandsUpTracksV2.trackClickHeadsUpRequestPopup(action: .close, handsUpType: handsupType, requestNum: 1)
            self.handsUp.closeAttention(handsupType: handsupType)
        }
        let title: String
        switch handsupType {
        case .mic:
            title = I18n.View_M_NameRaisedHand(name)
        case .camera:
            title = I18n.View_G_NameRequestingCamOn(name)
        case .localRecord:
            title = I18n.View_G_NameRequestLocalRecord(name)
        }
        let attributedTitle = NSMutableAttributedString(string: title, config: .h3, textColor: UIColor.ud.textTitle)
        var titleLink: LKTextLink?
        let range = title.range(of: name)
        if let range = range {
            let location = title.distance(from: title.startIndex, to: range.lowerBound)
            let length = title.distance(from: range.lowerBound, to: range.upperBound)
            let nameRange = NSRange(location: location, length: length)
            let attributes = [NSAttributedString.Key.foregroundColor: UIColor.ud.textTitle,
                              NSAttributedString.Key.backgroundColor: UIColor.ud.bgFloat]
            // 点击name跳转到详情页
            titleLink = LKTextLink(range: nameRange, type: .link, attributes: attributes)
            titleLink?.linkTapBlock = { [weak self] (_, _) in
                guard let `self` = self else { return }
                self.jumpToUserProfile(profileId: participant.participantId.larkUserId, isLarkGuest: participant.isLarkGuest)
                HandsUpTracks.trackAttentionProfileOfHandsUp(user: participant.user,
                                                             count: 1,
                                                             meeting: self.handsUp.meeting)
                HandsUpTracksV2.trackClickHeadsUpRequestPopup(action: .userProfile, handsUpType: handsupType, requestNum: 1)
            }
        }
        let viewDetailText = I18n.View_G_ViewDetails
        let unMuteText = I18n.View_G_ApproveButton
        let handsUpAttention: AttentionView?
        switch handsupType {
        case .mic:
            handsUpAttention = micHandsUpAttention
        case .camera:
            handsUpAttention = cameraHandsUpAttention
        case .localRecord:
            handsUpAttention = localRecordHandsUpAttention
        }
        if handsUpAttention == nil {
            let attention = AttentionView(attributedTitle: attributedTitle,
                                          titleLink: titleLink,
                                          actions: AttentionAction(name: viewDetailText, handler: viewDetail),
                                          AttentionAction(name: unMuteText, handler: unMute),
                                          beforeClose: beforeClose)
            showAttentionView(attention)
            updateAttentionLayout(attention)
            switch handsupType {
            case .mic:
                micHandsUpAttention = attention
            case .camera:
                cameraHandsUpAttention = attention
            case .localRecord:
                localRecordHandsUpAttention = attention
            }
        } else {
            handsUpAttention?.update(attributedTitle: attributedTitle,
                                     titleLink: titleLink,
                                     actions: AttentionAction(name: viewDetailText, handler: viewDetail),
                                     AttentionAction(name: unMuteText, handler: unMute),
                                     beforeClose: beforeClose)
            showAttentionView(handsUpAttention)
            updateAttentionLayout(handsUpAttention)
        }
    }

    private func showHandsUpAttentionForNum(_ num: Int, handsupType: HandsUpType) {
        HandsUpTracks.trackAttentionAppearOfHandsUp(count: num, meeting: handsUp.meeting)
        HandsUpTracksV2.trackHandsUpPopup(handsUpType: handsupType, requestNum: num)
        let viewDetail: (() -> Void) = { [weak self] in
            guard let `self` = self else { return }
            HandsUpTracks.trackAttentionDetailOfHandsUp(count: num, meeting: self.handsUp.meeting)
            HandsUpTracksV2.trackClickHeadsUpRequestPopup(action: .viewDetails, handsUpType: handsupType, requestNum: num)
            self.startParticipants(.none)
        }
        let beforeClose: (() -> Void) = { [weak self] in
            guard let `self` = self else { return }
            HandsUpTracks.trackAttentionClosedOfHandsUp(count: num, meeting: self.handsUp.meeting)
            HandsUpTracksV2.trackClickHeadsUpRequestPopup(action: .close, handsUpType: handsupType, requestNum: num)
            self.handsUp.closeAttention(handsupType: handsupType)
        }
        let title: String
        switch handsupType {
        case .mic:
            title = I18n.View_M_NumberParticipantsRaisedHands(num)
        case .camera:
            title = I18n.View_G_NumRequestTurnCamOn(num)
        case .localRecord:
            title = I18n.View_G_NumberRequestLocalRecord(num)
        }
        let attributedTitle = NSMutableAttributedString(string: title, config: .h3, textColor: UIColor.ud.textTitle)
        let viewDetailText = I18n.View_G_ViewDetails

        let handsUpAttention: AttentionView?
        switch handsupType {
        case .mic:
            handsUpAttention = micHandsUpAttention
        case .camera:
            handsUpAttention = cameraHandsUpAttention
        case .localRecord:
            handsUpAttention = localRecordHandsUpAttention
        }
        if handsUpAttention == nil {
            let attention = AttentionView(attributedTitle: attributedTitle,
                                          actions: AttentionAction(name: viewDetailText, handler: viewDetail),
                                          beforeClose: beforeClose)
            showAttentionView(attention)
            updateAttentionLayout(attention)
            switch handsupType {
            case .mic:
                micHandsUpAttention = attention
            case .camera:
                cameraHandsUpAttention = attention
            case .localRecord:
                localRecordHandsUpAttention = attention
            }
        } else {
            handsUpAttention?.update(attributedTitle: attributedTitle,
                                     actions: AttentionAction(name: viewDetailText, handler: viewDetail),
                                     beforeClose: beforeClose)
            showAttentionView(handsUpAttention)
            updateAttentionLayout(handsUpAttention)
        }
    }

    private func jumpToUserProfile(profileId: String?, isLarkGuest: Bool) {
        if handsUp.meeting.setting.isBrowseUserProfileEnabled, let userId = profileId, !isLarkGuest {
            InMeetUserProfileAction.show(userId: userId, meeting: handsUp.meeting)
        }
    }

    private func startParticipants(_ autoScrollToLobby: ParticipantsViewController.ScrollToLobbyList) {
        meeting.router.startParticipants(meeting: meeting, resolver: resolver, autoScrollToLobby: autoScrollToLobby)
    }
}

extension InMeetAttentionComponent: BreakoutRoomHostControlListener {
    func updateBreakoutRoomAttention(attention: BreakoutRoomAttention) {
        Util.runInMainThread { [weak self] in
            switch attention {
            case .none:
                self?.breakoutRoomAttention?.dismiss()
            case let .one(user, userInfo, roomInfo):
                self?.showBreakoutRoomAttentionForOne(user, userInfo, roomInfo)
            case let .many(count):
                self?.showBreakoutRoomForMany(count)
            }
        }
    }

    private func showBreakoutRoomAttentionForOne(_ user: VCManageNotify.BreakoutRoomUser,
                                                 _ userInfo: ParticipantUserInfo,
                                                 _ roomInfo: BreakoutRoomInfo) {
        let attention = self.breakoutRoomAttention ?? AttentionView()
        let titleText = I18n.View_G_NameAskedForHelp(userInfo.name, roomInfo.topic)
        let viewDetailAction = AttentionAction(name: I18n.View_G_ViewDetails) { [weak self] in
            guard let self = self else { return }
            self.gotoBreakoutRoomHostControl()
            BreakoutRoomTracksV2.trackAttentionClick(self.meeting, .viewDetail)
        }
        let joinRoomAction = AttentionAction(name: I18n.View_G_JoinRoom) { [weak self] in
            guard let self = self else { return }
            self.breakoutRoomManager.join(breakoutRoomID: user.breakoutRoomId)
            BreakoutRoomTracksV2.trackAttentionClick(self.meeting, .joinRoom)
        }
        attention.update(
            attributedTitle: .init(string: titleText, config: .h3, textColor: .ud.textTitle),
            actions: viewDetailAction, joinRoomAction
        )
        showAttentionView(attention)
        updateAttentionLayout(attention)
        self.breakoutRoomAttention = attention
    }

    private func showBreakoutRoomForMany(_ count: Int) {
        let attention = self.breakoutRoomAttention ?? AttentionView()
        let titleText = I18n.View_G_NumAskingForHelp(count)
        let viewDetailAction = AttentionAction(name: I18n.View_G_ViewDetails) { [weak self] in
            guard let self = self else { return }
            self.gotoBreakoutRoomHostControl()
            BreakoutRoomTracksV2.trackAttentionClick(self.meeting, .viewDetail)
        }
        attention.update(
            attributedTitle: .init(string: titleText, config: .h3, textColor: .ud.textTitle),
            actions: viewDetailAction
        )
        showAttentionView(attention)
        updateAttentionLayout(attention)
        self.breakoutRoomAttention = attention
    }

    private func gotoBreakoutRoomHostControl() {
        let viewController = BreakoutRoomHostControlViewController(viewModel: self.breakoutRoomManager)
        meeting.router.presentDynamicModal(viewController,
                                           regularConfig: .init(presentationStyle: .formSheet, needNavigation: true),
                                           compactConfig: .init(presentationStyle: .pageSheet, needNavigation: true))
    }
}
