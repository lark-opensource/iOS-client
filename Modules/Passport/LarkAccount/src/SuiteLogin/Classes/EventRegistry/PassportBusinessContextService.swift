//
//  PassportBusinessContextService.swift
//  SuiteLogin
//
//  Created by tangyunfei.tyf on 2020/8/31.
//

import Foundation
import LKCommonsLogging
import LarkContainer

enum PassportBusinessContext: String {
//    case loginRegister
    case joinTeam
    case accountManage
    case accountAppeal

    /// 启动时登录或注册，本地没有用户身份
    case outerLoginOrRegister

    /// 端内登录或注册，目前从「+」入口触发，已有用户身份
    case innerLoginOrRegister

    /// 切换用户
    case switchUser
}

class PassportBusinessContextService: NSObject {

    static let logger = Logger.log(PassportBusinessContextService.self, category: "SuiteLogin.PassportBusinessContextService")
    static let shared = PassportBusinessContextService()
    
    public private(set) var currentContext: PassportBusinessContext
    
    @Provider var userManager: UserManager

    override init() {
        self.currentContext = .outerLoginOrRegister
        super.init()
    }

    func triggerChange(_ context: PassportBusinessContext) {
        Self.logger.info("PassportBusinessContext was set to be \(context)", method: .local)
        currentContext = context
    }

}
