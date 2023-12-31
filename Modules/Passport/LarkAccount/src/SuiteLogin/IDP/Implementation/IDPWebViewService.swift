//
//  IDPWebViewService.swift
//  SuiteLogin
//
//  Created by tangyunfei.tyf on 2020/1/13.
//

import Foundation
import RxSwift
import LKCommonsLogging
import RxRelay
import RoundedHUD
import LarkAlertController
import LarkPerf
import LarkContainer
import ECOProbeMeta

#if SUITELOGIN_KA
import AnyCodable
import LarkReleaseConfig
import LarkSetting
import Reachability
#endif

// MARK: IDPWebViewService
enum IDPLoginStepStatus<Input, Output> {
    case notTriger(Input)
    case loading
    case success(Output)
    case failure(Error)
}

enum IDPLoginStep {
    // .asyncsDomainSettings -> .asyncIdpConfig -> .idpLogin -> .idpDispatch -> .postIdpLogin
    case asyncDomainSetting(AsynGetDynamicDomainStatus)
    case asyncIdpConfig(IDPLoginStepStatus<String?, IDPConfigModel>)
    case idpLogin(IDPLoginStepStatus<IDPAuthConfigModel, IDPLoginJSBResponse>)
    case idpDispatch(IDPLoginStepStatus<IDPLoginJSBResponse, V3.Step>)
    case postIdpLogin(IDPLoginStepStatus<V3.Step, Void>)
}

class IDPWebViewService: IDPLoginServiceProtocol {

    private var success: V3IDPLoginSuccess = nil

    private var error: V3IDPLoginError = nil

    private let configuration: PassportConf = PassportConf.shared

    private var loginStateSub: BehaviorRelay<V3LoginState> {
        loginService.loginStateSub
    }

    private var apiHelper: V3APIHelper {
        loginService.apiHelper
    }

    private var webViewContainerService: IDPWebViewContainerService?

    private var errorHandler: V3ErrorHandler?

    private let disposeBag = DisposeBag()

    private var idpAuthConfig: IDPAuthConfigModel?

    private var idpConfig: IDPConfigModel?

    private var loginStep: BehaviorRelay<IDPLoginStep>?

    private var indicatedIDPCacheKey = genKey("com.bytedance.ee.idp.indicatedIDP")

    private var indicatedIDP: String? {
        get {
            /// IDP 名称不允许为空字符串
            if let idpName = PassportStore.shared.indicatedIDP, !idpName.isEmpty {
                return idpName
            }
            return nil
        }
        set {
            PassportStore.shared.indicatedIDP = newValue
        }
    }

    private var webErrorHandler: V3ErrorHandler?

    private var needRetry: Bool = true

    lazy var api: IdpAPI = { return IdpAPI() }()

    private lazy var defaultEventBus: PassportEventBusProtocol = {
        return LoginPassportEventBus.shared
    }()

    private var passportEventBus: PassportEventBusProtocol?

    @Provider var dependency: PassportDependency // user:checked (global-resolve)

    @Provider var loginService: V3LoginService

    @Provider var dynamicDomainService: DynamicDomainService
    
    #if SUITELOGIN_KA
    /// 使用通用的 IdP Service 承载 KA 逻辑
    @InjectedLazy var kaLoginManager: KaLoginManager
    #endif

    var context: UniContextProtocol?

    static let logger = Logger.plog(IDPWebViewService.self, category: "SuiteLogin.IDP.IDPWebViewService")

    init() {
        self.subscriteLoginState()
    }

    func isPageValidFor(vc: UIViewController) -> Bool {
        if vc !=  self.webViewContainerService?.currentController() {
            return false
        }

        return true
    }

    func isSecurityIdMatch(identifier: String) -> Bool {
        guard let idpConfig = self.idpConfig, let authConfig = idpConfig.authConfig else {
            return false
        }

        if identifier != authConfig.securityId {
            return false
        }

        return true
    }

    func loginPageForIDPName(
        _ idpName: String?,
        context: UniContextProtocol,
        success: V3IDPLoginSuccess,
        error: V3IDPLoginError
    ) -> UIViewController {
        self.success = success
        self.error = error

        self.indicatedIDP = idpName ?? self.indicatedIDP
        self.loginStep = BehaviorRelay(value: IDPLoginStep.asyncDomainSetting(.notTriger))
        // swiftlint:disable ForceUnwrapping
        let webViewContainerService = IDPWebViewContainerService(url: URL(string: CommonConst.aboutBlank)!, dependency: dependency)
        // swiftlint:enable ForceUnwrapping
        self.webViewContainerService = webViewContainerService
        self.errorHandler = V3ErrorHandler(
            vc: webViewContainerService.currentController(),
            context: context,
            contextExpiredPostEvent: false,
            showToastOnWindow: true
        )
        self.context = context
        self.passportEventBus = defaultEventBus
        self.needRetry = true
        self.subscribeForIDP(webViewContainerService)
        return webViewContainerService.currentController()
    }

