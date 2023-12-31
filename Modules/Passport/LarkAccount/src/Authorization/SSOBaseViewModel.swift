//
//  SSOBaseViewModel.swift
//  LarkAccount
//
//  Created by Miaoqi Wang on 2020/11/2.
//

import Foundation
import LarkContainer
import LarkAccountInterface
import RxSwift
import LKCommonsLogging
import LarkFoundation
import ECOProbeMeta

/// Tech Design https://bytedance.feishu.cn/docs/doccnzf3VACEenIrgYPhs63Uwch#
class SSOBaseViewModel: UserResolverWrapper {
    static let logger = Logger.plog(SSOBaseViewModel.self, category: "SuiteLogin.SSOBaseViewModel")
    
    let startDate: Date

    let info: SSOAuthType
    let context = UniContextCreator.create(.authorization)
    var confirmed = false
    private let disposeBag = DisposeBag()

    @ScopedInjectedLazy var qrCodeAPI: QRCodeAPI?
    @ScopedInjectedLazy var ssoAPI: SSOAPI?

    private let _userResolver: UserResolver?
    var userResolver: UserResolver {
        return _userResolver ?? PassportUserScope.getCurrentUserResolver() // user:current
    }

    init(resolver: UserResolver?, info: SSOAuthType, startDate: Date = Date()) {
        self._userResolver = resolver
        self.info = info
        self.startDate = startDate
    }

    func closeWork(authorizationPageType: String?) {
        Self.logger.info(addSdkLogTagIfNeed(original: "cancelled"))

        let _ = cancel(authorizationPageType: authorizationPageType).subscribe()

        switch info {
        case .sdk:
            cancelledTryJumpToSDK()
        case .url(_, _, let schema), .authAutoLogin(_, _, let schema):
            // 原bundleid逻辑使用私有api，v6.1起使用url scheme跳转
            if let url = URL(string: schema) {
                UIApplication.shared.open(url)
            }
        case .qrCode: break
        }
    }

    func cancelledTryJumpToSDK() {
        guard case .sdk = info, let url = info.ssoSDKCancelUrl() else { return }
        UIApplication.shared.open(url) { (success) in
            if !success {
                Self.logger.error("fail to jump lark open url \(url) failed")
            }
        }
    }

    func failedTryJumpToSDK(errCode: Int) {
        guard case .sdk = info, let url = info.ssoSDKFailureUrl(errCode: errCode) else { return }
        UIApplication.shared.open(url) { (success) in
            if !success {
                Self.logger.error("fail to jump lark open url \(url) failed")
            }
        }
    }
}

extension SSOBaseViewModel {
    private func qrLoginType(for loginAuthInfo: SSOAuthType) -> QRLoginType {
        if case .authAutoLogin(_, _, _) = info {
            return .authAutoLogin
        } else {
            return .qrCode
        }
    }
    
    func resolveAuthorizationType() -> String {
        switch info {
        case .sdk:
            return "sdk"
        case .qrCode:
            return "qrcode"
        case .url:
            fallthrough
        case .authAutoLogin:
            return "applink"
        }
    }

