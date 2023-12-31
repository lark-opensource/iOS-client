//
//  ClientVarSqliteMigrationManager.swift
//  SpaceKit
//
//  Created by chenhuaguan on 2019/12/20.
//

import SKFoundation
import SQLiteMigrationManager
import SQLite
import SKInfra

struct ClientVarSqliteMigrationManager {
    private var currentFileDBVersionKey: String {
        UserDefaultKeys.clientVarSqlieVersion + (User.current.info?.userID ?? "unknown")
    }
    var migration: SQLiteMigrationManager!
    private let connection: Connection

    private var currentFileDBVersion: Int64 {
        get {
            let value: Int64? = CCMKeyValue.globalUserDefault.value(forKey: currentFileDBVersionKey)
            DocsLogger.info("get ClientVarSqliteVersion is \(String(describing: value)) for \(currentFileDBVersionKey)", component: LogComponents.newCache)
            return value ?? 0
        }
        set {
            DocsLogger.info("set ClientVarSqliteVersion is \(newValue) for \(currentFileDBVersionKey)", component: LogComponents.newCache)
            CCMKeyValue.globalUserDefault.set(newValue, forKey: currentFileDBVersionKey)
        }
    }

    init(db: Connection) {
        self.connection = db
        let allMigrations = getAllMigrations()
        self.migration = SQLiteMigrationManager(db: db, migrations: allMigrations, bundle: nil)
        if self.migration.hasMigrationsTable() {
            DocsLogger.info("newcache performMigrationIfNeed", component: LogComponents.newCache)
            performMigrationIfNeed()
        } else {
            do {
                DocsLogger.info("newcache createMigrationsTable", component: LogComponents.newCache)
                try self.migration.createMigrationsTable()
                addMissingColumnsIfNeeded()
                if let latestVersion = allMigrations.last?.version {
                    self.currentFileDBVersion = latestVersion
                }
            } catch {
                DocsLogger.error("newcache init db migration error", extraInfo: nil, error: error, component: LogComponents.newCache)
            }
        }
    }

    ///sepcital logic , add the key which miss before add the migrateion table
    func addMissingColumnsIfNeeded() {
        DocsLogger.info("newcache, addMissingColumnsIfNeeded", component: LogComponents.newCache)
        let table = Table(CVSqlDefine.Table.rawData.rawValue)
        //3.16
        let db = connection
        do {
            try db.run(table.addColumn(CVSqlDefine.Rd.dataSize, defaultValue: nil))
            try db.run(table.addColumn(CVSqlDefine.Rd.updateTime, defaultValue: nil))
            try db.run(table.addColumn(CVSqlDefine.Rd.accessTime, defaultValue: nil))
            try db.run(table.addColumn(CVSqlDefine.Rd.needPreload, defaultValue: nil))
            try db.run(table.addColumn(CVSqlDefine.Rd.cacheFrom, defaultValue: nil))
        } catch {
            DocsLogger.error("3.16 addMissingColumnsIfNeeded error", error: error, component: LogComponents.newCache)
        }
    }
    

    func performMigrationIfNeed() {
        guard migration.needsMigration() == true else {
            DocsLogger.info("newCache needsMigration NO", component: LogComponents.newCache)
            return
        }
        DocsLogger.info("newCache hasMigrationsTable() \(String(describing: migration.hasMigrationsTable()))", component: LogComponents.newCache)
        DocsLogger.info("newCache currentVersion()     \(String(describing: migration.currentVersion()))", component: LogComponents.newCache)
        DocsLogger.info("newCache originVersion()      \(String(describing: migration.originVersion()))", component: LogComponents.newCache)
        DocsLogger.info("newCache appliedVersions()    \(String(describing: migration.appliedVersions()))", component: LogComponents.newCache)
        DocsLogger.info("newCache pendingMigrations()  \(String(describing: migration.pendingMigrations()))", component: LogComponents.newCache)
        DocsLogger.info("newCache needsMigration()     \(String(describing: migration.needsMigration()))", component: LogComponents.newCache)

        do {
            try migration.migrateDatabase()
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .cache)
            DocsLogger.error("newCache performMigration error", extraInfo: nil, error: error, component: LogComponents.newCache)
        }
    }

    func getAllMigrations() -> [Migration] {
        var migrations: [Migration] = [MetaSqlMigration1(), MetaSqlMigration2(), MetaSqlMigration3()]
        let currentVersion = self.currentFileDBVersion
        return migrations.sorted { $0.version < $1.version }.filter { $0.version > currentVersion }
    }
}

struct MetaSqlMigration1: ClientVarMigration {
    var version: Int64 = 2019_12_20_19_54
    let docSDKVersion = "3.16.0"
    let reason = "RawData新增dataSize和accessTime字段"
    func migrateDatabase(_ db: Connection) throws {
        DocsLogger.info("newCache start mingraion \(version)", component: LogComponents.newCache)
        let table = Table(CVSqlDefine.Table.rawData.rawValue)
        do {
            try db.run(table.addColumn(CVSqlDefine.Rd.dataSize, defaultValue: nil))
            try db.run(table.addColumn(CVSqlDefine.Rd.updateTime, defaultValue: nil))
            try db.run(table.addColumn(CVSqlDefine.Rd.accessTime, defaultValue: nil))
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .cache)
            DocsLogger.error("newCache Migration error", error: error, component: LogComponents.newCache)
        }
    }
}


struct MetaSqlMigration2: ClientVarMigration {
    var version: Int64 = 2023_03_28_11_35
    let docSDKVersion = "6.2.0"
    let reason = "RawData add needPreload col"
    func migrateDatabase(_ db: Connection) throws {
        DocsLogger.info("newCache start mingraion \(version)", component: LogComponents.newCache)
        let table = Table(CVSqlDefine.Table.rawData.rawValue)
        do {
            try db.run(table.addColumn(CVSqlDefine.Rd.needPreload, defaultValue: nil))
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .cache)
            DocsLogger.error("newCache Migration error", error: error, component: LogComponents.newCache)
        }
    }
}

struct MetaSqlMigration3: ClientVarMigration {
    var version: Int64 = 2023_04_10_17_51
    let docSDKVersion = "6.4.0"
    let reason = "RawData add cacheFrom col"
    func migrateDatabase(_ db: Connection) throws {
        DocsLogger.info("newCache start mingraion \(version)", component: LogComponents.newCache)
        let table = Table(CVSqlDefine.Table.rawData.rawValue)
        do {
            try db.run(table.addColumn(CVSqlDefine.Rd.cacheFrom, defaultValue: nil))
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .cache)
            DocsLogger.error("newCache Migration error", error: error, component: LogComponents.newCache)
        }
    }
}

private protocol ClientVarMigration: Migration {

    /// 这次升级属于哪个版本
    var docSDKVersion: String { get }

    /// 这是升级做了什么事情
    var reason: String { get }
}
