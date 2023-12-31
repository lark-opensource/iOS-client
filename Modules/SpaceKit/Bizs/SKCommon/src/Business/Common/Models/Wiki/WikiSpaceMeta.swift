//
//  WikiSpaceMeta.swift
//  SpaceKit
//
//  Created by nine on 2019/8/26.
// swiftlint:disable nesting

import Foundation

/// 原 WikiSpace, 目前用在 docs 的 Lark 大搜搜索知识库
public final class WikiSpaceMeta: Codable {
    public let spaceId: String
    public let spaceName: String
    public var description: String?
    public var spaceIcon: URL?
    public var attr: Int?
    public var isStar: Bool?
    public var homePage: HomePage?

    public final class HomePage: Codable {
        let objToken: String
        let objType: Int
        let wikiToken: String
        private enum CodingKeys: String, CodingKey {
            case objToken = "obj_token"
            case objType = "obj_type"
            case wikiToken = "wiki_token"
        }
    }

    private enum CodingKeys: String, CodingKey {
        case spaceId = "space_id"
        case spaceName = "space_name"
        case description
        case spaceIcon = "space_icon"
        case attr
        case isStar = "is_star"
        case homePage = "home_page"
    }

    public init(spaceId: String, spaceName: String) {
        self.spaceId = spaceId
        self.spaceName = spaceName
    }
}
