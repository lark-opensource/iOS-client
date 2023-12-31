//
//  AudioRecognizeService.swift
//  LarkSDKInterface
//
//  Created by 李晨 on 2019/3/13.
//

import Foundation
import RxSwift
import LarkModel
import RustPB

public struct AudioRecognizeResult {
    public var uploadID: String
    public var seqID: Int32
    public var text: String
    public var finish: Bool
    public var diffIndexSlice: [Int32]
    public var error: Error?

    public init(
        uploadID: String,
        seqID: Int32,
        text: String,
        finish: Bool,
        diffIndexSlice: [Int32] = [],
        error: Error? = nil) {
        self.uploadID = uploadID
        self.seqID = seqID
        self.text = text
        self.finish = finish
        self.diffIndexSlice = diffIndexSlice
        self.error = error
    }
}

public enum AudioRecognizeState {
    case uploadFinish(Data)     // 数据上传结束 准备发送语音消息
    case recognizeFinish(Data)  // 数据上传结束 并且删除本地缓存数据
    case cancel                 // 取消上传数据
    case data(Data)             // 分片上传数据
    case recognizeData(Data)    // 分片上传数据 并且开启识别
}

public protocol AudioRecognizeService {
    var result: Observable<AudioRecognizeResult> { get }

    func checkLastRcognitionFinish() -> Bool

    func bindChatId(chatId: String)

    func receiveAudioRecognizeResult(
        result: AudioRecognizeResult,
        recognizeFailed: Bool
    )

    // 分片上传音频数据
    func updateAudioState(
        uploadID: String,
        sequenceId: Int32,
        state: AudioRecognizeState,
        callback: ((Error?) -> Void)?)

    // 语音识别接口
    func speechRecognition(
        uploadID: String,
        sequenceId: Int32,
        audioData: Data,
        action: RustPB.Im_V1_SendSpeechRecognitionRequest.Action,
        speechLocale: String,
        usePushResponse: Bool,
        uploadAudio: Bool, // uploadAudio：语音+文字场景边识别边上传优化
        callback: ((AudioRecognizeResult?, Error?) -> Void)?)
}

public extension AudioRecognizeService {
    func speechRecognition(
        uploadID: String,
        sequenceId: Int32,
        audioData: Data,
        action: RustPB.Im_V1_SendSpeechRecognitionRequest.Action,
        speechLocale: String,
        uploadAudio: Bool,
        callback: ((AudioRecognizeResult?, Error?) -> Void)?) {
            self.speechRecognition(uploadID: uploadID, sequenceId: sequenceId, audioData: audioData, action: action,
                                   speechLocale: speechLocale, usePushResponse: false, uploadAudio: uploadAudio, callback: callback)
        }
}
