//
//  RustAudioAPI.swift
//  LarkSDK
//
//  Created by 李晨 on 2019/3/9.
//

import Foundation
import RxSwift
import RustPB
import LarkModel
import LarkSDKInterface

final class RustAudioAPI: LarkAPI, AudioAPI {
    func toggleTextOnAudio(messageID: String, hideVoice2Text: Bool) -> Observable<Void> {
        var request = ToggleTextOnAudioRequest()
        request.messageID = messageID
        request.hideVoice2Text = hideVoice2Text
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    func uploadAudio(
        uploadID: String,
        data: Data,
        sequenceId: Int32,
        recognize: Bool,
        finish: Bool,
        cancel: Bool,
        deleteAudioResource: Bool
    ) -> Observable<RustPB.Media_V1_UploadAudioDataResponse> {

        var request = UploadAudioDataRequest()
        request.uploadID = uploadID
        request.sequenceID = sequenceId
        request.data = data
        request.audioType = "opus"
        request.needRecognize = recognize
        request.finish = finish
        request.cancel = cancel
        request.deleteAudioResource = deleteAudioResource
        return self.client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

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
        uploadAudio: Bool
    ) -> Observable<RustPB.Im_V1_SendSpeechRecognitionResponse> {
        var request = RustPB.Im_V1_SendSpeechRecognitionRequest()
        request.sourceID = uploadID
        request.audioData = audioData
        request.sequenceID = sequenceId
        request.deviceLocale = deviceLocale
        request.speechLocale = speechLocale
        request.action = action
        request.pushResponse = usePushResponse
        request.audioRate = audioRate
        request.audioFormat = audioFormat
        request.shouldDiffResult = shouldDiffResult
        request.chatID = chatId
        request.uploadAudio = uploadAudio
        return self.client.sendAsyncRequest(request).subscribeOn(scheduler)
    }
    // swiftlint:enable function_parameter_count

    // 取消语音上传：语音识别时边识别边上传
    func abortUploadAudio(uploadID: String) -> Observable<Void> {
        var request = RustPB.Media_V1_AbortUploadAudioRequest()
        request.sourceID = uploadID
        return self.client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    func recognitionAudioMessage(
        messageID: String,
        audioRate: Int32,
        audioFormat: String,
        deviceLocale: String
    ) -> Observable<Void> {
        var request = GetAudioMessageRecognitionRequest()
        request.messageID = messageID
        request.audioRate = audioRate
        request.audioFormat = audioFormat
        request.deviceLocale = deviceLocale
        return self.client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

}
