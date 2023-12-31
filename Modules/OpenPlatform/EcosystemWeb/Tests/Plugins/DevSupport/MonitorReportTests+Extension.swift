//
//  MonitorReportTests+Extension.swift
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
@testable import EcosystemWeb

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
class MonitorReport_WebApp_Extension_Fail_Tests: MonitorReport_WebApp_Fail_Tests {
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        APIExtensionFGHelper.enableExtension()
        testUtils.registerWebAppMockExtension()
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        APIExtensionFGHelper.disableExtension()
    }
    
    override func test_monitorReport_failed() throws {
        failed_async_api_test(apiName: apiName, params: params) { error in

            XCTAssertEqual(error.code.rawValue, OpenAPICommonErrorCode.errno.rawValue)

            guard let errno = error.errnoInfo["errno"] as? Int else {
                XCTFail("error \(error) has no errnoInfo!")
                return
            }

            XCTAssertEqual(errno, OpenAPICommonErrno.unable.rawValue)
            XCTAssertEqual(error.monitorMsg, "monitorReport extension unavailable")
        }
    }
}

@available(iOS 13.0, *)
final class MonitorReport_WebApp_Extension_Success_Tests: MonitorReport_WebApp_Success_Tests {
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        APIExtensionFGHelper.enableExtension()
        testUtils.registerWebAppMockExtension()
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
    
    func registerWebAppMockExtension() {
        // mock extension
        pluginManager.register(OpenAPIMonitorReportExtension.self) { resolver, context in
            try OpenAPIMonitorReportExtensionH5Impl(extensionResolver: resolver, context: context)
        }
        pluginManager.register(OpenAPICommonExtension.self) { _, context in
            OpenAPICommonExtensionAppImpl(gadgetContext: try EcosystemWeb.getGadgetContext(context))
        }
    }
}
