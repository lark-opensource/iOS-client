//
//  OPPluginGetUserInfoEx_APIOptMockTests.swift
//  AppHost-OPPlugin-Unit-Tests
//
//  Created by ByteDance on 2023/10/11.
//

import Foundation
import OPUnitTestFoundation
import OCMock
import AppContainer
import LarkAssembler
import Swinject
import LarkContainer

@available(iOS 13.0, *)
class OPPluginGetUserInfoEx_APIOptMockTests: GadgetAPIXCTestCase {
    
    let apiName = "getUserInfoEx"
    
    override func setUpWithError() throws {
        try super.setUpWithError()

        OPAPIUniteOptFGMock.enableUniteOpt()
        // 注入mock ECONetworkService
        let assemblies: [LarkAssemblyInterface] = [
            OPMockLarkOpenAPIServiceAssembly()
        ]
        _ = assemblies.forEach { $0.registContainer(container: BootLoader.container) }

    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        OPAPIUniteOptFGMock.disableUniteOpt()
    }
    
    func test_success_openid() throws {
        success_async_api_test(apiName: apiName)
    }
}
