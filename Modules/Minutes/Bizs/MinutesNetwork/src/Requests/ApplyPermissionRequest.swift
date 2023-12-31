//
//  ApplyPermissionRequest.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/1/12.
//

import Foundation
struct ApplyPermissionRequest: Request {
    typealias ResponseType = BasicResponse

    let endpoint: String = "/minutes/api/permission/apply/action"
    let requestID: String = UUID().uuidString
    let method: RequestMethod = .post
    let objectToken: String
    let remark: String
    var catchError: Bool

    var parameters: [String: Any] {
        var params: [String: Any] = [:]
        params["object_token"] = objectToken
        params["remark"] = remark
        return params
    }
}
