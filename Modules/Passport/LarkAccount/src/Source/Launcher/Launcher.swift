//
//  Launcher.swift
//  LarkAccount
//
//  Created by liuwanlin on 2018/11/24.
//

import Foundation
import RxSwift
import LKCommonsLogging
import LarkAlertController
import EENavigator
import LarkAccountInterface
import LarkPerf
import LarkContainer
import RoundedHUD
import UniverseDesignToast
import LarkUIKit
import RunloopTools
import Homeric
import LarkReleaseConfig
import LarkFoundation
#if SUITELOGIN_KA
import LKLifecycleExternalAssembly
#endif
import LarkContainer

// swiftlint:disable file_length
class Launcher {

    static let logger = Logger.plog(Launcher.self, category: "LarkAccount.Launcher")
    private static let uploadLogger = Logger.plog(Launcher.self, category: "SuiteLogin.Launcher")

    @InjectedLazy var userManager: UserManager

    @InjectedLazy var loginService: V3LoginService

    @InjectedLazy var joinTeamAPI: JoinTeamAPIV3 // user:checked (global-resolve)

    @InjectedLazy var kaLoginManager: KaLoginManager

    @InjectedLazy var kaLoginService: KaLoginService
    
    @InjectedLazy var unloginProcessHandler: UnloginProcessHandler // user:checked (global-resolve)

    @Provider var idpWebViewService: IDPWebViewServiceProtocol

    #if LarkAccount_Authorization
    @Provider var ssoApi: SSOAPI // user:checked (global-resolve)
    #endif

    #if LarkAccount_RUST
    @Provider var rustImpl: RustImplProtocol // user:checked (global-resolve)
    #endif

    @Provider var passportService: PassportService

    @Provider var logoutService: LogoutService

    @Provider var switchUserService: NewSwitchUserService

    @Provider var recoverAccountApi: RecoverAccountAPI // user:checked (global-resolve)

    @Provider var loginApi: LoginAPI
    
    @Provider var userCenterAPI: UserCenterAPI // user:checked (global-resolve)

    @Provider var envManager: EnvironmentInterface

    @InjectedLazy var disposableLoginManager: DisposableLoginManager // user:checked (global-resolve)

    @Provider var realnameVerifyAPI: RealnameVerifyAPI // user:checked (global-resolve)

    @Provider var stateService: PassportStateService

    let launcherContext: AccountLauncherContext = AccountLauncherContext()

    // 当前处在LaunchGuide
    var onLaunchGuide: Bool = false

    private var factories: [LauncherDelegateFactory] {
        return LauncherDelegateRegistery.factories()
    }

    let disposeBag = DisposeBag()
}

// MARK: - AccountService
extension Launcher {
    func startRealnameVerificationFromQRCode(params: [String : Any], completion: ((String?) -> Void)?) {
        Self.logger.info("n_action_general_qr_scan_req")
        realnameVerifyAPI.startVerificationFromQRCode(params: params).subscribe { step in
            Self.logger.info("n_action_general_qr_scan_succ", body: "nextStep:\(step.stepData.nextStep)")
            completion?(nil)
            LoginPassportEventBus.shared.post(event: step.stepData.nextStep, context: V3RawLoginContext(stepInfo: step.stepData.stepInfo, additionalInfo: CommonConst.closeAllParam, context: nil), success: { }, error: { _ in })
        } onError: { error in
            Self.logger.error("n_action_general_qr_scan_err")
            completion?(error.localizedDescription)
        }
    }

    func generateDisposableLoginToken(identifier: String, completion: @escaping (Result<DisposableLoginInfo, DisposableLoginError>) -> Void) {
        Self.logger.info("received generateDisposableLoginToken call, identifier: \(identifier)")
        self.disposableLoginManager.generateDisposableLoginToken(identifier: identifier, completion: completion)
    }

