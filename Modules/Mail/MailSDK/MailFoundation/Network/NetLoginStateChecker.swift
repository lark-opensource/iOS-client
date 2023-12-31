//
//  NetResponseChecker.swift
//  DocsSDK
//
//  Created by huahuahu on 2019/1/24.
//

import Foundation

/// 负责校验登陆态
struct MailNetLoginStateChecker {
    let requestContext: MailRequestContext
    var requestMasterKey: String?
    var identifier: String?

    init(context: MailRequestContext) {
        requestContext = context
        identifier = context.session.identifier
        requestMasterKey = currentRequestMasterKey(in: context.session)
    }

    func currentRequestMasterKey(in session: NetworkSession) -> String? {
        guard let cookies = session.cookies() else { return nil }
        if let bearSession = cookies.first(where: { $0.name == "bear-session" })?.value {
            return bearSession
        } else {
            return cookies.first(where: { $0.name == "session" })?.value
        }
    }

    func isUserSessionValid() -> Bool {
        if let requestMasterKey = self.requestMasterKey {
            guard requestMasterKey == self.currentRequestMasterKey(in: requestContext.session) else {
                return false
            }
        }
        return true
    }

    func isLoginRequired(_ error: Error?) -> Bool {
        guard let err = error as? MailNetworkError else {
            return false
        }
        return err.code == .loginRequired
    }

    func authorizationRequired() {
        requestContext.authorizationRequired(identifier)
    }
}
