//
//  OPPluginAppBadge_APIOptMockTests.swift
//  AppHost-OPPlugin-Unit-Tests
//
//  Created by ByteDance on 2023/10/11.
//

import Foundation
import OPUnitTestFoundation
import AppContainer
import LarkAssembler
import Swinject
import OCMock

@available(iOS 13.0, *)
class OPPluginAppBadge_APIOptMockTests: GadgetAPIXCTestCase {
    
    override func setUpWithError() throws {
        try super.setUpWithError()

        OPAPIUniteOptFGMock.enableUniteOpt()
        // 注入mock ECONetworkService
        let assemblies: [LarkAssemblyInterface] = [
            OPMockLarkOpenAPIServiceAssembly()
        ]
        assemblies.forEach { $0.registContainer(container: BootLoader.container) }

    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        OPAPIUniteOptFGMock.disableUniteOpt()
    }
    
    func test_success_onServerBadgePush() throws {
        let apiName = "onServerBadgePush"
        let params: [String: AnyHashable] = ["appId": "ss", "appIds": ["ss", "ss"]]
        success_async_api_test(apiName: apiName, params: params)
    }
    
    func test_success_offServerBadgePush() throws {
        let apiName = "offServerBadgePush"
        let params: [String: AnyHashable] = ["appId": "ss", "appIds": ["ss", "ss"]]
        success_async_api_test(apiName: apiName, params: params)
    }
    
    func test_success_updateBadge() throws {
        let apiName = "updateBadge"
        let params: [String: AnyHashable] = ["badgeNum": 5]
        success_async_api_test(apiName: apiName, params: params)
    }
}
