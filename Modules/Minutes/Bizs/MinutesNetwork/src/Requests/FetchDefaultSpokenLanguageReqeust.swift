//
//  FetchDefaultSpokenLanguageReqeust.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/3/28.
//

import Foundation

struct FetchDefaultSpokenLanguageReqeust: Request {
    typealias ResponseType = Response<RecodingLanguageResponse>

    let endpoint: String = MinutesAPIPath.audioLanguage
    let requestID: String = UUID().uuidString

    var parameters: [String: Any] {
        return [:]
    }
    var catchError: Bool
}
