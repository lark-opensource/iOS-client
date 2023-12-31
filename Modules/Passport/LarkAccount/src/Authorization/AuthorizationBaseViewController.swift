//
//  AuthorizationBaseViewController.swift
//  LarkQRCode
//
//  Created by Miaoqi Wang on 2020/3/17.
//

import Foundation
import LarkUIKit
import RoundedHUD
import RxSwift
import LKCommonsLogging
import Homeric
import LarkContainer
import LarkFoundation
import UniverseDesignTheme
import UniverseDesignToast
import LarkSetting
import UniverseDesignDialog

typealias SSOVerifyResources = BundleResources.LarkAccount.SSOverify

class AuthorizationBaseViewController: BaseUIViewController {

    static let logger = Logger.plog(AuthorizationBaseViewController.self, category: "SuiteLogin")

    let _userResolver: UserResolver?
    var userResolver: UserResolver {
        return _userResolver ?? PassportUserScope.getCurrentUserResolver() // user:current
    }

    var authorizationPageType: String?
    
    let vm: SSOBaseViewModel
    let disposeBag = DisposeBag()
    func needBackImage() -> Bool { false }
    
    lazy var topGradientMainCircle = GradientCircleView()
    lazy var topGradientSubCircle = GradientCircleView()
    lazy var topGradientRefCircle = GradientCircleView()
    lazy var blurEffectView = UIVisualEffectView()

