//
//  VideoTranscoderUnitTest.swift
//  LarkSendMessage-Unit-Tests
//
//  Created by 李勇 on 2023/1/31.
//

import UIKit
import XCTest
import Foundation
import AVFoundation
import RxSwift // DisposeBag
import LarkStorage // IsoPath
import LarkContainer // InjectedLazy
import LarkSDKInterface // UserGeneralSettings
@testable import LarkSendMessage

/// VideoTranscoder新增单测
final class VideoTranscoderUnitTest: CanSkipTestCase {
    @InjectedLazy private var transcodeService: VideoTranscodeService
    @InjectedLazy private var generalSettings: UserGeneralSettings

    func testDegress() {
        // 90
        XCTAssertEqual(VideoTranscoder.degress(with: CGAffineTransform(0, 1, -1, 0, 0, 0)), 90)
        XCTAssertEqual(VideoTranscoder.degress(with: CGAffineTransform(0, -1, -1, 0, 0, 0)), 90)
        // 270
        XCTAssertEqual(VideoTranscoder.degress(with: CGAffineTransform(0, -1, 1, 0, 0, 0)), 270)
        XCTAssertEqual(VideoTranscoder.degress(with: CGAffineTransform(0, 1, 1, 0, 0, 0)), 270)
        // 0
        XCTAssertEqual(VideoTranscoder.degress(with: CGAffineTransform(1, 0, 0, 1, 0, 0)), 0)
        // 180
        XCTAssertEqual(VideoTranscoder.degress(with: CGAffineTransform(-1, 0, 0, -1, 0, 0)), 180)
    }

    func testVideoPreviewSize() {
        // 调整
        XCTAssertEqual(VideoTranscoder.videoPreviewSize(with: CGSize(width: 10, height: 20), degress: 90), CGSize(width: 20, height: 10))
        XCTAssertEqual(VideoTranscoder.videoPreviewSize(with: CGSize(width: 10, height: 20), degress: 270), CGSize(width: 20, height: 10))
        // 不调整
        XCTAssertEqual(VideoTranscoder.videoPreviewSize(with: CGSize(width: 10, height: 20), degress: 0), CGSize(width: 10, height: 20))
        XCTAssertEqual(VideoTranscoder.videoPreviewSize(with: CGSize(width: 10, height: 20), degress: 180), CGSize(width: 10, height: 20))
    }

    func testFilesizeAndVideoInfo() {
        // 自己搞一个临时路径
        let tempFileDir = IsoPath.glboalTemporary(in: Domain.biz.messenger) + "test" + "upload"; try? tempFileDir.createDirectoryIfNeeded()
        let tempFilePath = tempFileDir + "temp.mp4"; try? tempFilePath.removeItem(); try? Resources.mediaData(named: "10-540x960-mp4").write(to: tempFilePath)
        XCTAssertEqual(VideoTranscoder.filesize(for: AVURLAsset(url: tempFilePath.url)), 235_822.28574609375)
        guard let info = VideoTranscoder.videoInfo(avasset: AVURLAsset(url: tempFilePath.url)) else {
            XCTExpectFailure("get video info error")
            return
        }
        XCTAssertEqual(info.0, 30.000003814697266); XCTAssertEqual(info.1, 94_103.6875); XCTAssertEqual(info.2, CGSize(width: 540, height: 960))

        XCTAssertEqual(VideoTranscoder.filesize(for: AVURLAsset(url: URL(fileURLWithPath: ""))), 0)
        XCTAssertNil(VideoTranscoder.videoInfo(avasset: AVURLAsset(url: URL(fileURLWithPath: ""))))
    }

    func testCompress() {
        XCTAssertEqual(VideoTranscoder.compress(size: CGSize(width: 100, height: 200), rate: 1000, scale: 120), 2_000_000.0)
        XCTAssertEqual(VideoTranscoder.compress(size: CGSize(width: 1000, height: 2000), rate: 10, scale: 20), 12_000_000.0)
    }

