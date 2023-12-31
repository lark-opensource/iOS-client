//
//  LingoDictSettingsRequest.swift
//  MinutesNetwork
//
//  Created by ByteDance on 2023/12/6.
//

import Foundation

public struct LingoDictSettingResponse: Codable {
    public struct Enabled: Codable {
        public let isEnabled: Bool

        private enum CodingKeys: String, CodingKey {
            case isEnabled = "is_enabled"
        }
    }
    
    public let minutes: Enabled?

    private enum CodingKeys: String, CodingKey {
        case minutes = "minutes"
    }
}

public struct LingoDictSettingsRequest: Request {

    public typealias ResponseType = Response<LingoDictSettingResponse>

    public let endpoint: String = "/lingo/v2/api/user_settings"
    public let requestID: String = UUID().uuidString
    public let method: RequestMethod = .get
    public let objectToken: String

    public let catchError: Bool

    public init(objectToken: String, catchError: Bool) {
        self.objectToken = objectToken
        self.catchError = catchError
    }

    public var parameters: [String: Any] {
        let params: [String: Any] = ["object_token": objectToken,
                                    "include_brand": true]
        return params
    }
}
