//
//  MonitorReportTests+Extension.swift
//  OPPlugin-Unit-Tests
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
final class MonitorReport_Gadget_Extension_Tests: MonitorReport_Gadget_Tests {
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        APIExtensionFGHelper.enableExtension()
        testUtils.registerGadgetMockExtension()
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        APIExtensionFGHelper.disableExtension()
    }
    
    override func test_monitorReport_success() throws {
        success_async_api_test(apiName: apiName, params: params)
    }
}


@available(iOS 13.0, *)
fileprivate extension OpenPluginTestUtils {
    
    func registerGadgetMockExtension() {
        // mock extension
        pluginManager.register(OpenAPICommonExtension.self) { _, context in
            OpenAPICommonExtensionAppImpl(gadgetContext: try getGadgetContext(context))
        }
    }
}
