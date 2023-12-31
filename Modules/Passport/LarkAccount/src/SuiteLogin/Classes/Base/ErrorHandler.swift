//
//  ErrorHandler.swift
//  SuiteLogin
//
//  Created by quyiming@bytedance.com on 2019/10/22.
//

import Foundation
import LKCommonsLogging
import UniverseDesignToast
import LarkAlertController
import LarkLocalizations
import EENavigator

protocol ErrorHandler: AnyObject {
    func handle(_ error: Error)
}

class V3ErrorHandler: ErrorHandler {

    static let logger = Logger.plog(V3ErrorHandler.self, category: "SuiteLogin.V3ErrorHandler")

    weak var vc: UIViewController?

    private let context: UniContextProtocol?

    private var passportEventBus: PassportEventBusProtocol

    private var contextExpiredPostEvent: Bool = V3ErrorHandler.defaultContextExpiredPostEvent

    private var showToastOnWindow: Bool = V3ErrorHandler.defaultShowToastOnWindow

    static let defaultContextExpiredPostEvent: Bool = true

    static let defaultShowToastOnWindow: Bool = false

    init(
        vc: UIViewController,
        context: UniContextProtocol,
        contextExpiredPostEvent: Bool = V3ErrorHandler.defaultContextExpiredPostEvent,
        showToastOnWindow: Bool = V3ErrorHandler.defaultShowToastOnWindow
    ) {
        self.vc = vc
        self.context = context
        self.contextExpiredPostEvent = contextExpiredPostEvent
        self.showToastOnWindow = showToastOnWindow
        self.passportEventBus = LoginPassportEventBus.shared
    }

    func handle(_ error: Error) {
        switch error {
        case let error as V3LoginError:
            handleLogin(error)
        case let error as EventBusError:
            handleEventBus(error)
        default:
            V3ErrorHandler.logger.warn("ui not handle error: \(error)")
        }
    }

    public func handleEventBus(_ error: EventBusError) {
        switch error {
        case let .internalError(loginError):
            handleLogin(loginError)
        case .castContextFail:
            defaultEventBusHandle("V3BaseVC: hanlde EventBus castContextFail error", errorMsg: BundleI18n.suiteLogin.Lark_Passport_BadServerData)
        case .noHandler:
            defaultEventBusHandle("V3BaseVC: hanlde EventBus noHandler error", errorMsg: BundleI18n.suiteLogin.Lark_Passport_BadServerData)
        case .invalidParams:
            defaultEventBusHandle("V3BaseVC: hanlde EventBus invalidParams error", errorMsg: BundleI18n.suiteLogin.Lark_Passport_BadServerData)
        case .invalidEvent:
            // not toast
            let msg = "V3BaseVC: hanlde EventBus invalidEvent warn"
            V3ErrorHandler.logger.warn(msg)
        }
    }

    // 处理 通用业务错误
    func handleCommonBizError(_ errorInfo: (V3LoginErrorInfo), confirm: (() -> Void)? = nil) -> Bool {
        V3ErrorHandler.logger.error("V3BaseVC: hanlde biz error code: \(errorInfo.type.rawValue) message: \(errorInfo.message)".desensitizeCredential())
        switch errorInfo.type {
        case .normalAlertError,
             .linkIsExpired,
             .repeatedScan,
             .isLoggingIn,
             .tokenExpired,
             .rescanNeeded:
            showAlert(errorInfo.message, confirm: confirm)
            return true
        case .normalToastError, .securityCodeTooOften:
            defaultHandleErrorInfo(errorInfo)
            return true
        case .normalFormError:
            defaultHandleErrorInfo(errorInfo)
            return true
        case .contextExpired:
            handleContextExpired(errorInfo)
            return true
        case .captchaRequired:
            handleCaptchaRequired(errorInfo)
            return true
        case .needTuringVerify:
            handleTuringVerify(errorInfo)
            return true
        case .needCrossUnit,
             .notCredentialContact,
             .applyCodeTooOften,
             .loginMobileIllegal,
             .rsaDecryptError,
             .switchUserContextExpired,
             .noMobileCredential,
             .linkIsWaitingForClick,
             .oneKeyLoginServiceError,
             .needNormalSwitch:
            /// 上层应该处理掉的错误
            V3ErrorHandler.logger.error("not hanlde biz error code: \(errorInfo.type.rawValue) message: \(errorInfo.message)".desensitizeCredential())
            return false
        case .verifyCodeError, .passwordError, .invalidUser, .serverError:
            return false
        default:
            return false
        }
    }

    public func handleLogin(_ error: V3LoginError, confirm: (() -> Void)? = nil) {
        var toastMessage = ""
        switch error {
        case .badResponse(let errorString):
            toastMessage = errorString
        case .fetchDeviceIDFail(let errorString):
            toastMessage = errorString
        case .server(let error):
            if (error as NSError).code != NSURLErrorCancelled {
                toastMessage = error.localizedDescription
            }
        case .transformJSON(let error):
            toastMessage = I18N.Lark_Passport_BadServerData
        case .resetEnvFail(let errorString):
            toastMessage = errorString
        case .badServerCode(let errorInfo):
            if handleCommonBizError(errorInfo, confirm: confirm) {
                return
            }
            toastMessage = errorInfo.message
        case .networkNotReachable(let needShowAlert):
            if needShowAlert {
                handleNetworkNotReachableError()
            }
            return
        case .toastError(let msg):
            toastMessage = msg
        case .alertError(let msg):
            showAlert(msg) {
                return
            }
        default:
            break
        }
        defaultHandleLoginError("V3BaseVC: hanlde login error: \(error.loggerInfo) message: \(toastMessage)", errorMsg: toastMessage)
    }

