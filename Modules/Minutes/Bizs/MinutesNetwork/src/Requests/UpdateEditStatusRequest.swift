//
//  UpdateEditStatusRequest.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/6/24.
//

import Foundation

enum UpdateEditStatusRequestAction: Int {
    case entry = 1
    case exit = 0
}

struct UpdateEditStatusRequest: Request {
    typealias ResponseType = Response<EditStatus>

    let endpoint: String = "/minutes/api/subtitles/edit/entry"
    let requestID: String = UUID().uuidString
    let method: RequestMethod = .post
    let objectToken: String
    let action: UpdateEditStatusRequestAction
    let version: Int
    let session: String

    var parameters: [String: Any] {
        var params: [String: Any] = [:]
        params["object_token"] = objectToken
        params["edit_status"] = action.rawValue
        params["now_version"] = version
        params["edit_session"] = session
        return params
    }
}
