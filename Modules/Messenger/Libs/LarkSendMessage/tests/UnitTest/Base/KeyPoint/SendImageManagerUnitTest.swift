//
//  SendImageManagerUnitTest.swift
//  LarkSendMessage-Unit-Tests
//
//  Created by 李勇 on 2023/1/20.
//

import UIKit
import XCTest
import Foundation
import Photos
import RxSwift // Observable
import ByteWebImage // SendImageRequest

/// SendImageManager新增单测
final class SendImageManagerUnitTest: CanSkipTestCase {
    /// 测试Process执行顺序、Context存取
    class TestProcessorResult { var number: Int = 0 }
    class TestCheckProcessor: LarkSendImageProcessor {
        private let result: TestProcessorResult
        init(_ result: TestProcessorResult) { self.result = result }
        func imageProcess(sendImageState: SendImageState, request: LarkSendImageAbstractRequest) -> Observable<Void> {
            XCTAssertEqual(self.result.number, 0)
            XCTAssertNotNil(request.getContext()[SendImageRequestKey.CheckResult.CheckResult])
            self.result.number = 1
            return .just(())
        }
    }
    class TestCompressProcessor: LarkSendImageProcessor {
        private let result: TestProcessorResult
        init(_ result: TestProcessorResult) { self.result = result }
        func imageProcess(sendImageState: SendImageState, request: LarkSendImageAbstractRequest) -> Observable<Void> {
            XCTAssertEqual(self.result.number, 2)
            XCTAssertNotNil(request.getContext()[SendImageRequestKey.CompressResult.CompressResult])
            self.result.number = 3
            return .just(())
        }
    }
    class TestImageUploader: LarkSendImageUploader {
        private let result: TestProcessorResult
        init(_ result: TestProcessorResult) { self.result = result }
        typealias ResultType = Int
        func imageUpload(request: LarkSendImageAbstractRequest) -> Observable<Int> {
            XCTAssertEqual(self.result.number, 3)
            self.result.number = 4
            return .just(100)
        }
    }
    class TestUploadProcessor: LarkSendImageProcessor {
        private let result: TestProcessorResult
        init(_ result: TestProcessorResult) { self.result = result }
        func imageProcess(sendImageState: SendImageState, request: LarkSendImageAbstractRequest) -> Observable<Void> {
            XCTAssertEqual(self.result.number, 4)
            XCTAssertNotNil(request.getContext()[SendImageRequestKey.UploadResult.ResultType])
            self.result.number = 5
            return .just(())
        }
    }
    func testProcessAndContext() {
        let disposeBag = DisposeBag()
        let expectation = LKTestExpectation(description: "@test process and context")
        let result = TestProcessorResult()
        XCTAssertEqual(result.number, 0)

        let request = SendImageRequest(input: .asset(PHAsset()), uploader: TestImageUploader(result))
        XCTAssertNotNil(request.getContext()[SendImageRequestKey.InitParams.InputType])
        XCTAssertNotNil(request.getContext()[SendImageRequestKey.InitParams.SendImageConfig])
        request.addProcessor(afterState: .check, processor: TestCheckProcessor(result), processorId: "test.image.check.process")
        let hasProProcessBlock: PreCompressResultBlock = { _ in
            XCTAssertEqual(result.number, 1)
            result.number = 2
            return ImageSourceResult(sourceType: .jpeg, data: Resources.imageData(named: "1200x1400-JPEG"), image: Resources.image(named: "1200x1400-JPEG"))
        }
        request.setContext(key: SendImageRequestKey.CompressResult.PreCompressResultBlock, value: hasProProcessBlock)
        request.addProcessor(afterState: .compress, processor: TestCompressProcessor(result), processorId: "test.image.compress.process")
        request.addProcessor(afterState: .upload, processor: TestUploadProcessor(result), processorId: "test.image.upload.process")
        SendImageManager.shared.sendImage(request: request).subscribe { uploadResult in
            XCTAssertEqual(result.number, 5)
            XCTAssertEqual(uploadResult, 100)
            expectation.fulfill()
        } onError: { _ in
            XCTExpectFailure("send image error")
            expectation.fulfill()
        }.disposed(by: disposeBag)

        expectation.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
        if expectation.autoFulfill { return }
    }

    /// 测试ImageUploadChecker对PHAsset的检测逻辑：文件类型、文件大小、分辨率
    func testPHAssetChecker() {
        // PHAsset是相册选取的，目前不好Mock，所以就测试一个默认行为：空的PHAsset()文件类型为unknown，通不过文件类型检测
        if case .failure(let checkError) = ImageUploadChecker.getAssetCheckResult(asset: PHAsset(), formatOptions: [.useOrigin]) {
            XCTAssertEqual(checkError, .fileTypeInvalid)
        } else {
            XCTExpectFailure("PHAsset checker error")
        }
    }

