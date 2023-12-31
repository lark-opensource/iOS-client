//
//  VideoParserUnitTest.swift
//  LarkSendMessage-Unit-Tests
//
//  Created by 李勇 on 2023/1/29.
//

import UIKit
import XCTest
import Foundation
import Photos
import CryptoSwift // md5
import RxSwift // DisposeBag
import LarkFileKit // Path
import LarkAccountInterface // AccountServiceAdapter
import LarkSDKInterface // UserGeneralSettings
import LarkContainer // InjectedLazy
import LarkStorage // IsoPath
@testable import LarkSendMessage

// swiftlint:disable force_try

/// VideoParser新增单测
final class VideoParserUnitTest: CanSkipTestCase {
    @InjectedLazy private var generalSettings: UserGeneralSettings
    @InjectedLazy private var transcodeService: VideoTranscodeService

    /// 测试沙盒路径创建是否成功
    func testCreateVideoSaveURL() {
        XCTAssertFalse(AccountServiceAdapter.shared.currentChatterId.isEmpty)
        let userID = AccountServiceAdapter.shared.currentChatterId
        // 原视频路径
        if let url = VideoParser.createVideoSaveURL(userID: userID, isOriginal: true) {
            XCTAssertTrue(url.absoluteString.contains(VideoParser.originPathSuffix))
            XCTAssertTrue(url.absoluteString.contains(sendVideoCache(userID: userID).rootPath))
            // createVideoSaveURL内部会创建文件所在文件夹，不会创建文件
            XCTAssertFalse(Path(url.absoluteString).exists)
            XCTAssertTrue(Path(sendVideoCache(userID: userID).rootPath).exists)
            // 删除创建的文件夹，不影响后续单测
            try? Path(sendVideoCache(userID: userID).rootPath).deleteFile()
        } else {
            XCTExpectFailure("create origin video save url error")
        }
        if let url = VideoParser.createVideoSaveURL(userID: AccountServiceAdapter.shared.currentChatterId, asset: PHAsset(), isOriginal: true) {
            XCTAssertTrue(url.absoluteString.contains(VideoParser.originPathSuffix))
            XCTAssertTrue(url.absoluteString.contains(sendVideoCache(userID: userID).rootPath))
            // createVideoSaveURL内部会创建文件所在文件夹，不会创建文件
            XCTAssertFalse(Path(url.absoluteString).exists)
            XCTAssertTrue(Path(sendVideoCache(userID: userID).rootPath).exists)
            // 删除创建的文件夹，不影响后续单测
            try? Path(sendVideoCache(userID: userID).rootPath).deleteFile()
        } else {
            XCTExpectFailure("create origin asset video save url error")
        }
        // 非原视频路径
        if let url = VideoParser.createVideoSaveURL(userID: AccountServiceAdapter.shared.currentChatterId, isOriginal: false) {
            XCTAssertFalse(url.absoluteString.contains(VideoParser.originPathSuffix))
            XCTAssertTrue(url.absoluteString.contains(sendVideoCache(userID: userID).rootPath))
            // createVideoSaveURL内部会创建文件所在文件夹，不会创建文件
            XCTAssertFalse(Path(url.absoluteString).exists)
            XCTAssertTrue(Path(sendVideoCache(userID: userID).rootPath).exists)
            // 删除创建的文件夹，不影响后续单测
            try? Path(sendVideoCache(userID: userID).rootPath).deleteFile()
        } else {
            XCTExpectFailure("create video save url error")
        }
        if let url = VideoParser.createVideoSaveURL(userID: AccountServiceAdapter.shared.currentChatterId, asset: PHAsset(), isOriginal: false) {
            XCTAssertFalse(url.absoluteString.contains(VideoParser.originPathSuffix))
            XCTAssertTrue(url.absoluteString.contains(sendVideoCache(userID: userID).rootPath))
            // createVideoSaveURL内部会创建文件所在文件夹，不会创建文件
            XCTAssertFalse(Path(url.absoluteString).exists)
            XCTAssertTrue(Path(sendVideoCache(userID: userID).rootPath).exists)
            // 删除创建的文件夹，不影响后续单测
            try? Path(sendVideoCache(userID: userID).rootPath).deleteFile()
        } else {
            XCTExpectFailure("create asset video save url error")
        }
    }

