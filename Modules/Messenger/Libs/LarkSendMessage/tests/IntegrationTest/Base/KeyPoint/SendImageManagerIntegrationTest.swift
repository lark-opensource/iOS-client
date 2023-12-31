//
//  SendImageManagerIntegrationTest.swift
//  LarkSendMessage-Unit-Tests
//
//  Created by 李勇 on 2023/1/28.
//

import XCTest
import Foundation
import ByteWebImage // LarkSendImageUploader
import LarkSDKInterface // ImageAPI
import LarkContainer // InjectedLazy
import RustPB // Media_V1_UploadSecureImageRequest
import RxSwift // Observable

/// 发送富文本：测试图片是否能正常上传成功
final class SendImageManagerIntegrationTest: CanSkipTestCase {
    func testDataUpload() {
        let disposeBag = DisposeBag()
        let expectation = LKTestExpectation(description: "@test data upload")
        let request = SendImageRequest(
            input: .data(Resources.imageData(named: "1200x1400-JPEG")),
            sendImageConfig: SendImageConfig(checkConfig: SendImageCheckConfig(isOrigin: true, scene: .Chat, biz: .Messenger, fromType: .post)),
            uploader: AttachmentDataUploader()
        )
        SendImageManager.shared.sendImage(request: request).subscribe(onNext: { result in
            XCTAssertFalse(result.isEmpty)
            expectation.fulfill()
        }, onError: { _ in
            XCTExpectFailure("upload data error")
            expectation.fulfill()
        }).disposed(by: disposeBag)
        expectation.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
        if expectation.autoFulfill { return }
    }

    /// 没必要测试SendImageRequest.input为Image的情况，因为上传时依然是Data传给SDK
    // func testImageUpload() { }

    /// 无法测试SendImageRequest.input为PHAsset的情况，因为PHAsset为相册选择的，无法Mock
    // func testAssetUpload() { }
}

final class AttachmentDataUploader: LarkSendImageUploader {
    typealias ResultType = String
    @InjectedLazy var imageAPI: ImageAPI

    func imageUpload(request: LarkSendImageAbstractRequest) -> Observable<String> {
        guard case .data(let imageData) = request.getInput() else {
            XCTExpectFailure("input need data type")
            return .just("")
        }
        return self.imageAPI.uploadSecureImage(data: imageData, type: .post, imageCompressedSizeKb: 0, encrypt: false)
    }
}
