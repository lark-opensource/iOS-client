//
//  PageModel.swift
//  SKCommon
//
//  Created by 曾浩泓 on 2021/9/28.
//  

import Foundation
public final class PageModel<T: Codable>: Codable {
    private(set) var data: [T]?
    private(set) var hasMore: Bool?
    private(set) var total: Int?
    private(set) var buffer: String?

    enum CodingKeys: String, CodingKey {
        case data
        case hasMore = "has_more"
        case total
        case buffer
    }

    public init(data: [T]?) {
        self.data = data
    }
}