    func relogin(
        conf: LogoutConf,
        onError: @escaping (_ message: String) -> Void,
        onSuccess: @escaping () -> Void,
        onInterrupt: @escaping () -> Void
    ) {
        logoutService.relogin(
            conf: conf,
            onError: onError,
            onSuccess: { _ in
                onSuccess()
            },
            onInterrupt: onInterrupt
        )
    }

    func switchTo(userID: String) {
        passportService.switchTo(userID: userID, complete: nil)
    }

    func switchTo(userID: String, complete: ((Bool) -> Void)?) {
        passportService.switchTo(userID: userID, complete: complete)
    }

    func autoSwitch(complete: ((Bool) -> Void)?) {
        switchUserService.autoSwitch(complete: complete, context: UniContextCreator.create(.logout))
    }
    
    func unRegisterUser(complete: ((Bool) -> Void)?){

        let config: LogoutConf
        if self.userManager.getActiveUserList().count > 1 {
            config = LogoutConf(forceLogout: true, destination: .switchUser, type: .foreground)
        } else {
            config = LogoutConf(forceLogout: true, destination: .login, type: .all)
        }

        logoutService.relogin(conf: config) { message in
            Self.logger.error("n_action_unregister", body: "unregister logout error\(message)")
            complete?(false)
        } onSuccess: { [weak self] _ in
            Self.logger.info("n_action_unregister", body: "unregister logout succ")
            guard let self = self else { return }
            if self.userManager.getActiveUserList().count > 0 {
                self.autoSwitch { flag in
                    Self.logger.info("n_action_unregister", body: "auto switch \(flag)")
                    complete?(flag)
                }
            }
        } onInterrupt: {
            Self.logger.error("n_action_unregister", body: "unregister logout interruptted")
            complete?(false)
        }
    }

    func unregisterUser(trigger: LogoutTrigger, complete: ((Bool) -> Void)?) {

        let config: LogoutConf
        if self.userManager.getActiveUserList().count > 1 {
            config = LogoutConf(forceLogout: true, trigger: trigger, destination: .switchUser, type: .foreground)
        } else {
            config = LogoutConf(forceLogout: true, trigger: trigger, destination: .login, type: .all)
        }

        logoutService.relogin(conf: config) { message in
            Self.logger.error("n_action_unregister", body: "unregister logout error\(message)")
            complete?(false)
        } onSuccess: { [weak self] _ in
            Self.logger.info("n_action_unregister", body: "unregister logout succ")
            guard let self = self else { return }
            if self.userManager.getActiveUserList().count > 0 {
                self.autoSwitch { flag in
                    Self.logger.info("n_action_unregister", body: "auto switch \(flag)")
                    complete?(flag)
                }
            }
        } onInterrupt: {
            Self.logger.error("n_action_unregister", body: "unregister logout interruptted")
            complete?(false)
        }
    }

    func quitTeamH5Url() -> URL? {
        return passportService.quitTeamH5Url()
    }

    func pushToTeamConversion(
        fromNavigation nav: UINavigationController,
        trackPath: String?
    ) {
        passportService.pushToTeamConversion(fromNavigation: nav, trackPath: trackPath)
    }

    func joinTeam(withQRUrl url: String, fromVC: UIViewController, result: @escaping JoinTeamResult) -> Bool {
        let context = UniContextCreator.create(.operationCenter)
        PassportBusinessContextService.shared.triggerChange(.joinTeam)
        return loginService.joinTeam(withQRUrl: url, fromVC: fromVC, result: result, context: context)
    }

    func upgradeTeamViewController(
        nav: UINavigationController,
        trackInfo: (path: String?, from: String?),
        handler: @escaping (_ success: Bool) -> Void,
        result: @escaping (UIViewController?) -> Void
    ) {
        //TODO: 空实现,后续依赖方移除代码后清理
    }

    func upgradeTeam(tenantName: String,
                     staffSize: String? = nil,
                     industryType: String? = nil) -> Observable<Bool> {
        //TODO: 空实现. 后续依赖方修改代码后移除
        return .just(false)
    }

