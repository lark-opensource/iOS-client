//
//  VideoTranscodeConfigFactory.swift
//  LarkMessageCore
//
//  Created by 李晨 on 2022/6/9.
//

import UIKit
import Foundation
import LarkSetting // SettingManager
import LarkDowngrade // LarkUniversalDowngradeService
import LarkSDKInterface // VideoTranscodeConfig
import RxCocoa // BehaviorRelay
import TTVideoEditor // IESMMMpeg
import LarkVideoDirector // VideoEditorManager
import LarkFoundation // Utils
import LarkPerf // DeviceExtension

// swiftlint:disable line_length
final class VideoTranscodeConfigFactory {
    struct VideoTranscodeConfigFactoryResult {
        var compileScene: String
        var compileQuality: String
        var videoTranscodeConfig: VideoTranscodeConfig
        var timeoutPeriod: Double?
        var aiCodec: Result<String, PrepareAICodecError>

        enum PrepareAICodecError: String, Error {
            case noModel, notWeakNet, lowDevice, cpu,
                 thermal, battery, debugDisable, settingDisable
        }
    }

    private let videoSettingRelay: BehaviorRelay<VideoSynthesisSetting>

    init(videoSetting: BehaviorRelay<VideoSynthesisSetting>) {
        self.videoSettingRelay = videoSetting
    }

    func config(strategy: VideoTranscodeStrategy, avasset: AVAsset?) -> VideoTranscodeConfigFactoryResult {
        let newCompressSetting = videoSettingRelay.value.newCompressSetting
        var useLowBitrateConfig = false
        if let track = avasset?.tracks(withMediaType: .video).first {
            let currVideoBitrate = CGFloat(track.estimatedDataRate)
            let isH264Video = Utils.isSimulator ? true : IESMMMpeg.isH264Video(avasset)
            if isH264Video,
               currVideoBitrate <= CGFloat(newCompressSetting.lowBitrateMax) {
                useLowBitrateConfig = true
            }
        }
        let timeoutPeriod = newCompressSetting.timeoutPeriod > 0 ? newCompressSetting.timeoutPeriod : nil
        var sceneKey = "middle"
        if VideoDebugKVStore.videoDebugEnable {
            // debug 配置
            return VideoTranscodeConfigFactoryResult(
                compileScene: "debug",
                compileQuality: "debug",
                videoTranscodeConfig: VideoTranscodeConfig(
                bigSideMax: Int(VideoDebugKVStore.bigSideMax),
                smallSideMax: Int(VideoDebugKVStore.smallSideMax),
                fpsMax: 30,
                bitrateSetting: VideoDebugKVStore.setting,
                remuxResolutionSetting: VideoDebugKVStore.remuxResolutionSetting,
                remuxFPSSetting: VideoDebugKVStore.remuxFPSSetting,
                remuxBitratelimitSetting: VideoDebugKVStore.remuxBitratelimitSetting,
                isForceReencode: strategy.isForceReencode
                ),
                timeoutPeriod: timeoutPeriod,
                aiCodec: getAICodecStatus(strategy: strategy))
        } else if useLowBitrateConfig {
            // 低码率配置
            sceneKey = "low_bitrate"
        } else if strategy.isOriginal {
            // 原画配置
            sceneKey = "origin"
        } else if strategy.isWeakNetwork {
            // 弱网配置
            sceneKey = "weak_net"
        } else {
            // 默认配置
            sceneKey = "common"
        }
        let qualityKey = newCompressSetting.scenes[sceneKey] ?? "middle"

        if let config = newCompressSetting.config[qualityKey] {
            return VideoTranscodeConfigFactoryResult(compileScene: sceneKey, compileQuality: qualityKey,
                                                     videoTranscodeConfig: config,
                                                     timeoutPeriod: timeoutPeriod,
                                                     aiCodec: getAICodecStatus(strategy: strategy))
        } else {
            return VideoTranscodeConfigFactoryResult(
                compileScene: "default",
                compileQuality: "default",
                videoTranscodeConfig: VideoTranscodeConfig(
                    bigSideMax: 960,
                    smallSideMax: 540,
                    fpsMax: 30,
                    bitrateSetting: "{\"compile\":{\"encode_mode\":\"hw\",\"hw\":{\"bitrate\":2831155,\"sd_bitrate_ratio\":0.4,\"full_hd_bitrate_ratio\":1.5,\"hevc_bitrate_ratio\":1,\"h_fps_bitrate_ratio\":1.4,\"effect_bitrate_ratio\":1.4,\"fps\":30,\"audio_bitrate\":128000}}}",
                    remuxResolutionSetting: 960 * 540,
                    remuxFPSSetting: 60,
                    remuxBitratelimitSetting: "{\"setting_values\":{\"normal_bitratelimit\": 3145728,\"hd_bitratelimit\":3145728}}",
                    isForceReencode: false
                ),
                timeoutPeriod: timeoutPeriod,
                aiCodec: getAICodecStatus(strategy: strategy)
            )
        }
    }

