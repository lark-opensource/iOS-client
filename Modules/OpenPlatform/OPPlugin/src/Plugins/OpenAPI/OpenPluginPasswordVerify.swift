//
//  OpenPluginPasswordVerify.swift
//  OPPlugin
//
//  Created by yi on 2021/3/23.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPPluginManagerAdapter
import ECOProbe
import OPPluginBiz
import OPFoundation
import LarkContainer

final class OpenPluginPasswordVerify: OpenBasePlugin {
    static let kErrCodeStartPasswordVerify = 40100

    func startPasswordVerify(context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenPluginStartPasswordVerifyResponse>) -> Void) {
        guard let delegate = EMAProtocolProvider.getEMADelegate() else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                .setMonitorMessage("passport delegate is nil")
            callback(.failure(error: error))
            return
        }
        let uniqueID = gadgetContext.uniqueID
        delegate.passwordVerify(for: uniqueID) { (dict) in
            let errCode = dict?["errCode"] as? Int ?? 0
            let errMsg = dict?["errMsg"] as? String ?? ""
            let token = dict?["token"] as? String ?? ""
            if errCode == 0 {
                callback(.success(data: OpenPluginStartPasswordVerifyResponse(token: token)))
            } else {
                let passwordErrorCode = OpenPluginPasswordVerify.passwordErrorCode(errCode: errCode)
                context.apiTrace.warn("start password verify fail, uniqueID=\(uniqueID), errorCode=\(errCode), errorMsg=\(errMsg)")
                var errorCode: OpenAPIErrorCodeProtocol = OpenAPICommonErrorCode.unknown
                var errno: OpenAPIErrnoProtocol = OpenAPICommonErrno.unknown
                if let response = OpenStartPasswordVerifyResponseCode(rawValue: passwordErrorCode) {
                    switch response {
                    case .userCancel:
                        errorCode = OpenStartPasswordVerifyErrorCode.userCancel
                        errno = OpenAPIPasswordErrno.startpasswordverifyUserCancel
                    case .passwordError:
                        errorCode = OpenStartPasswordVerifyErrorCode.passwordError
                        errno = OpenAPIPasswordErrno.startpasswordverifyPasswordError
                    case .retryTimeLimit:
                        errorCode = OpenStartPasswordVerifyErrorCode.retryTimeLimit
                        errno = OpenAPIPasswordErrno.startpasswordverifyRetryTimeLimit
                    }
                }
                let error = OpenAPIError(code: errorCode)
                    .setErrno(errno)
                    .setOuterCode(passwordErrorCode)
                    .setOuterMessage(errMsg)
                    .setMonitorMessage("start password verify fail, uniqueID=\(uniqueID), errorCode=\(errCode), errorMsg=\(errMsg)")
                callback(.failure(error: error))
            }
        }
    }

    class func passwordErrorCode(errCode: Int) -> Int {
        return OpenPluginPasswordVerify.kErrCodeStartPasswordVerify + errCode
    }

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandlerGadget(for: "startPasswordVerify", pluginType: Self.self, resultType: OpenPluginStartPasswordVerifyResponse.self) { (this, _, context, gadgetContext, callback) in
            this.startPasswordVerify(context: context, gadgetContext: gadgetContext, callback: callback)
        }
    }
}
