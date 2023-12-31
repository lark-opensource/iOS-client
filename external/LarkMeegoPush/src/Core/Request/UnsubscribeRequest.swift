//
//  UnsubscribeRequest.swift
//  LarkMeegoPush
//
//  Created by ByteDance on 2022/7/21.
//

import Foundation
import LarkMeegoNetClient

struct UnsubscribeRequest: Request {
    typealias ResponseType = Response<EmptyDataResponse>

    let method: RequestMethod = .post
    let endpoint: String = "/bff/v1/notification/unsubscribe"
    var catchError: Bool

    let ssbIds: [Int]
    let deviceIdentification: String

    var parameters: [String: Any] {
        var params: [String: Any] = [:]
        params["ssb_ids"] = ssbIds
        params["device_identification"] = deviceIdentification
        return params
    }
}
