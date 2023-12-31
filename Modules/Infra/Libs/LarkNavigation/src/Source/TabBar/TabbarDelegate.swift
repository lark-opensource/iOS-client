//
//  TabbarDelegate.swift
//  Lark
//
//  Created by liuwanlin on 2018/11/27.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkFoundation
import LarkRustClient
import LarkUIKit
import RxSwift
import Swinject
import LarkAlertController
import EENavigator
import UniverseDesignToast
import LarkAccountInterface
import SnapKit
import RxCocoa
import Homeric
import LarkPerf
import RunloopTools
import LarkFeatureGating
import LKCommonsLogging
import AnimatedTabBar
import LarkTab

public final class TabbarDelegate: TabBarLauncherDelegateService {
    static let logger = Logger.log(TabbarDelegate.self, category: "Module.TabBarDelegate")
    public let name: String = "Tabbar"

    private let resolver: Resolver
    private var preLauncheHomeDisposeBag = DisposeBag()
    private var timer: DispatchSourceTimer?
    private var hud: UDToast?
    private let showHudTimeInterval = 0.2

    init(resolver: Resolver) {
        self.resolver = resolver
    }

    public func afterLogout(context: LauncherContext, conf: LogoutConf) {
        if conf.destination != .switchUser {
            RunloopDispatcher.shared.clearUserScopeTask()
            RootNavigationController.shared.clear()
            TabRegistry.clear()
        }
    }

//    public func beforeSwitchAccout() {
//        hud = RoundedHUD()
//        ClientPerf.shared.startSlardarEvent(service: "tenant_switch_cost", logid: Homeric.EESA_TENANT_SWITCH_COST)
//        timer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.global())
//        timer?.schedule(deadline: .now() + showHudTimeInterval, leeway: DispatchTimeInterval.milliseconds(0))
//        timer?.setEventHandler { [weak self] in
//            DispatchQueue.main.async {
//                // 额外生成RoundedHUB，防止和其他模块Loading或者Toast冲突
//                self?.hud?.showLoading(
//                    with: BundleI18n.LarkNavigation.Lark_Setting_SwitchUserLoadingTip,
//                    on: RootNavigationController.shared.view.window ?? Navigator.shared.mainSceneWindow ?? RootNavigationController.shared.view,
//                    disableUserInteraction: true
//                )
//            }
//        }
//        timer?.resume()
//    }

    public func beforeSwitchSetAccount(_ account: LarkAccountInterface.Account) {
        RootNavigationController.shared.tabbar?.reset()
    }

    public func afterSwitchAccout(error: Error?) -> Observable<Void> {
        ClientPerf.shared.endSlardarEvent(service: "tenant_switch_cost", logid: Homeric.EESA_TENANT_SWITCH_COST)
        TabbarDelegate.logger.info("Switch account complete.", additionalData: ["hasError": "\(error != nil)"])
        if let error = error {
            return handleSwitchAccountError(error)
        } else {
            // 切换账户成功，清空Task
            RunloopDispatcher.shared.clearUserScopeTask()
            TabRegistry.clear()
            return .just(())
        }
    }

    public func removeHud() {
        timer?.cancel()
        timer = nil
        hud?.remove()
        hud = nil
    }

    private func handleSwitchAccountError(_ error: Error) -> Observable<Void> {
        TabbarDelegate.logger.error("Switch account with error.", error: error)
        SwitchUserMonitor.shared.update(step: .loadFinish)
        removeHud()
        switch error {
        case let error as RCError:
            // 被暂停使用
            if case let .businessFailure(errorInfo) = error, errorInfo.code == 10_015 {
                let alertController = LarkAlertController()
                alertController.setContent(text: BundleI18n.LarkNavigation.Lark_Legacy_SwitchAccountToCNotRegistedContent, font: .systemFont(ofSize: 14))
                alertController.setTitle(text: BundleI18n.LarkNavigation.Lark_Legacy_SwitchAccountToCNotRegisted)
                alertController.addPrimaryButton(text: BundleI18n.LarkNavigation .Lark_Legacy_Sure)
                Navigator.shared.present(alertController, from: RootNavigationController.shared)
            }
        case let error as AccountError:
            if case let .suiteLoginError(errorMessage) = error {
                hud = UDToast.showTipsOnScreenCenter(with: errorMessage, on: RootNavigationController.shared.view)
            }
        default: break
        }
        return .just(())
    }
}
