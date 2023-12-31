//
//  SubscribeRequest.swift
//  LarkMeegoPush
//
//  Created by ByteDance on 2022/7/20.
//

import Foundation
import LarkMeegoNetClient

struct SubscribeRequest: Request {
    typealias ResponseType = Response<SubscribeResponse>

    let method: RequestMethod = .post
    let endpoint: String = "/bff/v1/notification/subscribe"
    var catchError: Bool

    let topics: [[String: Any]]
    let deviceIdentification: String

    var parameters: [String: Any] {
        var params: [String: Any] = [:]
        params["topics"] = topics
        params["device_identification"] = deviceIdentification
        return params
    }
}
