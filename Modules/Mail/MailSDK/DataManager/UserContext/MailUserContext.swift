//
//  MailUserContext.swift
//  MailSDK
//
//  Created by Quanze Gao on 2022/10/31.
//

import Foundation
import LarkContainer
import LarkAppConfig
import LKCommonsLogging
import LKCommonsTracker
import LarkAccountInterface
import EENavigator

/// Mail 内与 Lark 用户绑定的上下文容器
public final class MailUserContext: MailSharedServicesProvider, MailEditorLoaderDelegate {
    static let logger = Logger.log(MailUserContext.self, category: "Module.UserContext")
    
    public var isLarkMailEnabled = false
    public let bootManager: MailBootManager

    private let resolver: UserResolver
    let sharedServices: MailSharedServices

    public init(resolver: UserResolver) throws {
        self.resolver = resolver
        self.bootManager = MailBootManager(resolver: resolver)
        self.sharedServices = MailSharedServices(
            user: try Self.createUser(resolver: resolver),
            navigator: resolver.navigator,
            provider: ServiceProvider(resolver: resolver),
            dataService: DataService(fetcher: try resolver.resolve(assert: DataServiceProxy.self)),
            editorLoader: MailEditorLoader()
        )
        self.sharedServices.editorLoader.delegate = self
        /// 过渡兼容逻辑
        Store.editorLoader = self.sharedServices.editorLoader
    }

    /// TODO: 邮箱账号隔离
    func getCurrentAccountContext() -> MailAccountContext {
        let context = MailAccountContext(mailAccount: Store.settingData.getCachedCurrentAccount(),
                           sharedServices: sharedServices)
        context.isLarkMailEnabled = isLarkMailEnabled
        return context
    }
    
    func getAccountContext(accountID: String?) -> MailAccountContext? {
        guard let id = accountID else { return nil }
        if let account = Store.settingData.getCachedAccountList()?.first(where: { $0.mailAccountID == id }) {
            let context = MailAccountContext(mailAccount: account, sharedServices: sharedServices)
            context.isLarkMailEnabled = isLarkMailEnabled
            return context
        } else {
            return nil
        }
    }
    
    func getAccountContextOrCurrent(accountID: String?) -> MailAccountContext {
        if let context = getAccountContext(accountID: accountID) {
            return context
        } else {
            return getCurrentAccountContext()
        }
    }
}

private extension MailUserContext {
    static func createUser(resolver: UserResolver) throws -> User {
        let appConfig = try resolver.resolve(assert: AppConfiguration.self)
        let userService = try resolver.resolve(assert: PassportUserService.self)
        let token = userService.user.sessionKey
        let tenantId = userService.userTenant.tenantID
        let userId = resolver.userID
        let tenantName = userService.userTenant.tenantName
        let avatarKey = userService.user.avatarKey
        let isOverSea = !userService.isFeishuBrand
        var domain = ""
        if let domainPrefix = userService.user.tenant.tenantDomain {
            if let mainDomain = appConfig.mainDomains.first {
                domain = "\(domainPrefix).\(mainDomain)"
            } else {
                let msg = "mail construct userDomain get nil mainDomain"
                Self.logger.error(msg)
                assertionFailure(msg)
            }
        } else {
            let msg = "AppConfiguration have not inject"
            Self.logger.error(msg)
            Tracker.post(TeaEvent("mail_stability_assert", params: ["message": msg]))
            assertionFailure(msg)
        }
        return User(userInfo: (userId, tenantId, tenantName, token, isOverSea, avatarKey), domain: domain)
    }
}
