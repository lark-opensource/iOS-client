//
//  LoginCenter.swift
//  LarkSendMessage-Unit-Tests
//
//  Created by 李勇 on 2022/12/14.
//

import Foundation
import LarkContainer // InjectedSafeLazy
import LarkAccountInterface // AutoLoginService

// MARK: - 自动登陆模块
class AutoLoginHandler {
    /// 测试账号：https://bytedance.feishu.cn/docx/VThDdraRioYcltxHCO7cFlxRnRd
    struct Account {
        let account = "12342339640"
        let password = "test123456"
        let userId = "7112332912338452481"
    }
    @InjectedSafeLazy private var autoLoginService: AutoLoginService
    @InjectedSafeLazy private var passportUserService: PassportUserService
    /// 目前CI单测耗时很长，一部分原因是autoLogin导致的，外部调用了autoLogin则至少会延迟10s再执行单测
    /// 优化点：如果不需要登陆，则只在第一次等待30s，后续可以直接开始执行单测
    private static var isFirstColdLaunch: Bool = true

    /// 如果当前未登陆/不是指定用户，则进行自动登陆
    func autoLogin(account: Account = Account(), onSuccess: @escaping () -> Void) {
        // 如果当前已登陆，并且user_id和目标user_id一致，则不进行登陆处理
        if passportUserService.user.userStatus == .normal, AccountServiceAdapter.shared.currentChatterId == account.userId {
            DispatchQueue.main.asyncAfter(deadline: .now() + (AutoLoginHandler.isFirstColdLaunch ? 30 : 1)) { onSuccess() }
            AutoLoginHandler.isFirstColdLaunch = false
            return
        }

        // 先退出登录
        LogoutHandler().logout {
            // 再进行登录
            self.autoLoginService.autoLogin(account: account.account, password: account.password, userId: account.userId) {
                // 延迟10s再回调，保障CPU尽量空闲
                DispatchQueue.main.asyncAfter(deadline: .now() + 30) { onSuccess() }
                AutoLoginHandler.isFirstColdLaunch = false
            }
        }
    }
}

// MARK: - 自动退出模块
class LogoutHandler {
    @InjectedSafeLazy private var passportService: PassportService

    /// 退出登陆，不自动切换到下一个租户
    func logout(onSuccess: @escaping () -> Void) {
        if !AccountServiceAdapter.shared.isLogin {
            onSuccess()
            return
        }
        // conf：toLogin强制退出到登陆界面
        self.passportService.logout(conf: .toLogin, onInterrupt: {}, onError: { _ in }, onSuccess: { _, _ in
            // 延迟2s再回调，保障一些清理工作尽量完成
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { onSuccess() }
        }, onSwitch: { _ in })
    }
}
