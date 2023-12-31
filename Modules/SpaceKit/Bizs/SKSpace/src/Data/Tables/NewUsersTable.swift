//
//  NewUsersTable.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/7/8.
//
// 存储用户信息

import SQLite
import Foundation
import SwiftyJSON
import SKFoundation
import SKCommon

final class NewUsersTable {
    var db: Connection?
    let table: Table!
    private let userId = Expression<String>("userId")
    private let name = Expression<String?>("name")
    private let cnName = Expression<String?>("cn_name")
    private let enName = Expression<String?>("en_name")
    private let tenantName = Expression<String?>("tenant_name")
    private let docConnection: DocsDBConnectionProvidor

    init(_ docConnection: DocsDBConnectionProvidor = Connection.docs) {
        self.docConnection = docConnection
        table = Table("NewUsers")
        db = docConnection.file
        do {
            try db?.run(createTableCMD())
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error)
            DocsLogger.error("删除数据库失败", error: error, component: LogComponents.db)
        }
    }

    func createTableCMD() -> String {
        return table.create(ifNotExists: true) { tbl in
            tbl.column(userId, primaryKey: true)
            tbl.column(name)
            tbl.column(cnName)
            tbl.column(enName)
            tbl.column(tenantName)
        }
    }

    func getAllUsers () -> [UserInfo] {
        var users = [UserInfo]()
        do {
            guard let entries = try db?.prepareRowIterator(table).map({ $0 }) else {
                DocsLogger.info("db is nil or err")
                return users
            }
            for record in entries {
                let cnNameValue = DocsTableUtil.getOriColumn(cnName, record: record)
                let enNameValue = DocsTableUtil.getOriColumn(enName, record: record)
                let nameValue = DocsTableUtil.getOriColumn(name, record: record)
                let userIdValue = DocsTableUtil.getOriColumn(userId, record: record)
                let tenantNameValue = DocsTableUtil.getOriColumn(tenantName, record: record)

                guard let userID = userIdValue else {
                    DocsLogger.info("userID is nil")
                    continue
                }

                let dict = ["cn_name": cnNameValue,
                            "en_name": enNameValue,
                            "name": nameValue,
                            "suid": userID,
                            "tenant_name": tenantNameValue]
                let userInfo = UserInfo(userID)
                userInfo.updatePropertiesFromV2(dict as [String: Any])
                users.append(userInfo)
            }
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error)
            DocsLogger.error("获取全部User失败", error: error, component: LogComponents.db)
        }
        return users
    }

    func insert(_ users: [UserInfo]) {
        //频繁的循环插入/删除操作导致内存增加，使用releasePool释放
        for userInfo in users {
            autoreleasepool {
                insert(userInfo)
            }
        }
    }
    
    func insert(_ userInfo: UserInfo) {
        do {
            let insert = table.insert(or: .replace,
                                      self.userId <- userInfo.userID,
                                      self.name <- userInfo.name,
                                      self.cnName <- userInfo.nameCn,
                                      self.enName <- userInfo.nameEn,
                                      self.tenantName <- userInfo.tenantName)
            try db?.run(insert)
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error)
            DocsLogger.error("insert user info to DB failed", error: error, component: LogComponents.db)
        }
    }
    
    func update(_ users: [UserInfo]) {
        delete(users)
        insert(users)
    }

    func delete(_ users: [UserInfo]) {
        do {
            // 分段删除，因为会报错 too many SQL variables
            // https://stackoverflow.com/questions/7106016/too-many-sql-variables-error-in-django-witih-sqlite3
            var userIds = users.compactMap { $0.userID }
            var currentCount = userIds.count
            let sliceMaxCount = 100
            while currentCount > 0 {
                //频繁的循环插入/删除操作导致内存增加，使用releasePool释放
                try autoreleasepool {
                    //找到要删除的
                    let sliceCount = min(sliceMaxCount, currentCount)
                    let sliceToDelete = userIds.prefix(sliceCount)

                    //删除
                    let matched = table.filter(sliceToDelete.contains(userId))
                    try db?.run(matched.delete())

                    //更新
                    userIds.removeFirst(sliceCount)
                    currentCount = userIds.count
                }
            }
        } catch {
            spaceAssertionFailure()
            DocsLogger.error("删除 users  失败", error: error, component: LogComponents.db)
        }
    }
}
