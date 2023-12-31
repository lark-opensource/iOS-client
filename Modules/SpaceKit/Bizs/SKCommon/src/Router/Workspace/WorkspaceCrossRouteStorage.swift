//
//  WorkspaceCrossRouteStorage.swift
//  SKCommon
//
//  Created by Weston Wu on 2022/4/29.
//

import Foundation
import SKFoundation
import SQLite
import SpaceInterface

public struct WorkspaceCrossRouteRecord {
    public let wikiToken: String
    public let objToken: String
    public let objType: DocsType
    public let inWiki: Bool
    // 请求对应的后端 logID
    public let logID: String?

    public init(wikiToken: String, objToken: String, objType: DocsType, inWiki: Bool, logID: String?) {
        self.wikiToken = wikiToken
        self.objToken = objToken
        self.objType = objType
        self.inWiki = inWiki
        self.logID = logID
    }
}

private class WorkspaceCrossRouteRecordTable {
    typealias Record = WorkspaceCrossRouteRecord
    private let id = Expression<Int64>("id")
    private let wikiToken = Expression<String>("wiki_token")
    private let objToken = Expression<String>("obj_token")
    private let objType = Expression<Int>("obj_type")
    private let inWiki = Expression<Bool>("in_wiki")
    private let insertTime = Expression<Date>("insert_at")
    private let logID = Expression<String>("log_id")

    private let db: Connection
    private let table: Table

    private var createTableCMD: String {
        let command = table.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(wikiToken)
            t.column(objToken)
            t.column(objType)
            t.column(inWiki)
            t.column(insertTime)
            t.column(logID)
        }
        return command
    }

    private func createIndex() throws {
        try db.run(table.createIndex(wikiToken, ifNotExists: true))
        try db.run(table.createIndex(objToken, ifNotExists: true))
        try db.run(table.createIndex(insertTime, ifNotExists: true))
    }

    init(connection: Connection, tableName: String = "cross_route_table") {
        db = connection
        table = Table(tableName)
    }

    func setup() throws {
        try db.run(createTableCMD)
        try createIndex()
    }

    func queryOne(wikiToken: String) -> Record? {
        do {
            let query = table.filter(self.wikiToken == wikiToken)
            if let row = try db.pluck(query) {
                return parse(record: row)
            } else {
                return nil
            }
        } catch {
            DocsLogger.error("workspace.crossRouter.DB --- db error query with wikiToken")
            return nil
        }
    }

    func queryOne(objToken: String) -> Record? {
        do {
            let query = table.filter(self.objToken == objToken)
            if let row = try db.pluck(query) {
                return parse(record: row)
            } else {
                return nil
            }
        } catch {
            DocsLogger.error("workspace.crossRouter.DB --- db error query with objToken")
            return nil
        }
    }

    func insert(record: Record) {
        do {
            let query = query(inserting: record)
            try db.run(query)
        } catch {
            DocsLogger.error("workspace.crossRouter.DB --- db error inserting record", error: error)
        }
    }

    func deleteAll() {
        do {
            try db.run(table.delete())
        } catch {
            DocsLogger.error("workspace.crossRouter.DB --- db error deleting all records", error: error)
        }
    }

    func delete(wikiToken: String) {
        do {
            let rows = table.filter(self.wikiToken == wikiToken)
            try db.run(rows.delete())
        } catch {
            DocsLogger.error("workspace.crossRouter.DB --- db error deleting record with wikiToken", error: error)
        }
    }

    func delete(objToken: String) {
        do {
            let rows = table.filter(self.objToken == objToken)
            try db.run(rows.delete())
        } catch {
            DocsLogger.error("workspace.crossRouter.DB --- db error deleting record with objToken", error: error)
        }
    }

    func preload(limit: Int = 100) -> [Record] {
        do {
            let query = table.order(insertTime.desc)
                .limit(limit)
            let rows = try db.prepare(query)
            return rows.map(parse(record:))
        } catch {
            DocsLogger.error("workspace.crossRouter.DB --- db error preloading data", error: error)
            return []
        }
    }

    private func parse(record: Row) -> Record {
        let wikiToken = record[self.wikiToken]
        let objToken = record[self.objToken]
        let objType = DocsType(rawValue: record[self.objType])
        let inWiki = record[self.inWiki]
        let logID = record[self.logID]
        return Record(wikiToken: wikiToken, objToken: objToken, objType: objType, inWiki: inWiki, logID: logID)
    }

    private func query(inserting record: Record) -> Insert {
        return table.insert(or: .replace,
                            wikiToken <- record.wikiToken,
                            objToken <- record.objToken,
                            objType <- record.objType.rawValue,
                            inWiki <- record.inWiki,
                            insertTime <- Date()
        )
    }
}