    /// 测试ImageUploadChecker对NSData的检测逻辑：文件类型、文件大小、分辨率
    func testNSDataChecker() {
        // 默认能通过检测
        if case .failure(_) = ImageUploadChecker.getDataCheckResult(data: Resources.imageData(named: "1200x1400-JPEG"), formatOptions: [.useOrigin]) {
            XCTExpectFailure("NSData checker error")
        }
        // 限制只能发送PNG
        if case .failure(let checkError) = ImageUploadChecker.getDataCheckResult(data: Resources.imageData(named: "1200x1400-JPEG"), formatOptions: [.useOrigin], customLimitFileType: ["PNG"]) {
            XCTAssertEqual(checkError, .fileTypeInvalid)
        } else {
            XCTExpectFailure("NSData checker error")
        }
        // 限制只能发送10kb的大小
        if case .failure(let checkError) = ImageUploadChecker.getDataCheckResult(data: Resources.imageData(named: "1200x1400-JPEG"), formatOptions: [.useOrigin], customLimitFileSize: 10 * 1024) {
            XCTAssertEqual(checkError, .imageFileSizeExceeded(10 * 1024))
        } else {
            XCTExpectFailure("NSData checker error")
        }
        // 限制只能发送10x10的分辨率
        if case .failure(let checkError) = ImageUploadChecker.getDataCheckResult(
            data: Resources.imageData(named: "1200x1400-JPEG"),
            formatOptions: [.useOrigin],
            customLimitImageSize: CGSize(width: 10, height: 10)) {
            XCTAssertEqual(checkError, .imagePixelsExceeded(CGSize(width: 10, height: 10)))
        } else {
            XCTExpectFailure("NSData checker error")
        }
    }

    /// 测试ImageUploadChecker对UIImage的检测逻辑：分辨率
    func testUIImageChecker() {
        // 默认能通过检测
        if case .failure(_) = ImageUploadChecker.getImageSizeCheckResult(sourceImageType: .jpeg, finalImageType: .jpeg, imageSize: CGSize(width: 1200, height: 1400)) {
            XCTExpectFailure("UIImage checker error")
        }
        // 限制只能发送10x10的分辨率
        if case .failure(let checkError) = ImageUploadChecker.getImageSizeCheckResult(
            sourceImageType: .jpeg,
            finalImageType: .jpeg,
            imageSize: CGSize(width: 1200, height: 1400),
            customLimitImageSize: CGSize(width: 10, height: 10)) {
            XCTAssertEqual(checkError, .imagePixelsExceeded(CGSize(width: 10, height: 10)))
        } else {
            XCTExpectFailure("UIImage checker error")
        }
    }

    /// 测试getFinalImageType
    func testFinalImageType() {
        // GIF/useOrigin格式保持不变
        XCTAssertEqual(ImageUploadChecker.getFinalImageType(imageType: .gif, formatOptions: [.needConvertToWebp]), .gif)
        XCTAssertEqual(ImageUploadChecker.getFinalImageType(imageType: .gif, formatOptions: []), .gif)
        XCTAssertEqual(ImageUploadChecker.getFinalImageType(imageType: .heic, formatOptions: [.useOrigin]), .heic)
        XCTAssertEqual(ImageUploadChecker.getFinalImageType(imageType: .png, formatOptions: [.useOrigin]), .png)
        XCTAssertEqual(ImageUploadChecker.getFinalImageType(imageType: .jpeg, formatOptions: [.useOrigin]), .jpeg)

        // 否则判断needConvertToWebp转为WebP
        XCTAssertEqual(ImageUploadChecker.getFinalImageType(imageType: .jpeg, formatOptions: [.needConvertToWebp]), .webp)
        XCTAssertEqual(ImageUploadChecker.getFinalImageType(imageType: .heic, formatOptions: [.needConvertToWebp]), .webp)
        XCTAssertEqual(ImageUploadChecker.getFinalImageType(imageType: .png, formatOptions: [.needConvertToWebp]), .webp)

        // 兜底为JPEG
        XCTAssertEqual(ImageUploadChecker.getFinalImageType(imageType: .jpeg, formatOptions: []), .jpeg)
        XCTAssertEqual(ImageUploadChecker.getFinalImageType(imageType: .heic, formatOptions: []), .jpeg)
        XCTAssertEqual(ImageUploadChecker.getFinalImageType(imageType: .png, formatOptions: []), .jpeg)
    }

    /// getImageInfoCheckResult内部是依次调用的getFileUTICheckResult、getFileSizeCheckResult、getImageSizeCheckResult，不用再单独写测试

