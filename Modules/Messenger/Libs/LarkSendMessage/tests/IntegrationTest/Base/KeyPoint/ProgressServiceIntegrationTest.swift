//
//  ProgressServiceIntegrationTest.swift
//  LarkSendMessage-Unit-Tests
//
//  Created by 李勇 on 2023/1/30.
//

import XCTest
import Foundation
import LarkStorage // IsoPath
import RxSwift // DisposeBag
import LarkModel // ImageContent
import LarkContainer // InjectedSafeLazy
import LarkSDKInterface // SDKRustService
@testable import LarkSendMessage

/// ProgressService新增集成测试
final class ProgressServiceIntegrationTest: CanSkipTestCase {
    @InjectedSafeLazy private var progressService: ProgressService
    @InjectedSafeLazy private var rustService: SDKRustService

    /// 测试图片上传时，进度、速率、完成是否正常回调
    func testImageUpload() {
        let disposeBag = DisposeBag(); let messageCid = RandomString.random(length: 16)
        let expectation = LKTestExpectation(description: "@test image upload")
        // 监听进度值
        var progressKeyLastValue: Int64 = 0; var progressKeyCount: Int64 = 0; var progressTestKey: String = ""
        DispatchQueue.global().async {
            // 图片比较大，我们缩小到5MB
            var testImageData = Resources.imageData(named: "1170x2532-PNG")
            testImageData = testImageData.subdata(in: 0..<5 * 1024 * 1024)
            // 图片后面拼上随机内容，防止秒传
            testImageData.append(RandomString.random(length: 100).data(using: .utf8) ?? Data())
            // 创建图片假消息
            let apiContext = APIContext(contextID: RandomString.random(length: 10))
            var originContent = QuasiContent()
            originContent.isOriginSource = true
            originContent.width = 1200
            originContent.height = 1400
            originContent.image = testImageData
            guard let quasiMessage = try? RustSendMessageModule.createQuasiMessage(chatId: "7180179231060557852",
                                                                                   type: .image,
                                                                                   content: originContent,
                                                                                   cid: messageCid,
                                                                                   client: self.rustService,
                                                                                   context: apiContext).0 else {
                XCTExpectFailure("quasi message is nil, cid:\(messageCid)")
                expectation.fulfill()
                return
            }
            guard let imageContent = (quasiMessage.content as? ImageContent) else {
                XCTExpectFailure("content not is image content, cid:\(messageCid)")
                expectation.fulfill()
                return
            }

            // SEND_MESSAGE时，SDK内部以此key向端上Push进度
            progressTestKey = imageContent.image.origin.key
            // 监听进度值
            self.progressService.value(key: progressTestKey).subscribe { progress in
                progressKeyCount += 1
                progressKeyLastValue = progress.completedUnitCount
                if progressKeyLastValue == 100 { DispatchQueue.main.asyncAfter(deadline: .now() + 2) { expectation.fulfill() } }
            }.disposed(by: disposeBag)
            // 监听速率值，图片上传场景，速率全是-1
            self.progressService.rateValue(key: progressTestKey).subscribe { progress in
                if progress == -1 { return }
                XCTExpectFailure("progress != -1, cid:\(messageCid)")
                expectation.fulfill()
            }.disposed(by: disposeBag)
            // 监听finish，图片上传场景，不会有finish回调
            self.progressService.finish(key: progressTestKey).subscribe { _ in
                XCTExpectFailure("have finish, cid:\(messageCid)")
                expectation.fulfill()
            }.disposed(by: disposeBag)

            // 发送消息
            RustSendMessageModule.sendMessage(cid: quasiMessage.cid, client: self.rustService, context: apiContext).subscribe().disposed(by: disposeBag)
        }
        expectation.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
        if expectation.autoFulfill { return }
        // 判断监听进度，SDK有频率控制，不一定次数很多
        XCTAssertEqual(progressKeyLastValue, 100, "cid:\(messageCid) key:\(progressTestKey)")
        XCTAssertTrue(progressKeyCount >= 1, "cid:\(messageCid) key:\(progressTestKey)")
    }

