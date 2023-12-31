//
//  LaunchGuideService.swift
//  Action
//
//  Created by Miaoqi Wang on 2019/5/19.
//

import UIKit
import Foundation
import RxSwift
import LarkContainer
import LarkUIKit
import LarkAppConfig
import LKCommonsLogging
import Swinject
import LarkReleaseConfig
import LarkKAFeatureSwitch
import LarkAccountInterface
import LarkStorage
import LarkSetting
import LKCommonsTracker
import UniverseDesignTheme

typealias I18N = BundleI18n.LKLaunchGuide

final class LaunchGuideServiceImpl: LaunchGuideService {

    static let logger = Logger.log(LaunchGuideServiceImpl.self, category: "LaunchGuideServiceImpl")
    /// other user default will be delete while force logout with clearData=true
    private var guideView: LaunchNewGuideView?
    private let config: LaunchGuideConfigProtocol
    private let resolver: Resolver
    private var itemNameToScroll: String?

    @Provider private var accountService: AccountServiceUG
    private lazy var globalStore = KVStores.LaunchGuide.global()

    private var didShow: Bool {
        return globalStore[KVKeys.LaunchGuide.show]
    }

    init(config: LaunchGuideConfigProtocol, resolver: Resolver) {
        self.config = config
        self.resolver = resolver
    }

    func willSkip(showGuestGuide: Bool) -> Bool {
        if !FeatureSwitch.share.bool(for: .launchGuide) {
            return true
        }
        return self.didShow && !showGuestGuide
    }

    func checkShowGuide(window: UIWindow?, showGuestGuide: Bool) -> Observable<LaunchAction> {
        return Observable.create { (observer) -> Disposable in
            if self.willSkip(showGuestGuide: showGuestGuide) {
                observer.onNext(.skip)
                observer.onCompleted()
            } else {
                Tracker.trackV3EnterGuidePage()
                self.showLaunchGuideVC(window, observer: observer)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                    if showGuestGuide {
                        self.presentGuestVC(window, observer: observer)
                    }
                }
            }
            return Disposables.create()
        }
    }

    func tryScrollToItem(name: String) -> Bool {
        itemNameToScroll = name
        return false
    }

    private func markShowLaunchGuide() {
        globalStore[KVKeys.LaunchGuide.show] = true
    }

    private func showLaunchGuideVC(_ window: UIWindow?, observer: AnyObserver<LaunchAction>) {
        let isDark: Bool = {
            if #available(iOS 13.0, *) {
                return UDThemeManager.getRealUserInterfaceStyle() == .dark
            } else {
                return false
            }
        }()
        let view = LaunchNewGuideView(frame: window?.bounds ?? UIScreen.main.bounds,
                                      isLark: ReleaseConfig.isLark,
                                      isDark: isDark)
        self.guideView = view
        view.signupAction = { [weak self] in
            self?.markShowLaunchGuide()
            observer.onNext(.createTeam)
            observer.onCompleted()
            Tracker.trackCreateTeamClick(index: 0)
            Tracker.trackV3RegisterGuidePage()
            /// 新埋点，注册按钮点击
            CommonsTracker.post(TeaEvent(
                "passport_landing_page_click",
                params: [
                         "click": "register",
                         "passport_appid": LarkAppID.lark,
                         "tracking_code": "none",
                         "template_id": "none",
                         "utm_from": "none"]
            ))
        }
        view.loginAction = { [weak self] in
            self?.markShowLaunchGuide()
            observer.onNext(.login)
            observer.onCompleted()
            Tracker.trackSignInClick(index: 0)
            Tracker.trackV3LoginGuidePage()
            /// 新埋点，登录按钮点击
            CommonsTracker.post(TeaEvent(
                "passport_landing_page_click",
                params: [
                         "click": "login",
                         "passport_appid": LarkAppID.lark,
                         "tracking_code": "none",
                         "template_id": "none",
                         "utm_from": "none"]
            ))
        }

        if ReleaseConfig.isFeishu {
            if ReleaseConfig.isKA {
                // KA 注册按钮通过settings配置控制，默认不显示
                self.guideView?.showSignButton = getSignUpEnableFromSettings() ?? false
            } else {
                accountService.getABTestValueForUGRegist { [weak view] enableUGRegist in
                    guard let launchGuideView = view else {
                        return
                    }
                    /// 开启UG的注册，则隐藏注册按钮
                    /// 只有确定收到不
                    launchGuideView.showSignButton = !enableUGRegist
                }
            }
        } else {
            if ReleaseConfig.isKA {
                // KA 注册按钮通过settings配置控制，默认不显示
                self.guideView?.showSignButton = getSignUpEnableFromSettings() ?? false
            } else {
                // 海外不走AB,默认展示按钮
                self.guideView?.showSignButton = true
            }
        }
        window?.rootViewController = LaunchGuideViewController(launchGuideView: view)
    }

    private func presentGuestVC(_ window: UIWindow?, observer: AnyObserver<LaunchAction>) {
        let guestVC = GuestGuideViewController()
        guestVC.modalPresentationStyle = .fullScreen
        guestVC.closeAction = { [weak guestVC] in
            guestVC?.dismiss(animated: true, completion: nil)
        }

        guestVC.startAction = { [weak guestVC] in
            guestVC?.dismiss(animated: true, completion: {
                observer.onNext(.createTeam)
                observer.onCompleted()
            })
        }

        window?.rootViewController?.present(guestVC, animated: true, completion: nil)
    }
    
    private func getSignUpEnableFromSettings() -> Bool? {
        return try? SettingManager.shared.setting(with: UserSettingKey.make(userKeyLiteral: "passport_view_display_enable"))["login_enable_create_entry"] as? Bool
    }
}
