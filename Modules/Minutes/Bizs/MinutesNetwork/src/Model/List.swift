//
//  List.swift
//  LarkMinutesAPI
//
//  Created by lvdaqian on 2021/1/11.
//

import Foundation

public struct List<T: Codable>: Codable {
    public let total: Int
    public let offset: Int?
    public let size: Int?
    public let hasMore: Bool?
    public let list: [T]?

    private enum CodingKeys: String, CodingKey {
        case total
        case offset
        case size
        case hasMore = "has_more"
        case list
    }
}
