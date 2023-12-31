//
//  AVAudioSession+Description.swift
//  AudioSessionScenario
//
//  Created by fakegourmet on 2020/11/16.
//

import AVFoundation

public enum InterruptionReason {
    case unknown
    case `default`
    case appWasSuspended
    case builtInMicMuted

    var rawValue: AVAudioSession.InterruptionReason {
        switch self {
        case .default, .unknown: return .default
        case .appWasSuspended:
            if #available(iOS 14.5, *) {
                return .appWasSuspended
            } else {
                return .default
            }
        case .builtInMicMuted: return .builtInMicMuted
        }
    }
}

extension InterruptionReason: CustomStringConvertible {
    public var description: String {
        #if compiler(>=5.4)
        if #available(iOS 14.5, *) {
            return rawValue.description
        } else {
            return "unknown"
        }
        #else
        return "unknown"
        #endif
    }
}

extension AVAudioSession.Category: CustomStringConvertible {
    public var description: String {
        switch self {
        case .ambient:
            return "ambient"
        case .soloAmbient:
            return "soloAmbient"
        case .playback:
            return "playback"
        case .record:
            return "record"
        case .playAndRecord:
            return "playAndRecord"
        case .multiRoute:
            return "multiRoute"
        default:
            return "Category(rawValue: \(rawValue)"
        }
    }
}

extension AVAudioSession.Mode: CustomStringConvertible {
    public var description: String {
        switch self {
        case .default:
            return "default"
        case .gameChat:
            return "gameChat"
        case .measurement:
            return "measurement"
        case .moviePlayback:
            return "moviePlayback"
        case .spokenAudio:
            return "spokenAudio"
        case .videoChat:
            return "videoChat"
        case .videoRecording:
            return "videoRecording"
        case .voiceChat:
            return "voiceChat"
        default:
            if #available(iOS 12.0, *), self == .voicePrompt {
                return "voicePrompt"
            }
            return "Mode(rawValue: \(rawValue)"
        }
    }
}

extension AVAudioSession.CategoryOptions: CustomStringConvertible {

    public var description: String {
        var options: [String] = []

        if #available(iOS 10.0, *) {
            if self.contains(.allowAirPlay) { options.append("allowAirPlay") }
        }
        if #available(iOS 10.0, *) {
            if self.contains(.allowBluetoothA2DP) { options.append("allowBluetoothA2DP") }
        }
        if self.contains(.interruptSpokenAudioAndMixWithOthers) { options.append("interruptSpokenAudioAndMixWithOthers") }
        if self.contains(.defaultToSpeaker) { options.append("defaultToSpeaker") }
        if self.contains(.allowBluetooth) { options.append("allowBluetooth") }
        if self.contains(.duckOthers) { options.append("duckOthers") }
        if self.contains(.mixWithOthers) { options.append("mixWithOthers") }
        #if compiler(>=5.4)
        if #available(iOS 14.5, *) {
            if self.contains(.overrideMutedMicrophoneInterruption) { options.append("overrideMutedMicrophoneInterruption") }
        }
        #endif
        if options.isEmpty && rawValue != 0 { options.append("unknown") }
        if options.isEmpty { return "" }

        return options.joined(separator: "|")
    }

    public static func buildOptions(_ from: String) -> AVAudioSession.CategoryOptions {
        var option = AVAudioSession.CategoryOptions(rawValue: 0)
        let optionStrings = from.split(separator: "|")
        for optionString in optionStrings {
            switch optionString {
            case "allowAirPlay":
                if #available(iOS 10.0, *) {
                    option.insert(.allowAirPlay)
                } else {
                    AVAudioSession.logger.warn("\(optionString) is not support under iOS 10.0")
                }
            case "allowBluetoothA2DP":
                if #available(iOS 10.0, *) {
                    option.insert(.allowBluetoothA2DP)
                } else {
                    AVAudioSession.logger.warn("\(optionString) is not support under iOS 10.0")
                }
            case "interruptSpokenAudioAndMixWithOthers":
                option.insert(.interruptSpokenAudioAndMixWithOthers)
            case "defaultToSpeaker":
                option.insert(.defaultToSpeaker)
            case "allowBluetooth":
                option.insert(.allowBluetooth)
            case "duckOthers":
                option.insert(.duckOthers)
            case "mixWithOthers":
                option.insert(.mixWithOthers)
            case "overrideMutedMicrophoneInterruption":
                #if compiler(>=5.4)
                if #available(iOS 14.5, *) {
                    option.insert(.overrideMutedMicrophoneInterruption)
                } else {
                    AVAudioSession.logger.warn("\(optionString) is not support under iOS 14.5")
                }
                #else
                break
                #endif
            default:
                print("error, no category options for \(optionString)")
            }
        }

        return option
    }

    static public var knownOptions: [AVAudioSession.CategoryOptions] {
        var options: [AVAudioSession.CategoryOptions] = [.allowBluetooth, .defaultToSpeaker, .duckOthers, .interruptSpokenAudioAndMixWithOthers, .mixWithOthers]
        if #available(iOS 10.0, *) {
            options.append(.allowBluetoothA2DP)
            options.append(.allowAirPlay)
        }
        #if compiler(>=5.4)
        if #available(iOS 14.5, *) {
            options.append(.overrideMutedMicrophoneInterruption)
        }
        #endif
        return options
    }
}

