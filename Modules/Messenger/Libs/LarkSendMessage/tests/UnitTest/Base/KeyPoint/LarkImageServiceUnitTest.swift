//
//  LarkImageServiceUnitTest.swift
//  LarkSendMessage-Unit-Tests
//
//  Created by 李勇 on 2023/1/18.
//

import XCTest
import Foundation
import ByteWebImage // LarkImageService

/// LarkImageService新增单测：只新增缓存读取部分，从SDK获取数据不在发消息范畴
final class LarkImageServiceUnitTest: CanSkipTestCase {
    /// LarkImageService.shared.removeCache是异步的，需要等待一段时间
    private let removeCacheWaitTime: UInt32 = 5

    /// 测试originCache
    func testOriginCache() {
        let defaultResource: LarkImageResource = .default(key: "default")
        // 初始时，内存+磁盘缓存没有内容
        XCTAssertNil(LarkImageService.shared.image(with: defaultResource, cacheOptions: .memory))
        XCTAssertFalse(LarkImageService.shared.isCached(resource: defaultResource, options: .memory))
        XCTAssertNil(LarkImageService.shared.image(with: defaultResource, cacheOptions: .disk))
        XCTAssertFalse(LarkImageService.shared.isCached(resource: defaultResource, options: .disk))

        // 设置内存缓存，此时内存缓存中有内容
        LarkImageService.shared.cacheImage(image: Resources.image(named: "1200x1400-JPEG"), resource: defaultResource, cacheOptions: .memory)
        XCTAssertNotNil(LarkImageService.shared.image(with: defaultResource, cacheOptions: .memory))
        XCTAssertTrue(LarkImageService.shared.isCached(resource: defaultResource, options: .memory))
        // 磁盘缓存依然没有内容
        XCTAssertNil(LarkImageService.shared.image(with: defaultResource, cacheOptions: .disk))
        XCTAssertFalse(LarkImageService.shared.isCached(resource: defaultResource, options: .disk))

        // 删除内存缓存，此时内存缓存没有内容，需要sleep(self.removeCacheWaitTime)，removeCache是异步的
        LarkImageService.shared.removeCache(resource: defaultResource, options: .memory); sleep(self.removeCacheWaitTime)
        XCTAssertNil(LarkImageService.shared.image(with: defaultResource, cacheOptions: .memory))
        XCTAssertFalse(LarkImageService.shared.isCached(resource: defaultResource, options: .memory))
        // 磁盘缓存依然没有内容
        XCTAssertNil(LarkImageService.shared.image(with: defaultResource, cacheOptions: .disk))
        XCTAssertFalse(LarkImageService.shared.isCached(resource: defaultResource, options: .disk))

        // 设置磁盘缓存，此时内存缓存中没有内容
        LarkImageService.shared.cacheImage(image: Resources.image(named: "1200x1400-JPEG"), resource: defaultResource, cacheOptions: .disk)
        XCTAssertNil(LarkImageService.shared.image(with: defaultResource, cacheOptions: .memory))
        XCTAssertFalse(LarkImageService.shared.isCached(resource: defaultResource, options: .memory))
        // 此时磁盘缓存中已有内容
        XCTAssertNotNil(LarkImageService.shared.image(with: defaultResource, cacheOptions: .disk))
        XCTAssertTrue(LarkImageService.shared.isCached(resource: defaultResource, options: .disk))
        // 如果取了磁盘缓存的内容，内部会默认加到内存缓存里
        XCTAssertNotNil(LarkImageService.shared.image(with: defaultResource, cacheOptions: .memory))
        XCTAssertTrue(LarkImageService.shared.isCached(resource: defaultResource, options: .memory))

        // 删除磁盘缓存，此时磁盘缓存没有内容，需要sleep(self.removeCacheWaitTime)，removeCache是异步的
        LarkImageService.shared.removeCache(resource: defaultResource, options: .disk); sleep(self.removeCacheWaitTime)
        XCTAssertNil(LarkImageService.shared.image(with: defaultResource, cacheOptions: .disk))
        XCTAssertFalse(LarkImageService.shared.isCached(resource: defaultResource, options: .disk))
        // 内存缓存依然有内容
        XCTAssertNotNil(LarkImageService.shared.image(with: defaultResource, cacheOptions: .memory))
        XCTAssertTrue(LarkImageService.shared.isCached(resource: defaultResource, options: .memory))
        // 删除内存缓存，此时内存缓存没有内容
        LarkImageService.shared.removeCache(resource: defaultResource, options: .memory); sleep(self.removeCacheWaitTime)
        XCTAssertNil(LarkImageService.shared.image(with: defaultResource, cacheOptions: .memory))
        XCTAssertFalse(LarkImageService.shared.isCached(resource: defaultResource, options: .memory))

        // 设置内存+磁盘缓存，此时内存+磁盘缓存中已有内容
        LarkImageService.shared.removeCache(resource: defaultResource, options: .all); sleep(self.removeCacheWaitTime)
        LarkImageService.shared.cacheImage(image: Resources.image(named: "1200x1400-JPEG"), resource: defaultResource, cacheOptions: .all)
        XCTAssertNotNil(LarkImageService.shared.image(with: defaultResource, cacheOptions: .memory))
        XCTAssertTrue(LarkImageService.shared.isCached(resource: defaultResource, options: .memory))
        XCTAssertNotNil(LarkImageService.shared.image(with: defaultResource, cacheOptions: .disk))
        XCTAssertTrue(LarkImageService.shared.isCached(resource: defaultResource, options: .disk))

        // 删除内存缓存，此时内存缓存没有内容，需要sleep(self.removeCacheWaitTime)，removeCache是异步的
        LarkImageService.shared.removeCache(resource: defaultResource, options: .memory); sleep(self.removeCacheWaitTime)
        XCTAssertNil(LarkImageService.shared.image(with: defaultResource, cacheOptions: .memory))
        XCTAssertFalse(LarkImageService.shared.isCached(resource: defaultResource, options: .memory))
        // 此时磁盘缓存还有内容
        XCTAssertNotNil(LarkImageService.shared.image(with: defaultResource, cacheOptions: .disk))
        XCTAssertTrue(LarkImageService.shared.isCached(resource: defaultResource, options: .disk))
        // 如果取了磁盘缓存的内容，内部会默认加到内存缓存里
        XCTAssertNotNil(LarkImageService.shared.image(with: defaultResource, cacheOptions: .memory))
        XCTAssertTrue(LarkImageService.shared.isCached(resource: defaultResource, options: .memory))

        // 删除磁盘缓存，此时磁盘缓存没有内容，需要sleep(self.removeCacheWaitTime)，removeCache是异步的
        LarkImageService.shared.removeCache(resource: defaultResource, options: .disk); sleep(self.removeCacheWaitTime)
        XCTAssertNil(LarkImageService.shared.image(with: defaultResource, cacheOptions: .disk))
        XCTAssertFalse(LarkImageService.shared.isCached(resource: defaultResource, options: .disk))
        // 删除磁盘缓存，内存缓存依然有值
        XCTAssertNotNil(LarkImageService.shared.image(with: defaultResource, cacheOptions: .memory))
        XCTAssertTrue(LarkImageService.shared.isCached(resource: defaultResource, options: .memory))
        // 删除内存缓存，此时内存缓存没有内容，需要sleep(self.removeCacheWaitTime)，removeCache是异步的
        LarkImageService.shared.removeCache(resource: defaultResource, options: .memory); sleep(self.removeCacheWaitTime)
        XCTAssertNil(LarkImageService.shared.image(with: defaultResource, cacheOptions: .memory))
        XCTAssertFalse(LarkImageService.shared.isCached(resource: defaultResource, options: .memory))
    }

