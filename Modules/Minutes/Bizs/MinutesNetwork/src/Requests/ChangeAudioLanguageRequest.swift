//
//  ChangeAudioLanguageRequest.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/3/18.
//

import Foundation

struct ChangeAudioLanguageRequest: Request {
    typealias ResponseType = BasicResponse

    let endpoint: String = MinutesAPIPath.audioLanguage
    let requestID: String = UUID().uuidString
    let method: RequestMethod = .post
    let objectToken: String
    let translateLanguage: String?
    let recordingLanguage: String?
    var catchError: Bool

    var parameters: [String: Any] {
        var params: [String: Any] = [:]
        params["object_token"] = objectToken
        params["recording_lang"] = recordingLanguage
        params["translate_lang"] = translateLanguage
        return params
    }
}
