//
//  FetchMergedTimelineRequest.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/3/3.
//

import Foundation

struct FetchMergedTimelineRequest: Request {
    typealias ResponseType = Response<MergedReactionInfoResponse>

    let endpoint: String = MinutesAPIPath.timelineMerge
    let requestID: String = UUID().uuidString
    let objectToken: String
    let language: String?
    let type: Int = 3
    let startTime: Int
    let stopTime: Int
    var catchError: Bool

    var parameters: [String: Any] {
        var params: [String: Any] = [:]
        params["object_token"] = objectToken
        params["language"] = language
        params["type"] = type
        params["start_time"] = startTime
        params["stop_time"] = stopTime
        return params
    }
}
