//
//  FetchWebVTTReqeust.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/2/4.
//

import Foundation

struct FetchWebVTTReqeust: Request {
    typealias ResponseType = String

    let endpoint: String = "/minutes/api/subtitles/webvtt"
    let requestID: String = UUID().uuidString
    let objectToken: String
    let translateLang: String

    var parameters: [String: Any] {
        var params: [String: Any] = [:]
        params["object_token"] = objectToken
        params["translate_lang"] = translateLang
        return params
    }
}
