//
//  PassportWebAuthNService.swift
//  LarkAccount
//
//  Created by ZhaoKejie on 2023/2/21.
//

import Foundation
import AuthenticationServices
import LarkContainer
import LKCommonsLogging
import ECOProbeMeta
import LarkLocalizations
import LocalAuthentication
import UniverseDesignToast

public enum ActionType: Int{
    case register = 0
    case auth = 1
}

public protocol PassportWebAuthService {

    var actionType: ActionType { get }

    var isSupportAuth: Bool { get }

    var callback: ((Bool, [String: Any]) -> Void)? { get }

    var addtionalParams: [String: Any] { set get }

    func start()

}

// MARK: - default Impl
class PassportWebAuthServiceBaseImpl: NSObject, PassportWebAuthService {

    private static let logger = Logger.plog(PassportWebAuthServiceBaseImpl.self, category: "PassportWebAuthServiceDefaultImpl")

    @Provider var client: HTTPClient

    let actionType: ActionType

    var usePackageDomain: Bool = false

    var addtionalParams: [String : Any] = [:]

    var mfaToken: String?

    var context: UniContextProtocol = UniContext(.unknown)

    var callback: ((Bool, [String : Any]) -> Void)?

    var errorHandler: ((Error) -> Void)?

    var toast: UniverseDesignToast.UDToast?

    var beginLogID: String?

    var finishLogID: String?

    var isSupportAuth: Bool = {
        //判断端上是否开启了锁屏认证
        let laContext = LAContext()
        let evaluate = laContext.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
        return evaluate
    }()

    func processBegin() {
        let beginParams: [String: Any] = addtionalParams
        switch actionType {
        case .register:
            beginRegist(params: beginParams) { [weak self] stepInfo, logID in
                self?.addtionalParams = [:]
                self?.beginLogID = logID
                self?.requestAuthenticator(params: stepInfo)
            }
        case .auth:
            self.toast = PassportLoadingService.showLoading()
            beginAuth(params: beginParams) { [weak self] stepInfo, logID in
                self?.addtionalParams = ["flow_type": stepInfo["flow_type"] ?? ""]
                self?.beginLogID = logID
                self?.requestAuthenticator(params: stepInfo)
            }
        }
    }

    func processFinish(params: [String : Any]) {
        var finishParams: [String: Any] = addtionalParams
        finishParams.merge(params) { _, addParms in addParms }
        switch actionType {
        case .register:
            finishRegist(params: finishParams) { [weak self] _, logID in
                self?.finishLogID = logID
            }
        case .auth:
            self.toast = PassportLoadingService.showLoading()
            finishAuth(params: finishParams) { [weak self] _, logID in
                self?.finishLogID = logID
            }
        }
    }

    func requestAuthenticator(params: [String : Any]) {
        assertionFailure("Please use browserImpl or NativeImpl")
        end(endReason: .systemNotSupport, stage: "requestAuthenticator")
    }

    init(actionType: ActionType) {
        self.actionType = actionType
    }

    convenience init(actionType: ActionType, context: UniContextProtocol = UniContext(.unknown), addtionalParams: [String: Any]) {
        self.init(actionType: actionType)
        self.context = context
        self.addtionalParams = addtionalParams

        if actionType == .register {
            //mfa token是header传的不是body传的
            self.mfaToken = self.addtionalParams["mfa_token"] as? String
            self.addtionalParams.removeValue(forKey: "mfa_token")
        }
    }

    convenience init(actionType: ActionType,
                     context: UniContextProtocol,
                     addtionalParams: [String: Any],
                     callback: @escaping ((Bool, [String: Any]) -> Void),
                     usePackageDomain: Bool = false,
                     errorHandler: ((Error) -> Void)? = nil) {
        self.init(actionType: actionType, context: context, addtionalParams: addtionalParams)
        self.callback = callback
        self.errorHandler = errorHandler
        self.usePackageDomain = usePackageDomain
    }