    func check() -> Observable<LoginAuthInfo?> {
        let authorizationType = resolveAuthorizationType()
        let startDate = startDate
        switch info {
        case let .sdk(appId, state, otherParams):
            Self.logger.info(
                Self.ssoSDKLog(
                    original: "check auth appId: \(appId) params:\(otherParams)",
                    associateId: state
                )
            )
            Self.logger.info("n_action_ssosdk_auth_request", body: "appId: \(appId)")
            PassportMonitor.flush(EPMClientPassportMonitorAuthorizationCode.sso_sdk_login_auth_request_start, context: self.context)
            guard let ssoAPI = ssoAPI else { return .just(nil) }
            return ssoAPI.oauth(body: OAuthRequestBody(appId: appId, state: state, otherParams: otherParams))
                .flatMap({ (step) -> Observable<LoginAuthInfo?> in
                    guard let userConfirm = PassportStep.userConfirm.pageInfo(with: step.stepData.stepInfo) as? V3UserConfirm else {
                        Self.logger.error("no user confirm data")
                        return .error(V3LoginError.badServerData)
                    }
                    Self.logger.info(Self.ssoSDKLog(original: "sso check success", associateId: state))
                    return .just(userConfirm.toLoginAuthInfo())
                })
                .do(onNext: { [weak self] _ in
                    guard let self = self else { return }
                    Self.logger.info("n_action_ssosdk_auth_req_succ")
                    PassportMonitor.flush(EPMClientPassportMonitorAuthorizationCode.sso_sdk_login_auth_request_succ, context: self.context)
                    PassportMonitor.monitor(PassportMonitorMetaAuthorization.authorizationScanResult, eventName: ProbeConst.monitorEventName, categoryValueMap: [ProbeConst.duration: Int64(Date().timeIntervalSince(startDate) * 1000), ProbeConst.authorizationType: authorizationType], context: self.context).setResultTypeSuccess().flush()
                }, onError: { [weak self] error in
                    guard let self = self else { return }
                    Self.logger.error("n_action_ssosdk_auth_req_fail", error: error)
                    PassportMonitor.flush(EPMClientPassportMonitorAuthorizationCode.sso_sdk_login_auth_request_fail, context: self.context, error: error)
                    PassportMonitor.monitor(PassportMonitorMetaAuthorization.authorizationScanResult, eventName: ProbeConst.monitorEventName, categoryValueMap: [ProbeConst.authorizationType: authorizationType], context: self.context).setPassportErrorParams(error: error).setResultTypeFail().flush()
                })
        case .qrCode(let token), .url(let token, _, _), .authAutoLogin(let token, _, _):
            Self.logger.info("n_action_qrlogin_scan_request", body: "token: \(token.desensitized())")
            PassportMonitor.flush(EPMClientPassportMonitorAuthorizationCode.qr_login_scan_request_start, context: self.context)
            guard let qrCodeAPI = qrCodeAPI else { return .just(nil) }
            return qrCodeAPI
                .checkTokenForLogin(token: token, loginType: qrLoginType(for: info))
                .map({ step -> LoginAuthInfo? in
                    if step.stepData.nextStep == PassportStep.qrLoginScan.rawValue {
                        // 正常授权逻辑
                        let stepInfo = step.stepData.stepInfo
                        do {
                            let data = try JSONSerialization.data(withJSONObject: stepInfo)
                            let info = try JSONDecoder().decode(LoginAuthInfo.self, from: data)
                            return info
                        } catch {
                            Self.logger.error("PassportStep: can not get pageInfo from none jsonDic)")
                            throw error
                        }
                    } else {
                        // 否则执行返回的 step
                        self.userResolver.passportEventBus.post(
                            event: step.stepData.nextStep,
                            context: V3RawLoginContext(
                                stepInfo: step.stepData.stepInfo,
                                backFirst: step.stepData.backFirst,
                                context: self.context
                            ),
                            success: {

                            }, error: { error in

                            }
                        )
                        return nil
                    }
                })
                .observeOn(MainScheduler.instance)
                .do(onNext: { [weak self] _ in
                    guard let self = self else { return }
                    Self.logger.info("n_action_qrlogin_scan_request_succ")
                    PassportMonitor.flush(EPMClientPassportMonitorAuthorizationCode.qr_login_scan_request_succ, context: self.context)
                    PassportMonitor.monitor(PassportMonitorMetaAuthorization.authorizationScanResult, eventName: ProbeConst.monitorEventName, categoryValueMap: [ProbeConst.duration: Int64(Date().timeIntervalSince(startDate) * 1000), ProbeConst.authorizationType: authorizationType], context: self.context).setResultTypeSuccess().flush()
                }, onError: { [weak self] error in
                    guard let self = self else { return }
                    Self.logger.error("n_action_qrlogin_scan_request_fail", error: error)
                    PassportMonitor.flush(EPMClientPassportMonitorAuthorizationCode.qr_login_scan_request_fail, context: self.context, error: error)
                    PassportMonitor.monitor(PassportMonitorMetaAuthorization.authorizationScanResult, eventName: ProbeConst.monitorEventName, categoryValueMap: [ProbeConst.authorizationType: authorizationType], context: self.context).setPassportErrorParams(error: error).setResultTypeFail().flush()
                })
        }
    }

