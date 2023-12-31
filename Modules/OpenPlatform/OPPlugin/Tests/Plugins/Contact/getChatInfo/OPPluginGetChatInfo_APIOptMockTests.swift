//
//  OPPluginGetChatInfo_APIOptMockTests.swift
//  OPPlugin-Unit-Tests
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
class OPPluginGetChatInfo_APIOptMockTests: GadgetAPIXCTestCase {
    
    let apiName = "getChatInfo"
    
    var mockRecorder: OCMockObject?
    
    let successResponseContent: [String: AnyHashable] = ["chatids": ["openChatId": "openChatId"]]
    
    let successResponseContentGetOpenChatID: [String: [String: AnyHashable]] = ["openchatids": ["openChatId": ["chat_name": "dd"]]]
    
    @Provider var ecoService: ECONetworkService
    var mockService: OPMockECONetworkService? {
        return ecoService as? OPMockECONetworkService
    }
    
    override func setUpWithError() throws {
        try super.setUpWithError()

        // 注入mock ECONetworkService
        let assemblies: [LarkAssemblyInterface] = [
            OPECONetworkServiceMockAssembly(),
            OPMockLarkOpenAPIServiceAssembly(),
        ]
        _ = assemblies.forEach { $0.registContainer(container: BootLoader.container) }

    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        let assemblies: [LarkAssemblyInterface] = [
            ECONetworkAssembly(),
        ]
        _ = assemblies.forEach { $0.registContainer(container: BootLoader.container) }
    }
    
    func test_success_openid() throws {
        
        OPAPIUniteOptFGMock.enableUniteOpt()
        OPECONetworkAPISettingMock.enableECONetwork()
        ContactChatStandardizeMockSetting.enableContactChatStandardize()
        
        let innerCipher = EMANetworkCipher()
        
        guard let encryptString = innerCipher.encryptString(content: successResponseContent) else {
            throw NSError(domain: "cannot generate encryptString!", code: -1)
        }
        
        guard let encryptString2 = innerCipher.encryptString(content: successResponseContentGetOpenChatID) else {
            throw NSError(domain: "cannot generate encryptString!", code: -1)
        }
        
        mockRecorder = OCMockAssistant.mock_EMANetworkCipher {
            innerCipher
        }
        
        addTeardownBlock {
            OPAPIUniteOptFGMock.disableUniteOpt()
            OPECONetworkAPISettingMock.disableECONetwork()
            ContactChatStandardizeMockSetting.disableContactChatStandardize()
            self.mockRecorder?.stopMocking()
        }
        

        
        let response =
        [
            "encryptedData": encryptString,
            "error": 0,
            "message": "just test"
        ] as [String : Any]
        
        let response2 =
        [
            "encryptedData": encryptString2,
            "error": 0,
            "message": "just test"
        ] as [String : Any]
        
        mockService?.addMockResultDic(path: "/open-apis/mina/getChatIDsByOpenChatIDs", result: (response, nil))
        mockService?.addMockResultDic(path: "/open-apis/mina/v4/getOpenChatIDsByChatIDs", result: (response2, nil))
        
        let validParams: [String: AnyHashable] = ["openChatId": "openChatId"]
        success_async_api_test(apiName: apiName, params: validParams)
    }

    
}
