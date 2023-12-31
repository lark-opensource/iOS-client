//
//  WikiSpaceInfo.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2019/12/23.
//  

import Foundation

extension WikiSpaceInfo {
    // 用来解决 Codable 解析 members 时，任意一个解析失败导致全部失败的问题
    public struct Meta: Codable {
        let spaceName: String
        let spaceDescription: String
        let isStar: Bool
        let wikiScope: Int?

        enum CodingKeys: String, CodingKey {
            case spaceName          = "space_name"
            case spaceDescription   = "description"
            case isStar             = "is_star"
            case wikiScope          = "wiki_scope"
        }
    }
}

public struct WikiSpaceInfo {

    public let spaceName: String
    public let spaceDescription: String
    public let wikiScope: Int?
    public let isStar: Bool
    public let members: [WikiMember]

    public var isPublic: Bool {
        return wikiScope == 1
    }

    public init(space: WikiSpace) {
        spaceName = space.spaceName
        spaceDescription = space.wikiDescription
        isStar = space.isStar ?? false
        members = []
        wikiScope = space.wikiScope
    }

    public init(meta: Meta, members: [WikiMember]) {
        spaceName = meta.spaceName
        spaceDescription = meta.spaceDescription
        isStar = meta.isStar
        self.members = members
        self.wikiScope = meta.wikiScope
    }
}
