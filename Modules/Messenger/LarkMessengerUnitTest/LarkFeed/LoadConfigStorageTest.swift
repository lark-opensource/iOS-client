//
//  LoadConfigStorageTest.swift
//  LarkMessengerUnitTest
//
//  Created by 袁平 on 2020/9/6.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import XCTest
import RxSwift
import RustPB
import SwiftProtobuf
import RunloopTools
@testable import LarkFeed

/// Mock中有强解包，暂时disable swiftlint
// swiftlint:disable all
class LoadConfigStorageTest: XCTestCase {
    var loadConfig: LoadConfigStorage!

    override func setUp() {
        RunloopDispatcher.enable = true
        // 清除缓存
        UserDefaults.standard.removeObject(forKey: "Feed.Loadmessenger_feed_load_count")
        loadConfig = LoadConfigStorage()
        super.setUp()
    }

    override func tearDown() {
        loadConfig = nil
        super.tearDown()
    }

    // MARK: - pull

    /// case 1: 拉取并保存成功
    func test_pull() {
        // 拉取 && 保存
        loadConfig.pull(MockLoadConfigDependency())

        mainWait()

        // 读取保存的数据，进行校验
        let storage = UserDefaults.standard.string(forKey: "Feed.Loadmessenger_feed_load_count")
        let data = storage!.data(using: .utf8)
        let setting = try! JSONDecoder().decode(LoadSetting.self, from: data!)
        XCTAssert(setting.buffer == 40)
        XCTAssert(setting.cache_total == 90)
        XCTAssert(setting.loadmore == 40)
        XCTAssert(setting.refresh == 10)
    }

    // MARK: - settings

    /// case 1: config存在，settings读取成功
    func test_settings_1() {
        // 拉取并保存config
        loadConfig.pull(MockLoadConfigDependency())
        mainWait()

        XCTAssert(loadConfig.settings != nil)
    }

    /// case 2: config不存在，settings为nil
    func test_settings_2() {
        XCTAssert(loadConfig.settings == nil)
    }

    // MARK: - refresh

    /// case 1: config存在，refresh取config值
    func test_refresh_1() {
        // 拉取并保存config
        loadConfig.pull(MockLoadConfigDependency())
        mainWait()

        XCTAssert(loadConfig.refresh == 10)
    }

    /// case 2: config不存在，refresh取默认值
    func test_refresh_2() {
        XCTAssert(loadConfig.refresh == 20)
    }

    // MARK: - loadMore

    /// case 1: config存在，loadMore取config值
    func test_loadMore_1() {
        // 拉取并保存config
        loadConfig.pull(MockLoadConfigDependency())
        mainWait()

        XCTAssert(loadConfig.loadMore == 40)
    }

    /// case 2: config不存在，loadMore取默认值
    func test_loadMore_2() {
        XCTAssert(loadConfig.loadMore == 50)
    }

    // MARK: - buffer

    /// case 1: config存在，buffer取config值
    func test_buffer_1() {
        // 拉取并保存config
        loadConfig.pull(MockLoadConfigDependency())
        mainWait()

        XCTAssert(loadConfig.buffer == 40)
    }

    /// case 2: config不存在，buffer取默认值
    func test_buffer_2() {
        XCTAssert(loadConfig.buffer == 50)
    }
}

private class MockLoadConfigDependency: LoadConfigDependency {
    func sendAsyncRequest(_ request: Message) -> Observable<[String: String]> {
        // 为了和sdk返回值区分，这里故意取-10的值
        let setting = LoadSetting(buffer: 40, cache_total: 90, loadmore: 40, refresh: 10)
        let data = try! JSONEncoder().encode(setting)
        let str = String(data: data, encoding: .utf8)
        print("Feed Config: \(str!)")
        let res = ["messenger_feed_load_count": str!]
        return .just(res)
    }
}

// swiftlint:enable all
