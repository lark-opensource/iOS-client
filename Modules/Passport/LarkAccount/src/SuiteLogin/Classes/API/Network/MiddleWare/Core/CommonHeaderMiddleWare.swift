//
//  CommonHeaderMiddleWare.swift
//  SuiteLogin
//
//  Created by quyiming on 2020/4/22.
//

import Foundation
import LKCommonsLogging

class CommonHeaderMiddleWare: HTTPMiddlewareProtocol {

    static let logger = Logger.plog(CommonHeaderMiddleWare.self, category: "SuiteLogin.CommonHeaderMiddleWare")
    let helper: V3APIHelper

    init(helper: V3APIHelper) {
        self.helper = helper
    }

    func config() -> HTTPMiddlewareConfig {
        [
            .request: .medium
        ]
    }

    func handle<ResponseData: ResponseV3>(
        request: PassportRequest<ResponseData>,
        complete: @escaping () -> Void
    ) {
        var passportToken: String?
        var pwdToken: String?
        var suiteSessionKey: String?
        var verifyToken: String?
        var flowKey: String?
        var proxyUnit: String?
        var sessionKeys: [String]?
        var authFlowKey: String?
        request.requiredHeader.forEach { header in
            switch header {
            case .passportToken:
                passportToken = helper.tokenManager.passportToken
            case .pwdToken:
                pwdToken = helper.tokenManager.pwdToken
            case .suiteSessionKey:
                suiteSessionKey = helper.suiteSessionKey
            case .verifyToken:
                verifyToken = helper.tokenManager.verifyToken
            case .flowKey:
                flowKey = helper.tokenManager.flowKey
            case .proxyUnit:
                proxyUnit = helper.tokenManager.proxyUnit
            case .authFlowKey:
                authFlowKey = helper.tokenManager.authFlowKey
            case .sessionKeys:
                sessionKeys = PassportStore.shared.getUserList().map { $0.suiteSessionKey ?? "" }
            }
        }
        let headers = helper.getHeader(
            passportToken: passportToken,
            pwdToken: pwdToken,
            suiteSessionKey: suiteSessionKey,
            verifyToken: verifyToken,
            flowKey: flowKey,
            proxyUnit: proxyUnit,
            authFlowKey: authFlowKey,
            sessionKeys: sessionKeys
        )

        request.context.extraHeaders.merge(headers) { (_, new) -> String in
            let msg = "header key conflict old header not used"
            Self.logger.error(msg)
            assertionFailure(msg)
            return new
        }
        complete()
    }
}
