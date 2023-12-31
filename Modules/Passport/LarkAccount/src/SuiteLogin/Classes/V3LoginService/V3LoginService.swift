//
//  V3LoginService.swift
//  SuiteLogin
//
//  Created by quyiming@bytedance.com on 2019/9/19.
//

import Foundation
import LKCommonsLogging
import Homeric
import RxRelay
import RxSwift
import LarkPerf
import UniverseDesignToast
import LarkAccountInterface
import LarkContainer
import LarkReleaseConfig
import LarkEnv
import EENavigator
import ECOProbe
import LarkAlertController
import ECOProbeMeta

class V3LoginService {

    static let logger = Logger.plog(V3LoginService.self, category: "SuiteLogin.LoginService")

    let envLogger = SwitchEnvironmentManager.logger

    // 用户上一次的登陆状态，从文件中读取，优先级最高，每次用户跳转到”输入账号页面“下一个页面时，保存状态;
    var userLoginConfig: V3UserLoginConfig? {
        return store.userLoginConfig
    }

    let disposeBag = DisposeBag()

    // 默认为V3ConfigInfo.default对应的状态
    // 服务端config接口返回后，进行刷新
    private var _configInfo: V3ConfigInfo?
    internal private(set) var configInfo: V3ConfigInfo {
        get {
            if let conf = _configInfo {
                return conf
            }
            if let conf = store.configInfo {
                _configInfo = conf
                return conf
            } else {
                let conf = V3ConfigInfo.defaultConfig
                _configInfo = conf
                return conf
            }
        }
        set {
            _configInfo = newValue
            store.configInfo = newValue

            // 为了避免 json 解析影响启动速度
            store.enableUserScope = newValue.config().getEnableUserScope()
            store.enableInstallIDUpdatedSeparately = newValue.config().getEnableInstallIDUpdatedSeparately()
            store.enableUUIDAndNewStoreReset = newValue.config().getEnableUUIDAndNewStoreReset()
            store.enableLazySetupEventRegister = newValue.config().getEnableLazySetupEventRegister()
            store.tnsAuthURLRegex = newValue.config().getTNSAuthURLRegex()
            store.enableRegisterEntry = newValue.config().getEnableRegisterEntry()
            store.enableLeftNaviButtonsRootVCOpt = newValue.config().getEnableLeftNaviButtonsRootVCOpt()
            store.enableNativeWebauthnRegister = newValue.config().getEnableWebauthnNativeRegister()
            store.enableNativeWebauthnAuth = newValue.config().getEnableWebauthnNativeAuth()
            store.globalRegistrationTimeout = newValue.config().getGlobalRegistrationTimeout()
            store.passportOfflineConfig = newValue.config().getPassportOfflineConfig()

            // 更新 config 时同步更新 log 配置
            PassportLogHelper.shared.setLogByOPMonitor(store.configInfo?.config().getEnableLogByOPMonitor() ?? false)
        }
    }

    lazy var enterpriseLoginSchemeService: PassportEnterpriseLoginSchemeService = {
        return PassportEnterpriseLoginSchemeService()
    }()

    lazy var loginVCAvailableSub: BehaviorRelay<Bool> = {
        return BehaviorRelay(value: false)
    }()

    // MARK: login
    lazy var loginStateSub: BehaviorRelay<V3LoginState> = {
        return BehaviorRelay(value: store.isLoggedIn ? .logined: .notLogin)
    }()

    var loginCallback: SuiteLoginCallback?
    var enterAppUserListCallback: EnterAppUserListCallback?

    @Provider var userManager: UserManager
    
    @Provider var newSwitchUserService: NewSwitchUserService

    @Provider var setDeviceInfoAPI: SetDeviceInfoAPI // user:checked (global-resolve)

    @Provider var idpWebViewService: IDPWebViewServiceProtocol
    
    @Provider var logoutService: LogoutService

    lazy var apiHelper: V3APIHelper = {
        let helper = V3APIHelper(
            enableCaptchaTokenFetcher: { [weak self] in
                guard let `self` = self else {
                    V3LoginService.logger.error("self is nil")
                    return V3NormalConfig.defaultEnableCaptchaToken
                }
                guard let enableCaptchaToken = self.configInfo.config().enableCaptchaToken else {
                    V3LoginService.logger.error("config not has enableCaptchaToken")
                    return V3NormalConfig.defaultEnableCaptchaToken
                }
                return enableCaptchaToken
            })
        // TODO: suite session key 不再从 header 获取
//        helper.suiteSessionKey = getSessionKey()
        return helper
    }()

    lazy var credentialAPI: CredentialAPI = {
        let api = CredentialAPI()
        return api
    }()

    lazy var passportAPI: LoginAPI = {
        let api = LoginAPI()
        return api
    }()

    lazy var joinTeamAPI: JoinTeamAPIV3 = {
        return JoinTeamAPIV3()
    }()

    lazy var userCenterAPI: UserCenterAPI = {
        return UserCenterAPI()
    }()

    lazy var switchUserAPI: SwitchUserAPI = {
        return SwitchUserAPI()
    }()

    lazy var securityAPI: SecurityAPI = {
        return SecurityAPI()
    }()

