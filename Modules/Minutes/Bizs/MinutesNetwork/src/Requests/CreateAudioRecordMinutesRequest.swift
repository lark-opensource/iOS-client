//
//  CreateAudioRecordMinutesRequest.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/3/18.
//

import Foundation

public struct AudioRecordMinutes: Codable, Equatable {

    public let objectToken: String?
    public let topic: String?
    public let startTime: Int?
    public let isAdmin: Bool?
    public let userName: String?
    public let noQuotaNotice: String?
    public let privacyAgreement: String?
    public let billUrl: String?

    private enum CodingKeys: String, CodingKey {
        case objectToken = "object_token"
        case topic = "topic"
        case startTime = "start_time"
        case isAdmin = "is_admin"
        case userName = "user_name"
        case noQuotaNotice = "no_quota_notice"
        case privacyAgreement = "privacy_agreement"
        case billUrl = "bill_url"
    }
}

public struct StorageSpaceError: LocalizedError {

    public var code: Int
    public var isAdmin: Bool
    public var billUrl: String?
    public var errorDescription: String? { return _description }

    private var _description: String?

    init(code: Int, isAdmin: Bool, description: String?, billUrl: String?) {
        self._description = description
        self.isAdmin = isAdmin
        self.code = code
        self.billUrl = billUrl
    }
}

struct CreateAudioRecordMinutesRequest: Request {
    typealias ResponseType = Response<AudioRecordMinutes>

    let endpoint: String = MinutesAPIPath.create
    let requestID: String = UUID().uuidString
    let method: RequestMethod = .post
    let topic: String?
    let language: String
    let isForced: Bool
    var catchError: Bool

    var parameters: [String: Any] {
        var params: [String: Any] = [:]
        params["topic"] = topic
        params["recording_lang"] = language
        params["is_forced"] = isForced
        return params
    }
}
