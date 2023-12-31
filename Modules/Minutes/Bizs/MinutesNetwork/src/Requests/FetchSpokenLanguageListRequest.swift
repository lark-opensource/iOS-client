//
//  FetchSpokenLanguageListRequest.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/3/26.
//

import Foundation

enum LanguageListType: Int, Codable {
    case spoken = 1
    case translate = 2
}

struct FetchSpokenLanguageListRequest: Request {
    typealias ResponseType = Response<[Language]>

    let endpoint: String = "/minutes/api/audio/language-list"
    let requestID: String = UUID().uuidString
    let objectToken: String
    let type: LanguageListType

    var parameters: [String: Any] {
        var params: [String: Any] = [:]
        params["object_token"] = objectToken
        params["type"] = type.rawValue
        return params
    }
}
