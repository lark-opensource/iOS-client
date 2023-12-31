//
//  PassportRedirectToSaasHandler.swift
//  LarkCreateTeam
//
//  Created by zhaoKejie on 2023/11/13.
//

import Foundation
import WebBrowser
import LarkAccountInterface
import LKCommonsLogging
import LarkContainer
import EENavigator
import LarkSetting
import JsSDK
import UniverseDesignToast

class PassportRedirectToSaasHandler: JsAPIHandler {
    static let logger = Logger.log(PassportRedirectToSaasHandler.self, category: "Module.JSSDK")

    @Provider var dependency: PassportWebViewDependency

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {

        guard enableRedirectToSaas() else {
            if let view = api.view {
                DispatchQueue.main.async {
                    UDToast.showTips(with: self.dependency.unsupportErrorTip, on: view)
                }
            }
            callback.callbackFailure(param: ["errMsg": dependency.unsupportErrorTip])
            return
        }

        let loginVC = dependency.getSaasLoginVC()

        if replaceVC(current: api, target: loginVC) {
            Self.logger.info("replace root web vc to saas native vc")
        } else {
            if api.closeVC() {
                Self.logger.info("close web vc succ")
            } else {
                Self.logger.info("close web vc fail")
            }

        }
    }

    func replaceVC(current: UIViewController, target: UIViewController) -> Bool {

        func replaceRootVC(to vc: UIViewController, on window: UIWindow) {
            DispatchQueue.main.async {
                UIView.transition(with: window, duration: 0.5, options: .transitionFlipFromLeft, animations: {
                    window.rootViewController = vc
                }, completion: nil)
            }
        }

        if let window = current.view.window,
           let rootVC = window.rootViewController {

            if current === rootVC {
                replaceRootVC(to: target, on: window)
                Self.logger.info("replace root vc to native")
                return true
            }

            if let naviVC = current.navigationController,
               let firstVC = naviVC.viewControllers.first {

                if naviVC === rootVC && current === firstVC {
                    replaceRootVC(to: target, on: window)
                    Self.logger.info("replace root navi vc to native")
                    return true
                }

            }

        }
        return false

    }

    func enableRedirectToSaas() -> Bool {
        return (try? SettingManager.shared.setting(with: UserSettingKey.make(userKeyLiteral: "passport_view_display_enable"))["login_redirect_to_saas_login"] as? Bool) ?? false
    }
}
