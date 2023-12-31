//
//  Language.swift
//  LarkMinutesAPI
//
//  Created by lvdaqian on 2021/1/11.
//

import Foundation

public struct Language: Codable, Equatable {
    public init(name: String, code: String) {
        self.name = name
        self.code = code
    }

    public let name: String
    public let code: String

    private enum CodingKeys: String, CodingKey {
        case name = "language_name"
        case code = "language"
    }

    public static let `default` = Language(name: "origin", code: "default")

    public static func == (lhs: Language, rhs: Language) -> Bool {
        return lhs.code == rhs.code
    }
}
