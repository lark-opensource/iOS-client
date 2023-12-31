//
//  SpeakerUpdateRequest.swift
//  MinutesFoundation
//
//  Created by chenlehui on 2021/6/20.
//

import Foundation

struct SpeakerUpdateRequest: Request {

    typealias ResponseType = Response<SpeakerUpdate>

    let endpoint: String = "/minutes/api/subtitles/speaker/update"
    let requestID: String = UUID().uuidString
    let method: RequestMethod = .post
    let objectToken: String
    let paragraphId: String
    let usetType: Int
    let userId: String
    let userName: String
    let editSession: String
    let batch: Bool
    var catchError: Bool

    var parameters: [String: Any] {
        let para: [String: Any] = ["object_token": objectToken,
                                    "paragraph_id": paragraphId,
                                    "user_type": usetType,
                                    "user_id": userId,
                                    "user_name": userName,
                                    "edit_session": editSession,
                                    "batch": batch]
        return para
    }
}