    init(vm: SSOBaseViewModel, resolver: UserResolver?) {
        self.vm = vm
        self._userResolver = resolver
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        guard #available(iOS 13.0, *),
            traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else {
            // 如果当前设置主题一致，则不需要切换资源
            return
        }
        
        let isDarkModeTheme = UDThemeManager.getRealUserInterfaceStyle() == .dark
        setGradientLayerColors(isDarkModeTheme: UDThemeManager.getRealUserInterfaceStyle() == .dark)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if needBackImage() {
            var isDarkModeTheme: Bool = false
            if #available(iOS 13.0, *) {
                isDarkModeTheme = UDThemeManager.getRealUserInterfaceStyle() == .dark
            }
            
            self.view.addSubview(topGradientMainCircle)
            self.view.addSubview(topGradientSubCircle)
            self.view.addSubview(topGradientRefCircle)
            topGradientMainCircle.snp.makeConstraints { (make) in
                make.left.equalTo(-40.0 / 375 * view.frame.width)
                make.top.equalTo(0.0)
                make.width.equalToSuperview().multipliedBy(120.0 / 375)
                make.height.equalToSuperview().multipliedBy(96.0 / 812)
            }
            topGradientSubCircle.snp.makeConstraints { (make) in
                make.left.equalTo(-16.0 / 375 * view.frame.width)
                make.top.equalTo(-112.0 / 812 * view.frame.height)
                make.width.equalToSuperview().multipliedBy(228.0 / 375)
                make.height.equalToSuperview().multipliedBy(220.0 / 812)
            }
            topGradientRefCircle.snp.makeConstraints { (make) in
                make.left.equalTo(150.0 / 375 * view.frame.width)
                make.top.equalTo(-22.0 / 812 * view.frame.height)
                make.width.equalToSuperview().multipliedBy(136.0 / 375)
                make.height.equalToSuperview().multipliedBy(131.0 / 812)
            }
            self.view.addSubview(blurEffectView)
            blurEffectView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
            setGradientLayerColors(isDarkModeTheme: isDarkModeTheme)
        }
        view.backgroundColor = UIColor.ud.bgLogin
        NotificationCenter.default
            .rx
            .notification(UIApplication.didEnterBackgroundNotification)
            .flatMap({ [weak self] _ -> Observable<Bool> in
                guard let `self` = self, !self.vm.confirmed else { return .just(true) }
                return self.vm.cancel(authorizationPageType: self.authorizationPageType)
            })
            .catchErrorJustReturn(true)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.dismiss(animated: true, completion: nil)
            }).disposed(by: disposeBag)
    }
    
    private func setGradientLayerColors(isDarkModeTheme: Bool) {
        topGradientMainCircle.setColors(color: UIColor.ud.rgb("#1456F0"), opacity: 0.16)
        topGradientSubCircle.setColors(color: UIColor.ud.rgb("#336DF4"), opacity: 0.16)
        topGradientRefCircle.setColors(color: UIColor.ud.rgb("#2DBEAB"), opacity: 0.10)
        blurEffectView.effect = isDarkModeTheme ? UIBlurEffect(style: .dark) : UIBlurEffect(style: .light)
    }

    func checkToken(loadingOnview: UIView? = nil, success: @escaping (LoginAuthInfo?) -> Void, failure: @escaping (Error) -> Void) {
        let hud = UDToast.showDefaultLoading(on: loadingOnview ?? self.view)
        vm.check()
            .subscribe { (authInfo) in
                hud.remove()
                success(authInfo)
            } onError: { (error) in
                hud.remove()
                failure(error)
            }.disposed(by: disposeBag)
    }

    func confirmToken(scope: String, isMultiLogin: Bool, success: @escaping () -> Void, failure: @escaping () -> Void) {
        let hud = UDToast.showDefaultLoading(on: PassportNavigator.getUserScopeKeyWindow(userResolver: userResolver) ?? self.view)
        var categoryValueMap: [String: Any] = [ProbeConst.authorizationType: vm.resolveAuthorizationType()]
        if let authorizationPageType = authorizationPageType {
            categoryValueMap[ProbeConst.authorizationPageType] = authorizationPageType
        }
        let startDate = Date()

        lazy var enableSSOManualTransferDialog: Bool = PassportGray.shared.getGrayValue(key: .enableSSOManualTransferDialog)

        PassportMonitor.flush(PassportMonitorMetaAuthorization.startAuthorizationConfirm, eventName: ProbeConst.monitorEventName, categoryValueMap: categoryValueMap, context: vm.context)
        vm.confirm(scope: scope, isMultiLogin: isMultiLogin)
            .subscribe { [weak self](jump) in
                guard let `self` = self else { return }
                hud.remove()
                var categoryValueMap = categoryValueMap
                categoryValueMap[ProbeConst.duration] = Int64(Date().timeIntervalSince(startDate) * 1000)
                if case .scheme(let url) = jump {
                    categoryValueMap[ProbeConst.scheme] = url
                }
                PassportMonitor.monitor(PassportMonitorMetaAuthorization.authorizationConfirmResult, eventName: ProbeConst.monitorEventName, categoryValueMap: categoryValueMap, context: self.vm.context).setResultTypeSuccess().flush()
                success()
                switch jump {
                case .bundleId(_):
                    // 原bundleid逻辑使用私有api，v6.1起使用url scheme跳转
                    assertionFailure("Open app via bundle id was deprecated, should use scheme.")
                    AuthorizationBaseViewController.logger.info("Open app via bundle id was deprecated, should use scheme.")
                case .scheme(let url):
                    if !enableSSOManualTransferDialog {
                        Self.logger.info("enableSSOManualTransferDialog FG Off")
                        if let url = URL(string: url) {
                            AuthorizationBaseViewController.logger.info("login auth success jump to \(url)")
                            UIApplication.shared.open(url) { (_) in
                                self.dismiss(animated: true, completion: nil)
                            }
                        } else {
                            Self.logger.errorWithAssertion("no url for scheme jump")
                            self.dismiss(animated: true, completion: nil)
                        }
                    } else {
                        Self.logger.info("enableSSOManualTransferDialog FG On")
                        let settingKey = UserSettingKey.make(userKeyLiteral: "sso_auth_auto_broswer")
                        let settingValue = try? SettingManager.shared.setting(with: settingKey)["sso_auth_auto_broswer"] as? [String] // user:checked
                        guard let settingValue = settingValue else {
                            Self.logger.errorWithAssertion("Cannot fetch valid sso_auth_auto_broswer Lark Setting")
                            self.dismiss(animated: true)
                            return
                        }
                        if settingValue.contains(url), let url = URL(string: url) {
                            PassportMonitor.flush(PassportMonitorMetaCommon.ssoTransferByAuto, eventName: ProbeConst.monitorEventName, categoryValueMap: categoryValueMap, context: self.vm.context)
                            AuthorizationBaseViewController.logger.info("login auth success jump to \(url)")
                            UIApplication.shared.open(url) { (_) in
                                self.dismiss(animated: true, completion: nil)
                            }
                        } else {
                            PassportMonitor.flush(PassportMonitorMetaCommon.ssoTransferByManual, eventName: ProbeConst.monitorEventName, categoryValueMap: categoryValueMap, context: self.vm.context)
                            Self.logger.errorWithAssertion("need manual jump")
                            let alert = UDDialog()
                            alert.setTitle(text: I18N.Lark_Legacy_Hint)
                            alert.setContent(text: I18N.Lark_Passport_WebAuthorizedThroughApp_GoToBrowserToCheckDialogue_Desc())
                            alert.addPrimaryButton(
                                text: I18N.Lark_Passport_ApprovedEmailJoinDirectly_DetailsDesc_GotItButton,
                                dismissCompletion: {
                                    self.dismiss(animated: true)
                                })
                            self.present(alert, animated: true)
                        }
                    }

                case .none(let needDismiss):
                    if needDismiss {
                        self.dismiss(animated: true, completion: nil)
                    }
                }
            } onError: { [weak self](error) in
                guard let `self` = self else { return }
                hud.remove()
                PassportMonitor.monitor(PassportMonitorMetaAuthorization.authorizationConfirmResult, eventName: ProbeConst.monitorEventName, categoryValueMap: categoryValueMap, context: self.vm.context).setPassportErrorParams(error: error).setResultTypeFail().flush()
                failure()
                self.errorHandle(error: error)
            }.disposed(by: disposeBag)
    }

    func errorHandle(error: Error, closeAlertHandle: @escaping () -> Void = {}) {
        var errorInfo: String
        var code: Int = -1
        if let error = error.underlyingError as? QRCodeError {
            switch error.type {
            case .networkIsNotAvailable:
                errorInfo = I18N.Lark_Legacy_NetworkOrServiceError
            default:
                errorInfo = error.displayMessage
            }
        } else if let error = error as? V3LoginError, case .badServerCode(let info) = error {
            code = Int(info.rawCode)
            errorInfo = info.message
        } else {
            errorInfo = error.localizedDescription
        }
        AuthorizationBaseViewController.logger.error(self.vm.addSdkLogTagIfNeed(original: "login auth fail errorInfo: \(errorInfo)"))
        self.showAlert(title: I18N.Lark_Legacy_Hint, message: errorInfo, handler: { [weak self] _ in
            self?.vm.failedTryJumpToSDK(errCode: code)
            closeAlertHandle()
        })
    }

    func setupNavigation(hasTitle: Bool) {
        let closeBtn = UIButton(type: .custom)
        closeBtn.setImage(BundleResources.UDIconResources.closeOutlined, for: .normal)
        closeBtn.addTarget(self, action: #selector(closeBtnClick), for: .touchUpInside)
        view.addSubview(closeBtn)

        closeBtn.snp.makeConstraints { (make) in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(BaseLayout.itemSpace)
            make.left.equalToSuperview().offset(BaseLayout.itemMinHorizonal)
            make.size.equalTo(BaseLayout.closeBtnSize)
        }

        if hasTitle {
            let titleLabel = UILabel()
            titleLabel.text = I18N.Lark_Login_SSO_AuthorizationTitle()
            titleLabel.font = BaseLayout.titleFont
            view.addSubview(titleLabel)

            titleLabel.snp.makeConstraints { (make) in
                make.centerY.equalTo(closeBtn)
                make.centerX.equalToSuperview()
                make.left.greaterThanOrEqualTo(closeBtn.snp.right)
            }
        }
    }

    @objc
    func closeBtnClick() {
        Self.logger.info("cancel auth")
        vm.closeWork(authorizationPageType: authorizationPageType)
        dismiss(animated: true, completion: nil)
    }
}

