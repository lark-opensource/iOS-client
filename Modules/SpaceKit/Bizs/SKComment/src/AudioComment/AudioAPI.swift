//
//  AudioAPI.swift
//  SpaceKit
//
//  Created by maxiao on 2019/4/16.
//  Copyright © 2019 Bytedance. All rights reserved.
//
//  swiftlint:disable 

import RustPB
import RxSwift
import LarkRustClient

public typealias SendSpeechRecognitionResponse = RustPB.Im_V1_SendSpeechRecognitionResponse
public typealias SendSpeechRecognitionRequest = RustPB.Im_V1_SendSpeechRecognitionRequest

public extension ObservableType {
    func subscribeOn(_ scheduler: ImmediateSchedulerType? = nil) -> Observable<Self.Element> {
        if let scheduler = scheduler {
            return self.subscribeOn(scheduler)
        }
        return self.asObservable()
    }
}

protocol AudioAPI {

    func speechRecognition(
        uploadID: String,
        audioData: Data,
        sequenceId: Int32,
        deviceLocale: String,
        speechLocale: String,
        action: SendSpeechRecognitionRequest.Action,
        audioRate: Int32,
        audioFormat: String,
        shouldDiffResult: Bool) -> Observable<SendSpeechRecognitionResponse>
}

class AudioAPIImpl: AudioAPI {

    public let client: RustService
    public let scheduler: ImmediateSchedulerType?

    public init(client: RustService, onScheduler: ImmediateSchedulerType? = nil) {
        self.client = client
        self.scheduler = onScheduler
    }

    func speechRecognition(
        uploadID: String,
        audioData: Data,
        sequenceId: Int32,
        deviceLocale: String,
        speechLocale: String,
        action: SendSpeechRecognitionRequest.Action,
        audioRate: Int32,
        audioFormat: String,
        shouldDiffResult: Bool
    ) -> Observable<SendSpeechRecognitionResponse> {
        var request = SendSpeechRecognitionRequest()
        request.sourceID = uploadID
        request.audioData = audioData
        request.sequenceID = sequenceId
        request.deviceLocale = deviceLocale
        request.speechLocale = speechLocale
        request.action = action
        request.audioRate = audioRate
        request.audioFormat = audioFormat
        request.shouldDiffResult = shouldDiffResult
        return self.client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

}