    lazy var idpAPI: IdpAPI = {
        return IdpAPI()
    }()

    var securityResult: SecurityResult?
    var securityAppID: String?

    var suiteSessionKey: String? {
        set {
            // TODO: suite session key 不再从 header 获取
//            apiHelper.suiteSessionKey = newValue
        }
        get {
            return apiHelper.suiteSessionKey
        }
    }

    @Provider var deviceService: InternalDeviceServiceProtocol

    @Provider var envManager: EnvironmentInterface

    @Provider var httpClient: HTTPClient

    @Provider var eventRegistry: PassportEventRegistry // user:checked (global-resolve)

    var userName: String? {
        didSet {
            if let name = userName {
                V3LoginService.logger.info("set user name len: \(name.count)")
            } else {
                V3LoginService.logger.info("set user name nil")
            }
        }
    }

    lazy var store = PassportStore.shared
    weak var accountSecurityStartVC: UIViewController?

    let configuration: PassportConf

    let dependency: PassportDependency
    
    var interruptOperations: [InterruptOperation] = []

    private lazy var enableEnterAppUserListFixing: Bool = PassportGray.shared.getGrayValue(key: .enableEnterAppUserListFixing)

    init(
        configuration: PassportConf,
        dependency: PassportDependency
    ) {
        self.configuration = configuration
        self.dependency = dependency

        if !PassportSwitch.shared.enableLazySetupEventRegister {
            // 初始化设置event bus
            eventRegistry.setupEventRegister(eventBus: LoginPassportEventBus.shared)
        }

        // 初始化Device Service
        _ = PassportDeviceServiceWrapper.shared

        #if ONE_KEY_LOGIN
        UserDefaults.standard.register(defaults: [OneKeyLogin.isOneKeyLoginBeforeGuideKey: true])
        OneKeyLogin.updateIsOneKeyLoginBeforeGuide(UserDefaults.standard.bool(forKey: OneKeyLogin.isOneKeyLoginBeforeGuideKey))
        #endif

        V3LoginService.logger.info("init with env: \(envManager.env)", method: .local)
    }

    func inject(pattern: String?, regParams: [String: Any]?) {
        if pattern == nil && regParams == nil { return }

        if let pt = pattern {
            apiHelper.injectParams.pattern = pt
        }
        if let reg = regParams {
            apiHelper.injectParams.regParams = reg
        }
    }
}

extension V3LoginService {

    func register(interruptOperation observable: InterruptOperation) {
        Self.logger.info("n_action_register_interrupt", additionalData: [
            "interruptOperation": String(describing: observable)
        ])
        interruptOperations.append(observable)
    }

    func removeAllInterruptOperations() {
        Self.logger.info("n_action_remove_all_interrupt")
        interruptOperations.removeAll()
    }
}

extension V3LoginService {

    func refreshLoginConfig() {
        passportAPI.config(success: { [weak self] (info) in
            guard let `self` = self else { return }
            V3LoginService.logger.info("fetch v3 config: \(info)")
            self.configInfo = info
            #if ONE_KEY_LOGIN
            // app 进入后台不调用，内部实现会请求 idfv
            guard UIApplication.shared.applicationState == .active else {
                OneKeyLogin.logger.warn("n_action_one_key_login: update setting skipped when not active")
                return
            }
            // 在 Launch Guide 之前不调用，需要用户授权信息许可
            guard !OneKeyLogin.isOneKeyLoginBeforeGuide else {
                OneKeyLogin.logger.warn("n_action_one_key_login: update setting skipped before guide")
                return
            }
            OneKeyLogin.updateSetting(oneKeyLoginConfig: self.config.getOneKeyLoginConfig())
            #endif
        })
        deviceService.fetchDeviceId { (_) in }
        // has io not block main thread
        DispatchQueue.global().async {
            UploadLogger.shared.flushLog(UploadLogManager.shared, logined: self.store.isLoggedIn)
        }
    }

    func storeLoginConfig(_ type: SuiteLoginMethod, regionCode: String) {
        let config = V3UserLoginConfig(type: type, code: regionCode)
        store.userLoginConfig = config
    }

    func v4EnterApp(
        serverInfo: ServerInfo,
        userId: String? = nil,
        success: @escaping () -> Void,
        error: @escaping (EventBusError) -> Void,
        context: UniContextProtocol
    ) {
        self.passportAPI.v4EnterApp(serverInfo: serverInfo, userId: userId, context: context).post(context: context).subscribe(onNext: { (_) in
            Self.logger.info("v4 enterApp success")
            success()
        }, onError: { (postError) in
            // enterApp api error
            if let err = postError as? V3LoginError {
                Self.logger.error("v4 enterApp login error: \(err)")
                error(EventBusError.internalError(err))
            } else if let err = postError as? EventBusError {
                // post eventbus error
                Self.logger.error("v4 enterApp event bus error: \(err)")
                error(err)
            } else {
                // unexpected error
                Self.logger.errorWithAssertion("v4 enterApp error but not EventbusError or V3LoginError")
                error(EventBusError.internalError(.badServerData))
            }
        }).disposed(by: self.disposeBag)
    }

