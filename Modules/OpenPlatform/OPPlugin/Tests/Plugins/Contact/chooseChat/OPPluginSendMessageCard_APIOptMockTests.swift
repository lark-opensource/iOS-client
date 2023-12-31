//
//  OPPluginSendMessageCard_APIOptMockTests.swift
//  OPPlugin-Unit-Tests
//
//  Created by ByteDance on 2023/10/11.
//

import Foundation
import OPUnitTestFoundation
import AppContainer
import LarkAssembler
import Swinject
import OCMock
import LarkContainer

@available(iOS 13.0, *)
class OPPluginSendMessageCard_APIOptMockTests: GadgetAPIXCTestCase {
    
    let apiName = "sendMessageCard"
    
    var mockRecorder: OCMockObject?
    
    let successResponseGetChatIDByOpenChatID: [String: [String: AnyHashable]] = ["chatids": ["test_openChatid": "chatid"]]
    
    let successResponseGetChatIDByOpenID: [String: [String: AnyHashable]] = ["chatids_map": ["chatid":  2]]
    

    
    @Provider var ecoService: ECONetworkService
    var mockService: OPMockECONetworkService? {
        return ecoService as? OPMockECONetworkService
    }
    
    override func setUpWithError() throws {
        try super.setUpWithError()

        OPAPIUniteOptFGMock.enableUniteOpt()
        OPAPIEMARouteProviderFGMock.enableProviderOpt()
        let assemblies: [LarkAssemblyInterface] = [
            OPECONetworkServiceMockAssembly(),
            OPMockEMAProtocolService()
        ]
        _ = assemblies.forEach { $0.registContainer(container: BootLoader.container) }
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        OPAPIUniteOptFGMock.disableUniteOpt()
        OPAPIEMARouteProviderFGMock.disableProviderOpt()
        let assemblies: [LarkAssemblyInterface] = [
            ECONetworkAssembly(),
        ]
        _ = assemblies.forEach { $0.registContainer(container: BootLoader.container) }
    }
    
    func test_success_openChatID() throws {
        let innerCipher = EMANetworkCipher()
        mockRecorder = OCMockAssistant.mock_EMANetworkCipher {
            innerCipher
        }
        
        addTeardownBlock {
            self.mockRecorder?.stopMocking()
        }
        
        guard let encryptStringGetUserID = innerCipher.encryptString(content: successResponseGetChatIDByOpenChatID) else {
            throw NSError(domain: "cannot generate encryptString!", code: -1)
        }
        
        let getUserIDResponse =
        [
            "encryptedData": encryptStringGetUserID,
            "error": 0,
            "message": "just test"
        ] as [String : Any]
        
        mockService?.mockResult = (getUserIDResponse, nil)

        let params: [String: AnyHashable] = ["openChatIDs": ["test_openChatid"], "cardContent": ["ddd": "ddd"]]
        success_async_api_test(apiName: apiName, params: params)
    }
    
    func test_success_openID() throws {
        let innerCipher = EMANetworkCipher()
        mockRecorder = OCMockAssistant.mock_EMANetworkCipher {
            innerCipher
        }
        
        addTeardownBlock {
            self.mockRecorder?.stopMocking()
        }
        
        guard let encryptStringGetUserID = innerCipher.encryptString(content: successResponseGetChatIDByOpenID) else {
            throw NSError(domain: "cannot generate encryptString!", code: -1)
        }
        
        let getUserIDResponse =
        [
            "encryptedData": encryptStringGetUserID,
            "error": 0,
            "message": "just test"
        ] as [String : Any]
        
        mockService?.mockResult = (getUserIDResponse, nil)

        let params: [String: AnyHashable] = ["openIDs": ["test_openid"], "cardContent": ["ddd": "ddd"]]
        success_async_api_test(apiName: apiName, params: params)
    }
    
}
