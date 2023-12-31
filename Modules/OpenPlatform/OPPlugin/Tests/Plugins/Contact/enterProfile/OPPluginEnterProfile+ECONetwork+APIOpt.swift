//
//  OPPluginEnterProfile+ECONetwork+APIOpt.swift
//  OPPlugin-Unit-Tests
//
//  Created by baojianjun on 2023/10/9.
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

@testable import OPPlugin
@testable import OPPluginManagerAdapter
@testable import TTMicroApp

@available(iOS 13.0, *)
class OPPluginEnterProfile_ECONetwork_SuccessResponse_Tests: GadgetAPIXCTestCase {
    
    let apiName = "enterProfile"
    
    let successResponseContent: [String: AnyHashable] = ["userid": "mock-userid-value"]
    
    let validParams: [String: AnyHashable] = ["openid": ""]
    
    let validParamsKey: String = "openid"
    
    @Provider var ecoService: ECONetworkService
    var mockService: OPMockECONetworkService? {
        return ecoService as? OPMockECONetworkService
    }
    
//    var mockObject: OPPluginContact_Mock = OPPluginContact_EMANetworkManager_POSTURL_Mock()
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // 注入mock ECONetworkService
        let assemblies: [LarkAssemblyInterface] = [
            OPECONetworkServiceMockAssembly(),
            OPMockLarkOpenAPIServiceAssembly(),
            OpenPlatformOuterMockAssembly(),
        ]
        _ = assemblies.forEach { $0.registContainer(container: BootLoader.container) }
        
        // enable ECONetwork
        OPECONetworkAPISettingMock.enableECONetwork()
        
        // enable unite opt
        OPAPIUniteOptFGMock.enableUniteOpt()
        
        // disable extension
        APIExtensionFGHelper.disableExtension()
        
        testUtils.registerMockExtension()
        
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        
        let assemblies: [LarkAssemblyInterface] = [
            ECONetworkAssembly(),
            OpenPlatformOuterRestoreAssembly(),
        ]
        _ = assemblies.forEach { $0.registContainer(container: BootLoader.container) }
        
        OPECONetworkAPISettingMock.disableECONetwork()
        
        OPAPIUniteOptFGMock.disableUniteOpt()
        
        APIExtensionFGHelper.enableExtension()
    }
    
    var mockRecorder: OCMockObject?
    
    func test_success() throws {
        
        let innerCipher = EMANetworkCipher()
        
        guard let encryptString = innerCipher.encryptString(content: successResponseContent) else {
            throw NSError(domain: "cannot generate encryptString!", code: -1)
        }
        
        APIExtensionFGHelper.disableExtension()
        
        mockRecorder = OCMockAssistant.mock_EMANetworkCipher {
            innerCipher
        }
        
        addTeardownBlock {
            self.mockRecorder?.stopMocking()
            APIExtensionFGHelper.enableExtension()
        }
        
        let response =
        [
            "encryptedData": encryptString,
            "error": 0,
            "message": "just test"
        ] as [String : Any]
        
        mockService?.mockResult = (response, nil)
        
        success_async_api_test(apiName: apiName, params: validParams)
    }
    
    func test_success_witth_extension() throws {
        
        let innerCipher = EMANetworkCipher()
        
        guard let encryptString = innerCipher.encryptString(content: successResponseContent) else {
            throw NSError(domain: "cannot generate encryptString!", code: -1)
        }
        
        APIExtensionFGHelper.enableExtension()
        mockRecorder = OCMockAssistant.mock_EMANetworkCipher {
            innerCipher
        }
        
        addTeardownBlock {
            APIExtensionFGHelper.disableExtension()
            self.mockRecorder?.stopMocking()
        }
        
        let response =
        [
            "encryptedData": encryptString,
            "error": 0,
            "message": "just test"
        ] as [String : Any]
        
        mockService?.mockResult = (response, nil)
        
        success_async_api_test(apiName: apiName, params: validParams)
    }
    
    func test_no_valid_params_failed() throws {
    }
}

@available(iOS 13.0, *)
fileprivate extension OpenPluginTestUtils {
    
    func registerMockExtension() {
        // mock extension
        pluginManager.register(OpenAPIContactExtension.self) { resolver, context in
            try OpenAPIContactExtensionAppImpl(extensionResolver: resolver, context: context)
        }
        pluginManager.register(OpenAPICommonExtension.self) { _, context in
            OpenAPICommonExtensionAppImpl(gadgetContext: try TTMicroApp.getGadgetContext(context))
        }
        pluginManager.register(OpenAPISessionExtension.self) { _, context in
            OpenAPISessionExtensionGadgetImpl(gadgetContext: try TTMicroApp.getGadgetContext(context))
        }
    }
}
