//
//  KALoginService.swift
//  SuiteLogin
//
//  Created by quyiming@bytedance.com on 2019/10/12.
//

import Foundation
import RxSwift
import LKCommonsLogging
import RxRelay
import RoundedHUD
import LarkAppConfig
import LarkAccountInterface
import LarkContainer

enum KaLoginStepStatus<Input, Output> {
    case notTriger(Input)
    case loading
    case success(Output)
    case failure(Error)
}

enum KaLoginStep {
    // .asyncsDomainSettings -> .asyncIdpConfig -> .idpLogin -> .enterApp
    static let intializeStep: KaLoginStep = .asyncDomainSetting
    static let startIdpConfigStep: KaLoginStep = .asyncIdpConfig(.notTriger(()))

    case asyncDomainSetting
    case asyncIdpConfig(KaLoginStepStatus<Void, KaAuthURL>)
    case idpLogin(KaLoginStepStatus<URL, [String: Any]>)
    case enterApp(KaLoginStepStatus<[String: Any], Void>)
}

class KaLoginServiceImpl: KaLoginService, KAStoreUpdatable {

    private let loginStateSub: BehaviorRelay<V3LoginState>

    private let httpClient: HTTPClient

    @Provider var dependency: PassportDependency // user:checked (global-resolve) 

    private let context: UniContextProtocol

    init(
        loginStateSub: BehaviorRelay<V3LoginState>,
        httpClient: HTTPClient,
        context: UniContextProtocol
        ) {
        self.loginStateSub = loginStateSub
        self.httpClient = httpClient
        self.context = context
        let store = KaStore()
        self.store = store
        self.kaTokenManager = KaTokenManager(
            store: store,
            loginStateSub: loginStateSub
        )
        registerUserListStep()
        subscriteLoginState()
    }

    private let disposeBag = DisposeBag()

    private let store: KaStore

    private var kaTokenManager: KaTokenManager

    static let logger = Logger.log(KaLoginServiceImpl.self, category: "SuiteLogin.KaLoginServiceImpl")

    private var webViewManager: KaLoginWebViewManager?

    private lazy var api: KaAPI = {
        return KaAPI()
    }()

    private var errorHandler: ErrorHandler?

    private var loginStep: BehaviorRelay<KaLoginStep> = BehaviorRelay(value: .intializeStep)

    /// KA DEBUG use idp type local cache
    private var indicateIdpType: String? {
        set {
            store.indicateIdpType = newValue
        }
        get {
            return store.indicateIdpType
        }
    }
    // MARK: jsbridge

    private var preConfig: PreConfig? {
        set {
            store.preConfig = newValue
        }
        get {
            return store.preConfig
        }
    }

    private var settings: KaSettings?

    func getKaConfig() -> [String: Any]? {
        guard let preConf = preConfig else {
            KaLoginServiceImpl.logger.error("kaConfig is nil")
            return nil
        }
        do {
            return try preConf.ext.asDictionary()
        } catch {
            KaLoginServiceImpl.logger.error("get kaConfig fail error: \(error)")
            return nil
        }
    }

    func getExtraIdentity(
        onSuccess: @escaping ([String: Any]) -> Void,
        onError: @escaping (Error) -> Void
        ) {
        self.kaTokenManager.fetchIdentity(onSuccess: { identity in
            do {
                let extraIdentity = try identity.extraIdentity.asDictionary()
                onSuccess(extraIdentity)
            } catch {
                onError(error)
            }
        }, onError: { error in
            onError(error)
        })
    }

    func kaLoginResult(args: [String: Any]) {
        updateStep(.idpLogin(.success(args)))
    }

    func switchIdp(_ idp: String) {
        KaLoginServiceImpl.logger.info("switch to idp: \(idp)")
        indicateIdpType = idp
        updateStep(.startIdpConfigStep)
    }
    
    func updateExtraIdentity(_ extraIdentity: ExtraIdentity) {
        self.kaTokenManager.updateExtraIdentity(extraIdentity)
    }

    func updatePreConfig(_ preConfig: PreConfig) {
        self.preConfig = preConfig
    }

}

// MARK: Biz Logic

extension KaLoginServiceImpl {

    // MARK: subscribe

    func subscriteLoginState() {
        loginStateSub.distinctUntilChanged().subscribe(onNext: { [weak self] (state) in
            guard let self = self else { return }
            switch state {
            case .notLogin:
                KaLoginServiceImpl.logger.info("not login remove all ka store data")
                self.store.removeAll()
            case .logined:
                break
            }
        }).disposed(by: disposeBag)
    }

