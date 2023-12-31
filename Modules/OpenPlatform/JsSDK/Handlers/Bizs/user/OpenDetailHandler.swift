//
//  OpenDetailHandler.swift
//  LarkWeb
//
//  Created by 武嘉晟 on 2019/9/11.
//

import Alamofire
import EEMicroAppSDK
import EENavigator
import LarkRustHTTP
import LKCommonsLogging
import Swinject
import LarkAccountInterface
import WebBrowser
import LarkMessengerInterface
import LarkContainer

class OpenDetailHandler: JsAPIHandler, UserResolverWrapper {

    static let log = Logger.log(OpenDetailHandler.self, category: "Module.JSSDK")

    /// RSA 加密公钥
    private let publicKey = """
-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDTb2DxxIj17sf2H/hr6ZSNxsaa
FjgCMHZOSZsvAaZpl+9hHd76ex1nVCpZXbjIsYHfJzYLVDlRZYXcHA3yOhneyJbC
kO4e05t+5j/lXWQY09gkp9w3pGIWOCzfr8zY/5CA3ThIbNBKFQZTnX8nQIhaTf+u
nJDe6Nkq3Tau6cz75QIDAQAB
-----END PUBLIC KEY-----
"""
    @ScopedProvider private var userService: PassportUserService?
    
    let userResolver: UserResolver

    private let apiBizCode: UInt = 38

    var needAuthrized: Bool {
        return true
    }

    init(resolver: UserResolver) {
        userResolver = resolver
    }

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {

        guard let openId = args["openId"] as? String,
            !openId.isEmpty else {
                callback.callbackFailure(param: NewJsSDKErrorAPI.invalidParameter(extraMsg: "openId").description())
                OpenDetailHandler.log.error("openId为空")
                return
        }
        
        guard let userService else {
            Self.log.error("resolve PassportUserService failed")
            callback.callbackFailure(param: NewJsSDKErrorAPI.resolveServiceError.description())
            return
        }

        /// 请求头
        let larkSession = userService.user.sessionKey ?? ""
        var headers = HTTPHeaders()
        headers["Cookie"] = "session=\(larkSession)"
        headers["Content-Type"] = "application/json"

        let jsonParam = [
            "openID": openId
        ]

        guard JSONSerialization.isValidJSONObject(jsonParam),
            let jsonData = try? JSONSerialization.data(withJSONObject: jsonParam),
            let encryptJsonData = try? NSData.web_encryptData(jsonData, publicKey: publicKey) as NSData,
            let encryptedParam = encryptJsonData.web_base64EncodedString() else {
                callback.callbackFailure(param: NewJsSDKErrorAPI.OpenDetail.openDetailInnerError.description())
                OpenDetailHandler.log.error("加密失败")
                return
        }

        /// 获取 ttcode 日后迁移到开放平台 pod
        let cipher = EMANetworkCipher()
        let ttcode = cipher.encryptKey

        /// 获取 jssdkSession
        let jssdkSession = sdk.authSession ?? ""

        /// 请求体
        let param = [
            "session": jssdkSession,
            "ttcode": ttcode,
            "encryptedParam": encryptedParam
        ]

        sdk.sessionManager
            .request(OpenPlatformNetworkAPI(resolver: resolver).openDetailURL, method: .post, parameters: param, encoding: JSONEncoding.default, headers: headers)
            .responseJSON { [weak self] (response) in
                switch response.result {
                case .success(let value):
                    guard let result = value as? [String: Any],
                        let encryptedData = result["encryptedData"] as? String,
                        let code = result["error"] as? Int else {
                            /// 内部错误 参数解析失败
                        callback.callbackFailure(param: NewJsSDKErrorAPI.OpenDetail.openDetailInnerError.description())
                            return
                    }
                    let message = result["message"] as? String ?? ""
                    /// 不为0代表后端返回错误值
                    if code != 0 {
                        /// 其他错误码
                        callback.callbackFailure(param: NewJsSDKErrorAPI.customApiError(api: NewJsSDKErrorAPI.OpenDetail.self, innerCode: 3, backendCode: code, backendMsg: message).description())
                        return
                    }
                    guard let userIDDic = EMANetworkCipher.decryptDict(forEncryptedContent: encryptedData, cipher: cipher) as? [String: Any],
                        let userID = userIDDic["userID"] as? String else {
                        callback.callbackFailure(param: NewJsSDKErrorAPI.OpenDetail.openDetailDecryptError.description())
                            OpenDetailHandler.log.error("解密失败")
                            return
                    }

                    let body = PersonCardBody(chatterId: userID)
                    self?.userResolver.navigator.push(body: body, from: api) { (_, res) in
                        if res.error == nil {
                            callback.callbackSuccess(param: ["code": 0])
                        } else {
                            callback.callbackFailure(param: NewJsSDKErrorAPI.OpenDetail.openDetailInnerError.description())
                            OpenDetailHandler.log.error("userID有误，跳转失败")
                        }
                    }
                case .failure(let value):
                    /// 网络请求失败
                    callback.callbackFailure(param: NewJsSDKErrorAPI.networkError.description())
                    OpenDetailHandler.log.error("网络请求失败 错误信息\(value.localizedDescription)")
                }
            }
    }
}
