//
//  UpdatingParticipantSettings.swift
//  ByteViewNetwork
//
//  Created by kiri on 2022/10/15.
//

import Foundation

public struct UpdatingParticipantSettings: Equatable {
    public init() {}
    public var isMicrophoneMuted: Bool?
    public var isCameraMuted: Bool?
    public var microphoneStatus: ParticipantSettings.EquipmentStatus?
    public var cameraStatus: ParticipantSettings.EquipmentStatus?
    public var enableSubtitleRecord: Bool?
    public var isTranslationOn: Bool?
    public var spokenLanguage: String?
    public var subtitleLanguage: String?
    public var transcriptLanguage: String?
    public var micHandsStatus: ParticipantHandsStatus?
    public var cameraHandsStatus: ParticipantHandsStatus?
    public var interpreterSetting: UpdatingInterpreterSetting?
    public var inMeetingName: String?
    public var audioMode: ParticipantSettings.AudioMode?
    public var syncRoom: SyncRoom?
    public var conditionEmojiInfo: ParticipantSettings.ConditionEmojiInfo?
    public var mobileCallingStatus: ParticipantSettings.MobileCallingStatus?
    public var attendeeSettings: WebinarAttendeeSettings?
    /// 其他人进出/离开会议时是否有提示音
    public var playEnterExitChimes: Bool?

    public struct SyncRoom: Equatable {
        public var targetToJoinTogether: ByteviewUser?

        public init(targetToJoinTogether: ByteviewUser?) {
            self.targetToJoinTogether = targetToJoinTogether
        }
    }
}

public struct UpdatingInterpreterSetting: Equatable {
    public init(interpretingLanguage: InterpreterSetting.LanguageType? = nil,
                confirmStatus: InterpreterSetting.ConfirmStatus? = nil) {
        self.interpretingLanguage = interpretingLanguage
        self.confirmStatus = confirmStatus
    }

    public var interpretingLanguage: InterpreterSetting.LanguageType?
    public var confirmStatus: InterpreterSetting.ConfirmStatus?
}

extension UpdatingParticipantSettings {
    var pbType: PBParticipantSettings {
        var settings = PBParticipantSettings()
        if let value = isMicrophoneMuted {
            settings.isMicrophoneMuted = value
        }
        if let value = isCameraMuted {
            settings.isCameraMuted = value
        }
        if let value = microphoneStatus {
            settings.microphoneStatus = value.pbType
        }
        if let value = cameraStatus {
            settings.cameraStatus = value.pbType
        }
        if let value = audioMode {
            settings.audioMode = value.pbType
        }
        if let value = enableSubtitleRecord {
            settings.enableSubtitleRecord = value
        }
        if let value = isTranslationOn {
            settings.isTranslationOn = value
        }
        if let value = spokenLanguage {
            settings.spokenLanguage = value
        }
        if let value = subtitleLanguage {
            settings.subtitleLanguage = value
        }
        if let value = transcriptLanguage {
            settings.transcriptLanguage = value
        }
        if let value = micHandsStatus {
            settings.handsStatus = .init(rawValue: value.rawValue) ?? .unknownHandsStatus
        }
        if let value = cameraHandsStatus {
            settings.cameraHandsStatus = .init(rawValue: value.rawValue) ?? .unknownHandsStatus
        }
        if let value = interpreterSetting {
            settings.interpreterSetting = value.pbType
        }
        if let value = inMeetingName {
            settings.inMeetingName = value
        }
        if let value = syncRoom {
            settings.syncRoom = .init()
            if let room = value.targetToJoinTogether {
                settings.syncRoom.targetToJoinTogether = room.pbType
            }
        }
        if let value = conditionEmojiInfo {
            settings.conditionEmojiInfo = value.pbType
        }
        if let value = mobileCallingStatus{
            settings.mobileCallingStatus = value.pbType
        }

        if let value = attendeeSettings {
            settings.attendeeSettings = value.pbType
        }
        if let value = playEnterExitChimes {
            settings.playEnterExitChimes = value
        }
        return settings
    }
}

extension UpdatingInterpreterSetting {
    var pbType: PBInterpreterSetting {
        var settings = PBInterpreterSetting()
        if let value = interpretingLanguage {
            settings.interpretingLanguage = value.pbType
        }
        if let value = confirmStatus {
            settings.confirmStatus = .init(rawValue: value.rawValue) ?? .reserve
        }
        return settings
    }
}

private extension ParticipantSettings.EquipmentStatus {
    var pbType: PBParticipantSettings.EquipmentStatus {
        switch self {
        case .unknown:
            return .unknown
        case .notExist:
            return .notExist
        case .noPermission:
            return .noPermission
        case .unavailable:
            return .unavailable
        case .normal:
            return .normal
        }
    }
}

private extension ParticipantSettings.AudioMode {
    var pbType: PBParticipantSettings.AudioMode {
        switch self {
        case .unknown:
            return .unknown
        case .internet:
            return .internet
        case .pstn:
            return .pstn
        case .noConnect:
            return .noConnect
        }
    }
}

private extension ParticipantSettings.MobileCallingStatus {
    var pbType: PBParticipantSettings.MobileCallingStatus {
        switch self {
        case .unknown:
            return .unknown
        case .idle:
            return .idle
        case .busy:
            return .busy
        }
    }
}

private extension ParticipantSettings.ConditionEmojiInfo {
    var pbType: PBConditionEmojiInfo {
        var info = PBConditionEmojiInfo()
        if let val = self.isStepUp {
            info.isStepUp = val
        }
        if let val = self.isHandsUp {
            info.isHandsUp = val
        }
        if let val = self.handsUpTime {
            info.handsUpTime = val
        }
        info.handsUpEmojiKey = self.handsUpEmojiKey
        return info
    }
}
