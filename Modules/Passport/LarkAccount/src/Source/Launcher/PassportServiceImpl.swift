//
//  PassportServiceImpl.swift
//  LarkAccount
//
//  Created by Nix Wang on 2022/6/28.
//

import LarkAccountInterface
import LarkContainer
import RxSwift
import LKCommonsLogging
import LarkUIKit
import LarkPerf
import UniverseDesignToast
import LarkEnv

class PassportServiceImpl: PassportService {
    static let logger = Logger.plog(PassportServiceImpl.self, category: "LarkAccount.PassportServiceImpl")

    @Provider private var loginService: V3LoginService
    @Provider private var logoutService: LogoutService
    @Provider private var userManager: UserManager
    @Provider private var loginApi: LoginAPI
    @Provider private var switchUserService: NewSwitchUserService
    @Provider private var userCenterAPI: UserCenterAPI // user:checked (global-resolve)
    @Provider private var launcher: Launcher
    @Provider private var envManager: EnvironmentInterface
    @Provider private var stateService: PassportStateService
    @Provider private var userSessionService: UserSessionService


    var state: Observable<PassportState> { return stateService.state }

    let disposeBag = DisposeBag()

    var deviceID: String {
        PassportDeviceServiceWrapper.shared.deviceId
    }
    
    func getLegacyDeviceId() -> String? {
        return PassportStore.shared.didChangedMap?[EnvManager.env.unit]
    }
    
    func getLegacyDeviceIdBy(unit: String) -> String? {
        return PassportStore.shared.didChangedMap?[unit]
    }
}

// MARK: - 用户相关
extension PassportServiceImpl {

    var foregroundUser: User? { // user:current
        return userManager.foregroundUser?.makeUser() // user:current
    }

    var userList: [User] {
        return userManager.getUserList().map { $0.makeUser() }
    }

    var activeUserList: [User] {
        return userManager.getActiveUserList().map { $0.makeUser() }
    }

    var menuUserListObservable: Observable<[User]> {
        return userManager.userListObservable.map { $0.makeUserList() }
    }

    /// 等同于 userList map tenant
    var tenantList: [Tenant] {
        return userList.map { $0.tenant }
    }

    func getUser(_ userID: String) -> User? {
        return userList.first(where: { $0.userID == userID })
    }

    func updateUserInfo(
        userId: String,
        name: String,
        avatarKey: String,
        enUsName: String,
        avatarUrl: String
    ) {
        Self.logger.info("n_action_user_manager_outside_update_user_info", method: .local)
        // 直接拉取一次 user/list 接口，更新用户数据
        userManager.updateUserList()
    }

    var tenantBrand: TenantBrand {
        return envManager.tenantBrand
    }

    var isFeishuBrand: Bool {
        return tenantBrand == .feishu
    }

    var enableUserScope: Bool {
        return PassportUserScope.enableUserScope
    }

}

// MARK: - 配置
extension PassportServiceImpl {
    var conf: PassportConfProtocol {
        return PassportConf.shared
    }

    var `switch`: PassportSwitchProtocol {
        return PassportSwitch.shared
    }

}

// MARK: - 无 BootManager 集成
extension PassportServiceImpl {
    func setup() {
        AccountIntegrator.shared.setup()
    }

    func mainViewLoaded() {
        AccountIntegrator.shared.mainViewLoaded()
    }
}

// MARK: - 登出
extension PassportServiceImpl {

    func logout(
        conf: LogoutConf,
        onInterrupt: @escaping () -> Void,
        onError: @escaping (_ message: String) -> Void,
        onSuccess: @escaping (_ willSwitchUser: Bool, _ message: String?) -> Void,
        onSwitch: ((_ success: Bool) -> Void)?
    ) {
        logoutService.relogin(conf: conf, onError: onError) { [weak self] message in
            guard let self = self else { return }

            if self.userManager.getActiveUserList().count > 0 {
                Self.logger.info("n_action_logout", body: "will switch user")
                onSuccess(true, message)

                self.autoSwitch { result in
                    Self.logger.info("n_action_logout", body: "auto switch result \(result)")
                    onSwitch?(result)
                }
            } else {
                Self.logger.info("n_action_logout", body: "won't switch user")
                onSuccess(false, message)
            }
        } onInterrupt: {
            onInterrupt()
        }
    }

    func register(interruptOperation observable: InterruptOperation) {
        loginService.register(interruptOperation: observable)
    }

    func injectLogin(pattern: String? = nil, regParams: [String: Any]? = nil) {
        loginService.inject(pattern: pattern, regParams: regParams)
    }

