//
//  FeatureGatingManagerTest.swift
//  LarkSettingDevEEUnitTest
//
//  Created by Supeng on 2021/6/3.
//

import Foundation
import XCTest
@testable import LarkSetting

class FeatureGatingManagerTest: XCTestCase {

    private struct FeatureGatingProperyWrapperTestModel {
        @FeatureGatingValue(key: .allDBDamageKey) var allDBDamageFG: Bool
        @FeatureGatingValue(key: "all_db_damage") var allDBDamageFG1: Bool
        @FeatureGatingValue(key: .anotherNotExistKey) var notExistKeyFG: Bool
        @FeatureGatingValue(key: "another_not_exist_key") var notExistKeyFG1: Bool
    }

    override func setUp() {
        super.setUp()
        cache.removeAllObjects()
        FeatureGatingManager.currentChatterID = { testUserID }
    }

    func testGetFeature() throws {
        let feature1 = FeatureGatingManager.shared.featureGatingValue(with: .allDBDamageKey)
        XCTAssertTrue(feature1)

        let feature2 = FeatureGatingManager.shared.featureGatingValue(with: .notExistKey)
        XCTAssertFalse(feature2)
    }

    func testUpdateFeature() {
        // 测试更新Feature以后，可以收到更新后的值
        let onlineValue = FeatureGatingStorage.staticShared.features(of: testUserID)
            .union([FeatureGatingManager.Key.existKey.rawValue])
        FeatureGatingStorage.staticShared.update(with: .init(online: Array(onlineValue), values: [:]), and: testUserID)

        XCTAssertTrue(FeatureGatingManager.shared.featureGatingValue(with: .existKey))
    }

    func testDiskCache() {
        // 初始DiskCache数目为0
        XCTAssertEqual(cache.diskCache?.totalCount() ?? -1, 0)

        let onlineValue = Array(FeatureGatingStorage.staticShared.features(of: testUserID))
        + [FeatureGatingManager.Key.existKey.rawValue]
        FeatureGatingStorage.staticShared.update(with: .init(online: onlineValue, values: [:]), and: testUserID)
        FeatureGatingStorage.dynamicShared.update(with: .init(online: onlineValue, values: [:]), and: testUserID)

        // 磁盘缓存是异步的，所以需要等一小段时间再读才能读到正确的数据
        let expect = expectation(description: "disk cache")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            // 有fg更新以后，disk cache数目为1
            XCTAssertEqual(LarkSetting.cache.diskCache?.totalCount() ?? -1, 1)
            let fgData = cache.diskCache?.object(forKey: "featureGating" + testUserID) as? Data
            XCTAssertNotNil(fgData)
            let fg = try? LarkFeature.from(data: fgData ?? .init())
            XCTAssertEqual(fg?.online ?? [], onlineValue)

            expect.fulfill()
        }
        wait(for: [expect], timeout: 1.0)
    }

    func testMemoryCache() {
        // 调用过一次feature接口以后内存缓存有数据
        _ = FeatureGatingManager.shared.featureGatingValue(with: .notExistKey)
        XCTAssertTrue(!FeatureGatingStorage.staticShared.features(of: testUserID).isEmpty)

        // 切换用户以后，内存缓存数据跟着切换
        let anotherUser = "not valid user"
        FeatureGatingManager.currentChatterID = { anotherUser }
        _ = FeatureGatingManager.shared.featureGatingValue(with: .notExistKey)
        XCTAssertTrue(!FeatureGatingStorage.staticShared.features(of: anotherUser).isEmpty)
    }

    func testMultiUser() {
        let onlineValue = Array(FeatureGatingStorage.staticShared.features(of: testUserID)
            .union([FeatureGatingManager.Key.existKey.rawValue]))
        FeatureGatingStorage.staticShared.update(with: .init(online: onlineValue, values: [:]),
                                                 and: testUserID)
        FeatureGatingStorage.dynamicShared.update(with: .init(online: onlineValue, values: [:]),
                                                  and: testUserID)

        XCTAssertTrue(FeatureGatingManager.shared.featureGatingValue(with: .existKey))

        // 切换到其它用户，获取不到test user的fg
        let anotherUser = "not valid user"
        FeatureGatingManager.currentChatterID = { anotherUser }
        XCTAssertFalse(FeatureGatingManager.shared.featureGatingValue(with: .existKey))

        // 更新其它用户以后，磁盘缓存有两份数据
        FeatureGatingStorage.staticShared.update(with: .init(online: onlineValue,
                                                             values: [:]),
                                                 and: anotherUser)
        FeatureGatingStorage.dynamicShared.update(with: .init(online: onlineValue,
                                                              values: [:]),
                                                  and: anotherUser)

        let expect = expectation(description: "disk cache")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            XCTAssertEqual(LarkSetting.cache.diskCache?.totalCount() ?? -1, 2)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1.0)

        // 切换会test用户，可以继续获取该用户的fg
        FeatureGatingManager.currentChatterID = { testUserID }
        XCTAssertTrue(FeatureGatingManager.shared.featureGatingValue(with: .existKey))
    }

    func testFeatureGatingProperyWrapper() {
        let model = FeatureGatingProperyWrapperTestModel()
        XCTAssertTrue(model.allDBDamageFG)
        XCTAssertTrue(model.allDBDamageFG1)

        XCTAssertFalse(model.notExistKeyFG)
        XCTAssertFalse(model.notExistKeyFG1)
    }

    func testMultiThread() {
        let currentFeature = Array(FeatureGatingStorage.staticShared.features(of: testUserID))
        let testFeature = ["\(123)", "\(456)"]
        DispatchQueue.concurrentPerform(iterations: 10_000) { i in
            if i % 2 == 0 {
                FeatureGatingStorage.staticShared.update(with: .init(online: currentFeature, values: [:]),
                                                         and: testUserID)
            } else {
                FeatureGatingStorage.staticShared.update(with: .init(online: testFeature, values: [:]),
                                                         and: testUserID)
            }
        }
    }
}

extension FeatureGatingManager.Key {
    static let allDBDamageKey: Self = "all_db_damage"
    static let existKey: Self = "exist_key"
    static let notExistKey: Self = "not_exist_key"
    static let anotherNotExistKey: Self = "another_not_exist_key"
}
