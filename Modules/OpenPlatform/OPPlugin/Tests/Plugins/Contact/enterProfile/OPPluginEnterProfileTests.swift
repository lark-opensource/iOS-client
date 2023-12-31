//
//  OPPluginEnterProfileTests.swift
//  OPPlugin-Unit-Tests
//
//  Created by baojianjun on 2023/7/20.
//

import XCTest

import LarkOpenAPIModel
import LarkOpenPluginManager
import OPUnitTestFoundation
import OPFoundation
import ECOInfra

import Swinject
import LarkAssembler
import AppContainer

@testable import OPPlugin
@testable import OPPluginManagerAdapter
@testable import TTMicroApp

@available(iOS 13.0, *)
class OPPluginEnterProfile_EMANetworkManager_SuccessResponse_Tests: GadgetAPIXCTestCase {
    
    let apiName = "enterProfile"
    
    let successResponseContent: [String: AnyHashable] = ["userid": "mock-userid-value"]
    
    let validParams: [String: AnyHashable] = ["openid": ""]
    
    let validParamsKey: String = "openid"
    
    var mockObject: OPPluginContact_Mock = OPPluginContact_EMANetworkManager_POSTURL_Mock()
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        // setting mock EMANetworkManager
        OPECONetworkAPISettingMock.disableECONetwork()
        OPAPIUniteOptFGMock.disableUniteOpt()
        try mockObject.prepareForSuccessMock(responseContent: successResponseContent, responseError: 0, responseMessage: "this is unit test message")
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        mockObject.release()
        OPAPIUniteOptFGMock.enableUniteOpt()
        OPECONetworkAPISettingMock.enableECONetwork()
    }
    
    func test_success() throws {
        
        // 无extension实现的情况下，需要mock EMARouteMediator.sharedInstance
        EMARouteMediator.sharedInstance().enterProfileBlock = { _, _, _ in }
        APIExtensionFGHelper.disableExtension()
        OPECONetworkAPISettingMock.disableECONetwork()
        addTeardownBlock {
            EMARouteMediator.sharedInstance().enterProfileBlock = nil
            APIExtensionFGHelper.enableExtension()
            OPECONetworkAPISettingMock.enableECONetwork()
        }
        
        success_async_api_test(apiName: apiName, params: validParams)
    }
    
    func test_no_valid_params_failed() throws {
        
        // 无extension实现的情况下，需要mock EMARouteMediator.sharedInstance
        EMARouteMediator.sharedInstance().enterProfileBlock = { _, _, _ in }
        APIExtensionFGHelper.disableExtension()
        addTeardownBlock {
            EMARouteMediator.sharedInstance().enterProfileBlock = nil
            APIExtensionFGHelper.enableExtension()
        }
        
        failed_async_api_test(apiName: apiName, params: [:]) { error in
            if let errMsg = error.isEqualToParamCannotEmpty(jsonKey: self.validParamsKey) {
                XCTFail(errMsg)
            }
        }
    }
}

@available(iOS 13.0, *)
class OPPluginEnterProfile_EMANetworkManager_FailedResponse_Tests: GadgetAPIXCTestCase {
    
    let apiName = "enterProfile"
    
    let validParams: [String: AnyHashable] = ["openid": ""]
    
    let validParamsKey: String = "openid"
    
    var mockObject: OPPluginContact_Mock = OPPluginContact_EMANetworkManager_POSTURL_Mock()
    
    func test_no_response_failed() throws {
        
        // 无extension实现的情况下，需要mock EMARouteMediator.sharedInstance
        EMARouteMediator.sharedInstance().enterProfileBlock = { _, _, _ in }
        APIExtensionFGHelper.disableExtension()
        OPAPIUniteOptFGMock.disableUniteOpt()
        OPECONetworkAPISettingMock.disableECONetwork()
        addTeardownBlock {
            EMARouteMediator.sharedInstance().enterProfileBlock = nil
            APIExtensionFGHelper.enableExtension()
            OPECONetworkAPISettingMock.enableECONetwork()
            self.mockObject.release()
            OPAPIUniteOptFGMock.enableUniteOpt()
        }
        
        let monitorMsg = mockObject.prepareForNoResponseFailedMock()
        
        failed_async_api_test(apiName: apiName, params: validParams) { error in
            XCTAssertEqual(error.monitorMsg, monitorMsg)
        }
    }
    
