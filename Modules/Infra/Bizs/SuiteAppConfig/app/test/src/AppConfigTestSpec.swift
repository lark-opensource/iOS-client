//
//  AppConfigTestSpec.swift
//  SuiteAppConfigDevEEUnitTest
//
//  Created by liuwanlin on 2020/3/4.
//

import Foundation
import XCTest
import LarkRustClient
import SwiftProtobuf
import RxSwift
import RustPB
import LarkFeatureGating
@testable import SuiteAppConfig

class AppConfigTestSpec: XCTestCase {
    private var disposeBag = DisposeBag()

    override func setUp() {
        super.setUp()
        LarkFeatureGating.shared.loadFeatureValues(with: "1")
        LarkFeatureGating.shared.updateFeatureBoolValue(for: "lark.leanmode.debug.log", value: true)
        LarkFeatureGating.shared.updateFeatureBoolValue(for: "lark.leanmode.switch", value: true)
        AppConfigManager.shared.setDependency { () -> RustService in
            return MockRustClient()
        }
    }

    override func tearDown() {
        super.tearDown()
        AppConfigManager.shared.clearConfig()
    }

    func testPullConfig_1() {
        let expectation = XCTestExpectation(description: "load config")
        AppConfigManager.shared.pullConfig(for: "1", success: {
            // Test enable
            XCTAssert(AppConfigManager.shared.feature(for: "push").isOn == false)
            XCTAssert(AppConfigManager.shared.feature(for: "navi").isOn == true)

            // Test get trait
            let specializeProfile: Bool = AppConfigManager.shared.feature(for: "leanMode").trait(for: "specializeProfile") ?? false
            let clearDataTimeInterval: Int = AppConfigManager.shared.feature(for: "leanMode").trait(for: "clearDataTimeInterval") ?? 0
            XCTAssert(specializeProfile == true && clearDataTimeInterval > 0)

            // Test unknown feature
            XCTAssert(AppConfigManager.shared.feature(for: "unknown").key == "unknown")

            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 1)
    }

    func testPullConfig_2() {
        let expectation = XCTestExpectation(description: "load config")
        AppConfigManager.shared.pullConfig(for: "1", strategy: .forceServer)
            .subscribe(onNext: { (_) in
                // Test enable
                XCTAssert(AppConfigManager.shared.feature(for: "push").isOn == false)
                XCTAssert(AppConfigManager.shared.feature(for: "navi").isOn == true)

                // Test get trait
                let specializeProfile: Bool = AppConfigManager.shared.feature(for: "leanMode").trait(for: "specializeProfile") ?? false
                let clearDataTimeInterval: Int = AppConfigManager.shared.feature(for: "leanMode").trait(for: "clearDataTimeInterval") ?? 0
                XCTAssert(specializeProfile == true && clearDataTimeInterval > 0)

                // Test unknown feature
                XCTAssert(AppConfigManager.shared.feature(for: "unknown").key == "unknown")

                expectation.fulfill()
            })
            .disposed(by: self.disposeBag)

        wait(for: [expectation], timeout: 1)
    }

    func testLoadLocalConfig() {
        let expectation = XCTestExpectation(description: "load config")
        AppConfigManager.shared.pullConfig(for: "1", success: {
            AppConfigManager.shared.loadLocalConfig(for: "1")
            // Test enable
            XCTAssert(AppConfigManager.shared.feature(for: "push").isOn == false)
            XCTAssert(AppConfigManager.shared.feature(for: "navi").isOn == true)

            // Test get trait
            let specializeProfile: Bool = AppConfigManager.shared.feature(for: "leanMode").trait(for: "specializeProfile") ?? false
            let clearDataTimeInterval: Int = AppConfigManager.shared.feature(for: "leanMode").trait(for: "clearDataTimeInterval") ?? 0
            XCTAssert(specializeProfile == true && clearDataTimeInterval > 0)

            // Test unknown feature
            XCTAssert(AppConfigManager.shared.feature(for: "unknown").key == "unknown")

            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 1)
    }

    func testReloadConfig() {
        let expectation = XCTestExpectation(description: "load config")
        LarkFeatureGating.shared.updateFeatureBoolValue(for: "lark.leanmode.switch", value: true)
        AppConfigManager.shared.updateLocalConfigStatus(status: true, userId: "1")
        AppConfigManager.shared.pullConfig(for: "1", success: {
            AppConfigManager.shared.reloadConfig(for: "1")
            // Test enable
            XCTAssert(AppConfigManager.shared.feature(for: "push").isOn == false)
            XCTAssert(AppConfigManager.shared.feature(for: "navi").isOn == true)

            // Test get trait
            let specializeProfile: Bool = AppConfigManager.shared.feature(for: "leanMode").trait(for: "specializeProfile") ?? false
            let clearDataTimeInterval: Int = AppConfigManager.shared.feature(for: "leanMode").trait(for: "clearDataTimeInterval") ?? 0
            XCTAssert(specializeProfile == true && clearDataTimeInterval > 0)

            // Test unknown feature
            XCTAssert(AppConfigManager.shared.feature(for: "unknown").key == "unknown")

            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 1)
    }

    func testEnableLeanMode() {
        LarkFeatureGating.shared.updateFeatureBoolValue(for: "lark.leanmode.switch", value: false)
        AppConfigManager.shared.updateLocalConfigStatus(status: true, userId: "1")
        AppConfigManager.shared.loadLocalConfig(for: "1")
        XCTAssert(AppConfigManager.shared.features.isEmpty)
    }

    func testClear() {
        let expectation = XCTestExpectation(description: "load config")
        AppConfigManager.shared.pullConfig(for: "1", success: {
            // Test enable
            XCTAssert(AppConfigManager.shared.feature(for: "navi").isOn == true)

            AppConfigManager.shared.clearConfig()

            XCTAssert(AppConfigManager.shared.features.isEmpty)

            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 1)
    }

    func testPush() {
        let expectation = XCTestExpectation(description: "load config")
        AppConfigManager.shared.pullConfig(for: "1", success: {
            // fake feature
            var feature = AppConfigV2.FeatureConf()
            feature.isOn = true
            feature.traits = "{}"

            // mock config
            var config = mockConfig()
            config.section.features["fake.feature"] = feature

            var response = Im_V1_PushAllAppConfigV2Response()
            response.config = config

            let pushHandler = PushAllAppConfigV2PushHandler(currentUserId: "1")
            pushHandler.doProcessing(message: response)

            XCTAssert(AppConfigManager.shared.feature(for: "fake.feature").isOn)

            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 1)
    }

    func testComplicatedTraits() {
        let expectation = XCTestExpectation(description: "load config")
        AppConfigManager.shared.pullConfig(for: "1", success: {
            let tabs: [[String: Any]] = AppConfigManager.shared.feature(for: "navi").trait(for: "tabs") ?? []
            XCTAssert(!tabs.isEmpty && tabs[0]["primaryOnly"] as? Bool == true)
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 1)
    }

    func testExist() {
        let expectation = XCTestExpectation(description: "exist")
        AppConfigManager.shared.pullConfig(for: "1", success: {
            // key存在
            let leanMode = AppConfigManager.shared.exist(for: "leanMode")
            XCTAssert(leanMode == true)
            // key不存在
            let testLeanMode = AppConfigManager.shared.exist(for: "test_leanMode")
            XCTAssert(testLeanMode == false)
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 1)
    }

    func testPerfomance() {
        let expectation = XCTestExpectation(description: "load config")
        AppConfigManager.shared.pullConfig(for: "1", success: {
            AppConfigManager.shared.loadLocalConfig(for: "1")
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 1)
    }

    func testBaseConfig() {
        let config = try? BaseConfig(key: "baseConfig", traits: "{ leanMode: true }")
        config?.trait(for: "leanMode", decode: { leanMode in
            XCTAssert((leanMode as? Bool) == true)
        })
    }
}