extension AVAudioSession {
    static func toValues() -> [String: Any] {
        var values: [String: Any] = [:]
        values["category"] = AVAudioSession.sharedInstance().category.rawValue
        values["mode"] =  AVAudioSession.sharedInstance().mode.rawValue
        values["categoryOption"] = "\(AVAudioSession.sharedInstance().categoryOptions)"
        if #available(iOS 11.0, *) {
            values["routeSharingPolicy"] = "\(AVAudioSession.sharedInstance().routeSharingPolicy)"
        }
        values["recordPermission"] = "\(AVAudioSession.sharedInstance().recordPermission)"
        values["isOtherAudioPlaying"] = "\(AVAudioSession.sharedInstance().isOtherAudioPlaying)"
        values["secondaryAudioShouldBeSilencedHint"] = "\(AVAudioSession.sharedInstance().secondaryAudioShouldBeSilencedHint)"
        values["currentRoute"] = "\(AVAudioSession.sharedInstance().currentRoute)"
        values["preferredInput"] = "\(String(describing: AVAudioSession.sharedInstance().preferredInput))"
        if #available(iOS 13.0, *) {
            values["promptStyle"] = "\(AVAudioSession.sharedInstance().promptStyle)"
        }

        return values
    }

    static func toStats() -> [String: Any] {
        var values: [String: Any] = [:]

        values["preferredSampleRate"] = "\(AVAudioSession.sharedInstance().preferredSampleRate)"
        values["preferredIOBufferDuration"] = "\(AVAudioSession.sharedInstance().preferredIOBufferDuration)"
        values["preferredInputNumberOfChannels"] = "\(AVAudioSession.sharedInstance().preferredInputNumberOfChannels)"
        values["preferredOutputNumberOfChannels"] = "\(AVAudioSession.sharedInstance().preferredOutputNumberOfChannels)"
        values["maximumInputNumberOfChannels"] = "\(AVAudioSession.sharedInstance().maximumInputNumberOfChannels)"
        values["maximumOutputNumberOfChannels"] = "\(AVAudioSession.sharedInstance().maximumOutputNumberOfChannels)"
        values["inputGain"] = "\(AVAudioSession.sharedInstance().inputGain)"
        values["isInputGainSettable"] = "\(AVAudioSession.sharedInstance().isInputGainSettable)"
        values["isInputAvailable"] = "\(AVAudioSession.sharedInstance().isInputAvailable)"
        values["inputDataSource"] = "\(String(describing: AVAudioSession.sharedInstance().inputDataSource))"
        values["outputDataSource"] = "\(String(describing: AVAudioSession.sharedInstance().outputDataSource))"
        values["sampleRate"] = "\(AVAudioSession.sharedInstance().sampleRate)"
        values["inputNumberOfChannels"] = "\(AVAudioSession.sharedInstance().inputNumberOfChannels)"
        values["outputNumberOfChannels"] = "\(AVAudioSession.sharedInstance().outputNumberOfChannels)"
        values["outputVolume"] = "\(AVAudioSession.sharedInstance().outputVolume)"
        values["inputLatency"] = "\(AVAudioSession.sharedInstance().inputLatency)"
        values["outputLatency"] = "\(AVAudioSession.sharedInstance().outputLatency)"
        values["ioBufferDuration"] = "\(AVAudioSession.sharedInstance().ioBufferDuration)"

        return values
    }
}

extension AVAudioSessionRouteDescription {
    open override var description: String {
        return "I:\(inputs) O:\(outputs)"
    }
}

extension AVAudioSessionPortDescription {
    open override var description: String {
        return "\(portType.rawValue)-\(portName)"
    }
}

extension AVAudioSession.RouteChangeReason: CustomStringConvertible {
    public var description: String {

        switch self {
        case .unknown: return "unknown"

        case .newDeviceAvailable: return "newDeviceAvailable"

        case .oldDeviceUnavailable: return "oldDeviceUnavailable"

        case .categoryChange: return "categoryChange"

        case .override: return "override"

        case .wakeFromSleep: return "wakeFromSleep"

        case .noSuitableRouteForCategory: return "noSuitableRouteForCategory"

        case .routeConfigurationChange: return "routeConfigurationChange"
        @unknown default:
            return "unknown: \(rawValue)"
        }
    }

}

extension AVAudioSession.InterruptionType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .began: return "began"
        case .ended: return "ended"
        @unknown default:
            return "unknown: \(rawValue)"
        }
    }

}

extension AVAudioSession.InterruptionOptions: CustomStringConvertible {
    public var description: String {
        switch self {
        case .shouldResume: return "shouldResume"
        default:
            return "unknown: \(rawValue)"
        }
    }

}