    func test_response_no_userid_failed() throws {
        
        // 无extension实现的情况下，需要mock EMARouteMediator.sharedInstance
        EMARouteMediator.sharedInstance().enterProfileBlock = { _, _, _ in }
        APIExtensionFGHelper.disableExtension()
        OPECONetworkAPISettingMock.disableECONetwork()
        OPAPIUniteOptFGMock.disableUniteOpt()
        addTeardownBlock {
            EMARouteMediator.sharedInstance().enterProfileBlock = nil
            APIExtensionFGHelper.enableExtension()
            OPECONetworkAPISettingMock.enableECONetwork()
            OPAPIUniteOptFGMock.enableUniteOpt()
        }
        
        let monitorMsgPrefix = "enterProfile error, no userid"
        try mockObject.prepare_for_failed_response_mock(monitorMsgPrefix: monitorMsgPrefix)
        let logidLog = "logid:\(mockObject.logID)"
        
        addTeardownBlock {
            self.mockObject.release()
        }
        
        failed_async_api_test(apiName: apiName, params: validParams) { error in
            XCTAssertTrue(error.monitorMsg?.contains(monitorMsgPrefix) ?? false, "the monitorMsg of the error: \(error) is not contains: \(monitorMsgPrefix)")
            XCTAssertTrue(error.monitorMsg?.contains(logidLog) ?? false, "the monitorMsg of the error: \(error) is not contains: \(logidLog)")
        }
    }
}


@available(iOS 13.0, *)
final class OPPluginEnterProfile_EMANetworkManager_SuccessResponse_Extension_Tests: OPPluginEnterProfile_EMANetworkManager_SuccessResponse_Tests {
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        APIExtensionFGHelper.enableExtension()
        // 注册extension服务
        testUtils.registerMockExtension()
        
        let assemblies: [LarkAssemblyInterface] = [
            OpenPlatformOuterMockAssembly(),
        ]
        assemblies.forEach { $0.registContainer(container: BootLoader.container) }
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        
        APIExtensionFGHelper.disableExtension()
        
        let assemblies: [LarkAssemblyInterface] = [
            OpenPlatformOuterRestoreAssembly(),
        ]
        assemblies.forEach { $0.registContainer(container: BootLoader.container) }
    }
    
    func test_extension_success() throws {
        success_async_api_test(apiName: apiName, params: validParams)
    }
    
    func test_extension_no_valid_params_failed() throws {
        failed_async_api_test(apiName: apiName, params: [:]) { error in
            if let errMsg = error.isEqualToParamCannotEmpty(jsonKey: self.validParamsKey) {
                XCTFail(errMsg)
            }
        }
    }
}

@available(iOS 13.0, *)
final class OPPluginEnterProfile_EMANetworkManager_FailedResponse_Extension_Tests: OPPluginEnterProfile_EMANetworkManager_FailedResponse_Tests {
    
    let successResponseContent: [String: AnyHashable] = ["userid": "mock-userid-value"]
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        APIExtensionFGHelper.enableExtension()
        OPAPIUniteOptFGMock.disableUniteOpt()
        OPECONetworkAPISettingMock.disableECONetwork()
        
        let assemblies: [LarkAssemblyInterface] = [
            OpenPlatformOuterMockAssembly(),
        ]
        assemblies.forEach { $0.registContainer(container: BootLoader.container) }
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        OPAPIUniteOptFGMock.enableUniteOpt()
        APIExtensionFGHelper.disableExtension()
        OPECONetworkAPISettingMock.enableECONetwork()
        
        let assemblies: [LarkAssemblyInterface] = [
            OpenPlatformOuterRestoreAssembly(),
        ]
        assemblies.forEach { $0.registContainer(container: BootLoader.container) }
    }
    
    override func test_no_response_failed() throws {
        
        testUtils.registerMockExtension()
        
        let monitorMsg = mockObject.prepareForNoResponseFailedMock()
        
        addTeardownBlock {
            self.mockObject.release()
        }
        
        failed_async_api_test(apiName: apiName, params: validParams) { error in
            XCTAssertEqual(error.monitorMsg, monitorMsg)
        }
    }
    
    override func test_response_no_userid_failed() throws {
        
        testUtils.registerMockExtension()
        
        let monitorMsgPrefix = "enterProfile error, no userid"
        try mockObject.prepare_for_failed_response_mock(monitorMsgPrefix: monitorMsgPrefix)
        let logidLog = "logid:\(mockObject.logID)"
        
        addTeardownBlock {
            self.mockObject.release()
        }
        
        failed_async_api_test(apiName: apiName, params: validParams) { error in
            XCTAssertTrue(error.monitorMsg?.contains(monitorMsgPrefix) ?? false, "the monitorMsg of the error: \(error) is not contains: \(monitorMsgPrefix)")
            XCTAssertTrue(error.monitorMsg?.contains(logidLog) ?? false, "the monitorMsg of the error: \(error) is not contains: \(logidLog)")
        }
    }
    
    func test_no_extension_failed() throws {
        
        // 准备response
        try mockObject.prepareForSuccessMock(responseContent: successResponseContent, responseError: 0, responseMessage: "this is unit test message")
        addTeardownBlock {
            self.mockObject.release()
        }
        
        failed_async_api_test(apiName: apiName, params: validParams) { error in
            guard let monitorMsg = error.monitorMsg else {
                XCTFail("error: \(error) has no monitorMsg!")
                return
            }
            XCTAssertTrue(monitorMsg.starts(with: "cannot find entry of key:"), "monitorMsg: \(monitorMsg) is not contain \"cannot find entry of key:\"")
        }
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
