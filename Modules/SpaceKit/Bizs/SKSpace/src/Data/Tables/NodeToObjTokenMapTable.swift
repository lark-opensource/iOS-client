//
//  NewTokenMapTable.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/7/8.
//  

import SQLite
import Foundation
import SwiftyJSON
import SKFoundation
import SKCommon

final class NodeToObjTokenMapTable {
    var db: Connection?
    let table: Table!
    private let objToken = Expression<String>("objToken")
    private let nodeToken = Expression<String>("nodeToken")
    private let nodeType = Expression<Int?>(FileListServerKeys.nodeType.rawValue)
    private let docConnection: DocsDBConnectionProvidor

    init(_ docConnection: DocsDBConnectionProvidor = Connection.docs) {
        self.docConnection = docConnection
        table = Table("nodeToObjTokenMap")
        db = docConnection.file
        do {
            try db?.run(createTableCMD())
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error)
            DocsLogger.error("创建 nodeToObjTokenMap 失败", error: error, component: LogComponents.db)
        }
    }

    func createTableCMD() -> String {
        return table.create(ifNotExists: true) { tbl in
            tbl.column(nodeToken, primaryKey: true)
            tbl.column(objToken)
            tbl.column(nodeType)
        }
    }

    func getNodeObjTokenMap() -> [TokenStruct: FileListDefine.ObjToken] {
        do {
            var map = [TokenStruct: FileListDefine.ObjToken]()
            guard let records = try db?.prepareRowIterator(table).map({ $0 }) else {
                DocsLogger.info("db is nil or err occur")
                return map
            }
            for record in records {
                let objTokenValue = DocsTableUtil.getOriColumn(objToken, record: record)
                let nodeTokenValue = DocsTableUtil.getOriColumn(nodeToken, record: record)
                let nodeTypeValue = DocsTableUtil.getOriColumn(nodeType, record: record)
                if let objTokenValue = objTokenValue, let nodeTokenValue = nodeTokenValue {
                    let tokenNode = TokenStruct(token: nodeTokenValue, nodeType: nodeTypeValue ?? 0)
                    map[tokenNode] = objTokenValue
                }
            }
            return map
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error)
            DocsLogger.error("获取 nodeObjTokenMap 失败", error: error, component: LogComponents.db)
            return [:]
        }
    }

    func insert(_ nodeObjTokenMap: [TokenStruct: FileListDefine.ObjToken]) {
        //频繁的循环插入/删除操作导致内存增加，使用releasePool释放
        for (tokenNode, objToken) in nodeObjTokenMap {
            autoreleasepool {
                insert(tokenNode: tokenNode, objToken: objToken)
            }
        }
    }
    
    func insert(tokenNode: TokenStruct, objToken: FileListDefine.ObjToken) {
        do {
            let insert = table.insert(or: .replace,
                                      self.objToken <- objToken,
                                      self.nodeToken <- tokenNode.token,
                                      self.nodeType <- tokenNode.nodeType)
            try db?.run(insert)
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error)
            DocsLogger.error("insert nodeObjTokenMap table error", error: error, component: LogComponents.db)
        }
    }
    

    func update(_ nodeObjTokenMap: [TokenStruct: FileListDefine.ObjToken]) {
        delete(nodeObjTokenMap)
        insert(nodeObjTokenMap)
    }

    func delete(_ nodeObjTokenMap: [TokenStruct: FileListDefine.ObjToken]) {
        do {
            // 分段删除，因为会报错 too many SQL variables
            // https://stackoverflow.com/questions/7106016/too-many-sql-variables-error-in-django-witih-sqlite3
            var nodeTokens = nodeObjTokenMap.keys.map { $0.token }
            var currentCount = nodeTokens.count
            let sliceMaxCount = 100
            while currentCount > 0 {
                //频繁的循环插入/删除操作导致内存增加，使用releasePool释放
                try autoreleasepool {
                    //找到要删除的
                    let sliceCount = min(sliceMaxCount, currentCount)
                    let sliceToDelete = nodeTokens.prefix(sliceCount)

                    //删除
                    let matched = table.filter(sliceToDelete.contains(nodeToken))
                    try db?.run(matched.delete())

                    //更新
                    nodeTokens.removeFirst(sliceCount)
                    currentCount = nodeTokens.count
                }
            }
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error)
            spaceAssertionFailure()
            DocsLogger.error("删除 nodeObjTokenMap  失败", error: error, component: LogComponents.db)
        }
    }
}