    func start() {
        if case .register = self.actionType {
            PassportMonitor.flush(EPMClientPassportMonitorFidoCode.passport_fido_reg_start, context: self.context)
        } else {
            PassportMonitor.flush(EPMClientPassportMonitorFidoCode.passport_fido_auth_start, context: self.context)
        }
        PassportMonitor.flush(PassportMonitorMetaStep.startFidoVerify,
                              eventName: ProbeConst.monitorEventName,
                              context: context)
        guard isSupportAuth else {
            end(endReason: .screenLockClose, stage: "before_begin")
            return
        }

        processBegin()

    }

    func end(endReason: EndReason, stage: String) {
        if case .success = endReason {
            switch actionType {
            case .register:
                PassportMonitor.flush(EPMClientPassportMonitorFidoCode.passport_fido_reg_succ,
                                      categoryValueMap: ["begin_logid": beginLogID,
                                                         "finish_logid": finishLogID],
                                      context: self.context)
            case .auth:
                PassportMonitor.flush(EPMClientPassportMonitorFidoCode.passport_fido_auth_succ,
                                      categoryValueMap: ["begin_logid": beginLogID,
                                                         "finish_logid": finishLogID],
                                      context: self.context)
                self.toast?.remove()
            }
        } else {
            switch actionType {
            case .register:
                PassportMonitor.flush(EPMClientPassportMonitorFidoCode.passport_fido_reg_fail,
                                      categoryValueMap: ["begin_logid": beginLogID,
                                                         "finish_logid": finishLogID,
                                                         "error_msg": endReason.getMessage(type: actionType),
                                                         "end_case": endReason.desc,
                                                         "stage": stage],
                                      context: self.context)
            case .auth:
                PassportMonitor.flush(EPMClientPassportMonitorFidoCode.passport_fido_auth_fail,
                                      categoryValueMap: ["begin_logid": beginLogID,
                                                         "finish_logid": finishLogID,
                                                         "error_msg": endReason.getMessage(type: actionType),
                                                         "end_case": endReason.desc,
                                                         "stage": stage],
                                      context: self.context)
                self.toast?.remove()
            }

            if case .serverError(let error) = endReason {
                errorHandler?(error)
            } else {
                let remindMethod = (endReason.code / 100) % 10
                var error: V3LoginError?
                switch remindMethod {
                case -1:
                    error = V3LoginError.alertError(endReason.getMessage(type: actionType))
                case -2:
                    error = V3LoginError.toastError(endReason.getMessage(type: actionType))
                default:
                    error = nil
                }
                if let error = error {
                    errorHandler?(error)
                }
            }
        }

        if let callback = callback {
            var callbackParams: [String: Any] = ["code": endReason.code, "message": endReason.getMessage(type: actionType)]
            if let beginLogID = beginLogID {
                callbackParams["beginLogid"] = beginLogID

            }
            if let finishLogID = finishLogID {
                callbackParams["finishLogid"] = finishLogID
            }
            if case .success = endReason {
                callback(true, callbackParams)
            } else {
                callback(false, callbackParams)
            }

        }
    }

}

// MARK: - Common API
extension PassportWebAuthServiceBaseImpl {

