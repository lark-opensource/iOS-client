//
//  WidgetAccountTaskDelegate.swift
//  Lark
//
//  Created by ZhangHongyun on 2020/12/6.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import Swinject
import RxSwift
import LarkAccountInterface

protocol WidgetAccountDelegateService: LauncherDelegate {}

/// 账号状态监听
final class WidgetAccountTaskDelegate: WidgetAccountDelegateService {
    public let name: String = "WidgetAccountTaskDelegate"

    /// 登录成功（切换租户不触发）
    func afterLoginSucceded(_ context: LauncherContext) {
        LarkWidgetService.share.applicationDidLogin()
    }

    /// 切换账号/租户
    func afterSwitchSetAccount(_ account: Account) {
        LarkWidgetService.share.applicationDidSwitchAccount()
    }

    /// 退出登录
    public func afterLogout(_ context: LauncherContext) {
        LarkWidgetService.share.applicationDidLogout()
    }
}
