//
//  FetchSpeakersRequest.swift
//  MinutesFoundation
//
//  Created by yangyao on 2023/3/31.
//

import Foundation

public struct SpeakerData: Codable {
    public let paragraphToSpeaker: [String: String]
    public let speakerInfoMap: [String: Participant]
    public let hasMore: Bool
    public let total: Int

    private enum CodingKeys: String, CodingKey {
        case paragraphToSpeaker = "paragraph_to_speaker"
        case speakerInfoMap = "speaker_info_map"
        case hasMore = "has_more"
        case total = "total"
    }
}

public struct FetchSpeakersRequest: Request {

    public typealias ResponseType = Response<SpeakerData>

    public let endpoint: String = MinutesAPIPath.speakers
    public let requestID: String = UUID().uuidString
    public let objectToken: String
    public let paragraphID: String?
    public let size: Int?
    public let translateLang: String?
    public var catchError: Bool

    public var parameters: [String: Any] {
        var params: [String: Any] = [:]
        params["object_token"] = objectToken
        params["paragraph_id"] = paragraphID
        params["size"] = size
        params["translate_lang"] = translateLang
        return params
    }
}
