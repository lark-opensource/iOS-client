//
//  SendAudioInterfaceTest.swift
//  LarkSendMessage-Unit-Tests
//
//  Created by 李瑞 on 2023/2/8.
//

import Foundation
import XCTest
import LarkSDKInterface // SendMessageAPI
import LarkContainer // InjectedSafeLazy
import RxSwift // DisposeBag
import LarkModel // AudioContent
import RustPB // Media_V1_UploadAudioDataResponse
import LarkAudioKit // OpusStreamUtil
import LarkLocalizations // Lang
@testable import LarkSendMessage

// 测试sendAudio接口，测试接口可用性，输入与接收push的一致性
final class SendAudioInterfaceTest: CanSkipTestCase {
    @InjectedSafeLazy private var sendMessageAPI: SendMessageAPI
    @InjectedSafeLazy private var audioAPI: AudioAPI
    @InjectedSafeLazy private var resourceAPI: ResourceAPI
    @InjectedSafeLazy private var chatAPI: ChatAPI
    /// 测试账号信息
    private let groupChatID = "7112368233654714369"

    // 发送语音+文字消息，测试接口调用是否成功，校验发送消息与接收push的文本内容一致
    func testSendAudioWithText() {
        let expectationSendMsg = LKTestExpectation(description: "@test send audio msg")
        let expectationReceivePushMsg = LKTestExpectation(description: "@test receive push msg")
        let disposeBag = DisposeBag()
        // 准备测试数据
        let audioData = Resources.audioData(named: "1-opus")
        let audio = AudioDataInfo(data: audioData,
                                  length: TimeInterval(2.0),
                                  type: .opus,
                                  text: "Hello@",
                                  uploadID: "")
        let apiContext = APIContext(contextID: RandomString.random(length: 10))
        // 标记消息发送是否成功
        var inspecterSend = false
        // 标记消息的key
        var inspecterAudioKey = false
        // 标记接收到push消息的
        var inspecterVoiceText = ""
        // 标记发送的消息cid
        var msgCid = ""
        // 调用asyncSubscribeChatEvent进行订阅
        self.chatAPI.asyncSubscribeChatEvent(chatIds: [self.groupChatID], subscribe: true)
        // 发送语音消息
        self.sendMessageAPI.sendAudio(context: apiContext,
                                      audio: audio,
                                      parentMessage: nil,
                                      chatId: self.groupChatID,
                                      threadId: nil,
                                      stateHandler: { state in
            if case let .getQuasiMessage(msg, _, _, _, _) = state { msgCid = msg.cid }
            if case .finishSendMessage(_, _, _, _, _) = state {
                inspecterSend = true
                expectationSendMsg.fulfill()
            }
        })
        // 监听Push
        self.sendMessageAPI.pushCenter.observable(for: PushChannelMessage.self).subscribe(onNext: { [ weak self] pushMsg in
            // 根据cid 判断是否为发送的消息
            guard let `self` = self, pushMsg.message.cid == msgCid, pushMsg.message.localStatus == .success else { return }
            if let currentContent = pushMsg.message.content as? AudioContent {
                inspecterVoiceText = currentContent.voiceText
                inspecterAudioKey = currentContent.key.isEmpty
                expectationReceivePushMsg.fulfill()
            }
        }).disposed(by: disposeBag)
        expectationSendMsg.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        expectationReceivePushMsg.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectationSendMsg, expectationReceivePushMsg], timeout: WaitTimeout.defaultTimeout)
        // 取消订阅
        _ = self.chatAPI.asyncSubscribeChatEvent(chatIds: [self.groupChatID], subscribe: false)
        if expectationSendMsg.autoFulfill || expectationReceivePushMsg.autoFulfill { return }
        // 校验点1 语音消息发送是否成功
        XCTAssertTrue(inspecterSend)
        // 校验点2 文本内容是否一致, 发送消息与接收push的文本内容一致
        XCTAssertEqual(inspecterVoiceText, "Hello@")
        XCTAssertFalse(inspecterAudioKey)
    }

    // 发送录音，测试接口调用是否成功，校验发送消息与接收push的大小一致
    func testSendAudio() {
        let expectationSendMsg = LKTestExpectation(description: "@test send audio msg")
        let expectationReceivePushMsg = LKTestExpectation(description: "@test receive push msg")
        let expectationUploadAudioData = LKTestExpectation(description: "@test upload audio data")
        let disposeBag = DisposeBag()
        // 准备测试数据
        var audioData = Resources.audioData(named: "1-opus")
        let apiContext = APIContext(contextID: RandomString.random(length: 10))
        // 标记消息发送是否成功
        var inspecterSend = false
        // 标记接收到push音频的key
        var inspecterKey = false
        // 标记发送的消息cid
        var msgCid = ""
        // 录音上传ID
        var uploadID: String?
        // 调用asyncSubscribeChatEvent进行订阅
        self.chatAPI.asyncSubscribeChatEvent(chatIds: [self.groupChatID], subscribe: true)
        // 提前获取到uploadID，并上传录音数据
        uploadID = try? self.resourceAPI.fetchUploadID(chatID: self.groupChatID, language: Lang(rawValue: "zh"))
        self.audioAPI.uploadAudio(uploadID: uploadID!,
                                  data: audioData,
                                  sequenceId: 1,
                                  recognize: false,
                                  finish: true,
                                  cancel: false,
                                  deleteAudioResource: false).subscribe(onNext: { _ in
            expectationUploadAudioData.fulfill()
        }, onError: { _ in
            XCTFail("upload audio data faild, uploadID:\(String(describing: uploadID))")
            expectationUploadAudioData.fulfill()
        }).disposed(by: disposeBag)
        let streamAudioInfo = StreamAudioInfo(uploadID: uploadID!, length: TimeInterval(2))
        // 发送语音消息
        self.sendMessageAPI.sendAudio(context: apiContext,
                                      audioInfo: streamAudioInfo,
                                      parentMessage: nil,
                                      chatId: self.groupChatID,
                                      threadId: nil,
                                      sendMessageTracker: nil,
                                      stateHandler: { state in
            if case let .getQuasiMessage(msg, _, _, _, _) = state { msgCid = msg.cid }
            if case .finishSendMessage(_, _, _, _, _) = state {
                inspecterSend = true
                expectationSendMsg.fulfill()
            }
        })
        // 监听Push
        self.sendMessageAPI.pushCenter.observable(for: PushChannelMessage.self).subscribe(onNext: { [ weak self] pushMsg in
            // 根据cid 判断是否为发送的消息
            guard let `self` = self, pushMsg.message.cid == msgCid, pushMsg.message.localStatus == .success else { return }
            if let currentContent = pushMsg.message.content as? AudioContent {
                inspecterKey = currentContent.key.isEmpty
            }
            expectationReceivePushMsg.fulfill()
        }).disposed(by: disposeBag)
        expectationSendMsg.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        expectationReceivePushMsg.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        expectationUploadAudioData.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectationSendMsg, expectationReceivePushMsg, expectationUploadAudioData], timeout: WaitTimeout.defaultTimeout)
        // 取消订阅
        _ = self.chatAPI.asyncSubscribeChatEvent(chatIds: [self.groupChatID], subscribe: false)
        if expectationSendMsg.autoFulfill || expectationReceivePushMsg.autoFulfill || expectationUploadAudioData.autoFulfill { return }
        // 校验点1 语音消息发送是否成功
        XCTAssertTrue(inspecterSend)
        // 校验点2 发送语音消息与接收Push的key是否一致
        XCTAssertFalse(inspecterKey)
    }

