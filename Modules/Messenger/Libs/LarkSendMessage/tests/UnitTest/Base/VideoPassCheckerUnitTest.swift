//
//  VideoPassCheckerUnitTest.swift
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
import LarkFoundation // Utils
@testable import LarkSendMessage

/// VideoPassChecker新增单测，VideoPassChecker下线了，暂时不需要跑单测了
/* final class VideoPassCheckerUnitTest: CanSkipTestCase {
    @InjectedLazy private var generalSettings: UserGeneralSettings

    /// 测试checkVideoCanPassthrough、videoCanPassthrough
    func testCanPassthrough() {
        let expectation = LKTestExpectation(description: "@test check can passthrough")
        // CPU限制时，不进行检查，此时VideoPassChecker内部逻辑不会执行
        let rawConfig = self.generalSettings.videoSynthesisSetting.value.newCompressSetting.videoRawConfig
        let averageCPUUsage = (try? Utils.averageCPUUsage) ?? 100
        guard rawConfig.limitCpuUsaged > averageCPUUsage, rawConfig.enable else {
            expectation.fulfill()
            return
        }

        // 自己搞一个沙盒路径，不然Path().exists会为false
        let tempFileDir = IsoPath.glboalTemporary(in: Domain.biz.messenger) + "test" + "upload"; try? tempFileDir.createDirectoryIfNeeded()
        let tempFilePath = tempFileDir + "temp.mp4"; try? tempFilePath.removeItem()
        try? Resources.mediaData(named: "10-540x960-mp4").write(to: tempFilePath)

        let videoInfo = VideoParseInfo()
        videoInfo.compressPath = VideoParser.createVideoSaveURL(userID: AccountServiceAdapter.shared.currentChatterId, isOriginal: true)!.absoluteString
        videoInfo.exportPath = tempFilePath.absoluteString; videoInfo.filesize = 10 * 1024
        let checker = VideoPassChecker(); checker.checkVideoCanPassthrough(videoInfo: videoInfo) {
            // 稳定检查失败，只有checkFileInfo能过
            XCTAssertEqual(checker.videoCanPassthrough(videoInfo: videoInfo, isOriginal: true), false)
            XCTAssertEqual(checker.videoCanPassthrough(videoInfo: videoInfo, isOriginal: false), false)
            // 先执行的block，再清理的currrentTask
            XCTAssertNotNil(checker.currrentTask.value)
            DispatchQueue.main.async { XCTAssertNil(checker.currrentTask.value) }
            // 此时会缓存结果
            XCTAssertTrue(checker.cache.containsObject(forKey: VideoPassChecker.cacheKey(info: videoInfo)))
            // 清除缓存，避免影响其他case运行
            checker.cache.removeAllObjects(); sleep(2)
            XCTAssertFalse(checker.cache.containsObject(forKey: VideoPassChecker.cacheKey(info: videoInfo)))
            expectation.fulfill()
        }
        // 立马会开始执行任务，因为此时只有一个任务：因为checkFileInfo同步完成，上面的call back也会同步执行，此时currrentTask已经被清空了
        XCTAssertNil(checker.currrentTask.value)
        XCTAssertTrue(checker.tasks.isEmpty)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
    }

    /// 测试cancelAllTasks
    func testCancelAllTrask() {
        let expectation = LKTestExpectation(description: "@test check can passthrough")
        // CPU限制时，不进行检查，此时VideoPassChecker内部逻辑不会执行
        let rawConfig = self.generalSettings.videoSynthesisSetting.value.newCompressSetting.videoRawConfig
        let averageCPUUsage = (try? Utils.averageCPUUsage) ?? 100
        guard rawConfig.limitCpuUsaged > averageCPUUsage, rawConfig.enable else {
            expectation.fulfill()
            return
        }

        // 自己搞一个沙盒路径，不然Path().exists会为false
        let tempFileDir = IsoPath.glboalTemporary(in: Domain.biz.messenger) + "test" + "upload"; try? tempFileDir.createDirectoryIfNeeded()
        let tempFilePath = tempFileDir + "temp.mp4"; try? tempFilePath.removeItem()
        try? Resources.mediaData(named: "10-540x960-mp4").write(to: tempFilePath)

        let videoInfo = VideoParseInfo()
        videoInfo.compressPath = VideoParser.createVideoSaveURL(userID: AccountServiceAdapter.shared.currentChatterId, isOriginal: true)!.absoluteString
        videoInfo.exportPath = tempFilePath.absoluteString; videoInfo.filesize = 10 * 1024
        let checker = VideoPassChecker(); checker.checkVideoCanPassthrough(videoInfo: videoInfo) {
            // 稳定检查失败，只有checkFileInfo能过
            XCTAssertEqual(checker.videoCanPassthrough(videoInfo: videoInfo, isOriginal: true), false)
            XCTAssertEqual(checker.videoCanPassthrough(videoInfo: videoInfo, isOriginal: false), false)
            // 先执行的block，再清理的currrentTask
            XCTAssertNotNil(checker.currrentTask.value)
            DispatchQueue.main.async { XCTAssertNil(checker.currrentTask.value) }
            // 此时会缓存结果
            XCTAssertTrue(checker.cache.containsObject(forKey: VideoPassChecker.cacheKey(info: videoInfo)))
            // 清除缓存，避免影响其他case运行
            checker.cache.removeAllObjects(); sleep(2)
            XCTAssertFalse(checker.cache.containsObject(forKey: VideoPassChecker.cacheKey(info: videoInfo)))
            expectation.fulfill()
        }
        // 立马会开始执行任务，因为此时只有一个任务：因为checkFileInfo同步完成，上面的call back也会同步执行，此时currrentTask已经被清空了
        XCTAssertNil(checker.currrentTask.value)
        XCTAssertTrue(checker.tasks.isEmpty)

        // cancle会删除tasks、currrentTask：但因为checkFileInfo同步完成，所以cancel不起作用，和testCanPassthrough结果一致
        checker.cancelAllTasks()
        XCTAssertNil(checker.currrentTask.value)
        XCTAssertTrue(checker.tasks.isEmpty)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
    }

    /// 测试cacheKey方法
    func testCacheKey() {
        let videoInfo = VideoParseInfo()
        videoInfo.assetUUID = "assetUUID"
        // 优先assetUUID
        XCTAssertEqual(VideoPassChecker.cacheKey(info: videoInfo), "assetUUID")
        // 其次exportPath
        videoInfo.assetUUID = ""; videoInfo.exportPath = "exportPath"
        XCTAssertEqual(VideoPassChecker.cacheKey(info: videoInfo), "exportPath".md5())
    }

    /// 测试VideoPassCheckerTask-checkFileInfo逻辑
    func testCheckFileInfo() {
        let disposeBag = DisposeBag()
        let expectation = LKTestExpectation(description: "@test check file info")
        expectation.expectedFulfillmentCount = 4
        // 自己搞一个沙盒路径，不然Path().exists会为false
        let tempFileDir = IsoPath.glboalTemporary(in: Domain.biz.messenger) + "test" + "upload"; try? tempFileDir.createDirectoryIfNeeded()
        let tempFilePath = tempFileDir + "temp.mp4"; try? tempFilePath.removeItem()
        try? Resources.mediaData(named: "10-540x960-mp4").write(to: tempFilePath)
        // 用信号量把后续测试变成串行
        let semaphore = DispatchSemaphore(value: 0)
        let videoInfo = VideoParseInfo()
        let videoPassCheckerTask = VideoPassCheckerTask(userResolver: Container.shared.getCurrentUserResolver(), videoInfo: videoInfo, userGeneralSettings: self.generalSettings)
        // 已存在转码结果
        videoInfo.compressPath = tempFilePath.absoluteString
        videoPassCheckerTask.checkFileInfo(result: VideoPassCheckerResult()).subscribe { result in
            if case .failed(let enable) = result.enable, case .failed(let originEnable) = result.originEnable {
                XCTAssertEqual(enable, VideoPassError.noNeedPassthrough)
                XCTAssertEqual(originEnable, VideoPassError.noNeedPassthrough)
            } else {
                XCTExpectFailure("should no need passthrough error")
            }
            semaphore.signal(); expectation.fulfill()
        } onError: { error in
            XCTExpectFailure("should no error \(error)")
            semaphore.signal(); expectation.fulfill()
        }.disposed(by: disposeBag)
        // 文件不存在
        semaphore.wait(); videoInfo.compressPath = VideoParser.createVideoSaveURL(userID: AccountServiceAdapter.shared.currentChatterId, isOriginal: true)!.absoluteString
        videoPassCheckerTask.checkFileInfo(result: VideoPassCheckerResult()).subscribe { result in
            if case .failed(let enable) = result.enable, case .failed(let originEnable) = result.originEnable {
                XCTAssertEqual(enable, VideoPassError.videoParseInfoError)
                XCTAssertEqual(originEnable, VideoPassError.videoParseInfoError)
            } else {
                XCTExpectFailure("should video parse info error")
            }
            semaphore.signal(); expectation.fulfill()
        } onError: { error in
            XCTExpectFailure("should no error \(error)")
            semaphore.signal(); expectation.fulfill()
        }.disposed(by: disposeBag)
        // 文件大小过大
        semaphore.wait(); videoInfo.exportPath = tempFilePath.absoluteString; videoInfo.filesize = UInt64.max
        videoPassCheckerTask.checkFileInfo(result: VideoPassCheckerResult()).subscribe { result in
            if case .failed(let enable) = result.enable, case .failed(let originEnable) = result.originEnable {
                XCTAssertEqual(enable, VideoPassError.fileSizeLimit(0))
                XCTAssertEqual(originEnable, VideoPassError.fileSizeLimit(0))
            } else {
                XCTExpectFailure("should file size limit error")
            }
            semaphore.signal(); expectation.fulfill()
        } onError: { error in
            XCTExpectFailure("should no error \(error)")
            semaphore.signal(); expectation.fulfill()
        }.disposed(by: disposeBag)
        // 分辨率、码率、HDR、H264，需要准备对应视频，这里就不写单测了
        // 正常视频
        semaphore.wait(); videoInfo.filesize = 10 * 1024
        videoPassCheckerTask.checkFileInfo(result: VideoPassCheckerResult()).subscribe { result in
            if case .failed(_) = result.enable, case .failed(_) = result.originEnable { XCTExpectFailure("should no error") }
            semaphore.signal(); expectation.fulfill()
        } onError: { error in
            XCTExpectFailure("should no error \(error)")
            semaphore.signal(); expectation.fulfill()
        }.disposed(by: disposeBag)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
    }

    /// 测试VideoPassCheckerTask-checkVideoRemuxEnable逻辑，模拟器上VECompileTaskManagerSession.isPreUploadable永远为fasle
    /* func testCheckVideoRemuxEnable() {
     let disposeBag = DisposeBag()
     let expectation = LKTestExpectation(description: "@test check video remux enable")
     expectation.expectedFulfillmentCount = 2
     // 自己搞一个沙盒路径，不然Path().exists会为false
     let tempFileDir = IsoPath.glboalTemporary(in: Domain.biz.messenger) + "test" + "upload"; try? tempFileDir.createDirectoryIfNeeded()
     let tempFilePath = tempFileDir + "temp.mp4"; try? tempFilePath.removeItem()
     try? Resources.mediaData(named: "20-1080x1920-mov").write(to: tempFilePath)
     // 用信号量把后续测试变成串行
     let semaphore = DispatchSemaphore(value: 0)
     let videoInfo = VideoParseInfo()
     videoInfo.exportPath = tempFilePath.absoluteString
     let videoPassCheckerTask = VideoPassCheckerTask(userResolver: Container.shared.getCurrentUserResolver(), videoInfo: videoInfo, userGeneralSettings: self.generalSettings)
     // mov预期不能通过
     videoPassCheckerTask.checkVideoRemuxEnable(result: VideoPassCheckerResult()).subscribe { result in
     if case .failed(let enable) = result.enable, case .failed(let originEnable) = result.originEnable {
     XCTAssertEqual(enable, VideoPassError.remuxLimit)
     XCTAssertEqual(originEnable, VideoPassError.remuxLimit)
     } else {
     XCTExpectFailure("should remux limit")
     }
     semaphore.signal(); expectation.fulfill()
     } onError: { error in
     XCTExpectFailure("should no error \(error)")
     semaphore.signal(); expectation.fulfill()
     }.disposed(by: disposeBag)
     // mp4预期能通过，模拟器上VECompileTaskManagerSession.isPreUploadable永远为fasle
     semaphore.wait(); try? Path(tempFilePath.absoluteString).deleteFile(); try? Resources.mediaData(named: "10-540x960-mp4").write(to: tempFilePath)
     videoPassCheckerTask.checkVideoRemuxEnable(result: VideoPassCheckerResult()).subscribe { result in
     if case .failed(_) = result.enable, case .failed(_) = result.originEnable { XCTExpectFailure("should no error") }
     semaphore.signal(); expectation.fulfill()
     } onError: { error in
     XCTExpectFailure("should no error \(error)")
     semaphore.signal(); expectation.fulfill()
     }.disposed(by: disposeBag)
     wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
     } */

    /// 测试VideoPassCheckerTask-checkVideoInterleaveEnable逻辑，VEVideoInterleaveChecker在模拟器不生效
    /* func testCheckVideoInterleaveEnable() {
     let disposeBag = DisposeBag()
     let expectation = LKTestExpectation(description: "@test check video interleave enable")
     expectation.expectedFulfillmentCount = 2
     // 自己搞一个沙盒路径，不然Path().exists会为false
     let tempFileDir = IsoPath.glboalTemporary(in: Domain.biz.messenger) + "test" + "upload"; try? tempFileDir.createDirectoryIfNeeded()
     let tempFilePath = tempFileDir + "temp.mp4"; try? tempFilePath.removeItem()
     try? Resources.mediaData(named: "66-1280x590-mp4").write(to: tempFilePath)
     // 用信号量把后续测试变成串行
     let semaphore = DispatchSemaphore(value: 0)
     let videoInfo = VideoParseInfo()
     videoInfo.exportPath = tempFilePath.absoluteString
     var videoPassCheckerTask = VideoPassCheckerTask(userResolver: Container.shared.getCurrentUserResolver(), videoInfo: videoInfo, userGeneralSettings: self.generalSettings)
     // 预期有音视频交织
     videoPassCheckerTask.checkVideoInterleaveEnable(result: VideoPassCheckerResult()).subscribe { result in
     if case .failed(let enable) = result.enable, case .failed(let originEnable) = result.originEnable {
     XCTAssertEqual(enable, VideoPassError.interleaveLimit(0))
     XCTAssertEqual(originEnable, VideoPassError.interleaveLimit(0))
     } else {
     XCTExpectFailure("should remux linterleave limitimit")
     }
     semaphore.signal(); expectation.fulfill()
     } onError: { error in
     XCTExpectFailure("should no error \(error)")
     semaphore.signal(); expectation.fulfill()
     }.disposed(by: disposeBag)
     // 预期没有音视频交织
     semaphore.wait(); try? Path(tempFilePath.absoluteString).deleteFile(); try? Resources.mediaData(named: "10-540x960-mp4").write(to: tempFilePath)
     videoPassCheckerTask = VideoPassCheckerTask(userResolver: Container.shared.getCurrentUserResolver(), videoInfo: videoInfo, userGeneralSettings: self.generalSettings)
     videoPassCheckerTask.checkVideoInterleaveEnable(result: VideoPassCheckerResult()).subscribe { result in
     if case .failed(_) = result.enable, case .failed(_) = result.originEnable { XCTExpectFailure("should no error") }
     semaphore.signal(); expectation.fulfill()
     } onError: { error in
     XCTExpectFailure("should no error \(error)")
     semaphore.signal(); expectation.fulfill()
     }.disposed(by: disposeBag)
     wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
     } */
} */