    private func getAICodecStatus(strategy: VideoTranscodeStrategy
    ) -> Result<String, VideoTranscodeConfigFactoryResult.PrepareAICodecError> {
        let useAICodec = {
            if VideoDebugKVStore.videoDebugEnable {
                return VideoDebugKVStore.useAICodec
            } else {
                return VideoDebugKVStore.DebugAICodecStrategy.auto
            }
        }()
        switch useAICodec {
        case .forceDisable:
            return .failure(.debugDisable)
        case .auto:
            let setting = videoSettingRelay.value.newCompressSetting.aiCodec
            // FG，弱网&高端机&cpu&内存&温度&电量
            guard setting.enable else {
                return .failure(.settingDisable)
            }
            let weakNet = strategy.isWeakNetwork
            if !weakNet {
                VideoEditorManager.shared.fetchSmartCodecModel() // 网络好时先拉取模型
                if setting.weakNetLimit {
                    return .failure(.notWeakNet)
                }
            }
            if let universalDowngradeSetting = try? SettingManager.shared // 临时使用，没问题就删
                .setting(with: UserSettingKey.make(userKeyLiteral: "lark_ios_universal_downgrade_config")),
               let enableUniversalDowngrade = universalDowngradeSetting["enableDowngrade"] as? Bool,
               enableUniversalDowngrade {
                let key = "videoAICodecTask"
                if setting.lowDeviceLimit > 0,
                   LarkUniversalDowngradeService.shared.needDowngrade(
                    key: key, strategies: [.lowDevice(setting.lowDeviceLimit)]) {
                    return .failure(.lowDevice)
                }
                if setting.cpuLimit > 0,
                   LarkUniversalDowngradeService.shared.needDowngrade(
                    key: key, strategies: [.overCPU(Double(setting.cpuLimit), nil, 1)]) {
                    return .failure(.cpu)
                }
                if setting.thermalLimit < ProcessInfo.ThermalState.critical.rawValue,
                   LarkUniversalDowngradeService.shared.needDowngrade(
                    key: key, strategies: [.overTemperature(Double(setting.thermalLimit), nil, 1)]) {
                    return .failure(.thermal)
                }
                if setting.batteryLimit > 0,
                   LarkUniversalDowngradeService.shared.needDowngrade(
                    key: key, strategies: [.overBattery(Double(setting.batteryLimit), 100)]) {
                    return .failure(.battery)
                }
            } else {
                if setting.lowDeviceLimit > 0, DeviceExtension.isLowDeviceClassify {
                    return .failure(.lowDevice)
                }
                let cpuLimit = setting.cpuLimit
                if cpuLimit > 0, let cpuUsage = try? Utils.averageCPUUsage, Float(cpuLimit) < cpuUsage {
                    return .failure(.cpu)
                }
                let thermalLimit = setting.thermalLimit
                if thermalLimit < ProcessInfo.processInfo.thermalState.rawValue {
                    return .failure(.thermal)
                }
                let batteryLimit = setting.batteryLimit
                if batteryLimit > 0 {
                    UIDevice.current.isBatteryMonitoringEnabled = true
                    if Float(batteryLimit) < UIDevice.current.batteryLevel * 100 {
                        return .failure(.battery)
                    }
                }
            }
        case .forceEnable:
            break
        }
        if let modelURL = VideoEditorManager.shared.getSmartCodecModel() {
            return .success(modelURL.path)
        }
        return .failure(.noModel)
    }
}
// swiftlint:enable line_length