    /// 注册场景，不需要参数，需要callback begin、finish的logid，需要callback一个code和message
    func beginRegist(params:[String: Any], complete: @escaping ([String: Any], _ logID: String) -> Void) {
        // 发起BeginRegister请求：准备参数
        let req = AfterLoginRequest<V3.Step>(pathPrefix: CommonConst.v4APIPathPrefix, pathSuffix: APPID.fidoBeginRegist.apiIdentify())
        req.method = .post
        req.domain = .passportAccounts(usingPackageDomain: self.usePackageDomain)
        if let mfaToken = self.mfaToken {
            req.add(headers: [CommonConst.xMfaToken: mfaToken])
        }
        req.body = params

        client.send(req) {[weak self] step, header in

            guard step.stepData.nextStep == "register_fido" else {
                Self.logger.error("n_action_webauthn_register_begin_step_error")
                self?.end(endReason: .stepError, stage: "begin_regist")
                //如果下发其他的step就push到状态机中
                LoginPassportEventBus.shared.post(event: step.stepData.nextStep, context: V3RawLoginContext(stepInfo: step.stepData.stepInfo, context: UniContext(.fidoCutout)), success: {
                    Self.logger.info("n_action_webauthn_register_begin_step_error_cutout_succ")
                }, error: { error in
                    Self.logger.error("n_action_webauthn_register_begin_step_error_cutout_error", error: error)
                })
                return
            }
            // 完成beginRegist
            complete(step.stepData.stepInfo, header.xTTLogid ?? "")

        } failure: {[weak self] error in
            Self.logger.error("n_action_webauthn_register_begin_error", error: error)
            self?.end(endReason: .serverError(error), stage: "begin_regist")
        }
    }

    func finishRegist(params:[String: Any], complete: @escaping ([String: Any], _ logID: String) -> Void) {
        // 发起finish Register请求到服务端完成认证
        let req = AfterLoginRequest<V3.Step>(pathPrefix: CommonConst.v4APIPathPrefix, pathSuffix: APPID.fidoFinishRegist.apiIdentify())
        req.method = .post
        req.domain = .passportAccounts(usingPackageDomain: self.usePackageDomain)
        if let mfaToken = mfaToken {
            req.add(headers: [CommonConst.xMfaToken: mfaToken])
        }
        req.body = params
        self.client.send(req) {[weak self] _, _ in
            self?.end(endReason: .success, stage: "finish_regist")
        } failure: {[weak self] error in
            self?.end(endReason: .serverError(error), stage: "finish_regist")
        }
    }



    public func beginAuth(params: [String: Any], complete: @escaping ([String: Any], _ logID: String) -> Void) {
        // 发起BeginRegister准备参数
        let req = LoginRequest<V3.Step>(pathPrefix: CommonConst.v4APIPathPrefix, pathSuffix: APPID.fidoBeginAuth.apiIdentify())

        req.method = .post
        req.domain = .passportAccounts(usingPackageDomain: self.usePackageDomain)
        req.body = params
        req.required(.flowKey)

        client.send(req) {[weak self] (resp: V3.Step, header: ResponseHeader) in
            guard resp.stepData.nextStep == "verify_fido" else {
                Self.logger.error("n_action_webauthn_auth_begin_step_error")
                self?.end(endReason: .stepError, stage: "begin_auth")
                LoginPassportEventBus.shared.post(event: resp.stepData.nextStep, context: V3RawLoginContext(stepInfo: resp.stepData.stepInfo, context: UniContext(.fidoCutout)), success: {
                    Self.logger.info("n_action_webauthn_auth_begin_step_error_cutout_succ")
                }, error: { error in
                    Self.logger.error("n_action_webauthn_auth_begin_step_error_cutout_error", error: error)
                })
                return
            }
            complete(resp.stepData.stepInfo, header.xTTLogid ?? "")
        } failure: {[weak self] error in
            Self.logger.info("n_action_webauthn_auth_begin_step_error", error: error)
            self?.end(endReason: .serverError(error), stage: "begin_auth")
        }

    }

    public func finishAuth(params:[String: Any], complete: @escaping ([String: Any], _ logID: String) -> Void) {
        let req = LoginRequest<V3.Step>(pathPrefix: CommonConst.v4APIPathPrefix, pathSuffix: APPID.fidoFinishAuth.apiIdentify())
        req.method = .post
        req.domain = .passportAccounts(usingPackageDomain: self.usePackageDomain)
        req.required(.flowKey)
        let reqBody = params
        req.body = reqBody
        self.client.send(req).post(context: self.context).subscribe {[weak self] _ in
            self?.end(endReason: .success, stage: "finish_auth")
            Self.logger.info("n_action_webauthn_auth_finish_succ")
        } onError: {[weak self] error in
            self?.end(endReason: .serverError(error), stage: "finish_auth")
            Self.logger.error("n_action_webauthn_auth_finish_error", error: error)
        }
    }

}

