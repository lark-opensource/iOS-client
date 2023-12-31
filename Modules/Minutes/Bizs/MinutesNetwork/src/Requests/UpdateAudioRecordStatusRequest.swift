//
//  UpdateAudioRecordStatusRequest.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/3/18.
//

import Foundation

public enum AudioRecordStatus: Int {
    case paused = 1
    case resume = 2
    case recordComplete = 3
    case uploadComplete = 4
}

struct UpdateAudioRecordStatusRequest: Request {
    typealias ResponseType = BasicResponse

    let endpoint: String = MinutesAPIPath.audioStatus
    let requestID: String = UUID().uuidString
    let method: RequestMethod = .post
    let objectToken: String
    let status: AudioRecordStatus
    var catchError: Bool

    var parameters: [String: Any] {
        var params: [String: Any] = [:]
        params["object_token"] = objectToken
        params["status"] = status.rawValue
        return params
    }
}