    private func subscribe(_ manager: KaLoginWebViewManager) {
        subscribeRefreshBtnClick(manager)
        subscribeKaLoginStep(manager)
    }

    private func subscribeRefreshBtnClick(_ manager: KaLoginWebViewManager) {
        manager.refreshSub.subscribe(onNext: { [weak self] () in
            guard let self = self else { return }
            self.handleRefresh()
        }).disposed(by: manager.disposeBag)
    }

    private func subscribeKaLoginStep(_ manager: KaLoginWebViewManager) {
        loginStep.asDriver().drive(onNext: { [weak self] (step) in
            guard let self = self else { return }
            self.handle(step)
        }).disposed(by: manager.disposeBag)
    }

    // MARK: handle login step

    private func updateStep(_ step: KaLoginStep) {
        loginStep.accept(step)
    }

    private func handle(_ step: KaLoginStep) {
        KaLoginServiceImpl.logger.info("kaLogin handle step: \(step)")
        switch step {
        case .asyncDomainSetting:
            updateStep(.startIdpConfigStep)
        case .asyncIdpConfig(let status):
            handleAsyncIdpConfig(status)
        case .idpLogin(let status):
            handleIdpLogin(status)
        case .enterApp(let status):
            handleEnterApp(status)
        }
    }

    private func handleAsyncIdpConfig(_ status: KaLoginStepStatus<Void, KaAuthURL>) {
        switch status {
        case .notTriger:
            showLoading()
            asyncIdpConfig()
        case .loading:
            break
        case .success(let authUrl):
            hideLoading()
            if let url = URL(string: authUrl.url) {
                updateStep(.idpLogin(.notTriger(url)))
            }
        case .failure(let error):
            handle(error)
        }
    }

    private func handleIdpLogin(_ status: KaLoginStepStatus<URL, [String: Any]>) {
        guard let manager = self.webViewManager else {
            KaLoginServiceImpl.logger.error("no webViewManager")
            return
        }
        switch status {
        case .notTriger(let url):
            manager.open(url)
            updateStep(.idpLogin(.loading))
        case .loading:
            break
        case .success(let args):
            updateStep(.enterApp(.notTriger(args)))
        case .failure(let error):
            handle(error)
        }
    }

    private func handleEnterApp(_ status: KaLoginStepStatus<[String: Any], Void>) {
        switch status {
        case .notTriger(let args):
            // not show loading webview's loading
            enterApp(args: args)
        case .loading:
            break
        case .success:
            onEnterAppSuccess()
        case .failure(let error):
            handle(error)
            updateStep(.startIdpConfigStep)
        }
    }

    // MARK: refresh

    private func handleRefresh() {
        guard let value = self.refreshConvertStep(step: self.loginStep.value) else {
            KaLoginServiceImpl.logger.warn("can not refresh kaLoginStep: \(self.loginStep)")
            return
        }
        KaLoginServiceImpl.logger.info("refresh current kaLoginStep: \(self.loginStep) to kaLoginStep: \(value)")
        updateStep(value)
    }

    private func refreshConvertStep(step: KaLoginStep) -> KaLoginStep? {
        var value: KaLoginStep?
        switch step {
        case .asyncDomainSetting: break
        case .asyncIdpConfig(let status):
            switch status {
            case .notTriger, .failure:
                value = .startIdpConfigStep
            case .loading, .success:
                break
            }
        case .idpLogin(let status):
            switch status {
            case .notTriger, .failure, .loading:
                value = .startIdpConfigStep
            case .success:
                break
            }
        case .enterApp(let status):
            switch status {
            case .notTriger, .failure:
                value = .startIdpConfigStep
            case .loading, .success:
                break
            }
        }
        return value
    }

    // MARK: idp config

    private func asyncIdpConfig() {
        updateStep(.asyncIdpConfig(.loading))
        self.api.settings(onSuccess: { settings in
            self.logOpenPlatformDeviceId()
            self.settings = settings
            var useIdp: String
            if let indicateIdp = self.indicateIdpType {
                useIdp = indicateIdp
                KaLoginServiceImpl.logger.info("use indicate idp: \(indicateIdp)")
            } else {
                useIdp = settings.defaultIdpType
                KaLoginServiceImpl.logger.info("use default idp: \(settings.defaultIdpType)")
            }
            self.api.authUrl(aliasCode: useIdp, onSuccess: { authUrl in
                self.preConfig = authUrl.preConfig
                self.updateStep(.asyncIdpConfig(.success(authUrl)))
            }, onFailure: { error in
                self.updateStep(.asyncIdpConfig(.failure(error)))
            })
        }, onFailure: { error in
            self.logOpenPlatformDeviceId()
            self.updateStep(.asyncIdpConfig(.failure(error)))
        })
    }

