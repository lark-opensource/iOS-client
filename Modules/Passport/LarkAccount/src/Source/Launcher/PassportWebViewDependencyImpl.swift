//
//  PassportWebViewDependencyImpl.swift
//  LarkAccount
//
//  Created by Nix Wang on 2022/8/12.
//

import LKCommonsLogging
import LarkContainer
import LarkReleaseConfig
import LarkAccountInterface
import LarkFoundation
import LarkLocalizations
import LarkUIKit
import UniverseDesignToast
import RxSwift

class PassportWebViewDependencyImpl: PassportWebViewDependency {

    private static let logger = Logger.plog(PassportWebViewDependencyImpl.self, category: "PassportWebViewDependencyImpl")

    @Provider var loginService: V3LoginService

    @Provider var kaLoginService: KaLoginService

    @Provider var idpWebViewService: IDPWebViewServiceProtocol

    @Provider var deviceService: DeviceService

    @Provider var dependency: PassportDependency // user:checked (global-resolve)

    @Provider var client: HTTPClient

    var webAuthNService: PassportWebAuthService?
    
    var unsupportErrorTip: String {
        I18N.Lark_Passport_EmailVerificationCodeLogin_FallbackError_ActionNotSupported_Toast
    }

    func open(
        data: [String: Any],
        success: @escaping () -> Void,
        failure: @escaping (Error) -> Void
    ) {
        // JsBridge data: {"header": {}, "data": {}}
        let dataKey = "data"
        let headerKey = "header"

        guard let dataInfo = data[dataKey] as? [String: Any] else {
            failure(V3LoginError.badServerData)
            return
        }

        if let headerInfo = data[headerKey] as? [String: Any] {
            loginService.apiHelper.oneTimeHeader = headerInfo.mapValues({ (value) -> String in
                return "\(value)"
            })
        }
        let event = V3.Step.getNextStep(dataInfo)
        let stepInfo = V3.Step.getStepInfo(dataInfo)

        var additionalInfo: [String: Bool] = [:]
        if let step = PassportStep(rawValue: event),
           WebConfig.closeAllStartPointSteps.contains(step) {
            additionalInfo = CommonConst.closeAllParam
        }

        LoginPassportEventBus.shared.post(
            event: event,
            context: V3RawLoginContext(
                stepInfo: stepInfo,
                additionalInfo: additionalInfo,
                context: UniContextCreator.create(.unknown)
            ),
            success: success,
            error: failure
        )

        Self.logger.info("n_action_handle_event", additionalData: ["action": event])
    }

    func getAppInfo() -> [String: Any] {
        return [
            "device_id": deviceService.deviceId,
            "terminal_type": PassportConf.terminalType,
            "device_name": PassportConf.deviceName,
            "device_model": PassportConf.deviceModel,
            "device_os": PassportConf.deviceOS,
            "is_lark": ReleaseConfig.isLark,
            "package_name": Utils.appName
        ]
    }

    func getStepInfo() -> [String: Any] {
        return ExternalEventBus.shared.stepInfo
    }

