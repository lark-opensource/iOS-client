//
//  WikiNode.swift
//  SpaceKit
//
//  Created by bupozhuang on 2019/9/24.
//

import UIKit
import SKCommon
import SQLite
import SKFoundation
import SKResource
import SpaceInterface

// WikiNodeMeta 的定义下沉到了 SpaceInterface

extension WikiNodeMeta {
    public static var defaultWikiNodeMeta: WikiNodeMeta {
        return WikiNodeMeta(wikiToken: "", objToken: "", docsType: .unknownDefaultType, spaceID: "")
    }
}

// MARK: - Utils
extension WikiNodeMeta {
    // wiki节点对应的URL
    public var wikiUrl: URL {
        return DocsUrlUtil.url(type: .wiki, token: wikiToken)
    }
}

class WikiNodeMetaTable {
    private let wikiToken = Expression<String>("wiki_token")
    private let spaceID = Expression<String>("space_id")
    private let objToken = Expression<String>("obj_token")
    private let objType = Expression<Int>("obj_type")

    private let db: Connection
    private let table: Table

    private var createTableCMD: String {
        let command = table.create(ifNotExists: true) { t in
            t.column(wikiToken, primaryKey: true)
            t.column(spaceID)
            t.column(objToken)
            t.column(objType)
        }
        return command
    }

    init(connection: Connection, tableName: String = "wiki_space") {
        db = connection
        table = Table(tableName)
    }

    func setup() throws {
        try db.run(createTableCMD)
    }

    private func parse(record: Row) -> WikiNodeMeta {
        let spaceID = record[self.spaceID]
        let wikiToken = record[self.wikiToken]
        let objToken = record[self.objToken]
        let objType = record[self.objType]
        let nodeMeta = WikiNodeMeta(wikiToken: wikiToken,
                                    objToken: objToken,
                                    docsType: DocsType(rawValue: objType),
                                    spaceID: spaceID)
        return nodeMeta
    }

    private func insertQuery(with node: WikiNodeMeta) -> Insert {
        let insertQuery = table.insert(or: .replace,
                                       self.spaceID <- node.spaceID,
                                       self.wikiToken <- node.wikiToken,
                                       self.objToken <- node.objToken,
                                       self.objType <- node.docsType.rawValue)
        return insertQuery
    }

    func getNodeMeta(_ wikiToken: String) -> WikiNodeMeta? {
        do {
            var nodes: [WikiNodeMeta] = []
            let records = try db.prepare(table.where(self.wikiToken == wikiToken))
            for r in records {
                let node = parse(record: r)
                nodes.append(node)
            }
            return nodes.first
        } catch {
            spaceAssertionFailure("wiki.db.space --- db error when get all spaces \(error)")
            return nil
        }
    }

    func insert(node: WikiNodeMeta) {
        do {
            let query = insertQuery(with: node)
            try db.run(query)
        } catch {
            spaceAssertionFailure("wiki.db.wikiNodeMeta --- db error when insert node record \(error)")
        }
    }

    func delete(for wikiToken: String) {
        do {
            let query = table.filter(self.wikiToken == wikiToken)
            try db.run(query.delete())
        } catch {
            spaceAssertionFailure("wiki.db.wikiNodeMeta --- db error when delete node record \(error)")
        }
    }
}