    func pushToJoinTeam(from: UIViewController) {
        //TODO: 空实现. 后续依赖方修改代码后移除
    }

    func pushToSwitchUserViewController(from: UIViewController) {
        let switchUserController = NativeSwitchUserViewController(vm: NativeSwitchUserViewModel(context: UniContextCreator.create(.external)))
        if let navVC = from.navigationController, !Display.pad {
            navVC.pushViewController(switchUserController, animated: true)
        } else {
            let navVC = LoginNaviController.init(rootViewController: switchUserController)
            if Display.pad { navVC.modalPresentationStyle = .formSheet }
            from.present(navVC, animated: true, completion: nil)
        }
    }

    /// checkUnRegisterStatus 已迁移至 PassportUserService 并改为用户态
    func checkUnRegisterStatus(scope: UnregisterScope?) -> Observable<CheckUnRegisterStatusModel> {
        #if DEBUG || ALPHA
        fatalError("Should use PassportUserService instead.")
        #else
        return Observable.create({ [weak self] (ob) -> Disposable in
            guard let self = self else { return Disposables.create() }
            return Disposables.create()
        })
        #endif
    }

    func getCurrentSecurityPwdStatus() -> Observable<(Bool, Bool)> {
        return Observable<(Bool, Bool)>.create({ (observer) -> Disposable in
            self.loginService.getCurrentSecurityPwdStatus(callback: { (isOpen, error) in
                if error != nil {
                    observer.onNext((isOpen, false))
                    observer.onCompleted()
                } else {
                    observer.onNext((isOpen, true))
                    observer.onCompleted()
                }
            })
            return Disposables.create()
        })
    }

    func getSecurityPwdViewControllerToPush(
        isSetPwd: Bool,
        createNewSuccess: @escaping () -> Void,
        callback: @escaping (UIViewController?) -> Void
    ) {
        guard let urlConfig = loginService.webUrl(for: .securityPasswordSetting) else {
            callback(nil)
            return
        }
        let url = WebConfig.commonParamsUrlFrom(url: urlConfig, with: [:])
        callback(loginService.dependency.createWebViewController(url, customUserAgent: nil))
    }

    func getSecurityStatus(appId: String, result: @escaping SecurityResult) {
        loginService.getSecurityStatus(appId: appId, result: result, context: UniContextCreator.create(.unknown))
    }

    func credentialList(context: UniContextProtocol) -> UIViewController {
        PassportBusinessContextService.shared.triggerChange(.accountManage)
        return loginService.credentialList(context: context)
    }

    func getAccountPhoneNumbers() -> Observable<[LarkAccountInterface.PhoneNumber]> {
        let loginService = self.loginService
        return Observable<[LarkAccountInterface.PhoneNumber]>.create { (observer) -> Disposable in
            loginService.getAccountPhoneNumbers { (res) in
                switch res {
                case .failure(let error):
                    observer.onError(error)
                case .success(let phoneNumbers):
                    observer.onNext(phoneNumbers
                        .map({ LarkAccountInterface.PhoneNumber($0.contryCode, $0.phoneNumber) }))
                    observer.onCompleted()
                }
            }
            return Disposables.create()
        }
    }

    func getTopCountryList() -> [String] {
        return loginService.topCountryList
    }

    func getBlackCountryList() -> [String] {
        return loginService.blackCountryList
    }

    func register(interruptOperation observable: InterruptOperation) {
        passportService.register(interruptOperation: observable)
    }

    func injectLogin(pattern: String? = nil, regParams: [String: Any]? = nil) {
        passportService.injectLogin(pattern: pattern, regParams: regParams)
    }

