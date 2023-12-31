//
//  AudioSessionScenario.swift
//  AudioSessionStack
//
//  Created by lvdaqian on 2018/11/15.
//

import AVFoundation

public typealias ScenarioHook = (String) -> Void

/// 音频场景
public struct AudioSessionScenario {
    /// 场景标识符
    public let name: String
    /// catgory
    public let category: AVAudioSession.Category
    /// mode
    public let mode: AVAudioSession.Mode
    /// cateogry options
    public let options: AVAudioSession.CategoryOptions
    /// RouteSharingPolicy
    public let policy: AVAudioSession.RouteSharingPolicy
    /// 场景是否需要占用音轨
    public let isNeedActive: Bool

    public init(_ name: String,
                category: AVAudioSession.Category = .soloAmbient,
                mode: AVAudioSession.Mode = .default,
                options: AVAudioSession.CategoryOptions = [],
                policy: AVAudioSession.RouteSharingPolicy = .default,
                isNeedActive: Bool = true) {
        self.name = name
        self.category = category
        self.mode = mode
        self.options = options
        self.policy = policy
        self.isNeedActive = isNeedActive
    }
}

public struct ScenarioEntryOptions: OptionSet, CustomStringConvertible {

    public typealias RawValue = Int

    public let rawValue: RawValue

    public init(rawValue: RawValue) {
        self.rawValue = rawValue
    }

    /// 激活后默认扬声器(使用override配置)，仅不接外界设备时生效
    ///
    /// 适用于 enter
    public static let enableSpeakerIfNeeded    = ScenarioEntryOptions(rawValue: 1 << 0)
    /// 无视enableSpeakerIfNeeded过滤条件
    ///
    /// 适用于 enter
    public static let forceEnableSpeaker       = ScenarioEntryOptions(rawValue: 1 << 1)
    /// 强制执行音频配置聚合逻辑
    ///
    /// 适用于 enter
    public static let forceEntry               = ScenarioEntryOptions(rawValue: 1 << 2)
    /// 手动执行active
    ///
    /// 适用于 enter
    public static let manualActive             = ScenarioEntryOptions(rawValue: 1 << 3)
    /// 禁止发生 Category 切换
    ///
    /// 适用于 leave
    public static let disableCategoryChange    = ScenarioEntryOptions(rawValue: 1 << 4)

    public var description: String {
        var des: [String] = []
        if self.contains(.enableSpeakerIfNeeded) {
            des.append("enableSpeakerIfNeeded")
        }
        if self.contains(.forceEnableSpeaker) {
            des.append("forceEnableSpeaker")
        }
        if self.contains(.forceEntry) {
            des.append("forceEntry")
        }
        if self.contains(.manualActive) {
            des.append("manualActive")
        }
        if self.contains(.disableCategoryChange) {
            des.append("disableCategoryChange")
        }
        return des.joined(separator: "|")
    }
}

extension AudioSessionScenario: Hashable {
    public static func == (lhs: AudioSessionScenario, rhs: AudioSessionScenario) -> Bool {
        return lhs.name == rhs.name
            && lhs.category == rhs.category
            && lhs.mode == rhs.mode
            && lhs.options == rhs.options
            && lhs.policy == rhs.policy
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(category)
        hasher.combine(mode)
        hasher.combine(options.rawValue)
        hasher.combine(policy)
    }
}

extension AudioSessionScenario {

    private var isVoiceChatScenario: Bool {
        return self.category == .playAndRecord && [.default, .voiceChat].contains(self.mode)
    }

    func merge(_ other: AudioSessionScenario?) -> AudioSessionScenario {
        guard let other = other else {
            return self
        }

        if self == other { return self }

        var category = self.category

        switch (self.category, other.category) {
        case (.record, _), (_, .record), (.playAndRecord, _), (_, .playAndRecord):
            category = .playAndRecord
        default:
            break
        }

        var mode: AVAudioSession.Mode = self.mode
        if self.category == .playAndRecord, other.category == .playAndRecord,
           self.mode == .default, other.mode == .voiceChat {
            mode = .default
        } else if self.mode == .voiceChat || other.mode == .voiceChat {
            mode = .voiceChat
        }

        var options: AVAudioSession.CategoryOptions = self.options
        if other.isVoiceChatScenario {
            if self.isVoiceChatScenario {
                options = self.options.union(other.options)
            } else {
                options = other.options
            }
        }

        var policy: AVAudioSession.RouteSharingPolicy  = self.policy
        switch (self.policy, other.policy) {
        case (.longFormVideo, _), (_, .longFormVideo):
            if #available(iOS 13.0, *) {
                policy = .longFormVideo
            }
        case (.longFormAudio, _), (_, .longFormAudio):
            policy = .longFormAudio
        default:
            break
        }

        return AudioSessionScenario(name,
                                    category: category,
                                    mode: mode,
                                    options: options,
                                    policy: policy,
                                    isNeedActive: isNeedActive)
    }
}

public extension AudioSessionScenario {
    /// 是否正在使用当前场景
    var isActive: Bool {
        return LarkAudioSessionManager.scenarioCache.exist({ $0 == self })
    }
}

// class wrapper
final class AudioSessionScenarioWrapper: Hashable, CustomDebugStringConvertible {

    static func == (lhs: AudioSessionScenarioWrapper, rhs: AudioSessionScenarioWrapper) -> Bool {
        lhs.scenario == rhs.scenario
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(scenario)
    }

    let scenario: AudioSessionScenario
    init(scenario: AudioSessionScenario) {
        self.scenario = scenario
    }

    var debugDescription: String {
        "\(scenario)"
    }
}
