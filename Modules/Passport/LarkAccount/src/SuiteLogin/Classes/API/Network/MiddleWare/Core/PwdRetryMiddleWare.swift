//
//  PwdRetryMiddleWare.swift
//  SuiteLogin
//
//  Created by quyiming on 2020/5/12.
//

import Foundation

class PwdRetryMiddleWare: HTTPMiddlewareProtocol {

    private(set) static var useRSAEncrypt: Bool = true

    func config() -> [HTTPMiddlewareAspect: HTTPMiddlewarePriority] {
        [
            .error: .low
        ]
    }

    func handle<ResponseData: ResponseV3>(
        request: PassportRequest<ResponseData>,
        complete: @escaping () -> Void
    ) {
        guard case V3LoginError.badServerCode(let errorInfo)? = request.context.error,
            case .rsaDecryptError = errorInfo.type else {
            complete()
            return
        }
        // if server fails to decrypt pwd, retry without encrypted
        Self.disableRSAEncrypt()
        request.context.needRetry = true
        complete()
    }

    static func disableRSAEncrypt() {
        Self.useRSAEncrypt = false
    }

}
