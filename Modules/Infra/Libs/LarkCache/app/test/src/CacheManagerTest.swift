//
//  CacheManagerTest.swift
//  LarkCacheDevEEUnitTest
//
//  Created by Supeng on 2020/8/17.
//

import UIKit
import Foundation
import XCTest
@testable import LarkCache

class CacheManagerTest: XCTestCase {

    var cacheManager: CacheManager!
    var testCleanTask: CacheManagerTestCleanTask!

    override func setUp() {
        super.setUp()
        cacheManager = CacheManager.shared
        testCleanTask = CacheManagerTestCleanTask()
        CleanTaskRegistry.allTasks = [CleanTaskRegistry.TaskWrapper(task: { self.testCleanTask })]
        CleanTaskRegistry.register(cleanTask: SimpleCleanTask() )
        UserDefaults.standard.cleanRecord = nil
    }

    override func tearDown() {
        CacheManager.shared = CacheManager()
        cacheManager.removeObserver()
        cacheManager = nil
        testCleanTask = nil
        CleanTaskRegistry.allTasks = [CleanTaskRegistry.TaskWrapper(task: { DefaultCacheCleanTask() })]
        super.tearDown()
    }

    /// 初始化Cache测试，保证CacheConfig一致的情况下，返回的cache是同一个对象
    func testCacheManagerInitializeCacheTest() {
        XCTAssertTrue(cacheManager.cache(biz: Messenger.self, directory: .cache, cleanIdentifier: "")
                      === cacheManager.cache(biz: Messenger.self, directory: .cache))

        XCTAssertTrue(cacheManager.cache(relativePath: Messenger.self.fullPath, directory: .cache)
                      === cacheManager.cache(relativePath: Messenger.self.fullPath, directory: .cache))

        XCTAssertFalse(cacheManager.cache(relativePath: Messenger.self.fullPath, directory: .cache)
                       === cacheManager.cache(relativePath: CCM.self.fullPath, directory: .cache))
    }

    /// 直接调用autoClean方法，在没有进入后台的情况下，没有效果
    func autoCleanWillNotTriggerCleanWhenNotEnterBackground() {
        cacheManager.autoClean(cleanConfig: CleanConfig(cleanInterval: 0))
        let expect = expectation(description: "test")
        expect.isInverted = true
        DispatchQueue.main.async {
            if self.testCleanTask.cleaning || self.testCleanTask.cleanCount > 0 {
                expect.fulfill()
            }
        }
        wait(for: [expect], timeout: 0.5)
    }

    /// 测试正常情况下，调用autoClean，进入后台后，会触发clean方法
    func testAutoCleanWillTirggerCleanTaskCleanMethod() {
        cacheManager.autoClean(cleanConfig: CleanConfig(cleanInterval: 0))
        sendBackgroundNotification(checkExpectAfterDelay: 0.5) { (expect) in
            if self.testCleanTask.cleaning {
                expect.fulfill()
            }
        }
    }

    /// 如果autoCleanEnable为false，则触发进入后台通知也不会清理
    func testAutoCleanWillNotCleanWhenAutoCleanEqualsFalse() {
        cacheManager.autoCleanEnable = false
        cacheManager.autoClean(cleanConfig: CleanConfig(cleanInterval: 0))
        sendBackgroundNotification(checkExpectAfterDelay: 0.5,
                                   expectInverted: true,
                                   handleExpect: { _ in })
    }

    /// 调用多次autoClean以后，再次触发进入后台通知，只会清理一次
    func testMultipleAutoCleanCanOnlyExecuteOnce() {
        let preCleanCount = testCleanTask.cleanCount

        cacheManager.autoClean(cleanConfig: CleanConfig(cleanInterval: 0))
        cacheManager.autoClean(cleanConfig: CleanConfig(cleanInterval: 0))
        cacheManager.autoClean(cleanConfig: CleanConfig(cleanInterval: 0))
        cacheManager.autoClean(cleanConfig: CleanConfig(cleanInterval: 0))
        cacheManager.autoClean(cleanConfig: CleanConfig(cleanInterval: 0))
        cacheManager.autoClean(cleanConfig: CleanConfig(cleanInterval: 0))
        cacheManager.autoClean(cleanConfig: CleanConfig(cleanInterval: 0))
        cacheManager.autoClean(cleanConfig: CleanConfig(cleanInterval: 0))
        cacheManager.autoClean(cleanConfig: CleanConfig(cleanInterval: 0))
        cacheManager.autoClean(cleanConfig: CleanConfig(cleanInterval: 0))
        cacheManager.autoClean(cleanConfig: CleanConfig(cleanInterval: 0))
        cacheManager.autoClean(cleanConfig: CleanConfig(cleanInterval: 0))
        cacheManager.autoClean(cleanConfig: CleanConfig(cleanInterval: 0))

        sendBackgroundNotification(checkExpectAfterDelay: 0.5) { (expect) in
            if self.testCleanTask.cleanCount == preCleanCount + 1 {
                expect.fulfill()
            }
        }
    }