    func tokenJoinTeam(
        params: [String: String]
    ) {
        let context = UniContextCreator.create(.operationCenter)
        Self.logger.info("start token join team code")
        if isLogin {
            guard let navi = Navigator.shared.navigation else { // user:checked (navigator)
                Self.logger.error("logged teamcode join no navigation")
                return
            }
            PassportBusinessContextService.shared.triggerChange(.joinTeam)
            loginService.loggedTeamCodeJoin(
                params: params,
                navigation: navi,
                trackPath: TrackConst.pathTokenJoinTeamLogin,
                context: context
            )
        } else {
            loginService.loginJoinTeamCodeJoin(
                params: params,
                trackPath: TrackConst.pathTokenJoinTeamNotLogin,
                context: context
            )
        }
    }

    func launchGuideLogin(context: LauncherContext) -> Observable<Void> {
        let newContext = self.launcherContext.merge(context: context)
        return Observable.create { [weak self] ob -> Disposable in
            guard let self = self else { return Disposables.create() }

            self.loginService.enterAppUserListCallback = { [weak self] users in
                guard let self = self else { return }
                EnterAppMonitor.shared.update(step: .login)
                EnterAppMonitor.shared.start(key: .toPolicy)
//                Self.logger.info("SuiteLogin login success: \(data.users[data.userIndex].id)")

                self.userManager.setEnterAppUserList(users)

                if let id = users.first?.userID {
                    newContext.currentUserID = id
                }
                self.execute(
                    .afterLoginSucceded,
                    block: {
                        $0.afterLoginSucceded(newContext)
                    }
                )
                ob.onNext(())
                ob.onCompleted()
            }
            return Disposables.create()
        }
    }

    func createLoginNavigation(rootViewController: UIViewController) -> UINavigationController {
        return passportService.createLoginNavigation(rootViewController: rootViewController)
    }

    func accountSecurityCenterEntryTitle() -> String {
        return passportService.accountSecurityCenterEntryTitle()
    }

    func openAccountSecurityCenter(from: UIViewController) {
        self.loginService.openAccountSecurityCenter(for: .accountSecurityCenter, from: from)
    }

    // 打开对应SSO页面
    func handleSSOLogin(
        _ ssoDomain: String,
        tenantName: String,
        context: UniContextProtocol
    ) {
        loginService.handleSSOLogin(
            ssoDomain,
            tenantName: tenantName,
            refreshUserListBlock: {
                return Observable.create { [weak self] ob -> Disposable in
                    self?.userManager.updateUserList { userList in
                        ob.onNext(())
                        ob.onCompleted()
                    }
                    return Disposables.create()
                }
            },
            switchUserBlock: { (userId, complete) in
                self.switchTo(userID: userId, complete: complete)
            },
            context: context)
    }

    func teamConversionEntryTitle(for account: Account) -> String {
        return passportService.teamConversionEntryTitle()
    }

    func verifyContactPoint(
        scope: VerifyScope,
        contact: String,
        contactType: ContactType,
        viewControllerHandler: @escaping (Result<UIViewController, Error>) -> Void,
        completionHandler: @escaping (Result<VerifyToken, Error>) -> Void
    ) {
        loginService.verifyContactPoint(verifyScope: scope, contact: contact, contactType: contactType.rawValue, context: UniContextCreator.create(.unknown), viewControllerHandler: viewControllerHandler, completionHandler: completionHandler)
    }

    func verifyContactPoint(
        scope: VerifyScope,
        contact: String,
        complete: @escaping (Result<VerifyToken, Error>) -> Void,
        title: String?,
        subtitle: String?
    ) -> UIViewController {
        let vm = OTPForPublicViewModel(
            verifyScope: scope,
            contact: contact,
            titleIn: title,
            subtitleIn: subtitle,
            context: UniContextCreator.create(.unknown),
            complete: complete
        )
        let verifyVC = OTPVerifyViewController(vm: vm)
        return verifyVC
    }

    func updateUserInfo(
        userId: String,
        name: String,
        avatarKey: String,
        enUsName: String,
        avatarUrl: String
    ) {
        passportService.updateUserInfo(userId: userId, name: name, avatarKey: avatarKey, enUsName: enUsName, avatarUrl: avatarUrl)
    }
    
