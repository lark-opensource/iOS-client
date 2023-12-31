//
//  FetchMobileOverlaySubtilteRequst.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/2/4.
//

import Foundation

struct FetchMobileOverlaySubtilteRequst: Request {
    typealias ResponseType = Response<OverlaySubtitleResponse>

    let endpoint: String = "/minutes/api/subtitles/mobile-sub"
    let requestID: String = UUID().uuidString
    let objectToken: String
    let language: String

    var parameters: [String: Any] {
        var params: [String: Any] = [:]
        params["object_token"] = objectToken
        params["translate_lang"] = language
        return params
    }
}
