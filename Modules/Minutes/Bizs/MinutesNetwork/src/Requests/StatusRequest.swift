//
//  StatusRequest.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/1/12.
//

import Foundation

struct StatusRequest: Request {
    typealias ResponseType = Response<StatusInfo>

    let endpoint: String = MinutesAPIPath.status
    let requestID: String = UUID().uuidString
    let objectToken: String
    var catchError: Bool

    var parameters: [String: Any] {
        var params: [String: Any] = [:]
        params["object_token"] = objectToken
        return params
    }
}
