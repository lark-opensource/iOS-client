//
//  VideoChunkUploaderUnitTest.swift
//  LarkSendMessage-Unit-Tests
//
//  Created by 李勇 on 2023/1/29.
//

import XCTest
import Foundation
import LarkModel // Message
import RustPB // Basic_V1_LarkError
import LarkContainer // InjectedSafeLazy
import LarkSDKInterface // ChatAPI
@testable import LarkSendMessage

// swiftlint:disable force_try

/// VideoChunkUploader新增单测
final class VideoChunkUploaderUnitTest: CanSkipTestCase {
    @InjectedSafeLazy private var sendMessageAPI: SendMessageAPI
    @InjectedSafeLazy private var chatAPI: ChatAPI
    /// 需要持有，不然会deinit，导致finishCallback无法触发
    private lazy var chunkUploader = try! VideoChunkUploader(userResolver: Container.shared.getCurrentUserResolver())
    private lazy var transcodeTask = try! TranscodeTask(
        userResolver: Container.shared.getCurrentUserResolver(),
        id: "", type: .normal, isOriginal: true, key: "", duration: 0, size: 0, exportPath: "", compressPath: "", videoSize: .zero, isPHAssetVideo: false,
        canPassthrough: false, compressCoverFileSize: 0, modificationDate: Date().timeIntervalSince1970, from: nil, sender: { _ in }, stateHandler: nil)

    override func setUp() {
        super.setUp()
        self.chunkUploader = try! VideoChunkUploader(userResolver: Container.shared.getCurrentUserResolver())
    }

    /// 测试分片上传
    func testChunkUpload() {
        let expectation = LKTestExpectation(description: "@test chunk upload")
        // 需要设置cid、chatId，Rust才会给端上PushChunkyUploadStatus
        let message = Message.transform(pb: Message.PBModel())
        message.cid = RandomString.random(length: 10)
        message.channel.id = "7180179231060557852"
        self.transcodeTask.extraInfo[VideoChunkUploader.messageKey] = message

        self.chunkUploader.finishCallback = { (cancel, error) in
            XCTAssertNil(error)
            XCTAssertFalse(cancel)
            expectation.fulfill()
        }
        // 伪造两个分片数据进行上传
        let chunkQueue = DispatchQueue(label: "video_chunk_queue", qos: .userInteractive, attributes: [], autoreleaseFrequency: .inherit, target: nil)
        let mediaDatas = Resources.mediaData(named: "10-540x960-mp4")
        self.chunkUploader.upload(task: self.transcodeTask, data: mediaDatas.prefix(100 * 1024), offset: 0, size: 100 * 1024, isFinish: false, in: chunkQueue)
        self.chunkUploader.upload(task: self.transcodeTask, data: mediaDatas.suffix(from: 100 * 1024), offset: 100 * 1024, size: Int32(mediaDatas.count - 100 * 1024), isFinish: true,
                                  in: chunkQueue)
        expectation.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
        if expectation.autoFulfill { return }
    }

    /// 测试finishCallback是否正常回调、uploading/finished值是否正确
    func testFinishCallbackForCancel() {
        let expectation = LKTestExpectation(description: "@test finish callback")
        XCTAssertFalse(self.chunkUploader.uploading)
        XCTAssertFalse(self.chunkUploader.finished)
        self.chunkUploader.upload(task: self.transcodeTask, data: Data(), offset: 0, size: 0, isFinish: false, in: DispatchQueue.global())
        XCTAssertTrue(self.chunkUploader.uploading)
        XCTAssertFalse(self.chunkUploader.finished)
        // 测试手动cancle
        self.chunkUploader.finishCallback = { [weak self] (cancel, error) in
            XCTAssertNil(error)
            XCTAssertTrue(cancel)
            XCTAssertTrue(self?.chunkUploader.finished ?? false)
            XCTAssertFalse(self?.chunkUploader.uploading ?? false)
            expectation.fulfill()
        }
        self.chunkUploader.cancel(in: DispatchQueue.global())
        expectation.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
        if expectation.autoFulfill { return }
    }

    /// 测试finishCallback是否正常回调、uploading/finished值是否正确
    func testFinishCallbackForPush() {
        let expectation = LKTestExpectation(description: "@test finish callback")
        self.chunkUploader.upload(task: self.transcodeTask, data: Data(), offset: 0, size: 0, isFinish: false, in: DispatchQueue.global())
        // 测试手动push
        self.chunkUploader.finishCallback = { [weak self] (cancel, error) in
            XCTAssertNil(error)
            XCTAssertFalse(cancel)
            XCTAssertTrue(self?.chunkUploader.finished ?? false)
            XCTAssertFalse(self?.chunkUploader.uploading ?? false)
            expectation.fulfill()
        }
        self.sendMessageAPI.pushCenter.post(PushChunkyUploadStatus(uploadID: self.chunkUploader.uploadID, status: .success(0)))
        expectation.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
        if expectation.autoFulfill { return }
    }

    /// 测试finishCallback是否正常回调、uploading/finished值是否正确
    func testFinishCallbackForPushError() {
        let expectation = LKTestExpectation(description: "@test finish callback")
        self.chunkUploader.upload(task: self.transcodeTask, data: Data(), offset: 0, size: 0, isFinish: false, in: DispatchQueue.global())
        // 测试手动error
        self.chunkUploader.finishCallback = { [weak self] (cancel, error) in
            XCTAssertNotNil(error)
            XCTAssertFalse(cancel)
            XCTAssertTrue(self?.chunkUploader.finished ?? false)
            XCTAssertFalse(self?.chunkUploader.uploading ?? false)
            expectation.fulfill()
        }
        self.sendMessageAPI.pushCenter.post(PushChunkyUploadStatus(uploadID: self.chunkUploader.uploadID, status: .error(Basic_V1_LarkError())))
        expectation.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
        if expectation.autoFulfill { return }
    }
}
// swiftlint:enable force_try
