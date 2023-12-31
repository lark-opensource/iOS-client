//
//  AudioTracker.swift
//  LarkAudio
//
//  Created by 李晨 on 2019/7/4.
//

import UIKit
import Foundation
import Homeric
import LKCommonsTracker
import LKCommonsLogging
import LarkLocalizations
import AppReciableSDK

final class AudioTracker {

    enum From: String {
        case audioMenu = "audio_menu"
        case audioButton = "audio_button"
    }

    enum RecognizeType: String {
        case textOnly = "text_only"
        case audioAndText = "audio_and_text"
    }

    enum SendAudioType: String {
        case audioAndText = "audio_and_text"
        case audioOnly = "audio_only"
    }

    enum VoiceMsgClickFrom: String {
        /// 切换到语音转文字页按钮
        case speechToText = "speech_to_text"
        /// 切换到语音加文字页按钮
        case speechPlusText = "speech_plus_text"
        /// 切换到录音页按钮
        case recordingView = "recording_view"
        /// 按住录音按钮
        case holdToTalk = "hold_to_talk"
        /// 清空按钮
        case empty = "empty"
        /// 发送按钮
        case send = "send"
        /// 只发送语音按钮
        case onlyVoice = "only_voice"
        /// 只发送文字按钮
        case onlyText = "only_text"
        /// 点击输入框
        case clickInput = "click_input"
    }

    enum VoiceMsgClickViewType: String {
        case speechToText = "speech_to_text"
        case speechPlusText = "speech_plus_text"
        case recordingView = "recording_view"
    }

    class func trackChangeAudioLanguage(language: Lang, type: RecognizeType) {
        var action = ""
        switch language {
        case .en_US:
            action = "english"
        case .zh_CN:
            action = "chinese"
        default:
            break
        }

        Tracker.post(TeaEvent(Homeric.SET_AUDIO_TO_TEXT_LANGUAGE, params: ["action": action, "location": type.rawValue]))
    }

    static func trackSendAudio(duration: TimeInterval, sendType: SendAudioType) {
        Tracker.post(TeaEvent(Homeric.AUDIO_SEND, params: ["audio_time": duration, "way": sendType.rawValue]))
    }

    static func selectSendAudioOnly() {
        Tracker.post(TeaEvent(Homeric.SELECT_SEND_AUDIO_ONLY))
    }

    static func trackCancelAudio() {
        Tracker.post(TeaEvent(Homeric.AUDIO_RECORD_CANCEL))
    }

    static func trackTapAudioKeyboard() {
        Tracker.post(TeaEvent(Homeric.AUDIO_RECORD_CLICK))
    }

    static func sendAudioRecognizeTextMessage(isEdit: Bool) {
        Tracker.post(TeaEvent(Homeric.SEND_SPEECH_TO_TEXT_MESSAGE, params: ["is_edit": isEdit ? "y" : "n"]))
    }

    static func touchAudioWithText(from: AudioTracker.From) {
        Tracker.post(TeaEvent(Homeric.SEND_AUDIO_AND_TEXT, params: ["location": from.rawValue]))
    }

    static func trackLongpressAudioKeyboard(from: AudioTracker.From) {
        Tracker.post(TeaEvent(Homeric.AUDIO_RECORD_LONG_PRESS, params: ["location": from.rawValue]))
    }

    static func trackSpeechToText(hasResult: Bool, from: AudioTracker.From) {
        Tracker.post(TeaEvent(Homeric.SPEECH_TO_TEXT, params: ["result": hasResult ? "y" : "n", "location": from.rawValue]))
    }

    static func audioConvertServerError(type: AudioTracker.RecognizeType) {
        var page: String = ""
        switch type {
        case .audioAndText:
            page = "audio_and_text"
        case .textOnly:
            page = "text"
        }
        Tracker.post(TeaEvent(Homeric.AUDIO_CONVERT_SERVER_ERROR, params: ["page": page]))
    }

    static func imVoiceSwitchLanguaeClick(viewType: AudioTracker.RecognizeType, beforeLanguage: Lang, selectLanguage: Lang) {
        var params: [AnyHashable: Any] = [:]
        params["click"] = selectLanguage.rawValue
        switch viewType {
        case .audioAndText:
            params["view_type"] = "speech_plus_text"
        case .textOnly:
            params["view_type"] = "speech_to_text"
        }
        params["before_language"] = beforeLanguage.rawValue
        Tracker.post(TeaEvent(Homeric.IM_VOICE_SWITCH_LANGUAE_CLICK, params: params))
    }

    static func imChatVoiceMsgClick(click: VoiceMsgClickFrom, viewType: RecognizeLanguageManager.RecognizeType) {
        var params: [AnyHashable: Any] = [:]
        params["click"] = click.rawValue

        switch viewType {
        case .audioWithText:
            params["view_type"] = "speech_plus_text"
        case .text:
            params["view_type"] = "speech_to_text"
        case .audio:
            params["view_type"] = "recording_view"
        }

        if click == .holdToTalk {
            params["language"] = AudioKeyboardDataService.generateLocaleIdentifier(lang: RecognizeLanguageManager.shared.recognitionLanguage)
        }
        Tracker.post(TeaEvent(Homeric.IM_CHAT_VOICE_MSG_CLICK, params: params))
    }

    static func inlineAIEntranceView() {
        let params: [String: String] = ["from_entrance": "voice_input_toolbar",
                                        "product_type": "voice_input"]
        Tracker.post(TeaEvent("public_inline_ai_entrance_view", params: params))
    }

    static func inlineAIEntranceClick(type: String) {
        let params: [String: String] = ["from_entrance": "voice_input_toolbar",
                                        "product_type": "voice_input",
                                        "click": "quick_action",
                                        "action_type": type]
        Tracker.post(TeaEvent("public_inline_ai_entrance_click", params: params))
    }
}

