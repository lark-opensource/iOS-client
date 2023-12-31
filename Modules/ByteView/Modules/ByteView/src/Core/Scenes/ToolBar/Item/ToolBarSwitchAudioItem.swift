//
//  ToolBarSwitchAudioItem.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/6/6.
//

import Foundation
import ByteViewUI
import ByteViewSetting
import ByteViewTracker
import UniverseDesignIcon
import ByteViewNetwork

final class ToolBarSwitchAudioItem: ToolBarItem {
    private(set) var isE2EeMeeting: Bool

    override var itemType: ToolBarItemType { .switchAudio }

    override var title: String {
        switch meeting.audioMode {
        case .internet, .pstn:
            return Display.pad ? I18n.View_G_DisconnectAudioLongButton : I18n.View_MV_SwitchAudio_BarButton
        case .noConnect:
            return Display.pad ? I18n.View_MV_ConnectAudio_BarButton : I18n.View_MV_SwitchAudio_BarButton
        default:
            return ""
        }
    }

    override var filledIcon: ToolBarIconType {
        return outlinedIcon
    }

    override var outlinedIcon: ToolBarIconType {
        let size = CGSize(width: 24, height: 24)
        /// 直接使用 UDIcon.getIconByKey获取的image, LM/DM切换颜色不变
        let switchColorful = UIImage.dynamic(light: UDIcon.getIconByKey(.switchAudioFilledColorful, size: size).alwaysLight, dark: UDIcon.getIconByKey(.switchAudioFilledColorful, size: size).alwaysDark)
        let connectAudioIcon = UIImage.dynamic(light: UDIcon.getIconByKey(.connectAudioOutlinedColorful, size: size).alwaysLight, dark: UDIcon.getIconByKey(.connectAudioOutlinedColorful, size: size).alwaysDark)
        switch meeting.audioMode {
        case .internet, .pstn:
            return Display.pad ? .icon(key: .disconnectAudioOutlined) : .image(switchColorful)
        case .noConnect:
            return Display.pad ? .image(connectAudioIcon) : .image(switchColorful)
        default:
            return .none
        }
    }

    override var phoneLocation: ToolBarItemPhoneLocation {
        meeting.setting.showsSwitchAudio ? .more : .none
    }

    override var desiredPadLocation: ToolBarItemPadLocation {
        meeting.setting.showsSwitchAudio ? .more : .none
    }

    required init(meeting: InMeetMeeting,
                  provider: ToolBarServiceProvider?,
                  resolver: InMeetViewModelResolver) {
        self.isE2EeMeeting = meeting.isE2EeMeeing
        super.init(meeting: meeting, provider: provider, resolver: resolver)
        self.addBadgeListener()
        meeting.setting.addListener(self, for: [.showsSwitchAudio])
    }

    override func clickAction() {
        shrinkToolBar { [weak self] in
            guard let self = self else { return }
            if Display.pad {
                Self.showSwitchAudioAlert(with: self.meeting)
            } else {
                var audio: ParticipantSettings.AudioMode? = self.meeting.audioMode
                var audioList: [ParticipantSettings.AudioMode] = [.internet, .noConnect]
                let isRoomConnected = self.meeting.myself.settings.targetToJoinTogether != nil
                if self.meeting.audioMode == .noConnect && isRoomConnected {
                    audioList = [.internet]
                    audio = nil
                }
                if !self.isE2EeMeeting {
                    audioList.insert(.pstn, at: 1)
                }
                VCTracker.post(name: .vc_meeting_onthecall_click, params: [.click: "change_audio", "is_more": true, .target: "none"])
                let vc = AudioSelectViewController(scene: .inMeet(self.meeting), audioType: audio, audioList: audioList, isRoomConnected: isRoomConnected)
                self.meeting.router.presentDynamicModal(vc, config: DynamicModalConfig(presentationStyle: .pan))
            }
        }
    }

    /// 仅新版Pad样式使用，且切换仅在 internet <-> noConnect
    static func showSwitchAudioAlert(with meeting: InMeetMeeting, isMore: Bool = true) {
        switch meeting.audioMode {
        case .internet:
            VCTracker.post(name: .vc_meeting_onthecall_click, params: [.click: "unconnected_audio", .target: "vc_meeting_popup_view"])
            VCTracker.post(name: .vc_meeting_popup_view, params: [.content: "unconnected_audio"])

            Self.showSwitchAudioAlert(content: I18n.View_MV_DisconnectedCantHear_Pop, colorTheme: .redLight, leftHandler: {
                VCTracker.post(name: .vc_meeting_popup_click, params: [.click: "cancel", .content: "unconnected_audio"])
            }, rightTitle: I18n.View_MV_DisconnectedCantHear_PopDisconnect, rightHandler: { [weak meeting] in
                VCTracker.post(name: .vc_meeting_popup_click, params: [.click: "confirm", .content: "unconnected_audio"])
                meeting?.audioModeManager.changeBizAudioMode(bizMode: .noConnect)
            })
        case .noConnect:
            VCTracker.post(name: .vc_meeting_onthecall_click, params: [.click: "connecte_audio",
                                                                       "is_more": isMore,
                                                                       .target: "vc_meeting_popup_view"])
            VCTracker.post(name: .vc_meeting_popup_view, params: [.content: "system_audio"])
            Self.showSwitchAudioAlert(content: I18n.View_G_ConnectSystemAudioPop, message: I18n.View_G_ConnectSystemAudioPopExplain, leftHandler: {
                VCTracker.post(name: .vc_meeting_popup_click, params: [.click: "cancel", .content: "system_audio"])
            }, rightTitle: I18n.View_G_ConnectSystemAudioButton, rightHandler: { [weak meeting] in
                VCTracker.post(name: .vc_meeting_popup_click, params: [.click: "confirm", .content: "system_audio"])
                meeting?.audioModeManager.changeBizAudioMode(bizMode: .internet)
            })
        default:
            break
        }
    }

    static func showSwitchAudioAlert(content: String, message: String? = nil, colorTheme: ByteViewDialogConfig.ColorTheme = .defaultTheme, leftHandler: @escaping () -> Void, rightTitle: String, rightHandler: @escaping () -> Void) {
        ByteViewDialog.Builder()
            .id(.padNoAudio)
            .needAutoDismiss(true)
            .colorTheme(colorTheme)
            .title(content)
            .message(message)
            .leftTitle(I18n.View_MV_CancelButtonTwo)
            .leftHandler({ _ in
                leftHandler()
            })
            .rightTitle(rightTitle)
            .rightHandler({ _ in
                rightHandler()
            })
            .show()
    }
}

extension ToolBarSwitchAudioItem: MeetingSettingListener {
    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        notifyListeners()
    }
}
