//
//  ParticipantsAddRequest.swift
//  MinutesFoundation
//
//  Created by panzaofeng on 2021/6/22
//

import Foundation

struct CreateAddReqeustPayload: Codable {

    public let userId: String
    public let userName: String
    public let userType: Int

    private enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case userType = "user_type"
        case userName = "user_name"
    }
}

struct ParticipantsAddRequest: Request {
    typealias ResponseType = BasicResponse

    let endpoint: String = "/minutes/api/multi-participants/add"
    let requestID: String = UUID().uuidString
    let method: RequestMethod = .post
    let objectToken: String
    let users: [Participant]
    let uuid: String
    var catchError: Bool

    var parameters: [String: Any] {
        var params: [String: Any] = [:]
        params["object_token"] = objectToken
        params["uuid"] = uuid
        let data = mapToPayload(users)
        if let payload = try? JSONEncoder().encode(data) {
            params["users"] = String(data: payload, encoding: .utf8)
        }
        return params
    }

    private func mapToPayload(_ users: [Participant]) -> [CreateAddReqeustPayload] {
        return users.map {
            return CreateAddReqeustPayload(userId: $0.userID,
                                           userName: $0.userName,
                                           userType: $0.userType.rawValue)
        }
    }
}
