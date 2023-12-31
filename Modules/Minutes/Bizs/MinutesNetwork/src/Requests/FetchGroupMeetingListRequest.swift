//
//  FetchGroupMeetingListRequest.swift
//  MinutesFoundation
//
//  Created by yangyao on 2023/5/15.
//

import Foundation

struct FetchGroupMeetingListRequest: Request {
    typealias ResponseType = Response<GroupMeetingListResponse>

    let endpoint: String = "/minutes/api/group_url"
    let requestID: String = UUID().uuidString
    let method: RequestMethod = .get
    let objectToken: String

    var parameters: [String: Any] {
        var params: [String: Any] = [:]
        params["object_token"] = objectToken
        params["main_object_token"] = objectToken

        return params
    }
}