    func retrieveAppLink(token: String, type: String?) {
        guard let loadingVC = PassportNavigator.topMostVC else {
            Self.logger.errorWithAssertion("no loading vc for recoverAccountAppLink")
            return
        }
        let context = UniContextCreator.create(.unknown)
        let hud = RoundedHUD.showLoading(on: loadingVC.view)
        let errorHandler = V3ErrorHandler(vc: loadingVC, context: context)
        PassportBusinessContextService.shared.triggerChange(.accountAppeal)
        loginApi.retrieveAppealGuide(token: token,type:type, context: context)
            .do(onNext: { step in
                Self.logger.info("n_action_retrieve_applink_req_succ")
            }, onError: { error in
                Self.logger.error("n_action_retrieve_applink_req_fail")
            })
            .post([CommonConst.closeAllStartPointKey: true],
                  vcHandler: { vc in
                    if let vc = vc {
                        let nav = LoginNaviController(rootViewController: vc)
                        // 必须是FullScreen，禁用下拉dismiss，能下拉dismiss，流程会错误
                        if Display.pad {
                            nav.modalPresentationStyle = .formSheet
                        }else {
                            nav.modalPresentationStyle = .fullScreen
                        }
                        if let mainSceneTopMost = PassportNavigator.topMostVC {
                            mainSceneTopMost.present(nav, animated: true, completion: nil)
                        } else {
                            //TODO: log
                        }
                    }
                  },
                  context: context)
            .subscribe(onNext: { (_) in
                hud.remove()
            }, onError: { (error) in
                hud.remove()
                errorHandler.handle(error)
            })
            .disposed(by: disposeBag)
    }

    func setup() {
        AccountIntegrator.shared.setup()
    }

    func mainViewLoaded() {
        AccountIntegrator.shared.mainViewLoaded()
    }
    
    func openCJURL(_ url: String) {
        passportService.openCJURL(url)
    }
    
    func getPhoneNumberRegionList(_ completion: @escaping (_ allowList: [String]?, _ blockList: [String]?, _ error: Error?) -> Void) -> Void {
        passportService.getPhoneNumberRegionList(completion)
    }
}

// MARK: - Utils
extension Launcher {
    func execute(_ aspect: LauncherAspect, block: @escaping (LauncherDelegate) -> Void) { // user:checked
        var totalCost: [(name: String, cost: CFAbsoluteTime)] = []
        self.factories.forEach { (factory) in
            let delegate = factory.delegate
            let start = CFAbsoluteTimeGetCurrent()
            block(delegate)
            let end = CFAbsoluteTimeGetCurrent()
            totalCost.append((name: delegate.name, cost: end - start))
        }
        Self.logger.info("launcher aspect execute cost", additionalData: [
            "aspect": String(describing: aspect),
            "totalCost": String(describing: totalCost)
        ], method: .local)
    }
}
// swiftlint:enable file_length

// MARK: Passport Private
extension Launcher {

//    func getSettingFeature() -> SettingFeature {
//        // 相关业务逻辑已经迁移到 Web 版帐号安全中心
//        return V3SecurityConfig.placeholder.settingFeature
//    }

