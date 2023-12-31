//
//  SendLocationInterfaceTest.swift
//  LarkSendMessage-Unit-Tests
//
//  Created by 李瑞 on 2023/2/20.
//

import Foundation
import XCTest
import LarkSDKInterface // SendMessageAPI
import LarkContainer // InjectedSafeLazy
import LarkModel // LocationContent
import RxSwift // DisposeBag
import LarkSDKInterface // SDKRustService
import RustPB // Basic_V1_Location
@testable import LarkSendMessage

// 测试sendLocation接口，校验接口调用是否成功
final class SendLocationInterfaceTest: CanSkipTestCase {
    @InjectedSafeLazy private var sendMessageAPI: SendMessageAPI
    @InjectedSafeLazy private var chatAPI: ChatAPI
    /// 测试账号信息
    private let groupChatID = "7196963741224157187"

    // 测试发送位置信息，校验调用是否成功
    func testSendLocation() {
        // 设置异步等待
        // 1 等待发送接口
        let expectationSendMsg = LKTestExpectation(description: "@test send location msg")
        // 2 等待接收push
        let expectationReceivePushMsg = LKTestExpectation(description: "@test receive push msg")
        let disposeBag = DisposeBag()
        let context = APIContext(contextID: RandomString.random(length: 10))
        // 发送消息cid
        var msgCid: String = ""
        // 标记消息发送是否成功
        var inspecterSend = false
        // 封面图片的key
        var inspecterImageKey = false
        var inspecterAddress = ""
        var inspecterAddressDetail = ""
        // 输入数据
        let addressName = "1 Stockton St (Stockton St)"
        let addressDetail = "1 Stockton St San Francisco CA 98 United States"
        var location = Basic_V1_Location()
        location.name = addressName; location.description_p = addressDetail
        let locationContent = LocationContent(latitude: "",
                                              longitude: "",
                                              zoomLevel: 14,
                                              vendor: "",
                                              image: Basic_V1_ImageSet(),
                                              location: location,
                                              isInternal: false)

        // 封面数据
        let image = Resources.image(named: "1170x2532-PNG")
        // tracker
        let chatInfo = ChatKeyPointTrackerInfo(id: self.groupChatID,
                                               isCrypto: false,
                                               chat: nil)
        let sendMessageTracker = SendMessageTracker(userResolver: Container.shared.getCurrentUserResolver(),
                                                    chatInfo: chatInfo,
                                                    actionPosition: .chat)

        // 调用asyncSubscribeChatEvent进行订阅
        self.chatAPI.asyncSubscribeChatEvent(chatIds: [self.groupChatID], subscribe: true)

        self.sendMessageAPI.sendLocation(context: context,
                                         parentMessage: nil,
                                         chatId: self.groupChatID,
                                         threadId: nil,
                                         screenShot: image,
                                         location: locationContent,
                                         sendMessageTracker: sendMessageTracker,
                                         stateHandler: { state in
            if case let .getQuasiMessage(msg, _, _, _, _) = state { msgCid = msg.cid }
            if case .finishSendMessage(_, _, _, _, _) = state {
                expectationSendMsg.fulfill()
            }
        })

        // 监听Push
        self.sendMessageAPI.pushCenter.observable(for: PushChannelMessage.self).subscribe(onNext: { [weak self] pushMsg in
            // 根据cid 判断是否为发送的消息
            guard let `self` = self, pushMsg.message.cid == msgCid, pushMsg.message.localStatus == .success else { return }
            if let currentContent = pushMsg.message.content as? LocationContent {
                inspecterSend = true
                inspecterAddress = currentContent.location.name
                inspecterAddressDetail = currentContent.location.description_p
                inspecterImageKey = currentContent.image.key.isEmpty
            }
            expectationReceivePushMsg.fulfill()
        }).disposed(by: disposeBag)
        expectationSendMsg.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        expectationReceivePushMsg.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectationSendMsg, expectationReceivePushMsg], timeout: WaitTimeout.defaultTimeout)
        // 取消订阅
        _ = self.chatAPI.asyncSubscribeChatEvent(chatIds: [self.groupChatID], subscribe: false)
        if expectationSendMsg.autoFulfill || expectationReceivePushMsg.autoFulfill { return }
        // 校验点1: 消息是否发送成功
        XCTAssertTrue(inspecterSend)
        XCTAssertFalse(inspecterImageKey)
        XCTAssertEqual(inspecterAddress, addressName)
        XCTAssertEqual(inspecterAddressDetail, addressDetail)
    }
}