    /// 测试thumbCache
    func testThumbCache() {
        let defaultResource: LarkImageResource = .avatar(key: "avatar", entityID: "entityID", params: .defaultThumb)
        // 初始时，内存+磁盘缓存没有内容
        XCTAssertNil(LarkImageService.shared.image(with: defaultResource, cacheOptions: .memory))
        XCTAssertFalse(LarkImageService.shared.isCached(resource: defaultResource, options: .memory))
        XCTAssertNil(LarkImageService.shared.image(with: defaultResource, cacheOptions: .disk))
        XCTAssertFalse(LarkImageService.shared.isCached(resource: defaultResource, options: .disk))

        // 设置内存缓存，此时内存缓存中有内容
        LarkImageService.shared.cacheImage(image: Resources.image(named: "1200x1400-JPEG"), resource: defaultResource, cacheOptions: .memory)
        XCTAssertNotNil(LarkImageService.shared.image(with: defaultResource, cacheOptions: .memory))
        XCTAssertTrue(LarkImageService.shared.isCached(resource: defaultResource, options: .memory))
        // 磁盘缓存依然没有内容
        XCTAssertNil(LarkImageService.shared.image(with: defaultResource, cacheOptions: .disk))
        XCTAssertFalse(LarkImageService.shared.isCached(resource: defaultResource, options: .disk))

        // 删除内存缓存，此时内存缓存没有内容，需要sleep(self.removeCacheWaitTime)，removeCache是异步的
        LarkImageService.shared.removeCache(resource: defaultResource, options: .memory); sleep(self.removeCacheWaitTime)
        XCTAssertNil(LarkImageService.shared.image(with: defaultResource, cacheOptions: .memory))
        XCTAssertFalse(LarkImageService.shared.isCached(resource: defaultResource, options: .memory))
        // 磁盘缓存依然没有内容
        XCTAssertNil(LarkImageService.shared.image(with: defaultResource, cacheOptions: .disk))
        XCTAssertFalse(LarkImageService.shared.isCached(resource: defaultResource, options: .disk))

        // 设置磁盘缓存，此时内存缓存中没有内容
        LarkImageService.shared.cacheImage(image: Resources.image(named: "1200x1400-JPEG"), resource: defaultResource, cacheOptions: .disk)
        XCTAssertNil(LarkImageService.shared.image(with: defaultResource, cacheOptions: .memory))
        XCTAssertFalse(LarkImageService.shared.isCached(resource: defaultResource, options: .memory))
        // 此时磁盘缓存中已有内容
        XCTAssertNotNil(LarkImageService.shared.image(with: defaultResource, cacheOptions: .disk))
        XCTAssertTrue(LarkImageService.shared.isCached(resource: defaultResource, options: .disk))
        // 如果取了磁盘缓存的内容，内部会默认加到内存缓存里
        XCTAssertNotNil(LarkImageService.shared.image(with: defaultResource, cacheOptions: .memory))
        XCTAssertTrue(LarkImageService.shared.isCached(resource: defaultResource, options: .memory))

        // 删除磁盘缓存，此时磁盘缓存没有内容，需要sleep(self.removeCacheWaitTime)，removeCache是异步的
        LarkImageService.shared.removeCache(resource: defaultResource, options: .disk); sleep(self.removeCacheWaitTime)
        XCTAssertNil(LarkImageService.shared.image(with: defaultResource, cacheOptions: .disk))
        XCTAssertFalse(LarkImageService.shared.isCached(resource: defaultResource, options: .disk))
        // 内存缓存依然有内容
        XCTAssertNotNil(LarkImageService.shared.image(with: defaultResource, cacheOptions: .memory))
        XCTAssertTrue(LarkImageService.shared.isCached(resource: defaultResource, options: .memory))
        // 删除内存缓存，此时内存缓存没有内容
        LarkImageService.shared.removeCache(resource: defaultResource, options: .memory); sleep(self.removeCacheWaitTime)
        XCTAssertNil(LarkImageService.shared.image(with: defaultResource, cacheOptions: .memory))
        XCTAssertFalse(LarkImageService.shared.isCached(resource: defaultResource, options: .memory))

        // 设置内存+磁盘缓存，此时内存+磁盘缓存中已有内容
        LarkImageService.shared.removeCache(resource: defaultResource, options: .all); sleep(self.removeCacheWaitTime)
        LarkImageService.shared.cacheImage(image: Resources.image(named: "1200x1400-JPEG"), resource: defaultResource, cacheOptions: .all)
        XCTAssertNotNil(LarkImageService.shared.image(with: defaultResource, cacheOptions: .memory))
        XCTAssertTrue(LarkImageService.shared.isCached(resource: defaultResource, options: .memory))
        XCTAssertNotNil(LarkImageService.shared.image(with: defaultResource, cacheOptions: .disk))
        XCTAssertTrue(LarkImageService.shared.isCached(resource: defaultResource, options: .disk))

        // 删除内存缓存，此时内存缓存没有内容，需要sleep(self.removeCacheWaitTime)，removeCache是异步的
        LarkImageService.shared.removeCache(resource: defaultResource, options: .memory); sleep(self.removeCacheWaitTime)
        XCTAssertNil(LarkImageService.shared.image(with: defaultResource, cacheOptions: .memory))
        XCTAssertFalse(LarkImageService.shared.isCached(resource: defaultResource, options: .memory))
        // 此时磁盘缓存还有内容
        XCTAssertNotNil(LarkImageService.shared.image(with: defaultResource, cacheOptions: .disk))
        XCTAssertTrue(LarkImageService.shared.isCached(resource: defaultResource, options: .disk))
        // 如果取了磁盘缓存的内容，内部会默认加到内存缓存里
        XCTAssertNotNil(LarkImageService.shared.image(with: defaultResource, cacheOptions: .memory))
        XCTAssertTrue(LarkImageService.shared.isCached(resource: defaultResource, options: .memory))

        // 删除磁盘缓存，此时磁盘缓存没有内容，需要sleep(self.removeCacheWaitTime)，removeCache是异步的
        LarkImageService.shared.removeCache(resource: defaultResource, options: .disk); sleep(self.removeCacheWaitTime)
        XCTAssertNil(LarkImageService.shared.image(with: defaultResource, cacheOptions: .disk))
        XCTAssertFalse(LarkImageService.shared.isCached(resource: defaultResource, options: .disk))
        // 删除磁盘缓存，内存缓存依然有值
        XCTAssertNotNil(LarkImageService.shared.image(with: defaultResource, cacheOptions: .memory))
        XCTAssertTrue(LarkImageService.shared.isCached(resource: defaultResource, options: .memory))
        // 删除内存缓存，此时内存缓存没有内容，需要sleep(self.removeCacheWaitTime)，removeCache是异步的
        LarkImageService.shared.removeCache(resource: defaultResource, options: .memory); sleep(self.removeCacheWaitTime)
        XCTAssertNil(LarkImageService.shared.image(with: defaultResource, cacheOptions: .memory))
        XCTAssertFalse(LarkImageService.shared.isCached(resource: defaultResource, options: .memory))
    }