private class CrossRouteCache {
    typealias Record = WorkspaceCrossRouteRecord
    private var wikiTokenMap: [String: Record] = [:]
    private var objTokenMap: [String: Record] = [:]
    func get(wikiToken: String) -> Record? {
        wikiTokenMap[wikiToken]
    }
    func get(objToken: String) -> Record? {
        objTokenMap[objToken]
    }

    func set(record: Record) {
        wikiTokenMap[record.wikiToken] = record
        objTokenMap[record.objToken] = record
    }

    func delete(wikiToken: String) {
        wikiTokenMap[wikiToken] = nil
        objTokenMap = objTokenMap.filter { (_, record) in
            record.wikiToken != wikiToken
        }
    }

    func delete(objToken: String) {
        objTokenMap[objToken] = nil
        wikiTokenMap = wikiTokenMap.filter { (_, record) in
            record.objToken != objToken
        }
    }

    func deleteAll() {
        wikiTokenMap = [:]
        objTokenMap = [:]
    }
}

public final class WorkspaceCrossRouteStorage {
    public typealias Record = WorkspaceCrossRouteRecord
    // 不区分用户，所有用户共用一个
    private static var dbFolderPath: SKFilePath {
        let path = SKFilePath.globalSandboxWithLibrary
            .appendingRelativePath("workspace")
        path.createDirectoryIfNeeded()
        return path
    }
    private static let dbName = "workspace-cross-route-encrypt.sqlite"

    // 注意只在 DB 线程读写
    private var recordTable: WorkspaceCrossRouteRecordTable?
    // 注意只在主线程读写
    private let cache = CrossRouteCache()

    private let dbQueue = DispatchQueue(label: "workspace.crossRoute.db")

    init() {
        setup()
    }

    private func setup() {
        dbQueue.async { [weak self] in
            guard let self = self else { return }
            guard let table = self.setupDB() else {
                return
            }
            DispatchQueue.main.async { [weak self] in
                self?.recordTable = table
                self?.preload()
            }
        }
    }

    private func setupDB() -> WorkspaceCrossRouteRecordTable? {
        let dbFileURL = Self.dbFolderPath.appendingRelativePath(Self.dbName)
        let (_, connection) = Connection.getEncryptDatabase(unEncryptPath: nil,
                                                            encryptPath: dbFileURL,
                                                            readonly: false,
                                                            fromsource: .workspaceRouteTable)
        guard let connection = connection else {
            try? dbFileURL.removeItem()
            spaceAssertionFailure("workspace.crossRoute.DB --- db error when setup connection")
            return nil
        }
        do {
            try checkDBVersion(db: connection)
            let recordTable = WorkspaceCrossRouteRecordTable(connection: connection)
            try recordTable.setup()
            DocsLogger.info("workspace.crossRoute.DB --- setup complete.")
            return recordTable
        } catch {
            DocsLogger.error("workspace.crossRoute.DB --- table error when setup connection", error: error)
            spaceAssertionFailure("workspace.crossRoute.DB --- db error when setup connection")
            try? dbFileURL.removeItem()
            return nil
        }
    }

