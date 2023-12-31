//
//  AudioRecognizeServiceImpl.swift
//  LarkSDK
//
//  Created by 李晨 on 2019/3/13.
//

import Foundation
import LarkSDKInterface
import LarkModel
import LKCommonsLogging
import RxSwift
import LarkLocalizations
import RustPB
import LarkContainer

final class AudioRecognizeServiceImpl: AudioRecognizeService {
    static let logger = Logger.log(AudioRecognizeServiceImpl.self, category: "AudioRecognizeServiceImpl")

    let audioAPI: AudioAPI
    internal var chatId: String?
    let disposeBag: DisposeBag = DisposeBag()
    let pushCenter: PushNotificationCenter

    init(audioAPI: AudioAPI, pushCenter: PushNotificationCenter) {
        self.audioAPI = audioAPI
        self.pushCenter = pushCenter
        configPushCenter()
    }

    var resultSubject: ReplaySubject<AudioRecognizeResult> = ReplaySubject<AudioRecognizeResult>.create(bufferSize: 1)
    var result: Observable<AudioRecognizeResult> {
        return resultSubject.asObservable()
    }

    private var lastResult: AudioRecognizeResult?

    private var lastRecognizeUploadID: String?
    private var lastRecognizeTime: TimeInterval = 0

    func bindChatId(chatId: String) {
        self.chatId = chatId
    }

    func checkLastRcognitionFinish() -> Bool {
        if Date().timeIntervalSince1970 - self.lastRecognizeTime > 15 {
            return true
        }
        return lastRecognizeUploadID == nil
    }