    func v4EnterEmailCreate(
        serverInfo: ServerInfo,
        tenantId: String,
        success: @escaping () -> Void,
        error: @escaping (EventBusError) -> Void,
        context: UniContextProtocol
    ) {
        self.passportAPI.v4EnterEmailCreate(serverInfo: serverInfo, tenantId: tenantId, context: context).post(context: context).subscribe(onNext: { (_) in
            Self.logger.info("v4 enterEmailCreate success")
            success()
        }, onError: { (postError) in
            // enterApp api error
            if let err = postError as? V3LoginError {
                Self.logger.error("v4 enterEmailCreate login error: \(err)")
                error(EventBusError.internalError(err))
            } else if let err = postError as? EventBusError {
                // post eventbus error
                Self.logger.error("v4 enterEmailCreate event bus error: \(err)")
                error(err)
            } else {
                // unexpected error
                Self.logger.errorWithAssertion("v4 enterEmailCreate error but not EventbusError or V3LoginError")
                error(EventBusError.internalError(.badServerData))
            }
        }).disposed(by: self.disposeBag)
    }

    func v4CreateTenant(
        serverInfo: ServerInfo,
        success: @escaping () -> Void,
        error: @escaping (EventBusError) -> Void,
        context: UniContextProtocol
    ) {
        self.passportAPI.v4CreateTenant(serverInfo: serverInfo, context: context).post(context: context).subscribe(onNext: { (_) in
            Self.logger.info("v4 createTenant success")
            success()
        }, onError: { (postError) in
            // enterApp api error
            if let err = postError as? V3LoginError {
                Self.logger.error("v4 createTenant login error: \(err)")
                error(EventBusError.internalError(err))
            } else if let err = postError as? EventBusError {
                // post eventbus error
                Self.logger.error("v4 createTenant event bus error: \(err)")
                error(err)
            } else {
                // unexpected error
                Self.logger.errorWithAssertion("v4 createTenant error but not EventbusError or V3LoginError")
                error(EventBusError.internalError(.badServerData))
            }
        }).disposed(by: self.disposeBag)
    }

    private func sceneFromSceneInfo(sceneInfo: [String: String]) -> MultiSceneMonitor.Scene? {
        if let sceneString = sceneInfo[MultiSceneMonitor.Const.scene.rawValue],
            let scene = MultiSceneMonitor.Scene(rawValue: sceneString) {
            return scene
        }
        return nil
    }
    
    /// 在 enter_app step 之后调用，替代原先 finalEnterApp() 和 loginWithInfo()
    func enterAppDidCall(enterAppInfo: V4EnterAppInfo,
                         sceneInfo: [String: String],
                         success: @escaping () -> Void,
                         error: @escaping (V3LoginError) -> Void,
                         context: UniContextProtocol) {

        MultiSceneMonitor.shared.record(scene: .enterApp)
        Self.logger.info("n_action_enter_app", body: "Current uni context from: \(context.from)", method: .local)
        if let firstUser = enterAppInfo.userList.first {
            Self.logger.info("n_action_enter_app", body: "First user data is - tenant_brand: \(firstUser.user.tenant.brand); geo: \(firstUser.userGeo); unit: \(firstUser.user.unit)")
        }

        // remove from hidden
        userManager.removeHiddenUserByIDs(enterAppInfo.userList.compactMap({ $0.userID }))

        //切换租户流程
        if context.from == .continueSwitch {
            // 切换流程
            enterAppFromSwitchUser(enterAppInfo: enterAppInfo)
            return
        }


        if MultiUserActivitySwitch.enableMultipleUser {

            PassportMonitor.flush(PassportMonitorMetaStep.startEnterApp,
                                  eventName: ProbeConst.monitorEventName,
                                  categoryValueMap: ["type": PassportMonitorMetaStepEnterAppWorkflowProcessType],
                                  context: context)
            ProbeDurationHelper.startDuration(ProbeDurationHelper.enterAppFlow)

            if userManager.foregroundUser == nil { // user:current
                // 端外登录
                Self.logger.info("n_action_enter_app", body: "outer login workflow")
                enterAppFromOuterLoginOrRegisterV2(enterAppInfo: enterAppInfo, isFromRetry: false, successCallback: success, errorCallback: error)

            } else {
                // 端内登录
                Self.logger.info("n_action_enter_app", body: "switch user workflow")
                enterAppSwitchUserWorkflow(enterAppInfo: enterAppInfo, successCallback: success, errorCallback: error)
            }
        } else {

            PassportMonitor.flush(PassportMonitorMetaStep.startEnterApp,
                                  eventName: ProbeConst.monitorEventName,
                                  context: context)
            ProbeDurationHelper.startDuration(ProbeDurationHelper.enterAppFlow)

            if userManager.foregroundUser == nil { // user:current
                // 端外登录
                Self.logger.info("n_action_enter_app", body: "outer login legacy")
                enterAppFromOuterLoginOrRegister(enterAppInfo: enterAppInfo, success: success, error: error)
            } else {
                // 端内登录
                Self.logger.info("n_action_enter_app", body: "inner login legacy")
                enterAppFromInnerLoginOrRegister(enterAppInfo: enterAppInfo, success: success, error: error)
            }
        }
    }

