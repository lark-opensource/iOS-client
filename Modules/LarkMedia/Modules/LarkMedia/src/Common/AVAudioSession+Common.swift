//
//  AVAudioSession+Common.swift
//  AudioSessionScenario
//
//  Created by fakegourmet on 2022/2/21.
//

import Foundation
import AVFoundation
import LKCommonsLogging

public enum AudioOutput {
    case unknown
    case speaker
    case receiver
    case headphones
    case bluetooth
}

public extension AVAudioSessionPortDescription {
    var audioOutput: AudioOutput {
        switch self.portType {
        case .builtInReceiver:
            return .receiver
        case .builtInSpeaker:
            return .speaker
        case .bluetoothA2DP, .bluetoothLE, .bluetoothHFP, .airPlay, AVAudioSession.Port(rawValue: "Bluetooth"):
            return .bluetooth
        case .headphones:
            return .headphones
        default:
            return .unknown
        }
    }

    var isSpeakerOn: Bool {
        self.portType == .builtInSpeaker
    }
}

public extension AVAudioSessionRouteDescription {
    var audioOutput: AudioOutput {
        if let output = outputs.first {
            return output.audioOutput
        }
        return .unknown
    }

    var isSpeakerOn: Bool {
        if let output = outputs.first {
            return output.isSpeakerOn
        }
        return false
    }
}

public struct InterruptionInfo {
    public let type: AVAudioSession.InterruptionType
    public let options: AVAudioSession.InterruptionOptions
    public let reason: InterruptionReason
}

public struct AudioVolumeInfo {
    public let audioVolume: CGFloat
    public let userVolumeAboveEUVolumeLimit: CGFloat
    public let changeReason: String
    public let category: String

    public init(audioVolume: CGFloat = 0,
                userVolumeAboveEUVolumeLimit: CGFloat = 0,
                changeReason: String = "",
                category: String = "") {
        self.audioVolume = audioVolume
        self.userVolumeAboveEUVolumeLimit = userVolumeAboveEUVolumeLimit
        self.changeReason = changeReason
        self.category = category
    }

    public var isLowestButNotZero: Bool {
        return self.audioVolume < 0.1 && self.audioVolume > 0
    }
}

extension AVAudioSession {
    static var logger: Log { LarkAudioSession.logger }
}
