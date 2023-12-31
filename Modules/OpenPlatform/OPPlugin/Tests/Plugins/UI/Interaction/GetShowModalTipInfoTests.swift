//
//  GetShowModalTipInfoTests.swift
//  OPPlugin-Unit-Tests
//
//  Created by baojianjun on 2023/8/17.
//

import XCTest
import OCMock
import LarkOpenAPIModel
import OPUnitTestFoundation

@testable import TTMicroApp
@testable import OPPluginManagerAdapter

@available(iOS 13.0, *)
final class GetShowModalTipInfoTests: GadgetAPIXCTestCase {
    
    static let testName = "testName"
    
    private var testInstance: OCMockObject?

    override func setUpWithError() throws {
        testUtils.registerGadgetMockExtension()
        testInstance = OCMockAssistant.mock_BDPCommonManager_getCommon {
            let model = BDPModel.fakeModel(with: self.testUtils.uniqueID, name: Self.testName, icon: nil, urls: nil)
            return BDPCommon(model: model, schema: self.mockSchema())
        }
    }

    override func tearDownWithError() throws {
        testInstance?.stopMocking()
    }

    func test_success_call() throws {
        
        success_async_api_test(apiName: "getShowModalTipInfo") { result in
            guard let dict = result?.toJSONDict() else {
                XCTFail("result cannot covert to JSONDict")
                return
            }
            guard dict["confirmText"] is String else {
                XCTFail("result \(dict) cannot get confirmText")
                return
            }
            guard dict["cancelText"] is String else {
                XCTFail("result \(dict) cannot get cancelText")
                return
            }
            guard let title = dict["title"] as? String else {
                XCTFail("result \(dict) cannot get title")
                return
            }
            XCTAssertTrue(title.contains(Self.testName))
        }
    }
}

@available(iOS 13.0, *)
fileprivate extension OpenPluginTestUtils {
    
    func registerGadgetMockExtension() {
        // mock extension
        pluginManager.register(OpenAPIShowModalTipInfoExtension.self) { resolver, context in
            try OpenAPIShowModalTipExtensionGadgetImpl(extensionResolver: resolver, context: context)
        }
        pluginManager.register(OpenAPICommonExtension.self) { _, context in
            OpenAPICommonExtensionAppImpl(gadgetContext: try TTMicroApp.getGadgetContext(context))
        }
    }
}