    // 在这里处理 Web IdP 的返回
    func loginPageForIDPLoginInfo(
        _ idpLoginInfo: IDPLoginInfo,
        context: UniContextProtocol,
        passportEventBus: PassportEventBusProtocol?,
        switchUserStatusSub: PublishSubject<SwitchUserStatus>?,
        from: UIViewController,
        success: V3IDPLoginSuccess,
        error: V3IDPLoginError
    ) {
        self.success = success
        self.error = error

        guard URL(string: idpLoginInfo.url) != nil,
              let idpConfig = self.assembleIDPConfigFromIDPLoginInfo(idpLoginInfo),
              let authConfig = idpConfig.authConfig else {
            self.error?(V3LoginError.badResponse("can not generate config from idpLoginInfo: \(idpLoginInfo.url)"))
            IDPWebViewService.logger.info("failed to create config from idpLoginInfo: \(idpLoginInfo.url)")
            return
        }
        self.idpConfig = idpConfig
        self.loginStep = BehaviorRelay(value: IDPLoginStep.idpLogin(.notTriger(authConfig)))
        // swiftlint:disable ForceUnwrapping
        let webViewContainerService = IDPWebViewContainerService(url: URL(string: CommonConst.aboutBlank)!, dependency: dependency, customUserAgent: self.idpConfig?.userAgent)
        // swiftlint:enable ForceUnwrapping
        self.webViewContainerService = webViewContainerService
        self.errorHandler = V3ErrorHandler(
            vc: webViewContainerService.currentController(),
            context: context,
            contextExpiredPostEvent: false,
            showToastOnWindow: true
        )
        if let eventBus = passportEventBus {
            self.passportEventBus = eventBus
        } else {
            self.passportEventBus = defaultEventBus
        }
        self.webErrorHandler = IDPWebErrorHandler(
            vc: webViewContainerService.currentController(),
            context: context,
            contextExpiredPostEvent: false,
            showToastOnWindow: true,
            eventBus: passportEventBus,
            switchUserStatusSub: switchUserStatusSub
        )
        self.context = context
        self.needRetry = false
        self.subscribeForIDP(webViewContainerService)

        let vc = webViewContainerService.currentController()
        self.success?(.inAppWebPage(vc: vc))
    }

    var switchIDPCompletion: ((Bool, Error?) -> Void)?
    func switchIDP(_ idpName: String, completion: @escaping (Bool, Error?) -> Void) {
        IDPWebViewService.logger.info("switch to idp: \(idpName)")
        self.switchIDPCompletion = completion
        self.indicatedIDP = idpName
        self.idpConfig = nil
        self.updateStep(.asyncIdpConfig(.notTriger(self.indicatedIDP)))
    }

    func fetchConfigForIDP(_ body: SSOUrlReqBody) -> Observable<V3.Step> {
        indicatedIDP = body.idpName
        
        return api.fetchConfigForIDP(body)
    }

    func fetchNext(state: String, successCallback: (() -> Void)?, errorCallback: V3IDPLoginError) {
        Self.logger.info("n_action_idp_auth_dispatch_req")
        
        api.fetchNext(state: state)
            .do(onNext: { [weak self] step in
                guard let self = self else { return }
                PassportMonitor.flush(EPMClientPassportMonitorLoginCode.idp_b_login_idp_dispatch_request_succ, categoryValueMap: [
                    "next_step" : step.stepData.nextStep
                ], context: self.context ?? UniContextCreator.create(.unknown))
            })
            .post(context: self.context ?? UniContextCreator.create(.unknown))
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                Self.logger.info("n_action_idp_auth_dispatch_req_suc")
                PassportMonitor.flush(EPMClientPassportMonitorLoginCode.idp_b_login_end_goto_next_succ, context: self.context ?? UniContextCreator.create(.unknown))
                
                successCallback?()
            }, onError: { error in
                Self.logger.error("n_action_idp_auth_dispatch_req_fail", error: error)
                
                errorCallback?(error)
            })
            .disposed(by: self.disposeBag)
    }
}

extension IDPWebViewService {
    // MARK: step
    private func updateStep(_ step: IDPLoginStep) {
        self.loginStep?.accept(step)
    }