//    回复语音加文字
//    func testReplyAudioWithText() {
//        let expectationSendMsg = LKTestExpectation(description: "@test send audio msg")
//        let expectationReceivePushMsg = LKTestExpectation(description: "@test receive push msg")
//        let disposeBag = DisposeBag()
//        // 准备测试数据
//        // 提前获取到uploadID
//        let uploadID = try? self.resourceAPI.fetchUploadID(chatID: self.groupChatID, language: Lang(rawValue: "zh"))
//        let audioData = Resources.audioData(named: "1-opus")
//        let audio = AudioDataInfo(data: audioData,
//                                  length: TimeInterval(2.0),
//                                  type: .opus,
//                                  text: "Hello@",
//                                  uploadID: uploadID!)
//        let apiContext = APIContext(contextID: RandomString.random(length: 10))
//        // 标记消息发送是否成功
//        var inspecterSend = false
//        // 标记接收到push消息的
//        var inspecterVoiceText = ""
//        // 标记发送的消息cid
//        var msgCid = ""
//        AutoLoginHandler().autoLogin {
//            // 创建父消息
//            let parentMsg = LarkModel.Message.transform(pb: Message.PBModel())
//            parentMsg.id = ""
//            // 发送语音消息
//            self.sendMessageAPI.sendAudio(context: apiContext,
//                                          audio: audio,
//                                          parentMessage: parentMsg,
//                                          chatId: self.groupChatID,
//                                          threadId: nil,
//                                          stateHandler: { state in
//                if case let .getQuasiMessage(msg, _, _, _, _) = state { msgCid = msg.cid }
//                if case .finishSendMessage(_, _, _, _, _) = state {
//                    inspecterSend = true
//                    expectationSendMsg.fulfill()
//                }
//            })
//            // 监听Push
//            self.sendMessageAPI.pushCenter.observable(for: PushChannelMessage.self).subscribe(onNext: { [ weak self] pushMsg in
//                // 根据cid 判断是否为发送的消息
//                guard let `self` = self, pushMsg.message.cid == msgCid else { return }
//                if let currentContent = pushMsg.message.content as? AudioContent {
//                    inspecterVoiceText = currentContent.voiceText
//                }
//                expectationReceivePushMsg.fulfill()
//            }).disposed(by: disposeBag)
//        }
//        wait(for: [expectationSendMsg, expectationReceivePushMsg], timeout: WaitTimeout.defaultTimeout)
//        // 校验点1 语音消息发送是否成功
//        XCTAssertTrue(inspecterSend)
//        // 校验点2 文本内容是否一致, 发送消息与接收push的文本内容一致
//        XCTAssertEqual(inspecterVoiceText, "Hello@")
//    }