    func updateAudioState(uploadID: String, sequenceId: Int32, state: AudioRecognizeState, callback: ((Error?) -> Void)?) {
        var data = Data()
        var recognize = false
        var finish = false
        var cancel = false
        var deleteAudioResource = false

        switch state {
        case .cancel:
            cancel = true
        case .recognizeFinish(let audioData):
            data = audioData
            deleteAudioResource = true
            finish = true
            recognize = true
        case .uploadFinish(let audioData):
            data = audioData
            finish = true
        case .data(let audioData):
            data = audioData
        case .recognizeData(let audioData):
            data = audioData
            recognize = true
        }
        AudioRecognizeServiceImpl.logger.info(
            "update audio state",
            additionalData: [
                "uploadID": uploadID,
                "sequenceId": "\(sequenceId)",
                "finish": "\(finish)",
                "cancel": "\(cancel)",
                "deleteAudioResource": "\(deleteAudioResource)"
            ]
        )

        self.audioAPI.uploadAudio(
            uploadID: uploadID,
            data: data,
            sequenceId: sequenceId,
            recognize: recognize,
            finish: finish,
            cancel: cancel,
            deleteAudioResource: deleteAudioResource)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (response) in
                let result = AudioRecognizeResult(uploadID: response.uploadID, seqID: response.sequenceID, text: response.audio2Text, finish: finish)
                self?.receiveAudioRecognizeResult(result: result, recognizeFailed: false)
                callback?(nil)
            }, onError: { [weak self] (error) in
                AudioRecognizeServiceImpl.logger.error("upload audio data failed", error: error)
                let result = AudioRecognizeResult(uploadID: uploadID, seqID: sequenceId, text: "", finish: true, error: error)
                self?.receiveAudioRecognizeResult(result: result, recognizeFailed: true)
                callback?(error)
            }).disposed(by: self.disposeBag)
    }

    private func configPushCenter() {
        pushCenter.observable(for: PushAudioRecognition.self)
            .subscribe { push in
                let result = AudioRecognizeResult(
                    uploadID: push.push.sourceID,
                    seqID: push.push.sequenceID,
                    text: push.push.result,
                    finish: push.push.isEnd,
                    diffIndexSlice: push.push.diffIndexSlice
                )
                self.receiveAudioRecognizeResult(result: result, recognizeFailed: false)
            } onError: { error in
                AudioRecognizeServiceImpl.logger.error("NewAudioRecord: push \(error)")
            }.disposed(by: disposeBag)
    }

    func speechRecognition(
        uploadID: String,
        sequenceId: Int32,
        audioData: Data,
        action: RustPB.Im_V1_SendSpeechRecognitionRequest.Action,
        speechLocale: String,
        usePushResponse: Bool,
        uploadAudio: Bool,
        callback: ((AudioRecognizeResult?, Error?) -> Void)?) {
        self.lastRecognizeUploadID = uploadID
        self.lastRecognizeTime = Date().timeIntervalSince1970
        let deviceLocale: String = LanguageManager.currentLanguage.localeIdentifier

        AudioRecognizeServiceImpl.logger.info(
            "speech recognition",
            additionalData: [
                "uploadID": uploadID,
                "sequenceId": "\(sequenceId)",
                "action": "\(action)",
                "speechLocale": "\(speechLocale)"
            ]
        )

        self.audioAPI.speechRecognition(
            chatId: self.chatId ?? "",
            uploadID: uploadID,
            audioData: audioData,
            sequenceId: sequenceId,
            deviceLocale: deviceLocale.lowercased(),
            speechLocale: speechLocale.lowercased(),
            action: action,
            audioRate: 16_000,
            audioFormat: "opus",
            shouldDiffResult: true,
            usePushResponse: usePushResponse,
            uploadAudio: uploadAudio)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (response) in
                var recognizeResult: AudioRecognizeResult?
                if response.isAvailable {
                    let result = AudioRecognizeResult(
                        uploadID: response.sourceID,
                        seqID: response.sequenceID,
                        text: response.result,
                        finish: response.isEnd,
                        diffIndexSlice: response.diffIndexSlice
                    )
                    self?.receiveAudioRecognizeResult(result: result, recognizeFailed: false)
                    if result.finish {
                        self?.cleanLastRecognizeUploadID(uploadID: response.sourceID)
                    }
                    recognizeResult = result
                }
                callback?(recognizeResult, nil)
            }, onError: { [weak self] (error) in
                guard let `self` = self else { return }
                AudioRecognizeServiceImpl.logger.error(
                    "speech recognitio data failed",
                    additionalData: ["uploadID": uploadID, "seqID": "\(sequenceId)"],
                    error: error
                )
                let result = AudioRecognizeResult(uploadID: uploadID, seqID: sequenceId, text: "", finish: true, error: error)
                var recognizeFailed = true
                if let apiError = error.underlyingError as? APIError,
                    case .recognitionWithEmptyResult = apiError.type {
                    recognizeFailed = false
                }
                self.receiveAudioRecognizeResult(result: result, recognizeFailed: recognizeFailed)
                callback?(result, recognizeFailed ? error : nil)
                self.cleanLastRecognizeUploadID(uploadID: uploadID)
            }).disposed(by: self.disposeBag)
    }

    func receiveAudioRecognizeResult(result: AudioRecognizeResult, recognizeFailed: Bool) {

        let sendResult = { (result: AudioRecognizeResult) in
            self.lastResult = result
            self.resultSubject.onNext(result)
        }

        var result = result
        // 第一次收到识别结果
        guard let last = self.lastResult else {
            sendResult(result)
            return
        }

        // 收到不同的识别结果
        if last.uploadID != result.uploadID {
            sendResult(result)
            return
        }

        // 如果新收到的结果不是最新的 则不发通知
        if last.finish ||
            last.seqID > result.seqID && !result.finish {
            return
        }

        // 识别错误继续使用上一次的结果
        if recognizeFailed {
            result.text = last.text
        }

        sendResult(result)
    }

    func cleanLastRecognizeUploadID(uploadID: String) {
        if uploadID == self.lastRecognizeUploadID {
            self.lastRecognizeUploadID = nil
        }
    }
}
