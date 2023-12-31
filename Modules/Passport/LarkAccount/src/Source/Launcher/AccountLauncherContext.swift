//
//  AccountLauncherContext.swift
//  LarkAccount
//
//  Created by Miaoqi Wang on 2021/3/28.
//

import Foundation
import LarkAccountInterface

class AccountLauncherContext: LauncherContext {
    /// 是否启动直接登录
    var isFastLogin: Bool = false
    
    /// 是否为统一did升级成功那次的启动
    var isDIDUpgrade: Bool = false

    /// 当前UserID
    var currentUserID: String?

    init(isFastLogin: Bool = false,
         currentUserID: String? = nil) {
        self.isFastLogin = isFastLogin
        self.currentUserID = currentUserID
    }

    @discardableResult
    func merge(userInfo: V4UserInfo, isFastLogin: Bool) -> AccountLauncherContext {
        self.isFastLogin = isFastLogin
        self.currentUserID = userInfo.userID
        return self
    }

    @discardableResult
    func merge(context: LauncherContext) -> AccountLauncherContext {
        self.isFastLogin = context.isFastLogin
        self.currentUserID = context.currentUserID
        return self
    }

    func reset() {
        self.isFastLogin = false
        self.currentUserID = nil
    }
}
