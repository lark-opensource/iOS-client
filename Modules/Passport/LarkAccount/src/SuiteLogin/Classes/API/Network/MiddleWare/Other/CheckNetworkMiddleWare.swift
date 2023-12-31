//
//  CheckNetworkMiddleWare.swift
//  SuiteLogin
//
//  Created by quyiming on 2020/4/22.
//

import Foundation

class CheckNetworkMiddleWare: HTTPMiddlewareProtocol {
    func config() -> HTTPMiddlewareConfig {
        [
            .request: .highest
        ]
    }

    func handle<ResponseData: ResponseV3>(
        request: PassportRequest<ResponseData>,
        complete: @escaping () -> Void) {
        if !SuiteLoginUtil.isNetworkEnable() {
            request.context.error = V3LoginError.networkNotReachable(true)
        }
        complete()
    }
}
