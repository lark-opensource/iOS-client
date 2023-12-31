//
//  StartBiometrics.swift
//  LarkWeb
//
//  Created by yuanping on 2019/5/14.
//

import Alamofire
import LKCommonsLogging
import LarkAccountInterface
import LarkSetting
import LarkRustHTTP
import WebBrowser
import RustPB
import RxSwift
import SwiftyJSON
import Swinject
import LarkOPInterface
import EEMicroAppSDK
import LarkBytedCert
import LarkContainer

fileprivate extension String {
    enum ErrorInfo {
        static let code = "errorCode"
        static let msg = "errorMessage"
        // 返回给调用方的内部错误信息，保持与原逻辑返回的一致
        static let interalErrorMsg = "something error"
    }

    enum JsonKey {
        static let code = "code"
        static let data = "data"
        static let msg = "msg"
    }

    enum BizParam {
        static let appId = "appId"
        static let nonce = "nonce"
        static let timestamp = "timestamp"
        static let sign = "sign"
        static let verifyUid = "verifyUid"
        static let uid = "uid"
        static let ticketType = "ticketType"
        static let ticket = "ticket"
        static let scene = "scene"
        static let aid = "aid"
        static let mode = "mode"
        static let reqNo = "reqNo"
        static let statusCode = "status_code"
    }
}

fileprivate extension Int {
    // 与原始需求开发者确认，内部错误errorcode传-1，用于保证不与服务端errorcode冲突
    static let internalErrorCode = -1
}

fileprivate extension StartBiometrics {

    var domain: String {
        return DomainSettingManager.shared.currentSetting[.open]?.first ?? ""
    }

    var path: String {
        return "open-apis/id_verify/v1"
    }

    var verifyURL: URL? {
        return URL(string: "https://\(domain)")?.appendingPathComponent(path)
    }

    var hasAuthedURL: URL? {
        return verifyURL?.appendingPathComponent("has_authed")
    }

    var getTicketURL: URL? {
        return verifyURL?.appendingPathComponent("get_user_ticket")
    }

    var headerWithCookie: HTTPHeaders {
        if userService == nil {
            Self.logger.error("resolve PassportUserService failed")
        }
        var header = HTTPHeaders()
        header["Cookie"] = "session=\(userService?.user.sessionKey ?? "")"
        header["Content-Type"] = "application/json"
        return header
    }
}

class StartBiometrics: JsAPIHandler, UserResolverWrapper {
    static private let logger = Logger.log(StartBiometrics.self, category: "Module.JSSDK")

    @ScopedProvider private var userService: PassportUserService?
    
    let userResolver: UserResolver
    
    init(resolver: UserResolver) {
        userResolver = resolver
    }