extension AuthorizationBaseViewController {
    /// iPad
    ///  not show success mask
    /// iPhone
    ///  (not record screen) show success mask
    private func showSuccessMaskIfNeeded() {
        func apply(xcode11IOS13: () -> Void, xcode11LowerIOS13: () -> Void, xcode10: () -> Void) {
            #if canImport(CryptoKit)
            if #available(iOS 13.0, *) {
                xcode11IOS13()
            } else {
                xcode11LowerIOS13()
            }
            #else
            xcode10()
            #endif
        }
        if UIScreen.main.isCaptured {
            AuthorizationBaseViewController.logger.info("record screen not show mask")
            return
        }
        if Display.pad {
            apply(xcode11IOS13: {
                AuthorizationBaseViewController.logger.info("ipad not show mask")
            }, xcode11LowerIOS13: {
                AuthorizationBaseViewController.logger.error("unexpect condition (lower than iOS13 no bundle id), not show mask")
            }, xcode10: {
                AuthorizationBaseViewController.logger.error("unexpect condition (lower than xcode11 build product no bundle id), not show mask")
            })
        } else {
            apply(xcode11IOS13: {
                showSSOSuccessMask()
            }, xcode11LowerIOS13: {
                AuthorizationBaseViewController.logger.error("unexpect condition (lower than iOS13 no bundle id), show mask")
                showSSOSuccessMask()
            }, xcode10: {
                AuthorizationBaseViewController.logger.error("unexpect condition (lower than xcode11 build product no bundle id), show mask")
                showSSOSuccessMask()
            })
        }
    }

    private func showSSOSuccessMask() {
        let animateDuration: TimeInterval = 0.4
        AuthorizationBaseViewController.logger.info("sso auth show mask")
        let vc = SSOSuccessMaskViewController()
        vc.closeBtn.rx.tap.bind { [weak vc] _ in
            guard let vc = vc else { return }
            SuiteLoginTracker.track(Homeric.SSO_MASK_CLOSE_BTN_CLICK)
            AuthorizationBaseViewController.logger.info("sso auth close mask")
            UIView.animate(withDuration: animateDuration, animations: {
                vc.view.alpha = 0
            }) { _ in
                vc.view.removeFromSuperview()
                vc.removeFromParent()
            }
        }.disposed(by: vc.disposeBag)

        addChild(vc)
        view.addSubview(vc.view)
        vc.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        vc.view.alpha = 0
        UIView.animate(withDuration: animateDuration) {
            vc.view.alpha = 1
        }
    }
}

