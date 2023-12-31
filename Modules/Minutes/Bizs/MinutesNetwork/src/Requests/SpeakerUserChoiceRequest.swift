//
//  SpeakerUserChoiceRequest.swift
//  MinutesFoundation
//
//  Created by chenlehui on 2022/2/24.
//

import Foundation

struct SpeakerUserChoiceRequest: Request {

    typealias ResponseType = Response<SpeakerUserChoice>

    let endpoint: String = "/minutes/api/user/choice"
    let requestID: String = UUID().uuidString
    let method: RequestMethod = .get
    let userType: Int

    var parameters: [String: Any] {
        var params: [String: Any] = [:]
        params["user_type"] = userType
        return params
    }
}