    /// 切换用户
    private func enterAppFromSwitchUser(enterAppInfo: V4EnterAppInfo) {
        Self.logger.info("n_action_enter_app_from_switch_user")
        newSwitchUserService.continueSwitch(enterAppInfo: enterAppInfo)
    }

    //端外登录处理流程
    private func enterAppFromOuterLoginOrRegisterV2(enterAppInfo: V4EnterAppInfo,
                                                    isFromRetry: Bool,
                                                    successCallback: @escaping () -> Void,
                                                    errorCallback: @escaping (V3LoginError) -> Void) {

        guard let newForegroundUser = enterAppInfo.userList.first,
              newForegroundUser.isActive else {
            Self.logger.info("n_action_enter_app", body: "switch user workflow")
            enterAppSwitchUserWorkflow(enterAppInfo: enterAppInfo, successCallback: successCallback, errorCallback: errorCallback)
            return
        }
        //登录流程已经完成，回调成功；后续为初始化数据流程，初始化失败会有对应的重试逻辑
        successCallback()

        let loadingHUD = PassportLoadingService.showLoadingOnWindow()

        let context = UniContextCreator.create(.enterApp)

        let workflow = (saveUserListHasSideEffectTask(context: context) --> //更新userList到本地
                        getNewForegroundUserFromUserListTask(context: context) --> //获取新的前台用户
                        updateForegroundUserHasSideEffectTask(context: context, action: .login)) //刷新activity user list

        workflow.runnable(enterAppInfo.userList).execute { newForegroundUser in
            //执行成功
            self.envLogger.info("n_action_enter_app_with_env: \(self.envManager.env).", method: .local)

            UploadLogManager.shared.userId = newForegroundUser.userID
            PassportProbeHelper.shared.userID = newForegroundUser.userID
            self.store.loginMethod = self.store.userLoginConfig?.loginType ?? .phoneNumber

            #if ONE_KEY_LOGIN
            OneKeyLogin.loginSucceed()
            #endif

            MigrationMonitor.shared.end(scene: .migration)

            self.monitorEnterAppEventResult(isSucceeded: true, errorMsg: nil, type: PassportMonitorMetaStepEnterAppWorkflowProcessType)

            //通过enterAppUserListCallback 切换bootManager到loginSuccessFlow
            self.enterAppUserListCallback?(enterAppInfo.userList)

            //更新登录状态
            self.loginStateSub.accept(.logined)

            //后续还有bootManager的初始化流程，这里不移除loading toast, 页面重建时自动移除

        } failureCallback: {[weak self] error in
            Self.logger.error("n_action_enter_app_failed", body: "login workflow", error: error)
            self?.monitorEnterAppEventResult(isSucceeded: false, errorMsg: (error as NSError).localizedDescription)

            //移除loading
            loadingHUD?.remove()

            //执行失败
            if let topVC = PassportNavigator.topMostVC {
                let alertVC = LarkAlertController()
                alertVC.setTitle(text: BundleI18n.suiteLogin.Lark_Legacy_Hint)
                alertVC.setContent(text: isFromRetry ? BundleI18n.suiteLogin.Lark_Passport_LoginSessionError_InitializationFailedRestartClient_Desc : BundleI18n.suiteLogin.Lark_Passport_LoginSessionError_InitializationFailedTryAgain_Desc)
                alertVC.addPrimaryButton(text: isFromRetry ? BundleI18n.suiteLogin.Lark_Passport_LoginSessionError_InitializationFailedRestartClient_Confirm_Button : BundleI18n.suiteLogin.Lark_Passport_LoginSessionError_InitializationFailedTryAgain_TryAgain_Button, dismissCompletion: {[weak self] in
                    if isFromRetry {
                        exit(0)
                    } else {
                        self?.enterAppFromOuterLoginOrRegisterV2(enterAppInfo: enterAppInfo, isFromRetry: true, successCallback: successCallback, errorCallback: errorCallback)
                    }
                })
                topVC.present(alertVC, animated: true)
            }
        }
    }

