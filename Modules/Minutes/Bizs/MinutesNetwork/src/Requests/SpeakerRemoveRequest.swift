//
//  SpeakerRemoveRequest.swift
//  MinutesFoundation
//
//  Created by panzaofeng on 2021/12/6.
//

import Foundation

struct SpeakerRemoveRequest: Request {

    typealias ResponseType = Response<SpeakerUpdate>

    let endpoint: String = "/minutes/api/subtitles/speaker/remove"
    let requestID: String = UUID().uuidString
    let method: RequestMethod = .post
    let objectToken: String
    let paragraphId: String
    let usetType: Int
    let userId: String
    let batch: Bool

    let catchError: Bool

    var parameters: [String: Any] {
        let para: [String: Any] = ["object_token": objectToken,
                                    "paragraph_id": paragraphId,
                                    "user_type": usetType,
                                    "user_id": userId,
                                    "batch": batch]
        return para
    }
}
