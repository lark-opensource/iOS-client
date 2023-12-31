//
//  FetchPodcastSubtitleReqeust.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/4/7.
//

import Foundation

struct FetchPodcastSubtitleReqeust: Request {
    typealias ResponseType = Response<OverlaySubtitleResponse>

    let endpoint: String = "/minutes/api/subtitles/podcast"
    let requestID: String = UUID().uuidString
    let objectToken: String
    let language: String?
    let translateLang: String?

    var parameters: [String: Any] {
        var params: [String: Any] = [:]
        params["object_token"] = objectToken
        params["language"] = language
        params["translate_lang"] = translateLang
        return params
    }
}
