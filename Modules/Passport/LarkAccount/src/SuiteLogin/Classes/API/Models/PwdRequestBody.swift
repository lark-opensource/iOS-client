//
//  File.swift
//  SuiteLogin
//
//  Created by quyiming on 2020/5/12.
//

import Foundation
import LKCommonsLogging

class PwdRequestBody: RequestBody {

    static let logger = Logger.plog(PwdRequestBody.self, category: "SuiteLogin.PwdRequestBody")

    struct Const {
        static let pwd: String = "pwd"
        static let rsaToken: String = "rsa_token"
        static let sourceType: String = "source_type"
        static let contactType: String = "contact_type"
        static let flowType: String = "flow_type"
    }

    let pwd: String
    let rsaInfo: RSAInfo?
    let sourceType: Int?
    let contactType: Int?
    let flowType: String?
    private let logId: String

    // RSA每次加密，密文都不同，一次请求只计算一次
    private lazy var encryptPwd: String? = {
        if let info = rsaInfo {
            return SuiteLoginUtil.rsaEncrypt(plain: pwd, publicKey: info.publicKey)
        } else {
            return nil
        }
    }()

    init(
        pwd: String,
        rsaInfo: RSAInfo?,
        sourceType: Int?,
        logId: String,
        contactType: Int? = nil,
        flowType: String? = nil
    ) {
        self.pwd = pwd
        self.rsaInfo = rsaInfo
        self.sourceType = sourceType
        self.logId = logId
        self.contactType = contactType
        self.flowType = flowType
    }

    func getParams() -> [String: Any] {
        var params = passwordParams(password: pwd, rsaInfo: rsaInfo, logID: logId)
        if let contactType = self.contactType {
            params[Const.contactType] = contactType
        }
        if let flowType = self.flowType {
            params[Const.flowType] = flowType
        }
        if let sourceType = self.sourceType {
            params[Const.sourceType] = sourceType
        }
        return params
    }

    func passwordParams(password: String, rsaInfo: RSAInfo?, logID: String) -> [String: Any] {
        if PwdRetryMiddleWare.useRSAEncrypt,
            let rsaInfo = rsaInfo,
            let encrpytedPwd = encryptPwd {
            PwdRequestBody.logger.info("\(logID) transfer RSA encrypted pwd", method: .local)
            return [Const.pwd: encrpytedPwd, Const.rsaToken: rsaInfo.token]
        } else {
            PwdRequestBody.logger.info("\(logID) transfer bare pwd", method: .local)
            return [Const.pwd: password]
        }
    }

}

extension PassportRequest {
    func setPwdReqBody(_ body: PwdRequestBody) {
        self.body = body
        required(.pwdRetry)
    }
}
