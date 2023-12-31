//
//  UpdateHeaderMiddleWare.swift
//  SuiteLogin
//
//  Created by quyiming on 2020/4/22.
//

import Foundation

class UpdateHeaderMiddleWare: HTTPMiddlewareProtocol {

    let helper: V3APIHelper

    init(helper: V3APIHelper) {
        self.helper = helper
    }

    func config() -> HTTPMiddlewareConfig {
        [
            .response: .medium
        ]
    }

    func handle<ResponseData: ResponseV3>(
        request: PassportRequest<ResponseData>,
        complete: @escaping () -> Void
    ) {
        guard let header = request.response.header else {
            complete()
            return
        }
        if let passportToken = header.passportToken {
            helper.tokenManager.passportToken = passportToken
            HTTPClient.logger.info("save passportToken len: \(passportToken.count)")
        }
        if let pwdToken = header.pwdToken {
            helper.tokenManager.pwdToken = pwdToken
            HTTPClient.logger.info("save pwdToken len: \(pwdToken.count)")
        }
        if let sessionKey = header.suiteSessionKey {
            // TODO: suite session key 不再从 header 获取
//            helper.suiteSessionKey = sessionKey
            HTTPClient.logger.info("save suiteSessionKey len: \(sessionKey.count)")
        }
        if let verifyToken = header.verifyToken {
            helper.tokenManager.verifyToken = verifyToken
            HTTPClient.logger.info("save verifyToken len: \(verifyToken.count)")
        }
        if let flowKey = header.flowKey {
            if flowKey.isEmpty {
                HTTPClient.logger.warn("flow key is empty", method: .local)
            } else {
                helper.tokenManager.flowKey = flowKey
                HTTPClient.logger.info("save flowKey: \(flowKey.desensitized())")
            }
        }
        if let proxyUnit = header.proxyUnit {
            helper.tokenManager.proxyUnit = proxyUnit
            HTTPClient.logger.info("save proxyUnit: \(proxyUnit)")
        }
        if let authFlowKey = header.authFlowKey {
            helper.tokenManager.authFlowKey = authFlowKey
            HTTPClient.logger.info("save auth flow key: \(authFlowKey)")
        }

        complete()
    }
}
