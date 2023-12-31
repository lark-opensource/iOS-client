//
//  NewFolderMapTable.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/7/8.
//  

import SQLite
import Foundation
import SwiftyJSON
import SKFoundation
import SKCommon

final class NewFolderMapTable {
    var db: Connection?
    let table: Table!
    private let parentNodeToken = Expression<String>("parent_node_token")
    private let childNodeToken = Expression<String>("child_node_token")
    private let nodeType = Expression<Int?>(FileListServerKeys.nodeType.rawValue)
    private let docConnection: DocsDBConnectionProvidor

    init(_ docConnection: DocsDBConnectionProvidor = Connection.docs) {
        self.docConnection = docConnection
        table = Table("NodeTokenTree")
        db = docConnection.file
        do {
            try db?.run(createTableCMD())
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error)
            DocsLogger.error("创建 NodeTokenTree 失败", error: error, component: LogComponents.db)
        }
    }

    func createTableCMD() -> String {
        return table.create(ifNotExists: true) { tbl in
            tbl.column(childNodeToken, primaryKey: true)
            tbl.column(parentNodeToken)
            tbl.column(nodeType)
        }
    }

    func getFolderMap() -> [FileListDefine.NodeToken: [TokenStruct]] {
        //删除parent为nil的row
        delete(["": []])

        do {
            var parentToChildMap = [FileListDefine.NodeToken: [TokenStruct]]()
            guard let records = try db?.prepareRowIterator(table).map({ $0 }) else {
                DocsLogger.info("db is nil or err occur")
                return parentToChildMap
            }
            for record in records {
                let childNodeTokenValue = DocsTableUtil.getOriColumn(childNodeToken, record: record)
                let parentNodeTokenValue = DocsTableUtil.getOriColumn(parentNodeToken, record: record)
                let nodeTypeValue = DocsTableUtil.getOriColumn(nodeType, record: record)
                if let childNodeTokenValue = childNodeTokenValue, let parentNodeTokenValue = parentNodeTokenValue {
                    var nodeTokenArray = [TokenStruct]()
                    if let childs = parentToChildMap[parentNodeTokenValue] {
                        nodeTokenArray.append(contentsOf: childs)
                    }
                    nodeTokenArray.append(TokenStruct(token: childNodeTokenValue, nodeType: nodeTypeValue ?? 0))
                    parentToChildMap[parentNodeTokenValue] = nodeTokenArray
                }
            }
            return parentToChildMap
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error)
            DocsLogger.error("获取 folderMap 失败", error: error, component: LogComponents.db)
            return [:]
        }
    }

    func insert(_ folderMap: [FileListDefine.NodeToken: [TokenStruct]]) {
        //频繁的循环插入/删除操作导致内存增加，使用releasePool释放
        folderMap.forEach { (arg0) in
            let (parent, tokenNodes) = arg0
            tokenNodes.forEach({ (tokenNode) in
                autoreleasepool {
                    insert(tokenNode: tokenNode, parentNodeToken: parent)
                }
            })
        }
    }
    
    func insert(tokenNode: TokenStruct, parentNodeToken: FileListDefine.NodeToken) {
        do {
            if !tokenNode.token.isEmpty, !parentNodeToken.isEmpty {
                let insert = table.insert(or: .replace,
                                          self.childNodeToken <- tokenNode.token,
                                          self.parentNodeToken <- parentNodeToken,
                                          self.nodeType <- tokenNode.nodeType)
                try db?.run(insert)
            } else {
                DocsLogger.warning("children/parent should not empty")
            }
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error)
            DocsLogger.error("insert new folder map table failed", error: error, component: LogComponents.db)
        }
    }

    func update(_ folderMap: [FileListDefine.NodeToken: [TokenStruct]]) {
        delete(folderMap)
        insert(folderMap)
    }

    func delete(_ folderMap: [FileListDefine.NodeToken: [TokenStruct]]) {
        do {
            // 分段删除，因为会报错 too many SQL variables
            // https://stackoverflow.com/questions/7106016/too-many-sql-variables-error-in-django-witih-sqlite3
            var parentTokens = folderMap.keys.map { $0 }
            var currentCount = parentTokens.count
            let sliceMaxCount = 100
            while currentCount > 0 {
                //频繁的循环插入/删除操作导致内存增加，使用releasePool释放
                try autoreleasepool {
                    //找到要删除的
                    let sliceCount = min(sliceMaxCount, currentCount)
                    let sliceToDelete = parentTokens.prefix(sliceCount)

                    //删除
                    let matched = table.filter(sliceToDelete.contains(parentNodeToken))
                    try db?.run(matched.delete())

                    //更新
                    parentTokens.removeFirst(sliceCount)
                    currentCount = parentTokens.count
                }
            }
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error)
            DocsLogger.error("删除 folderMap  失败", error: error, component: LogComponents.db)
        }
    }
}
