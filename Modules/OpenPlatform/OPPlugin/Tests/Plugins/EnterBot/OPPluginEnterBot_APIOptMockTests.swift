//
//  OPPluginEnterBot_APIOptMockTests.swift
//  AppHost-OPPlugin-Unit-Tests
//
//  Created by ByteDance on 2023/10/9.
//

import Foundation
import OPUnitTestFoundation
import AppContainer
import LarkAssembler
import Swinject
import OCMock

@available(iOS 13.0, *)
class OPPluginEnterBot_APIOptMockTests: GadgetAPIXCTestCase {
    
    let apiName = "enterBot"
    
    private var testInstance: OCMockObject?

    override func setUpWithError() throws {
        try super.setUpWithError()

        // 注入mock ECONetworkService
        let assemblies: [LarkAssemblyInterface] = [
            OPMockLarkOpenAPIServiceAssembly(),
        ]
        _ = assemblies.forEach { $0.registContainer(container: BootLoader.container) }
        
        testInstance = OCMockAssistant.mock_BDPCommonManager_getCommon {
            var model = BDPModel.fakeModel(with: self.testUtils.uniqueID, name: "testName", icon: nil, urls: nil)
            model.extraDict = ["botid": "test_botid"]
            return BDPCommon(model: model, schema: self.mockSchema())
        }

    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        testInstance?.stopMocking()
    }

    func test_success() throws {
        
        // enable unite opt
        OPAPIUniteOptFGMock.enableUniteOpt()
        
        addTeardownBlock {
            OPAPIUniteOptFGMock.disableUniteOpt()
        }
        
        success_async_api_test(apiName: apiName)
    }
    
    func test_success_disable() throws {
        
        // enable unite opt
        OPAPIUniteOptFGMock.disableUniteOpt()
        EMARouteMediator.sharedInstance().enterBotBlock = { _, _, _ in }
        
        addTeardownBlock {
            OPAPIUniteOptFGMock.enableUniteOpt()
            EMARouteMediator.sharedInstance().enterBotBlock = nil
        }
        
        success_async_api_test(apiName: apiName)
    }
}
