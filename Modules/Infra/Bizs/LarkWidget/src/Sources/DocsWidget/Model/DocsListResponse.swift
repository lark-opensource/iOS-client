//
//  DocsListResponse.swift
//  LarkWidget
//
//  Created by Hayden Wang on 2022/8/16.
//

import Foundation

// swiftlint:disable all
public struct DocListResponse: Codable {

    public var code: Int
    public var msg: String
    public var data: DocListData
}

public struct DocListData: Codable {

    public var entities: DocListEntities
    public var node_list: [String]

    public var docItems: [DocItem] {
        node_list.compactMap {
            entities.nodes[$0]
        }
    }
}

public struct DocListEntities: Codable {
    public var nodes: [String: DocItem]
}
// swiftlint:enable all
