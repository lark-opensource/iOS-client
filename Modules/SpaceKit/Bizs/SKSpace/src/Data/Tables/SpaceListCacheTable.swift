//
//  SpaceListCacheTable.swift
//  SKCommon
//
//  Created by Weston Wu on 2021/3/2.
//

import SQLite
import Foundation
import SKFoundation

// 存储各列表在切换筛选过滤配置时，对应列表的缓存，保证列表数据的立即展示
final class SpaceListCacheTable {

    private let connection: Connection
    private let table: Table

    private let listID = Expression<String>("list_id")
    private let filterType = Expression<String>("filter_type")
    private let sortType = Expression<String>("sort_type")
    private let isAscending = Expression<Bool>("is_ascending")
    private let tokens = Expression<String>("tokens")

    private var createTableCMD: String {
        let command = table.create(ifNotExists: true) { builder in
            builder.column(listID)
            builder.column(filterType)
            builder.column(sortType)
            builder.column(isAscending)
            builder.column(tokens)
            builder.primaryKey(listID, filterType, sortType, isAscending)
        }
        return command
    }

    init?(connectionProvider: DocsDBConnectionProvidor) {
        guard let connection = connectionProvider.file else {
            DocsLogger.error("创建 SpaceListCacheTable 失败，无法获取 connection 对象")
            return nil
        }
        self.connection = connection
        table = Table("SpaceListCache")
        do {
            try connection.run(createTableCMD)
        } catch {
            DocsLogger.error("DB 创建 SpaceListCacheTable 失败", error: error, component: LogComponents.db)
        }
    }

    func getTokens(listID: String, filterType: String, sortType: String, isAscending: Bool) -> [String]? {
        do {
            let query = table.select(tokens)
                .where(self.listID == listID
                        && self.filterType == filterType
                        && self.sortType == sortType
                        && self.isAscending == isAscending)
                .limit(1)
            let records = try connection.prepare(query)
            let tokens = records.flatMap { row -> [String] in
                let data = row[self.tokens]
                return data.split(separator: ",").map(String.init)
            }
            return tokens
        } catch {
            DocsLogger.error("查询 SpaceListCacheTable 失败", extraInfo: ["listID": listID, "filterType": filterType, "sortType": sortType, "isAscending": isAscending], error: error)
            assertionFailure()
            return nil
        }
    }

    func save(tokens: [String], listID: String, filterType: String, sortType: String, isAscending: Bool) {
        do {
            let data = tokens.joined(separator: ",")
            let query = table.insert(or: .replace,
                                     self.listID <- listID,
                                     self.filterType <- filterType,
                                     self.sortType <- sortType,
                                     self.isAscending <- isAscending,
                                     self.tokens <- data)
            try connection.run(query)
        } catch {
            DocsLogger.error("更新 SpaceListCacheTable 失败", extraInfo: ["listID": listID, "filterType": filterType, "sortType": sortType, "isAscending": isAscending], error: error)
            assertionFailure()
        }
    }
}
