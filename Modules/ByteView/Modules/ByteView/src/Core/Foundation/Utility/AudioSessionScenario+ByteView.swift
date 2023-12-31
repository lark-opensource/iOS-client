//
//  AudioSessionScenario+ByteView.swift
//  ByteView
//
//  Created by kiri on 2020/8/7.
//

import Foundation
import AVFoundation
import LarkMedia
import ByteViewMeeting
import UniverseDesignIcon

extension AudioSessionScenario {
    static func byteviewScenario(session: MeetingSession) -> AudioSessionScenario {
        if session.state == .ringing {
            return AudioSessionScenario("ringing", category: .soloAmbient, mode: .default)
        } else {
            let isCallKit = session.isCallKit
            return AudioSessionScenario("byteView_\(isCallKit ? "callkit" : "normal")_\(session.sessionId)",
                                        category: byteViewCategory, mode: byteViewMode,
                                        options: isCallKit ? byteViewCallKitOptions : byteViewOptions)
        }
    }

    /// callkit的scenario不能做session隔离（和session不是一个纬度）
    /// https://bytedance.feishu.cn/docs/doccnAgvP9dFN9WktakiAd1qEYg#
    static var callKitInternalScenario = AudioSessionScenario("byteViewCallKitInternal",
                                                              category: AudioSessionScenario.byteViewCategory,
                                                              mode: AudioSessionScenario.byteViewMode,
                                                              options: AudioSessionScenario.byteViewCallKitOptions)

    static var ultrawave = AudioSessionScenario("ultrawave", category: .playAndRecord, mode: .default, options: [.allowAirPlay, .allowBluetooth, .allowBluetoothA2DP])
}

extension AudioSessionScenario {
    // byteViewCallKit Scenario 中需要使用 和 byteView Scenario 相同的配置
    static let byteViewCategory: AVAudioSession.Category = .playAndRecord
    static let byteViewMode: AVAudioSession.Mode = .voiceChat
    static let byteViewOptions: AVAudioSession.CategoryOptions = [.allowBluetooth, .allowBluetoothA2DP, .mixWithOthers, .duckOthers, .allowAirPlay]
    // CallKit 设置 mixWithOthers 会导致 AudioSession 被闹钟打断后无法恢复
    static let byteViewCallKitOptions: AVAudioSession.CategoryOptions = [.allowBluetooth, .allowBluetoothA2DP, .allowAirPlay]
}

extension AVAudioSession.RouteChangeReason {
    var isDeviceChanged: Bool {
        return self == .newDeviceAvailable || self == .oldDeviceUnavailable
    }
}

extension AudioOutput {

    enum ImageState {
        case normal
        case highlighted
        case disabled
    }

    func imageKey(isSolid: Bool) -> UDIconType {
        switch self {
        case .receiver: return isSolid ? .earFilled : .earOutlined
        case .headphones: return .headphoneFilled
        case .bluetooth: return isSolid ? .bluetoothFilled : .bluetoothOutlined
        default: return isSolid ? .speakerFilled : .speakerOutlined
        }
    }

    func image(isSolid: Bool = true, dimension: CGFloat = 22, color: UIColor? = nil) -> UIImage {
        let iconType = imageKey(isSolid: isSolid)
        return UDIcon.getIconByKey(iconType, iconColor: color, size: CGSize(width: dimension, height: dimension))
    }

    var i18nText: String {
        switch self {
        case .receiver:
            return I18n.View_G_Receiver
        case .headphones:
            return I18n.View_G_Headphones
        case .bluetooth:
            return I18n.View_G_Bluetooth
        default:
            return I18n.View_VM_Speaker
        }
    }

    var trackText: String {
        switch self {
        case .speaker:
            return "speaker"
        case .receiver:
            return "earpiece"
        case .headphones:
            return "headphone"
        case .bluetooth:
            return "bluetooth"
        default:
            return "another"
        }
    }
}
