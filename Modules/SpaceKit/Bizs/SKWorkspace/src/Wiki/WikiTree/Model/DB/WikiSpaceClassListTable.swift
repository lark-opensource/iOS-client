//
//  WikiSpaceClassListTable.swift
//  SKWikiV2
//
//  Created by majie.7 on 2022/12/6.
//

import Foundation
import SQLite
import SKFoundation

public enum SpaceType: String {
    case all
    case team
    case personal
    case star   //置顶空间
}

public enum SpaceClassType: Equatable {
    case all
    case star   // 置顶空间
    case other(String)
    
    public var classId: String {
        switch self {
        case .all:
            return "all"
        case .star:
            return "star"
        case let .other(classId):
            return classId
        }
    }
}

public struct WikiSpaceQuote {
    let spaceID: String
    let spaceType: SpaceType
    let spaceClassType: SpaceClassType
    
    public init(spaceID: String, spaceType: SpaceType, spaceClassType: SpaceClassType) {
        self.spaceID = spaceID
        self.spaceType = spaceType
        self.spaceClassType = spaceClassType
    }
}

class WikiSpaceQuoteListTable {
    private let spaceID         = Expression<String>("space_id")
    private let spaceType       = Expression<String>("space_type")
    private let spaceClassId    = Expression<String>("space_class_id")
    
    private let db: Connection
    private let table: Table
    
    private var createTableCMD: String {
        let command = table.create(ifNotExists: true) { t in
            t.column(spaceID)
            t.column(spaceType)
            t.column(spaceClassId)
            t.primaryKey(spaceID, spaceType, spaceClassId)
        }
        return command
    }
    
    init(connection: Connection, tableName: String = "wiki_space_quote_list") {
        db = connection
        table = Table(tableName)
    }
    
    func setup() throws {
        try db.run(createTableCMD)
    }
    
    private func parse(record: Row) -> WikiSpaceQuote {
        let spaceId         = record[self.spaceID]
        let spaceType       = record[self.spaceType]
        let spaceClassId    = record[self.spaceClassId]
        
        let type = SpaceType(rawValue: spaceType) ?? .all
        let spaceClassType: SpaceClassType = spaceClassId == "all" ? .all : .other(spaceClassId)
        let quote = WikiSpaceQuote(spaceID: spaceId, spaceType: type, spaceClassType: spaceClassType)
        return quote
    }
    
    private func insertQuery(with quote: WikiSpaceQuote) -> Insert {
        let insertQuery = table.insert(or: .replace,
                                       self.spaceID <- quote.spaceID,
                                       self.spaceType <- quote.spaceType.rawValue,
                                       self.spaceClassId <- quote.spaceClassType.classId)
        return insertQuery
    }
    
    func getAllSpaceIdOfCurrentClass(spaceType: SpaceType, spaceClassId: SpaceClassType) -> [String] {
        var spaceIds = [String]()
        do {
            let records = try db.prepare(table.filter(self.spaceType == spaceType.rawValue && self.spaceClassId == spaceClassId.classId))
            spaceIds = records.map({ record in
                parse(record: record).spaceID
            })
        } catch {
            DocsLogger.error("wiki.space.quota.list --- db error when get spaceID", error: error)
        }
        return spaceIds
    }
    
    func getAllStarSpaceIds() -> [String] {
        return getAllSpaceIdOfCurrentClass(spaceType: .star, spaceClassId: .star)
    }
    
    func insert(with quote: WikiSpaceQuote) {
        do {
            let query = insertQuery(with: quote)
            try db.run(query)
        } catch {
            DocsLogger.error("wiki.space.quote.list --- db error when insert wiki space quote", error: error)
        }
    }
    
    func insert(with quotes: [WikiSpaceQuote]) {
        // 插入新的相同引用数据前删掉旧的数据
        if let quote = quotes.first {
            delete(with: quote)
        }
        quotes.forEach {
            insert(with: $0)
        }
    }
    
    func delete(with quote: WikiSpaceQuote) {
        do {
            let records = table.filter(self.spaceType == quote.spaceType.rawValue && self.spaceClassId == quote.spaceClassType.classId)
            try db.run(records.delete())
        } catch {
            DocsLogger.error("wiki.space.quote.list -- db error when delete wiki space quote", error: error)
        }
    }
    
    func deleteQuoto(type: SpaceType, classType: SpaceClassType) {
        do {
            let records = table.filter(self.spaceType == type.rawValue && self.spaceClassId == classType.classId)
            try db.run(records.delete())
        } catch {
            DocsLogger.error("wiki.space.quote.list -- db error when delete wiki space quote with type ", error: error)
        }
    }
    
    func deleteAllQuote() {
        do {
            try db.run(table.delete())
        } catch {
            DocsLogger.error("wiki.space.quote.list -- db error when delete all quote", error: error)
        }
    }
}