    func confirm(scope: String, isMultiLogin: Bool) -> Observable<SSOJump> {
        confirmed = true
        return _confirm(scope: scope, isMultiLogin: isMultiLogin)
            .do(onError: { [weak self] _ in
                self?.confirmed = false
            })
    }

    private func _confirm(scope: String, isMultiLogin: Bool) -> Observable<SSOJump> {
        guard let ssoAPI = ssoAPI, let qrCodeAPI = qrCodeAPI else { return .just(.none(needDismiss: true)) }

        func handleRiskStepIfNeeded(_ step: V3.Step) -> SSOJump {
            Self.logger.passportInfo("n_action_qr_login: handle step \(step.stepData.nextStep)")
            if step.stepData.nextStep == PassportStep.ok.rawValue {
                // 免密授权
                if case .authAutoLogin(_, _, let schema) = info {
                    return .scheme(schema)
                }
                // 扫码登录
                return .none(needDismiss: true)
            }
            // v6.8 起可能会返回风控流程（qr_login_confirm），流转至状态机处理
            userResolver.passportEventBus.post(
                event: step.stepData.nextStep,
                context: V3RawLoginContext(
                    stepInfo: step.stepData.stepInfo,
                    additionalInfo: AuthorizationRiskPayload(authType: self.info, isMultiLogin: isMultiLogin),
                    backFirst: step.stepData.backFirst,
                    context: self.context
                ),
                success: {
                    Self.logger.passportInfo("n_action_qr_login_risk_step")
                }, error: { error in
                    Self.logger.passportError("n_action_qr_login_risk_error: \(error.localizedDescription)")
                }
            )
            return .none(needDismiss: false)
        }

        switch info {
        case .sdk(_, let state, _):
            Self.logger.info("n_action_ssosdk_auth_confirm_request", body: "scope: \(scope), state: \(state)")
            let userID = userResolver.userID
            return ssoAPI
                .confirm(scope: scope, userID: userID).flatMap { (step) -> Observable<SSOJump> in
                    guard let webUrl = PassportStep.webUrl.pageInfo(with: step.stepData.stepInfo) as? V3WebUrl else {
                        return .error(V3LoginError.badServerData)
                    }
                    guard CommonConst.ssoWebUrlMode == webUrl.mode else {
                        Self.logger.error("unsupport web url mode \(webUrl.mode)")
                        return .error(V3LoginError.badServerData)
                    }
                    Self.logger.info(Self.ssoSDKLog(original: "sso confirm success", associateId: state))
                    return .just(.scheme(webUrl.uri))
                }
                .do(onNext: { [weak self] _ in
                    guard let self = self else { return }
                    Self.logger.info("n_action_ssosdk_auth_confirm_req_succ")
                    PassportMonitor.flush(EPMClientPassportMonitorAuthorizationCode.sso_sdk_login_auth_confirm_request_succ, context: self.context)
                }, onError: { [weak self] error in
                    guard let self = self else { return }
                    Self.logger.error("n_action_ssosdk_auth_confirm_req_fail", error: error)
                    PassportMonitor.flush(EPMClientPassportMonitorAuthorizationCode.sso_sdk_login_auth_confirm_request_fail, context: self.context, error: error)
                })
        case .qrCode(let token):
            Self.logger.info("n_action_auth_login_confirm_request", body: "scope: \(scope), token: \(token.desensitized()), isMultiLogin: \(isMultiLogin)")
            return qrCodeAPI
                .confirmTokenForLogin(token: token, scope: scope, isMultiLogin: isMultiLogin, loginType: .qrCode)
                .observeOn(MainScheduler.instance)
                .do(onNext: { _ in
                    Self.logger.info("n_action_auth_login_confirm_request_succ", body: "isMultiLogin: \(isMultiLogin)", method: .local)
                }, onError: { error in
                    Self.logger.error("n_action_auth_login_confirm_request_fail", body: "isMultiLogin: \(isMultiLogin)", error: error)
                })
                .map { step -> SSOJump in
                    handleRiskStepIfNeeded(step)
                }
        case .url(let token, _, let schema):
            Self.logger.info("confirm with token: \(token), schema: \(schema)")
            return qrCodeAPI
                .confirmTokenForLogin(token: token, scope: scope, isMultiLogin: isMultiLogin, loginType: qrLoginType(for: info))
                .observeOn(MainScheduler.instance)
                .map { (_) -> SSOJump in
                    return .scheme(schema)
                }
        case .authAutoLogin(let token, _, let schema):
            Self.logger.info("confirm with token: \(token), schema: \(schema)")
            return qrCodeAPI
                .confirmTokenForLogin(token: token, scope: scope, isMultiLogin: isMultiLogin, loginType: qrLoginType(for: info))
                .observeOn(MainScheduler.instance)
                .map { step -> SSOJump in
                    handleRiskStepIfNeeded(step)
                }
        }
    }