    func nativeHttpRequest(_ args: [String : Any], success: @escaping ([String: Any]) -> Void, failure: @escaping ([String: Any]) -> Void) {
        guard let path = args["path"] as? String,
              let body = args["data"] as? [String: Any],
              let returnType = args["return_type"] as? Int,
              let method = args["method"] as? String else {
            Self.logger.info("n_action_nativeHttp_params_error")
            failure(["code": -1, "message": BundleI18n.suiteLogin.Lark_Passport_BadServerData])
            return
        }
        if returnType == 1 {
            //端上处理response
            Self.logger.info("n_action_native_httpRequest_start",additionalData: ["returnType": 1])
            let req = NativeCommonRequest<V3.Step>(pathSuffix: path)
            req.body = body
            switch method.lowercased() {
            case "get":
                req.method = .get
            case "post":
                req.method = .post
            default:
                req.method = .get
            }
            client.send(req) { step, info in
                Self.logger.info("n_action_native_httpRequest_request_succ",additionalData: ["returnType": 1])
                let rawContext = V3RawLoginContext(stepInfo: step.stepData.stepInfo, context: UniContext(.jsbridge))
                LoginPassportEventBus.shared.post(event: step.stepData.nextStep, context: rawContext) {
                    Self.logger.info("n_action_native_httpRequest_post_succ",additionalData: ["returnType": 1])
                    success(step.stepData.stepInfo)
                } error: { error in
                    Self.logger.error("n_action_native_httpRequest_post_error",additionalData: ["returnType": 1], error: error)
                    failure(["code": step.code, "message": step.errorInfo?.message])
                }
            } failure: { error in
                var callbackParams: [String: Any] = [:]
                if let error = error as? V3LoginError, case .badServerCode(let info) = error {
                    callbackParams["code"] = info.rawCode
                    callbackParams["message"] = info.message
                    callbackParams["data"] = info.detail
                    callbackParams["biz_code"] = info.bizCode
                } else {
                    callbackParams["code"] = error.errorCode
                    callbackParams["message"] = error.localizedDescription
                }
                Self.logger.error("n_action_native_httpRequest_request_error", additionalData: ["returnType": 1], error: error)
                failure(callbackParams)
            }


        } else {
            //透传给web端处理
            Self.logger.info("n_action_native_httpRequest_start", additionalData: ["returnType": 2])
            let req = NativeCommonRequest<V3.SimpleResponse>(pathSuffix: path)
            req.body = body
            switch method.lowercased() {
            case "get":
                req.method = .get
            case "post":
                req.method = .post
            default:
                req.method = .get
            }
            client.send(req) { resp, header in
                if let respStr = resp.rawData {
                    Self.logger.info("n_action_native_httpRequest_succ", additionalData: ["returnType": 2])
                    if resp.code == 0 {
                        success(respStr)
                    } else {
                        failure(["code": resp.code, "messgae": resp.errorInfo?.message ?? BundleI18n.suiteLogin.Lark_Passport_BadServerData])
                    }
                } else {
                    Self.logger.error("n_action_native_httpRequest_fail_errorData", additionalData: ["returnType": 2])
                    failure(["code": resp.code, "messgae": resp.errorInfo?.message ?? BundleI18n.suiteLogin.Lark_Passport_BadServerData])
                }
            } failure: { error in
                var callbackParams: [String: Any] = [:]
                if let error = error as? V3LoginError, case .badServerCode(let info) = error {
                    callbackParams["code"] = info.rawCode
                    callbackParams["message"] = info.message
                    callbackParams["data"] = info.detail
                    callbackParams["biz_code"] = info.bizCode
                } else {
                    callbackParams["code"] = error.errorCode
                    callbackParams["message"] = error.localizedDescription
                }
                Self.logger.error("n_action_native_httpRequest_request_error", additionalData: ["returnType": 2], error: error)
                failure(callbackParams)
            }

        }

    }

    func registerFido(_ args: [String: Any], success: @escaping ([String: Any]) -> Void, failure: @escaping ([String: Any]) -> Void) {
        guard #available(iOS 14.0, *) else {
            let endReason = EndReason.systemNotSupport
            failure(["code": endReason.code, "message": endReason.getMessage(type: .register)])
            return
        }

        var addtionalParams: [String: Any] = [:]
        if let mfaToken = args["mfa_token"] as? String {
            addtionalParams["mfa_token"] = mfaToken
        }