    /// 测试setImage thumbCache
    func testSetImageForAvatar() {
        var expectation = LKTestExpectation(description: "@test set image avatar")
        let avatarResource: LarkImageResource = .avatar(key: "avatar", entityID: "entityID", params: .defaultThumb)
        LarkImageService.shared.setImage(with: avatarResource, completion: { imageResult in
            switch imageResult {
            case .success(_):
                // 预期没有结果
                XCTExpectFailure()
            case .failure(_):
                break
            }
            expectation.fulfill()
        })
        expectation.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
        if expectation.autoFulfill { return }

        expectation = LKTestExpectation(description: "@test set image avatar")
        LarkImageService.shared.cacheImage(image: Resources.image(named: "1200x1400-JPEG"), resource: avatarResource, cacheOptions: .memory)
        LarkImageService.shared.setImage(with: avatarResource, completion: { [weak self] imageResult in
            guard let `self` = self else { return }

            switch imageResult {
            case .success(let result):
                // 预期命中内存缓存
                XCTAssertTrue(result.from == .memoryCache)
            case .failure(_):
                XCTExpectFailure()
            }
            LarkImageService.shared.removeCache(resource: avatarResource, options: .all); sleep(self.removeCacheWaitTime)
            expectation.fulfill()
        })
        expectation.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
        if expectation.autoFulfill { return }

        expectation = LKTestExpectation(description: "@test set image avatar")
        LarkImageService.shared.cacheImage(image: Resources.image(named: "1200x1400-JPEG"), resource: avatarResource, cacheOptions: .disk)
        LarkImageService.shared.setImage(with: avatarResource, completion: { [weak self] imageResult in
            guard let `self` = self else { return }

            switch imageResult {
            case .success(let result):
                // 预期命中磁盘缓存
                XCTAssertTrue(result.from == .diskCache)
                // ImageManager.enableMemoryCache默认为true，如果从磁盘获取，则会放入一份到内存
                XCTAssertNotNil(LarkImageService.shared.image(with: avatarResource, cacheOptions: .memory))
                XCTAssertTrue(LarkImageService.shared.isCached(resource: avatarResource, options: .memory))
            case .failure(_):
                XCTExpectFailure()
            }
            LarkImageService.shared.removeCache(resource: avatarResource, options: .all); sleep(self.removeCacheWaitTime)
            expectation.fulfill()
        })
        expectation.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
        if expectation.autoFulfill { return }

        expectation = LKTestExpectation(description: "@test set image avatar")
        LarkImageService.shared.cacheImage(image: Resources.image(named: "1200x1400-JPEG"), resource: avatarResource, cacheOptions: .all)
        LarkImageService.shared.setImage(with: avatarResource, completion: { [weak self] imageResult in
            guard let `self` = self else { return }

            switch imageResult {
            case .success(let result):
                // 预期命中内存缓存
                XCTAssertTrue(result.from == .memoryCache)
            case .failure(_):
                XCTExpectFailure()
            }
            LarkImageService.shared.removeCache(resource: avatarResource, options: .all); sleep(self.removeCacheWaitTime)
            expectation.fulfill()
        })
        expectation.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
        if expectation.autoFulfill { return }
    }

