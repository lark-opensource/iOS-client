//
//  LarkVideoEngine.swift
//  LarkMessageCore
//
//  Created by luyz on 2021/11/22.
//

import Foundation
import TTVideoEngine
import LarkSetting
import LKCommonsLogging
import LKCommonsTracker
import LarkVideoDirector

public final class LarkVideoEngine: NSObject {
    static let logger = Logger.log(AssetBrowserVideoPlayProxy.self, category: "Module.LarkVideoEngine")

    // 视频播放器相关配置
    // https://bytedance.feishu.cn/docs/doccnZyKqudI6KASckZ8FSUAotb
    // https://cloud.bytedance.net/appSettings/config/146444/detail/status
    public static func videoEngine(settingService: SettingService) -> TTVideoEngine {

        /// 初始化 VideoEngineDelegate
        VideoEngineSetupManager.shared.setupVideoEngineDelegateIfNeeded()

        let videoEngine = TTVideoEngine(ownPlayer: true)

        var videoOptions: [VEKKeyType: Any] = [
            VEKKeyType(value: VEKKey.VEKKeyViewScaleMode_ENUM.rawValue): TTVideoEngineScalingMode.aspectFit.rawValue,
            VEKKeyType(value: VEKKey.VEKKeyViewRenderEngine_ENUM.rawValue): TTVideoEngineRenderEngine.metal.rawValue
        ]

        if let settings = try? settingService.setting(with: UserSettingKey.make(userKeyLiteral: "im_video_player_config")) {
            if let videoConfig = settings["engine"] as? [String: Any] {
                Self.logger.info("get video engine config \(videoConfig)")
                videoOptions = self.updateEngine(videoOptions: videoOptions, videoConfig: videoConfig)
            }
            if let onlineSwitch = settings["online_switch"] as? [String: Any],
               let engineConfig = onlineSwitch["engine"] as? [[String: Any]] {
                videoOptions = self.updateEngineOnline(videoOptions: videoOptions, videoConfig: engineConfig)
            }
        }
        // 点播平台接入 ab 配置
        if let abSetting = Tracker.experimentValue(key: "im_video_player_ab_config", shouldExposure: true) as? [String: Any] {
            Self.logger.info("get ab video config \(abSetting)")
            if let videoConfig = abSetting["engine"] as? [String: Any] {
                videoOptions = self.updateEngine(videoOptions: videoOptions, videoConfig: videoConfig)
            }
            if let onlineSwitch = abSetting["online_switch"] as? [String: Any],
               let engineConfig = onlineSwitch["engine"] as? [[String: Any]] {
                videoOptions = self.updateEngineOnline(videoOptions: videoOptions, videoConfig: engineConfig)
            }
        }
        videoEngine.setOptions(videoOptions)
        return videoEngine
    }

    static func updateEngineOnline(videoOptions: [VEKKeyType: Any], videoConfig: [[String: Any]]) -> [VEKKeyType: Any] {
        var videoOptions = videoOptions
        videoConfig.forEach { config in
            if let key = config["key"] as? NSInteger,
               let option = config["option"] {
                videoOptions[VEKKeyType(value: key)] = option
            }
        }
        return videoOptions
    }