    private func handle(_ step: IDPLoginStep) {
        IDPWebViewService.logger.info("IDPLogin handle step: \(step)")
        switch step {
        case .asyncDomainSetting(let status):
            handleAsyncInitSetting(status)
        case .asyncIdpConfig(let status):
            handleAsyncIdpConfig(status)
        case .idpLogin(let status):
            handleIdpLogin(status)
        case .idpDispatch(let status):
            handleIdpDispatch(status)
        case .postIdpLogin(let status):
            handlePostIdpLogin(status)
        }
    }

    private func handleWeb(_ error: Error) {
        self.hideLoading()
        if let handler = self.webErrorHandler {
            DispatchQueue.main.async {
                handler.vc = self.webViewContainerService?.currentController()
                handler.handle(error)
            }
        } else {
            self.handle(error)
        }
    }

    private func handle(_ error: Error) {
        self.hideLoading()
        self.webViewContainerService?.showFailView(error)
        guard let handler = self.errorHandler else {
            IDPWebViewService.logger.error("no error handler")
            return
        }
        DispatchQueue.main.async {
            handler.vc = self.webViewContainerService?.currentController()
            handler.handle(error)
        }
    }

    private func handleAsyncInitSetting(_ status: AsynGetDynamicDomainStatus) {
        switch status {
        case .notTriger:
            asyncDomainSettings()
        case .loading:
            showLoading()
        case .success:
            hideLoading()
            updateStep(.asyncIdpConfig(.notTriger(self.indicatedIDP)))
        case .failure(let error):
            handle(error)
        @unknown default:
            hideLoading()
            Self.logger.errorWithAssertion("unsupport status")
        }
    }

    private func handleAsyncIdpConfig(_ status: IDPLoginStepStatus<String?, IDPConfigModel>) {
        switch status {
        case .notTriger(let idpName):
            showLoading()
            asyncIdpConfig(idpName)
        case .loading:
            break
        case .success(let idpConfig):
            hideLoading()
            if let authConfig = idpConfig.authConfig {
                updateStep(.idpLogin(.notTriger(authConfig)))
            }

            switchIDPCompletion?(true, nil)
            switchIDPCompletion = nil
        case .failure(let error):
            handle(error)

            switchIDPCompletion?(false, error)
            switchIDPCompletion = nil
        }
    }

    private func handleIdpLogin(_ status: IDPLoginStepStatus<IDPAuthConfigModel, IDPLoginJSBResponse>) {
        switch status {
        case .notTriger(let authConfig):
            self.openPageWith(info: authConfig)
        case .loading:
            break
        case .success(let args):
            updateStep(.idpDispatch(.notTriger(args)))
        case .failure(let error):
            handle(error)
        }
    }

    private func handleIdpDispatch(_ status: IDPLoginStepStatus<IDPLoginJSBResponse, V3.Step>) {
        switch status {
        case .notTriger(let state):
            asyncIdpDispatch(state)
        case .loading:
            break
        case .success(let step):
            updateStep(.postIdpLogin(.notTriger(step)))
        case .failure(let error):
            handle(error)
        }
    }

    private func openPageWith(info: IDPAuthConfigModel) {
        guard let service = self.webViewContainerService else {
            IDPWebViewService.logger.error("no webViewContainerService")
            return
        }
        if let openMethod = info.openMethod,
           openMethod == "browser",
           let landURLString = info.landURL,
           let landURL = URL(string: landURLString) {
            self.success?(.systemWebPage(url: info.url))
            service.open(landURL)
            updateStep(.idpLogin(.loading))
        } else if let url = URL(string: info.url) {
            self.idpAuthConfig = info
            IDPWebViewService.logger.error("fail to trigger page, url: \(info.url), openMethod: \(String(describing: info.openMethod)), landURL: \(String(describing: info.landURL))")
            service.open(url)
            updateStep(.idpLogin(.loading))
        } else {
            IDPWebViewService.logger.error("fail to trigger page, url: \(info.url), openMethod: \(String(describing: info.openMethod)), landURL: \(String(describing: info.landURL))")
        }
    }

    private func handlePostIdpLogin(_ status: IDPLoginStepStatus<V3.Step, Void>) {
        switch status {
        case .notTriger(let args):
            // not show loading webview's loading
            postIdpLogin(resp: args)
        case .loading:
            break
        case .success:
            onPostIdpLoginSuccess()
        case .failure(let error):
            handleWeb(error)
            guard needRetry else {
                IDPWebViewService.logger.info("not retry load idp url")
                return
            }
            if let idpName = self.indicatedIDP {
                updateStep(.asyncIdpConfig(.notTriger(idpName)))
            } else if let idpConfig = self.idpConfig, let authConfig = idpConfig.authConfig {
                updateStep(.idpLogin(.notTriger(authConfig)))
            }
        }
    }

