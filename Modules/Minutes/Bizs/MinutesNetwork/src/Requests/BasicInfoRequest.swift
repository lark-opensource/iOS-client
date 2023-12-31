//
//  BasicInfoRequest.swift
//  LarkMinutesAPI
//
//  Created by lvdaqian on 2021/1/11.
//

import Foundation

struct BasicInfoRequest: Request {
    typealias ResponseType = Response<BasicInfo>

    let endpoint: String = MinutesAPIPath.simpleBaseInfo
    let requestID: String = UUID().uuidString
    let objectToken: String
    var catchError: Bool

    var parameters: [String: Any] {
        var params: [String: Any] = [:]
        params["object_token"] = objectToken
        return params
    }
}
