//
//  SendMessageAPIUnitTest.swift
//  LarkSendMessage-Unit-Tests
//
//  Created by 李勇 on 2023/1/31.
//

import XCTest
import Foundation
import RxSwift // DisposeBag
import LarkModel // Message
import LarkContainer // InjectedLazy
import LarkRustClient // RequestPacket
import LarkSDKInterface // SDKRustService
import LarkStorage // IsoPath
import ByteWebImage // ImageSourceResult
import LarkAccountInterface
@testable import LarkSendMessage // SendMessageRequest

/// SendMessageAPI新增单测
final class SendMessageAPIUnitTest: CanSkipTestCase {
    @InjectedLazy private var sendMessageAPI: SendMessageAPI
    @InjectedLazy private var generalSettings: UserGeneralSettings
    @InjectedLazy private var progressService: ProgressService

    /// 测试APIContext
    func testAPIContext() {
        // 测试contextID存取
        let contextID = RandomString.random(length: 10)
        let context = APIContext(contextID: contextID)
        XCTAssertEqual(context.contextID, contextID)
        XCTAssertNotNil(context.get(key: APIContext.contextIDKey))
        XCTAssertNotNil(context.getContext().get(key: APIContext.contextIDKey))
        XCTAssertEqual(context.get(key: APIContext.contextIDKey) ?? "", contextID)
        XCTAssertEqual(context.getContext().get(key: APIContext.contextIDKey) ?? "", contextID)
        // 测试bool值自定义存取
        context.set(key: APIContext.chatDisplayModeKey, value: true)
        XCTAssertNotNil(context.get(key: APIContext.chatDisplayModeKey))
        XCTAssertNotNil(context.getContext().get(key: APIContext.chatDisplayModeKey))
        XCTAssertEqual(context.get(key: APIContext.chatDisplayModeKey) ?? false, true)
        XCTAssertEqual(context.getContext().get(key: APIContext.chatDisplayModeKey) ?? false, true)
        // 测试string值自定义存取
        context.set(key: APIContext.replyInThreadKey, value: "replyInThreadKey")
        XCTAssertNotNil(context.get(key: APIContext.replyInThreadKey))
        XCTAssertNotNil(context.getContext().get(key: APIContext.replyInThreadKey))
        XCTAssertEqual(context.get(key: APIContext.replyInThreadKey) ?? "", "replyInThreadKey")
        XCTAssertEqual(context.getContext().get(key: APIContext.replyInThreadKey) ?? "", "replyInThreadKey")
    }

    /// replyInThreadMessagePosition值为固定的-3
    func testReplyInThreadMessagePosition() {
        XCTAssertEqual(replyInThreadMessagePosition, -3)
    }

    /// originImageCachePre值固定
    func testOriginImageCachePre() {
        XCTAssertEqual(RustSendMessageAPI.originImageCachePre, "originPreKey")
    }

    /// pendingMessages值存取
    func testPendingMessages1() {
        let disposeBag = DisposeBag()
        let expectation = LKTestExpectation(description: "@test status driver")
        // 网络不好时，adjustLocalStatus不会生效，需要绕过
        if self.sendMessageAPI.currentNetStatus != .excellent, self.sendMessageAPI.currentNetStatus != .evaluating {
            expectation.fulfill()
            return
        }
        let randomCid = RandomString.random(length: 10)
        self.sendMessageAPI.statusDriver.drive { (message, error) in
            guard message.cid == randomCid else { return }
            XCTAssertEqual(message.cid, randomCid)
            XCTAssertTrue(message.localStatus == .process)
            XCTAssertNil(error)
            expectation.fulfill()
        }.disposed(by: disposeBag)
        let message = Message.transform(pb: Message.PBModel()); message.cid = randomCid; message.type = .file; message.content = FileContent.transform(pb: FileContent.PBModel())
        self.sendMessageAPI.addPendingMessages(id: randomCid, value: (message, "", false))
        self.sendMessageAPI.adjustLocalStatus(message: message, stateHandler: nil)
        expectation.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
        if expectation.autoFulfill { return }
    }

