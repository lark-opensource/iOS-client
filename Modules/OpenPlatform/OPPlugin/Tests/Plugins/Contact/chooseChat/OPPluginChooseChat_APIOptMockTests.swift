//
//  OPPluginChooseChat_APIOptMockTests.swift
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
import LarkContainer

@objc
class OPMockBDPAuthModuleProtocolImpl: NSObject, BDPAuthModuleProtocol {
    
    @objc
    func checkSchema(_ url: URL!, uniqueID: OPAppUniqueID!, errorMsg failErrMsg: String!) -> Bool {
        return true
    }
    
    @objc
    func requestUserPermission(forScopeIfNeeded scope: String!, context: BDPPluginContext!, completion: ((BDPAuthorizationPermissionResult) -> Void)!) {
    }
    
    @objc
    func getSessionContext(_ contex: BDPPluginContext!) -> String! {
        return "test_session"
    }
    
    @objc
    func userInfoDict(_ data: [AnyHashable : Any]!, uniqueID: OPAppUniqueID!) -> [AnyHashable : Any]! {
        return [:]
    }
    
    @objc
    func userInfoURLUniqueID(_ uniqueID: OPAppUniqueID!) -> String! {
        return "test_userinfo"
    }
    
    @objc
    var moduleManager: BDPModuleManager?
}


@available(iOS 13.0, *)
class OPPluginChooseChat_APIOptMockTests: GadgetAPIXCTestCase {
    
    var mockRecorder: OCMockObject?
    
    let successResponseGetUserIDByOpenID: [String: AnyHashable] = ["userids": ["test_openid": "open_userids"]]
    
    let successResponseGetChatIDByOpenChatID: [String: [String: AnyHashable]] = ["chatids": ["test_openChatid": "oc_chatid"]]
    
    let successResponseGetOpenChatIDByChatID: [String: [String: AnyHashable]] = ["openchatids": ["2": ["chat_name": "dd"]]]
    
    @Provider var ecoService: ECONetworkService
    var mockService: OPMockECONetworkService? {
        return ecoService as? OPMockECONetworkService
    }
    
    override func setUpWithError() throws {
        try super.setUpWithError()

        OPAPIUniteOptFGMock.enableUniteOpt()
        OPECONetworkAPISettingMock.enableECONetwork()
        OPAPIEMARouteProviderFGMock.enableProviderOpt()
        // 注入mock ECONetworkService
        let assemblies: [LarkAssemblyInterface] = [
            OPMockLarkOpenAPIServiceAssembly(),
            OPECONetworkServiceMockAssembly(),
            OPMockEMAProtocolService()
        ]
        assemblies.forEach { $0.registContainer(container: BootLoader.container) }

    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        OPAPIUniteOptFGMock.disableUniteOpt()
        OPECONetworkAPISettingMock.disableECONetwork()
        OPAPIEMARouteProviderFGMock.disableProviderOpt()
        let assemblies: [LarkAssemblyInterface] = [
            ECONetworkAssembly(),
        ]
        assemblies.forEach { $0.registContainer(container: BootLoader.container) }
    }
    
    func test_success() throws {
        // let innerCipher = EMANetworkCipher()
        // mockRecorder = OCMockAssistant.mock_EMANetworkCipher {
        //     innerCipher
        // }
        
        // let manager = BDPModuleManager(of: .gadget)
        // manager.registerModule(with: BDPAuthModuleProtocol.self, class: OPMockBDPAuthModuleProtocolImpl.self)
        
        // addTeardownBlock {
        //     self.mockRecorder?.stopMocking()
        //     manager.registerModule(with: BDPAuthModuleProtocol.self, class: BDPAuthModule.self)
        // }
        
        // guard let encryptStringGetUserID = innerCipher.encryptString(content: successResponseGetUserIDByOpenID) else {
        //     throw NSError(domain: "cannot generate encryptString!", code: -1)
        // }
        
        // guard let encryptStringGetChatID = innerCipher.encryptString(content: successResponseGetChatIDByOpenChatID) else {
        //     throw NSError(domain: "cannot generate encryptString!", code: -1)
        // }
        
        // guard let encryptStringGetOpenChatID = innerCipher.encryptString(content: successResponseGetOpenChatIDByChatID) else {
        //     throw NSError(domain: "cannot generate encryptString!", code: -1)
        // }
        
        // let getUserIDResponse =
        // [
        //     "encryptedData": encryptStringGetUserID,
        //     "error": 0,
        //     "message": "just test"
        // ] as [String : Any]
        
        // let getChatIDResponse =
        // [
        //     "encryptedData": encryptStringGetChatID,
        //     "error": 0,
        //     "message": "just test"
        // ] as [String : Any]
        
        // let getOpenChatIDResponse =
        // [
        //     "encryptedData": encryptStringGetOpenChatID,
        //     "error": 0,
        //     "message": "just test"
        // ] as [String : Any]
        
        // mockService?.addMockResultDic(path: "/open-apis/mina/v2/getUserIDsByOpenIDs", result: (getUserIDResponse, nil))
        // mockService?.addMockResultDic(path: "/open-apis/mina/getChatIDsByOpenChatIDs", result: (getChatIDResponse, nil))
        // mockService?.addMockResultDic(path: "/open-apis/mina/v4/getOpenChatIDsByChatIDs", result: (getOpenChatIDResponse, nil))

        // let params: [String: AnyHashable] = ["chosenOpenIds": ["test_openid"], "chosenOpenChatIds": ["test_openChatid"]]
        // success_async_api_test(apiName: "chooseChat", params: params)
        
//        success_async_api_test(apiName: "chooseChat")
    }
}

