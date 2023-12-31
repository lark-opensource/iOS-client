//
//  AuthorizationImp.swift
//  LarkAccount
//
//  Created by Miaoqi Wang on 2020/12/1.
//

import UIKit
import Swinject
import LarkAccountInterface
import LarkAssembler
import LarkContainer
import EENavigator
import LKCommonsLogging
import RxSwift

class AuthorizationAssembly: LarkAssemblyInterface {

    public func registContainer(container: Swinject.Container) {
        container.inObjectScope(PassportUserScope.userScope).register(PassportAuthorizationService.self) { r -> PassportAuthorizationService in
            return try PassportAuthorizationServiceImpl(resolver: r)
        }

        container.inObjectScope(PassportUserScope.userScope).register(SSOAPI.self) { _ -> SSOAPI in
            return SSOAPI()
        }
    }

    public func registRouter(container: Swinject.Container) {
        Navigator.shared.registerRoute.type(SSOVerifyBody.self).handle { (r, body, _, response) in
            let startDate = Date()
            let context = UniContextCreator.create(.authorization)
            PassportMonitor.flush(PassportMonitorMetaAuthorization.authorizationEnter, eventName: ProbeConst.monitorEventName, categoryValueMap: [ProbeConst.authorizationType: "applink"], context: context)
            PassportMonitor.flush(PassportMonitorMetaAuthorization.startAuthorizationScan, eventName: ProbeConst.monitorEventName, categoryValueMap: [ProbeConst.authorizationType: "applink"], context: context)
            let userResolver: UserResolver? = PassportUserScope.enableUserScopeTransitionAccount ? r : nil
            let vm = SSOBaseViewModel(resolver: userResolver, info: .url(body.qrCode, body.bundleId, body.schema), startDate: startDate)
            response.end(resource: CheckAuthTokenViewController(vm: vm, resolver: userResolver))
        }
    }

    public func registURLInterceptor(container: Swinject.Container) {
        (SSOVerifyBody.pattern, { (url: URL, from: NavigatorFrom) in
            guard PassportConf.shared.appConfig.featureOn(for: .sso) else { return }
            // 首次启动或登录后立即调起 需要等待首页加载
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                Navigator.shared.present(url, from: from, prepare: { $0.modalPresentationStyle = .overCurrentContext })
            }
        })
    }
}

class PassportAuthorizationServiceImpl {

    static let logger = Logger.log(PassportAuthorizationServiceImpl.self, category: "LarkAccount.PassportAuthorizationServiceImpl")

    let disposeBag = DisposeBag()
    let unloginProcessHandler: UnloginProcessHandler
    let ssoAPI: SSOAPI

    private let userResolver: UserResolver

    init(resolver: UserResolver) throws {
        self.userResolver = resolver
        unloginProcessHandler = try resolver.resolve(assert: UnloginProcessHandler.self)
        ssoAPI = try resolver.resolve(assert: SSOAPI.self)
    }

}

extension PassportAuthorizationServiceImpl: PassportAuthorizationService {
    func checkAuth(info: LarkAccountInterface.SSOAuthType, result: @escaping (Result<UIViewController?, Error>) -> Void) {
        let startDate = Date()
        let context = UniContextCreator.create(.authorization)
        let authorizationType: String
        switch info {
        case .sdk:
            authorizationType = "sdk"
        case .qrCode:
            authorizationType = "qrcode"
        case .url:
            fallthrough
        case .authAutoLogin:
            authorizationType = "applink"
        }
        PassportMonitor.flush(PassportMonitorMetaAuthorization.authorizationEnter, eventName: ProbeConst.monitorEventName, categoryValueMap: [ProbeConst.authorizationType: authorizationType], context: context)
        PassportMonitor.flush(PassportMonitorMetaAuthorization.startAuthorizationScan, eventName: ProbeConst.monitorEventName, categoryValueMap: [ProbeConst.authorizationType: authorizationType], context: context)
        let vm = SSOBaseViewModel(resolver: userResolver, info: info, startDate: startDate)
        vm.check()
            .subscribe { (authInfo) in
                if let authInfo = authInfo {
                    if let vc = AuthorizationBaseViewController.loginAuthViewController(vm: vm, authInfo: authInfo, resolver: self.userResolver) {
                        result(.success(vc))
                    } else {
                        result(.failure(V3LoginError.badServerData))
                    }
                } else {
                    result(.success(nil))
                }
            } onError: { (error) in
                result(.failure(error))
            }.disposed(by: disposeBag)
    }