    /// 测试进入后台自动触发的清理任务，再次进入前台，会被cancel
    func testCancelTask() {
        cacheManager.autoClean(cleanConfig: CleanConfig(cleanInterval: 0))

        sendBackgroundNotification(checkExpectAfterDelay: 0.3) { (expect) in
            let beforeCancelCount = self.testCleanTask.cancelCount
            NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                // 验证cancelCount增加1
                if self.testCleanTask.cancelCount == beforeCancelCount + 1 {
                    expect.fulfill()
                }
            }
        }
    }

    /// 测试超时任务
    func testTimeoutTask() {
        let slowTask = CustomCleanTask()
        slowTask.delay = 5
        CleanTaskRegistry.register(cleanTask: slowTask)
        cacheManager.autoClean(cleanConfig: CleanConfig(cleanInterval: 0, taskCostLimit: 1))
        sendBackgroundNotification(checkExpectAfterDelay: 0.1, timeoutInterval: 5) { (expect) in
            let beforeCancelCount = slowTask.cancelCount
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                // 验证cancelCount增加1
                if slowTask.cancelCount == beforeCancelCount + 1 {
                    expect.fulfill()
                }
            }
        }
    }

    /// 测试取消超时任务
    func testCancelTimeoutTask() {
        let slowTask = CustomCleanTask()
        slowTask.delay = 5
        CleanTaskRegistry.register(cleanTask: slowTask)
        cacheManager.autoClean(cleanConfig: CleanConfig(cleanInterval: 0, taskCostLimit: 1))
        sendBackgroundNotification(checkExpectAfterDelay: 0.2, timeoutInterval: 5) { (expect) in
            let beforeCancelCount = slowTask.cancelCount
            NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // 验证cancelCount增加1
                XCTAssert(slowTask.cancelCount == beforeCancelCount + 1)
                // 再次回到后台，等待第一次timeout 时间
                NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    // 验证 cancelCount 没有变化
                    XCTAssert(slowTask.cancelCount == beforeCancelCount + 1)
                    expect.fulfill()
                }
            }
        }
    }

    /// 测试手动清理任务 回调 complete
    func testCleanCache() {
        let expect = expectation(description: "test")
        cacheManager.clean(config: CleanConfig(isUserTriggered: true, cleanInterval: 0)) {
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1)
    }

    /// 测试手动清理任务，进入后台，不会再次触发cleanTask
    func testEnterbackgrounWillNotTriggerCleanWhenUserTriggersCleanTask() {
        cacheManager.clean(config: CleanConfig(isUserTriggered: true, cleanInterval: 0))

        sendBackgroundNotification(checkExpectAfterDelay: 0.3, expectInverted: true) { (expect) in
            let beforeCancelCount = self.testCleanTask.cancelCount
            NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                // 验证cancelCount增加1
                if self.testCleanTask.cancelCount == beforeCancelCount + 1 {
                    expect.fulfill()
                }
            }
        }
    }

    /// 测试获取缓存 size 相关接口
    func testGetTaskCacheSize() {
        let expect1 = expectation(description: "GetTaskSize")
        cacheManager.size(config: CleanConfig()) { (sizes) in
            XCTAssert(self.testCleanTask.sizeCount == 1)
            XCTAssert(sizes.cleanBytes == 200)
            XCTAssert(sizes.cleanCount == 200)
            expect1.fulfill()
        }
        wait(for: [expect1], timeout: 1.5)
    }

    func sendBackgroundNotification(checkExpectAfterDelay: TimeInterval,
                                    expectInverted: Bool = false,
                                    timeoutInterval: TimeInterval = 1.5,
                                    handleExpect: @escaping ((XCTestExpectation) -> Void)) {
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        let expect1 = expectation(description: "CleanTaskBegin")
        expect1.isInverted = expectInverted
        DispatchQueue.main.asyncAfter(deadline: .now() + checkExpectAfterDelay) {
            handleExpect(expect1)
        }
        wait(for: [expect1], timeout: timeoutInterval)
    }

    func sendBackgroundNotification(delay: TimeInterval,
                                    handler: @escaping (() -> Void)) {
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            handler()
        }
    }

    /// 测试清理Cache目录后，yycache可以继续正常工作
    func testCleanCacheDir() throws {
        let cache = cacheManager.cache(biz: Messenger.self, directory: .cache)
        cache.set(object: "123".data(using: .utf8)!, forKey: "tempkey")
        XCTAssertTrue(cache.yyCache?.memoryCache.containsObject(forKey: "tempkey") ?? false)
        XCTAssertTrue(cache.yyCache?.diskCache.containsObject(forKey: "tempkey") ?? false)

        let docPath = CacheDirectory.cache.path
        try "123".write(toFile: docPath + "/tempfile", atomically: true, encoding: .utf8)
        XCTAssertTrue(FileManager.default.fileExists(atPath: docPath + "/tempfile"))

        let cacheDBPath = cache.rootPath + "/CacheDB/manifest.sqlite"
        //测试 DB 文件存在
        XCTAssertTrue(FileManager.default.fileExists(atPath: cacheDBPath, isDirectory: nil))
        // 清除 Cache
        DefaultCacheCleanTask().cleanCachesDirectory()
        cacheManager.cleanAll()

        //确保数据库被清除 且没有被重建
        XCTAssertTrue(!FileManager.default.fileExists(atPath: cacheDBPath, isDirectory: nil))
        //确保cache中文件已经被删除
        XCTAssertFalse(FileManager.default.fileExists(atPath: docPath + "/tempfile"))
        //确保内存缓存被清除
        XCTAssertFalse(cache.yyCache?.memoryCache.containsObject(forKey: "tempkey") ?? false)
        //确保磁盘缓存被清除
        XCTAssertFalse(cache.yyCache?.diskCache.containsObject(forKey: "tempkey") ?? false)
        //确保清理cache目录后，磁盘缓存，内存缓存还可以继续工作
        //对磁盘kv做下重置
        cache.yyCache?.diskCache.reinitialize()
        cache.set(object: "123".data(using: .utf8)!, forKey: "tempkey")
        XCTAssertTrue(cache.yyCache?.memoryCache.containsObject(forKey: "tempkey") ?? false)
        XCTAssertTrue(cache.yyCache?.diskCache.containsObject(forKey: "tempkey") ?? false)
        //确保数据库被重建
        XCTAssertTrue(FileManager.default.fileExists(atPath: cacheDBPath, isDirectory: nil))
    }

    // 测试超出最大 clean 次数
    func testAutoCleanMaxTimes() {
        let task = CustomCleanTask()
        task.delay = 0
        CleanTaskRegistry.register(cleanTask: task)
        cacheManager.autoCleanMaxCount = 3
        cacheManager.autoClean(cleanConfig: CleanConfig(cleanInterval: 0))
        sendBackgroundNotification(checkExpectAfterDelay: 0.1, timeoutInterval: 2) { (expect) in
            XCTAssertEqual(task.cleanCount, 1)
            NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
            self.sendBackgroundNotification(delay: 0.1) {
                XCTAssertEqual(task.cleanCount, 2)
                NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
                self.sendBackgroundNotification(delay: 0.1) {
                    XCTAssertEqual(task.cleanCount, 3)
                    NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
                    self.sendBackgroundNotification(delay: 0.1) {
                        XCTAssertEqual(task.cleanCount, 3)
                        expect.fulfill()
                    }
                }
            }
        }
    }
}