    func testAdjustVideoSize() {
        // 如果settings没下发完成，不执行用例
        if self.generalSettings.videoSynthesisSetting.value.newCompressSetting.scenes.isEmpty || self.generalSettings.videoSynthesisSetting.value.newCompressSetting.config.isEmpty {
            return
        }

        var strategy = VideoTranscodeStrategy()
        XCTAssertEqual(self.transcodeService.adjustVideoSize(CGSize(width: 1280, height: 1280), strategy: strategy), CGSize(width: 960, height: 960))
        strategy.isOriginal = true
        XCTAssertEqual(self.transcodeService.adjustVideoSize(CGSize(width: 2000, height: 2000), strategy: strategy), CGSize(width: 1280, height: 1280))
        strategy.isOriginal = false; strategy.isForceReencode = true
        XCTAssertEqual(self.transcodeService.adjustVideoSize(CGSize(width: 1280, height: 1280), strategy: strategy), CGSize(width: 960, height: 960))
        strategy.isForceReencode = false; strategy.isWeakNetwork = true
        XCTAssertEqual(self.transcodeService.adjustVideoSize(CGSize(width: 1280, height: 1280), strategy: strategy), CGSize(width: 960, height: 960))
        strategy.isWeakNetwork = false; strategy.isPassthrough = true
        XCTAssertEqual(self.transcodeService.adjustVideoSize(CGSize(width: 1280, height: 1280), strategy: strategy), CGSize(width: 960, height: 960))
    }

    func testTranscode() {
        let disposeBag = DisposeBag()
        let expectation = LKTestExpectation(description: "@test check can passthrough")
        // 自己搞一个沙盒路径，不然Path().exists会为false
        let tempFileDir = IsoPath.glboalTemporary(in: Domain.biz.messenger) + "test" + "upload"; try? tempFileDir.createDirectoryIfNeeded()
        let tempFilePath = tempFileDir + "temp.mp4"; try? tempFilePath.removeItem()
        try? Resources.mediaData(named: "10-540x960-mp4").write(to: tempFilePath)

        // 开始转码
        self.transcodeService.transcode(key: "transcode_key", form: tempFilePath.absoluteString, to: tempFilePath.absoluteString, strategy: VideoTranscodeStrategy(),
                                        videoSize: CGSize(width: 540, height: 960), extraInfo: [:], progressBlock: nil, dataBlock: nil, retryBlock: nil).do(onDispose: { [weak self] in
            guard let `self` = self else { return }
            XCTAssertFalse(self.transcodeService.isTranscoding())
            expectation.fulfill()
        }).subscribe().disposed(by: disposeBag)
        // 此时在转码中，只有一个转码任务，会立即进入转码状态：但模拟器的transcode是同步完成的，所以上面的call back也会同步执行，此时inTranskdingKey已经被清空了
        XCTAssertFalse(self.transcodeService.isTranscoding())
        expectation.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
        if expectation.autoFulfill { return }
    }

    func testCancelTranscode() {
        let disposeBag = DisposeBag()
        let expectation = LKTestExpectation(description: "@test check can passthrough")
        // 自己搞一个沙盒路径，不然Path().exists会为false
        let tempFileDir = IsoPath.glboalTemporary(in: Domain.biz.messenger) + "test" + "upload"; try? tempFileDir.createDirectoryIfNeeded()
        let tempFilePath = tempFileDir + "temp.mp4"; try? tempFilePath.removeItem()
        try? Resources.mediaData(named: "10-540x960-mp4").write(to: tempFilePath)

        // 开始转码
        self.transcodeService.transcode(key: "transcode_key", form: tempFilePath.absoluteString, to: tempFilePath.absoluteString, strategy: VideoTranscodeStrategy(),
                                        videoSize: CGSize(width: 540, height: 960), extraInfo: [:], progressBlock: nil, dataBlock: nil, retryBlock: nil).do(onDispose: { [weak self] in
            guard let `self` = self else { return }
            XCTAssertFalse(self.transcodeService.isTranscoding())
            expectation.fulfill()
        }).subscribe().disposed(by: disposeBag)
        XCTAssertFalse(self.transcodeService.isTranscoding())
        // 立即取消转码，已经开始VE转码的会调用VE的cancel，VE会立即回调，其他清空不起作用，所以这里不会有任何作用
        self.transcodeService.cancelVideoTranscode(key: "transcode_key")
        expectation.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
        if expectation.autoFulfill { return }
    }
}
