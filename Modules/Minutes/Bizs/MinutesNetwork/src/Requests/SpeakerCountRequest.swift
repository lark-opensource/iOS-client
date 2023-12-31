//
//  SpeakerCountRequest.swift
//  MinutesFoundation
//
//  Created by panzaofeng on 2022/4/22.
//

import Foundation

struct SpeakerCountRequest: Request {

    typealias ResponseType = Response<SpeakerCount>

    let endpoint: String = "/minutes/api/subtitles/speaker/count"
    let requestID: String = UUID().uuidString
    let method: RequestMethod = .get
    let objectToken: String
    let usetType: Int
    let userId: String
    let catchError: Bool

    var parameters: [String: Any] {
        let para: [String: Any] = ["object_token": objectToken,
                                    "user_type": usetType,
                                    "user_id": userId]
        return para
    }
}