    /// 测试文件上传时，进度、速率、完成是否正常回调
    func testFileUpload() {
        let disposeBag = DisposeBag(); let messageCid = RandomString.random(length: 16)
        let expectation = LKTestExpectation(description: "@test file upload")
        // 监听进度值
        var progressKeyLastValue: Int64 = 0; var progressKeyCount: Int64 = 0; var progressTestKey: String = ""
        // 监听速率值、finish
        var rateKeyValue: Int64 = 0; var haveKeyFinish: Bool = false
        DispatchQueue.global().async {
            // 文件比较大，我们缩小到5MB
            var testImageData = Resources.imageData(named: "1170x2532-PNG")
            testImageData = testImageData.subdata(in: 0..<5 * 1024 * 1024)
            // 文件后面拼上随机内容，防止秒传
            testImageData.append(RandomString.random(length: 100).data(using: .utf8) ?? Data())
            // 自己搞一个临时路径
            let tempFileDir = IsoPath.glboalTemporary(in: Domain.biz.messenger) + "test" + "upload"
            try? tempFileDir.createDirectoryIfNeeded()
            let tempFilePath = tempFileDir + "temp"
            try? tempFilePath.removeItem()
            do {
                let imageData = testImageData
                try imageData.write(to: tempFilePath)
            } catch {
                XCTExpectFailure("data move to path error")
                expectation.fulfill()
            }
            // 创建文件假消息
            let apiContext = APIContext(contextID: RandomString.random(length: 10))
            var originContent = QuasiContent()
            originContent.path = tempFilePath.absoluteString
            originContent.name = "1170x2532-PNG"
            originContent.fileSource = .larkServer
            guard let quasiMessage = try? RustSendMessageModule.createQuasiMessage(chatId: "7180179231060557852",
                                                                                   type: .file,
                                                                                   content: originContent,
                                                                                   cid: messageCid,
                                                                                   client: self.rustService,
                                                                                   context: apiContext).0 else {

                XCTExpectFailure("quasi message is nil, cid:\(messageCid)")
                expectation.fulfill()
                return
            }
            guard let fileContent = (quasiMessage.content as? FileContent) else {
                XCTExpectFailure("content not is file content, cid:\(messageCid)")
                expectation.fulfill()
                return
            }

            // SEND_MESSAGE时，SDK内部以此key向端上Push进度
            progressTestKey = fileContent.key
            // 监听进度值
            self.progressService.value(key: progressTestKey).subscribe { progress in
                progressKeyCount += 1
                progressKeyLastValue = progress.completedUnitCount
            }.disposed(by: disposeBag)
            // 监听速率值
            self.progressService.rateValue(key: progressTestKey).subscribe { progress in
                rateKeyValue = max(rateKeyValue, progress)
            }.disposed(by: disposeBag)
            // 监听finish，文件上传场景，有finish回调
            self.progressService.finish(key: progressTestKey).subscribe { _ in
                haveKeyFinish = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) { expectation.fulfill() }
            }.disposed(by: disposeBag)

            // 发送消息
            RustSendMessageModule.sendMessage(cid: quasiMessage.cid, client: self.rustService, context: apiContext).subscribe().disposed(by: disposeBag)
        }
        expectation.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
        if expectation.autoFulfill { return }
        // 判断监听进度，SDK有频率控制，不一定次数很多
        XCTAssertEqual(progressKeyLastValue, 100)
        XCTAssertTrue(progressKeyCount >= 1)
        XCTAssertTrue(rateKeyValue > 0, "cid:\(messageCid) key:\(progressTestKey)")
        XCTAssertTrue(haveKeyFinish, "cid:\(messageCid) key:\(progressTestKey)")
    }

    /// 测试视频上传时，进度、速率、完成是否正常回调
    func testMediaUpload() {
        let disposeBag = DisposeBag(); let messageCid = RandomString.random(length: 16)
        let expectation = LKTestExpectation(description: "@test media upload")
        // 监听进度值
        var progressKeyLastValue: Int64 = 0; var progressKeyCount: Int64 = 0
        // 监听速率值、finish
        var rateKeyValue: Int64 = 0; var haveKeyFinish: Bool = false; var progressTestKey: String = ""
        DispatchQueue.global().async {
            // 自己搞一个临时路径
            let tempFileDir = IsoPath.glboalTemporary(in: Domain.biz.messenger) + "test" + "upload"
            try? tempFileDir.createDirectoryIfNeeded()
            let tempFilePath = tempFileDir + "temp.mp4"
            try? tempFilePath.removeItem()
            do {
                // 视频比较大，我们缩小到5MB
                var testMediaData = Resources.mediaData(named: "20-1080x1920-mov")
                testMediaData = testMediaData.subdata(in: 0..<5 * 1024 * 1024)
                // 视频后面拼上随机内容，防止秒传
                testMediaData.append(RandomString.random(length: 100).data(using: .utf8) ?? Data())
                try testMediaData.write(to: tempFilePath)
            } catch {
                XCTExpectFailure("data move to path error")
                expectation.fulfill()
            }
            // 创建视频假消息
            let apiContext = APIContext(contextID: RandomString.random(length: 10))
            var originContent = QuasiContent()
            // 视频
            originContent.compressPath = tempFilePath.absoluteString
            originContent.path = originContent.compressPath // SDK创建假消息有值为空的判断，不会有其他作用
            originContent.name = "20-1080x1920-mov"
            originContent.duration = 10
            originContent.mediaSource = .lark
            // 首帧
            originContent.width = 1200
            originContent.height = 1400
            originContent.image = Resources.imageData(named: "1200x1400-JPEG")
            guard let quasiMessage = try? RustSendMessageModule.createQuasiMessage(chatId: "7180179231060557852",
                                                                                   type: .media,
                                                                                   content: originContent,
                                                                                   cid: messageCid,
                                                                                   client: self.rustService,
                                                                                   context: apiContext).0 else {

                XCTExpectFailure("quasi message is nil, cid:\(messageCid)")
                expectation.fulfill()
                return
            }
            guard let mediaContent = (quasiMessage.content as? MediaContent) else {
                XCTExpectFailure("content not is media content, cid:\(messageCid)")
                expectation.fulfill()
                return
            }

            // SEND_MESSAGE时，SDK内部以此key向端上Push进度
            progressTestKey = mediaContent.key
            // 监听进度值
            self.progressService.value(key: progressTestKey).subscribe { progress in
                progressKeyCount += 1
                progressKeyLastValue = progress.completedUnitCount
            }.disposed(by: disposeBag)
            // 监听速率值
            self.progressService.rateValue(key: progressTestKey).subscribe { progress in
                rateKeyValue = max(rateKeyValue, progress)
            }.disposed(by: disposeBag)
            // 监听finish，视频上传场景，有finish回调
            self.progressService.finish(key: progressTestKey).subscribe { _ in
                haveKeyFinish = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) { expectation.fulfill() }
            }.disposed(by: disposeBag)

            // 发送消息
            RustSendMessageModule.sendMessage(cid: quasiMessage.cid, client: self.rustService, context: apiContext).subscribe().disposed(by: disposeBag)
        }
        expectation.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
        if expectation.autoFulfill { return }
        // 判断监听进度，SDK有频率控制，不一定次数很多
        XCTAssertEqual(progressKeyLastValue, 100)
        XCTAssertTrue(progressKeyCount >= 1)
        XCTAssertTrue(rateKeyValue > 0, "cid:\(messageCid) key:\(progressTestKey)")
        XCTAssertTrue(haveKeyFinish, "cid:\(messageCid) key:\(progressTestKey)")
    }
}
