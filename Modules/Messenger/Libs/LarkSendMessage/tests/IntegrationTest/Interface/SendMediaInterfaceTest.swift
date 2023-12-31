//
//  SendMediaInterfaceTest.swift
//  LarkSendMessage-Unit-Tests
//
//  Created by 李瑞 on 2023/2/8.
//

import UIKit
import Foundation
import XCTest
import LarkSDKInterface // SendMessageAPI
import LarkContainer // InjectedSafeLazy
import LarkStorage // IsoPath
import LarkModel // MediaContent
import RxSwift // DisposeBag
@testable import LarkSendMessage

// 测试sendVideo接口，测试接口可用性，发送与push消息的一致性
final class SendMediaInterfaceTest: CanSkipTestCase {
    @InjectedSafeLazy private var sendMessageAPI: SendMessageAPI
    @InjectedSafeLazy private var videoSendService: VideoMessageSendService
    @InjectedSafeLazy private var chatAPI: ChatAPI
    /// 测试账号信息
    private let groupChatID = "7196963741224157187"

    // 发送视频消息，校验接口调用是否成功，发送视频与接收push大小是否一致
    func testSendMedia() {
        let expectationSendMsg = LKTestExpectation(description: "@test send media msg")
        let expectationReceivePushMsg = LKTestExpectation(description: "@test receive push msg")
        let disposeBag = DisposeBag()
        // 发送消息cid
        var msgCid: String = ""
        // 标记视频消息是否发送成功
        var inspecterSend = false
        // 标记视频消息key
        var inspecterMediaKey = false
        // 标记视频消息大小
        var inspecterSize: Int64?
        var originMediaSize: Int64?
        // 构建测试数据
        // 临时路径
        let tempFileDir = IsoPath.glboalTemporary(in: Domain.biz.messenger) + "interfaceTest" + "sendMedia"
        try? tempFileDir.createDirectoryIfNeeded()
        let tempFilePath = tempFileDir + "sendMedia.mp4"
        try? tempFilePath.removeItem()
        do {
            let testMediaData = Resources.mediaData(named: "10-540x960-mp4")
            originMediaSize = Int64(testMediaData.count)
            try testMediaData.write(to: tempFilePath)
        } catch {
            XCTExpectFailure("data move to path error")
            expectationSendMsg.fulfill()
        }
        let context = APIContext(contextID: RandomString.random(length: 10))
        let sendVideoParams = SendVideoParams(content: .fileURL(tempFilePath.url),
                                              isCrypto: false,
                                              isOriginal: false,
                                              forceFile: false,
                                              chatId: self.groupChatID,
                                              threadId: nil,
                                              parentMessage: nil,
                                              from: UIViewController())
        // 调用asyncSubscribeChatEvent进行订阅
        self.chatAPI.asyncSubscribeChatEvent(chatIds: [self.groupChatID], subscribe: true)
        // 发送视频消息
        self.videoSendService.sendVideo(with: sendVideoParams, extraParam: nil, context: context, sendMessageTracker: nil) { state in
            if case let .getQuasiMessage(msg, _, _, _, _) = state { msgCid = msg.cid }
            if case .finishSendMessage(_, _, _, _, _) = state {
                inspecterSend = true
                expectationSendMsg.fulfill()
            }
        }
        // 监听Push
        self.sendMessageAPI.pushCenter.observable(for: PushChannelMessage.self).subscribe(onNext: { [weak self] pushMsg in
            // 根据cid 判断是否为发送的消息
            guard let `self` = self, pushMsg.message.cid == msgCid, pushMsg.message.localStatus == .success else { return }
            if let currentContent = pushMsg.message.content as? MediaContent {
                inspecterSize = currentContent.size
                inspecterMediaKey = currentContent.key.isEmpty
            }
            expectationReceivePushMsg.fulfill()
        }).disposed(by: disposeBag)
        expectationSendMsg.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        expectationReceivePushMsg.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectationSendMsg, expectationReceivePushMsg], timeout: WaitTimeout.defaultTimeout)
        _ = self.chatAPI.asyncSubscribeChatEvent(chatIds: [self.groupChatID], subscribe: false)
        if expectationSendMsg.autoFulfill || expectationReceivePushMsg.autoFulfill { return }
        // 校验 是否可以成功发送视频消息
        XCTAssertTrue(inspecterSend)
        // 校验 发送视频和收到的push大小一致
        XCTAssertEqual(inspecterSize, originMediaSize)
        XCTAssertFalse(inspecterMediaKey)
    }

//    // 回复视频
//    func testReplyMedia() {
//        let expectationSendMsg = LKTestExpectation(description: "@test send media msg")
//        let expectationReceivePushMsg = LKTestExpectation(description: "@test receive push msg")
//        let disposeBag = DisposeBag()
//        // 发送消息cid
//        var msgCid: String = ""
//        // 标记视频消息是否发送成功
//        var inspecterSend = false
//        // 标记视频消息大小
//        var inspecterSize: Int64?
//        var originMediaSize: Int64?
//        // 构建测试数据
//        // 临时路径
//        let tempFileDir = IsoPath.glboalTemporary(in: Domain.biz.messenger) + "interfaceTest" + "sendMedia"
//        try? tempFileDir.createDirectoryIfNeeded()
//        let tempFilePath = tempFileDir + "sendMedia.mp4"
//        try? tempFilePath.removeItem()
//        do {
//            let testMediaData = Resources.mediaData(named: "10-540x960-mp4")
//            originMediaSize = Int64(testMediaData.count)
//            try testMediaData.write(to: tempFilePath)
//        } catch {
//            XCTExpectFailure("data move to path error")
//            expectationSendMsg.fulfill()
//        }
//        let context = APIContext(contextID: RandomString.random(length: 10))
//        // 创建父消息
//        let parentMsg = LarkModel.Message.transform(pb: Message.PBModel())
//        let sendVideoParams = SendVideoParams(content: .fileURL(tempFilePath.url),
//                                              isCrypto: false,
//                                              isOriginal: false,
//                                              forceFile: false,
//                                              chatId: self.groupChatID,
//                                              threadId: nil,
//                                              parentMessage: parentMsg,
//                                              from: UIViewController())
//        AutoLoginHandler().autoLogin {
//            // 发送视频消息
//            self.videoSendService.sendVideo(with: sendVideoParams, extraParam: nil, context: context, sendMessageTracker: MySendMessageTracker()) { state in
//                if case let .getQuasiMessage(msg, _, _, _, _) = state { msgCid = msg.cid }
//                if case .finishSendMessage(_, _, _, _, _) = state {
//                    inspecterSend = true
//                    expectationSendMsg.fulfill()
//                }
//            }
//            // 监听Push
//            self.sendMessageAPI.pushCenter.observable(for: PushChannelMessage.self).subscribe(onNext: { [weak self] pushMsg in
//                // 根据cid 判断是否为发送的消息
//                guard let `self` = self, pushMsg.message.cid == msgCid else { return }
//                if let currentContent = pushMsg.message.content as? MediaContent {
//                    inspecterSize = currentContent.size
//                }
//                expectationReceivePushMsg.fulfill()
//            }).disposed(by: disposeBag)
//        }
//        wait(for: [expectationSendMsg, expectationReceivePushMsg], timeout: WaitTimeout.defaultTimeout)
//        // 校验 是否可以成功发送视频消息
//        XCTAssertTrue(inspecterSend)
//        // 校验 发送视频和收到的push大小一致
//        XCTAssertEqual(inspecterSize, originMediaSize)
//    }
}