extension AuthorizationBaseViewController {
    class func loginAuthViewController(vm: SSOBaseViewModel, authInfo: LoginAuthInfo, resolver: UserResolver?) -> UIViewController? {
        var vc: AuthorizationBaseViewController?

        Self.logger.info("n_action_auth_choose", body: "template: \(authInfo.template?.rawValue ?? "")", method: .local)

        if authInfo.isSuite {
            // 一方
            Self.logger.info("n_action_auth_choose", body: "template: suite")
            vc = SuiteAuthViewController(vm: vm, authInfo: authInfo, resolver: resolver)
        } else if authInfo.template == .authAutoLogin || authInfo.template == .authAutoLoginError {
            // 授权免登
            Self.logger.info("n_action_auth_choose", body: "template: auth_auto_login")
            vc = AuthAutoLoginViewController(vm: vm, authInfo: authInfo, resolver: resolver)
        } else {
            // 三方
            if authInfo.thirdPartyAuthInfo != nil {
                Self.logger.info("n_action_auth_choose", body: "template: authz")
                vc = ThirdPartyAuthViewController(vm: vm, authInfo: authInfo, resolver: resolver)
            } else {
                var templateString = "nil"
                if let template = authInfo.template {
                    templateString = "\(template)"
                }
                Self.logger.error("n_action_auth_choose_error", body: "template: \(templateString), auth info is nil")
            }
        }
        vc?.authorizationPageType = authInfo.template?.rawValue
        
        return vc
    }
}

extension AuthorizationBaseViewController {
    enum BaseLayout {
        static let itemMinHorizonal: CGFloat = 24.0
        static let itemSpace: CGFloat = 16.0
        static let titleFont = UIFont.systemFont(ofSize: 17.0)
        static let closeBtnSize: CGSize = CGSize(width: 18, height: 18)
    }
}