    func login(conf: LoginConf, window: UIWindow?) -> Observable<PassportUsersInfo> {
        return Observable<PassportUsersInfo>.create({ (observer) -> Disposable in
            self.execute(.beforeLogin, block: { $0.beforeLogin(self.launcherContext, onLaunchGuide: self.onLaunchGuide) })
            PassportDelegateRegistry.resolver(LogAppenderPassportDelegate.self)?
                .adjustLogAppenders()

            let transitionView = window?.rootViewController?.view.snapshotView(afterScreenUpdates: false) ?? UIView()
            // 目前约定服务端返回列表的第一个是 active user
            let index = 0
            var context = UniContextCreator.create(.login)
            let nextVC = self.login(fromGuide: conf.fromLaunchGuide, context: context) { users in
                EnterAppMonitor.shared.update(step: .login)
                EnterAppMonitor.shared.start(key: .toPolicy)
//                Self.logger.info("SuiteLogin login success: \(info.users[info.userIndex].id)")
                guard let user = users.first else {
                    return
                }
                let passportUsersInfo = PassportUsersInfo(
                    accounts: users.toAccountList(),
                    currentAccount: user.makeAccount(),
                    currentAccountIndex: index
                )

                if !MultiUserActivitySwitch.enableMultipleUser {
                    self.userManager.setEnterAppUserList(users)
                }

                self.launcherContext.currentUserID = user.userID

                let newState = PassportState(user: user.makeUser(), loginState: .online, action: .login)
                self.stateService.updateState(newState: newState)

                self.execute(.afterLoginSucceded, block: { $0.afterLoginSucceded(self.launcherContext) })

                observer.onNext(passportUsersInfo)
                observer.onCompleted()
            }

            if !conf.isRollbackLogout {
                window?.rootViewController = nextVC

                nextVC.view.addSubview(transitionView)
                transitionView.snp.makeConstraints { (make) in
                    make.edges.equalToSuperview()
                }
                UIView.animate(withDuration: 0.3, animations: {
                    transitionView.alpha = 0
                }) { (_) in
                    transitionView.removeFromSuperview()
                }
            }
            return Disposables.create()
        })
    }

    func register(conf: LoginConf, window: UIWindow?) -> Observable<PassportUsersInfo> {
        return Observable<PassportUsersInfo>.create({ (observer) -> Disposable in
            self.execute(.beforeLogin, block: { $0.beforeLogin(self.launcherContext, onLaunchGuide: self.onLaunchGuide) })
            PassportDelegateRegistry.resolver(LogAppenderPassportDelegate.self)?
                .adjustLogAppenders()
            
            let transitionView = window?.rootViewController?.view.snapshotView(afterScreenUpdates: false) ?? UIView()

            self.loginApi.fetchPrepareTenantInfo(context: UniContextCreator.create(.register)).subscribe(onNext: { step in
                guard let passportStep = PassportStep(rawValue: step.stepData.nextStep),
                      let serverInfo = passportStep.pageInfo(with: step.stepData.stepInfo) as? V3CreateTenantInfo else {
                    observer.onError(V3LoginError.badServerCode(V3LoginErrorInfo(type: .serverError, message: "invalid step info")))
                    observer.onCompleted()
                    return
                }

                let nextVC = self.register(
                    fromGuide: conf.fromLaunchGuide,
                    info: serverInfo,
                    context: UniContextCreator.create(.register),
                    callback: { users in
                        EnterAppMonitor.shared.update(step: .login)
                        EnterAppMonitor.shared.start(key: .toPolicy)

                        guard let user = users.first else {
                            return
                        }
                        let index = 0
                        let passportUsersInfo = PassportUsersInfo(
                            accounts: users.toAccountList(),
                            currentAccount: user.makeAccount(),
                            currentAccountIndex: index
                        )

                        self.userManager.setEnterAppUserList(users)

                        self.launcherContext.currentUserID = user.userID

                        let newState = PassportState(user: user.makeUser(), loginState: .online, action: .login)
                        self.stateService.updateState(newState: newState)

                        self.execute(.afterLoginSucceded, block: { $0.afterLoginSucceded(self.launcherContext) })

                        observer.onNext(passportUsersInfo)
                        observer.onCompleted()
                    })

                if !conf.isRollbackLogout {
                    window?.rootViewController = nextVC

                    nextVC.view.addSubview(transitionView)
                    transitionView.snp.makeConstraints { (make) in
                        make.edges.equalToSuperview()
                    }
                    UIView.animate(withDuration: 0.3, animations: {
                        transitionView.alpha = 0
                    }) { (_) in
                        transitionView.removeFromSuperview()
                    }
                }
            }, onError: { error in
                Self.logger.info("register vc fail to present: \(error.localizedDescription)")
                observer.onCompleted()
            }).disposed(by: self.disposeBag)
            return Disposables.create()
        })
    }

