//
//  SpecialFoler.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/7/8.
//  

import SQLite
import Foundation
import SwiftyJSON
import SKFoundation
import SKCommon

final class SpecialFolderTable {
    var db: Connection?
    let table: Table!
    private let location = Expression<Int>("location")
    private let token = Expression<String>("token")
    private let nodeType = Expression<Int?>(FileListServerKeys.nodeType.rawValue)
    private let docConnection: DocsDBConnectionProvidor

    init(_ docConnection: DocsDBConnectionProvidor = Connection.docs) {
        self.docConnection = docConnection
        table = Table("SpecialToken")
        db = docConnection.file
        do {
            try db?.run(createTableCMD())
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error)
            DocsLogger.error("creat SpecialToken failed", error: error, component: LogComponents.db)
        }
    }

    func createTableCMD() -> String {
        return table.create(ifNotExists: true) { tbl in
            tbl.column(location)
            tbl.column(token)
            tbl.column(nodeType)
            tbl.primaryKey(location, token)
        }
    }

    func getSpecialTokens() -> SpecialTokens {
        var specialTokens = SpecialTokens()
        do {
            guard let records = try db?.prepareRowIterator(table).map({ $0 }) else {
                DocsLogger.info("db is nil or err occur")
                return specialTokens
            }

            for record in records {
                let locationValue = DocsTableUtil.getOriColumn(location, record: record)
                let tokenValue = DocsTableUtil.getOriColumn(token, record: record)
                let nodeTypeValue = DocsTableUtil.getOriColumn(nodeType, record: record)
                guard let locationReslut = locationValue,
                      let tokenReslut = tokenValue,
                      let key = DocFolderKey(rawValue: locationReslut) else {
                    DocsLogger.info("invalied special Key", component: LogComponents.db)
                    continue
                }
                specialTokens.addToken(tokenReslut, folderKey: key, nodeType: nodeTypeValue ?? 0)
            }
            logInfo(specialTokens: specialTokens)
            return specialTokens
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error)
            DocsLogger.error("get nodeObjTokenMap failed", error: error, component: LogComponents.db)
            return specialTokens
        }
    }

    func update(specialTokensDiff: SpecialTokensDiff) {
        do {
            func insert(token: String, folderKey: DocFolderKey, nodeType: Int) throws {
                let insert = table.insert(self.token <- token,
                                          self.location <- folderKey.rawValue,
                                          self.nodeType <- nodeType)
                try db?.run(insert)
            }
            try specialTokensDiff.storages.forEach { folderKey, tokens in
                deleteByLocation(folderKey)
                try tokens.forEach { token in
                    try insert(token: token.token, folderKey: folderKey, nodeType: token.nodeType)
                }
            }
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error)
            DocsLogger.error("insert DB failed", error: error, component: LogComponents.db)
        }
    }

    private func deleteByLocation(_ folderKey: DocFolderKey) {
        let matchedTokens = table.filter(location == folderKey.rawValue)
        do {
            try db?.run(matchedTokens.delete())
        } catch {
            spaceAssertionFailure()
            DBErrorStatistics.dbStatisticsFor(error: error)
            DocsLogger.error("delete tokens for \(folderKey.rawValue) failed", error: error, component: LogComponents.db)
        }
    }

    private func logInfo(specialTokens: SpecialTokens) {
        specialTokens.storages.forEach { folderKey, tokens in
            DocsLogger.debugFileList(tag: folderKey, desc: "read from DB list: \(folderKey.name) count is \(tokens.count)")
        }
    }
}
