//
//  InterfaceExtensions.swift
//  LarkAccount
//
//  Created by liuwanlin on 2018/11/25.
//

import Foundation
import RxSwift
import LarkAccountInterface
import LarkEnv
import LarkReleaseConfig

extension Launcher: AccountServiceCore { // user:checked

    // MARK: - 5.2 新帐号模型接口，对外推荐使用

    var foregroundUser: User? { // user:current
        return userManager.foregroundUser?.makeUser() // user:current
    }

    var foregroundUserObservable: Observable<User?> { // user:current
        return userManager.foregroundUserObservable.map { $0?.makeUser() } // user:current
    }

    var userList: [User] {
        return userManager.getUserList().map { $0.makeUser() }
    }

    var activeUserList: [User] {
        return userManager.getActiveUserList().map { $0.makeUser() }
    }

    var menuUserListObservable: Observable<[User]> {
        return userManager.userListObservable.map { $0.makeUserList() }
    }

    /// 等同于 foregroundUser.tenant
    var foregroundTenant: Tenant? {
        return foregroundUser?.tenant // user:current
    }
    
    /// 外部获取 suiteSessionKeyWithDomains 的唯一接口
    var sessionKeyWithDomains: [String: [String : String]]? {
        guard let foregroundUser = userManager.foregroundUser else { // user:current
            Self.logger.info("n_action_interface_extension_sessionKeyWithDomains", body: "foreground user is nil")
            return nil
        }
        
        guard let sessionKeyWithDomains = foregroundUser.suiteSessionKeyWithDomains else { // user:current
            Self.logger.warn("n_action_interface_extension_sessionKeyWithDomains", body: "domainsWithSession is nil")
            return nil
        }
        
        var domainsWithSession = ""
        for (domain, value) in sessionKeyWithDomains {
            domainsWithSession.append(contentsOf: " \(domain) : \(value["value"]?.desensitized() ?? "null"), ")
        }
        Self.logger.info("n_action_interface_extension_sessionKeyWithDomains", body: "content: \(domainsWithSession)")
        
        return sessionKeyWithDomains
    }

    /// 等同于 userList map tenant
    var tenantList: [Tenant] {
        return userList.map { $0.tenant }
    }

    // MARK: - 5.7 MultiGeo 新增接口

    var foregroundTenantBrand: TenantBrand {
        // MultiGeo Updated
        return envManager.tenantBrand
    }

    var isFeishuBrand: Bool {
        return foregroundTenantBrand == .feishu
    }

    var foregroundUserUnit: String { // user:current
        if let foregroundUser = foregroundUser, let unit = foregroundUser.userUnit { // user:current
            return unit
        }
        // MultiGeo Updated
        // 当没有前台用户时，根据包决定
        return envManager.env.unit
    }

    var foregroundUserGeo: String { // user:current
        if let foregroundUser = foregroundUser { // user:current
            return foregroundUser.geo // user:current
        }
        // MultiGeo Updated
        // 当没有前台用户时，根据包决定
        return envManager.env.geo
    }

    /// 当前前台用户 geo (地理归属地) 是否为中国大陆地区，语义上等于国内用户
    var isChinaMainlandGeo: Bool {
        return EnvManager.validateCountryCodeIsChinaMainland(foregroundUserGeo) // user:current
    }

    // MARK: - 以下 5.2 前原有接口

    var currentAccountInfo: Account {
        if let user = userManager.foregroundUser { // user:current
            return user.makeAccount()
        }

        // placeholderAccount 逻辑将在之后被移除
        Self.logger.warn("n_action_interface_extension_current_account_info_nil", method: .local)
        return UserManager.placeholderUser.makeAccount()
    }

    var conf: PassportConfProtocol {
        return PassportConf.shared
    }

    var `switch`: PassportSwitchProtocol {
        return PassportSwitch.shared
    }

    var currentAccountIsEmpty: Bool {
        return userManager.foregroundUser == nil // user:current
    }

    // TODO: 梳理使用方，将被废弃
    var currentAccountObservable: Observable<Account> {
        return userManager.foregroundUserObservable.map { $0?.makeAccount() ?? UserManager.placeholderUser.makeAccount() } // user:current
    }

    // TODO: 梳理使用方，将被废弃
    var accountChangedObservable: Observable<Account?> {
        return userManager.foregroundUserObservable.map { $0?.makeAccount() ?? UserManager.placeholderUser.makeAccount() } // user:current
    }

    // TODO: 梳理使用方，将被废弃
    var currentUserTypeObservable: Observable<AccountUserType> {
        let value = userManager.foregroundUser?.makeUser().type ?? UserManager.placeholderUser.makeUser().type // user:current
        let userType = Account.userTypeFromPassportUserType(value)
        return BehaviorSubject<AccountUserType>(value: userType).asObservable()
    }

    var accounts: [Account] {
        return userManager.userListRelay.value.map { $0.makeAccount() }
    }

    var accountsObservable: Observable<[Account]> {
        return userManager.userListObservable.map { $0.map { $0.makeAccount() } }
    }

    // TODO: 梳理使用方，将被废弃
    // 新账号模型下使用 userList
    var userListObservable: Observable<AccountUserList> {
        let accounts = userManager.userListRelay.value.map { $0.makeAccount() }
        let accountUserList = AccountUserList(normal: accounts, pending: [])
        return BehaviorSubject<AccountUserList>(value: accountUserList).asObservable()
    }

    func updateOnLaunchGuide(_ onLaunchGuide: Bool) {
        self.onLaunchGuide = onLaunchGuide
    }

    var deviceService: DeviceService {
        PassportDeviceServiceWrapper.shared
    }
    
    func subscribeStatusBarInteraction() {
        FetchClientLogHelper.subscribeStatusBarInteraction()
    }
    
    func unsubscribeStatusBarInteraction() {
        FetchClientLogHelper.unsubscribeStatusBarInteraction()
    }
   
    func fetchClientLog(completion: @escaping (ClientLogShareViewController?) -> Void) {
        FetchClientLogHelper.fetchClientLog(completion: completion)
    }

    #if DEBUG || BETA || ALPHA
    func getNetworkInfoItem() -> [LarkAccountInterface.NetworkInfoItem] {
        NetworkDebugInfoHelper.shared.itemList
    }
    #endif
}