    private func login(
        fromGuide: Bool,
        context: UniContextProtocol,
        callback: @escaping EnterAppUserListCallback
    ) -> UIViewController {
        // TODO: KA
        #if SUITELOGIN_KA
        // 移除 KAR 的特化
        loginService.enterAppUserListCallback = callback
        let vc = idpWebViewService.loginPageForIDPName(nil, context: context, success: { (idpServiceStep) in
            switch idpServiceStep {
            case .stepData(let step, let stepInfo):
                LoginPassportEventBus.shared.post(
                    event: step,
                    context: V3RawLoginContext(stepInfo: stepInfo, context: context),
                    success: {},
                    error: { _ in }
                )
            default:
                break
            }
        }, error: { _ in
            //私有化KA自有代码有需求要感知idp登录失败，飞书内暂时不开放(后续Passport切换到用户容器之后只会有online，offline)
            if let kaLifeCycleInstance = implicitResolver?.resolve(LKLifecycleExternal.self) { // user:checked
                Self.logger.info("n_action_idp_login_failed", body: "called")
                kaLifeCycleInstance.onloginFailed(isFast: false)
            } else {
                Self.logger.warn("n_action_idp_login_failed", body: "no lifeCycleInstance")
            }
        })
        let navVC = PassportKANavigationController(rootViewController: vc)
        return navVC
        #else
        return v4Login(fromGuide: fromGuide, context: context, callback: callback)
        #endif
    }

    private func register(
        fromGuide: Bool,
        info: V3CreateTenantInfo,
        context: UniContextProtocol,
        callback: @escaping EnterAppUserListCallback
    ) -> UIViewController {
        return v4Register(
            fromGuide: fromGuide,
            info: info,
            context: context,
            callback: callback
        )
    }

    /// 当 fast login 未成功时，为了防止之前的数据污染新的登录
    /// 重置 Rust，重置环境，清理本地 session 等数据，清空 cookie
    internal func resetWhenBackToLogin() {
        Self.logger.error("n_action_fast_login_reset_data")
        loginService.reset()
        execute(
            .afterLogout,
            block: { [weak self] in
                guard let self = self else { return }
                // 用于触发外部的数据清空，例如 CookieManager
                $0.afterLogout(self.launcherContext)
                // 这里暂不调用新版的 afterLogout(context:, conf:)，因为 config .default 会有副作用，而 CookieManager 里只用到老接口
//                $0.afterLogout(context: self.launcherContext, conf: .default)
            }
        )
        launcherContext.reset()
    }

    private func v4Login(
        fromGuide: Bool,
        context: UniContextProtocol,
        callback: @escaping EnterAppUserListCallback
    ) -> UIViewController {
        loginService.enterAppUserListCallback = callback
        return loginService.loginVC(fromGuide: fromGuide, context: context)
    }

    private func v4Register(
        fromGuide: Bool,
        info: V3CreateTenantInfo,
        context: UniContextProtocol,
        callback: @escaping EnterAppUserListCallback
    ) -> UIViewController {
        loginService.enterAppUserListCallback = callback
        return loginService.registerVC(
            fromGuide: fromGuide,
            info: info,
            context: context
        )
    }