    /// 端内登录/注册
    private func enterAppSwitchUserWorkflow(enterAppInfo: V4EnterAppInfo,
                                                  successCallback: @escaping () -> Void,
                                                  errorCallback: @escaping (V3LoginError) -> Void) {

        let context = UniContextCreator.create(.enterApp)
        var additionInfo: SwitchUserContextAdditionInfo? = nil
        if let toast = enterAppInfo.toast, !toast.isEmpty {
            additionInfo = SwitchUserContextAdditionInfo(toast: toast)
        }

        let workflow = (saveUserListHasSideEffectTask(context: context) --> //更新userList到本地
                        getNewForegroundUserFromUserListTask(context: context) --> //获取新的前台用户
                        fastSwitchUserTask(context: context, additionInfo: additionInfo))

        workflow.runnable(enterAppInfo.userList).execute { [weak self] in

            guard let self = self else {
                Self.logger.error("Self lost in enter app inner")
                return
            }

            //更新state
            self.loginStateSub.accept(.logined)
            self.monitorEnterAppEventResult(isSucceeded: true, errorMsg: nil, type: PassportMonitorMetaStepEnterAppWorkflowProcessType)

            // 某些 KA 不允许多账号同时登录，此时登出其他租户并提示 https://bytedance.feishu.cn/docs/doccnfLmKuFekUh9p7kbH3XvPMb
            if let userInfo = self.getCurrentUser(), userInfo.user.excludeLogin ?? false {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    if let rootVC = PassportNavigator.keyWindow?.rootViewController {
                        let alert = LarkAlertController()
                        alert.setContent(text: I18N.Lark_Passport_MultipleAccount_JoinAutoLogoutPopup(userInfo.user.tenant.name))
                        alert.addSecondaryButton(text: I18N.Lark_Passport_MultipleAccount_JoinAutoLogoutPopupButton)

                        rootVC.present(alert, animated: true, completion: nil)
                    }
                }

                self.logoutService.relogin(conf: .background, onError: { errorMessage in
                    Self.logger.error("Failed to relogin for exclude login: \(errorMessage)")
                }, onSuccess: { _ in
                    Self.logger.info("Succeeded to relogin for exclude login")
                }, onInterrupt: {
                    Self.logger.error("Interrupted relogin for exclude login")
                })
            }

        } failureCallback: {[weak self] error in
            Self.logger.error("n_action_enter_app_failed", body: "switch workflow", error: error)
            self?.monitorEnterAppEventResult(isSucceeded: false, errorMsg: (error as NSError).localizedDescription, type: PassportMonitorMetaStepEnterAppWorkflowProcessType)
            errorCallback(V3LoginError.clientError((error as NSError).localizedDescription))
        }
    }


    /// 端外登录/注册
    private func enterAppFromOuterLoginOrRegister(enterAppInfo: V4EnterAppInfo,
                                                  success: @escaping () -> Void,
                                                  error: @escaping (V3LoginError) -> Void) {
        Self.logger.info("n_action_enter_app_from_OUTER_login_or_register", method: .local)

        guard let selectedUser = enterAppInfo.userList.first else {
            let e = V3LoginError.badResponse("enterAppInfo user null")
            error(e)
            Self.logger.error("n_action_enter_app_no_user_OUTER", error: e)
            monitorEnterAppEventResult(isSucceeded: false, errorMsg: "nil foreground user")
            return
        }

        if !enableEnterAppUserListFixing {
            userManager.setEnterAppUserList(enterAppInfo.userList)
        }

        var additionInfo: SwitchUserContextAdditionInfo? = nil
        if let toast = enterAppInfo.toast, !toast.isEmpty {
            additionInfo = SwitchUserContextAdditionInfo(toast: toast)
        }

        let appUnit = envManager.env.unit
        let geo = selectedUser.user.geo
        let appBrand = envManager.tenantBrand
        let userBrand = selectedUser.user.tenant.brand
        guard let userUnit = selectedUser.user.unit else {
            let e = V3LoginError.badResponse("enterAppInfo user hasn't got unit: \(selectedUser.user.unit) or geo: \(selectedUser.user.geo).")
            error(e)
            Self.logger.error("n_action_enter_app_no_user_unit_or_isOverseaUnit_OUTER", error: e)
            monitorEnterAppEventResult(isSucceeded: false, errorMsg: "nil user unit")
            return
        }

        // 完成端外登录的收尾工作
        func process() {
            self.envLogger.info("n_action_enter_app_with_env: \(envManager.env).", method: .local)

            //先获取当前的 vc, 避免后续再获取的是错误的 vc(后续涉及到 UI 堆栈的重建)
            let topVC = PassportNavigator.topMostVC

            userManager.setEnterAppUserList(enterAppInfo.userList)
            userManager.updateForegroundUser(enterAppInfo.userList.first) // user:current

            UploadLogManager.shared.userId = selectedUser.userID
            PassportProbeHelper.shared.userID = selectedUser.userID
            store.loginMethod = store.userLoginConfig?.loginType ?? .phoneNumber

            #if ONE_KEY_LOGIN
            OneKeyLogin.loginSucceed()
            #endif


            MigrationMonitor.shared.end(scene: .migration)

            monitorEnterAppEventResult(isSucceeded: true, errorMsg: nil)

            enterAppUserListCallback?(enterAppInfo.userList)
            loginStateSub.accept(.logined)

            success()

            //提示 loading, 后面会执行 setupMainTask, 重置 UI
            if let view = topVC?.view {
                PassportLoadingService.shared.showLoading(on: view)
            }
        }

        // 登录时不需要跨端，正常完成接下去的流程
        if userUnit == appUnit && userBrand == appBrand {
            if selectedUser.isAnonymous {
                //上报埋点
                PassportMonitor.flush(EPMClientPassportMonitorUniversalDidCode.passport_login_invalid_session,
                                      eventName: ProbeConst.monitorEventName,
                                      categoryValueMap: ["type": PassportStore.shared.universalDeviceServiceUpgraded ? 2 : 1],
                                      context: UniContextCreator.create(.enterApp))
                monitorEnterAppEventResult(isSucceeded: false, errorMsg: "selected user's session is anonymous")
                
                let e = V3LoginError.badResponse("invalid session")
                error(e)
                Self.logger.error("n_action_enter_app_no_user_OUTER", error: e)
                assertionFailure("something wrong, please contact passport")
                return
            }
            process()
            return
        }

        // 登录时跨端，先切换环境
        // 如果 session 有效，继续普通登录流程
        // 如果 session 匿名，走 switch
        envLogger.info("n_action_enter_cross_start")

        // MultiGeo updated
        let futureEnv = Env(unit: userUnit, geo: geo, type: envManager.env.type)
        envLogger.info("n_action_enter_cross_switch_start")

        if !enableEnterAppUserListFixing {
            userManager.setEnterAppUserList(enterAppInfo.userList)
        }
        envManager.switchEnvAndUpdateDeviceInfo(futureEnv: futureEnv, brand: selectedUser.user.tenant.brand) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(_):
                self.envLogger.info("n_action_enter_cross_switch_succ")
                if case .invalid = selectedUser.userStatus {
                    self.monitorEnterAppEventResult(isSucceeded: true, errorMsg: nil)
                    // anonymous session，先切环境，拿到新 device id，走 switch
                    success()
                    // 此时本地没有存储的 user，使用 switchTo(userInfo:) 接口
                    self.newSwitchUserService.switchTo(userInfo: selectedUser,
                                                       complete: { isSucc in
                        if !isSucc {
                            error(V3LoginError.badResponse(I18N.Lark_Passport_BadServerData))
                        }
                        if self.enableEnterAppUserListFixing {
                            // 添加list时，前台用户已经通过switch加入，这里不再set（同时也避免有效session被匿名session覆盖）
                            self.userManager.setEnterAppUserList(enterAppInfo.userList.filter { $0.userID != selectedUser.userID })
                        }
                    },
                                                       additionInfo: additionInfo,
                                                       context: UniContextCreator.create(.enterApp))
                } else {
                    // employee session，只需要切环境
                    self.envLogger.info("n_action_enter_cross: Fetch employee session! Only switch unit.")
                    process()
                }
            case .failure(let e):
                self.envLogger.error("n_action_enter_cross_switch_fail", error: e)
                self.envLogger.error("n_action_clean_env", error: e)
                self.envManager.resetEnv(completion: nil)
                self.monitorEnterAppEventResult(isSucceeded: false, errorMsg: "switch env failed")
                error(V3LoginError.badServerData)
            }
        }
    }

    /// 端内登录/注册
    private func enterAppFromInnerLoginOrRegister(enterAppInfo: V4EnterAppInfo,
                                                  success: @escaping () -> Void,
                                                  error: @escaping (V3LoginError) -> Void) {
        Self.logger.info("n_action_enter_app_from_INNER_login_or_register")

        if !enableEnterAppUserListFixing {
            // 更新 user 信息到 user manager
            userManager.setEnterAppUserList(enterAppInfo.userList)
        }

        // 端内登录
        guard let user = enterAppInfo.userList.first else {
            let e = V3LoginError.badResponse("enterAppInfo user null")
            error(e)
            Self.logger.error("n_action_enter_app_no_user_INNER", error: e)
            monitorEnterAppEventResult(isSucceeded: false, errorMsg: "nil foreground user")
            return
        }

        var additionInfo: SwitchUserContextAdditionInfo? = nil
        if let toast = enterAppInfo.toast, !toast.isEmpty {
            additionInfo = SwitchUserContextAdditionInfo(toast: toast)
        }

        newSwitchUserService.switchTo(
            enterApp: enterAppInfo,
            complete: { [weak self] result in

                success()

                guard let self = self else {
                    Self.logger.error("Self lost in enter app inner")
                    return
                }
                if !result {
                    self.monitorEnterAppEventResult(isSucceeded: false, errorMsg: "switch user failed")
                    Self.logger.error("Failed to switch user")
                    return
                }
                if self.enableEnterAppUserListFixing {
                    // 添加list时，前台用户已经通过switch加入，这里不再set（同时也避免有效session被匿名session覆盖）
                    self.userManager.setEnterAppUserList(enterAppInfo.userList.filter { $0.userID != user.userID })
                }

                self.monitorEnterAppEventResult(isSucceeded: true, errorMsg: nil)

                // 某些 KA 不允许多账号同时登录，此时登出其他租户并提示 https://bytedance.feishu.cn/docs/doccnfLmKuFekUh9p7kbH3XvPMb
                if let userInfo = self.getCurrentUser(), userInfo.user.excludeLogin ?? false {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        if let rootVC = PassportNavigator.keyWindow?.rootViewController {
                            let alert = LarkAlertController()
                            alert.setContent(text: I18N.Lark_Passport_MultipleAccount_JoinAutoLogoutPopup(userInfo.user.tenant.name))
                            alert.addSecondaryButton(text: I18N.Lark_Passport_MultipleAccount_JoinAutoLogoutPopupButton)

                            rootVC.present(alert, animated: true, completion: nil)
                        }
                    }

                    self.logoutService.relogin(conf: .background, onError: { errorMessage in
                        Self.logger.error("Failed to relogin for exclude login: \(errorMessage)")
                    }, onSuccess: { _ in
                        Self.logger.info("Succeeded to relogin for exclude login")
                    }, onInterrupt: {
                        Self.logger.error("Interrupted relogin for exclude login")
                    })
                }
            },
            additionInfo: additionInfo,
            context: UniContextCreator.create(.enterApp))
    }

    private func monitorEnterAppEventResult(isSucceeded: Bool, errorMsg: String?, type: Int? = nil) {
        let duration = ProbeDurationHelper.stopDuration(ProbeDurationHelper.enterAppFlow)
        var additionInfo = [ProbeConst.duration: duration]
        if let type = type { additionInfo["type"] = type }
        let monitor = PassportMonitor.monitor(PassportMonitorMetaStep.enterAppResult,
                                              eventName: ProbeConst.monitorEventName,
                                              categoryValueMap: additionInfo,
                                              context: UniContextCreator.create(.enterApp))
        if isSucceeded {
            monitor.setResultTypeSuccess().flush()
        } else {
            monitor.setResultTypeFail().setErrorMessage(errorMsg).setErrorCode(ProbeConst.commonInternalErrorCode).flush()
        }
    }

    public func getAccountPhoneNumbers(
        callback: @escaping (Result<[PhoneNumber], Error>) -> Void
    ) {
        userCenterAPI.fetchCredentialList()
            .subscribe(onNext: { (cps) in
                let phoneNumbers = cps.compactMap({ (credential) -> PhoneNumber? in
                    guard credential.type == .phone, let mobile = credential.contact.mobile else {
                        return nil
                    }
                    return PhoneNumber(mobile.countryCode, mobile.phoneNumber)
                })
                callback(.success(phoneNumbers))
            }, onError: { (error) in
                callback(.failure(error))
            })
            .disposed(by: disposeBag)
    }

    func getSecurityStatus(appId: String, result: @escaping SecurityResult, context: UniContextProtocol) {
        securityResult = result
        securityAppID = appId

        let window = PassportNavigator.keyWindow
        var hud: UDToast? = nil
        if let window = window {
            hud = UDToast.showDefaultLoading(on: window)
        }
        Self.logger.info("n_action_get_security_status_start")
        _ = securityAPI.checkSecurityPasswordStatus { resp in
            Self.logger.info("n_action_get_security_status_succ")
            
            hud?.remove()
            LoginPassportEventBus.shared.post(
                event: resp.stepData.nextStep,
                context: V3RawLoginContext(stepInfo: resp.stepData.stepInfo, context: context),
                success: {},
                error: {_ in })
        } failure: { [weak self] error in
            Self.logger.error("n_action_get_security_status_failed", error: error)

            hud?.remove()
            if let window = window {
                UDToast.showFailure(with: error.localizedDescription, on: window)
            } else {
                Self.logger.errorWithAssertion("no main scene for getSecurityStatus")
            }
            result(SecurityResultCode.userCancelOrFailed, error.localizedDescription, nil)
            self?.securityResult = nil
        }
    }

    func getCurrentSecurityPwdStatus(callback: @escaping (Bool, Error?) -> Void) {
        securityAPI.checkSecurityPasswordStatus(completion: callback)
    }

    public func activeAccount(callback: @escaping SuiteLoginCallback) {
        self.loginCallback = callback
    }

    public func makeUserForeground(callback: @escaping EnterAppUserListCallback) {
        self.enterAppUserListCallback = callback
    }

    func reset() {
        // reset 本地数据时，同时重置环境
        Self.logger.info("n_action_reset_in_v3_login_service_start", method: .local)

        envManager.resetEnv(completion: nil)

        store.reset()

        setDeviceInfoAPI
            .setDeviceInfo(deviceId: "", installId: "")
            .subscribe(onNext: { _ in
                Self.logger.info("n_action_reset_in_login_service_succ", method: .local)
            }, onError: { error in
                Self.logger.error("n_action_reset_in_login_service_failed", error: error)
            })
            .disposed(by: disposeBag)
    }

    public func getCurrentUser() -> V4UserInfo? {
        return self.store.foregroundUser // user:current
    }

    public func storeCountryCode(code: String) {
        self.store.regionCode = code
    }

    public func getCountryCode() -> String? {
        return self.store.regionCode
    }

    func revertEnvIfNeeded() {
        Self.logger.info("Revert env if needed start v3ConfigEnv: \(store.configEnv) env: \(envManager.env)", method: .local)
        // 未有登录态 重置环境
        self.store.resetConfigEnv()
        OPMonitor(EPMClientPassportLoginCode.passport_env_will_switch)
                    .addCategoryValue("deviceID", self.deviceService.deviceId)
                    .addCategoryValue("installID", self.deviceService.installId)
                    .flush()

        envManager.resetEnv { [weak self] succeeded in
            guard let self = self else { return }
            if succeeded {
                Self.logger.info("Reset env succeeded. Current configEnv: \(self.store.configEnv); env: \(self.envManager.env)", method: .local)
                OPMonitor(EPMClientPassportLoginCode.passport_env_did_switch)
                                    .addCategoryValue("deviceID", self.deviceService.deviceId)
                                    .addCategoryValue("installID", self.deviceService.installId)
                                    .flush()
            } else {
                Self.logger.error("Reset env failed. Now configEnv: \(self.store.configEnv) env: \(self.envManager.env)")
            }
        }
    }
}