    func cancel(authorizationPageType: String?) -> Observable<Bool> {
        let authorizationType: String = resolveAuthorizationType()
        switch info {
        case .sdk:
            Self.logger.info("n_action_ssosdk_auth_cancel")
            PassportMonitor.flush(EPMClientPassportMonitorAuthorizationCode.sso_sdk_login_auth_cancle, context: self.context)
            PassportMonitor.flush(PassportMonitorMetaAuthorization.startAuthorizationCancel, eventName: ProbeConst.monitorEventName, categoryValueMap: [ProbeConst.authorizationType: authorizationType], context: context)
            PassportMonitor.monitor(PassportMonitorMetaAuthorization.authorizationCancelResult, eventName: ProbeConst.monitorEventName, categoryValueMap: [ProbeConst.authorizationType: authorizationType, ProbeConst.duration: 0], context: context).setResultTypeSuccess().flush()
            
            return .just(false)
        case .qrCode(let token), .url(let token, _, _), .authAutoLogin(let token, _, _):
            Self.logger.info("n_action_auth_login_cancel_request", body: "token: \(token.desensitized())")
            PassportMonitor.flush(EPMClientPassportMonitorAuthorizationCode.qr_login_cancle_request_start, context: self.context)
            var categoryValueMap: [String: Any] = [ProbeConst.authorizationType: authorizationType]
            if let authorizationPageType = authorizationPageType {
                categoryValueMap[ProbeConst.authorizationPageType] = authorizationPageType
            }
            let startDate = Date()
            PassportMonitor.flush(PassportMonitorMetaAuthorization.startAuthorizationCancel, eventName: ProbeConst.monitorEventName, categoryValueMap: categoryValueMap, context: context)
            let context = context
            guard let qrCodeAPI = qrCodeAPI else { return .just(false) }
            return qrCodeAPI
                .cancelTokenForLogin(token: token, loginType: qrLoginType(for: info))
                .map { true }
                .observeOn(MainScheduler.instance)
                .do(onNext: { _ in
                    var categoryValueMap = categoryValueMap
                    categoryValueMap[ProbeConst.duration] = Int64(Date().timeIntervalSince(startDate) * 1000)
                    PassportMonitor.monitor(PassportMonitorMetaAuthorization.authorizationCancelResult, eventName: ProbeConst.monitorEventName, categoryValueMap: categoryValueMap, context: context).setResultTypeSuccess().flush()
                    Self.logger.info("n_action_auth_login_cancel_request_succ")
                    PassportMonitor.flush(EPMClientPassportMonitorAuthorizationCode.qr_login_cancle_request_succ, context: context)
                }, onError: { error in
                    PassportMonitor.monitor(PassportMonitorMetaAuthorization.authorizationCancelResult, eventName: ProbeConst.monitorEventName, categoryValueMap: categoryValueMap, context: context).setPassportErrorParams(error: error).setResultTypeFail().flush()
                    Self.logger.error("n_action_auth_login_cancel_request_fail", error: error)
                    PassportMonitor.flush(EPMClientPassportMonitorAuthorizationCode.qr_login_cancle_request_fail,
                                          context: context,
                                          error: error)
                })
        }
    }

