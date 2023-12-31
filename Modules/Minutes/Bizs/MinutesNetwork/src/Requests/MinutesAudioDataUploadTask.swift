//
//  MinutesAudioDataUploadTask.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/3/24.
//

import Foundation

public enum MinutesAudioDataUploadFormat: Int {
    case pcm = 1
    case aac = 2
}

public struct MinutesAudioDataUploadTask: UploadRequest {

    public init(objectToken: String, language: String, startTime: String, duration: Int, segID: Int, payload: Data, format: MinutesAudioDataUploadFormat? = nil, originSize: Int? = nil) {
        self.objectToken = objectToken
        self.language = language
        self.startTime = startTime
        self.duration = duration
        self.segID = segID
        self.payload = payload
        self.format = format
        self.size = originSize
    }

    public let objectToken: String
    public let language: String
    public let startTime: String
    public let duration: Int
    public let segID: Int
    public let payload: Data
    public let format: MinutesAudioDataUploadFormat?
    public let size: Int?

    public typealias ResponseType = UploadResponse

    public let endpoint: String = MinutesAPIPath.upload
    public let requestID: String = UUID().uuidString
    public var parameters: [String: Any] {
        var params: [String: Any] = [:]
        params["object_token"] = objectToken
        params["recording_lang"] = language
        params["start_ms"] = startTime
        params["duration"] = duration
        params["seg_id"] = segID
        params["recording_format"] = format?.rawValue
        return params
    }
}
