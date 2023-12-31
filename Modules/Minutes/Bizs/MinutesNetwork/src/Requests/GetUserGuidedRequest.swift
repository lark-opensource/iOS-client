//
//  GetUserGuidedRequest.swift
//  MinutesFoundation
//
//  Created by panzaofeng on 2022/1/4.
//

import Foundation

public struct GetUserGuidedResponse: Codable {
    public let guided: Bool
    private enum CodingKeys: String, CodingKey {
        case guided = "guided"
    }
}

struct GetUserGuidedRequest: Request {
    typealias ResponseType = Response<GetUserGuidedResponse>

    let endpoint: String = "/minutes/api/user/guided"
    let requestID: String = UUID().uuidString
    let method: RequestMethod = .get
    let guideType: String
    var catchError: Bool

    var parameters: [String: Any] {
        var params: [String: Any] = [:]
        params["guide_type"] = guideType
        return params
    }
}
