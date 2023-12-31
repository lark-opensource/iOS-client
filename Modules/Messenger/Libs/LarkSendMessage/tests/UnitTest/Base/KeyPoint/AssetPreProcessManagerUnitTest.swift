//
//  AssetPreProcessManagerUnitTest.swift
//  LarkSendMessage-Unit-Tests
//
//  Created by 李勇 on 2023/1/6.
//

import XCTest
import Foundation
import Photos
import RxSwift // DisposeBag
import RustPB // Media_V1_PreprocessResourceRequest
import LarkStorage // IsoPath
import ByteWebImage // ImageSourceResult
import LarkContainer // InjectedLazy
import LarkSDKInterface // SDKRustService
@testable import LarkSendMessage

/// 对AssetPreProcessManager类进行单测
final class AssetPreProcessManagerUnitTest: CanSkipTestCase {
    // 这里使用懒加载方式，否则获取到过期的userResolver
    private lazy var preProcessManager = AssetPreProcessManager(userResolver: Container.shared.getCurrentUserResolver(), isCrypto: false)
    @InjectedLazy private var rustService: SDKRustService
    private let assetName = "test_asset_name"

    override func setUp() {
        // checkPreProcessEnable、checkEnable设置为true，内部逻辑才能正常生效
        self.preProcessManager.checkPreProcessEnable = true
        self.preProcessManager.checkEnable = true
        super.setUp()
    }

    /// 测试工具接口
    func testToolFunc() {
        // getDefaultKeyFrom
        XCTAssertFalse(preProcessManager.getDefaultKeyFrom(phAsset: PHAsset()).isEmpty)
        // combineImageKeyWithIsOriginal
        XCTAssertTrue(preProcessManager.combineImageKeyWithIsOriginal(imageKey: "", isOriginal: true) == "_oiginal")
        XCTAssertTrue(preProcessManager.combineImageKeyWithIsOriginal(imageKey: "", isOriginal: false) == "_notOriginal")
        // combineImageKeyWithCover
        XCTAssertTrue(preProcessManager.combineImageKeyWithCover(imageKey: "") == "_cover")
        // checkEnableByType
        XCTAssertTrue(preProcessManager.checkEnableByType(fileType: .file))
        XCTAssertTrue(preProcessManager.checkEnableByType(fileType: .image))
        XCTAssertTrue(preProcessManager.checkEnableByType(fileType: .media))
    }

    /// 测试finishAssets存取
    func testFinishAssets() {
        // 初始时没有数据
        XCTAssertNil(preProcessManager.getImageSourceResult(assetName: self.assetName))
        XCTAssertTrue(!preProcessManager.checkAssetHasOperation(assetName: self.assetName))

        // 添加数据
        preProcessManager.addToFinishAssets(name: self.assetName, value: ImageSourceResult(imageProcessResult: nil))
        XCTAssertNotNil(preProcessManager.getImageSourceResult(assetName: self.assetName))
        XCTAssertTrue(preProcessManager.checkAssetHasOperation(assetName: self.assetName))

        // afterPreProcess内部会清空
        preProcessManager.afterPreProcess(assets: [])
        XCTAssertNil(preProcessManager.getImageSourceResult(assetName: self.assetName))
        XCTAssertTrue(!preProcessManager.checkAssetHasOperation(assetName: self.assetName))
    }

    /// 测试preProcessResourceKeys存取
    func testPreProcessResourceKeys() {
        // 初始时没有数据
        XCTAssertNil(preProcessManager.getPreprocessResourceKey(assetName: self.assetName))

        // 添加数据
        preProcessManager.addToPreprocessResource(name: self.assetName, value: "-")
        XCTAssertTrue(preProcessManager.getPreprocessResourceKey(assetName: self.assetName) == "-")

        // afterPreProcess内部会清空
        preProcessManager.afterPreProcess(assets: [])
        XCTAssertNil(preProcessManager.getPreprocessResourceKey(assetName: self.assetName))

        // 添加数据
        preProcessManager.addToPreprocessResource(name: self.assetName, value: "-")
        XCTAssertTrue(preProcessManager.getPreprocessResourceKey(assetName: self.assetName) == "-")

        // cancelPreprocessResource内部会删除对应key
        preProcessManager.cancelPreprocessResource(assetName: self.assetName)
        XCTAssertNil(preProcessManager.getPreprocessResourceKey(assetName: self.assetName))
    }

