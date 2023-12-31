//
//  ToolBarHandsUpItem.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/6/6.
//

import Foundation
import ByteViewSetting
import ByteViewNetwork
import ByteViewUI

final class ToolBarHandsUpItem: ToolBarItem {
    /// 是否正在举手
    private var isHandsUp: Bool
    private var handsUpEmojiKey: String?

    override var itemType: ToolBarItemType { .handsup }

    override var title: String {
        isHandsUp ? I18n.View_G_HandDown_Button : I18n.View_G_RaiseHand_Button
    }

    override var filledIcon: ToolBarIconType {
        if isHandsUp {
            return .image(EmojiResources.getEmojiSkin(by: handsUpEmojiKey))
        } else {
            return .icon(key: .raisehandFilled)
        }
    }

    override var outlinedIcon: ToolBarIconType {
        if isHandsUp {
            return .image(EmojiResources.getEmojiSkin(by: handsUpEmojiKey))
        } else {
            return .icon(key: .raisehandOutlined)
        }
    }

    override var phoneLocation: ToolBarItemPhoneLocation {
        if meeting.isWebinarAttendee {
            return (Display.phone && !VCScene.isLandscape) ? .toolbar : .navbar
        } else {
            return .none
        }
    }

    override var desiredPadLocation: ToolBarItemPadLocation {
        meeting.isWebinarAttendee ? .center : .none
    }

    required init(meeting: InMeetMeeting,
                  provider: ToolBarServiceProvider?,
                  resolver: InMeetViewModelResolver) {
        self.isHandsUp = meeting.myself.settings.conditionEmojiInfo?.isHandsUp == true
        self.handsUpEmojiKey = meeting.setting.handsUpEmojiKey
        super.init(meeting: meeting, provider: provider, resolver: resolver)
        meeting.addMyselfListener(self, fireImmediately: false)
        meeting.setting.addComplexListener(self, for: .handsUpEmojiKey)
    }

    override func clickAction() {
        MeetingTracksV2.trackClickConditionEmoji(isHandsUp ? "hands_down" : "hands_up", location: "onthecall_toolbar")
        var request = ParticipantChangeSettingsRequest(meeting: meeting)
        request.participantSettings.conditionEmojiInfo = ParticipantSettings.ConditionEmojiInfo(isHandsUp: !isHandsUp, handsUpEmojiKey: handsUpEmojiKey ?? "")
        meeting.httpClient.send(request)
    }

    private func updateState(_ p: Participant) {
        let newHandsUp = p.settings.conditionEmojiInfo?.isHandsUp == true
        if isHandsUp != newHandsUp {
            isHandsUp = newHandsUp
            notifyListeners()
        }
    }

    private func updateEmojiKey(_ emojiKey: String) {
        if handsUpEmojiKey != emojiKey {
            handsUpEmojiKey = emojiKey
            notifyListeners()
        }
    }
}

extension ToolBarHandsUpItem: MyselfListener {
    func didChangeMyself(_ myself: Participant, oldValue: Participant?) {
        updateState(myself)
    }
}

extension ToolBarHandsUpItem: MeetingComplexSettingListener {
    func didChangeComplexSetting(_ settings: MeetingSettingManager, key: MeetingComplexSettingKey, value: Any, oldValue: Any?) {
        if key == .handsUpEmojiKey, let emojiKey = value as? String {
            updateEmojiKey(emojiKey)
        }
    }
}