class CacheManagerTestCleanTask: CleanTask {
    var name: String = "aaaaa"

    var cleaning: Bool = false
    var cleanCount: Int = 0
    var cancelCount: Int = 0
    var sizeCount: Int = 0

    /// 0.8s处理完任务，调用completion回调
    /// 如果这期间被cancel，则不会调用completion回调
    func clean(config: CleanConfig, completion: @escaping Completion) {
        cleaning = true
        let breforeCancelCount = cancelCount
        cleanCount += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            guard self.cancelCount == breforeCancelCount else { return }
            self.cleaning = false
            completion(TaskResult(completed: true, costTime: 1, size: .count(0)))
        }
    }

    /// 0.8s处理完任务，调用completion回调
    /// 默认返回 100 bytes 100 count
    func size(config: CleanConfig, completion: @escaping Completion) {
        sizeCount += 1
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.8) {
            completion(TaskResult(completed: true, costTime: 1, sizes: [.bytes(100), .count(100)]))
        }
    }

    func cancel() {
        cancelCount += 1
        cleaning = false
    }
}

struct SimpleCleanTask: CleanTask {
    var name: String { "SimpleCleanTask" }

    func clean(config: CleanConfig, completion: @escaping Completion) {
        completion(TaskResult(completed: true, costTime: 0, sizes: [.bytes(0)]))
    }

    func size(config: CleanConfig, completion: @escaping Completion) {
        completion(TaskResult(completed: true, costTime: 1, sizes: [.bytes(100), .count(100)]))
    }
}

class CustomCleanTask: CleanTask {
    var name: String { "CustomCleanTask" }
    var delay: TimeInterval = 1
    var cancelCount: Int = 0
    var cleaning: Bool = false
    var sizeCount: Int = 0
    var cleanCount: Int = 0

    func clean(config: CleanConfig, completion: @escaping Completion) {
        cleaning = true
        cleanCount += 1
        let breforeCancelCount = cancelCount
        DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
            guard self.cancelCount == breforeCancelCount else { return }
            self.cleaning = false
            completion(TaskResult(completed: true, costTime: 1, sizes: [.bytes(100), .count(100)]))
        }
    }

    func size(config: CleanConfig, completion: @escaping Completion) {
        sizeCount += 1
        DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
            completion(TaskResult(completed: true, costTime: 1, sizes: [.bytes(100), .count(100)]))
        }
    }

    func cancel() {
        cancelCount += 1
        cleaning = false
    }
}
