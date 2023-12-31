//
//  SetupMainTabTask.swift
//  LarkNavigation
//
//  Created by KT on 2020/7/1.
//

import UIKit
import Foundation
import BootManager
import LarkPerf
import LarkContainer
import LarkAccountInterface
import LKCommonsLogging
import LarkUIKit
import LarkSceneManager
import LarkFeatureGating
import LarkStorage
import LarkLocalizations

final class SetupMainTabTask: UserFlowBootTask, Identifiable {
    static var identify = "SetupMainTabTask"

    static let logger = Logger.log(SetupMainTabTask.self)

    override var runOnlyOnceInUserScope: Bool { return false }

    override func execute(_ context: BootContext) {
        // 发通知清除BundleI18n中_tableMap,解决动态资源切换不生效
        LanguageManager.resetLanguage()
        NewBootManager.shared.addSerialTask {
            self.subscribeTimezoneNotification()
        }
        SwitchUserMonitor.shared.end(key: .toGetOnboarding)
        SwitchUserMonitor.shared.start(key: .toMainRender)

        let accountService = AccountServiceAdapter.shared
        if !accountService.isLogin {
            TabbarDelegate.logger.error("launch home root view controller cancel for unlogin")
            NewBootManager.shared.login()
            return
        }
        TabbarDelegate.logger.info("launch home root view controller")

        var home: UIViewController = UIViewController()
        if #available(iOS 13.0, *),
           let scene = context.scene,
           let session = context.session,
           let options = context.connectionOptions,
           let window = context.window,
           let vc = SceneManager.shared.sceneViewController(
                scene: scene, session: session, options: options, window: window
            ) {
            home = vc
        } else if let window = context.window,
                  let vc = SceneManager.shared.createMainSceneRootVC(on: window) {
            home = vc
        } else {
            assertionFailure()
        }

        if context.isSwitchAccount,
           !context.isRollbackSwitchUser,
            let contextWindow = context.window {
            let tab = LauncherDelegateRegistery.resolver(TabbarDelegate.self)
            UIView.transition(with: contextWindow, duration: 0.5, options: .transitionFlipFromLeft, animations: {
                context.window?.rootViewController = home
            }, completion: { _ in
                tab?.removeHud()
            })
            tab?.removeHud()
            SwitchUserMonitor.shared.update(step: .loadFinish)
        } else {
            if let previewVC = context.window?.rootViewController {
                let view = previewVC.view
                previewVC.dismiss(animated: false) {
                    // 有可能旧root和新root是同一个VC(RootNavigationController.shared)，避免根View被意外移除
                    if view != context.window?.rootViewController?.view {
                        view?.removeFromSuperview()
                    }
                }
            }
            context.window?.rootViewController = home
        }

        let firstViewController = (home as? RootNavigationController)?.tabbar?.viewControllers?.first
        let userControlledSignal = (firstViewController as? UserControlledLaunchTransition)?.dismissSignal

        if context.isFastLogin && !context.isSwitchAccount {
            let feedBadgeStyle = KVConfig<Int?>(
                key: "feed.badge",
                store: KVStores.udkv(
                    space: .user(id: AccountServiceAdapter.shared.currentChatterId),
                    domain: Domain.biz.feed
                )
            )
            /// 如果使用了本地缓存，不需要使用蒙层盖住feed
            if feedBadgeStyle.value == nil {
                LaunchTransition.shared.add(in: home.view, userControlledSignal: userControlledSignal)
            }
        } else {
            NotificationCenter.default.post(name: .launchTransitionDidDismiss, object: nil)
        }
    }

    // 初始化RustClient后，监听系统时区通知并同步给rustClient
    private func subscribeTimezoneNotification() {
        _ = NotificationCenter.default.rx
            .notification(UIApplication.significantTimeChangeNotification)
            .subscribe(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                _ = RustAccountBadgeAPI(userResolver: self.userResolver)
                    .updateRustClientTimeZone(timeZone: TimeZone.current.identifier)
                    .subscribe()
            })
    }
}
