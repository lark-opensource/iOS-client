//
//  AuditLogTable.swift
//  LarkSecurityAudit
//
//  Created by Yiming Qu on 2020/11/23.
//

import Foundation
import SQLite
import LKCommonsLogging
import SwiftProtobuf

#if !DEBUG && !ALPHA
extension SecurityEvent_Event: SwiftProtobuf.MessageJSONLarkExt {}
#endif
typealias IdEventTuple = (id: String, event: Event)
final class AuditLogTable {

    static let logger = Logger.log(Database.self, category: "SecurityAudit.Database.AuditLogTable")

    lazy var table: Table = {
        Table("audit_log")
    }()

    let id = Expression<String>("id")
    let event = Expression<String>("event")

    var db: Connection?

    init(db: Connection?) {
        self.db = db
        do {
            try self.db?.run(self.createTableSQL())
        } catch {
            Self.logger.error("create database failed", error: error)
        }
    }

    func insert(event: SecurityEvent_Event) {
        do {
            let eventJSONData = try event.jsonUTF8Data()
            guard eventJSONData.count < Const.eventSizeLimit50k else {
                Self.logger.error("serialize event size over limit")
                return
            }
            guard let eventJSONString = String(data: eventJSONData, encoding: .utf8) else {
                Self.logger.error("serialize event json string fail")
                return
            }
            let insert = self.table.insert(
                self.id <- UUID().uuidString,
                self.event <- eventJSONString
            )
            try self.db?.run(insert)
        } catch {
            Self.logger.error("insert event failed", error: error)
        }
    }

    func delete(_ eventIds: [String]) {
        do {
            // 分段删除，因为会报错 too many SQL variables
            // https://stackoverflow.com/questions/7106016/too-many-sql-variables-error-in-django-witih-sqlite3
            var ids = eventIds
            var currentCount = ids.count
            let sliceMaxCount = 300
            while currentCount > 0 {
                // 找到要删除的
                let sliceCount = min(sliceMaxCount, currentCount)
                let sliceToDelete = ids.prefix(sliceCount)

                // 删除
                let matched = self.table.filter(sliceToDelete.contains(self.id))
                try self.db?.run(matched.delete())

                // 更新
                ids.removeFirst(sliceCount)
                currentCount = ids.count
            }
        } catch {
            Self.logger.error("delete event failed", error: error)
        }
    }

    func createTableSQL() -> String {
        /*
         TEXT VARCHAR 性能对比
         CREATE TABLE IF NOT EXISTS \"SecurityEvent\" (\"id\" TEXT PRIMARY KEY NOT NULL, \"event\" TEXT NOT NULL)
         */

        return table.create(ifNotExists: true) { tbl in
            tbl.column(id, primaryKey: true)
            tbl.column(event)
        }
    }

    func read(limit: Int) -> [IdEventTuple] {
        do {
            guard let db = self.db else {
                Self.logger.error("empty db")
                return []
            }
            let seq = try db.prepare(table.select([id, event]).limit(limit))

            var result: [IdEventTuple] = []
            for row in seq {
                do {
                    let idVal = try row.get(self.id)
                    let entityJSONVal = try row.get(self.event)
                    let entityValue = try SecurityEvent_Event(jsonString: entityJSONVal)
                    result.append((idVal, entityValue))
                } catch {
                    Self.logger.error("read row fail", error: error)
                }
            }
            return result
        } catch {
            Self.logger.error("read event failed", error: error)
            return []
        }
    }

}