    private func preload() {
        guard let table = recordTable else { return }
        dbQueue.async { [weak self] in
            guard let self = self else { return }
            let records = table.preload(limit: 100)
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                records.forEach(self.cache.set(record:))
            }
        }
    }

    // 只请求 cache，并异步从 DB 更新 cache，可能导致首次取不到数据
    public func get(wikiToken: String) -> Record? {
        if let record = cache.get(wikiToken: wikiToken) {
            return record
        }
        guard let table = recordTable else { return nil }
        dbQueue.async { [weak self] in
            guard let self = self,
                  let record = table.queryOne(wikiToken: wikiToken) else {
                return
            }
            DispatchQueue.main.async { [weak self] in
                self?.cache.set(record: record)
            }
        }
        return nil
    }

    public func get(objToken: String) -> Record? {
        if let record = cache.get(objToken: objToken) {
            return record
        }
        guard let table = recordTable else { return nil }
        dbQueue.async { [weak self] in
            guard let self = self,
                  let record = table.queryOne(objToken: objToken) else {
                return
            }
            DispatchQueue.main.async { [weak self] in
                self?.cache.set(record: record)
            }
        }
        return nil
    }

    /*
    // block 当前线程的同步 get 方法，顺序请求 cache - DB
    public func syncGet(wikiToken: String) -> Record? {
        if let record = cache.get(wikiToken: wikiToken) {
            return record
        }
        guard let table = recordTable else { return nil }
        let record = dbQueue.sync { table.queryOne(wikiToken: wikiToken) }
        guard let record = record else { return nil }
        cache.set(record: record)
        return record
    }

    public func syncGet(objToken: String) -> Record? {
        if let record = cache.get(objToken: objToken) {
            return record
        }
        guard let table = recordTable else { return nil }
        let record = dbQueue.sync { table.queryOne(objToken: objToken) }
        guard let record = record else { return nil }
        cache.set(record: record)
        return record
    }

    // 异步 get 方法，顺序请求 cache - DB
    public func asyncGet(wikiToken: String, completion: @escaping (Record?) -> Void) {
        if let record = cache.get(wikiToken: wikiToken) {
            completion(record)
            return
        }
        guard let table = recordTable else {
            completion(nil)
            return
        }
        dbQueue.async { [weak self] in
            guard let self = self,
                  let record = table.queryOne(wikiToken: wikiToken) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            DispatchQueue.main.async { [weak self] in
                self?.cache.set(record: record)
                completion(nil)
            }
        }
    }

    public func asyncGet(objToken: String, completion: @escaping (Record?) -> Void) {
        if let record = cache.get(objToken: objToken) {
            completion(record)
            return
        }
        guard let table = recordTable else {
            completion(nil)
            return
        }
        dbQueue.async { [weak self] in
            guard let self = self,
                  let record = table.queryOne(objToken: objToken) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            DispatchQueue.main.async { [weak self] in
                self?.cache.set(record: record)
                completion(nil)
            }
        }
    }
     */

    // 发生用户可感知的重定向时，调用此方法更新 DB 并上报埋点
    public func notifyRedirect(record: Record) {
        // 埋点
        dbQueue.async { [weak self] in
            guard let self = self else { return }
            if let dbRecord = self.recordTable?.queryOne(wikiToken: record.wikiToken) {
                if dbRecord.inWiki == record.inWiki {
                    // DB 有数据，且数据正确，上报 missCache
                    WorkspaceTracker.reportWorkspaceRedirectEvent(record: record, reason: .missCache)
                } else {
                    // DB 有数据，但数据错误，上报 wrongCache
                    WorkspaceTracker.reportWorkspaceRedirectEvent(record: record, reason: .wrongCache)
                }
            } else {
                // DB 没数据，上报 noCache
                WorkspaceTracker.reportWorkspaceRedirectEvent(record: record, reason: .noCache)
            }
        }
        // 更新 DB
        set(record: record)
    }

    // 预加载场景等需要更新 DB，调用此方法，不会上报埋点
    public func set(record: Record) {
        // memory
        if record.inWiki {
            cache.delete(objToken: record.objToken)
        } else {
            cache.delete(wikiToken: record.wikiToken)
        }
        cache.set(record: record)

        // DB
        dbQueue.async { [weak self] in
            guard let table = self?.recordTable else { return }
            if record.inWiki {
                table.delete(objToken: record.objToken)    
            } else {
                table.delete(wikiToken: record.wikiToken)
            }
            table.insert(record: record)
        }
    }

    public func delete(wikiToken: String) {
        cache.delete(wikiToken: wikiToken)
        dbQueue.async { [weak self] in
            self?.recordTable?.delete(wikiToken: wikiToken)
        }
    }

    public func delete(objToken: String) {
        cache.delete(objToken: objToken)
        dbQueue.async { [weak self] in
            self?.recordTable?.delete(objToken: objToken)
        }
    }

    public func deleteAll() {
        DispatchQueue.main.async { [weak self] in
            self?.cache.deleteAll()
            self?.dbQueue.async {
                self?.recordTable?.deleteAll()
            }
        }
    }
}

extension WorkspaceCrossRouteStorage {
    private func checkDBVersion(db: Connection) throws {
        if db.dbVersion == 0 {
            try db.run(Table("cross_route_table").drop(ifExists: true))
            db.dbVersion = 1
        }

        // 数据库版本降低
        if db.dbVersion > 1 {
            db.dbVersion = 0
            try checkDBVersion(db: db)
        }
    }
}

extension Connection {
    fileprivate var dbVersion: Int32 {
        get {
            do {
                return Int32(try scalar("PRAGMA user_version") as? Int64 ?? 0)
            } catch {
                DocsLogger.error("workspace.storage --- get db version error", error: error)
                return 0
            }
        }
        set {
            do {
                try run("PRAGMA user_version = \(newValue)")
            } catch {
                DocsLogger.error("workspace.storage --- set db version error", error: error)
            }
        }
    }
}