//    // replyInThread语音加文字
//    func testReplyInThreadAudioWithText() {
//        let expectationSendMsg = LKTestExpectation(description: "@test send audio msg")
//        let expectationReceivePushMsg = LKTestExpectation(description: "@test receive push msg")
//        let disposeBag = DisposeBag()
//        // 准备测试数据
//        // 提前获取到uploadID
//        let uploadID = try? self.resourceAPI.fetchUploadID(chatID: self.groupChatID, language: Lang(rawValue: "zh"))
//        let audioData = Resources.audioData(named: "1-opus")
//        let audio = AudioDataInfo(data: audioData,
//                                  length: TimeInterval(2.0),
//                                  type: .opus,
//                                  text: "Hello@",
//                                  uploadID: uploadID!)
//        let apiContext = APIContext(contextID: RandomString.random(length: 10))
//        apiContext.set(key: APIContext.replyInThreadKey, value: true)
//        // 标记消息发送是否成功
//        var inspecterSend = false
//        // 标记接收到push消息的
//        var inspecterVoiceText = ""
//        // 标记发送的消息cid
//        var msgCid = ""
//        AutoLoginHandler().autoLogin {
//            // 创建父消息
//            let parentMsg = LarkModel.Message.transform(pb: Message.PBModel())
//            parentMsg.id = ""
//            // 发送语音消息
//            self.sendMessageAPI.sendAudio(context: apiContext,
//                                          audio: audio,
//                                          parentMessage: parentMsg,
//                                          chatId: self.groupChatID,
//                                          threadId: parentMsg.id,
//                                          stateHandler: { state in
//                if case let .getQuasiMessage(msg, _, _, _, _) = state { msgCid = msg.cid }
//                if case .finishSendMessage(_, _, _, _, _) = state {
//                    inspecterSend = true
//                    expectationSendMsg.fulfill()
//                }
//            })
//            // 监听Push
//            self.sendMessageAPI.pushCenter.observable(for: PushChannelMessage.self).subscribe(onNext: { [ weak self] pushMsg in
//                // 根据cid 判断是否为发送的消息
//                guard let `self` = self, pushMsg.message.cid == msgCid else { return }
//                if let currentContent = pushMsg.message.content as? AudioContent {
//                    inspecterVoiceText = currentContent.voiceText
//                }
//                expectationReceivePushMsg.fulfill()
//            }).disposed(by: disposeBag)
//        }
//        wait(for: [expectationSendMsg, expectationReceivePushMsg], timeout: WaitTimeout.defaultTimeout)
//        // 校验点1 语音消息发送是否成功
//        XCTAssertTrue(inspecterSend)
//        // 校验点2 文本内容是否一致, 发送消息与接收push的文本内容一致
//        XCTAssertEqual(inspecterVoiceText, "Hello@")
//    }