    private func asyncDomainSettings() {
        dynamicDomainService.asyncGetDynamicDomain()
    }

    // 部分 KA 会移除首次启动的隐私合规弹窗，App 打开后，系统网络权限弹框下加载登录页会失败
    // 为了优化这里的体验，增加一个纯色背景的初始页，等完成网络权限后再加载登录页
    private func pendAsyncIdPConfigIfNeeded() {

        func updateAsyncDomainSettingSuccess() {
            updateStep(.asyncDomainSetting(AsynGetDynamicDomainStatus.success))
        }

        #if SUITELOGIN_KA

        let needPrivacyAlert: Bool
        if ReleaseConfig.isKA {
            needPrivacyAlert = FeatureGatingManager.realTimeManager.featureGatingValue(with: "lark.authorization.splash.popup_window") // user:checked (setting)
        } else {
            needPrivacyAlert = true
        }
        Self.logger.info("n_action_idp_pending: \(needPrivacyAlert)")

        if needPrivacyAlert {
            updateAsyncDomainSettingSuccess()
            return
        }

        // true: 已经在首次启动添加过 pending 页
        let hasPendedAsyncIdPConfigKey = "Passport.IdP.HasPendedAsyncIdPConfigKey"
        UserDefaults.standard.register(defaults: [hasPendedAsyncIdPConfigKey: false])
        if UserDefaults.standard.bool(forKey: hasPendedAsyncIdPConfigKey) {
            updateAsyncDomainSettingSuccess()
            return
        }
        Self.logger.info("n_action_idp_pending_view_process")

        // 检查当前网络
        if let reach = Reachability(), reach.connection == .none {
            Self.logger.info("n_action_idp_pending_view_network_loss")
            webViewContainerService?.addPendingView()
            NotificationCenter.default.rx
                .notification(.reachabilityChanged)
                .filter({ notification in
                    if let reach = notification.object as? Reachability {
                        return reach.connection != .none
                    } else {
                        return false
                    }
                })
                .take(1)
                .timeout(.seconds(10), scheduler: MainScheduler.instance)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] _ in
                    guard let self = self else { return }
                    Self.logger.info("n_action_idp_pending_view_network_changed")
                    self.webViewContainerService?.removePendingView()
                    UserDefaults.standard.setValue(true, forKey: hasPendedAsyncIdPConfigKey)
                    updateAsyncDomainSettingSuccess()
                }, onError: { [weak self] _ in
                    guard let self = self else { return }
                    if let r = Reachability(), r.connection != .none {
                        Self.logger.info("n_action_idp_pending_view_network_recover")
                        self.webViewContainerService?.removePendingView()
                        UserDefaults.standard.setValue(true, forKey: hasPendedAsyncIdPConfigKey)
                        updateAsyncDomainSettingSuccess()
                    } else {
                        Self.logger.warn("n_action_idp_pending_view_network_failure")
                        self.webViewContainerService?.removePendingView()
                        UserDefaults.standard.setValue(true, forKey: hasPendedAsyncIdPConfigKey)
                        self.updateStep(.asyncDomainSetting(.failure(V3LoginError.networkNotReachable(false))))
                    }
                })
                .disposed(by: self.disposeBag)
        } else {
            // 网络可用
            Self.logger.info("n_action_idp_pending_view_network_default_available")
            UserDefaults.standard.setValue(true, forKey: hasPendedAsyncIdPConfigKey)
            updateAsyncDomainSettingSuccess()
        }

        #else

        updateAsyncDomainSettingSuccess()

        #endif
    }

    private func logOpenPlatformDeviceId() {
        // trace feishu log with idp log for diagnose
        // reason: idp's service only known open platform did
        IDPWebViewService.logger.info("openPlatformDeviceId: \(dependency.getOpenPlatformDeviceId())")
    }

    private func asyncIdpConfig(_ idpName: String?) {
        updateStep(.asyncIdpConfig(.loading))
        if let idpName = idpName {
            self.api
                .fetchConfigForIDP(SSOUrlReqBody(idpName: idpName, context: context ?? UniContext.placeholder))
                .subscribe(onNext: { (step) in
                    self.logOpenPlatformDeviceId()
                    if let idpConfig = self.assembleIDPConfigFromDict(step.stepData.stepInfo) {
                        self.idpConfig = idpConfig
                        self.updateStep(.asyncIdpConfig(.success(idpConfig)))
                    } else {
                        self.updateStep(.asyncIdpConfig(.failure(V3LoginError.badServerData)))
                    }
                }, onError: { (error) in
                    self.logOpenPlatformDeviceId()
                    self.updateStep(.asyncIdpConfig(.failure(error)))
                }).disposed(by: self.disposeBag)
        } else {
            self.api.fetchDefaultIDP(onSuccess: { defaultIDPSetting in
                self.indicatedIDP = defaultIDPSetting.defaultIdpType
                IDPWebViewService.logger.info("use default idp: \(defaultIDPSetting.defaultIdpType)")
                let body = SSOUrlReqBody(idpName: self.indicatedIDP, context: self.context ?? UniContext.placeholder)
                self.api
                    .fetchConfigForIDP(body)
                    .subscribe(onNext: { (step) in
                        self.logOpenPlatformDeviceId()
                        if let idpConfig = self.assembleIDPConfigFromDict(step.stepData.stepInfo) {
                            self.idpConfig = idpConfig
                            self.updateStep(.asyncIdpConfig(.success(idpConfig)))
                        } else {
                            self.updateStep(.asyncIdpConfig(.failure(V3LoginError.badServerData)))
                        }
                    }, onError: { (error) in
                        self.logOpenPlatformDeviceId()
                        self.updateStep(.asyncIdpConfig(.failure(error)))
                    }).disposed(by: self.disposeBag)
            }, onFailure: { error in
                self.updateStep(.asyncIdpConfig(.failure(error)))
            })
        }
    }

    private func assembleIDPConfigFromIDPLoginInfo(_ idpLoginInfo: IDPLoginInfo) -> IDPConfigModel? {
        guard let preConfigData = idpLoginInfo.preConfigJSON.data(using: .utf8) else {
            IDPWebViewService.logger.error("convert preConfigJSON from IDPLoginInfo to data failed")
            return nil
        }

        var stepInfoDict: [String: Any] = [
            "url": idpLoginInfo.url,
            "pre_config": [:]
        ]

        do {
            let preConfigDict = try JSONSerialization.jsonObject(with: preConfigData, options: [])
            stepInfoDict["pre_config"] = preConfigDict
        } catch {
            Self.logger.error("preConfigDict serialization failed, \((error as NSError).localizedDescription)")
        }

        if let securityId = idpLoginInfo.securityId {
            stepInfoDict["security_id"] = securityId
        }

        if let openMethod = idpLoginInfo.openMethod {
            stepInfoDict["open_with"] = openMethod
        }

        if let landURL = idpLoginInfo.landURL {
            stepInfoDict["land_url"] = landURL
        }

        return self.assembleIDPConfigFromDict(stepInfoDict)
    }

    private func assembleIDPConfigFromDict(_ stepInfoDict: [String: Any]) -> IDPConfigModel? {
        do {
            let idpConfig = IDPConfigModel()
            let stepInfoData = try stepInfoDict.asData()
            let idpAuthConfig = try IDPAuthConfigModel.from(stepInfoData)
            idpConfig.authConfig = idpAuthConfig

            if let preConfig = stepInfoDict["pre_config"] as? [String: Any] {
                if let externalDict = preConfig["external"] as? [String: Any] {
                    idpConfig.externalConfig = externalDict
                }
                if let internalDict = preConfig["internal"] as? [String: Any] {
                    idpConfig.internalConfigDict = internalDict
                }
                
                #if SUITELOGIN_KA
                if KAFeatureConfigManager.enableKACRC {
                    Self.logger.info("n_action_idp_auth_update_KA_config_need_decode")
                    let decoder = JSONDecoder()
                    let externalData = try JSONSerialization.data(withJSONObject: preConfig["external"])
                    let externalPart = try decoder.decode([String: AnyCodable].self, from: externalData)
                    
                    let internalData = try JSONSerialization.data(withJSONObject: preConfig["internal"])
                    let internalPart = try decoder.decode(Client.self, from: internalData)
                    
                    let karPreConfig = PreConfig(ext: externalPart, client: internalPart)
                    
                    kaLoginManager.updatePreConfig(karPreConfig)
                    Self.logger.info("n_action_idp_auth_update_KA_config_updated")
                }
                #endif
            }
            
            return idpConfig
        } catch {
            IDPWebViewService.logger.error("parse IDPConfigModel from stepInfoDict fail error: \(error)")
            return nil
        }
    }

    private func asyncIdpDispatch(_ resp: IDPLoginJSBResponse) {
        updateStep(.idpDispatch(.loading))

        guard resp.code == 0 else {
            updateStep(.idpDispatch(.failure(V3LoginError.toastError(resp.message ?? ""))))
            monitorIDPEventResult(isSucceeded: false, errorMsg: "response_code_not_equal_zero")
            return
        }

        #if SUITELOGIN_KA
        // refresh_token 相关内容更新到 JSB 的 response 中
        if let extraIdentity = resp.extraIdentity {
            Self.logger.info("n_action_idp_update_extra_identity")
            self.kaLoginManager.updateExtraIdentity(extraIdentity)
        }
        #endif

        PassportMonitor.monitor(PassportMonitorMetaLogin.startIdpLoginDispatch,
                                eventName: ProbeConst.monitorEventName,
                                context: self.context ?? UniContextCreator.create(.login)).flush()

        Self.logger.info("n_action_idp_auth_dispatch_req")
        self.api.fetchNext(state: resp.state).subscribe { [weak self] step in
            Self.logger.info("n_action_idp_auth_dispatch_req_suc")
            guard let self = self else {
                let monitor = PassportMonitor.monitor(PassportMonitorMetaLogin.idpLoginVerifyResult,
                                                      eventName: ProbeConst.monitorEventName,
                                                      categoryValueMap: [ProbeConst.channel: ProbeConst.idpEnterprise,
                                                                         ProbeConst.type: "web"],
                                                      context: UniContextCreator.create(.login))
                monitor.setResultTypeFail()
                    .setErrorMessage("weak_self_fail_on_next")
                    .setErrorCode(ProbeConst.commonInternalErrorCode)
                    .flush()
                return
            }

            PassportMonitor.monitor(PassportMonitorMetaLogin.idpLoginDispatchSuccess,
                                    eventName: ProbeConst.monitorEventName,
                                    context: self.context ?? UniContextCreator.create(.login)).flush()

            // SSO 登录时退出 Web 页面
            if self.context?.from == .login && step.stepData.nextStep != PassportStep.enterApp.rawValue {
                self.hideLoading()
                if let webVC = self.webViewContainerService?.currentController(),
                   let nav = webVC.navigationController, webVC == nav.topViewController {
                    nav.popViewController(animated: true)
                }
            }
            self.updateStep(.idpDispatch(.success(step)))
        } onError: { [weak self] error in
            Self.logger.error("n_action_idp_auth_dispatch_req_fail", error: error)
            guard let self = self else {
                let monitor = PassportMonitor.monitor(PassportMonitorMetaLogin.idpLoginVerifyResult,
                                                      eventName: ProbeConst.monitorEventName,
                                                      categoryValueMap: [ProbeConst.channel: ProbeConst.idpEnterprise,
                                                                         ProbeConst.type: "web"],
                                                      context: UniContextCreator.create(.login))
                monitor.setResultTypeFail()
                    .setErrorMessage("weak_self_fail_on_error")
                    .setErrorCode(ProbeConst.commonInternalErrorCode)
                    .flush()
                return
            }
            self.monitorIDPEventResult(isSucceeded: false, errorMsg: "dispatch_req_fail, \(error.localizedDescription)")

            // 跟前端对齐，超时统一回到前一个页面 https://bits.bytedance.net/meego/larksuite/issue/detail/2381367
            if let webVC = self.webViewContainerService?.currentController(),
               let nav = webVC.navigationController, webVC == nav.topViewController,
               (error as NSError).code == NSURLErrorTimedOut {
                self.hideLoading()
                if let handler = self.errorHandler {
                    DispatchQueue.main.async {
                        handler.vc = nav
                        handler.handle(error)
                    }
                }
                nav.popViewController(animated: true)
                self.clear()
            } else {
                self.updateStep(.idpDispatch(.failure(error)))
            }
        }.disposed(by: disposeBag)
    }

    private func postIdpLogin(resp: V3.Step) {
        updateStep(.postIdpLogin(.loading))

        if let loginStep = PassportStep(rawValue: resp.stepData.nextStep),
           let userListInfo = loginStep.pageInfo(with: resp.stepData.stepInfo) as? V3UserListInfo,
           let innerIdentify = userListInfo.innerIdentity,
           let identification = innerIdentify.identification {

            IDPWebViewService.logger.info("called idp finished login,identification id = \(identification)")
        }

        // 新帐号模型后，下发 enter_app step，从下面这里回调
        if resp.code == V3.Const.successCode {
            let step = resp.stepData.nextStep
            let stepInfo = resp.stepData.stepInfo
            self.monitorIDPEventResult(isSucceeded: true, errorMsg: nil)
            self.updateStep(.postIdpLogin(.success(())))
            self.success?(.stepData(step: step, stepInfo: stepInfo))
        } else {
            let type = V3ServerBizError(rawValue: resp.code) ?? .unknown
            let error = resp.errorInfo ?? V3LoginErrorInfo(type: type, message: "")
            self.monitorIDPEventResult(isSucceeded: false, errorMsg: V3LoginError.badServerCode(error).localizedDescription)
            updateStep(.postIdpLogin(.failure(V3LoginError.badServerCode(error))))
        }
    }

    private func onPostIdpLoginSuccess() {
        self.webViewContainerService = nil
        self.errorHandler = nil
        self.idpConfig = nil
        self.loginStep = nil
        self.success = nil
        self.error = nil
    }

    private func clear() {
        onPostIdpLoginSuccess()
    }

    private func handleRefresh() {
        guard let loginStep = self.loginStep, let value = self.refreshConvertStep(step: loginStep.value) else {
            IDPWebViewService.logger.warn("can not refresh IDPLoginStep: \(String(describing: self.loginStep))")
            return
        }
        IDPWebViewService.logger.info("refresh current IDPLoginStep: \(loginStep) to IDPLoginStep: \(value)")
        self.updateStep(value)
    }

    private func refreshStepAfterIdpConfig() -> IDPLoginStep? {
        var value: IDPLoginStep?
        if let idpName = self.indicatedIDP {
            value = .asyncIdpConfig(.notTriger(idpName))
        } else if let idpConfig = self.idpConfig, let authConfig = idpConfig.authConfig {
            value = .idpLogin(.notTriger(authConfig))
        }
        return value
    }

    private func refreshConvertStep(step: IDPLoginStep) -> IDPLoginStep? {
        var value: IDPLoginStep?
        switch step {
        case .asyncDomainSetting(let status):
            switch status {
            case .notTriger, .failure:
                value = .asyncDomainSetting(.notTriger)
            case .loading, .success:
                break
            }
        case .asyncIdpConfig(let status):
            switch status {
            case .notTriger, .failure:
                value = .asyncIdpConfig(.notTriger(self.indicatedIDP))
            case .loading, .success:
                break
            }
        case .idpLogin(let status):
            switch status {
            case .notTriger, .failure, .loading:
                value = self.refreshStepAfterIdpConfig()
            case .success:
                break
            }
        case .idpDispatch(let status):
            switch status {
            case .notTriger, .failure, .loading:
                value = self.refreshStepAfterIdpConfig()
            case .success:
                break
            }
        case .postIdpLogin(let status):
            switch status {
            case .notTriger, .failure:
                value = self.refreshStepAfterIdpConfig()
            case .loading, .success:
                break
            }
        }
        return value
    }

    // MARK: loading
    private func showLoading() {
        DispatchQueue.main.async {
            guard let service = self.webViewContainerService else {
                IDPWebViewService.logger.error("webViewContainerService is nil, can't showLoading")
                return
            }
            RoundedHUD.showLoading(on: service.currentController().view)
        }
    }

    private func hideLoading() {
        DispatchQueue.main.async {
            guard let service = self.webViewContainerService else {
                IDPWebViewService.logger.error("webViewContainerService is nil, can't hideLoading")
                return
            }
            RoundedHUD.removeHUD(on: service.currentController().view)
        }
    }

    // MARK: subcribe
    func subscriteLoginState() {
        self.loginStateSub.distinctUntilChanged().subscribe(onNext: { [weak self] (state) in
            guard let self = self else { return }
            switch state {
            case .notLogin:
                IDPWebViewService.logger.info("not login, remove all idp store data")
                self.idpConfig?.removeAll()
            case .logined:
                break
            }
        }).disposed(by: disposeBag)
    }

    private func subscribeForIDP(_ service: IDPWebViewContainerServiceProtocol) {
        switch loginStep?.value {
        case .idpLogin:
            break
        default:
            subscribeDomainSettingsStatus(service)
        }
        subscribeRefreshBtnClick(service)
        subscribeIDPLoginStep(service)
    }

    private func subscribeDomainSettingsStatus(_ service: IDPWebViewContainerServiceProtocol) {
        dynamicDomainService
            .result
            .observeOn(MainScheduler.instance)
            .skip(1)    // skip init value
            .subscribe(onNext: { [weak self] (status) in
                guard let self = self else { return }
                if case .success = status {
                    self.pendAsyncIdPConfigIfNeeded()
                } else {
                    self.updateStep(.asyncDomainSetting(status))
                }
            }, onError: { [weak self] error in
                guard let self = self else { return }
                self.updateStep(.asyncDomainSetting(.failure(error)))
            }).disposed(by: service.disposeBag)
    }

    private func subscribeRefreshBtnClick(_ service: IDPWebViewContainerServiceProtocol) {
        service.refreshSub.subscribe(onNext: { [weak self] () in
            guard let self = self else { return }
            self.handleRefresh()
        }).disposed(by: service.disposeBag)
    }

    private func subscribeIDPLoginStep(_ service: IDPWebViewContainerServiceProtocol) {
        self.loginStep?.asDriver().drive(onNext: { [weak self] (step) in
            guard let self = self else { return }
            self.handle(step)
        }).disposed(by: service.disposeBag)
    }
}

