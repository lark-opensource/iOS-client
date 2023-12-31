//
//  OPPluginChooseContact_APIOptMockTests.swift
//  AppHost-OPPlugin-Unit-Tests
//
//  Created by ByteDance on 2023/10/10.
//

import Foundation
import OPUnitTestFoundation
import OCMock
import AppContainer
import LarkAssembler
import Swinject
import LarkContainer

@available(iOS 13.0, *)
class OPPluginChooseContact_APIOptMockTests: GadgetAPIXCTestCase {
    
    let apiName = "chooseContact"
    
    var mockRecorder: OCMockObject?
    
    let successResponseContent: [String: AnyHashable] = ["open_user_summary": ["test_chatid1":["openid": "ss", "union_id": "ss"], "test_chatid2":["openid": "ss", "union_id": "ss"]]]
    
    @Provider var ecoService: ECONetworkService
    var mockService: OPMockECONetworkService? {
        return ecoService as? OPMockECONetworkService
    }
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        ContactChatStandardizeMockSetting.enableContactChatStandardize()

        // 注入mock ECONetworkService
        let assemblies: [LarkAssemblyInterface] = [
            OPMockLarkOpenAPIServiceAssembly(),
            OPECONetworkServiceMockAssembly(),
        ]
        _ = assemblies.forEach { $0.registContainer(container: BootLoader.container) }

    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        let assemblies: [LarkAssemblyInterface] = [
            ECONetworkAssembly(),
        ]
        ContactChatStandardizeMockSetting.disableContactChatStandardize()
        _ = assemblies.forEach { $0.registContainer(container: BootLoader.container) }
    }
    
    func test_success_openid() throws {
        
        OPAPIUniteOptFGMock.enableUniteOpt()
        OPECONetworkAPISettingMock.enableECONetwork()
        
        let innerCipher = EMANetworkCipher()
        
        guard let encryptString = innerCipher.encryptString(content: successResponseContent) else {
            throw NSError(domain: "cannot generate encryptString!", code: -1)
        }
        
        mockRecorder = OCMockAssistant.mock_EMANetworkCipher {
            innerCipher
        }
        
        addTeardownBlock {
            OPAPIUniteOptFGMock.disableUniteOpt()
            OPECONetworkAPISettingMock.disableECONetwork()
            self.mockRecorder?.stopMocking()
        }
        
        let response =
        [
            "encryptedData": encryptString,
            "error": 0,
            "message": "just test"
        ] as [String : Any]
        
        mockService?.mockResult = (response, nil)
        
        let validParams: [String: AnyHashable] = ["openChatId": "openid"]
        success_async_api_test(apiName: apiName, params: validParams)
    }
    
}
