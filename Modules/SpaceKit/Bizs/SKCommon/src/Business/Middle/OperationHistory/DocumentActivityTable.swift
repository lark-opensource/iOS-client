//
//  DocumentActivityTable.swift
//  SKCommon
//
//  Created by Weston Wu on 2021/11/9.
//

import Foundation
import SQLite
import SKFoundation
import SpaceInterface

public struct DocumentActivity {
    // 唯一 ID
    let uuid: String
    // 文档 ID，通常是 objToken
    let objID: String
    // 文档类型，objType.rawValue
    let objType: Int
    // 操作者 userID，通常是当前用户 ID
    let operatorID: String
    // 操作场景
    let scene: Int
    // 操作类型
    let operationName: String
    // 操作发生的时间戳, 单位 秒
    let time: Int
    // 拓展字段，序列化后的字符串
    let extraInfo: String?
}

extension DocumentActivity {
    public init(objToken: FileListDefine.ObjToken, objType: DocsType, operatorID: String, scene: Scene,
                operationType: OperationType, time: Double = Date().timeIntervalSince1970, extraInfo: String? = nil) {
        self.init(uuid: UUID().uuidString, objID: objToken, objType: objType.rawValue, operatorID: operatorID,
                  scene: scene.rawValue, operationName: operationType.rawValue, time: Int(time), extraInfo: extraInfo)
    }
}

extension DocumentActivity {
    public enum Scene: Int {
        case download = 3
    }

    public enum OperationType: String {
        case download = "download"
        case offline = "offline"
        case saveToLocal = "save_to_local"
        case openWithOtherApp = "open_with_other_app"
    }
}

struct BatchDocumentActivity {
    let objID: String
    let objType: Int
    let activities: [DocumentActivity]
}

class DocumentActivityTable {
    private let uuid = Expression<String>("uuid")
    private let objID = Expression<String>("obj_id")
    private let objType = Expression<Int>("obj_type")
    private let operatorID = Expression<String>("operator_id")
    private let scene = Expression<Int>("operate_scene")
    private let operationName = Expression<String>("operate_name")
    private let time = Expression<Int>("operate_time")
    private let extraInfo = Expression<String?>("extra")

    private let db: Connection
    private let table: Table

    private var createTableCMD: String {
        let command = table.create(ifNotExists: true) { t in
            t.column(uuid, primaryKey: true)
            t.column(objID)
            t.column(objType)
            t.column(operatorID)
            t.column(scene)
            t.column(operationName)
            t.column(time)
            t.column(extraInfo)
        }
        return command
    }

    init(connection: Connection, tableName: String = "document_activity") {
        db = connection
        table = Table(tableName)
    }

    func setup() throws {
        try db.run(createTableCMD)
    }

    private func parse(activity: Row) -> DocumentActivity {
        let uuid = activity[self.uuid]
        let objID = activity[self.objID]
        let objType = activity[self.objType]
        let operatorID = activity[self.operatorID]
        let scene = activity[self.scene]
        let operationName = activity[self.operationName]
        let time = activity[self.time]
        let extraInfo = activity[self.extraInfo]

        return DocumentActivity(uuid: uuid, objID: objID, objType: objType, operatorID: operatorID,
                                scene: scene, operationName: operationName, time: time, extraInfo: extraInfo)
    }

    private func queryForInsert(activity: DocumentActivity) -> Insert {
        let query = table.insert(or: .replace,
                                 self.uuid <- activity.uuid,
                                 self.objID <- activity.objID,
                                 self.objType <- activity.objType,
                                 self.operatorID <- activity.operatorID,
                                 self.scene <- activity.scene,
                                 self.operationName <- activity.operationName,
                                 self.time <- activity.time,
                                 self.extraInfo <- activity.extraInfo)
        return query
    }

    func save(activity: DocumentActivity) {
        do {
            let query = queryForInsert(activity: activity)
            try db.run(query)
        } catch {
            DocsLogger.error("operation-history.db --- save record failed", error: error)
            spaceAssertionFailure()
        }
    }

    func getNextBatchActivities(limit: Int) -> BatchDocumentActivity? {
        do {
            // SELECT * FROM operation_history record WHERE (record.objID) in (select objID from operation_history limit 1) LIMIT :limit
            // 按 token 维度先聚合，再上报
            let idRows = try db.prepare(table.select(self.objID, self.objType).limit(1))
            guard let (objID, objType) = idRows.map({ ($0[self.objID], $0[self.objType]) }).first else { return nil }
            let query = table.filter(self.objID == objID).limit(limit)
            let rows = try db.prepare(query)
            let activities = rows.map(parse(activity:))
            return BatchDocumentActivity(objID: objID, objType: objType, activities: activities)
        } catch {
            DocsLogger.error("operation-history.db --- db error when get records", error: error)
            spaceAssertionFailure()
            return nil
        }
    }

    func delete(uuids: [String]) {
        do {
            var remainUUIDs = uuids
            var recordCount = uuids.count
            while recordCount > 0 {
                // 每次删 100 个
                let uuidsToDelete = remainUUIDs.prefix(100)
                recordCount -= 100
                if remainUUIDs.count >= 100 {
                    remainUUIDs.removeFirst(100)
                }
                let matched = table.filter(uuidsToDelete.contains(self.uuid))
                try db.run(matched.delete())
            }
        } catch {
            DocsLogger.error("document-activity.db --- db error when delete records", error: error)
            spaceAssertionFailure()
        }
    }
}
