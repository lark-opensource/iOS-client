//
//  FetchPodcastBacgroundRequest.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/4/7.
//

import Foundation

struct FetchPodcastBackgroundRequest: Request {
    typealias ResponseType = Response<PodcastBacground>

    let endpoint: String = "/minutes/api/podcast-bgs"
    let requestID: String = UUID().uuidString

    var parameters: [String: Any] {
        var params: [String: Any] = [:]
        return params
    }
}
