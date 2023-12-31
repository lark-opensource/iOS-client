//
//  ToolBarCameraItem.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/6/6.
//

import Foundation
import ByteViewSetting
import ByteViewTracker
import UniverseDesignIcon
import ByteViewUI

final class ToolBarCameraItem: ToolBarItem {
    override var itemType: ToolBarItemType { .camera }

    override var title: String {
        I18n.View_VM_Camera
    }

    override var phoneLocation: ToolBarItemPhoneLocation {
        if meeting.setting.showsCamera {
            return VCScene.isPhonePortrait ? .toolbar : .navbar
        } else {
            return .none
        }
    }

    override var desiredPadLocation: ToolBarItemPadLocation {
        meeting.setting.showsCamera ? .center : .none
    }

    override var filledIcon: ToolBarIconType {
        let key: UDIconType
        let color: UIColor
        if unauthorized {
            key = .videoOffFilled
            color = UIColor.ud.iconDisabled
        } else if isMuted {
            key = .videoOffFilled
            color = UIColor.ud.functionDangerContentDefault
        } else {
            return .icon(key: .videoFilled)
        }
        return .customColoredIcon(key: key, color: color)
    }

    override var outlinedIcon: ToolBarIconType {
        let key: UDIconType
        let color: UIColor
        if unauthorized {
            key = .videoOffOutlined
            color = UIColor.ud.iconDisabled
        } else if isMuted {
            key = .videoOffOutlined
            color = UIColor.ud.functionDangerContentDefault
        } else {
            return .icon(key: .videoOutlined)
        }
        return .customColoredIcon(key: key, color: color)
    }

    var unauthorized: Bool { Privacy.videoDenied }
    var isMuted: Bool { meeting.camera.isMuted }

    required init(meeting: InMeetMeeting,
                  provider: ToolBarServiceProvider?,
                  resolver: InMeetViewModelResolver) {
        super.init(meeting: meeting, provider: provider, resolver: resolver)
        meeting.setting.addListener(self, for: .showsCamera)
        meeting.camera.addListener(self)
    }

    override func clickAction() {
        guard let provider = provider else { return }
        provider.generateImpactFeedback()
        let isMyVideoMuted = meeting.camera.isMuted
        let trackName = meeting.type.trackName
        VCTracker.post(name: trackName, params: [.action_name: "camera", .from_source: "control_bar",
                                                 .extend_value: ["is_sharing": meeting.shareData.isSharingContent ? 1 : 0,
                                                                 "action_enabled": isMyVideoMuted ? 0 : 1]])
        MeetingTracksV2.trackClickCam(!isMyVideoMuted, isSharingContent: meeting.shareData.isSharingContent, isMinimized: meeting.router.isFloating, isMore: false)
        meeting.camera.muteMyself(!isMyVideoMuted, source: .toolbar, completion: nil)
    }
}

extension ToolBarCameraItem: MeetingSettingListener {
    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        notifyListeners()
    }
}

extension ToolBarCameraItem: InMeetCameraListener {
    func didChangeCameraMuted(_ camera: InMeetCameraManager) {
        notifyListeners()
    }
}