    /// 测试getFileUTICheckResult
    func testFileUTICheckResult() {
        // JPEG等常见格式能通过检测
        if case .failure(_) = ImageUploadChecker.getFileUTICheckResult(finalImageType: .jpeg) {
            XCTExpectFailure("UIImage checker error")
        }
        if case .failure(_) = ImageUploadChecker.getFileUTICheckResult(finalImageType: .webp) {
            XCTExpectFailure("UIImage checker error")
        }
        if case .failure(_) = ImageUploadChecker.getFileUTICheckResult(finalImageType: .png) {
            XCTExpectFailure("UIImage checker error")
        }
        if case .failure(_) = ImageUploadChecker.getFileUTICheckResult(finalImageType: .gif) {
            XCTExpectFailure("UIImage checker error")
        }
        // 密聊场景，heic/heif无法通过检测，密聊场景能通过的格式见：FileTypeCheckConfig-localWhiteList
        if case .failure(let checkError) = ImageUploadChecker.getFileUTICheckResult(finalImageType: .heic, formatOptions: [.isFromCrypto]) {
            XCTAssertEqual(checkError, .fileTypeInvalid)
        } else {
            XCTExpectFailure("UIImage checker error")
        }
        if case .failure(let checkError) = ImageUploadChecker.getFileUTICheckResult(finalImageType: .heif, formatOptions: [.isFromCrypto]) {
            XCTAssertEqual(checkError, .fileTypeInvalid)
        } else {
            XCTExpectFailure("UIImage checker error")
        }
        // 密聊场景，可通过自定义白名单绕过
        if case .failure(_) = ImageUploadChecker.getFileUTICheckResult(finalImageType: .heic, customLimitFileType: ["heic"], formatOptions: [.isFromCrypto]) {
            XCTExpectFailure("UIImage checker error")
        }
        if case .failure(_) = ImageUploadChecker.getFileUTICheckResult(finalImageType: .heif, customLimitFileType: ["heif"], formatOptions: [.isFromCrypto]) {
            XCTExpectFailure("UIImage checker error")
        }
        // 非密聊场景，heic/heif可以通过检测，非密聊场景能通过的格式见：FileTypeCheckConfig-serverWhiteList
        if case .failure(_) = ImageUploadChecker.getFileUTICheckResult(finalImageType: .heic) {
            XCTExpectFailure("UIImage checker error")
        }
        if case .failure(_) = ImageUploadChecker.getFileUTICheckResult(finalImageType: .heif) {
            XCTExpectFailure("UIImage checker error")
        }
    }

    /// 测试getFileSizeCheckResult，目前对PNG、JPEG、GIF进行了单独配置，其他使用兜底配置
    func testFileSizeCheckResult() {
        // PNG
        if case .failure(_) = ImageUploadChecker.getFileSizeCheckResult(sourceImageType: .png, finalImageType: .png, fileSize: 100) {
            XCTExpectFailure("UIImage checker error")
        }
        if case .failure(_) = ImageUploadChecker.getFileSizeCheckResult(sourceImageType: .png, finalImageType: .png, fileSize: 100, customLimitFileSize: 10) {} else {
            XCTExpectFailure("UIImage checker error")
        }
        // JPEG
        if case .failure(_) = ImageUploadChecker.getFileSizeCheckResult(sourceImageType: .jpeg, finalImageType: .jpeg, fileSize: 100) {
            XCTExpectFailure("UIImage checker error")
        }
        if case .failure(_) = ImageUploadChecker.getFileSizeCheckResult(sourceImageType: .jpeg, finalImageType: .jpeg, fileSize: 100, customLimitFileSize: 10) {} else {
            XCTExpectFailure("UIImage checker error")
        }
        // GIF
        if case .failure(_) = ImageUploadChecker.getFileSizeCheckResult(sourceImageType: .gif, finalImageType: .gif, fileSize: 100) {
            XCTExpectFailure("UIImage checker error")
        }
        if case .failure(_) = ImageUploadChecker.getFileSizeCheckResult(sourceImageType: .gif, finalImageType: .gif, fileSize: 100, customLimitFileSize: 10) {} else {
            XCTExpectFailure("UIImage checker error")
        }
        // 其他
        if case .failure(_) = ImageUploadChecker.getFileSizeCheckResult(sourceImageType: .webp, finalImageType: .webp, fileSize: 100) {
            XCTExpectFailure("UIImage checker error")
        }
        if case .failure(_) = ImageUploadChecker.getFileSizeCheckResult(sourceImageType: .webp, finalImageType: .webp, fileSize: 100, customLimitFileSize: 10) {} else {
            XCTExpectFailure("UIImage checker error")
        }
        if case .failure(_) = ImageUploadChecker.getFileSizeCheckResult(sourceImageType: .heif, finalImageType: .heif, fileSize: 100) {
            XCTExpectFailure("UIImage checker error")
        }
        if case .failure(_) = ImageUploadChecker.getFileSizeCheckResult(sourceImageType: .heif, finalImageType: .heif, fileSize: 100, customLimitFileSize: 10) {} else {
            XCTExpectFailure("UIImage checker error")
        }
        if case .failure(_) = ImageUploadChecker.getFileSizeCheckResult(sourceImageType: .heic, finalImageType: .heic, fileSize: 100) {
            XCTExpectFailure("UIImage checker error")
        }
        if case .failure(_) = ImageUploadChecker.getFileSizeCheckResult(sourceImageType: .heic, finalImageType: .heic, fileSize: 100, customLimitFileSize: 10) {} else {
            XCTExpectFailure("UIImage checker error")
        }
    }

    ///测试SendImageProcessorImpl对图片的编码逻辑，已经在SendImageProcessorUnitTest中实现了
    // func testSendImageProcessor() {}
}