    /// pendingMessages值存取
    func testPendingMessages2() {
        let disposeBag = DisposeBag()
        let expectation = LKTestExpectation(description: "@test status driver")
        var statusDriverCount = 0
        // 网络不好时，adjustLocalStatus不会生效，需要绕过
        if self.sendMessageAPI.currentNetStatus != .excellent, self.sendMessageAPI.currentNetStatus != .evaluating {
            expectation.fulfill()
            return
        }
        let randomCid = RandomString.random(length: 10)
        self.sendMessageAPI.statusDriver.drive { (message, _) in
            guard message.cid == randomCid else { return }
            statusDriverCount += 1
        }.disposed(by: disposeBag)
        let message = Message.transform(pb: Message.PBModel()); message.cid = randomCid; message.type = .file; message.content = FileContent.transform(pb: FileContent.PBModel())
        self.sendMessageAPI.addPendingMessages(id: randomCid, value: (message, "", false))
        // 预期dealPushMessage会移除pendingMessages（需要把cid加到sendingCids/resendingCids中）
        self.sendMessageAPI.preSendMessage(cid: randomCid)
        // dealPushMessage中只会对localStatus为fail/success进行remove操作；内部会触发一次statusDriver回调
        message.localStatus = .fail; _ = self.sendMessageAPI.dealPushMessage(message: message)
        // adjustLocalStatus预期不会触发statusDriver
        self.sendMessageAPI.adjustLocalStatus(message: message, stateHandler: nil)
        // 给2s时间去判断有没有触发statusDriver
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) { expectation.fulfill() }
        expectation.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
        if expectation.autoFulfill { return }
        XCTAssertEqual(statusDriverCount, 1)
    }

    /// pendingMessages值存取
    func testPendingMessages3() {
        let disposeBag = DisposeBag()
        let expectation = LKTestExpectation(description: "@test status driver")
        // 网络不好时，adjustLocalStatus不会生效，需要绕过
        if self.sendMessageAPI.currentNetStatus != .excellent, self.sendMessageAPI.currentNetStatus != .evaluating {
            expectation.fulfill()
            return
        }
        let randomCid = RandomString.random(length: 10)
        self.sendMessageAPI.statusDriver.drive { (message, _) in
            guard message.cid == randomCid else { return }
            XCTExpectFailure("should not status driver")
        }.disposed(by: disposeBag)
        let message = Message.transform(pb: Message.PBModel()); message.cid = randomCid; message.type = .file; message.content = FileContent.transform(pb: FileContent.PBModel())
        self.sendMessageAPI.addPendingMessages(id: randomCid, value: (message, "", false))
        // 预期uploadFileFinish会移除pendingMessages（state需要为uploadFail，这块逻辑太久远了，就不追究了），adjustLocalStatus预期不会触发statusDriver
        self.progressService.dealUploadFileInfo(PushUploadFile(localKey: randomCid, key: "", progress: Progress(), state: .uploadFail, type: .message, rate: 0))
        self.sendMessageAPI.adjustLocalStatus(message: message, stateHandler: nil)
        // 给2s时间去判断有没有触发statusDriver
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) { expectation.fulfill() }
        expectation.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
        if expectation.autoFulfill { return }
    }

    /// quasiMsgCreateByNative逻辑
    func testQuasiMsgCreateByNative() {
        XCTAssertFalse(self.sendMessageAPI.quasiMsgCreateByNative(context: nil))
        // settings为false，后续不用判断，quasiMsgCreateByNative稳定为false
        if !self.generalSettings.createQuasiMessageConfig.isNativeQuasiMessage { return }

        let apiContext = APIContext(contextID: "")
        XCTAssertFalse(self.sendMessageAPI.quasiMsgCreateByNative(context: apiContext))
        apiContext.lastMessagePosition = 10
        XCTAssertFalse(self.sendMessageAPI.quasiMsgCreateByNative(context: apiContext))
        apiContext.chatDisplayMode = .default
        XCTAssertFalse(self.sendMessageAPI.quasiMsgCreateByNative(context: apiContext))
        apiContext.quasiMsgCreateByNative = true
        XCTAssertTrue(self.sendMessageAPI.quasiMsgCreateByNative(context: apiContext))
    }

    /// 测试fileDownloadCache、sendVideoCache、VideoPassCache，保证LarkStorage没有错误的改动
    func testCachePath() {
        let userID = AccountServiceAdapter.shared.currentChatterId
        XCTAssertTrue(fileDownloadRootPath(userID: userID).absoluteString.contains("/Library/Caches/messenger/LarkUser_7112332912338452481/downloads"))
        XCTAssertTrue(sendVideoRootPath(userID: userID).absoluteString.contains("/Library/Caches/messenger/LarkUser_7112332912338452481/videoCache"))
        XCTAssertTrue(VideoPassRootPath(userID: userID).absoluteString.contains("/Library/Caches/LarkStorage/Space-User_7112332912338452481/Domain-Messenger-VideoPass"))
    }

    /// 测试getImageMessageInfoCost
    func testGetImageMessageInfoCost() {
        // 无cover获取origin.compressCost
        var source = SendImageSource(cover: nil, origin: { ImageSourceResult(sourceType: .jpeg, data: nil, image: nil, compressCost: 20) })
        var info = ImageMessageInfo(originalImageSize: .zero, sendImageSource: source)
        XCTAssertEqual(self.sendMessageAPI.getImageMessageInfoCost(info: info), 20)
        // 有cover获取cover.compressCost
        let origin = { ImageSourceResult(sourceType: .jpeg, data: nil, image: nil, compressCost: 20) }
        source = SendImageSource(cover: { ImageSourceResult(sourceType: .jpeg, data: nil, image: nil, compressCost: 10) }, origin: origin)
        info = ImageMessageInfo(originalImageSize: .zero, sendImageSource: source)
        XCTAssertEqual(self.sendMessageAPI.getImageMessageInfoCost(info: info), 10)
    }

    /// 测试statusDriver能否正常回调
    func testStatusDriverForSendError() {
        let disposeBag = DisposeBag()
        let expectation = LKTestExpectation(description: "@test status driver")
        self.sendMessageAPI.statusDriver.drive { (_, error) in
            XCTAssertNil(error)
            expectation.fulfill()
        }.disposed(by: disposeBag)
        self.sendMessageAPI.sendError(value: (Message.transform(pb: Message.PBModel()), nil))
        expectation.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
        if expectation.autoFulfill { return }
    }

    /// 测试statusDriver能否正常回调
    func testStatusDriverForAdjustLocalStatus() {
        let disposeBag = DisposeBag()
        let expectation = LKTestExpectation(description: "@test status driver")
        // 网络不好时，adjustLocalStatus不会生效，需要绕过
        if self.sendMessageAPI.currentNetStatus != .excellent, self.sendMessageAPI.currentNetStatus != .evaluating {
            expectation.fulfill()
            return
        }
        let randomCid = RandomString.random(length: 10)
        self.sendMessageAPI.statusDriver.drive { (message, error) in
            guard message.cid == randomCid else { return }
            XCTAssertEqual(message.cid, randomCid)
            XCTAssertTrue(message.localStatus == .process)
            XCTAssertNil(error)
            expectation.fulfill()
        }.disposed(by: disposeBag)
        self.sendMessageAPI.preSendMessage(cid: randomCid)
        let message = Message.transform(pb: Message.PBModel()); message.cid = randomCid
        self.sendMessageAPI.adjustLocalStatus(message: message, stateHandler: nil)
        expectation.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
        if expectation.autoFulfill { return }
    }

    /// 测试statusDriver能否正常回调
    func testStatusDriverForDealPushMessage() {
        let disposeBag = DisposeBag()
        let expectation = LKTestExpectation(description: "@test status driver")
        let randomCid = RandomString.random(length: 10)
        self.sendMessageAPI.statusDriver.drive { (message, error) in
            guard message.cid == randomCid else { return }
            XCTAssertEqual(message.cid, randomCid)
            XCTAssertNil(error)
            expectation.fulfill()
        }.disposed(by: disposeBag)
        self.sendMessageAPI.preSendMessage(cid: randomCid)
        let message = Message.transform(pb: Message.PBModel()); message.cid = randomCid
        _ = self.sendMessageAPI.dealPushMessage(message: message)
        expectation.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
        if expectation.autoFulfill { return }
    }
}
