//
//  OpenPluginClipboardDataTests.swift
//  OPPlugin-Unit-Tests
//
//  Created by baojianjun on 2023/8/18.
//

import XCTest
import OCMock
import LarkOpenAPIModel
import OPUnitTestFoundation

@testable import TTMicroApp

// @available(iOS 13.0, *)
// final class OpenPluginClipboardData_Success_Tests: GadgetAPIXCTestCase {
    
//     let apiName = "getClipboardData"
    
//     static let testName = "testName"
    
//     private var testInstance: OCMockObject?
    
//     override func setUpWithError() throws {
//         try super.setUpWithError()
        
//         testInstance = OCMockAssistant.mock_BDPCommonManager_getCommon {
//             let model = BDPModel.fakeModel(with: self.testUtils.uniqueID, name: Self.testName, icon: nil, urls: nil)
//             let common = BDPCommon(model: model, schema: self.mockSchema())
//             common?.isActive = true
//             common?.isReady = true
//             return common
//         }
//     }
    
//     override func tearDownWithError() throws {
//         try super.tearDownWithError()
//         testInstance?.stopMocking()
//     }
    
//     func test_success() throws {
        
//         APIExtensionFGHelper7_1.disableExtension()
//         addTeardownBlock {
//             APIExtensionFGHelper7_1.enableExtension()
//         }
        
//         success_async_api_test(apiName: apiName, params: [:])
//     }
    
    
//     func test_extension_success() throws {
        
//         testUtils.registerGadgetMockExtension()
        
//         APIExtensionFGHelper7_1.enableExtension()
//         addTeardownBlock {
//             APIExtensionFGHelper7_1.disableExtension()
//         }
        
//         success_async_api_test(apiName: apiName, params: [:])
//     }
// }

// @available(iOS 13.0, *)
// final class OpenPluginClipboardData_Fail_Tests: GadgetAPIXCTestCase {
    
//     let apiName = "getClipboardData"
    
//     static let testName = "testName"
    
//     private var testInstance: OCMockObject?
    
//     override func setUpWithError() throws {
//         try super.setUpWithError()
        
//         testInstance = OCMockAssistant.mock_BDPCommonManager_getCommon {
//             let model = BDPModel.fakeModel(with: self.testUtils.uniqueID, name: Self.testName, icon: nil, urls: nil)
//             let common = BDPCommon(model: model, schema: self.mockSchema())
//             common?.isActive = false
//             return common
//         }
//     }
    
//     override func tearDownWithError() throws {
//         try super.tearDownWithError()
//         testInstance?.stopMocking()
//     }
    
//     func test_fail() throws {
        
//         APIExtensionFGHelper7_1.disableExtension()
//         addTeardownBlock {
//             APIExtensionFGHelper7_1.enableExtension()
//         }
        
// //        failed_async_api_test(apiName: apiName) { error in
// //            XCTAssertEqual(error.code.rawValue, OpenAPISetClipboardDataErrorCode.inovkeInBackground.rawValue, "it should be inovkeInBackground error when common is not active")
// //        }
//         // CI单测没有 登录态，所以没有preventAccessClipBoardInBackground 的setting，因此这里会直接成功
//         success_async_api_test(apiName: apiName)
//     }
    
    
//     func test_extension_fail() throws {
        
//         testUtils.registerGadgetMockExtension()
        
//         APIExtensionFGHelper7_1.enableExtension()
//         addTeardownBlock {
//             APIExtensionFGHelper7_1.disableExtension()
//         }
        
//         failed_async_api_test(apiName: apiName) { error in
//             XCTAssertEqual(error.code.rawValue, OpenAPISetClipboardDataErrorCode.inovkeInBackground.rawValue, "it should be inovkeInBackground error when common is not active")
//         }
//     }
    
//     func test_no_common_fail() throws {
        
//         testInstance?.stopMocking()
        
//         APIExtensionFGHelper7_1.disableExtension()
//         addTeardownBlock {
//             APIExtensionFGHelper7_1.enableExtension()
//         }
        
//         failed_async_api_test(apiName: apiName) { error in
//             XCTAssertEqual(error.code.rawValue, OpenAPICommonErrorCode.internalError.rawValue, "it should be no common error")
//         }
//     }
// }

// @available(iOS 13.0, *)
// final class OpenPluginClipboardData_Default_Extension_Success_Tests: GadgetAPIXCTestCase {
    
//     let apiName = "getClipboardData"
    
//     func test_default_extension_success() throws {
        
//         APIExtensionFGHelper7_1.enableExtension()
//         addTeardownBlock {
//             APIExtensionFGHelper7_1.disableExtension()
//         }
        
//         success_async_api_test(apiName: apiName)
//     }
// }

// @available(iOS 13.0, *)
// fileprivate extension OpenPluginTestUtils {
    
//     func registerGadgetMockExtension() {
//         // mock extension
//         pluginManager.register(OpenAPIClipboardDataExtension.self) { resolver, context in
//             try OpenAPIClipboardDataExtensionGadgetImpl(extensionResolver: resolver, context: context)
//         }
//     }
// }
