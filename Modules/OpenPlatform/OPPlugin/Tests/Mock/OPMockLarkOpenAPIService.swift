//
//  OPMockLarkOpenAPIService.swift
//  OPPlugin-Unit-Tests
//
//  Created by baojianjun on 2023/10/9.
//

import Foundation
import Swinject
import LarkContainer
import LarkAssembler
import LarkOPInterface

final class OPMockLarkOpenAPIServiceAssembly: LarkAssemblyInterface {
    init() {}

    func registContainer(container: Swinject.Container) {
        
        container.register(LarkOpenAPIService.self) {_ in
            OPMockLarkOpenAPIService()
        }.inObjectScope(.container)
    }
}

final class OPMockLarkOpenAPIService: NSObject, LarkOpenAPIService {
    func enterBot(botID: String, from: UINavigationController?) {
        
    }
    
    func enterChat(chatID: String, showBadge: Bool, from: UINavigationController?) {
        
    }
    
    func enterProfile(userID: String, from: UINavigationController?) {
        
    }
    
    func chooseContact(config: LarkOPInterface.ChooseContactConfig, sourceVC: UIViewController, presentCompletion: @escaping (() -> Void), selectedNameCompletion: @escaping ([String]?, [String]?, [String]?) -> (() -> Void)?) {
        let completion = selectedNameCompletion(["test_chatid1","test_chatid2"], ["test_chatid1","test_chatid2"], [])
        completion?()
    }
    
    func chooseChat(config: LarkOPInterface.ChooseChatConfig) {
        config.completion?(["items": [["chatid": "2"]]], false)
    }
    
    func getChatInfo(chatID: String) -> [AnyHashable : Any]? {
        nil
    }
    
    func getAtInfo(chatID: String, block: @escaping (([String : Any]?) -> Void)) {
        block([:])
    }
    
    func getUserInfoEx(successBlock: @escaping (([String : Any]) -> Void), failBlock: @escaping (() -> Void)) {
        successBlock([:])
    }
    
    func onServerBadgePush(appID: String, subAppIDs: [String], completion: @escaping ((LarkOPInterface.AppBadgeNode) -> Void)) {
        
    }
    
    func offServerBadgePush(appID: String, subAppIDs: [String]) {
        
    }
    
    func updateAppBadge(appID: String, appType: LarkOPInterface.AppBadgeAppType, extra: LarkOPInterface.UpdateBadgeRequestParameters?, completion: ((LarkOPInterface.UpdateAppBadgeNodeResponse?, Error?) -> Void)?) {
        let result = UpdateAppBadgeNodeResponse(code: .codeSuccess, msg: "mock success")
        completion?(result, nil)
    }
    
    func pullAppBadge(appID: String, appType: LarkOPInterface.AppBadgeAppType, extra: LarkOPInterface.PullBadgeRequestParameters?, completion: ((LarkOPInterface.PullAppBadgeNodeResponse?, Error?) -> Void)?) {
        let result = PullAppBadgeNodeResponse(noticeNodes: [])
        completion?(result, nil)
    }
}