    static func updateEngine(videoOptions: [VEKKeyType: Any], videoConfig: [String: Any]) -> [VEKKeyType: Any] {
        var videoOptions = videoOptions
        if let openTimeOut = videoConfig["VEKKeyPlayerOpenTimeOut"] as? Int {
            videoOptions[VEKKeyType(value: VEKKey.VEKKeyPlayerOpenTimeOut_NSInteger.rawValue)] = NSNumber(value: openTimeOut)
        }
        if let bufferingTimeOut = videoConfig["VEKKeyPlayerBufferingTimeOut"] as? Int {
            videoOptions[VEKKeyType(value: VEKKey.VEKKeyPlayerBufferingTimeOut_NSInteger.rawValue)] = NSNumber(value: bufferingTimeOut)
        }
        if let defaultBufferEndTime = videoConfig["VEKKeyPlayerDefaultBufferEndTime"] as? Int {
            videoOptions[VEKKeyType(value: VEKKey.VEKKeyPlayerDefaultBufferEndTime_NSInteger.rawValue)] = NSNumber(value: defaultBufferEndTime)
        }
        if let maxBufferEndTime = videoConfig["VEKKeyPlayerMaxBufferEndTime"] as? Int {
            videoOptions[VEKKeyType(value: VEKKey.VEKKeyPlayerMaxBufferEndTime_NSInteger.rawValue)] = NSNumber(value: maxBufferEndTime)
        }
        if let positionUpdateInterval = videoConfig["VEKKeyPlayerPositionUpdateInterval"] as? Int {
            videoOptions[VEKKeyType(value: VEKKey.VEKKeyPlayerPositionUpdateInterval_NSInteger.rawValue)] = NSNumber(value: positionUpdateInterval)
        }
        if let skipFindStreamInfo = videoConfig["VEKKeyPlayerSkipFindStreamInfo"] as? Int {
            videoOptions[VEKKeyType(value: VEKKey.VEKKeyPlayerSkipFindStreamInfo_BOOL.rawValue)] = skipFindStreamInfo == 1
        }
        if let postPrepareMsg = videoConfig["VEKKeyPlayerPostPrepareMsg"] as? Int {
            videoOptions[VEKKeyType(value: VEKKey.VEKKeyPlayerPostPrepareMsg.rawValue)] = NSNumber(value: postPrepareMsg)
        }
        if let keepFormatAlive = videoConfig["VEKKEYPlayerKeepFormatAlive"] as? Int {
            videoOptions[VEKKeyType(value: VEKKey.VEKKEYPlayerKeepFormatAlive_BOOL.rawValue)] = NSNumber(value: keepFormatAlive)
        }
        if let enableOutletDropLimit = videoConfig["VEKKeyPlayerEnableOutletDropLimit"] as? Int {
            videoOptions[VEKKeyType(value: VEKKey.VEKKeyPlayerEnableOutletDropLimit_BOOL.rawValue)] = enableOutletDropLimit == 1
        }
        if let preferNearestSampleEnable = videoConfig["VEKKeyPlayerPreferNearestSampleEnable"] as? Int {
            videoOptions[VEKKeyType(value: VEKKey.VEKKeyPlayerPreferNearestSampleEnable.rawValue)] = preferNearestSampleEnable == 1
        }
        if let preferNearestMaxPosOffset = videoConfig["VEKKeyPlayerPreferNearestMaxPosOffset"] as? Int {
            videoOptions[VEKKeyType(value: VEKKey.VEKKeyPlayerPreferNearestMaxPosOffset.rawValue)] = NSNumber(value: preferNearestMaxPosOffset)
        }
        if let cacheMaxSeconds = videoConfig["VEKKeyPlayerCacheMaxSeconds"] as? Int {
            videoOptions[VEKKeyType(value: VEKKey.VEKKeyPlayerCacheMaxSeconds_NSInteger.rawValue)] = NSNumber(value: cacheMaxSeconds)
        }
        if let enableAVStack = videoConfig["PLAYER_AVStack_ENABLE"] as? Int {
            videoOptions[VEKKeyType(value: VEKKey.VEKKeyPlayerEnableAVStack_BOOL.rawValue)] = enableAVStack == 1
        }
        if let enableDemuxNonblockRead = videoConfig["PLAYER_OPTION_ENABLE_DEMUX_NONBLOCK_READ"] as? Int {
            videoOptions[VEKKeyType(value: VEKKey.VEKKeyPlayerEnableDemuxNonBlockRead_BOOL.rawValue)] = enableDemuxNonblockRead == 1
        }
        if let enableEnterBufferingDirectly = videoConfig["VEKKeyEnterBufferingDirectly"] as? Int {
            videoOptions[VEKKeyType(value: VEKKey.VEKKeyEnterBufferingDirectly_BOOL.rawValue)] = enableEnterBufferingDirectly == 1
        }
        if let maxBufferEndMilliSeconds = videoConfig["VEKKeyPlayersMaxBufferEndMilliSeconds"] as? Int {
            videoOptions[VEKKeyType(value: VEKKey.VEKKeyPlayersMaxBufferEndMilliSeconds_NSInteger.rawValue)] = maxBufferEndMilliSeconds
        }
        if let playerCheckVoiceInBufferingStart = videoConfig["VEKKeyPlayerCheckVoiceInBufferingStart"] as? Int {
            videoOptions[VEKKeyType(value: VEKKey.VEKKeyPlayerCheckVoiceInBufferingStart_BOOL.rawValue)] = playerCheckVoiceInBufferingStart == 1
        }
        if let playerEnableDemuxNonBlockRead = videoConfig["VEKKeyPlayerEnableDemuxNonBlockRead"] as? Int {
            videoOptions[VEKKeyType(value: VEKKey.VEKKeyPlayerEnableDemuxNonBlockRead_BOOL.rawValue)] = playerEnableDemuxNonBlockRead == 1
        }

        if let bufferingDirectlyRenderStartReportEnable = videoConfig["VEKKeyPlayerEnableBufferingDirectlyRenderStartReport"] as? Int {
            videoOptions[VEKKeyType(value: VEKKey.VEKKeyPlayerEnableBufferingDirectlyRenderStartReport_BOOL.rawValue)] = bufferingDirectlyRenderStartReportEnable == 1
        }

        if let directlyBufferingEndTimeMilliSecondsEnable = videoConfig["VEKKeyPlayerEnableDirectlyBufferingEndTimeMilliSeconds"] as? Int {
            videoOptions[VEKKeyType(value: VEKKey.VEKKeyPlayerEnableDirectlyBufferingEndTimeMilliSeconds_BOOL.rawValue)] = directlyBufferingEndTimeMilliSecondsEnable == 1
        }

        if let directlyBufferingEndTimeMilliSeconds = videoConfig["VEKKeyPlayerDirectlyBufferingEndTimeMilliSeconds"] as? Int {
            videoOptions[VEKKeyType(value: VEKKey.VEKKeyPlayerDirectlyBufferingEndTimeMilliSeconds_NSInteger.rawValue)] = directlyBufferingEndTimeMilliSeconds
        }

        if let directlyBufferingSendVideoPacketEnable = videoConfig["VEKKeyPlayerEnableDirectlyBufferingSendVideoPacket"] as? Int {
            videoOptions[VEKKeyType(value: VEKKey.VEKKeyPlayerEnableDirectlyBufferingSendVideoPacket_BOOL.rawValue)] = directlyBufferingSendVideoPacketEnable == 1
        }

        if let medialoaderNativeEnable = videoConfig["VEKKeyMedialoaderNativeEnable"] as? Int {
            videoOptions[VEKKeyType(value: VEKKey.VEKKeyMedialoaderNativeEnable_BOOL.rawValue)] = medialoaderNativeEnable == 1
        }

        if let mp4CheckEnable = videoConfig["VEKKeyPlayerEnableMp4Check"] as? Int {
            videoOptions[VEKKeyType(value: VEKKey.VEKKeyPlayerEnableMp4Check_NSInteger.rawValue)] = mp4CheckEnable == 1
        }
        return videoOptions
    }
}
