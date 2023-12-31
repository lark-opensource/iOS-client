//
//  OPPluginGetSystemInfoTests+Extension.swift
//  OPPlugin-Unit-Tests
//
//  Created by baojianjun on 2023/7/25.
//

import Foundation
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
@testable import EcosystemWeb

// MARK: - 网页应用 Common + Extension
@available(iOS 13.0, *)
class OPPluginGetSystemInfo_WebApp_Extension_Tests: OPPluginGetSystemInfo_WebApp_Tests {
    
    override func setUpWithError() throws {
        APIExtensionFGHelper.enableExtension()
        testUtils.registerWebAppMockExtension()
    }
    
    override func tearDownWithError() throws {
        APIExtensionFGHelper.disableExtension()
    }
    
    override func test_getSystemInfo_common_success() throws {
        try super.test_getSystemInfo_common_success()
    }
}

@available(iOS 13.0, *)
fileprivate extension OpenPluginTestUtils {
    
    func registerWebAppMockExtension() {
        // mock extension
        pluginManager.register(OpenAPIGetSystemInfoExtension.self) { resolver, context in
            try OpenAPIGetSystemInfoExtensionWebAppImpl(extensionResolver: resolver, context: context)
        }
        pluginManager.register(OpenAPICommonExtension.self) { _, context in
            OpenAPICommonExtensionAppImpl(gadgetContext: try TTMicroApp.getGadgetContext(context))
        }
    }
}
