//
//  MeetingNotesRequest.swift
//  MinutesFoundation
//
//  Created by ByteDance on 2023/9/7.
//

import Foundation

public struct MeetingNotesRequest: Request {
    public typealias ResponseType = Response<FileInfo>

    public let endpoint: String = "/minutes/api/meeting-notes"
    public let requestID: String = UUID().uuidString
    public let method: RequestMethod = .get
    public let objectToken: String
    public let catchError: Bool

    public init(objectToken: String, catchError: Bool) {
        self.objectToken = objectToken
        self.catchError = catchError
    }

    public var parameters: [String: Any] {
        var params: [String: Any] = [:]
        params["object_token"] = objectToken
        return params
    }


}