extension V3LoginService {
    class func jsonToObj<T: Codable>(type: T.Type, json: [AnyHashable: Any]) -> T? {
        return SuiteLoginUtil.jsonToObj(type: type, json: json)
    }

    class func jsonArrayToObj<T: Codable>(type: T.Type, json: [Any]) -> T? {
        return SuiteLoginUtil.jsonArrayToObj(type: type, json: json)
    }
}

extension V3LoginService {
    var topCountryList: [String] {
        return configInfo.config().topCountryList(for: store.configEnv)
    }

    var blackCountryList: [String] {
        return configInfo.config().blackCountryList(for: store.configEnv)
    }

    var config: V3NormalConfig {
        return configInfo.config()
    }
}

extension V3LoginService {
    func handleSSOLogin(
        _ ssoDomain: String,
        tenantName: String,
        refreshUserListBlock: @escaping () -> Observable<Void>,
        switchUserBlock: @escaping (String, @escaping (Bool) -> Void) -> Void,
        context: UniContextProtocol
    ) {
        self.enterpriseLoginSchemeService.handleSSOLogin(
            ssoDomain,
            tenantName: tenantName,
            refreshUserListBlock: refreshUserListBlock,
            switchUserBlock: switchUserBlock,
            context: context
        )
    }

    func handleSSOLoginCallback(
        _ token: String,
        fromVC: UIViewController,
        context: UniContextProtocol
    ) {
        Self.logger.info("n_action_idp_auth_external_suc")
        
        guard let tokenString = token.passport_fromBase64() else {
            Self.logger.error("n_action_idp_auth_external_fail", additionalData: ["msg" : "fail to decode token: \(token)"])
            return
        }
        
        func onError(errorMessage: String?, fromVC: UIViewController) {
            if let errorMessage = errorMessage, errorMessage.count > 0, let view = fromVC.navigationController?.view {
                UDToast.showFailure(with: errorMessage, on: view)
            }
            fromVC.navigationController?.popViewController(animated: true)
        }

        do {
            guard self.idpWebViewService.isPageValidFor(vc: fromVC) else {
                Self.logger.error("n_action_idp_auth_external_fail", additionalData: ["msg" : "not in the right page"])
                return
            }

            let response = try JSONDecoder().decode(IDPLoginCallBackResponse.self, from: Data(tokenString.utf8))
            guard self.idpWebViewService.isSecurityIdMatch(identifier: response.securityId) else {
                Self.logger.error("n_action_idp_auth_external_fail", additionalData: ["msg" : "Secufity ids do not match"])
                
                onError(errorMessage: BundleI18n.suiteLogin.Lark_Passport_SSOLogin_VerifyExpireToast, fromVC: fromVC)
                return
            }
            
            Self.logger.info("n_action_idp_auth_security_suc")

            guard response.code == 0 else {
                Self.logger.error("n_action_idp_auth_external_fail", additionalData: ["msg" : "Response code: \(response.code)"])
                
                onError(errorMessage: response.message, fromVC: fromVC)
                return
            }

            Self.logger.info("sso branch: will send request")

            UDToast.showDefaultLoading(on: fromVC.view)

            self.idpWebViewService.fetchNext(state: response.state) {
                UDToast.removeToast(on: fromVC.view)
                Self.logger.info("sso branch: succeed to fetch next")
            } errorCallback: { error in
                Self.logger.error("sso branch: fail to fetch next: \((error as NSError).localizedDescription)")
                UDToast.removeToast(on: fromVC.view)
                var message: String?
                if let error = error as? V3LoginError,
                   case .badServerCode(let info) = error {
                    message = info.message
                }
                onError(errorMessage: message, fromVC: fromVC)
            }
        } catch {
            Self.logger.error("sso branch: fail to serialize info from tokenString: \(tokenString), error: \((error as NSError).localizedDescription)")
            onError(errorMessage: (error as NSError).localizedDescription, fromVC: fromVC)
        }
    }
    
