//
//  UniversalCardLynxPersonListModel.swift
//  LarkMessageCard
//
//  Created by ByteDance on 2023/6/14.
//

import Foundation
enum PersonType: String, Codable {
    case user = "user"
    case chat = "chat"
}
enum PersonListMode: String, Codable {
    case name = "name"
    case avatar = "avatar"
    case nameAvatar = "nameAvatar"
}
struct Person: Decodable {
    let id: String?
    let type: PersonType
    let tag: [String]?
    let content: String?
    let avatarKey: String?

    static func from(dict: [String: Any?]) throws -> Self {
        return try JSONDecoder().decode(
            Person.self,
            from: JSONSerialization.data(withJSONObject: dict)
        )
    }
}

struct PersonListProps: Decodable {
    let tag: String
    let id: String
    let persons: [Person]
    let lines: Int?
    let showAvatar: Bool?
    let showName: Bool?
    let styles: Styles
    // 文本对齐方式，可以是left|right|center|
    let align: TextAlign?

    struct Styles: Decodable {
        let avatarSize: CGFloat
        let avatarSpace: CGFloat
        let nameSize: CGFloat
        let nameToken: String
        let nameLineHeight: CGFloat
        let nameColor: String
        let moreSize: CGFloat
        let moreColor: String
        let moreTextColor: String
        let moreTextToken: String
        let moreTextSize: CGFloat
        let moreMaxCount: Int
        let margin: Margin

        struct Margin: Decodable {
            let left: CGFloat
            let right: CGFloat
            let top: CGFloat
            let bottom: CGFloat
        }
    }

    static func from(dict: [String: Any?]) throws -> Self {
        return try JSONDecoder().decode(
            PersonListProps.self,
            from: JSONSerialization.data(withJSONObject: dict)
        )
    }
}
