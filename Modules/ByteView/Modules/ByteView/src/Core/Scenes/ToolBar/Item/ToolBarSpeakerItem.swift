//
//  ToolBarSpeakerItem.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/6/6.
//

import Foundation
import LarkMedia
import AVFoundation
import ByteViewSetting
import ByteViewTracker
import UniverseDesignIcon
import ByteViewUI

final class ToolBarSpeakerItem: ToolBarItem {
    private weak var breakoutRoom: BreakoutRoomManager?
    private var isPickerOpening = false

    override var itemType: ToolBarItemType { .speaker }

    override var title: String {
        let output = meeting.audioDevice.output
        return (output.isDisabled || output.isMuted) ? I18n.View_MV_AlreadyMutedButton : output.currentOutput.i18nText
    }

    override var phoneLocation: ToolBarItemPhoneLocation {
        if meeting.setting.showsSpeaker {
            return (Display.phone && !VCScene.isLandscape) ? .toolbar : .navbar
        } else {
            return .none
        }
    }

    override var desiredPadLocation: ToolBarItemPadLocation {
        guard meeting.setting.showsSpeaker else { return .none }
        return meeting.isWebinarAttendee ? .left : .center
    }

    override var isEnabled: Bool {
        !meeting.audioDevice.output.isPadMicSpeakerDisabled
    }

    override var isSelected: Bool {
        isPickerOpening
    }

    override var filledIcon: ToolBarIconType {
        if !isEnabled || meeting.audioDevice.output.isMuted {
            return .icon(key: .speakerMuteFilled)
        } else {
            return .icon(key: meeting.audioDevice.output.currentOutput.imageKey(isSolid: true))
        }
    }

    override var outlinedIcon: ToolBarIconType {
        if !isEnabled || meeting.audioDevice.output.isMuted {
            return .icon(key: .speakerMuteOutlined)
        } else {
            return .icon(key: meeting.audioDevice.output.currentOutput.imageKey(isSolid: false))
        }
    }

    required init(meeting: InMeetMeeting,
                  provider: ToolBarServiceProvider?,
                  resolver: InMeetViewModelResolver) {
        self.breakoutRoom = resolver.resolve()
        super.init(meeting: meeting, provider: provider, resolver: resolver)
        meeting.setting.addListener(self, for: .showsSpeaker)
        meeting.microphone.addListener(self)
        meeting.audioDevice.output.addListener(self)
    }

    override func clickAction() {
        guard let provider = provider,
              let view = provider.itemView(with: .speaker),
              let topMost = provider.hostViewController?.vc.topMost else { return }

        // 妙享场景手机横屏，点击此按钮时，收起键盘
        if meeting.shareData.isSharingDocument, Display.phone, VCScene.isLandscape {
            Util.dismissKeyboard()
        }

        meeting.audioDevice.output.showPicker(scene: .onTheCall, from: topMost, anchorView: view)

        provider.generateImpactFeedback()
        let trackName = meeting.type.trackName
        let deviceName = LarkAudioSession.shared.currentOutput.trackText
        VCTracker.post(name: trackName, params: [.action_name: deviceName])
        /// 点击会中状态栏的输入设备
        VCTracker.post(name: .vc_bluetooth_status, params: ["status": "click_output", "output_device_name": deviceName])
        let isFloating = meeting.router.isFloating
        let isSharingContent = meeting.shareData.isSharingContent
        DispatchQueue.global().async {
            MeetingTracksV2.trackClickAudioOutput(isSheet: !LarkAudioSession.shared.isHeadsetConnected,
                                                  device: deviceName,
                                                  isSharingContent: isSharingContent,
                                                  isMinimized: isFloating,
                                                  isMore: false)
        }
    }
}

extension ToolBarSpeakerItem: MeetingSettingListener {
    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        notifyListeners()
    }
}

extension ToolBarSpeakerItem: InMeetMicrophoneListener {
    func didChangeMicrophoneMuted(_ microphone: InMeetMicrophoneManager) {
        if !microphone.isMuted, meeting.audioDevice.output.isMuted {
            meeting.audioDevice.output.setMuted(false)
        }
    }
}

extension ToolBarSpeakerItem: AudioOutputListener {
    func didChangeAudioOutput(_ output: AudioOutputManager, reason: AudioOutputChangeReason) {
        guard breakoutRoom?.transition.isTransitioning != true else { return }
        if !output.isDisabled, output.isMuted, !meeting.microphone.isMuted {
            meeting.microphone.muteMyself(true, source: .speaker_mute, showToastOnSuccess: false, completion: nil)
        }
        if !output.isDisabled, meeting.canShowAudioToast, !meeting.router.isFloating, !self.meeting.setting.isBoxSharing {
            output.showToast()
        }
        notifyListeners()
    }

    func audioOutputPickerWillAppear() {
        isPickerOpening = true
        notifyListeners()
    }

    func audioOutputPickerWillDisappear() {
        isPickerOpening = false
        notifyListeners()
    }
}
