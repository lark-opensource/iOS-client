//
//  ProgressServiceUnitTest.swift
//  LarkSendMessage-Unit-Tests
//
//  Created by 李勇 on 2023/1/18.
//

import XCTest
import Foundation
import UIKit
import RxSwift // DisposeBag
import LarkContainer // InjectedSafeLazy
@testable import LarkSendMessage

/// ProgressService新增单测
final class ProgressServiceUnitTest: CanSkipTestCase {
    @InjectedSafeLazy private var progressService: ProgressService
    private let progressTestKey = "progress_test_key"

    /// 测试进度是否正常回调
    func testProgress() {
        let disposeBag = DisposeBag()
        // 监听进度值
        var progressValue: Int64 = 0; var progressValueCount: Int64 = 0
        self.progressService.value.subscribe { [weak self] progress in
            guard let `self` = self else { return }
            // 如果出现了其他的key，直接报错
            if progress.0 != self.progressTestKey {
                XCTExpectFailure()
                return
            }
            progressValueCount += 1
            progressValue += progress.1.completedUnitCount
        }.disposed(by: disposeBag)
        var progressKeyValue: Int64 = 0; var progressKeyCount: Int64 = 0
        self.progressService.value(key: self.progressTestKey).subscribe { progress in
            progressKeyCount += 1
            progressKeyValue += progress.completedUnitCount
        }.disposed(by: disposeBag)

        // Mock进度，sleep(2)：信号异步发送
        let oneProgress = Progress(); oneProgress.completedUnitCount = 1
        self.progressService.update(key: self.progressTestKey, progress: oneProgress, rate: nil); sleep(2)
        guard let progress = self.progressService.getProgressValue(key: self.progressTestKey) else {
            XCTExpectFailure()
            return
        }
        XCTAssertEqual(progress.completedUnitCount, 1)
        let twoProgress = Progress(); twoProgress.completedUnitCount = 100
        self.progressService.dealUploadFileInfo(PushUploadFile(localKey: self.progressTestKey, key: "", progress: twoProgress, state: .uploading, type: .message, rate: 0)); sleep(2)
        guard let progress = self.progressService.getProgressValue(key: self.progressTestKey) else {
            XCTExpectFailure()
            return
        }
        XCTAssertEqual(progress.completedUnitCount, 100)

        // 对监听到的进度值断言
        XCTAssertEqual(progressValue, 101)
        XCTAssertEqual(progressValueCount, 2)
        XCTAssertEqual(progressKeyValue, 101)
        XCTAssertEqual(progressKeyCount, 2)
    }

    /// 测试速率是否正常回调
    func testRate() {
        let disposeBag = DisposeBag()
        // 监听速率值
        var rateValue: Int64 = 0; var rateValueCount: Int64 = 0
        self.progressService.rateValue.subscribe { [weak self] progress in
            guard let `self` = self else { return }
            // 如果出现了其他的key，直接报错
            if progress.0 != self.progressTestKey {
                XCTExpectFailure()
                return
            }
            rateValueCount += 1
            rateValue += progress.1
        }.disposed(by: disposeBag)
        var rateKeyValue: Int64 = 0; var rateKeyCount: Int64 = 0
        self.progressService.rateValue(key: self.progressTestKey).subscribe { progress in
            rateKeyCount += 1
            rateKeyValue += progress
        }.disposed(by: disposeBag)

        // Mock速率，sleep(2)：信号异步发送
        self.progressService.update(key: self.progressTestKey, progress: Progress(), rate: 1)
        self.progressService.dealUploadFileInfo(PushUploadFile(localKey: self.progressTestKey, key: "", progress: Progress(), state: .uploading, type: .message, rate: 100)); sleep(2)

        // 对监听到的进度值断言
        XCTAssertEqual(rateValue, 101)
        XCTAssertEqual(rateValueCount, 2)
        XCTAssertEqual(rateKeyValue, 101)
        XCTAssertEqual(rateKeyCount, 2)
    }

    /// 测试完成是否正常回调
    func testFinish() {
        let disposeBag = DisposeBag()
        var finishValueCount: Int64 = 0
        // 监听finish
        let expectation = LKTestExpectation(description: "@test finish")
        expectation.expectedFulfillmentCount = 2
        self.progressService.finish.subscribe { [weak self] progress in
            guard let `self` = self else { return }
            // 如果出现了其他的key，直接报错
            if progress.localKey != self.progressTestKey {
                XCTExpectFailure()
                return
            }
            finishValueCount += 1
            expectation.fulfill()
        }.disposed(by: disposeBag)
        self.progressService.finish(key: self.progressTestKey).subscribe { _ in
            finishValueCount += 1
            expectation.fulfill()
        }.disposed(by: disposeBag)

        self.progressService.dealUploadFileInfo(PushUploadFile(localKey: self.progressTestKey, key: "", progress: Progress(), state: .uploadSuccess, type: .message, rate: 0))
        expectation.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
        if expectation.autoFulfill { return }
        XCTAssertEqual(finishValueCount, 2)
    }

    /// 测试caches是否正常生效，主要是测试监听进度时是否有初始值
    func testCaches() {
        let disposeBag = DisposeBag()
        // Mock进度初始值，需要等一会儿，信号发送是异步的
        let oneProgress = Progress(); oneProgress.completedUnitCount = 50
        self.progressService.update(key: self.progressTestKey, progress: oneProgress, rate: nil); sleep(2)

        // 监听进度值，value没有初始值
        self.progressService.value.subscribe { [weak self] progress in
            guard let `self` = self else { return }
            // 如果出现了其他的key，直接报错
            if progress.0 != self.progressTestKey {
                XCTExpectFailure()
                return
            }
            // 有值输出也直接报错，预期value没有初始值
            XCTExpectFailure()
        }.disposed(by: disposeBag)

        // valueKey有初始值
        let expectation = LKTestExpectation(description: "@test caches")
        expectation.expectedFulfillmentCount = 1
        var progressKeyValue: Int64 = 0; var progressKeyCount: Int64 = 0
        self.progressService.value(key: self.progressTestKey).subscribe { progress in
            progressKeyCount += 1
            progressKeyValue += progress.completedUnitCount
            expectation.fulfill()
        }.disposed(by: disposeBag)
        expectation.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
        if expectation.autoFulfill { return }
        XCTAssertEqual(progressKeyValue, 50)
        XCTAssertEqual(progressKeyCount, 1)
    }
}