    func handleSSOSDKUrl(_ url: URL) -> Bool {
        Self.logger.info("n_action_open_sso_sdk_auth")
        let startDate = Date()
        let context = UniContextCreator.create(.authorization)
        PassportMonitor.flush(PassportMonitorMetaAuthorization.authorizationEnter, eventName: ProbeConst.monitorEventName, categoryValueMap: [ProbeConst.authorizationType: "sdk"], context: context)
        PassportMonitor.flush(PassportMonitorMetaAuthorization.startAuthorizationScan, eventName: ProbeConst.monitorEventName, categoryValueMap: [ProbeConst.authorizationType: "sdk"], context: context)

        guard let queryURL = url.queryParameters[SSOURL.ParamKey.url],
              let encodedURL = URL(string: queryURL.passport_urlQueryEncodedString()) // queryParameters 会去掉url参数的encode信息，导致生成URL对象失败。
              else {
            Self.logger.error("n_action_open_sso_sdk_auth", body: "Invalid query url")
            PassportMonitor.monitor(PassportMonitorMetaAuthorization.authorizationScanResult, eventName: ProbeConst.monitorEventName, categoryValueMap: [ProbeConst.authorizationType: "sdk"], context: context).setErrorCode("-3").setErrorMessage("Invalid query url.").setResultTypeFail().flush()

            return false
        }

        // 暂时不做 SDK Path 的校验，和 Android 同步
//        guard url.path == SSOURL.Const.sdkOAuth else {
//            Self.logger.info("n_action_open_sso_sdk_auth", body: "Path is not sdk oauth, will open url in browser")
//            return false
//        }

        let queries = encodedURL.queryParameters
        guard let appId = queries[SSOURL.ParamKey.clientId],
              let state = queries[SSOURL.ParamKey.state] else {
                  Self.logger.error("n_action_open_sso_sdk_auth", body: "invalid params: \(queries[SSOURL.ParamKey.clientId] ?? ""), \((queries[SSOURL.ParamKey.state] ?? "").desensitized())")
            PassportMonitor.monitor(PassportMonitorMetaAuthorization.authorizationScanResult, eventName: ProbeConst.monitorEventName, categoryValueMap: [ProbeConst.authorizationType: "sdk"], context: context).setErrorCode("-4").setErrorMessage("Invalid parameters.").setResultTypeFail().flush()

            return false
        }

        Self.logger.info("n_action_open_sso_sdk_auth", body: "appId: \(appId), state: \(state.desensitized()), loggedIn: \(PassportStore.shared.isLoggedIn)")

        guard PassportStore.shared.isLoggedIn else {
            Self.logger.info("n_action_open_sso_sdk_auth", body: "set unloginProcessHandler")
            // 处理未登录情况下的 SSO 唤起，保存 url 直到登录后重新授权
            unloginProcessHandler.lastVisitURL = url
            PassportMonitor.monitor(PassportMonitorMetaAuthorization.authorizationScanResult, eventName: ProbeConst.monitorEventName, categoryValueMap: [ProbeConst.authorizationType: "sdk"], context: context).setErrorCode("-5").setErrorMessage("Is not login state.").setResultTypeFail().flush()

            return true
        }

        // 首次启动或登录后立即调起 需要等待首页加载
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            guard let mainSceneWindow = PassportNavigator.getUserScopeKeyWindow(userResolver: self.userResolver) else {
                Self.logger.error("n_page_ssosdk_loading_start", body: "no main scene for handle sso sdk url")
                PassportMonitor.monitor(PassportMonitorMetaAuthorization.authorizationScanResult, eventName: ProbeConst.monitorEventName, categoryValueMap: [ProbeConst.authorizationType: "sdk"], context: context).setErrorCode("-6").setErrorMessage("No main scene to handle sso sdk url.").setResultTypeFail().flush()

                return
            }

            let vm = SSOBaseViewModel(resolver: self.userResolver, info: .sdk(appId, state, queries), startDate: startDate)
            let vc = CheckAuthTokenViewController(vm: vm, resolver: self.userResolver)
            vc.modalPresentationStyle = .overCurrentContext

            Self.logger.info("n_page_ssosdk_loading_start")
            self.userResolver.navigator.present(vc, from: mainSceneWindow)
        }
        return true
    }

    func getAuthorizationCode(req: LarkAccountInterface.AuthCodeReq, result: @escaping (Result<LarkAccountInterface.AuthCodeResp, Error>) -> Void) {
        ssoAPI.getAuthorizationCode(reqBody: req)
            .subscribe(onNext: { code in
                result(.success(code))
            }, onError: { error in
                result(.failure(error))
            })
            .disposed(by: disposeBag)
    }
}