// MARK: - Base64 encoder/decoder
extension PassportWebAuthService {
    //MARK: Data转Base64URL加密
    static func convertByte(data: Data?) -> String {
        guard let data = data else {
            return ""
        }
        // data数据进行base64加密
        var result = data.base64EncodedString()
        // =替换为空
        result = result.replacingOccurrences(of: "=", with: "")
        // +替换为—
        result = result.replacingOccurrences(of: "+", with: "-")
        // /替换为_
        result = result.replacingOccurrences(of: "/", with: "_")
        return result
    }

    static func convertBase64URL(base64: String?) -> Data? {
        guard let base64 = base64 else {
            return nil
        }
        // -替换为+
        var replaceFromUrl = base64.replacingOccurrences(of: "-", with: "+")
        // _替换为/
        replaceFromUrl = replaceFromUrl.replacingOccurrences(of: "_", with: "/")
        var rePadding = replaceFromUrl
        // =号补全
        let mod4 = replaceFromUrl.count % 4
        if mod4 > 0 {
            let padStr = ("====" as NSString).substring(to: (4 - mod4))
            rePadding += padStr
        }
        // base64Str转data并进行Base64Decoding
        return Data(base64Encoded: rePadding)
    }
}

enum EndReason {

    case success
    case systemNotSupport
    case screenLockClose
    case stepError
    case serverError(Error)
    case browserError(String?)
    case otherError
    case userCancel

    // https://bytedance.feishu.cn/wiki/wikcnpZaKL4plxrIzcmwWLmWROc
    var code: Int {
        switch self {
        case .success:
            return 0
        case .systemNotSupport:
            return -4104
        case .serverError(let error):
            if let error = error as? V3LoginError, case .badServerCode(let errorInfo) = error {
                return Int(errorInfo.rawCode)
            } else {
                return -4299
            }
        case .browserError:
            return -3202
        case .screenLockClose:
            return -4101
        case .stepError:
            return -4299
        case .otherError:
            return -4299
        case .userCancel:
            return -3201
        }
    }

    func getMessage(type: ActionType) -> String {
        let commonMessage: String
        switch type {
        case .register:
            commonMessage = BundleI18n.suiteLogin.Lark_Passport_AccountSecurityCenter_AccountProtection_SecurityKeyFailedToAdd_Toast
        case .auth:
            commonMessage = BundleI18n.suiteLogin.Lark_Passport_SecurityKeyVerification_UnableToVerify_Toast
        }
        switch self {
        case .success:
            return ""
        case .systemNotSupport:
            return BundleI18n.suiteLogin.Lark_Passport_AccountSecurityCenter_iOSVersionTooLow_Toast
        case .serverError(let error):
            if let error = error as? V3LoginError, case .badServerCode(let errorInfo) = error {
                return errorInfo.message
            } else {
                return commonMessage
            }
        case .browserError(let msg):
            return msg ?? commonMessage
        case .screenLockClose:
            return BundleI18n.suiteLogin.Lark_Passport_AccountSecurityCenter_AccountProtection_SecurityKeyManagementPage_LockScreenNotSetDesc
        case .stepError:
            return commonMessage
        case .otherError:
            return commonMessage
        case .userCancel:
            return commonMessage
        }
    }

    var desc: String {
        switch self {
        case .success:
            return "success"
        case .systemNotSupport:
            return "systemNotSupport"
        case .serverError:
            return "serverError"
        case .browserError:
            return "browserError"
        case .screenLockClose:
            return "screenLockClose"
        case .stepError:
            return "stepError"
        case .otherError:
            return "otherError"
        case .userCancel:
            return "userCancel"
        }
    }
}
