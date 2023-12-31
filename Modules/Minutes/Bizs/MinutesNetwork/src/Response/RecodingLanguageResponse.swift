//
//  RecodingLanguageResponse.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/3/28.
//

import Foundation

public struct RecodingLanguageResponse: Codable, MinutesResponseType {

    public let code: String
    public let name: String

    private enum CodingKeys: String, CodingKey {
        case code = "recording_lang"
        case name = "language_name"
    }
}