    public func handleContextExpired(_ errorInfo: V3LoginErrorInfo) {
        if contextExpiredPostEvent {
            V3ErrorHandler.showAlert(errorInfo.message, vc: vc, confirm: {
                self.post(errorInfo)
            })
        } else {
            showToast(errorInfo.message)
        }
    }

    private func handleCaptchaRequired(_ errorInfo: V3LoginErrorInfo) {
        defaultHandleErrorInfo(errorInfo)
    }

    private func handleTuringVerify(_ errorInfo: V3LoginErrorInfo) {
        guard let paramString = errorInfo.detail["decision"] as? String, let data = paramString.data(using: .utf8) else {
            V3ErrorHandler.logger.error("Turing verify: invalid decison")
            showToast(errorInfo.message)
            return
        }
        
        do {
            V3ErrorHandler.logger.info("Turing verify start")
            if let params = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String : Any] {
                TuringService.shared.verify(modelParams: params, completion: { _ in })
            }
        } catch {
            V3ErrorHandler.logger.error("Failed to parse turing verify model")
            showToast(errorInfo.message)
            return
        }
        
    }

    public func defaultHandleErrorInfo(_ errorInfo: V3LoginErrorInfo) {
        showToast(errorInfo.message)
    }

    public func defaultHandleLoginError(_ logMsg: String, errorMsg: String) {
        V3ErrorHandler.logger.error(logMsg)
        if !errorMsg.isEmpty {
            showToast(errorMsg)
        }
    }

    public func defaultEventBusHandle(_ logMsg: String, errorMsg: String) {
        V3ErrorHandler.logger.error(logMsg)
        showToast(errorMsg)
    }

    private func handleNetworkNotReachableError() {
        SuiteLoginUtil.runOnMain {
            var tmpUrl: URL?
            SuiteLoginUtil.currentLanguage(action: { (current) -> Bool in
                tmpUrl = BundleConfig.LarkAccountBundle.url(forResource: "help_\(current.localeIdentifier)", withExtension: "html")
                return tmpUrl != nil
            }) { (fallback) in
                tmpUrl = BundleConfig.LarkAccountBundle.url(forResource: "help_\(fallback.localeIdentifier)", withExtension: "html")
            }
            guard let url = tmpUrl,
                let appendParamURL = SuiteLoginUtil.queryURL(urlString: url.absoluteString, params: [CommonConst.appName: BundleI18n.bundleDisplayName]) else {
                self.showToast(I18N.Lark_Passport_LoginInitNetworkError)
                V3ErrorHandler.logger.error("not found help url")
                return
            }
            let controller = LarkAlertController()
            controller.setContent(text: I18N.Lark_Login_Uanble_Connect_Internet_Des)
            controller.addSecondaryButton(text: I18N.Lark_Login_Uanble_Connect_Internet_Cancel)
            controller.addPrimaryButton(
                text: I18N.Lark_Login_Uanble_Connect_Internet_Help,
                dismissCompletion: {
                    let stepInfo: Codable? = nil
                    self.passportEventBus.post(
                        event: V3NativeStep.simpleWeb.rawValue,
                        context: V3LoginContext(serverInfo: stepInfo, additionalInfo: V3SimpleWebInfo(url: appendParamURL)),
                        success: {}) { (err) in
                            self.showToast(I18N.Lark_Passport_LoginInitNetworkError)
                            V3ErrorHandler.logger.error("open help url with error: \(err)")
                    }
                })
            self.vc?.present(controller, animated: true, completion: nil)
        }
    }

    // MARK: UI

    public func showToast(_ message: String, on parent: UIView? = nil) {
        if !message.isEmpty {
            // NOTE: 1. 启动之前可能回被调用，导致无法取到window崩溃
            //       2. 需要UI层先处理好键盘，再回调
            DispatchQueue.main.async {
                var toShowTipsView: UIView? = parent
                if toShowTipsView == nil {
                    toShowTipsView = self.showToastOnWindow ? PassportNavigator.keyWindow : self.vc?.view
                }
                let config = UDToastConfig(toastType: .error, text: message, operation: nil)
                if let toShowView = toShowTipsView {
                    UDToast.showToast(with: config, on: toShowView)
                } else {
                    guard let mainSceneWindow = PassportNavigator.keyWindow else {
                        Self.logger.errorWithAssertion("no main scene for showToast")
                        return
                    }
                    UDToast.showToast(with: config, on: mainSceneWindow)
                }
            }
        }
    }

    func showAlert(_ message: String, confirm: (() -> Void)? = nil) {
        V3ErrorHandler.showAlert(message, vc: vc, confirm: confirm ?? {})
    }

    static func showAlert(_ message: String, title: String? = nil, confirmTitle: String? = nil, vc: UIViewController?, confirm: @escaping () -> Void) {
        if message.isEmpty {
            V3ErrorHandler.logger.error("empty message alert reject")
            return
        }
        SuiteLoginUtil.runOnMain {

            let alertVC = LarkAlertController()
            if let title = title {
                alertVC.setTitle(text: title)
            }
            alertVC.setContent(text: message)
            alertVC.addPrimaryButton(text: confirmTitle ?? BundleI18n.suiteLogin.Lark_Login_ComfirmToRestPasword, dismissCompletion:  {
                confirm()
            })
            vc?.present(alertVC, animated: true)
        }
    }

    func post(_ errorInfo: (V3LoginErrorInfo)) {
        let event = V3.Step.getNextStep(errorInfo.detail)
        let stepInfo = V3.Step.getStepInfo(errorInfo.detail)
        passportEventBus.post(event: event, context: V3RawLoginContext(stepInfo: stepInfo, context: context), success: {}, error: { _ in })
    }
}