    public func fastLogin(callback: @escaping FastLoginCallback) {

        Self.logger.info("n_action_fast_login_enter_login_service", method: .local)
        RangersAppLogDeviceServiceImpl.shared.assertInitialize()

        func onError(msg: String) {
            let error = V3LoginError.badLocalData(msg)
            Self.logger.error("n_action_fast_login_fail", error: error)

            AppStartupMonitor.shared.isFastLogin = false
            //开关开启的情况下，走loginTask的reset逻辑，兼容登出，ka包等场景
            if !PassportSwitch.shared.enableUUIDAndNewStoreReset {
                self.resetWhenBackToLogin()
            }
            callback(.failure(error))
        }

        guard PassportStore.shared.isDataValid else {
            //这里需要重置一些特殊数据
            //重置统一did
            PassportUniversalDeviceService.shared.reset()
            //重置非统一did
            RangersAppLogDeviceServiceImpl.shared.reset()

            onError(msg: "Store data is not valid. Please check store's dataIdentifier.")
            return
        }
        let userList = UserManager.shared.userListRelay.value
        guard let foregroundUser = UserManager.shared.foregroundUser, // user:current
              !userList.isEmpty else {
                  // 失败的数据重置统一由外部处理
                  onError(msg: "Can not get valid foregroundUserID and/or foregroundUser") // user:current
                  return
        }
        Self.logger.info("n_action_fast_login_succ: \(foregroundUser.userID)") // user:current

        self.launcherContext.isFastLogin = true
        self.launcherContext.currentUserID = foregroundUser.userID // user:current

        PassportProbeHelper.shared.userID = foregroundUser.userID // user:current
        PassportProbeHelper.shared.tenantID = foregroundUser.user.tenant.id // user:current
        UploadLogManager.shared.userId = foregroundUser.userID // user:current

        //先 rust online
        let account = foregroundUser.makeAccount() // user:current

        if MultiUserActivitySwitch.enableMultipleUser {
            updateForegroundUserHasSideEffectTask(context: UniContextCreator.create(.fastLogin), action: .fastLogin).runnable(foregroundUser).execute(successCallback: {_ in

                Self.logger.info("n_action_fast_login_activity_refresh_succ")
                finish()

            }) { error in
                //fastLogin不处理activity user list 失败场景，只做日志记录
                finish()
                Self.logger.error("n_action_fast_login_activity_refresh_fail", error: error)
            }
        } else {
            //先 rust online
            #if LarkAccount_RUST
            self.rustImpl.rustOnlineRequest(account: account)
            #endif

            let newState = PassportState(user: foregroundUser.makeUser(), loginState: .online, action: .fastLogin) // user:current
            self.stateService.updateState(newState: newState)
            
            finish()
        }

        func finish() {

            self.execute(.fastLoginAccount) { delegate in
                delegate.fastLoginAccount(account)
            }

            AppStartupMonitor.shared.isFastLogin = true

            #if ONE_KEY_LOGIN
            OneKeyLogin.fastLoginResult(.success((foregroundUser, userList))) // user:current
            #endif
            callback(.success((foregroundUser, userList))) // user:current
        }
    }

    // MARK: KA

    #if SUITELOGIN_KA
    @available(*, deprecated, message: "Only KAR used before and now aligns with SaaS.")
    private func kaLogin(context: UniContextProtocol, callback: @escaping EnterAppUserListCallback) -> UIViewController {
        loginService.enterAppUserListCallback = callback
        return kaLoginManager.kaLoginVC(context: context)
    }
    #endif
}

extension Launcher {

    func isExecutingSwitchUserV2() -> Bool {
        return switchUserService.stage.value == .executing
    }

    func enableSwitchUserEnterBarrierTask() -> Bool {
        return true
    }

    func isNewEnterAppProcess() -> Bool {
        return MultiUserActivitySwitch.enableMultipleUser
    }
}

enum LauncherAspect {
    case beforeLogin
    case afterLoginSucceded
    case beforeSetAccount
    case afterSetAccount
    case updateAccount
    case beforeLogout
    case beforeLogoutClearAccount
    case afterLogoutClearAccoount
    case logoutUserList
    case afterLogout
    case beforeSwitchAccount
    case beforeSwitchSetAccount
    case afterSwitchSetAccount
    case afterSwitchAccount
    case switchAccountSucceed
    case fastLoginAccount
}