    /// 测试通过PHAsset获取ResourceID等信息，PHAsset是相册选取的不好Mock，所以这里就测试空值是否符合预期
    func testPHAssetInfo() {
        XCTAssertNil(VideoParser.videoAssetResources(for: PHAsset()))
        XCTAssertFalse(PHAsset().localIdentifier.md5().isEmpty)
        XCTAssertFalse(VideoParser.phassetResourceID(asset: PHAsset()).isEmpty)
        XCTAssertTrue(VideoParser.videoLocallyAvailable(for: PHAsset()))
        let videoParser = try! VideoParser(
            userResolver: Container.shared.getCurrentUserResolver(),
            transcodeService: self.transcodeService,
            isOriginal: true, type: .normal,
            videoSendSetting: self.generalSettings.videoSynthesisSetting.value.sendSetting)
        XCTAssertFalse(videoParser.name(for: PHAsset()).isEmpty)
    }

    /// 测试获取首帧相关接口
    func testFirstFrame() {
        if !self.generalSettings.videoSynthesisSetting.value.coverSetting.limitEnable { return }

        let videoParser = try! VideoParser(userResolver: Container.shared.getCurrentUserResolver(),
                                      transcodeService: self.transcodeService,
                                      isOriginal: true,
                                      type: .normal,
                                      videoSendSetting: self.generalSettings.videoSynthesisSetting.value.sendSetting)
        // 测试首帧大小获取，目前限制为640 x 640
        XCTAssertEqual(videoParser.getFirstFrameSize(originSize: CGSize(width: 1200, height: 1200)), CGSize(width: 640, height: 640))
        // 测试UIImage -> NSData
        XCTAssertNotNil(videoParser.getFirstFrameImageData(image: Resources.image(named: "1200x1400-JPEG")))
        // 测试从VE获取首帧图，size会变小；目前模拟器会稳定失败
        /* let tempFileDir = IsoPath.glboalTemporary(in: Domain.biz.messenger) + "test" + "upload"; try? tempFileDir.createDirectoryIfNeeded()
         let tempFilePath = tempFileDir + "temp.mp4"; try? tempFilePath.removeItem(); try? Resources.mediaData(named: "10-540x960-mp4").write(to: tempFilePath)
         var result: (UIImage, Data?)? = videoParser.getFirstFrameByTTVideoEditor(exportPath: tempFilePath.absoluteString, size: CGSize(width: 1080, height: 1920))
         XCTAssertNotNil(result); XCTAssertNotNil(result?.1)
         XCTAssertEqual(result?.0.size, CGSize(width: 360, height: 640)) */
        // 测试从系统获取首帧图，size会变小
        let result: (UIImage, Data?)? = try? videoParser.firstFrame(with: AVURLAsset(url: Resources.mediaUrl(named: "20-1080x1920-mov")), size: CGSize(width: 1080, height: 1920))
        XCTAssertNotNil(result); XCTAssertNotNil(result?.1)
        XCTAssertEqual(result?.0.size, CGSize(width: 360, height: 640))
    }

    /// 测试baseVideoInfo中相关逻辑
    func testBaseVideoInfo() {
        let videoParser = try! VideoParser(userResolver: Container.shared.getCurrentUserResolver(),
                                      transcodeService: self.transcodeService,
                                      isOriginal: true,
                                      type: .normal,
                                      videoSendSetting: self.generalSettings.videoSynthesisSetting.value.sendSetting)
        // 测试文件大小获取
        XCTAssertTrue(videoParser.checkFileExistsAndGetFileSize(at: Resources.mediaUrl(named: "10-540x960-mp4")) ?? 0 > 0)
        // 测试分辨率获取
        let avasset = AVURLAsset(url: Resources.mediaUrl(named: "10-540x960-mp4"))
        XCTAssertEqual(VideoParser.naturalSize(with: avasset), CGSize(width: 540, height: 960))
        // 测试低端机分辨率处理
        XCTAssertEqual(videoParser.calculateSize(originSize: CGSize(width: 300, height: 300), maxSize: CGSize(width: 400, height: 400)), CGSize(width: 300, height: 300))
        XCTAssertEqual(videoParser.calculateSize(originSize: CGSize(width: 600, height: 600), maxSize: CGSize(width: 400, height: 400)), CGSize(width: 400, height: 400))
    }

