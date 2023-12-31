//
//  OPPluginGetSystemInfoTests.swift
//  OPPlugin-Unit-Tests
//
//  Created by baojianjun on 2023/7/20.
//

import XCTest
import OCMock

import LarkOpenAPIModel
import LarkOpenPluginManager
import OPUnitTestFoundation
import OPFoundation
import ECOInfra

import Swinject
import LarkAssembler
import AppContainer
import LarkContainer

@testable import OPPluginManagerAdapter

// MARK: - Common
@available(iOS 13.0, *)
class OPPluginGetSystemInfo_Common_Tests: APIXCTestCase {
    
    fileprivate static let apiName = "getSystemInfo"

    func test_getSystemInfo_common_success() throws {
        success_async_api_test(apiName: Self.apiName) { result in
            guard let result else {
                XCTFail(#function + "should get result but it is nil!")
                return
            }
            let dict = result.toJSONDict()
            
            guard let brand = dict["brand"] as? String else {
                XCTFail(#function + "should get brand but it is nil! dict: \(dict)")
                return
            }
            XCTAssertEqual(brand, "Apple")
            
            guard let model = dict["model"] as? String else {
                XCTFail(#function + "should get model but it is nil! dict: \(dict)")
                return
            }
            XCTAssertTrue(model == "iPhone Simulator" || model == "arm64")
            
            guard let pixelRatio = dict["pixelRatio"] as? Float else {
                XCTFail(#function + "should get pixelRatio but it is nil! dict: \(dict)")
                return
            }
            XCTAssertTrue(pixelRatio == 2.0 || pixelRatio == 3.0)
            
            guard let language = dict["language"] as? String else {
                XCTFail(#function + "should get language but it is nil! dict: \(dict)")
                return
            }
            XCTAssertFalse(language.isEmpty)
            
            guard dict["version"] is String else {
                XCTFail(#function + "should get version but it is nil! dict: \(dict)")
                return
            }
            
            guard let system = dict["system"] as? String else {
                XCTFail(#function + "should get system but it is nil! dict: \(dict)")
                return
            }
            XCTAssertTrue(system.starts(with: "iOS "))
            
            // 依赖了EMAProtocol, 未做注入, 直接判空即可
            guard dict["appName"] is String else {
                XCTFail(#function + "should get appName but it is nil! dict: \(dict)")
                return
            }
            
            guard let platform = dict["platform"] as? String else {
                XCTFail(#function + "should get platform but it is nil! dict: \(dict)")
                return
            }
            // 壳工程mock name
            XCTAssertTrue(platform == "iOS")
        }
    }
    
    func test_geo_success() {
        success_async_api_test(apiName: Self.apiName) { result in
            guard let result else {
                XCTFail(#function + "should get result but it is nil!")
                return
            }
            let dict = result.toJSONDict()
        }
    }
    
    func test_tenantGeo_success() {
        success_async_api_test(apiName: Self.apiName) { result in
            guard let result else {
                XCTFail(#function + "should get result but it is nil!")
                return
            }
            let dict = result.toJSONDict()
        }
    }
    
    func test_ui_model_success() {
        success_async_api_test(apiName: Self.apiName) { result in
            guard let result else {
                XCTFail(#function + "should get result but it is nil!")
                return
            }
            let dict = result.toJSONDict()
        }
    }
    
//    func test_ui_model_success() {
//        success_async_api_test(apiName: Self.apiName) { result in
//            guard let result else {
//                XCTFail(#function + "should get result but it is nil!")
//                return
//            }
//            let dict = result.toJSONDict()
//        }
//    }
}

// MARK: - Block Common
@available(iOS 13.0, *)
class OPPluginGetSystemInfo_Block_Tests: OPPluginGetSystemInfo_Common_Tests {
    private var _innerTestUtils = OpenPluginBlockTestUtils()
    override var testUtils: OpenPluginTestUtils {
        get {
            return _innerTestUtils
        }
        set {
            if let newValue = newValue as? OpenPluginBlockTestUtils {
                _innerTestUtils = newValue
            } else {
                fatalError()
            }
        }
    }
    
    override func test_getSystemInfo_common_success() throws {
        try super.test_getSystemInfo_common_success()
    }
}
