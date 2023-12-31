//
//  MonitorReportTests.swift
//  OPPlugin-Unit-Tests
//
//  Created by baojianjun on 2023/7/25.
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
class MonitorReport_Gadget_Tests: APIXCTestCase {
    
    func test_monitorReport_success() throws {
        success_async_api_test(apiName: apiName, params: params)
    }
}