        if #available(iOS 16.0, *), PassportStore.shared.enableNativeWebauthnRegister, !ReleaseConfig.isKA  {
            self.webAuthNService = PassportWebauthServiceNativeImpl(actionType: .register,
                                                                    context: UniContext(.jsbridge),
                                                                    addtionalParams: addtionalParams) { isSucc, args in
                if isSucc {
                    success(args)
                } else {
                    failure(args)
                }
            }
        } else {
            self.webAuthNService = PassportWebAuthServiceBrowserImpl(actionType: .register,
                                                                     context: UniContext(.jsbridge),
                                                                     addtionalParams: addtionalParams) { isSucc, args in
                if isSucc {
                    success(args)
                } else {
                    failure(args)
                }
            }
        }

        self.webAuthNService?.start()
        Self.logger.info("n_action_Fido_beginRegister_start")
    }

    func openNativeScanVC(_ stepInfo: [String: Any], complete: @escaping (String) -> Void) {
        let decoder = JSONDecoder()
        if let scanInfo = try? decoder.decode(V4JoinTenantScanInfo.self, from: stepInfo.asData()) {
            let vc = loginService.createJoinTenantScan(scanInfo, additionalInfo: nil,
                                              api: loginService.joinTeamAPI,
                                              context: UniContext(.external),
                                              externalHandler: complete)
            LoginPassportEventBus.shared.eventRegistry.showVC(vc, vcHandler: nil)
        } else {
            complete("error")
        }
    }

    func getAppLanguage() -> [String: Any] {
        let current = LanguageManager.currentLanguage.rawValue
        Self.logger.info("n_action_jsb_impl_get_lang", additionalData: ["lang": current])
        return ["lang": current]
    }

    func setAppLanguage(_ args: [String: Any]) {
        func showErrorToast() {
            DispatchQueue.main.async {
                let config = UDToastConfig(toastType: .error,
                                           text: I18N.Lark_Passport_SSOLoginSwitchLanguageSync_UnableToSwitch_LanguageNotAvailableToast,
                                           operation: nil)
                guard let mainSceneWindow = PassportNavigator.keyWindow else {
                    Self.logger.errorWithAssertion("no main scene for showToast")
                    return
                }
                UDToast.showToast(with: config, on: mainSceneWindow)
            }
        }

        guard let langString = args["lang"] as? String,
              !langString.isEmpty else {
            showErrorToast()
            Self.logger.error("n_action_jsb_impl_set_lang_NO_ARGS")
            return
        }

        let language = Lang(rawValue: langString)
        guard LanguageManager.supportLanguages.contains(where: { $0 == language }) else {
            showErrorToast()
            Self.logger.error("n_action_jsb_impl_set_lang_DO_NOT_SUPPORT")
            return
        }

        var isSystem = false
        if let current = LanguageManager.systemLanguage,
           LanguageManager.supportLanguages.contains(current),
           current == language {
            isSystem = true
        }

        Self.logger.info("n_action_jsb_impl_set_lang", additionalData: ["lang": langString])

        if let _ = UserManager.shared.foregroundUser { // user:current
            // 端内重设语言，需要完整的重启流程，走主端逻辑
            guard let from = PassportNavigator.topMostVC else {
                return
            }
            let isSelected: Bool
            if isSystem {
                isSelected = LanguageManager.isSelectSystem
            } else {
                isSelected = language == LanguageManager.currentLanguage && !LanguageManager.isSelectSystem
            }
            let model = LanguageModel(
                name: language.displayName,
                language: language,
                isSelected: isSelected,
                isSystem: isSystem
            )
            dependency.updateAppLanguage(model: model, from: from)
        } else {
            LanguageManager.setCurrent(language: language, isSystem: isSystem)
        }

    }

    // WebView使用
    func finishedLogin(_ args: [String: Any]) {
#if SUITELOGIN_KA
        // 移除 KAR 的特化
        idpWebViewService.finishedLogin(args)
#else
        idpWebViewService.finishedLogin(args)
#endif
    }

    func getIDPConfig() -> [String: Any]? {
#if SUITELOGIN_KA
        if KAFeatureConfigManager.enableKACRC {
            return kaLoginService.getKaConfig()
        }
        // 移除 KAR 的特化
        return idpWebViewService.getIDPExternalData()
#else
        return idpWebViewService.getIDPExternalData()
#endif
    }

    func getIDPAuthConfig() -> [String : Any]? {
        return idpWebViewService.getIDPAuthConfigData()
    }

    func switchIDP(_ idp: String, completion: @escaping (Bool, Error?) -> Void) {
        idpWebViewService.switchIDP(idp, completion: completion)
    }

    func startFaceIdentify(_ args: [String: Any], success: @escaping () -> Void, failure: @escaping (Error) -> Void) {

        guard let appID = args["app_id"] as? String,
              let scene = args["scene"] as? String,
              let ticket = args["ticket"] as? String,
              let identityName = args["identity_name"] as? String,
              let identityNumber = args["identity_number"] as? String else {
            failure(V3LoginError.badLocalData(""))
            return
        }

        Self.logger.info("n_action_jsb_impl_start_face_identity")

        dependency.doFaceLiveness(appId: appID, ticket: ticket, scene: scene, identityName: identityName, identityCode: identityNumber, presentToShow: true) { _, error in
            if let error = error {
                failure(error)
            } else {
                success()
            }
        }
    }

    func enableLeftNaviButtonsRootVCOptObservable() -> Observable<Bool> {
        Observable.create { (ob) -> Disposable in
            PassportStore.shared.enableLeftNaviButtonsRootVCOptObservable.subscribe { event in
                ob.on(event)
            }
            return Disposables.create()
        }
    }

    func enableCheckSensitiveJsApi() -> Bool {
        return PassportGray.shared.getGrayValue(key: .enableSensitiveJsApiCheck)
    }

    func monitorSensitiveJsApi(apiName: String, sourceUrl: URL?, from: String) {
        let params = ["apiName": apiName, "urlPath": sourceUrl?.path ?? "", "urlHost": sourceUrl?.host ?? "", "from": from]
        let context = UniContextCreator.create(.jsbridge)
        let monitor = PassportMonitor.monitor(PassportMonitorMetaCommon.callSensitiveJsApi, type: .common, context: context, categoryValueMap: params)
        monitor.flush()
    }

    func getSaasLoginVC() -> UIViewController {
        let vc = loginService.createSaasLoginVC(enableQRCodeLogin: false, context: UniContext(.jsbridge))
        return LoginNaviController(rootViewController: vc)
    }

}
