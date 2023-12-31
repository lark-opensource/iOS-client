//
//  OPPluginGetWifiStatusTests.swift
//  OPPlugin-Unit-Tests
//
//  Created by baojianjun on 2023/7/20.
//

import XCTest
import LarkOpenAPIModel
import OPUnitTestFoundation
@testable import OPPlugin

@available(iOS 13.0, *)
final class OPPluginWifiTests: GadgetAPIXCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_getWifiStatus_success() throws {
        can_call_async_api_test(apiName: "getWifiStatus")
    }
    
    func test_onGetWifiList_success() throws {
        success_async_api_test(apiName: "onGetWifiList") {
            XCTAssertTrue($0 == nil)
        }
    }
    
    func test_offGetWifiList_success() throws {
        success_async_api_test(apiName: "offGetWifiList") {
            XCTAssertTrue($0 == nil)
        }
    }
    
    func test_getWifiList_failed() throws {
        failed_async_api_test(apiName: "getWifiList") {
            XCTAssertTrue($0.code.rawValue == OpenAPICommonErrorCode.unable.rawValue)
            XCTAssertTrue($0.outerMessage == "system not support")
        }
    }
}