extension AudioTracker {
    static func stateDescription(_ state: UIGestureRecognizer.State) -> String {
        switch state {
        case .possible: return "possible"
        case .began: return "began"
        case .changed: return "changed"
        case .ended: return "ended"
        case .cancelled: return "cancelled"
        case .failed: return "failed"
        @unknown default:
            return "unknown"
        }
    }
}

final class AudioReciableTracker {
    enum RecognitionError: Int {
        case unknow = 0
        case sdkError = 1
        case noFinalCallback = 2
        case alwaysEmptyResult = 3
    }

    static let shared: AudioReciableTracker = AudioReciableTracker()

    fileprivate static let logger = Logger.log(AudioReciableTracker.self, category: "LarkAudio")

    // 当前正在识别的 session ID
    var sessionID: String?
    // 当前 session 开始时间
    var sessionStartTime: TimeInterval = 0
    // 当前 session 最大 poers
    var sessionMaxPower: Float = 0

    func audioRecordCost(startTime: TimeInterval, endTime: TimeInterval, isOtherAudioPlaying: Bool) {
        let timeCostParams = TimeCostParams(
            biz: .Messenger,
            scene: .Chat,
            event: .audioRecord,
            cost: Int((endTime - startTime) * 1000),
            page: nil,
            extra: Extra(
                category: [
                    "is_other_audio_play": isOtherAudioPlaying
                ]
            )
        )
        Self.logger.info("audioRecordCost \(timeCostParams)")
        AppReciableSDK.shared.timeCost(params: timeCostParams)
    }

    func audioRecordError(result: OSStatus, isOtherAudioPlaying: Bool) {
        var category: [String: Any] = [:]
        category["is_other_audio_play"] = isOtherAudioPlaying
        let extra = Extra(category: category)
        let errorParams = ErrorParams(
            biz: .Messenger,
            scene: .Chat,
            event: .audioRecord,
            errorType: .Other,
            errorLevel: .Fatal,
            errorCode: Int(result),
            userAction: nil,
            page: nil,
            errorMessage: nil,
            extra: extra
        )
        Self.logger.error("audioRecordError \(errorParams)")
        AppReciableSDK.shared.error(params: errorParams)
    }

    func audioPlayStart() -> DisposedKey {
        Self.logger.info("audioPlayCost start")
        return AppReciableSDK.shared.start(biz: .Messenger, scene: .Chat, event: .audioPlay, page: nil)
    }

    func audioPlayEnd(key: DisposedKey, downloadCost: TimeInterval, extraInfo: [String: Any]) {
        Self.logger.info("audioPlayCost end")
        AppReciableSDK.shared.end(key: key, extra: Extra(
            isNeedNet: true,
            latencyDetail: [
                "download_cost": downloadCost * 1000
            ],
            extra: extraInfo
        ))
    }

    func audioPlayError(downloadFiled: Bool, extraInfo: [String: Any]) {
        let extraInfo = Extra(isNeedNet: true, latencyDetail: nil, metric: nil, category: nil, extra: extraInfo)
        let errorParams = ErrorParams(
            biz: .Messenger,
            scene: .Chat,
            event: .audioPlay,
            errorType: .Network,
            errorLevel: .Fatal,
            errorCode: downloadFiled ? 1 : 2,
            userAction: nil,
            page: nil,
            errorMessage: nil,
            extra: extraInfo)
        Self.logger.error("audioPlayError \(errorParams)")
        AppReciableSDK.shared.error(params: errorParams)
    }

    func audioRecognitionStart(sessionID: String) {
        self.sessionID = sessionID
        self.sessionStartTime = Date().timeIntervalSince1970
    }

    func audioRecognitionFirstResultAppear(sessionID: String) {
        guard self.sessionID == sessionID else {
            return
        }
        let startTime = self.sessionStartTime
        let endTime = Date().timeIntervalSince1970

        let timeCostParams = TimeCostParams(
            biz: .Messenger,
            scene: .Chat,
            event: .audioRecognition,
            cost: Int((endTime - startTime) * 1000),
            page: nil,
            extra: Extra(
                isNeedNet: true
            )
        )
        Self.logger.info("audioRecognitionFirstResultAppear \(timeCostParams)")
        AppReciableSDK.shared.timeCost(params: timeCostParams)
        self.cleanSessionInfo()
    }

    func audioRecognitionError(
        sessionID: String,
        errorType: RecognitionError,
        audioLength: TimeInterval
    ) {
        guard self.sessionID == sessionID else {
            return
        }
        let extraInfo = Extra(isNeedNet: true, latencyDetail: nil, metric: nil, category: [
            "has_voice": self.sessionMaxPower > 40
        ], extra: [
            "audio_length": audioLength * 1000
        ])
        let errorParams = ErrorParams(
            biz: .Messenger,
            scene: .Chat,
            event: .audioRecognition,
            errorType: .Network,
            errorLevel: .Fatal,
            errorCode: errorType.rawValue,
            userAction: nil,
            page: nil,
            errorMessage: nil,
            extra: extraInfo)
        Self.logger.error("audioRecognitionError \(errorParams)")
        AppReciableSDK.shared.error(params: errorParams)
        self.cleanSessionInfo()
    }

    func audioRecognitionReceivePower(sessionID: String, power: Float) {
        guard self.sessionID == sessionID else {
            return
        }
        self.sessionMaxPower = max(self.sessionMaxPower, power)
    }

    private func cleanSessionInfo() {
        self.sessionID = nil
        self.sessionStartTime = 0
        self.sessionMaxPower = 0
    }
}