    func unregisterUser(trigger: LogoutTrigger, complete: ((Bool) -> Void)?) {
        launcher.unregisterUser(trigger: trigger, complete: complete)
    }

}

// MARK: - Session Service
extension PassportServiceImpl {
    func checkSessionInvalid() {
        userSessionService.start(reason: .external)
    }
}


// MARK: - 账号管理
extension PassportServiceImpl {

    func openAccountSecurityCenter(from: UIViewController) {
        self.loginService.openAccountSecurityCenter(for: .accountSecurityCenter, from: from)
    }

    func accountSecurityCenterEntryTitle() -> String {
        return I18N.Lark_Passport_AccountSecurityCenter_TitleMobile
    }

}


// MARK: - 切换租户
extension PassportServiceImpl {

    func switchTo(userID: String) {
        switchTo(userID: userID, complete: nil)
    }

    func switchTo(userID: String, complete: ((Bool) -> Void)?) {
        switchUserService.switchTo(userID: userID, complete: complete, context: UniContextCreator.create(.external))
    }

    func autoSwitch(complete: ((Bool) -> Void)?) {
        switchUserService.autoSwitch(complete: complete, context: UniContextCreator.create(.logout))
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

}

// MARK: - 财经
extension PassportServiceImpl {

    func openCJURL(_ url: String) {
        guard let vc = PassportNavigator.topMostVC else {
            Self.logger.errorWithAssertion("no loading vc for recoverAccountAppLink")
            return
        }
        self.loginService.dependency.openCJURL(url, from: vc)
    }

}

// MARK: - 国家代码
extension PassportServiceImpl {
    func getTopCountryList() -> [String] {
        return loginService.topCountryList
    }

    func getBlackCountryList() -> [String] {
        return loginService.blackCountryList
    }

    func getPhoneNumberRegionList(_ completion: @escaping (_ allowList: [String]?, _ blockList: [String]?, _ error: Error?) -> Void) -> Void {
        userCenterAPI.fetchPhoneNumberRegionList()
            .subscribe(onNext: { response in
                completion(response.credentialInfo.allowRegionList, response.credentialInfo.blockRegionList, nil)
            }, onError: { error in
                completion(nil, nil, error)
            })
            .disposed(by: disposeBag)
    }

}

// MARK: - 导出本地日志
extension PassportServiceImpl {
    /// 订阅状态栏点击 5 下行为
    /// 在获取本地日志路径后弹出 UIActivityViewController，分享日志压缩文件
    func subscribeStatusBarInteraction() {
        FetchClientLogHelper.subscribeStatusBarInteraction()
    }
    
    func unsubscribeStatusBarInteraction() {
        FetchClientLogHelper.unsubscribeStatusBarInteraction()
    }

    func fetchClientLog(completion: @escaping (ClientLogShareViewController?) -> Void) {
        FetchClientLogHelper.fetchClientLog(completion: completion)
    }
}

// MARK: - UI 相关
extension PassportServiceImpl {
    func launchGuideLogin(context: LauncherContext) -> Observable<Void> {
        return launcher.launchGuideLogin(context: context)
    }

    func createLoginNavigation(rootViewController: UIViewController) -> UINavigationController {
        return LoginNaviController(rootViewController: rootViewController)
    }

    func quitTeamH5Url() -> URL? {
        return loginService.webUrl(for: WebUrlKey.quitTeam)
    }

    func teamConversionEntryTitle() -> String {
        return I18N.Lark_Login_UseByOrgs
    }

    func pushToTeamConversion(fromNavigation nav: UINavigationController,
                              trackPath: String?) {
        guard let loadingVC = PassportNavigator.topMostVC else {
            Self.logger.errorWithAssertion("no loading vc for recoverAccountAppLink")
            return
        }

        guard let window = PassportNavigator.keyWindow else {
            Self.logger.errorWithAssertion("no loading vc for mainSceneWindow")
            return
        }

        let context = UniContextCreator.create(.operationCenter)
        PassportBusinessContextService.shared.triggerChange(.joinTeam)
        UDToast.showDefaultLoading(on: window)
        let errorHandler = V3ErrorHandler(vc: loadingVC, context: UniContextCreator.create(.operationCenter), showToastOnWindow: true)
        loginService.pushToTeamConversion(
            navigation: nav,
            trackPath: trackPath,
            context: context,
            success: {
                UDToast.removeToast(on: window)
            }, failure: { error in
                errorHandler.handle(error)
            })
    }
}