extension IDPWebViewService: IDPBridgeServiceProtocol {
    func getIDPExternalData() -> [String: Any] {
        if let result = self.idpConfig?.externalConfig {
            return result
        }
        IDPWebViewService.logger.error("get idp external data failed")
        return [:]
    }

    func finishedLogin(_ args: [String: Any]) {
        MultiSceneMonitor.shared.record(scene: .idpVerifyResult, categoryInfo: [
            MultiSceneMonitor.Const.type.rawValue: "webview_result",
            MultiSceneMonitor.Const.result.rawValue: "success"
        ])

        IDPWebViewService.logger.info("n_action_idp_finished_login_JSB_result: \(args)")
        guard let idpContext = args["idp_context"] as? String else {
            IDPWebViewService.logger.error("idp context isnot string")
            updateStep(.idpLogin(.failure(V3LoginError.badServerData)))
            monitorIDPEventResult(isSucceeded: false, errorMsg: "idp context isnot string")
            return
        }

        guard let idpContextStr = idpContext.passport_fromBase64() else {
            IDPWebViewService.logger.error("idp context decode fail")
            updateStep(.idpLogin(.failure(V3LoginError.badServerData)))
            monitorIDPEventResult(isSucceeded: false, errorMsg: "idp context decode fail")
            return
        }

        PassportMonitor.monitor(PassportMonitorMetaLogin.startIdpLoginVerify,
                                eventName: ProbeConst.monitorEventName,
                                categoryValueMap: [ProbeConst.channel: ProbeConst.idpEnterprise, ProbeConst.type: "web"],
                                context: context ?? UniContextCreator.create(.login)).flush()
        ProbeDurationHelper.startDuration(ProbeDurationHelper.loginIdpVerifyFlow)

        do {
            let response = try JSONDecoder().decode(IDPLoginJSBResponse.self, from: Data(idpContextStr.utf8))
            updateStep(.idpLogin(.success(response)))

        } catch {
            IDPWebViewService.logger.error("idp decode: \(idpContextStr), error: \((error as NSError).localizedDescription)")
            monitorIDPEventResult(isSucceeded: false, errorMsg: "idp context decode error \(error.localizedDescription)")
            updateStep(.idpLogin(.failure(error)))
        }
    }

