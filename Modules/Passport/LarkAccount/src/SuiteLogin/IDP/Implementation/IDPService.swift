//
//  IDPService.swift
//  SuiteLogin
//
//  Created by tangyunfei.tyf on 2020/4/17.
//

import Foundation
import RxSwift
import LKCommonsLogging
import Homeric
import LarkReleaseConfig
import LarkPerf
import LarkContainer
import ECOProbeMeta

class IDPService: NSObject, IDPServiceProtocol {
    static let shared: IDPService = IDPService()
    private let logger = Logger.plog(IDPService.self, category: "SuiteLogin.IDPService")

    @Provider var loginService: V3LoginService

    @Provider var idpWebViewService: IDPWebViewServiceProtocol

    lazy var idpSDKService: IDPSDKService = {
        IDPSDKService(loginService: loginService)
    }()

    var currentSupportCIdPChannels: [LoginCredentialIdpChannel] {
        if !PassportSwitch.shared.value(.toCIdPLogin) {
            return []
        }
        var optionalNormalConfig: V3NormalConfig?
        if ReleaseConfig.isLark {
            optionalNormalConfig = loginService.configInfo.config(for: V3ConfigEnv.lark)
        } else {
            optionalNormalConfig = loginService.configInfo.config(for: V3ConfigEnv.feishu)
        }

        guard let normalConfig = optionalNormalConfig,
        let idpSwitch = normalConfig.idpSwitch else {
            return []
        }

        var result: [LoginCredentialIdpChannel] = []
        _ = idpSwitch.map { (key, value) in
            if value == true, let channel = LoginCredentialIdpChannel(rawValue: key) {
                #if BETA || ALPHA
                // remove apple_id for inhouse build, because "sign in with apple" is note supported by inhouse certificate
                if channel != .apple_id {
                    result.append(channel)
                }
                #else
                result.append(channel)
                #endif
            }
        }
        return result
    }