    //流程：查询是否认证过 -> 获取ticket -> 唤起活体认证
    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        StartBiometrics.logger.info("StartBiometrics checkHasAuth start")
        checkHasAuthed(args: args, api: api, sdk: sdk, callback: callback)
    }

    private static func handleError(errorInfo: (code: Int, msg: String) = (code: Int.internalErrorCode, msg: String.ErrorInfo.interalErrorMsg), callback: WorkaroundAPICallBack) {
        callback.callbackFailure(param: [String.ErrorInfo.code: errorInfo.code,
                                         String.ErrorInfo.msg: errorInfo.msg])
    }

    private func checkHasAuthed(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        let appId = args[String.BizParam.appId] as? String ?? ""
        let nonce = args[String.BizParam.nonce] as? String ?? ""
        let timestamp = args[String.BizParam.timestamp] as? String ?? ""
        let sign = args[String.BizParam.sign] as? String ?? ""
        let requestParam: [String: String] = [String.BizParam.appId: appId,
                                              String.BizParam.nonce: nonce,
                                              String.BizParam.timestamp: timestamp,
                                              String.BizParam.sign: sign]
        let uniqueID = OPAppUniqueID(appID: appId, identifier: nil, versionType: .current, appType: .webApp)
        guard let url = hasAuthedURL, let requestUrl = url.lf.addQueryDictionary(requestParam)  else {
            StartBiometrics.logger.warn("Check has Authed fail with nil url, domain=\(domain) appId=\(appId)")
            StartBiometrics.handleError(callback: callback)
            OPMonitor(APIMonitorCodeFaceLiveness.internal_error)
                .setResultTypeFail()
                .setErrorMessage("Check has Authed fail with nil url, domain=\(domain)")
                .setUniqueID(uniqueID).flush()
            return
        }
        sdk.sessionManager.request(requestUrl, method: .get, parameters: [:], encoding: JSONEncoding.default, headers: headerWithCookie).responseJSON { [weak self](res) in
            guard let strongSelf = self else {
                StartBiometrics.logger.warn("check has authed response but handler is nil, appId=\(appId)")
                StartBiometrics.handleError(callback: callback)
                OPMonitor(APIMonitorCodeFaceLiveness.internal_error)
                    .setResultTypeFail()
                    .setErrorMessage("check has authed response but handler is nil")
                    .setUniqueID(uniqueID).flush()
                return
            }
            switch res.result {
            case .success(let value):
                let json = JSON(value)
                let code = json[String.JsonKey.code].int
                if code == 0 {
                    // 服务端返回成功, 始终保证活体检测调起
                    StartBiometrics.logger.info("Check has authed biz scuccess, appId=\(appId)")
                    OPMonitor(APIMonitorCodeFaceLiveness.check_has_authed_success).setResultTypeSuccess().setUniqueID(uniqueID).flush()
                    let verifyUID = json[String.JsonKey.data][String.BizParam.verifyUid].stringValue
                    var ticketArgs = args
                    ticketArgs[String.BizParam.uid] = verifyUID
                    ticketArgs[String.BizParam.ticketType] = "verify"
                    strongSelf.getTicket(args: ticketArgs, api: api, sdk: sdk, callback: callback)
                } else {
                    // 服务端返回业务失败
                    let errCode = code ?? Int.internalErrorCode
                    let errMsg = json[String.JsonKey.msg].stringValue
                    StartBiometrics.logger.warn("Check has authed biz fail, appId=\(appId) code=\(String(describing: code)) msg=\(errMsg)")
                    StartBiometrics.handleError(errorInfo: (code: errCode,
                                                            msg: errMsg), callback: callback)
                    strongSelf.monitorCheckHasAuthedError(uniqueID: uniqueID, code: errCode, msg: errMsg)
                }
            case .failure(let error):
                StartBiometrics.logger.error("Check has authed network fail, appId=\(appId) error= \(error)")
                StartBiometrics.handleError(callback: callback)
                OPMonitor(APIMonitorCodeFaceLiveness.check_has_authed_other_error).setResultTypeFail().setError(error).setUniqueID(uniqueID).flush()
            @unknown default:
                fatalError("Unknown type of network response")
            }
        }

    }

    private func monitorCheckHasAuthedError(uniqueID: OPAppUniqueID, code: Int, msg: String) {
        var mcode = APIMonitorCodeFaceLiveness.check_has_authed_other_error
        switch code {
        case 10_301:
            mcode = APIMonitorCodeFaceLiveness.check_has_authed_not_auth
        case 10_100:
            mcode = APIMonitorCodeFaceLiveness.check_has_authed_param_error
        default:
            break
        }
        OPMonitor(mcode).setResultTypeFail().setUniqueID(uniqueID).setErrorCode("\(code)").setErrorMessage(msg).flush()
    }

    private func getTicket(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        let appId = args[String.BizParam.appId] as? String ?? ""
        let uid = args[String.BizParam.uid] as? String ?? ""
        let ticketType = args[String.BizParam.ticketType] as? String ?? ""
        let requestParam: [String: String] = [String.BizParam.uid: uid,
                                              String.BizParam.ticketType: ticketType]
        let uniqueID = OPAppUniqueID(appID: appId, identifier: nil, versionType: .current, appType: .webApp)
        guard let url = getTicketURL, let requestURL = url.lf.addQueryDictionary(requestParam) else {
            StartBiometrics.logger.warn("Get user ticket fail with nil url, appId=\(appId) domain=\(domain)")
            StartBiometrics.handleError(callback: callback)
            OPMonitor(APIMonitorCodeFaceLiveness.internal_error)
                .setResultTypeFail()
                .setErrorMessage("Get user ticket fail with nil url, domain=\(domain)")
                .setUniqueID(uniqueID).flush()
            return
        }
        sdk.sessionManager.request(requestURL, method: .get, parameters: [:], encoding: JSONEncoding.default, headers: headerWithCookie).responseJSON { [weak self](res) in
            guard let strongSelf = self else {
                StartBiometrics.logger.warn("Get user ticket response but handler is nil, appId=\(appId)")
                StartBiometrics.handleError(callback: callback)
                OPMonitor(APIMonitorCodeFaceLiveness.internal_error)
                    .setResultTypeFail()
                    .setErrorMessage("Get user ticket response but handler is nil")
                    .setUniqueID(uniqueID).flush()
                return
            }
            switch res.result {
            case .success(let value):
                let json = JSON(value)
                let code = json[String.JsonKey.code].int
                if code == 0 {
                    // 服务端返回成功
                    let data = json[String.JsonKey.data]
                    var liveFaceArgs = args
                    let ticket = data[String.BizParam.ticket].stringValue
                    liveFaceArgs[String.BizParam.ticket] = ticket
                    liveFaceArgs[String.BizParam.scene] = data[String.BizParam.scene].stringValue
                    liveFaceArgs[String.BizParam.aid] = data[String.BizParam.appId].intValue
                    liveFaceArgs[String.BizParam.mode] = data[String.BizParam.mode].intValue
                    strongSelf.doFaceLiveness(args: liveFaceArgs, api: api, sdk: sdk, callback: callback)
                    OPMonitor(APIMonitorCodeFaceLiveness.get_user_ticket_success).setResultTypeSuccess().setUniqueID(uniqueID).flush()
                    StartBiometrics.logger.info("Get user ticket biz scuccess, appId=\(appId) code=\(code ?? -1) ticket=\(ticket)")
                } else {
                    // 服务端返回业务失败
                    let errCode = code ?? Int.internalErrorCode
                    let errMsg = json[String.JsonKey.msg].stringValue
                    StartBiometrics.logger.warn("Get user ticket biz fail, appId=\(appId) code=\(String(describing: code)) msg=\(errMsg)")
                    strongSelf.monitorGetUserTicketError(uniqueID: uniqueID, code: errCode, msg: errMsg)
                    StartBiometrics.handleError(errorInfo: (code: errCode,
                                                            msg: errMsg), callback: callback)
                }
            case .failure(let error):
                StartBiometrics.logger.error("Get user ticket network fail, appId=\(appId) error= \(error)")
                StartBiometrics.handleError(callback: callback)
                OPMonitor(APIMonitorCodeFaceLiveness.get_user_ticket_error).setResultTypeFail().setError(error).setUniqueID(uniqueID).flush()
            @unknown default:
                fatalError("Unknown type of network response")
            }
        }
    }

    private func monitorGetUserTicketError(uniqueID: OPAppUniqueID, code: Int, msg: String) {
        var mcode = APIMonitorCodeFaceLiveness.get_user_ticket_error
        switch code {
        case 10_100:
            mcode = APIMonitorCodeFaceLiveness.get_user_ticket_param_error
        default:
            break
        }
        OPMonitor(mcode).setResultTypeFail().setUniqueID(uniqueID).setErrorCode("\(code)").setErrorMessage(msg).flush()
    }

    private func doFaceLiveness(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        let appId = args[String.BizParam.appId] as? String ?? ""
        let ticket = args[String.BizParam.ticket] as? String ?? ""
        let uniqueID = OPAppUniqueID(appID: appId, identifier: nil, versionType: .current, appType: .webApp)
        let livenessDetector = LarkBytedCert()
        let arg: [String: Any] = [String.BizParam.ticket: ticket,
                                  String.BizParam.mode: args[String.BizParam.mode] as? Int ?? -1,
                                  String.BizParam.aid: args[String.BizParam.aid] as? Int ?? 0,
                                  String.BizParam.scene: args[String.BizParam.scene] as? String ?? ""]
        livenessDetector.checkFaceLivenessMessage(params: arg, shouldPresent: nil) { (result, error) in
            if let res = result, let code = res[String.BizParam.statusCode] as? Int, code == 0 {
                StartBiometrics.logger.info("Do face liveness success, appId=\(appId) ticket=\(ticket)")
                if let successCallback = args["onSuccess"] as? String {
                    api.call(funcName: successCallback, arguments: [["code": 0,
                                                                     "message": "ok",
                                                                     "data": ["reqNo": ticket]]])
                }
                OPMonitor(APIMonitorCodeFaceLiveness.face_live_success).setResultTypeSuccess().setUniqueID(uniqueID).addMap(["ticket": ticket]).flush()
                return
            }
            StartBiometrics.logger.warn("Do face liveness fail, appId=\(appId) ticket=\(ticket) error=\(String(describing: error))")
            let errorCode = error?[String.ErrorInfo.code] as? Int ?? -1
            let errorMsg = error?[String.ErrorInfo.msg] as? String ?? ""
            StartBiometrics.handleError(errorInfo: (code: errorCode, msg: errorMsg), callback: callback)
            var mcode = APIMonitorCodeFaceLiveness.face_live_internal_error
            switch errorCode {
            case -1003:
                mcode = APIMonitorCodeFaceLiveness.face_live_user_cancel_after_error
            case -1006:
                mcode = APIMonitorCodeFaceLiveness.face_live_user_cancel
            case -3000, -3002, -3003:
                mcode = APIMonitorCodeFaceLiveness.face_live_device_interrupt
            default:
                break
            }
            OPMonitor(mcode)
                .setResultTypeFail()
                .setUniqueID(uniqueID)
                .addMap(["ticket": ticket])
                .setErrorCode("\(errorCode)")
                .setErrorMessage(errorMsg).flush()
        }
    }
}