    func handleInAppInviteLogin(
        customDomain: String?,
        serverInfo: ServerInfo,
        userID: String,
        fromVC: UIViewController?,
        context: UniContextProtocol
    ){
        let containerVC = fromVC ?? PassportNavigator.topMostVC
        
        func handleError(_ error: Error){
            if let vc = containerVC {
                UDToast.removeToast(on: vc.view)
                UDToast.showFailure(with: error.localizedDescription, on: vc.view)
            }
        }
        //开始 loading
        if let vc = containerVC {
            UDToast.showDefaultLoading(on: vc.view)
        }
        
        //激活账号
        self.passportAPI
            .v4EnterApp(customDomain: customDomain, serverInfo: serverInfo, userId: userID, context: context)
            .observeOn(MainScheduler.instance)
            .subscribe {[weak self] resp in
                //隐藏 loading
                if let vc = containerVC {
                    UDToast.removeToast(on: vc.view)
                }
                
                //先回到主 feed 页面然后再 post
                LoginPassportEventBus.shared.post(
                    event: resp.stepData.nextStep,
                    context: V3RawLoginContext(
                        stepInfo: resp.stepData.stepInfo,
                        backFirst: true,
                        context: context
                    ),
                    success: {
                       
                    }, error: { error in
                       handleError(error)
                    })
            
        } onError: { error in
            handleError(error)
        }.disposed(by: self.disposeBag)
    }
}