    /// 测试pendingAssets存取
    func testPendingAssets() {
        // 初始时没有数据
        XCTAssertTrue(!preProcessManager.checkAssetHasOperation(assetName: self.assetName))

        // 添加数据
        preProcessManager.addToPendingAssets(name: self.assetName, value: NSObject())
        XCTAssertTrue(preProcessManager.checkAssetHasOperation(assetName: self.assetName))

        // cancelAllOperation内部会清空
        preProcessManager.cancelAllOperation()
        XCTAssertTrue(!preProcessManager.checkAssetHasOperation(assetName: self.assetName))

        // 添加数据
        preProcessManager.addToPendingAssets(name: self.assetName, value: NSObject())
        XCTAssertTrue(preProcessManager.checkAssetHasOperation(assetName: self.assetName))

        // removeFromPendingAsset内部会删除对应key
        preProcessManager.removeFromPendingAsset(name: self.assetName)
        XCTAssertTrue(!preProcessManager.checkAssetHasOperation(assetName: self.assetName))
    }

    /// 测试Rust图片预处理接口
    func testRustImagePreprocess() {
        var textResult = true; let disposeBag = DisposeBag()
        let expectation = LKTestExpectation(description: "@test rust image preprocess")
        // 发送预处理请求
        var request = RustPB.Media_V1_PreprocessResourceRequest()
        request.fileType = .image
        request.image = Resources.imageData(named: "1200x1400-JPEG")
        self.rustService.sendAsyncRequest(request).subscribe(onNext: { (resp: Media_V1_PreprocessResourceResponse) in
            // 发送取消预处理请求
            var request = RustPB.Media_V1_CancelPreprocessResourceRequest()
            request.key = resp.key
            self.rustService.sendAsyncRequest(request).subscribe(onNext: { _ in
                expectation.fulfill()
            }, onError: { _ in
                textResult = false
                expectation.fulfill()
            }).disposed(by: disposeBag)
        }, onError: { _ in
            textResult = false
            expectation.fulfill()
        }).disposed(by: disposeBag)
        expectation.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
        if expectation.autoFulfill { return }
        XCTAssertTrue(textResult)
    }

    /// 测试Rust文件预处理接口
    func testRustFilePreprocess() {
        var textResult = true; let disposeBag = DisposeBag()
        let expectation = LKTestExpectation(description: "@test rust file preprocess")
        // 自己搞一个临时路径
        let tempFileDir = IsoPath.glboalTemporary(in: Domain.biz.messenger) + "test" + "preprocess"
        try? tempFileDir.createDirectoryIfNeeded()
        let tempFilePath = tempFileDir + "temp"
        try? tempFilePath.removeItem()
        do {
            let imageData = Resources.imageData(named: "1200x1400-JPEG")
            try imageData.write(to: tempFilePath)
        } catch {
            textResult = false
            expectation.fulfill()
        }
        // 发送预处理请求
        var request = RustPB.Media_V1_PreprocessResourceRequest()
        request.fileType = .file
        request.filePath = tempFilePath.absoluteString
        self.rustService.sendAsyncRequest(request).subscribe(onNext: { (resp: Media_V1_PreprocessResourceResponse) in
            // 发送取消预处理请求
            var request = RustPB.Media_V1_CancelPreprocessResourceRequest()
            request.key = resp.key
            self.rustService.sendAsyncRequest(request).subscribe(onNext: { _ in
                expectation.fulfill()
            }, onError: { _ in
                textResult = false
                expectation.fulfill()
            }).disposed(by: disposeBag)
        }, onError: { _ in
            textResult = false
            expectation.fulfill()
        }).disposed(by: disposeBag)
        expectation.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
        if expectation.autoFulfill { return }
        XCTAssertTrue(textResult)
    }
}
