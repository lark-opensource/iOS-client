//
//  AudioAPI.swift
//  LarkSDKInterface
//
//  Created by 李晨 on 2019/3/9.
//

import Foundation
import RxSwift
import LarkModel
import RustPB

public protocol AudioAPI {
    func uploadAudio(
        uploadID: String,
        data: Data,
        sequenceId: Int32,
        recognize: Bool,
        finish: Bool,
        cancel: Bool,
        deleteAudioResource: Bool) -> Observable<RustPB.Media_V1_UploadAudioDataResponse>

    // swiftlint:disable function_parameter_count
    func speechRecognition(
        chatId: String,
        uploadID: String,
        audioData: Data,
        sequenceId: Int32,
        deviceLocale: String,
        speechLocale: String,
        action: RustPB.Im_V1_SendSpeechRecognitionRequest.Action,
        audioRate: Int32,
        audioFormat: String,
        shouldDiffResult: Bool,
        usePushResponse: Bool,
        // uploadAudio：语音+文字场景边识别边上传优化
        uploadAudio: Bool) -> Observable<RustPB.Im_V1_SendSpeechRecognitionResponse>
    // swiftlint:enable function_parameter_count

    // 语音+文字场景边识别边上传优化，用户点击取消时调用，取消语音上传
    func abortUploadAudio(uploadID: String) -> Observable<Void>

    func toggleTextOnAudio(messageID: String, hideVoice2Text: Bool) -> Observable<Void>

    func recognitionAudioMessage(
        messageID: String,
        audioRate: Int32,
        audioFormat: String,
        deviceLocale: String) -> Observable<Void>
}
