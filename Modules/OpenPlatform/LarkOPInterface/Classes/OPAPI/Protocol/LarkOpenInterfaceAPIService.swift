//
//  LarkOpenAPIService.swift
//  LarkOPInterface
//
//  Created by ByteDance on 2023/8/29.
//

import Foundation

@objc
public protocol LarkOpenAPIService: NSObjectProtocol {
    
    func enterBot(botID: String, from: UINavigationController?)
    
    func enterChat(chatID: String, showBadge: Bool, from: UINavigationController?)
    
    func enterProfile(userID: String, from: UINavigationController?)
    
    @objc
    func chooseContact(config: ChooseContactConfig, sourceVC: UIViewController, presentCompletion: @escaping (() -> Void), selectedNameCompletion: @escaping ([String]?, [String]?, [String]?) -> (() ->Void)?)
    
    func chooseChat(config: ChooseChatConfig)
    
    func getChatInfo(chatID: String) -> [AnyHashable: Any]?
    
    func getAtInfo(chatID: String, block: @escaping (([String: Any]?) -> Void))

    
    func getUserInfoEx(successBlock: @escaping (([String: Any]) -> Void), failBlock: @escaping (() -> Void))
    
    func onServerBadgePush(appID: String, subAppIDs: [String], completion: @escaping ((AppBadgeNode) -> Void))
    
    func offServerBadgePush(appID: String, subAppIDs: [String])
    
    func updateAppBadge(appID: String, appType: AppBadgeAppType, extra: UpdateBadgeRequestParameters?, completion: ((UpdateAppBadgeNodeResponse?, Error?) -> Void)?)
    
    func pullAppBadge(appID: String, appType: AppBadgeAppType, extra: PullBadgeRequestParameters?, completion: ((PullAppBadgeNodeResponse?, Error?) -> Void)?)
    
}

@objc
public class ChooseContactConfig: NSObject {
    public var multi: Bool
    public var ignore: Bool
    public var externalContact: Bool
    public var enableExternalSearch: Bool?
    public var showRelatedOrganizations: Bool?
    public var enableChooseDepartment: Bool
    public var selectedUserIDs: [String]?
    public var hasMaxNum: Bool?
    public var maxNum: Int
    public var limitTips: String?
    public var disableIds: [String]?
    public var exEmployeeFilterType: String?
    
    @objc
    public convenience init(externalContact: Bool) {
        self.init(multi: true, ignore: false, externalContact: externalContact, enableChooseDepartment: false, maxNum: 0)
        
    }
    
    public init(multi: Bool, ignore: Bool, externalContact: Bool, enableExternalSearch: Bool? = nil, showRelatedOrganizations: Bool? = nil, enableChooseDepartment: Bool, selectedUserIDs: [String]? = nil, hasMaxNum: Bool? = false, maxNum: Int, limitTips: String? = nil, disableIds: [String]? = nil, exEmployeeFilterType: String? = nil) {
        self.multi = multi
        self.ignore = ignore
        self.externalContact = externalContact
        self.enableExternalSearch = enableExternalSearch
        self.showRelatedOrganizations = showRelatedOrganizations
        self.enableChooseDepartment = enableChooseDepartment
        self.selectedUserIDs = selectedUserIDs
        self.hasMaxNum = hasMaxNum
        self.maxNum = maxNum
        self.limitTips = limitTips
        self.disableIds = disableIds
        self.exEmployeeFilterType = exEmployeeFilterType
    }
}

@objc
public class ChooseChatConfig: NSObject {
    
    public var params: [String: Any]
    public var title: String
    public var selectType: Int
    public var window: UIWindow?
    public var fromVC: UIViewController
    public var completion: (([String: Any]?, Bool) -> Void)?
    
    public init(params: [String: Any], title: String, selectType: Int, window: UIWindow?, fromVC: UIViewController, completion: (([String: Any]?, Bool) -> Void)? = nil) {
        self.params = params
        self.title = title
        self.selectType = selectType
        self.window = window
        self.fromVC = fromVC
        self.completion = completion
    }
}
