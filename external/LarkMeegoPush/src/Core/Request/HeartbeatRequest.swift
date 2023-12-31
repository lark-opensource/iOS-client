//
//  HeartbeatRequest.swift
//  LarkMeegoPush
//
//  Created by ByteDance on 2022/7/20.
//

import Foundation
import LarkMeegoNetClient

struct HeartbeatRequest: Request {
    typealias ResponseType = Response<HeartbeatResponse>

    let method: RequestMethod = .put
    let endpoint: String = "/bff/v1/notification/device/heartbeat"
    let catchError: Bool

    let deviceIdentification: String

    var parameters: [String: Any] {
        var params: [String: Any] = [:]
        params["device_identification"] = deviceIdentification
        return params
    }
}
