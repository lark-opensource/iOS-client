//
//  ToolBarParticipantsItem.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/6/6.
//

import Foundation
import ByteViewSetting
import ByteViewUI

final class ToolBarParticipantsItem: ToolBarItem {
    override var itemType: ToolBarItemType { .participants }

    override var title: String {
        I18n.View_M_Participants
    }

    override var filledIcon: ToolBarIconType {
        .icon(key: .personAddFilled)
    }

    override var outlinedIcon: ToolBarIconType {
        .icon(key: .memberAddOutlined)
    }

    override var phoneLocation: ToolBarItemPhoneLocation {
        if meeting.setting.showsParticipant {
            return (Display.phone && !VCScene.isLandscape) ? .toolbar : .navbar
        } else {
            return .none
        }
    }

    override var desiredPadLocation: ToolBarItemPadLocation {
        meeting.setting.showsParticipant ? .center : .none
    }

    var listTitle: String {
        "\(title)(\(participantNumber))"
    }

    var participantNumber = 0 {
        didSet {
            badgeBitsCount = bitsCount(for: participantNumber)
        }
    }
    var badgeBitsCount = 1

    private let lobbyViewModel: InMeetLobbyViewModel
    private let handsUpViewModel: InMeetHandsUpViewModel
    private let statusReactionViewModel: InMeetStatusReactionViewModel

    required init(meeting: InMeetMeeting,
                  provider: ToolBarServiceProvider?,
                  resolver: InMeetViewModelResolver) {
        self.lobbyViewModel = resolver.resolve()!
        self.handsUpViewModel = resolver.resolve()!
        self.statusReactionViewModel = resolver.resolve()!
        super.init(meeting: meeting, provider: provider, resolver: resolver)
        self.meeting.participant.addListener(self)
        self.meeting.setting.addListener(self, for: .showsParticipant)
        self.lobbyViewModel.addObserver(self)
        self.handsUpViewModel.addObserver(self)
        self.statusReactionViewModel.addObserver(self)
        self.addBadgeListener()
    }

    override func clickAction() {
        // 妙享场景手机横屏，点击此按钮时，收起键盘
        if self.meeting.shareData.isSharingDocument, Display.phone, VCScene.isLandscape {
            Util.dismissKeyboard()
        }

        provider?.generateImpactFeedback()
        MeetingTracksV2.trackMeetingClickOperation(action: .clickUserList,
                                                   isSharingContent: meeting.shareData.isSharingContent,
                                                   isMinimized: meeting.router.isFloating,
                                                   isMore: false)
        let needShrinkToolBarAction = phoneLocation != .navbar
        let completion: (() -> Void) = { [weak self] in
            guard let self = self else { return }

            if Display.phone, VCScene.isLandscape {
                MeetingTracksV2.trackChangeOrientation(toLandscape: false, reason: .click_function)
            }
            self.meeting.router.startParticipants(meeting: self.meeting, resolver: self.resolver)
            if self.meeting.type == .call {
                MeetingTracks.trackUpgradeInvite()
            } else {
                MeetingTracks.trackTapParticipants()
            }
        }
        if needShrinkToolBarAction {
            shrinkToolBar(completion: completion)
        } else {
            completion()
        }
    }

    private func updateParticipantNumber() {
        let oldBitsCount = self.badgeBitsCount
        participantNumber = meeting.participant.currentRoom.count + lobbyViewModel.participants.count + Int(meeting.participant.attendeeNum ?? 0)
        let bitsCount = self.badgeBitsCount

        notifyListeners()
        if Display.pad && (oldBitsCount > 3) != (bitsCount > 3) {
            notifySizeListeners()
        }
    }

    private func updateRedTip() {
        let badgeType: ToolBarBadgeType
        if lobbyViewModel.redTipCount > 0 || handsUpViewModel.redTipCount > 0 || statusReactionViewModel.redTipCount > 0 {
            badgeType = .dot
        } else {
            badgeType = .none
        }
        updateBadgeType(badgeType)
    }

    private func bitsCount(for number: Int) -> Int {
        guard number > 0 else { return 1 }
        var num = number
        var res = 0
        while num > 0 {
            res += 1
            num /= 10
        }
        return res
    }
}

extension ToolBarParticipantsItem: InMeetHandsUpViewModelObserver {
    func shouldShowHandsUpRedTip(_ count: Int) {
        updateRedTip()
    }
}

extension ToolBarParticipantsItem: InMeetLobbyViewModelObserver {
    func didChangeLobbyParticipants(_ participants: [LobbyParticipant]) {
        updateParticipantNumber()
    }

    func shouldShowLobbyRedTip(_ count: Int) {
        updateRedTip()
    }
}

extension ToolBarParticipantsItem: InMeetStatusReactionViewModelObserver {
    func shouldShowStatusReactionRedTip(_ count: Int) {
        updateRedTip()
    }
}

extension ToolBarParticipantsItem: InMeetParticipantListener {

    func didChangeCurrentRoomParticipants(_ output: InMeetParticipantOutput) {
        updateParticipantNumber()
    }

    func didChangeWebinarAttendeeNum(_ num: Int64) {
        updateParticipantNumber()
    }
}

extension ToolBarParticipantsItem: MeetingSettingListener {
    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        notifyListeners()
    }
}
