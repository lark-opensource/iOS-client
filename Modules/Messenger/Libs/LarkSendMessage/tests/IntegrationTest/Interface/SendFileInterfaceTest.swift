//
//  SendFileInterfaceTest.swift
//  LarkSendMessage-Unit-Tests
//
//  Created by 李瑞 on 2023/2/6.
//

import Foundation
import XCTest
import LarkSDKInterface // SendMessageAPI
import LarkContainer // InjectedSafeLazy
import LarkStorage // IsoPath
import LarkModel // FileContent
import RxSwift // DisposeBag
@testable import LarkSendMessage

// 测试sendFile接口，测试接口可用性，发送与接收push消息的一致性
final class SendFileInterfaceTest: CanSkipTestCase {
    @InjectedSafeLazy private var sendMessageAPI: SendMessageAPI
    @InjectedSafeLazy private var chatAPI: ChatAPI
    /// 测试账号信息
    private let groupChatID = "7196963741224157187"

    // 测试发送文件消息，校验接口是否可用，发送和接收push文件的大小一致
    func testSendFile() {
        let expectationSendMsg = LKTestExpectation(description: "@test send file msg")
        let expectationReceivePushMsg = LKTestExpectation(description: "@test receive push msg")
        let disposeBag = DisposeBag()
        let apiContext = APIContext(contextID: RandomString.random(length: 10))
        // 发送消息cid
        var msgCid: String = ""
        // 标记消息发送是否成功
        var inspecterSend = false
        // 标记发送文件大小
        var inspecterSize: Int64?
        var originFileSize: Int64?
        // 标记返回消息中的key
        var inspecterFileKey = false
        // 人为造一个临时路径
        let tempFileDir = IsoPath.glboalTemporary(in: Domain.biz.messenger) + "interfaceTest" + "sendFile"
        try? tempFileDir.createDirectoryIfNeeded()
        let tempFilePath = tempFileDir + "testFile.zip"
        try? tempFilePath.removeItem()
        do {
            let testFileData = Resources.fileData(named: "1-zip")
            originFileSize = Int64(testFileData.count)
            try testFileData.write(to: tempFilePath)
        } catch {
            XCTExpectFailure("data move to path error")
            expectationSendMsg.fulfill()
        }
        // 调用asyncSubscribeChatEvent进行订阅
        self.chatAPI.asyncSubscribeChatEvent(chatIds: [self.groupChatID], subscribe: true)
        // 调用sendFile,发送文件消息
        self.sendMessageAPI.sendFile(context: apiContext,
                                     path: tempFilePath.absoluteString,
                                     name: "testFile.zip",
                                     parentMessage: nil,
                                     removeOriginalFileAfterFinish: false,
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
        self.sendMessageAPI.pushCenter.observable(for: PushChannelMessage.self).subscribe(onNext: { [weak self ] pushMsg in
            guard let `self` = self, pushMsg.message.cid == msgCid, pushMsg.message.localStatus == .success else { return }
            guard let fileContent = pushMsg.message.content as? FileContent else { return }
            inspecterSize = fileContent.size
            inspecterFileKey = fileContent.key.isEmpty
            expectationReceivePushMsg.fulfill()
        }).disposed(by: disposeBag)
        expectationSendMsg.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        expectationReceivePushMsg.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectationSendMsg, expectationReceivePushMsg], timeout: WaitTimeout.defaultTimeout)
        // 取消会话订阅
        _ = self.chatAPI.asyncSubscribeChatEvent(chatIds: [self.groupChatID], subscribe: false)
        if expectationSendMsg.autoFulfill || expectationReceivePushMsg.autoFulfill { return }
        // 校验点1: 消息是否发送成功
        XCTAssertTrue(inspecterSend)
        // 校验点2： 发送和接收到push的文件大小是否一致
        XCTAssertEqual(inspecterSize, originFileSize)
        XCTAssertFalse(inspecterFileKey)
    }

//    // 回复文件
//    func testReplyFile() {
//        let expectationSendMsg = LKTestExpectation(description: "@test send file msg")
//        let expectationReceivePushMsg = LKTestExpectation(description: "@test receive push msg")
//        let disposeBag = DisposeBag()
//        let apiContext = APIContext(contextID: RandomString.random(length: 10))
//        // 发送消息cid
//        var msgCid: String = ""
//        // 标记消息发送是否成功
//        var inspecterSend = false
//        // 标记发送文件大小
//        var inspecterSize: Int64?
//        var originFileSize: Int64?
//        // 人为造一个临时路径
//        let tempFileDir = IsoPath.glboalTemporary(in: Domain.biz.messenger) + "interfaceTest" + "sendFile"
//        try? tempFileDir.createDirectoryIfNeeded()
//        let tempFilePath = tempFileDir + "testFile.zip"
//        try? tempFilePath.removeItem()
//        do {
//            let testFileData = Resources.fileData(named: "1-zip")
//            originFileSize = Int64(testFileData.count)
//            try testFileData.write(to: tempFilePath)
//        } catch {
//            XCTExpectFailure("data move to path error")
//            expectationSendMsg.fulfill()
//        }
//        AutoLoginHandler().autoLogin {
//            // 创建父消息
//            let parentMsg = LarkModel.Message.transform(pb: Message.PBModel())
//            parentMsg.id = "7197759945025011714"
//            // 调用sendFile,发送文件消息
//            self.sendMessageAPI.sendFile(context: apiContext,
//                                         path: tempFilePath.absoluteString,
//                                         name: "testFile.zip",
//                                         parentMessage: parentMsg,
//                                         removeOriginalFileAfterFinish: false,
//                                         chatId: self.groupChatID,
//                                         threadId: nil,
//                                         stateHandler: { state in
//                if case let .getQuasiMessage(msg, _, _, _, _) = state { msgCid = msg.cid }
//                if case .finishSendMessage(_, _, _, _, _) = state {
//                    inspecterSend = true
//                    expectationSendMsg.fulfill()
//                }
//            })
//            // 监听Push
//            self.sendMessageAPI.pushCenter.observable(for: PushChannelMessage.self).subscribe(onNext: { [weak self ] pushMsg in
//                guard let `self` = self, pushMsg.message.cid == msgCid else { return }
//                guard let fileContent = pushMsg.message.content as? FileContent else { return }
//                inspecterSize = fileContent.size
//                expectationReceivePushMsg.fulfill()
//            }).disposed(by: disposeBag)
//        }
//        wait(for: [expectationSendMsg, expectationReceivePushMsg], timeout: WaitTimeout.defaultTimeout)
//        // 校验点1: 消息是否发送成功
//        XCTAssertTrue(inspecterSend)
//        // 校验点2： 发送和接收到push的文件大小是否一致
//        XCTAssertEqual(inspecterSize, originFileSize)
//    }
}