    func fetchConfigForIDP(
        _ body: SSOUrlReqBody
    ) -> Observable<V3.Step> {
        let channel = body.authenticationChannel?.rawValue ?? "nil"
        self.logger.info("n_action_login_idp_auth_url_req", body: "source_type: \(body.sourceType), channel: \(channel)")
        return internalFetchConfigForIDP(body)
            .do(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.logger.info("n_action_login_idp_auth_url_req_suc")
            }, onError: { [weak self] error in
                guard let self = self else { return }
                self.logger.error("n_action_login_idp_auth_url_req_fail", error: error)
            })
    }

    var resultSupportCIdPChannels: [LoginCredentialIdpChannel] {
        let currentSupportChannels = self.currentSupportCIdPChannels
        var result: [LoginCredentialIdpChannel] = []
        let googleSwitch = currentSupportChannels.contains(.google)
        let appleIdSwitch = currentSupportChannels.contains(.apple_id)
        let wechatSwitch = currentSupportChannels.contains(.wechat)

#if GOOGLE_SIGN_IN
        if googleSwitch {
            result.append(.google)
        }
#endif

        if appleIdSwitch {
            if #available(iOS 13.0, *) {
                result.append(.apple_id)
            }
        }
        if wechatSwitch {
            result.append(.wechat)
        }

        return result
    }

    private func isLarkPackageAndLarkEnv() -> Bool {
        var result: Bool = ReleaseConfig.isLark && loginService.store.configEnv == V3ConfigEnv.lark
        #if DEBUG || BETA || ALPHA
        result = loginService.store.configEnv == V3ConfigEnv.lark
        #endif
        return result
    }

    private func isChannelSupportedBySDK(_ channel: LoginCredentialIdpChannel) -> Bool {
#if GOOGLE_SIGN_IN
        let supportedChannels = [LoginCredentialIdpChannel.apple_id, LoginCredentialIdpChannel.google]
#else
        let supportedChannels = [LoginCredentialIdpChannel.apple_id]
#endif
        return supportedChannels.contains(channel)
    }

    func signInWith(
        channel: LoginCredentialIdpChannel?,
        idpLoginInfo: IDPLoginInfo?,
        from: UIViewController,
        sceneInfo: [String: String] = [:],
        switchUserStatusSub: PublishSubject<SwitchUserStatus>?,
        context: UniContextProtocol
    ) -> Observable<IDPServiceStep> {
        if let scene = self.sceneFromSceneInfo(sceneInfo: sceneInfo) {
            MultiSceneMonitor.shared.start(scene: scene)
            MultiSceneMonitor.shared.addCategoryInfo(scene: scene, info: sceneInfo)
        }

        SuiteLoginTracker.track(Homeric.CLICK_INTO_THIRD_PARTY, params: ["type": channel?.rawValue ?? ""])
        self.logger.info("call sign in with channel: \(String(describing: channel?.rawValue))")
        return Observable.create({ [weak self] (ob) -> Disposable in
            guard let self = self else { return Disposables.create() }
            
            if self.isLarkPackageAndLarkEnv(),
                let channel = channel,
                self.isChannelSupportedBySDK(channel) {
                self.logger.info("n_action_idp_auth_sdk")
                if let scene = self.sceneFromSceneInfo(sceneInfo: sceneInfo) {
                    MultiSceneMonitor.shared.addCategoryInfo(scene: scene, info: [
                        "idp_category": "sdk"
                    ])
                    MultiSceneMonitor.shared.end(scene: scene)
                }

                var extraInfo: [String: Any] = [:]
                if let idpLoginInfo = idpLoginInfo {
                    if let stateTokenKey = idpLoginInfo.stateTokenKey {
                        extraInfo[CommonConst.stateTokenKey] = stateTokenKey
                    }

                    if let sourceType = idpLoginInfo.sourceType {
                        extraInfo[CommonConst.sourceType] = sourceType
                    }

                    if let queryScope = idpLoginInfo.queryScope {
                        extraInfo[CommonConst.queryScope] = queryScope
                    }
                }

                SuiteLoginTracker.track(Homeric.LOGIN_THIRD_PARTY, params: [
                    "type": channel.rawValue,
                    "method": "sdk",
                    "source_type": extraInfo[CommonConst.sourceType] ?? ""
                ])

                self.signInWithSDK(channel: channel, from: from, extraInfo: extraInfo, success: { [weak self] (idpServiceStep) in
                    switch idpServiceStep {
                    case .stepData(let step, let stepInfo):
                        self?.logger.info("n_action_idp_auth_sdk_suc", body: "\(step)")
                        
                        SuiteLoginTracker.track(Homeric.LOGIN_THIRD_PARTY_RESULT, params: [
                            "type": channel.rawValue,
                            "method": "sdk",
                            "source_type": extraInfo[CommonConst.sourceType] ?? "",
                            "result": "success"
                        ])
                        ob.onNext(IDPServiceStep.stepData(step: step, stepInfo: stepInfo))
                        ob.onCompleted()
                    default:
                        self?.logger.error("n_action_idp_auth_sdk_fail", body: "not supposed to receive step: \(idpServiceStep)")
                        
                        break
                    }
                }) { [weak self] (error) in
                    SuiteLoginTracker.track(Homeric.LOGIN_THIRD_PARTY_RESULT, params: [
                        "type": channel.rawValue,
                        "method": "sdk",
                        "source_type": extraInfo[CommonConst.sourceType] ?? "",
                        "result": "fail"
                    ])
                    
                    self?.logger.error("n_action_idp_auth_sdk_fail", error: error)
                    ob.onError(error)
                }

            } else {
                if let scene = self.sceneFromSceneInfo(sceneInfo: sceneInfo) {
                    MultiSceneMonitor.shared.addCategoryInfo(scene: scene, info: [
                        "idp_category": "webview"
                    ])
                }

                SuiteLoginTracker.track(Homeric.LOGIN_THIRD_PARTY, params: [
                    "type": channel?.rawValue ?? "",
                    "method": "webview"
                ])

                guard let idpLoginInfo = idpLoginInfo else {
                    SuiteLoginTracker.track(Homeric.LOGIN_THIRD_PARTY_RESULT, params: [
                        "type": channel?.rawValue ?? "",
                        "method": "webview",
                        "result": "fail"
                    ])
                    if let scene = self.sceneFromSceneInfo(sceneInfo: sceneInfo) {
                        MultiSceneMonitor.shared.addCategoryInfo(scene: scene, info: [
                            MultiSceneMonitor.Const.result.rawValue: "error"
                        ])
                        MultiSceneMonitor.shared.end(scene: scene)
                    }
                    let sceneString = sceneInfo[MultiSceneMonitor.Const.scene.rawValue]
                    
                    self.logger.error("n_action_idp_auth_web_auth_fail", body: "idp login info is nil, scene: \(String(describing: sceneString))")
                    
                    ob.onError(V3LoginError.transformJSON(V3LoginError.clientError("idp login info is nil")))
                    return Disposables.create()
                }

                self.idpWebViewService.loginPageForIDPLoginInfo(
                    idpLoginInfo,
                    context: context,
                    passportEventBus: LoginPassportEventBus.shared,
                    switchUserStatusSub: switchUserStatusSub,
                    from: from, success: { (idpServiceStep) in
                    switch idpServiceStep {
                    case .inAppWebPage(_):
                        self.logger.info("n_action_idp_auth_goto_web", additionalData: ["open_with": "in_app_web"])
                        PassportMonitor.flush(EPMClientPassportMonitorLoginCode.idp_b_login_auth_url_browser_open, categoryValueMap: [
                            "browser_type" : "internal"
                        ], context: context)
                        
                        if let scene = self.sceneFromSceneInfo(sceneInfo: sceneInfo) {
                            MultiSceneMonitor.shared.end(scene: scene)
                        }

                        ob.onNext(idpServiceStep)
                    case .systemWebPage(let urlString):
                        self.logger.info("n_action_idp_auth_goto_web", additionalData: ["open_with": "system_web"])
                        PassportMonitor.flush(EPMClientPassportMonitorLoginCode.idp_b_login_auth_url_browser_open, categoryValueMap: [
                            "browser_type" : "external"
                        ], context: context)
                        
                        ob.onNext(idpServiceStep)
                    case .stepData(let step, _):
                        self.logger.info("n_action_idp_auth_web_auth_suc", body: "\(step)")
                        PassportMonitor.flush(EPMClientPassportMonitorLoginCode.idp_b_login_browser_auth_succ, context: context)
                        ob.onNext(idpServiceStep)
                        ob.onCompleted()
                    }
                }, error: { [weak self] (error) in
                    if let scene = self?.sceneFromSceneInfo(sceneInfo: sceneInfo) {
                        MultiSceneMonitor.shared.addCategoryInfo(scene: scene, info: [
                            MultiSceneMonitor.Const.result.rawValue: "error"
                        ])
                        MultiSceneMonitor.shared.end(scene: scene)
                    }

                    SuiteLoginTracker.track(Homeric.LOGIN_THIRD_PARTY_RESULT, params: [
                        "type": channel?.rawValue ?? "",
                        "method": "webview",
                        "result": "fail"
                    ])
                    let sceneString = sceneInfo[MultiSceneMonitor.Const.scene.rawValue]
                    self?.logger.error("n_action_idp_auth_web_auth_fail", body: "fail to create web page for idp, scene: \(String(describing: sceneString))", error: error)
                    
                    ob.onError(error)
                })
            }
            return Disposables.create()
        })
    }

    private func sceneFromSceneInfo(sceneInfo: [String: String]) -> MultiSceneMonitor.Scene? {
        if let sceneString = sceneInfo[MultiSceneMonitor.Const.scene.rawValue],
            let scene = MultiSceneMonitor.Scene(rawValue: sceneString) {
            return scene
        }
        return nil
    }

    private func signInWithSDK(channel: LoginCredentialIdpChannel, from: UIViewController, extraInfo: [String: Any]?, success: V3IDPLoginSuccess = nil, error: V3IDPLoginError = nil) {
        var defaultExtraInfo: [String: Any] = [:]
        if let foregroundUserID = self.loginService.store.foregroundUserID, // user:current
            self.loginService.store.isLoggedIn == true {
            defaultExtraInfo["user_id"] = foregroundUserID // user:current
        }
        var finalExtraInfo: [String: Any] = defaultExtraInfo
        if let extraInfo = extraInfo {
            finalExtraInfo = defaultExtraInfo.merging(extraInfo) { (_, new) in new }
        }

        switch channel {
        case .apple_id:
            if #available(iOS 13.0, *) {
                idpSDKService.signInForAppleID(from: from, extraInfo: finalExtraInfo, success: success, error: error)
            }
        case .google:
            idpSDKService.signInForGoogle(from: from, extraInfo: finalExtraInfo, success: success, error: error)
        default:
            self.logger.error("call sign in with unsupported channel")
        }
    }

    private func internalFetchConfigForIDP(
        _ body: SSOUrlReqBody
    ) -> Observable<V3.Step> {
        guard SuiteLoginUtil.isNetworkEnable() else {
            return .error(V3LoginError.networkNotReachable(true))
        }
        return idpWebViewService
            .fetchConfigForIDP(body)
    }
}
