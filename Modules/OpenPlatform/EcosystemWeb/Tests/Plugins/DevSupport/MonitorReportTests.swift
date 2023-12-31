//
//  MonitorReportTests.swift
//  EcosystemWeb-Unit-Tests
//
//  Created by baojianjun on 2023/8/17.
//

import XCTest

import OPFoundation
import LarkOpenAPIModel
import OPUnitTestFoundation
import LarkOpenPluginManager

@testable import LarkSetting
@testable import OPPluginManagerAdapter

fileprivate let apiName = "monitorReport"

fileprivate let params: [String: [[AnyHashable: Any]]] = [
    "monitorEvents": [
        [
            "name": "name1",
        ],
        [
            "name": "name2",
        ],
    ]
]

@available(iOS 13.0, *)
class MonitorReport_WebApp_Fail_Tests: WebAppAPIXCTestCase {
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        FeatureGatingStorage.updateDebugFeatureGating(fg: EEFeatureGatingKeyGadgetWebAppApiMonitorReport, isEnable: true, id: "")
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        FeatureGatingStorage.updateDebugFeatureGating(fg: EEFeatureGatingKeyGadgetWebAppApiMonitorReport, isEnable: false, id: "")
    }
     
    func test_monitorReport_failed() throws {
        failed_async_api_test(apiName: apiName, params: params) { error in
            XCTAssertEqual(error.code.rawValue, OpenAPICommonErrorCode.unknown.rawValue)
        }
    }
}

@available(iOS 13.0, *)
class MonitorReport_WebApp_Success_Tests: WebAppAPIXCTestCase {
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        FeatureGatingStorage.updateDebugFeatureGating(fg: EEFeatureGatingKeyGadgetWebAppApiMonitorReport, isEnable: false, id: "")
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        FeatureGatingStorage.updateDebugFeatureGating(fg: EEFeatureGatingKeyGadgetWebAppApiMonitorReport, isEnable: true, id: "")
    }
    
    func test_monitorReport_success() throws {
        success_async_api_test(apiName: apiName, params: params)
    }
}
