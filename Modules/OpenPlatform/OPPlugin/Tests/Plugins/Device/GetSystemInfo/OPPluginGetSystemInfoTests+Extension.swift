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

@testable import OPPlugin
@testable import OPPluginManagerAdapter
@testable import TTMicroApp

// MARK: - 小程序 Common + Extension
@available(iOS 13.0, *)
class OPPluginGetSystemInfo_Gadget_Extension_Tests: OPPluginGetSystemInfo_Common_Tests {
    
    override func setUpWithError() throws {
        APIExtensionFGHelper.enableExtension()
        testUtils.registerGadgetMockExtension()
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
    
    func registerGadgetMockExtension() {
        // mock extension
        pluginManager.register(OpenAPIGetSystemInfoExtension.self) { resolver, context in
            try OpenAPIGetSystemInfoExtensionGadgetImpl(extensionResolver: resolver, context: context)
        }
        pluginManager.register(OpenAPICommonExtension.self) { _, context in
            OpenAPICommonExtensionAppImpl(gadgetContext: try TTMicroApp.getGadgetContext(context))
        }
    }
}

// MARK: - Block Common + Extension
@available(iOS 13.0, *)
class OPPluginGetSystemInfo_Block_Extension_Tests: OPPluginGetSystemInfo_Block_Tests {
    
    override func setUpWithError() throws {
        APIExtensionFGHelper.enableExtension()
        testUtils.registerBlockMockExtension()
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
    
    func registerBlockMockExtension() {
        // mock extension
        pluginManager.register(OpenAPIGetSystemInfoExtension.self) { resolver, context in
            try OpenAPIGetSystemInfoExtensionBlockImpl(extensionResolver: resolver, context: context)
        }
        pluginManager.register(OpenAPICommonExtension.self) { _, context in
            OpenAPICommonExtensionAppImpl(gadgetContext: try TTMicroApp.getGadgetContext(context))
        }
    }
}