    /// 测试VideoParser+URL->judgeInfo对于发送限制的判断
    func testJudgeInfoForUrl() {
        let disposeBag = DisposeBag()
        let expectation = LKTestExpectation(description: "@test judge info")
        expectation.expectedFulfillmentCount = 4
        // 用信号量把后续测试变成串行
        let semaphore = DispatchSemaphore(value: 0)
        // 自己搞一个临时路径
        let tempFileDir = IsoPath.glboalTemporary(in: Domain.biz.messenger) + "test" + "upload"; try? tempFileDir.createDirectoryIfNeeded()
        let tempFilePath = tempFileDir + "temp.mp4"; try? tempFilePath.removeItem()
        let videoParser = try! VideoParser(userResolver: Container.shared.getCurrentUserResolver(),
                                      transcodeService: self.transcodeService,
                                      isOriginal: true,
                                      type: .normal,
                                      videoSendSetting: self.generalSettings.videoSynthesisSetting.value.sendSetting)
        let parseInfo = VideoParseInfo()
        parseInfo.exportPath = VideoParser.createVideoSaveURL(userID: AccountServiceAdapter.shared.currentChatterId, isOriginal: true)?.absoluteString ?? ""
        // 测试文件超出限制
        try? Resources.mediaData(named: "10-540x960-mp4").write(to: tempFilePath)
        parseInfo.filesize = videoParser.fileMaxSize + 1
        videoParser.judgeInfo(info: parseInfo, url: tempFilePath.url).subscribe { _ in
            XCTExpectFailure("need file reach max error")
            expectation.fulfill(); semaphore.signal()
        } onError: { error in
            if case VideoParseError.fileReachMax = error {} else { XCTExpectFailure("need file reach max error") }
            expectation.fulfill(); semaphore.signal()
        }.disposed(by: disposeBag)
        // 测试大小超出限制，转附件，每次都要往tempFilePath写文件&&删除exportPath文件，因为judgeInfo内部会从tempFilePath位置move文件到exportPath
        semaphore.wait(); try? Resources.mediaData(named: "10-540x960-mp4").write(to: tempFilePath); try? Path(parseInfo.exportPath).deleteFile()
        parseInfo.filesize = 5 * 1024 * 1024 * 1024 + 1
        videoParser.judgeInfo(info: parseInfo, url: tempFilePath.url).subscribe { info in
            XCTAssertEqual(info.status, .reachMaxSize)
            expectation.fulfill(); semaphore.signal()
        } onError: { error in
            XCTExpectFailure("should no error \(error)")
            expectation.fulfill(); semaphore.signal()
        }.disposed(by: disposeBag)
        // 测试时长超出限制，转附件
        semaphore.wait(); try? Resources.mediaData(named: "10-540x960-mp4").write(to: tempFilePath); try? Path(parseInfo.exportPath).deleteFile()
        parseInfo.filesize = 10 * 1024; parseInfo.duration = self.generalSettings.videoSynthesisSetting.value.sendSetting.duration + 1
        videoParser.judgeInfo(info: parseInfo, url: tempFilePath.url).subscribe { info in
            XCTAssertEqual(info.status, .reachMaxDuration)
            expectation.fulfill(); semaphore.signal()
        } onError: { error in
            XCTExpectFailure("should no error \(error)")
            expectation.fulfill(); semaphore.signal()
        }.disposed(by: disposeBag)
        // "分辨率、帧率、码率超出限制，转附件"不好测试，需要准备很多视频，这里就不加单测了
        // xxx
        // 测试正常情况
        semaphore.wait(); try? Resources.mediaData(named: "10-540x960-mp4").write(to: tempFilePath); try? Path(parseInfo.exportPath).deleteFile()
        parseInfo.duration = 10
        videoParser.judgeInfo(info: parseInfo, url: tempFilePath.url).subscribe { info in
            XCTAssertEqual(info.status, .fillBaseInfo)
            expectation.fulfill(); semaphore.signal()
        } onError: { error in
            XCTExpectFailure("should no error \(error)")
            expectation.fulfill(); semaphore.signal()
        }.disposed(by: disposeBag)
        try? Path(parseInfo.exportPath).deleteFile()
        expectation.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
        if expectation.autoFulfill { return }
    }

