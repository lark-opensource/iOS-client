//
//  OPPluginGetChatIDsByOpenChatIDsTests.swift
//  OPPlugin-Unit-Tests
//
//  Created by baojianjun on 2023/8/18.
//

import XCTest
import LarkOpenAPIModel
import OPUnitTestFoundation
@testable import OPPluginManagerAdapter
@testable import TTMicroApp

// getChatIDsByOpenChatIDs
// EMANetworkManager
// no extension
// success
@available(iOS 13.0, *)
class OPPluginIDConverter_GetChatIDsByOpenChatIDs_EMANetworkManager_SuccessResponse_Tests: GadgetAPIXCTestCase {
    
    let apiName = "getChatIDsByOpenChatIDs"
    
    let successResponseContent: [String: AnyHashable] = ["chatids": ["unit-test-chat-id-1": 1]]
    
    let validParams: [String: AnyHashable] = ["openChatIDs": ["unit-test-open-chat-id-1"]]
    
    let validParamsKey: String = "openChatIDs"
    
    var mockObject: OPPluginContact_Mock = OPPluginContact_EMANetworkManager_RequestURL_Mock()
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        try mockObject.prepareForSuccessMock(responseContent: successResponseContent, responseError: 0, responseMessage: "this is unit test message")
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        mockObject.release()
    }
    
    func test_success() throws {
        
        APIExtensionFGHelper7_1.disableExtension()
        addTeardownBlock {
            APIExtensionFGHelper7_1.enableExtension()
        }
        
        success_async_api_test(apiName: apiName, params: validParams)
    }
    
    func test_no_valid_params_failed() throws {
        
        APIExtensionFGHelper7_1.disableExtension()
        addTeardownBlock {
            APIExtensionFGHelper7_1.enableExtension()
        }
        
        failed_async_api_test(apiName: apiName, params: [:]) { error in
            if let errMsg = error.isEqualToParamCannotEmpty(jsonKey: self.validParamsKey) {
                XCTFail(errMsg)
            }
        }
    }
}

// getChatIDsByOpenChatIDs
// EMANetworkManager
// no extension
// fail
@available(iOS 13.0, *)
class OPPluginIDConverter_GetChatIDsByOpenChatIDs_EMANetworkManager_FailedResponse_Tests: GadgetAPIXCTestCase {
    
    let apiName = "getChatIDsByOpenChatIDs"
    
    let validParams: [String: AnyHashable] = ["openChatIDs": ["unit-test-open-chat-id-1"]]
    
    let validParamsKey: String = "openChatIDs"
    
    var mockObject: OPPluginContact_Mock = OPPluginContact_EMANetworkManager_RequestURL_Mock()
    
    func test_no_response_failed() throws {
        
        APIExtensionFGHelper7_1.disableExtension()
        addTeardownBlock {
            APIExtensionFGHelper7_1.enableExtension()
        }
        
        let monitorMsg = mockObject.prepareForNoResponseFailedMock()
        
        addTeardownBlock {
            self.mockObject.release()
        }
        
        failed_async_api_test(apiName: apiName, params: validParams) { error in
            XCTAssertEqual(error.monitorMsg, monitorMsg)
        }
    }
    
    func test_response_not_valid_failed() throws {
        
        APIExtensionFGHelper7_1.disableExtension()
        addTeardownBlock {
            APIExtensionFGHelper7_1.enableExtension()
        }
        
        let monitorMsgPrefix = "get chatids from response data error"
        try mockObject.prepare_for_failed_response_mock(monitorMsgPrefix: monitorMsgPrefix)
        
        addTeardownBlock {
            self.mockObject.release()
        }
        
        failed_async_api_test(apiName: apiName, params: validParams) { error in
            XCTAssertTrue(error.monitorMsg?.starts(with: monitorMsgPrefix) ?? false, "the monitorMsg of the error: \(error) is not match with: \(monitorMsgPrefix)")
        }
    }
}


// getChatIDsByOpenChatIDs
// EMANetworkManager
// with extension
// success
@available(iOS 13.0, *)
final class OPPluginIDConverter_GetChatIDsByOpenChatIDs_EMANetworkManager_SuccessResponse_Extension_Tests: OPPluginIDConverter_GetChatIDsByOpenChatIDs_EMANetworkManager_SuccessResponse_Tests {
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        APIExtensionFGHelper7_1.enableExtension()
        // 注册extension服务
        testUtils.registerMockExtension()
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        
        APIExtensionFGHelper7_1.disableExtension()
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

// getChatIDsByOpenChatIDs
// EMANetworkManager
// with extension
// fail
@available(iOS 13.0, *)
final class OPPluginIDConverter_GetChatIDsByOpenChatIDs_EMANetworkManager_FailedResponse_Extension_Tests: OPPluginIDConverter_GetChatIDsByOpenChatIDs_EMANetworkManager_FailedResponse_Tests {
    
    let successResponseContent: [String: AnyHashable] = ["chatids": ["unit-test-chat-id-1": 1]]
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        APIExtensionFGHelper7_1.enableExtension()
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        
        APIExtensionFGHelper7_1.disableExtension()
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
    
    override func test_response_not_valid_failed() throws {
        
        testUtils.registerMockExtension()
        
        let monitorMsgPrefix = "get chatids from response data error"
        try mockObject.prepare_for_failed_response_mock(monitorMsgPrefix: monitorMsgPrefix)
        
        addTeardownBlock {
            self.mockObject.release()
        }
        
        failed_async_api_test(apiName: apiName, params: validParams) { error in
            XCTAssertTrue(error.monitorMsg?.starts(with: monitorMsgPrefix) ?? false, "the monitorMsg of the error: \(error) is not match with: \(monitorMsgPrefix)")
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
        pluginManager.register(OpenAPIChatIDExtension.self) { resolver, context in
            try OpenAPIChatIDExtensionGadgetImpl(extensionResolver: resolver, context: context)
        }
        pluginManager.register(OpenAPICommonExtension.self) { _, context in
            OpenAPICommonExtensionAppImpl(gadgetContext: try TTMicroApp.getGadgetContext(context))
        }
        pluginManager.register(OpenAPISessionExtension.self) { _, context in
            OpenAPISessionExtensionGadgetImpl(gadgetContext: try TTMicroApp.getGadgetContext(context))
        }
    }
}
