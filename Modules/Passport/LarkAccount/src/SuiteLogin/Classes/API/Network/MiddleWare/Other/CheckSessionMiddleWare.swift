//
//  CheckSessionMiddleWare.swift
//  LarkAccount
//
//  Created by bytedance on 2021/9/23.
//

import Foundation
import LarkContainer

class CheckSessionMiddleWare: HTTPMiddlewareProtocol {

    @Provider private var userSessionService: UserSessionService

    func config() -> HTTPMiddlewareConfig {
        [
            .response: .highest
        ]
    }

    func handle<ResponseData: ResponseV3>(
        request: PassportRequest<ResponseData>,
        complete: @escaping () -> Void) {

        guard let httpResponse = request.task?.response as? HTTPURLResponse,
              httpResponse.statusCode == CommonConst.checkSessionHTTPCode
              else {
            complete()
            return
        }
        CheckSessionPushHandler.logger.info("check session via http middleware")
        userSessionService.start(reason: .http)
        complete()
    }
}