    /// 测试VideoParser+PHAsset->judgeInfo对于发送限制的判断，PHAsset为相册获取的，目前只能测试默认情况
    func testJudgeInfoForAsset() {
        let disposeBag = DisposeBag()
        let expectation = LKTestExpectation(description: "@test judge info")
        expectation.expectedFulfillmentCount = 5
        let videoParser = try! VideoParser(userResolver: Container.shared.getCurrentUserResolver(),
                                      transcodeService: self.transcodeService,
                                      isOriginal: true,
                                      type: .normal,
                                      videoSendSetting: self.generalSettings.videoSynthesisSetting.value.sendSetting)
        let avAsset = AVURLAsset(url: Resources.mediaUrl(named: "10-540x960-mp4"))
        let parseInfo = VideoParseInfo()
        // 测试文件超出限制
        parseInfo.filesize = videoParser.fileMaxSize + 1
        videoParser.judgeInfo(info: parseInfo, avAsset: avAsset).subscribe { _ in
            XCTExpectFailure("need file reach max error")
            expectation.fulfill()
        } onError: { error in
            if case VideoParseError.fileReachMax = error {} else { XCTExpectFailure("need file reach max error") }
            expectation.fulfill()
        }.disposed(by: disposeBag)
        // 测试不存在视频轨
        parseInfo.filesize = 10 * 1024
        videoParser.judgeInfo(info: parseInfo, avAsset: AVURLAsset(url: URL(string: "www.baidu.com") ?? URL(fileURLWithPath: ""))).subscribe { (info, _) in
            XCTAssertEqual(info.status, .videoTrackEmpty)
            expectation.fulfill()
        } onError: { _ in
            XCTExpectFailure("should no error")
            expectation.fulfill()
        }.disposed(by: disposeBag)
        // 测试大小超出限制，转附件
        parseInfo.filesize = 5 * 1024 * 1024 * 1024 + 1
        videoParser.judgeInfo(info: parseInfo, avAsset: AVURLAsset(url: Resources.mediaUrl(named: "10-540x960-mp4"))).subscribe { (info, _) in
            XCTAssertEqual(info.status, .reachMaxSize)
            expectation.fulfill()
        } onError: { _ in
            XCTExpectFailure("should no error")
            expectation.fulfill()
        }.disposed(by: disposeBag)
        // 测试时长超出限制，转附件
        parseInfo.filesize = 10 * 1024; parseInfo.duration = self.generalSettings.videoSynthesisSetting.value.sendSetting.duration + 1
        videoParser.judgeInfo(info: parseInfo, avAsset: AVURLAsset(url: Resources.mediaUrl(named: "10-540x960-mp4"))).subscribe { (info, _) in
            XCTAssertEqual(info.status, .reachMaxDuration)
            expectation.fulfill()
        } onError: { _ in
            XCTExpectFailure("should no error")
            expectation.fulfill()
        }.disposed(by: disposeBag)
        // "分辨率、帧率、码率超出限制，转附件"不好测试，需要准备很多视频，这里就不加单测了
        // xxx
        // 测试正常情况
        parseInfo.duration = 10
        videoParser.judgeInfo(info: parseInfo, avAsset: AVURLAsset(url: Resources.mediaUrl(named: "10-540x960-mp4"))).subscribe { (info, _) in
            XCTAssertEqual(info.status, .fillBaseInfo)
            expectation.fulfill()
        } onError: { _ in
            XCTExpectFailure("should no error")
            expectation.fulfill()
        }.disposed(by: disposeBag)
        expectation.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
        if expectation.autoFulfill { return }
    }
}
// swiftlint:enable force_try
