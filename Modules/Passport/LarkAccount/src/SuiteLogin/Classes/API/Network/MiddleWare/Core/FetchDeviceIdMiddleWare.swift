//
//  FetchDeviceIdMiddleWare.swift
//  SuiteLogin
//
//  Created by quyiming on 2020/4/22.
//

import Foundation
import LarkContainer
import LarkAccountInterface

class FetchDeviceIdMiddleWare: HTTPMiddlewareProtocol {

    let helper: V3APIHelper

    @Provider var deviceService: InternalDeviceServiceProtocol

    init(helper: V3APIHelper) {
        self.helper = helper
    }

    func config() -> HTTPMiddlewareConfig {
        [
            .request: .high
        ]
    }

    func handle<ResponseData: ResponseV3>(
        request: PassportRequest<ResponseData>,
        complete: @escaping () -> Void
    ) {
        deviceService.fetchDeviceId({ (res) in
            switch res {
            case .success:
                complete()
            case .failure(let error):
                request.context.error = .fetchDeviceIDFail(error.localizedDescription)
                complete()
            }
        })
    }
}
