//
//  SetAuthenticationInfo.swift
//  LarkWeb
//
//  Created by yuanping on 2019/5/13.
//

import Swinject
import Alamofire
import LarkRustHTTP
import LKCommonsLogging
import SwiftyJSON
import LarkAccountInterface
import RustPB
import LarkSetting
import WebBrowser
import EEMicroAppSDK
import LarkContainer

class SetAuthenticationInfo: JsAPIHandler, UserResolverWrapper {
    static let logger = Logger.log(SetAuthenticationInfo.self, category: "Module.JSSDK")
    private lazy var str = DomainSettingManager.shared.currentSetting[.open]?.first ?? ""
    private lazy var url = "https://\(str)/open-apis/id_verify/v1/upload_auth_info"
    
    @ScopedProvider private var userService: PassportUserService?
    
    let userResolver: UserResolver
    
    init(resolver: UserResolver) {
        userResolver = resolver
    }

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        guard let userService else {
            Self.logger.error("resolve PassportUserService failed")
            callback.callbackFailure(param: NewJsSDKErrorAPI.resolveServiceError.description())
            return
        }
        
        let appId = args["appId"] as? String ?? ""
        var params = args
        params.removeValue(forKey: "onSuccess")
        params.removeValue(forKey: "onFailed")
        let session = userService.user.sessionKey ?? ""
        var headers = HTTPHeaders()
        headers["Cookie"] = "session=\(session)"
        headers["Content-Type"] = "application/json"
        sdk.sessionManager
            .request(
                URL(string: url)!,
                method: .post,
                parameters: params,
                encoding: JSONEncoding.default,
                headers: headers
        )
            .responseJSON(completionHandler: { (response) in
                switch response.result {
                case .success(let value):
                    var result = value as? [String: Any] ?? [:]
                    let code = result["code"] as? Int
                    let msg = result["msg"] as? String
                    if code == 0 {
                        OPMonitor(APIMonitorCodeFaceLiveness.upload_info_success).setAppID(appId).setAppType(.webApp).setResultTypeSuccess().flush()
                            result.removeValue(forKey: "msg")
                            result["message"] = "ok"
                        callback.callbackSuccess(param: result)

                        // 为了更好的表达 code 和 msg 的本意，这里直接使用 Optional 进行打印
                        SetAuthenticationInfo.logger.info("SetAuthenticationInfo request biz success. code=\(code), msg=\(msg)")
                    } else {
                        SetAuthenticationInfo.handleError(callback: callback, code: code ?? -1, message: msg ?? "")
                        // 为了更好的表达 code 和 msg 的本意，这里直接使用 Optional 进行打印
                        SetAuthenticationInfo.logger.error("SetAuthenticationInfo request biz error. code=\(code), msg=\(msg)")
                        SetAuthenticationInfo.monitorErrorCode(code ?? -1, message: msg ?? "", appId: appId)
                    }
                case .failure(let error):
                    SetAuthenticationInfo.handleError(callback: callback)
                    SetAuthenticationInfo.logger.error("SetAuthenticationInfo request network failed. error=\(error)")
                    OPMonitor(APIMonitorCodeFaceLiveness.upload_info_other_error).setResultTypeFail().setAppID(appId).setAppType(.webApp).setError(error).flush()
                @unknown default:
                    fatalError("Unknown type of network response")
                }
            })
    }

    static private func handleError(callback: WorkaroundAPICallBack, code: Int = -1, message: String = "something error") {
        callback.callbackFailure(param: ["errorCode": code,
                                         "errorMessage": message])
    }

    static private func monitorErrorCode(_ code: Int, message: String, appId: String) {
        var mcode = APIMonitorCodeFaceLiveness.upload_info_other_error
        switch code {
        case 10_001:
            mcode = APIMonitorCodeFaceLiveness.upload_info_fail
        case 10_002:
            mcode = APIMonitorCodeFaceLiveness.update_info_name_mismatch
        case 10_003:
            mcode = APIMonitorCodeFaceLiveness.update_info_code_mismatch
        case 10_004:
            mcode = APIMonitorCodeFaceLiveness.update_info_mobile_mismatch
        case 10_100:
            mcode = APIMonitorCodeFaceLiveness.upload_info_param_error
        default:
            break
        }
        OPMonitor(mcode).setResultTypeFail().setAppID(appId).setAppType(.webApp).setErrorCode("\(code)").setErrorMessage(message).flush()
    }
}