    /// 测试setImage originCache
    func testSetImageForDefault() {
        var expectation = LKTestExpectation(description: "@test set image default")
        let avatarResource: LarkImageResource = .default(key: "default")
        LarkImageService.shared.setImage(with: avatarResource, completion: { imageResult in
            switch imageResult {
            case .success(_):
                // 预期没有结果
                XCTExpectFailure()
            case .failure(_):
                break
            }
            expectation.fulfill()
        })
        expectation.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
        if expectation.autoFulfill { return }

        expectation = LKTestExpectation(description: "@test set image default")
        LarkImageService.shared.cacheImage(image: Resources.image(named: "1200x1400-JPEG"), resource: avatarResource, cacheOptions: .memory)
        LarkImageService.shared.setImage(with: avatarResource, completion: { [weak self] imageResult in
            guard let `self` = self else { return }

            switch imageResult {
            case .success(let result):
                // 预期命中内存缓存
                XCTAssertTrue(result.from == .memoryCache)
            case .failure(_):
                XCTExpectFailure()
            }
            LarkImageService.shared.removeCache(resource: avatarResource, options: .all); sleep(self.removeCacheWaitTime)
            expectation.fulfill()
        })
        expectation.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
        if expectation.autoFulfill { return }

        expectation = LKTestExpectation(description: "@test set image default")
        LarkImageService.shared.cacheImage(image: Resources.image(named: "1200x1400-JPEG"), resource: avatarResource, cacheOptions: .disk)
        LarkImageService.shared.setImage(with: avatarResource, completion: { [weak self] imageResult in
            guard let `self` = self else { return }

            switch imageResult {
            case .success(let result):
                // 预期命中磁盘缓存
                XCTAssertTrue(result.from == .diskCache)
                // ImageManager.enableMemoryCache默认为true，如果从磁盘获取，则会放入一份到内存
                XCTAssertNotNil(LarkImageService.shared.image(with: avatarResource, cacheOptions: .memory))
                XCTAssertTrue(LarkImageService.shared.isCached(resource: avatarResource, options: .memory))
            case .failure(_):
                XCTExpectFailure()
            }
            LarkImageService.shared.removeCache(resource: avatarResource, options: .all); sleep(self.removeCacheWaitTime)
            expectation.fulfill()
        })
        expectation.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
        if expectation.autoFulfill { return }

        expectation = LKTestExpectation(description: "@test set image default")
        LarkImageService.shared.cacheImage(image: Resources.image(named: "1200x1400-JPEG"), resource: avatarResource, cacheOptions: .all)
        LarkImageService.shared.setImage(with: avatarResource, completion: { [weak self] imageResult in
            guard let `self` = self else { return }

            switch imageResult {
            case .success(let result):
                // 预期命中内存缓存
                XCTAssertTrue(result.from == .memoryCache)
            case .failure(_):
                XCTExpectFailure()
            }
            LarkImageService.shared.removeCache(resource: avatarResource, options: .all); sleep(self.removeCacheWaitTime)
            expectation.fulfill()
        })
        expectation.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
        if expectation.autoFulfill { return }
    }
}
