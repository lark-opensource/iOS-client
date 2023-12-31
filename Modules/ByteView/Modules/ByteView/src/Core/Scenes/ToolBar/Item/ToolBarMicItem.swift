//
//  ToolBarMicItem.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/6/5.
//

import Foundation
import ByteViewSetting
import ByteViewTracker
import ByteViewNetwork
import ByteViewUI

protocol ToolBarMicItemDelegate: AnyObject {
    func volumeDidChange(_ volume: Int)
}

final class ToolBarMicItem: ToolBarItem {
    var micState: MicViewState = .off

    var volume = 0
    var enableVolumeWave = true
    private var isRoomAudioSelectVCVisible = false
    weak var micDelegate: ToolBarMicItemDelegate?

    override var itemType: ToolBarItemType { .microphone }

    override var title: String {
        switch micState {
        case .room:
            return I18n.View_G_ClickRoomMic_Button
        case .disconnect:
            return I18n.View_G_NoAudio_Icon
        case .callMe:
            return I18n.View_G_Phone
        default:
            return I18n.View_G_MicAbbreviated
        }
    }

    override var showTitle: Bool {
        switch micState {
        case .disconnect, .room, .callMe:
            return true
        default:
            return false
        }
    }

    override var isEnabled: Bool {
        micState != .forbidden && !micState.isCallMeRinging
    }

    override var isSelected: Bool {
        isRoomAudioSelectVCVisible
    }

    override var phoneLocation: ToolBarItemPhoneLocation {
        if VCScene.isLandscape {
            if micState == .disconnect { return .navbar }
            return .none
        } else {
            return meeting.setting.showsMicrophone ? .toolbar : .none
        }
    }

    override var desiredPadLocation: ToolBarItemPadLocation {
        guard meeting.setting.showsMicrophone else { return .none }
        if case .room = micState { return .inCombined }
        return meeting.isWebinarAttendee ? .left : .center
    }

    var hostViewController: UIViewController? { provider?.hostViewController }

    override func initialize() {
        meeting.volumeManager.addListener(self)
        meeting.setting.addListener(self, for: .showsMicrophone)
        meeting.audioModeManager.addListener(self)

        showGuideOnPad()
    }

    override func clickAction() {
        guard let provider = provider, !meeting.audioModeManager.shouldHandleMicClickEvent() else { return }
        provider.generateImpactFeedback()

        let isDisconnected = meeting.audioMode == .noConnect && !meeting.audioModeManager.isJoinPstnCalling
        if isDisconnected && meeting.audioModeManager.bizMode != .room {
            if Display.pad {
                ToolBarSwitchAudioItem.showSwitchAudioAlert(with: self.meeting, isMore: false)
            } else {
                let isCallMeEnable = meeting.setting.isCallMeEnabled
                var audioList: [ParticipantSettings.AudioMode] = []
                if isCallMeEnable || meeting.isE2EeMeeing {
                    audioList.append(.internet)
                    if !meeting.isE2EeMeeing {
                        audioList.append(.pstn)
                    }
                    // 端到端加密支持无音频
                    audioList.append(.noConnect)
                } else if meeting.setting.showsJoinRoom {
                    audioList.append(.internet)
                }
                let vc = AudioSelectViewController(scene: .inMeet(meeting), audioType: .noConnect, audioList: audioList, isRoomConnected: false)
                meeting.router.presentDynamicModal(vc, config: DynamicModalConfig(presentationStyle: .pan))
            }
            return
        }

        let mute = meeting.microphone.isMuted
        MeetingTracksV2.trackClickMic(!mute,
                                      meetingType: meeting.type,
                                      isSharingContent: meeting.shareData.isSharingContent,
                                      isMinimized: meeting.router.isFloating,
                                      isMore: false)
        if meeting.audioModeManager.bizMode == .room {
            VCTracker.post(name: .vc_meeting_onthecall_click, params: [.click: "room_mic", .option: mute ? "open" : "close"])
        }
        meeting.microphone.muteMyself(!mute, source: .toolbar, completion: nil)
    }

    private func showGuideOnPad() {
        guard Display.pad, meeting.service.shouldShowGuide(.micLocation) else { return }
        let guide = GuideDescriptor(type: .micLocation, title: nil, desc: I18n.View_G_NewMicPosition_Tooltip)
        guide.style = .darkPlain
        guide.sureAction = { [weak self] in self?.meeting.service.didShowGuide(.micLocation) }
        guide.duration = 5
        GuideManager.shared.request(guide: guide)
    }
}

extension ToolBarMicItem: VolumeManagerDelegate {
    func volumeDidChange(to volume: Int, rtcUid: RtcUID) {
        if rtcUid == meeting.myself.bindRtcUid {
            self.volume = volume
            self.micDelegate?.volumeDidChange(volume)
        }
    }
}

extension ToolBarMicItem: MeetingSettingListener {
    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        notifyListeners()
    }
}

extension ToolBarMicItem: RoomAudioSelectViewControllerDelegate {
    func roomAudioSelectViewControllerDidAppear(_ vc: UIViewController) {
        isRoomAudioSelectVCVisible = true
        notifyListeners()
    }

    func roomAudioSelectViewControllerWillDisappear(_ vc: UIViewController) {
        isRoomAudioSelectVCVisible = false
        notifyListeners()
    }
}

extension ToolBarMicItem: InMeetAudioModeListener {
    func didChangeMicState(_ state: MicViewState) {
        Logger.ui.info("ToolBarMicItem didChangeMicState \(state)")
        micState = state

        enableVolumeWave = state.showVolume

        notifyListeners()
    }
}
