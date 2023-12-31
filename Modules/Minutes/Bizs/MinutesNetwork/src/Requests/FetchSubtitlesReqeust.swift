//
//  FetchSubtitlesReqeust.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/1/12.
//

import Foundation

struct FetchSubtitlesReqeust: Request {
    typealias ResponseType = Response<Subtitles>

    let endpoint: String = MinutesAPIPath.subtitles
    let requestID: String = UUID().uuidString
    let objectToken: String
    let paragraphID: String?
    let size: Int?
    let fetchOrder: FetchOrder?
    let translateLang: String
    var catchError: Bool
    let forward: Int
    let filterSpeaker: Bool

    var parameters: [String: Any] {
        var params: [String: Any] = [:]
        params["object_token"] = objectToken
        params["paragraph_id"] = paragraphID
        params["size"] = size
        params["forward"] = fetchOrder?.rawValue
        params["translate_lang"] = translateLang
        params["forward"] = forward
        params["filter_speaker"] = filterSpeaker
        return params
    }
}
