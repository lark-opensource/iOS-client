//
//  PassportAppLinkRegistry.swift
//  PassportDebug
//
//  Created by Bytedance on 2022/12/5.
//

import Foundation

#if DEBUG || BETA || ALPHA
import LarkEnv
import EENavigator
import LarkStorage
import LarkContainer
import LarkAppLinkSDK
import LKCommonsLogging
import UniverseDesignToast
import LarkAccountInterface

/// 注册一些在Debug环境才能生效的AppLink，目前注册的如下：
/// 1. https://bytedance.feishu.cn/docx/D9v8dyDGaogGw5x9WddcEjYKnqe
@objc public final class PassportAppLinkRegistry: NSObject {
    private static let logger = Logger.log(PassportAppLinkRegistry.self, category: "PassportAppLinkRegistry")

    @objc static public func regist() {
        PassportAppLinkRegistry.logger.info("PassportAppLinkRegistry regist")
        // 切换环境
        PassportAppLinkRegistry.logger.info("applink register /client/qa/env")
        LarkAppLinkSDK.registerHandler(path: "/client/qa/env") { appLink in
            PassportAppLinkRegistry.logger.info("handle applink /client/qa/env")
            if let windowView = Navigator.shared.mainSceneWindow?.rootViewController?.view {
                UDToast.showTips(with: "获取要切换的环境...", on: windowView)
            }
            // 拼接得到Env
            guard let e = appLink.url.queryParameters["e"] as? String, !e.isEmpty else { return }
            let type: Env.TypeEnum = (e == "boe") ? .staging : (e == "pre" ? .preRelease : .release )
            guard let unit = appLink.url.queryParameters["u"] as? String, !unit.isEmpty else { return }
            let unitGeoMap = ["eu_nc": "cn", "eu_ea": "us", "larksgaws": "sg", "boecn": "boe-cn", "boeva": "boe-us"]
            guard let geo = unitGeoMap[unit] as? String, !geo.isEmpty else { return }
            let env = Env(unit: unit, geo: geo, type: type)

            // 如果要切换的环境和当前环境一样，则不需要进行任何操作
            guard env != EnvManager.env else {
                if let windowView = Navigator.shared.mainSceneWindow?.rootViewController?.view {
                    UDToast.showTips(with: "与当前环境一致，不进行切换操作", on: windowView)
                }
                return
            }
            if let windowView = Navigator.shared.mainSceneWindow?.rootViewController?.view {
                UDToast.showTips(with: "环境切换...", on: windowView)
            }
            // 进行环境切换操作，copy from SwitchDevDebugItem
            var exitSel: Selector { Selector(["terminate", "With", "Success"].joined()) }
            if AccountServiceAdapter.shared.isLogin {
                AccountServiceAdapter.shared.relogin(conf: .debugSwitchEnv, onError: { _ in }, onSuccess: {
                    if let windowView = Navigator.shared.mainSceneWindow?.rootViewController?.view {
                        UDToast.showTips(with: "环境切换成功", on: windowView)
                    }
                    // brand：品牌feishu/lark，无切换需求
                    SwitchDevDebugController.switchDevEnv(env, brand: AccountServiceAdapter.shared.foregroundTenantBrand.rawValue)
                }, onInterrupt: { })
            } else {
                if let windowView = Navigator.shared.mainSceneWindow?.rootViewController?.view {
                    UDToast.showTips(with: "环境切换成功", on: windowView)
                }
                // brand：品牌feishu/lark，无切换需求
                SwitchDevDebugController.switchDevEnv(env, brand: AccountServiceAdapter.shared.foregroundTenantBrand.rawValue)
            }
        }

        // 自动登录
        PassportAppLinkRegistry.logger.info("applink register /client/qa/passport/login")
        LarkAppLinkSDK.registerHandler(path: "/client/qa/passport/login") { appLink in
            PassportAppLinkRegistry.logger.info("handle applink /client/qa/passport/login")
            // 得到account、password、userId参数
            guard let account = appLink.url.queryParameters["account"] as? String, !account.isEmpty else { return }
            guard let password = appLink.url.queryParameters["password"] as? String, !password.isEmpty else { return }
            let userId = appLink.url.queryParameters["user_id"] as? String

            // 先退出登录，再登录
            if let windowView = Navigator.shared.mainSceneWindow?.rootViewController?.view {
                UDToast.showTips(with: "退出登录...", on: windowView)
            }
            LogoutHandler().logout {
                if let windowView = Navigator.shared.mainSceneWindow?.rootViewController?.view {
                    UDToast.showTips(with: "退出登录成功", on: windowView)
                }
                // 隔2s保证此时已经到了登陆界面
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    AutoLoginHandler(account: account, password: password, userId: userId).autoLogin(onSuccess: {})
                }
            }
        }

        // 退出登录
        PassportAppLinkRegistry.logger.info("applink register /client/qa/passport/logout")
        LarkAppLinkSDK.registerHandler(path: "/client/qa/passport/logout") { appLink in
            PassportAppLinkRegistry.logger.info("handle applink /client/qa/passport/logout")
            if let windowView = Navigator.shared.mainSceneWindow?.rootViewController?.view {
                UDToast.showTips(with: "退出登录...", on: windowView)
            }
            LogoutHandler().logout {
                if let windowView = Navigator.shared.mainSceneWindow?.rootViewController?.view {
                    UDToast.showTips(with: "退出登录成功", on: windowView)
                }
            }
        }
    }
}

/// 因为需要从容器里拿到Service，所以需要搞个class，通过InjectedSafeLazy拿
final class AutoLoginHandler {
    @InjectedSafeLazy private var autoLoginService: AutoLoginService
    private let account: String
    private let password: String
    private let userId: String?

    init(account: String, password: String, userId: String?) {
        self.account = account
        self.password = password
        self.userId = userId
    }

    /// 账号登陆 -> 密码登陆 -> 切换租户
    func autoLogin(onSuccess: @escaping () -> Void) {
        self.autoLoginService.autoLogin(account: self.account, password: self.password, userId: self.userId, onSuccess: onSuccess)
    }
}

/// 因为需要从容器里拿到Service，所以需要搞个class，通过InjectedSafeLazy拿
final class LogoutHandler {
    @InjectedSafeLazy private var passportService: PassportService

    /// 退出登陆，不自动切换到下一个租户
    func logout(onSuccess: @escaping () -> Void) {
        if !AccountServiceAdapter.shared.isLogin {
            onSuccess()
            return
        }
        // conf：toLogin强制退出到登陆界面
        self.passportService.logout(conf: .toLogin, onInterrupt: {}, onError: { _ in }, onSuccess: { _, _ in onSuccess() }, onSwitch: { _ in })
    }
}
#endif