    private func logOpenPlatformDeviceId() {
        // trace feishu log with idp log for diagnose
        // reason: idp's service only known open platform did
        IDPWebViewService.logger.info("openPlatformDeviceId: \(dependency.getOpenPlatformDeviceId())")
    }

    // MARK: enter app

    private func enterApp(args: [String: Any]) {
        updateStep(.enterApp(.loading))
        do {
            let resp = try V3.Step(dict: args as NSDictionary)
            if resp.code == V3.Const.successCode {
                let step = resp.stepData.nextStep
                let stepInfo = resp.stepData.stepInfo
                V3ViewModel.post(event: step, stepInfo: stepInfo, additionalInfo: nil, context: context, success: {
                    self.updateStep(.enterApp(.success(())))
                }, error: { error in
                    self.updateStep(.enterApp(.failure(error)))
                })
            } else {
                let type = V3ServerBizError(rawValue: resp.code) ?? .unknown
                let error = resp.errorInfo ?? V3LoginErrorInfo(type: type, message: "")
                updateStep(.enterApp(.failure(V3LoginError.badServerCode(error))))
            }
        } catch {
            updateStep(.enterApp(.failure(V3LoginError.transformJSON(error))))
        }
    }

    private func registerUserListStep() {
        LoginPassportEventBus.shared.register(
            event: PassportStep.userList.rawValue,
            handler: ServerInfoEventBusHandler<V3UserListInfo>(handleWork: { (args) in
                self.kaTokenManager.updateExtraIdentity(args.serverInfo.extraIdentity)
            })
        )
    }

    private func onEnterAppSuccess() {
        webViewManager = nil
        errorHandler = nil
        loginStep = BehaviorRelay(value: .intializeStep)
    }

}

// MARK: UI

extension KaLoginServiceImpl: KaLoginUI {

    func kaLoginVC(context: UniContextProtocol) -> UIViewController {
        // swiftlint:disable force_unwrapping
        let manager = KaLoginWebViewManagerImpl(url: URL(string: CommonConst.aboutBlank)!, dependency: dependency)
        // swiftlint:enable force_unwrapping

        webViewManager = manager
        errorHandler = V3ErrorHandler(vc: manager.webViewController(), context: context, contextExpiredPostEvent: false, showToastOnWindow: true)
        subscribe(manager)
        return manager.webViewController()
    }

    func kaModifyPwdVC() -> UIViewController {
        if let config = preConfig, let url = config.client.mpwURL, let URL = URL(string: url) {
            return dependency.createWebViewController(URL, customUserAgent: nil)
        } else {
            KaLoginServiceImpl.logger.error("wrong mpwURL \(String(describing: preConfig?.client.mpwURL))")
            // swiftlint:disable force_unwrapping
            return dependency.createWebViewController(URL(string: CommonConst.aboutBlank)!, customUserAgent: nil)
            // swiftlint:enable force_unwrapping

        }
    }

    private func showLoading() {
        DispatchQueue.main.async {
            guard let manager = self.webViewManager else {
                KaLoginServiceImpl.logger.error("webManager is nil, can't showLoading")
                return
            }
            RoundedHUD.showLoading(on: manager.webViewController().view)
        }
    }

    private func hideLoading() {
        DispatchQueue.main.async {
            guard let manager = self.webViewManager else {
                KaLoginServiceImpl.logger.error("webManager is nil, can't hideLoading")
                return
            }
            RoundedHUD.removeHUD(on: manager.webViewController().view)
        }
    }

    private func handle(_ error: Error) {
        hideLoading()
        webViewManager?.showFailView()
        guard let handler = errorHandler else {
            KaLoginServiceImpl.logger.error("no error handler")
            return
        }
        DispatchQueue.main.async {
            handler.handle(error)
        }
    }

}

extension KaLoginServiceImpl: KaLoginInternalService {
    func getSettingFeature() -> SettingFeature {
        if let config = self.preConfig, config.client.hasPassword() {
            return [.modifyPwd, .deviceManage]
        } else {
            return [.deviceManage]
        }
    }
}

// MARK: LogDesensitize

extension KaLoginStepStatus: LogDesensitize, CustomStringConvertible {
    public var description: String {
        return "\(self.desensitize())"
    }

    func desensitize() -> String {
        switch self {
        case .notTriger:
            return "noTriger"
        case .loading:
            return "loading"
        case .success:
            return "success"
        case .failure:
            return "failure"
        }
    }
}