    func clickLink(vc: UIViewController, url: URL) {
        func postWeb(url: URL) {
            self.userResolver.passportEventBus.post(
                event: V3NativeStep.simpleWeb.rawValue,
                context: V3LoginContext(serverInfo: nil, additionalInfo: V3SimpleWebInfo(url: url), context: nil),
                success: {},
                error: {error in
                    V3ErrorHandler(vc: vc, context: self.context).handle(error)
                }
            )
        }
        if let presentedViewController = vc.presentedViewController {
            Self.logger.warn("Current VC already has presented \(presentedViewController). \(presentedViewController) will be dismissed before web post.")
            presentedViewController.dismiss(animated: true, completion: {
                postWeb(url: url)
            })
        } else {
            postWeb(url: url)
        }
    }
}

extension SSOBaseViewModel {
    func addSdkLogTagIfNeed(original: String) -> String {
        guard case let .sdk(_, state, _) = self.info else {
            return original
        }
        return Self.ssoSDKLog(original: original, associateId: state)
    }

    static func ssoSDKLog(original: String, associateId: String) -> String {
        return "\(original) \(CommonConst.logAssociateId)=\(associateId)"
    }
}

extension SSOAuthType {
    fileprivate func ssoSDKCancelUrl() -> URL? {
        guard case let .sdk(appId, state, otherParams) = self else {
            return nil
        }

        var redirectURL: URL?

        // 新版本参数中有redirectUri 老版本没有
        if var redirectUri = otherParams[SSOURL.ParamKey.redirectUri] {
            if redirectUri.hasSuffix("/") {
                redirectUri.removeLast()
            }
            redirectURL = URL(string: redirectUri)
        } else {
            redirectURL = SSOURL.appIdRedirectUrl(appId)
        }

        if let url = redirectURL {
            ssoSdkLog("cancel with redirect url \(url.absoluteString)", state: state)
            return SSOURL.cancelUrl(with: url, state: state)
        } else {
            ssoSdkLog("cancel with no redirect url", state: state)
            return nil
        }
    }

    fileprivate func ssoSDKFailureUrl(errCode: Int) -> URL? {
        guard case let .sdk(appId, state, otherParams) = self else {
            return nil
        }

        var redirectURL: URL?

        // 新版本参数中有redirectUri 老版本没有
        if var redirectUri = otherParams[SSOURL.ParamKey.redirectUri] {
            if redirectUri.hasSuffix("/") {
                redirectUri.removeLast()
            }
            redirectURL = URL(string: redirectUri)
        } else {
            redirectURL = SSOURL.appIdRedirectUrl(appId)
        }

        if let url = redirectURL {
            ssoSdkLog("failure with redirect url \(url.absoluteString)", state: state)
            return SSOURL.failureUrl(with: url, errorCode: errCode, state: state)
        } else {
            ssoSdkLog("failure with no redirect uri", state: state)
            return nil
        }
    }

    private func ssoSdkLog(_ content: String, state: String) {
        SSOBaseViewModel.logger.info(
            SSOBaseViewModel.ssoSDKLog(original: content, associateId: state)
        )
    }
}

extension V3UserConfirm {
    func toLoginAuthInfo() -> LoginAuthInfo {
        return LoginAuthInfo(
            template: .authz,
            thirdPartyAuthInfo: self,
            suiteAuthInfo: nil,
            authAutoLoginInfo: nil,
            buttonList: nil
        )
    }
}
