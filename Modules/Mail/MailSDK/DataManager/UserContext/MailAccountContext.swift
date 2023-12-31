//
//  MailAccountContext.swift
//  MailSDK
//
//  Created by Quanze Gao on 2022/11/2.
//

import Foundation
import LarkContainer
import LarkAppConfig
import LKCommonsLogging
import LKCommonsTracker
import LarkAccountInterface
import EENavigator

/// 与邮箱账号绑定的上下文容器
/// TODO: 暂时只做占位类，待补充邮箱账号逻辑
final class MailAccountContext: MailSharedServicesProvider {
    static let logger = Logger.log(MailUserContext.self, category: "Module.AccountContext")

    var isLarkMailEnabled = false
    var mailAccount: MailAccount?
    let accountKVStore: MailKVStore
    let sharedServices: MailSharedServices
    var accountID: String {
        mailAccount?.mailAccountID ?? ""
    }
    
    public init(mailAccount: MailAccount?, sharedServices: MailSharedServices) {
        self.mailAccount = mailAccount
        let space: MSpace = {
            if let accountID = mailAccount?.mailAccountID {
                return .account(id: accountID)
            } else {
                return .global
            }
        }()
        self.accountKVStore = MailKVStore(space: .user(id: sharedServices.user.userID), mSpace: space)
        self.sharedServices = sharedServices
    }
}
