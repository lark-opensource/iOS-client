//
//  KeepEditStatusRequest.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/6/24.
//

import Foundation

struct KeepEditStatusRequest: Request {
    typealias ResponseType = Response<KeepEditStatus>

    let endpoint: String = "/minutes/api/subtitles/edit/keep"
    let requestID: String = UUID().uuidString
    let method: RequestMethod = .post
    let objectToken: String
    let session: String

    var parameters: [String: Any] {
        var params: [String: Any] = [:]
        params["object_token"] = objectToken
        params["edit_session"] = session
        return params
    }
}
