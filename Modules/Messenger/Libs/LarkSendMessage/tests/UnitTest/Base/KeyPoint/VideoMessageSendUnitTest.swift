//
//  VideoMessageSendUnitTest.swift
//  LarkSendMessage-Unit-Tests
//
//  Created by 李勇 on 2023/2/6.
//

import XCTest
import Foundation
import RxSwift // DisposeBag
import LarkContainer // InjectedSafeLazy
@testable import LarkSendMessage

/// VideoMessageSend新增单测
final class VideoMessageSendUnitTest: CanSkipTestCase {
    @InjectedSafeLazy private var videoSendService: VideoMessageSendService

    /// 测试正常发送进度
    func testProgess() {
        let disposeBag = DisposeBag()
        var testProgessCount: Double = 0
        let expectation = LKTestExpectation(description: "@test progess")
        let progessKey = RandomString.random(length: 10)
        self.videoSendService.compressProgessObservable.subscribe { (key, progess) in
            guard key == progessKey else { return }
            testProgessCount += progess
        }.disposed(by: disposeBag)
        self.videoSendService.setCompressProgress(key: progessKey, progress: 1)
        self.videoSendService.setCompressProgress(key: progessKey, progress: 50)
        sleep(3); expectation.fulfill()
        expectation.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
        if expectation.autoFulfill { return }
        XCTAssertEqual(testProgessCount, 51)
    }

    /// 测试进度缓存，compressProgessObservable没有初始值
    func testProgessCache1() {
        let disposeBag = DisposeBag()
        var testProgessCount: Double = 0
        let expectation = LKTestExpectation(description: "@test progess cache")
        let progessKey = RandomString.random(length: 10)
        self.videoSendService.setCompressProgress(key: progessKey, progress: 1)
        self.videoSendService.compressProgessObservable.subscribe { (key, progess) in
            guard key == progessKey else { return }
            testProgessCount += progess
        }.disposed(by: disposeBag)
        self.videoSendService.setCompressProgress(key: progessKey, progress: 50)
        sleep(3); expectation.fulfill()
        expectation.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
        if expectation.autoFulfill { return }
        XCTAssertEqual(testProgessCount, 50)
    }

    /// 测试进度缓存，compressProgessObservable(key: )有初始值
    func testProgessCache2() {
        let disposeBag = DisposeBag()
        var testProgessCount: Double = 0
        let expectation = LKTestExpectation(description: "@test progess cache")
        let progessKey = RandomString.random(length: 10)
        self.videoSendService.setCompressProgress(key: progessKey, progress: 1)
        self.videoSendService.compressProgessObservable(key: progessKey).subscribe { progess in
            testProgessCount += progess
        }.disposed(by: disposeBag)
        self.videoSendService.setCompressProgress(key: progessKey, progress: 50)
        sleep(3); expectation.fulfill()
        expectation.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
        if expectation.autoFulfill { return }
    }

    /// 测试clean进度
    func testProgessClean() {
        let disposeBag = DisposeBag()
        var testProgessCount: Double = 0
        let expectation = LKTestExpectation(description: "@test progess clean")
        let progessKey = RandomString.random(length: 10)
        self.videoSendService.setCompressProgress(key: progessKey, progress: 1)
        // 预期上一行设置的进度1会被clean
        self.videoSendService.cleanCompressProgress(key: progessKey)
        self.videoSendService.compressProgessObservable.subscribe { (key, progess) in
            guard key == progessKey else { return }
            testProgessCount += progess
        }.disposed(by: disposeBag)
        self.videoSendService.setCompressProgress(key: progessKey, progress: 50)
        sleep(3); expectation.fulfill()
        expectation.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
        if expectation.autoFulfill { return }
        XCTAssertEqual(testProgessCount, 50)
    }
}
