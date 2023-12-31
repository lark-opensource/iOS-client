//
//  StreamRenderView+Zoom.swift
//  ByteView
//
//  Created by kiri on 2022/9/21.
//

import Foundation
import ByteViewNetwork
import ByteViewSetting
import ByteViewRtcBridge

extension StreamRenderView: MeetingSettingListener {
    func bindMeetingSetting(_ setting: MeetingSettingManager) {
        self.isVideoMirrored = setting.isVideoMirrored
        self.isVoiceMode = setting.isVoiceModeOn
        if setting.isAdvancedDebugOptionsEnabled {
            self.showFps(setting.displayFPS)
            self.showCodec(setting.displayCodec)
            setting.addListener(self, for: [.isVideoMirrored, .displayFPS, .displayCodec, .isVoiceModeOn])
        } else {
            setting.addListener(self, for: [.isVideoMirrored, .isVoiceModeOn])
        }
    }

    public func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        switch key {
        case .isVideoMirrored:
            self.isVideoMirrored = isOn
        case .displayFPS:
            self.showFps(isOn)
        case .displayCodec:
            self.showCodec(isOn)
        case .isVoiceModeOn:
            self.isVoiceMode = isOn
        default:
            break
        }
    }
}

extension ByteViewSetting.MultiResSubscribeResolution {
    func toRtc() -> ByteViewRtcBridge.MultiResSubscribeResolution {
        .init(res: res, fps: fps, goodRes: goodFps, goodFps: goodFps, badRes: badRes, badFps: badFps)
    }
}
