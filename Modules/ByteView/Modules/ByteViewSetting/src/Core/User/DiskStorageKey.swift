//
//  GlobalSettingDiskStorageKey.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/4/10.
//

import Foundation
import ByteViewCommon

enum UserSettingStorageKey: String, LocalStorageKey {
    /// 记录是否merge过6.10以后的设置
    case mergeSettingV6v10

    /// default true
    case improveAudioQuality
    /// default true
    case ultrawave
    /// default true
    case needAdjustAnnotate
    case autoHideToolStatusBar

    case enterprisePhoneConfig
    case rtcFeatureGating
    case adminMediaServer
    case adminOrgSettings
    /// 响铃自定义铃声
    case customizeRingtoneForRing
    /// 最近的一通未完成的会议id
    case lastlyMeetingId
    case micCameraSetting
    case lastCalledPhoneNumber

    // 用户选择入会音频设置
    case preferAudioOutputSetting
    // 会议音频设备
    case meetingAudioDevice
    // 音频1v1音频设备
    case voiceAudioDevice
    // 视频1v1音频设备
    case videoAudioDevice

    case micSpeakerDisabled
    case keyboardMute
    case displayFPS
    case displayCodec
    case meetingHDVideo
    /// 标记是否使用过
    case centerStageUsed
    case pip
    case replaceJoinedDevice
    case hideReaction
    case hideChat
    case reactionDisplayMode

    var domain: LocalStorageDomain {
        .child("Core")
    }
}