//    // 回复录音
//    func testReplyAudio() {
//        let expectationSendMsg = LKTestExpectation(description: "@test send audio msg")
//        let expectationReceivePushMsg = LKTestExpectation(description: "@test receive push msg")
//        let expectationUploadAudioData = LKTestExpectation(description: "@test upload audio data")
//        let disposeBag = DisposeBag()
//        // 准备测试数据
//        var audioData = Resources.audioData(named: "1-opus")
//        // 提前获取到uploadID，并上传录音数据
//        let uploadID = try? self.resourceAPI.fetchUploadID(chatID: self.groupChatID, language: Lang(rawValue: "zh"))
//        self.audioAPI.uploadAudio(uploadID: uploadID!,
//                                  data: audioData,
//                                  sequenceId: 1,
//                                  recognize: false,
//                                  finish: true,
//                                  cancel: false,
//                                  deleteAudioResource: false).subscribe(onNext: { _ in
//            expectationUploadAudioData.fulfill()
//        }, onError: { _ in
//            XCTFail("upload audio data faild, uploadID:\(String(describing: uploadID))")
//            expectationUploadAudioData.fulfill()
//        }).disposed(by: disposeBag)
//        let streamAudioInfo = StreamAudioInfo(uploadID: uploadID!, length: TimeInterval(2))
//        let apiContext = APIContext(contextID: RandomString.random(length: 10))
//        // 标记消息发送是否成功
//        var inspecterSend = false
//        // 标记接收到push音频的key
//        var inspecterKey: String?
//        // 标记发送的消息cid
//        var msgCid = ""
//        AutoLoginHandler().autoLogin {
//            // 创建父消息
//            let parentMsg = LarkModel.Message.transform(pb: Message.PBModel())
//            parentMsg.id = ""
//            // 发送语音消息
//            self.sendMessageAPI.sendAudio(context: apiContext,
//                                          audioInfo: streamAudioInfo,
//                                          parentMessage: parentMsg,
//                                          chatId: self.groupChatID,
//                                          threadId: nil,
//                                          sendMessageTracker: nil,
//                                          stateHandler: { state in
//                if case let .getQuasiMessage(msg, _, _, _, _) = state { msgCid = msg.cid }
//                if case .finishSendMessage(_, _, _, _, _) = state {
//                    inspecterSend = true
//                    expectationSendMsg.fulfill()
//                }
//            })
//            // 监听Push
//            self.sendMessageAPI.pushCenter.observable(for: PushChannelMessage.self).subscribe(onNext: { [ weak self] pushMsg in
//                // 根据cid 判断是否为发送的消息
//                guard let `self` = self, pushMsg.message.cid == msgCid else { return }
//                if let currentContent = pushMsg.message.content as? AudioContent {
//                    inspecterKey = currentContent.key
//                }
//                expectationReceivePushMsg.fulfill()
//            }).disposed(by: disposeBag)
//        }
//        wait(for: [expectationSendMsg, expectationReceivePushMsg, expectationUploadAudioData], timeout: WaitTimeout.defaultTimeout)
//        // 校验点1 语音消息发送是否成功
//        XCTAssertTrue(inspecterSend)
//        // 校验点2 发送语音消息与接收Push的key是否一致
//        XCTAssertEqual(inspecterKey, uploadID)
//    }

