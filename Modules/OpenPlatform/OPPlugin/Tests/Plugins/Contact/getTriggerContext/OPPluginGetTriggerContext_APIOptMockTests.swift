//
//  OPPluginGetTriggerContext_APIOptMockTests.swift
//  AppHost-OPPlugin-Unit-Tests
//
//  Created by ByteDance on 2023/10/10.
//

import Foundation
import OPUnitTestFoundation
import LarkContainer
import OCMock
import AppContainer
import LarkAssembler
import Swinject
import OPFoundation

@available(iOS 13.0, *)
class OPPluginGetTriggerContext_APIOptMockTests: GadgetAPIXCTestCase {
    let apiName = "getTriggerContext"
    
    var mockRecorder: OCMockObject?
    
    let successResponseContent: [String: AnyHashable] = ["openchatids": ["chatID": ["open_chat_id": "dd"]]]
    
    @Provider var ecoService: ECONetworkService
    var mockService: OPMockECONetworkService? {
        return ecoService as? OPMockECONetworkService
    }
    
    override func setUpWithError() throws {
        try super.setUpWithError()

        // 注入mock ECONetworkService
        let assemblies: [LarkAssemblyInterface] = [
            OPECONetworkServiceMockAssembly(),
            OPMockEMAProtocolService()
        ]
        _ = assemblies.forEach { $0.registContainer(container: BootLoader.container) }

    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        let assemblies: [LarkAssemblyInterface] = [
            ECONetworkAssembly()
        ]
        
        _ = assemblies.forEach { $0.registContainer(container: BootLoader.container) }
    }
    
    func test_success() throws {
        
        OPAPIUniteOptFGMock.enableUniteOpt()
        OPAPIEMARouteProviderFGMock.enableProviderOpt()
        
        let innerCipher = EMANetworkCipher()
        
        guard let encryptString = innerCipher.encryptString(content: successResponseContent) else {
            throw NSError(domain: "cannot generate encryptString!", code: -1)
        }
        
        mockRecorder = OCMockAssistant.mock_EMANetworkCipher {
            innerCipher
        }
        
        let response =
        [
            "encryptedData": encryptString,
            "error": 0,
            "message": "just test"
        ] as [String : Any]
        
        addTeardownBlock {
            OPAPIUniteOptFGMock.disableUniteOpt()
            OPECONetworkAPISettingMock.disableECONetwork()
            OPAPIEMARouteProviderFGMock.disableProviderOpt()
            self.mockRecorder?.stopMocking()
        }
        
        mockService?.mockResult = (response, nil)
        
        let validParams: [String: AnyHashable] = ["triggerCode": "test_triggerCode"]
        success_async_api_test(apiName: apiName, params: validParams)
    }
}
