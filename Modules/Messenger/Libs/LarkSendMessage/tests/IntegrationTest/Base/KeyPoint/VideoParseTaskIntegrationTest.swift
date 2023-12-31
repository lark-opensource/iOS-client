//
//  VideoParseTaskIntegrationTest.swift
//  LarkSendMessage-Unit-Tests
//
//  Created by 李勇 on 2023/1/29.
//

import XCTest
import Foundation
import RxSwift // DisposeBag
import LarkStorage // IsoPath
import LarkFileKit // Path
import LarkSDKInterface // UserGeneralSettings
import LarkContainer // InjectedLazy
@testable import LarkSendMessage
import Photos

// swiftlint:disable force_try

/// VideoParseTask新增集成测试
final class VideoParseTaskIntegrationTest: CanSkipTestCase {
    @InjectedLazy private var generalSettings: UserGeneralSettings
    @InjectedLazy private var transcodeService: VideoTranscodeService
    private let parseManager = VideoParseTaskManager()
    private lazy var videoSendSetting = self.generalSettings.videoSynthesisSetting.value.sendSetting

    /// 测试VideoParser+URL完整的处理流程
    func testVideoParserForUrl() {
        if !self.generalSettings.videoSynthesisSetting.value.coverSetting.limitEnable { return }

        let disposeBag = DisposeBag()
        let expectation = LKTestExpectation(description: "@test video parser for url")
        let tempFileDir = IsoPath.glboalTemporary(in: Domain.biz.messenger) + "test" + "upload"; try? tempFileDir.createDirectoryIfNeeded()
        // 后缀名需要是mp4等，否则asset.tracks(withMediaType: .video)为空
        let tempFilePath = tempFileDir + "temp.mp4"; try? tempFilePath.removeItem()
        try? Resources.mediaData(named: "10-540x960-mp4").write(to: tempFilePath)
        let task = try! VideoParseTask(userResolver: Container.shared.getCurrentUserResolver(),
                                       data: .fileURL(tempFilePath.url), isOriginal: false, type: .normal, transcodeService: self.transcodeService,
                                  videoSendSetting: self.videoSendSetting, taskID: SendVideoLogger.IDGenerator.uniqueID)
        parseManager.add(task: task, immediately: true).subscribe(onNext: { videoInfo in
            // 文件名等信息正确
            XCTAssertNotNil(videoInfo.preview)
            XCTAssertTrue(videoInfo.assetUUID.isEmpty)
            XCTAssertFalse(videoInfo.name.isEmpty)
            XCTAssertTrue(videoInfo.filesize > 0)
            XCTAssertNotEqual(videoInfo.naturalSize, .zero)
            XCTAssertFalse(videoInfo.exportPath.isEmpty)
            XCTAssertFalse(videoInfo.compressPath.isEmpty)
            XCTAssertTrue(videoInfo.duration > 0)
            XCTAssertEqual(videoInfo.status, .fillBaseInfo)
            XCTAssertFalse(videoInfo.isPHAssetVideo)
            XCTAssertNotNil(videoInfo.videoSendSetting)
            XCTAssertNotNil(videoInfo.firstFrameData)
            // 原文件路径不存在，新文件路径有值
            XCTAssertFalse(tempFilePath.exists)
            XCTAssertTrue(Path(videoInfo.exportPath).exists)
            XCTAssertFalse(Path(videoInfo.compressPath).exists)
            // 删除文件，不影响后续单测
            try? Path(videoInfo.exportPath).deleteFile()
            expectation.fulfill()
        }, onError: { error in
            XCTExpectFailure("should no error \(error)")
            expectation.fulfill()
        }).disposed(by: disposeBag)
        expectation.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
        if expectation.autoFulfill { return }
    }

    /// 测试VideoParser+PHAsset完整的处理流程，PHAsset为相册获取的，目前只能测试默认情况
    func testVideoParserForPHAsset() {
        let disposeBag = DisposeBag()
        let expectation = LKTestExpectation(description: "@test video parser for asset")
        let task = try! VideoParseTask(userResolver: Container.shared.getCurrentUserResolver(), data: .asset(PHAsset()), isOriginal: false, type: .normal, transcodeService: self.transcodeService,
                                  videoSendSetting: self.videoSendSetting, taskID: SendVideoLogger.IDGenerator.uniqueID)
        parseManager.add(task: task, immediately: true).subscribe(onNext: { _ in
            XCTExpectFailure("should load avasset error")
            expectation.fulfill()
        }, onError: { error in
            if case VideoParseError.loadAVAssetError = error {} else { XCTExpectFailure("need load avasset error") }
            expectation.fulfill()
        }).disposed(by: disposeBag)
        expectation.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
        if expectation.autoFulfill { return }
    }
}

// swiftlint:enable force_try