//    // replyInThread录音
//    func testReplyInThreadAudio() {
//        let expectationSendMsg = LKTestExpectation(description: "@test send audio msg")
//        let expectationReceivePushMsg = LKTestExpectation(description: "@test receive push msg")
//        let expectationUploadAudioData = LKTestExpectation(description: "@test upload audio data")
//        let disposeBag = DisposeBag()
//        // 准备测试数据
//        var audioData = Resources.audioData(named: "1-opus")
//        // 提前获取到uploadID，并上传录音数据
//        let uploadID = try? self.resourceAPI.fetchUploadID(chatID: self.groupChatID, language: Lang(rawValue: "zh"))
//        self.audioAPI.uploadAudio(uploadID: uploadID!,
//                                  data: audioData,
//                                  sequenceId: 1,
//                                  recognize: false,
//                                  finish: true,
//                                  cancel: false,
//                                  deleteAudioResource: false).subscribe(onNext: { _ in
//            expectationUploadAudioData.fulfill()
//        }, onError: { _ in
//            XCTFail("upload audio data faild, uploadID:\(String(describing: uploadID))")
//            expectationUploadAudioData.fulfill()
//        }).disposed(by: disposeBag)
//        let streamAudioInfo = StreamAudioInfo(uploadID: uploadID!, length: TimeInterval(2))
//        let apiContext = APIContext(contextID: RandomString.random(length: 10))
//        apiContext.set(key: APIContext.replyInThreadKey, value: true)
//        // 标记消息发送是否成功
//        var inspecterSend = false
//        // 标记接收到push音频的key
//        var inspecterKey: String?
//        // 标记发送的消息cid
//        var msgCid = ""
//        AutoLoginHandler().autoLogin {
//            // 创建父消息
//            let parentMsg = LarkModel.Message.transform(pb: Message.PBModel())
//            parentMsg.id = ""
//            // 发送语音消息
//            self.sendMessageAPI.sendAudio(context: apiContext,
//                                          audioInfo: streamAudioInfo,
//                                          parentMessage: parentMsg,
//                                          chatId: self.groupChatID,
//                                          threadId: parentMsg.id,
//                                          sendMessageTracker: nil,
//                                          stateHandler: { state in
//                if case let .getQuasiMessage(msg, _, _, _, _) = state { msgCid = msg.cid }
//                if case .finishSendMessage(_, _, _, _, _) = state {
//                    inspecterSend = true
//                    expectationSendMsg.fulfill()
//                }
//            })
//            // 监听Push
//            self.sendMessageAPI.pushCenter.observable(for: PushChannelMessage.self).subscribe(onNext: { [ weak self] pushMsg in
//                // 根据cid 判断是否为发送的消息
//                guard let `self` = self, pushMsg.message.cid == msgCid else { return }
//                if let currentContent = pushMsg.message.content as? AudioContent {
//                    inspecterKey = currentContent.key
//                }
//                expectationReceivePushMsg.fulfill()
//            }).disposed(by: disposeBag)
//        }
//        wait(for: [expectationSendMsg, expectationReceivePushMsg, expectationUploadAudioData], timeout: WaitTimeout.defaultTimeout)
//        // 校验点1 语音消息发送是否成功
//        XCTAssertTrue(inspecterSend)
//        // 校验点2 发送语音消息与接收Push的key是否一致
//        XCTAssertEqual(inspecterKey, uploadID)
//    }
}
