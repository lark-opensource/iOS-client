//
//  InjectParamsMiddleWare.swift
//  SuiteLogin
//
//  Created by quyiming on 2020/4/25.
//

import Foundation

class InjectParamsMiddleWare: HTTPMiddlewareProtocol {

    let helper: V3APIHelper

    init(helper: V3APIHelper) {
        self.helper = helper
    }

    func config() -> HTTPMiddlewareConfig {
        [
            .request: .medium
        ]
     }

    func handle<ResponseData: ResponseV3>(request: PassportRequest<ResponseData>, complete: @escaping () -> Void) {
        let extraParams = helper.appendInjectParamsFor(request.context.extraParams)
        request.context.extraParams = extraParams
        complete()
    }

}
