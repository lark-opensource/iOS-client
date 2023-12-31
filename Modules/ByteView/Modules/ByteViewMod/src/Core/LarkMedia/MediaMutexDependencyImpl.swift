//
//  MediaMutexDependencyImpl.swift
//  ByteView
//
//  Created by fakegourmet on 2022/9/8.
//

import Foundation
import LarkMedia
import ByteViewCommon
import ByteViewNetwork
import LarkSetting
import LarkContainer
import ByteViewSetting

final class MediaMutexDependencyImpl: MediaMutexDependency {
    private static let logger = Logger.getLogger("MediaMutexDependency")

    let httpClient: HttpClient
    let service: SettingService
    let fg: FeatureGatingService
    init(userResolver: UserResolver) throws {
        self.httpClient = try userResolver.resolve(assert: HttpClient.self)
        self.service = try userResolver.resolve(assert: SettingService.self)
        self.fg = try userResolver.resolve(assert: FeatureGatingService.self)
    }

    var enableRuntime: Bool {
        do {
            return try service.setting(with: MuteAudioConfig.self, key: UserSettingKey.make(userKeyLiteral: "vc_mute_audio_unit")).enableRuntime
        } catch {
            Self.logger.error("fetch settings for vc_mute_audio_unit failed: \(error)")
            return false
        }
    }

    func makeErrorMsg(scene: MediaMutexScene, type: MediaMutexType) -> String {
        if let desc = scene.sceneDescription, !desc.isEmpty {
            return I18n.View_G_CurrentDoingTryLater(desc, type.desc)
        } else if let desc = scene.defaultDesc {
            return I18n.View_G_CurrentDoingTryLater(desc, type.desc)
        } else {
            return I18n.View_G_CurrentDoingTryLater("", type.desc)
        }
    }

    func fetchSettings(block: (([MediaMutexScene: SceneMediaConfig]) -> Void)?) {
        let cfgs: [MediaMutexConfig]
        do {
            cfgs = try service.setting(with: [MediaMutexConfig].self, key: UserSettingKey.make(userKeyLiteral: "vc_media_resource_mutex"))
        } catch {
            Self.logger.error("fetch settings for vc_media_resource_mutex failed: \(error)")
            return
        }
        var sceneMap: [MediaMutexScene: MediaMutexConfig] = [:]
        for cfg in cfgs {
            let scene = MediaMutexScene(rawValue: cfg.scene)
            sceneMap[scene] = cfg
        }
        // 填充国际化文案
        let keys = cfgs.map { $0.i18nKey }
        httpClient.i18n.get(keys) { result in
            switch result {
            case .success(let i18nMap):
                let m: [MediaMutexScene: SceneMediaConfig] = sceneMap.compactMapValues { v in
                    let k = MediaMutexScene(rawValue: v.scene)
                    var mediaConfig: [MediaMutexType: Int] = [:]
                    if v.record >= 0 {
                        mediaConfig[.record] = v.record
                    }
                    if v.play >= 0 {
                        mediaConfig[.play] = v.play
                    }
                    if v.camera >= 0 {
                        mediaConfig[.camera] = v.camera
                    }
                    var isEnabled = true
                    if v.disable >= 0 {
                        isEnabled = false
                    }
                    return SceneMediaConfig(scene: k,
                                            rawConfig: mediaConfig,
                                            mixWithOthers: v.isMix > 0,
                                            sceneDescription: i18nMap[v.i18nKey] ?? "",
                                            isEnabled: isEnabled)
                }
                block?(m)
                Self.logger.info("fetch media mutex settings success: \(m)")
            case .failure:
                break
            }
        }
    }
}

private extension MediaMutexType {
    var desc: String {
        switch self {
        case .camera: return I18n.View_G_CameraUsed_Fill
        case .record: return I18n.View_G_Recording_Fill
        case .play:   return I18n.View_G_Playing_Fill
        default: return ""
        }
    }
}

private extension MediaMutexScene {
    var defaultDesc: String? {
        switch self {
        case .vcMeeting, .vcRing, .voip, .voipRing, .vcRingtoneAudition, .ultrawave:
            return I18n.View_G_Meeting_Fill
        case .mmPlay, .mmRecord:
            return I18n.View_G_FeishuMinutes
        case .imPlay, .imRecord:
            return I18n.View_G_Voice_Fill
        case .imVideoPlay:
            return I18n.View_G_Video_Fill
        case .imCamera, .commonCamera, .commonVideoRecord:
            return I18n.View_G_CameraUsed_Fill
        case .ccmPlay, .ccmRecord:
            return I18n.View_G_Docs_Fill
        case .microPlay, .microRecord:
            return I18n.View_G_App_Fill
        default:
            let microScene: [MediaMutexScene] = [.microPlay, .microRecord]
            for scene in microScene {
                if self.rawValue == scene.rawValue {
                    return I18n.View_G_App_Fill
                }
            }
            return I18n.View_G_Meeting_Fill
        }
    }
}

private struct MediaMutexConfig: Decodable {
    let scene: String
    let isMix: Int
    let i18nKey: String
    @DefaultDecodable.IntMinus1
    var camera: Int
    @DefaultDecodable.IntMinus1
    var record: Int
    @DefaultDecodable.IntMinus1
    var play: Int
    @DefaultDecodable.IntMinus1
    var disable: Int
}
