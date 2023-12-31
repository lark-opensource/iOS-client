//
//  EntityConfigCodable.swift
//  LarkModel
//
//  Created by Yuri on 2023/5/22.
//

import Foundation

struct EnumCodableWarpper: Codable {
    var key: String
    var content: String
}

struct TimeRangeEnumCodableWarpper: Codable {
    var key: String
    var start: Int64?
    var end: Int64?
}

extension BelongUserCondition: Codable {
    enum CodingKeys: CodingKey {
        case value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Self.CodingKeys.self)
        let warpper = try container.decode(EnumCodableWarpper.self, forKey: .value)
        if warpper.key == "belong" {
            self = .belong(warpper.content.components(separatedBy: " "))
        } else {
            self = .all
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        var warpper: EnumCodableWarpper
        switch self {
        case .belong(let ids):
            warpper = EnumCodableWarpper(key: "belong", content: ids.joined(separator: " "))
        default:
            warpper = EnumCodableWarpper(key: "", content: "")
        }
        try container.encode(warpper, forKey: .value)
    }
}

extension BelongChatCondition: Codable {
    enum CodingKeys: CodingKey {
        case value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Self.CodingKeys.self)
        let warpper = try container.decode(EnumCodableWarpper.self, forKey: .value)
        if warpper.key == "belong" {
            self = .belong(warpper.content.components(separatedBy: " "))
        } else {
            self = .all
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        var warpper: EnumCodableWarpper
        switch self {
        case .belong(let ids):
            warpper = EnumCodableWarpper(key: "belong", content: ids.joined(separator: " "))
        default:
            warpper = EnumCodableWarpper(key: "all", content: "")
        }
        try container.encode(warpper, forKey: .value)
    }
}

extension TimeRangeCondition: Codable {
    enum CodingKeys: CodingKey {
        case value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Self.CodingKeys.self)
        let warpper = try container.decode(TimeRangeEnumCodableWarpper.self, forKey: .value)
        if warpper.key == "range" {
            self = .range(warpper.start, warpper.end)
        } else {
            self = .all
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        var warpper: TimeRangeEnumCodableWarpper
        switch self {
        case .range(let start, let end):
            warpper = TimeRangeEnumCodableWarpper(key: "range", start: start, end: end)
        default:
            warpper = TimeRangeEnumCodableWarpper(key: "all")
        }
        try container.encode(warpper, forKey: .value)
    }
}
