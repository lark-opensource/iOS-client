//
//  FetchPermissionApplyInfoRequest.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/1/12.
//

import Foundation

struct FetchPermissionApplyInfoRequest: Request {
    typealias ResponseType = Response<PermissionApplyInfo>

    let endpoint: String = "/minutes/api/permission/apply/info"
    let requestID: String = UUID().uuidString
    let objectToken: String

    var parameters: [String: Any] {
        var params: [String: Any] = [:]
        params["object_token"] = objectToken
        return params
    }
}
