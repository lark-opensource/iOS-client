//
//  JSONModels.swift
//  BDAlogProtocol
//
//  Created by PGB on 2020/4/1.
//

import Foundation

// swiftlint:disable identifier_name
public class RawConfig: Decodable {
    public required init() {}

    var configs: [RawMonitorConfig] = []
}

public class RawMonitorConfig: Decodable {
    var config_name: String!
    var max_level: Int?
    var classifications: [String: [RawCondition]]!
    var operations: [String: String]!
    var extra: [String: String]?
    public required init() {}
}

public class RawCondition: Decodable {
    var regex: String!
    var type: ConditionType?
    var item_name: String?

    public required init() {}
}
// swiftlint:enable identifier_name