extension AVAudioSession.InterruptionReason: CustomStringConvertible {
    public var description: String {
        switch self {
        case .appWasSuspended: return "appWasSuspended"
        case .builtInMicMuted: return "builtInMicMuted"
        case .default: return "default"
        default:
            return "unknown: \(rawValue)"
        }
    }

    public var wrappedValue: InterruptionReason {
        switch self {
        case .default: return .default
        case .appWasSuspended: return .appWasSuspended
        case .builtInMicMuted: return .builtInMicMuted
        default: return .unknown
        }
    }
}

extension AVAudioSession.SilenceSecondaryAudioHintType: CustomStringConvertible {
    public var description: String {

        switch self {
        case .begin: return "begin"
        case .end: return "end"
        @unknown default:
            return "unknown: \(rawValue)"
        }
    }

}

extension Notification {
    var routeChangeReason: AVAudioSession.RouteChangeReason? {
        guard let value = userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt else {
            return nil
        }

        return AVAudioSession.RouteChangeReason(rawValue: value)
    }

    var previousRoute: AVAudioSessionRouteDescription? {
        return userInfo?[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription
    }

    var currentRoute: AVAudioSessionRouteDescription? {
        return LarkAudioSession.shared._currentRoute
    }

    var interruptionOptions: AVAudioSession.InterruptionOptions? {
        guard let value = userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt else {
            return nil
        }

        return AVAudioSession.InterruptionOptions(rawValue: value)
    }

    #if compiler(>=5.4)
    @available(iOS 14.5, *)
    var interruptionReason: AVAudioSession.InterruptionReason? {
        guard let value = userInfo?[AVAudioSessionInterruptionReasonKey] as? UInt else {
            return nil
        }

        return AVAudioSession.InterruptionReason(rawValue: value)
    }
    #endif

    var wrappedInterruptionReason: InterruptionReason? {
        #if compiler(>=5.4)
        if #available(iOS 14.5, *) {
            return interruptionReason?.wrappedValue
        } else {
            return .unknown
        }
        #else
        return .unknown
        #endif
    }

    var interruptionType: AVAudioSession.InterruptionType? {
        guard let value = userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt else {
            return nil
        }

        return AVAudioSession.InterruptionType(rawValue: value)
    }

    var silenceSecondaryAudioHintType: AVAudioSession.SilenceSecondaryAudioHintType? {
        guard let value = userInfo?[AVAudioSessionSilenceSecondaryAudioHintTypeKey] as? UInt else {
            return nil
        }

        return AVAudioSession.SilenceSecondaryAudioHintType(rawValue: value)
    }

    var volumeInfo: AudioVolumeInfo? {
        guard let userInfo = userInfo else { return nil }
        return AudioVolumeInfo(
            audioVolume: userInfo["AVSystemController_AudioVolumeNotificationParameter"] as? CGFloat ?? userInfo["Volume"] as? CGFloat ?? 0.0,
            userVolumeAboveEUVolumeLimit: userInfo["AVSystemController_UserVolumeAboveEUVolumeLimitNotificationParameter"] as? CGFloat ?? 0.0,
            changeReason: userInfo["AVSystemController_AudioVolumeChangeReasonNotificationParameter"] as? String ?? userInfo["Reason"] as? String ?? "",
            category: userInfo["AVSystemController_AudioCategoryNotificationParameter"] as? String ?? userInfo["AudioCategory"] as? String ?? ""
        )
    }
}

extension AVAudioSession.RouteSharingPolicy: CustomStringConvertible {
    public var description: String {
        if #available(iOS 13.0, *) {
            switch self {
            case .independent:
                return "independent"
            case .longFormVideo:
                return "longFormVideo"
            case .longFormAudio:
                return "longFormAudio"
            case .longForm:
                return "longForm"
            case .default:
                return "default"
            default:
                return "unknown(\(rawValue))"
            }
        } else {
            switch self {
            case .independent:
                return "independent"
            case .longForm:
                return "longForm"
            case .default:
                return "default"
            default:
                return "unknown(\(rawValue))"
            }
        }
    }
}

extension AVAudioSession.RecordPermission: CustomStringConvertible {
    public var description: String {
        switch self {
        case .denied:
            return "denied"
        case .granted:
            return "granted"
        case .undetermined:
            return "undetermined"
        default:
            return "unknown"
        }
    }
}

extension AVAudioSession.PromptStyle: CustomStringConvertible {
    public var description: String {
        switch self {
        case .none:
            return "none"
        case .normal:
            return "normal"
        case .short:
            return "short"
        default:
            return "unknown"
        }
    }
}

extension AVAudioSession.PortOverride: CustomStringConvertible {
    public var description: String {
        switch self {
        case .none:
            return "none"
        case .speaker:
            return "speaker"
        default:
            return "unknown"
        }
    }
}

extension AVAudioSession.SetActiveOptions: CustomStringConvertible {
    public var description: String {
        switch self {
        case .notifyOthersOnDeactivation:
            return "notifyOthersOnDeactivation"
        default:
            return "SetActiveOptions(rawValue: \(rawValue))"
        }
    }
}