    private func showAlert(_ message: String) {
        let alert = LarkAlertController()
        alert.setContent(text: message, color: UIColor.ud.textCaption, alignment: .left)
        alert.addPrimaryButton(text: BundleI18n.suiteLogin.Lark_Passport_CP_Confirm, dismissCompletion: nil)
        let webviewVC = self.webViewContainerService?.currentController()
        webviewVC?.present(alert, animated: true)
    }

    func getIDPAuthConfigData() -> [String : Any] {
        if let result = try? self.idpAuthConfig?.asDictionary() {
            return result
        }
        return [:]
    }
}

extension IDPWebViewService {
    private func monitorIDPEventResult(isSucceeded: Bool, errorMsg: String?) {
        let duration = ProbeDurationHelper.stopDuration(ProbeDurationHelper.loginIdpVerifyFlow)
        let monitor = PassportMonitor.monitor(PassportMonitorMetaLogin.idpLoginVerifyResult,
                                              eventName: ProbeConst.monitorEventName,
                                              categoryValueMap: [ProbeConst.channel: ProbeConst.idpEnterprise,
                                                                 ProbeConst.companyInfo: indicatedIDP ?? "",
                                                                 ProbeConst.type: "web",
                                                                 ProbeConst.duration: duration],
                                              context: context ?? UniContextCreator.create(.login))
        if isSucceeded {
            monitor
                .setResultTypeSuccess()
                .flush()
        } else {
            monitor.setResultTypeFail()
                .setErrorMessage(errorMsg)
                .setErrorCode(ProbeConst.commonInternalErrorCode)
                .flush()
        }
    }
}

extension IDPWebViewService: PassportStoreMigratable {
    func startMigration() -> Bool {
        if let idpName = UserDefaults.standard.string(forKey: indicatedIDPCacheKey), !idpName.isEmpty {
            PassportStore.shared.indicatedIDP = idpName
        }
        UserDefaults.standard.removeObject(forKey: indicatedIDPCacheKey)

        return true
    }
}
