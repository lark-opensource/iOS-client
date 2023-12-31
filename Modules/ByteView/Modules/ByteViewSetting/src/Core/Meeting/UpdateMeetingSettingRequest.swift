//
//  UpdateMeetingSettingRequest.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/4/26.
//

import Foundation
import ByteViewNetwork

public struct UpdateMeetingSettingRequest {
    public init() {}

    public var handsUpEmojiKey: String?
    public var isMicSpeakerDisabled: Bool?
    public var isAutoTranslationOn: Bool?
    public var targetTranslateLanguage: String?
    public var translateRule: TranslateDisplayRule?
    public var isVideoMirrored: Bool?
    public var isFrontCameraEnabled: Bool?
    public var isSystemPhoneCalling: Bool?
    public var isInMeetCameraMuted: Bool?
    public var isInMeetMicrophoneMuted: Bool?
    public var isInMeetCameraEffectOn: Bool?
    public var isExternalMeeting: Bool?
    public var dataMode: DataMode?
    public var labEffect: String?
}
