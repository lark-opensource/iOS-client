//
//  LarkMediaMutex.swift
//  LarkMedia
//
//  Created by FakeGourmet on 2023/7/24.
//

import Foundation

/// 飞书媒体业务场景
public extension MediaMutexScene {
    // VC
    /// 视频会议
    static let vcMeeting = MediaMutexScene(rawValue: "vcMeeting")
    /// 视频会议响铃
    static let vcRing = MediaMutexScene(rawValue: "vcRing")
    /// 视频会议铃声试听
    static let vcRingtoneAudition = MediaMutexScene(rawValue: "vcRingtoneAudition")
    /// VoIP
    static let voip = MediaMutexScene(rawValue: "voip")
    /// VoIP 响铃
    static let voipRing = MediaMutexScene(rawValue: "voipRing")
    /// 超声波
    static let ultrawave = MediaMutexScene(rawValue: "ultrawave")

    // Minutes
    /// 妙记录制
    static let mmRecord = MediaMutexScene(rawValue: "mmRecord")
    /// 妙记播客
    static let mmPlay = MediaMutexScene(rawValue: "mmPlay")

    // IM
    /// IM 语音录制
    /// e.g. 语音消息/语音转文字
    static let imRecord = MediaMutexScene(rawValue: "imRecord")
    /// IM 音频播放
    static let imPlay = MediaMutexScene(rawValue: "imPlay")
    /// IM 视频播放
    static let imVideoPlay = MediaMutexScene(rawValue: "imVideoPlay")
    /// IM 拍照
    /// e.g. 扫一扫
    static let imCamera = MediaMutexScene(rawValue: "imCamera")

    // MicroApp、开放平台
    /// 小程序音视频播放
    static let microPlay = microPlay()
    static func microPlay(id: String = "") -> MediaMutexScene {
        MediaMutexScene(rawValue: "microPlay", id: id)
    }
    /// 小程序音频录制
    static let microRecord = microRecord()
    static func microRecord(id: String = "") -> MediaMutexScene {
        MediaMutexScene(rawValue: "microRecord", id: id)
    }

    // CCM
    /// 文档语音录制
    /// e.g. 语音评论
    static let ccmRecord = MediaMutexScene(rawValue: "ccmRecord")
    /// 文档音视频播放
    static let ccmPlay = MediaMutexScene(rawValue: "ccmPlay")

    // CameraKit
    static let commonCamera = MediaMutexScene(rawValue: "commonCamera")
    static let commonVideoRecord = MediaMutexScene(rawValue: "commonVideoRecord")
}

extension MediaMutexScene {
    var mediaConfig: SceneMediaConfig? {

        // remote config
        if let config = LarkMediaManager.shared.mediaMutex.configMap.first(where: { k, _ in
            k.rawValue == self.rawValue
        })?.value {
            return config.copy(scene: self)
        }

        // local config
        switch self {
        case .vcMeeting                 : return VCMeetingMediaConfig()
        case .vcRing                    : return VCRingMediaConfig()
        case .vcRingtoneAudition        : return VCRingtoneAuditionMediaConfig()
        case .ultrawave                 : return UltraWaveMediaConfig()

        case .voip                      : return VoIPMeetingMediaConfig()
        case .voipRing                  : return VoIPRingMediaConfig()

        case .mmRecord                  : return MMRecordMediaConfig()
        case .mmPlay                    : return MMPlayMediaConfig()

        case .imRecord                  : return IMRecordMediaConfig()
        case .imPlay                    : return IMPlayMediaConfig()
        case .imCamera                  : return IMCameraMediaConfig()
        case .imVideoPlay               : return IMVideoPlayMediaConfig()

        case .microRecord               : return MicroRecordMediaConfig()
        case .microPlay                 : return MicroPlayMediaConfig()
        case .microRecord(id: id)       : return MicroRecordMediaConfig(id: id)
        case .microPlay(id: id)         : return MicroPlayMediaConfig(id: id)

        case .ccmRecord                 : return CCMRecordMediaConfig()
        case .ccmPlay                   : return CCMPlayMediaConfig()

        case .commonCamera              : return CommonCameraMediaConfig()
        case .commonVideoRecord         : return CommonVideoRecordMediaConfig()

        default:
            MediaMutexManager.logger.warn("unknown media scene: \(rawValue)")
            return nil
        }
    }

    /// 是否需要同时录制
    var isMixRecordScene: Bool {
        [.vcMeeting, .ultrawave].contains(self)
    }
}
