//
//  UpdateSummaryCheckboxRequest.swift
//  MinutesFoundation
//
//  Created by Todd Cheng on 2021/5/13.
//

import Foundation

struct UpdateSummaryCheckboxRequest: Request {
    typealias ResponseType = BasicResponse

    let endpoint: String = "/minutes/api/summaries/checkbox"
    let requestID: String = UUID().uuidString
    let method: RequestMethod = .post
    let objectToken: String
    let contentId: String
    let checked: Bool

    var parameters: [String: Any] {
        var params: [String: Any] = [:]
        params["object_token"] = objectToken
        params["content_id"] = contentId
        params["checked"] = checked

        return params
    }
}
