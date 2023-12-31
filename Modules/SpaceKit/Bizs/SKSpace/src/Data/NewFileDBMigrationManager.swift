//
//  FileDBMigrationManager.swift
//  SpaceKit
//
//  Created by huahuahu on 2018/7/22.
//

import Foundation
import SQLiteMigrationManager
import SQLite
import SKFoundation
import SKCommon
import SKInfra

struct NewFileDBMigrationManager {
    var migration: SQLiteMigrationManager!
    private let connection: Connection

    private var currentFileDBVersion: Int64 {
        get {
            // 处理兼容逻辑，数据库未分用户存储时，字段的值
            let userStorage = CCMKeyValue.userDefault(User.current.info?.userID ?? "unknown")
            if let noUserIdValue: Int64 = CCMKeyValue.globalUserDefault.value(forKey: UserDefaultKeys.newCurrentFileDBVersionKey) {
                CCMKeyValue.globalUserDefault.removeObject(forKey: UserDefaultKeys.newCurrentFileDBVersionKey)
                DocsLogger.info("get legacy currentFileDBVersion is \(noUserIdValue)", component: LogComponents.db)
                userStorage.set(noUserIdValue, forKey: UserDefaultKeys.newCurrentFileDBVersionKey)
                return noUserIdValue
            }

            if let value: Int64 = userStorage.value(forKey: UserDefaultKeys.newCurrentFileDBVersionKey) {
                DocsLogger.info("get new currentFileDBVersion is \(value)", component: LogComponents.db)
                return value
            } else {
                DocsLogger.info("get new currentFileDBVersion is 0 for", component: LogComponents.db)
                return 0
            }
        }
        set {
            DocsLogger.info("set new currentFileDBVersion is \(newValue)", component: LogComponents.db)
            let userStorage = CCMKeyValue.userDefault(User.current.info?.userID ?? "unknown")
            userStorage.set(newValue, forKey: UserDefaultKeys.newCurrentFileDBVersionKey)
        }
    }

    init(db: Connection) {
        self.connection = db
        let allMigrations = getAllMigrations()
        self.migration = SQLiteMigrationManager(db: db, migrations: allMigrations, bundle: nil)
        if self.migration.hasMigrationsTable() {
            DocsLogger.info("performMigrationIfNeed", component: LogComponents.db)
            performMigrationIfNeed()
        } else {
            do {
                DocsLogger.info("createMigrationsTable", component: LogComponents.db)
                try self.migration.createMigrationsTable()
                if let latestVersion = allMigrations.last?.version {
                    self.currentFileDBVersion = latestVersion
                }
            } catch {
                DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .fileListMigrationCreate)
                DocsLogger.error("init db migration error", extraInfo: nil, error: error, component: nil)
            }
        }
        addMissingColumnsIfNeeded()
    }

    func performMigrationIfNeed() {
        guard migration.needsMigration() == true else {
            DocsLogger.info("needsMigration NO", component: LogComponents.db)
            return
        }
        DocsLogger.info("hasMigrationsTable() \(String(describing: migration.hasMigrationsTable()))")
        DocsLogger.info("currentVersion()     \(String(describing: migration.currentVersion()))")
        DocsLogger.info("originVersion()      \(String(describing: migration.originVersion()))")
        DocsLogger.info("appliedVersions()    \(String(describing: migration.appliedVersions()))")
        DocsLogger.info("pendingMigrations()  \(String(describing: migration.pendingMigrations()))")
        DocsLogger.info("needsMigration()     \(String(describing: migration.needsMigration()))")
        do {
            try migration.migrateDatabase()
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .fileListMigrationUpdate)
            DocsLogger.error("performMigration error", extraInfo: nil, error: error, component: LogComponents.db)
        }
    }

    func getAllMigrations() -> [Migration] {
        let migrations: [Migration] = [FileEntryMigration1(),
                                       FileEntryMigration2(),
                                       FileEntryMigration3(),
                                       FileEntryMigration4(),
                                       FileEntryMigration5(),
                                       FileEntryMigration6(),
                                       FileEntryMigration7(),
                                       FileEntryMigration8(),
                                       FileEntryMigration9(),
                                       FileEntryMigration10(),
                                       FileEntryMigration11(),
                                       FileEntryMigration12(),
                                       FileEntryMigration13(),
                                       FileEntryMigration14()
        ]
        let currentVersion = self.currentFileDBVersion
        return migrations.sorted { $0.version < $1.version }.filter { $0.version > currentVersion }
    }

//    https://bytedance.feishu.cn/space/doc/doccnXUjMVDT9PPpcOlCgdjPVCg#pmK0uf
    func addMissingColumnsIfNeeded() {
        if CCMKeyValue.globalUserDefault.bool(forKey: UserDefaultKeys.missingDBMigrationHasBeenAmendedV3) {
            return
        }
        CCMKeyValue.globalUserDefault.set(true, forKey: UserDefaultKeys.missingDBMigrationHasBeenAmendedV3)
        DocsLogger.info("addMissingColumnsIfNeeded")
        let table = Table("FileEntries")
        let nodeTokenTreeTable = Table("NodeTokenTree")
        let nodeToObjTokenMapTable = Table("nodeToObjTokenMap")
        let specialTokenTable = Table("SpecialToken")


        //3.8
        let db = connection
        do {
            try db.run(table.addColumn(Expression<Bool?>(ManualOfflineFile.isSetManuOfflineKey), defaultValue: false))
            try db.run(table.addColumn(Expression<Int64>(ManualOfflineFile.fileSizeKey), defaultValue: 0))
            try db.run(table.addColumn(Expression<Bool?>(ManualOfflineFile.hadShownManuStatusKey), defaultValue: false))
            try db.run(table.addColumn(Expression<TimeInterval?>(ManualOfflineFile.addManuOfflineTimeKey), defaultValue: nil))

        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .fileListMigrationAddMiss)
            DocsLogger.error("3.8 Migration error", extraInfo: ["version": "additional amend", "table": "FileEntries"], error: error, component: LogComponents.db)
        }
        //3.11
        do {
            try db.run(table.addColumn(Expression<Int?>(FileListServerKeys.shareVersion.rawValue), defaultValue: nil))
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .fileListMigrationAddMiss)
            DocsLogger.error("3.11 Migration error", extraInfo: ["version": "additional amend", "table": "FileEntries"], error: error, component: LogComponents.db)
        }
        //3.13
        do {
            try db.run(table.addColumn(Expression<String?>(FileListServerKeys.thumbnailExtra.rawValue), defaultValue: nil))
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .fileListMigrationAddMiss)
            DocsLogger.error("3.13 Migration error ", extraInfo: ["version": "additional amend", "table": "FileEntries"], error: error, component: LogComponents.db)
        }
        //3.19
        do {
            try db.run(table.addColumn(Expression<String?>(FileListServerKeys.iconKey.rawValue), defaultValue: nil))
            try db.run(table.addColumn(Expression<Int?>(FileListServerKeys.iconType.rawValue), defaultValue: nil))
            try db.run(table.addColumn(Expression<String?>(FileListServerKeys.iconFSUnit.rawValue), defaultValue: nil))
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .fileListMigrationAddMiss)
            DocsLogger.error("3.19 Migration error ", extraInfo: ["version": "additional amend", "table": "FileEntries"], error: error, component: LogComponents.db)
        }
        
        // 3.24
        do {
            try db.run(table.addColumn(Expression<Int?>(ManualOfflineFile.syncStatusKey), defaultValue: nil))
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .fileListMigrationAddMiss)
            DocsLogger.error("3.24 Migration error ", extraInfo: ["version": "additional amend", "table": "FileEntries"], error: error, component: LogComponents.db)
        }

        //3.47
        do {
            try db.run(table.addColumn(Expression<Int?>(FileListServerKeys.ownerType.rawValue), defaultValue: nil))
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .fileListMigrationAddMiss)
            DocsLogger.error("3.47 Migration error", extraInfo: ["version": "additional amend", "table": "FileEntries"], error: error, component: LogComponents.db)
        }

        //4.2.0
        do {
            try db.run(table.addColumn(Expression<Int?>(FileListServerKeys.nodeType.rawValue), defaultValue: 0))
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .fileListMigrationAddMiss)
            DocsLogger.error("4.2 Migration error", extraInfo: ["version": "additional amend", "table": "FileEntries"], error: error, component: LogComponents.db)
        }

        do {
            try db.run(nodeTokenTreeTable.addColumn(Expression<Int?>(FileListServerKeys.nodeType.rawValue), defaultValue: 0))
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .fileListMigrationAddMiss)
            DocsLogger.error("4.2 Migration error", extraInfo: ["version": "additional amend", "table": "nodeTokenTreeTable"], error: error, component: LogComponents.db)
        }

        do {
            try db.run(nodeToObjTokenMapTable.addColumn(Expression<Int?>(FileListServerKeys.nodeType.rawValue), defaultValue: 0))
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .fileListMigrationAddMiss)
            DocsLogger.error("4.2 Migration error", extraInfo: ["version": "additional amend", "table": "nodeToObjTokenMapTable"], error: error, component: LogComponents.db)
        }

        do {
            try db.run(specialTokenTable.addColumn(Expression<Int?>(FileListServerKeys.nodeType.rawValue), defaultValue: 0))
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .fileListMigrationAddMiss)
            DocsLogger.error("4.2 Migration error", extraInfo: ["version": "additional amend", "table": "specialTokenTable"], error: error, component: LogComponents.db)
        }

    }
}

struct FileEntryMigration1: DocsMigration {
    var version: Int64 = 2019_08_26_19_54

    let docSDKVersion = "3.8.0"
    let reason = "新增fileEntry 的  manu_set_Offline 字段"
    func migrateDatabase(_ db: Connection) throws {
        DocsLogger.info("start mingraion \(version)", component: LogComponents.db)
        let table = Table("FileEntries")
        do {
            try db.run(table.addColumn(Expression<Bool?>(ManualOfflineFile.isSetManuOfflineKey), defaultValue: false))
            try db.run(table.addColumn(Expression<Int64>(ManualOfflineFile.fileSizeKey), defaultValue: 0))
            try db.run(table.addColumn(Expression<Bool?>(ManualOfflineFile.hadShownManuStatusKey), defaultValue: false))
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .fileListMigrationProgress)
            DocsLogger.error("Migration error", extraInfo: ["version": version, "table": "FileEntries"], error: error, component: LogComponents.db)
        }
    }
}

struct FileEntryMigration2: DocsMigration {
    /// 用于隔了几天，中间有内测群的人安装了3.8.0，为了避免他们需要卸载重装，新增一个
    var version: Int64 = 2019_08_30_17_34

    let docSDKVersion = "3.8.0"
    let reason = "新增fileEntry 的  add_manu_offline_time 字段，为了离线列表页排序用"
    func migrateDatabase(_ db: Connection) throws {
        DocsLogger.info("start mingraion \(version)", component: LogComponents.db)
        let table = Table("FileEntries")
        do {
            try db.run(table.addColumn(Expression<TimeInterval?>(ManualOfflineFile.addManuOfflineTimeKey), defaultValue: nil))
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .fileListMigrationProgress)
            DocsLogger.error("Migration error", extraInfo: ["version": version, "table": "FileEntries"], error: error, component: LogComponents.db)
        }
    }
}

struct FileEntryMigration3: DocsMigration {

    var version: Int64 = 2019_10_18_18_30

    let docSDKVersion = "3.11.0"
    let reason = "新增fileEntry 的  shareVersion 字段，为了区分新旧共享文件夹"
    func migrateDatabase(_ db: Connection) throws {
        DocsLogger.info("start mingraion \(version)", component: LogComponents.db)
        let table = Table("FileEntries")
        do {//Expression<Int?>(FileListServerKeys.shareVersion.rawValue)
            try db.run(table.addColumn(Expression<Int?>(FileListServerKeys.shareVersion.rawValue), defaultValue: nil))
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .fileListMigrationProgress)
            DocsLogger.error("Migration error", extraInfo: ["version": version, "table": "FileEntries"], error: error, component: LogComponents.db)
        }
    }
}

struct FileEntryMigration4: DocsMigration {

    var version: Int64 = 2019_11_07_17_55

    let docSDKVersion = "3.13.0"
    let reason = "新增fileEntry 的  thumbnailExtra 字段，网格视图的缩略图加密等信息"
    func migrateDatabase(_ db: Connection) throws {
        DocsLogger.info("start mingraion \(version)", component: LogComponents.db)
        let table = Table("FileEntries")
        do {
            try db.run(table.addColumn(Expression<String?>(FileListServerKeys.thumbnailExtra.rawValue), defaultValue: nil))
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .fileListMigrationProgress)
            DocsLogger.error("Migration error", extraInfo: ["version": version, "table": "FileEntries"], error: error, component: LogComponents.db)
        }
    }
}

struct FileEntryMigration5: DocsMigration {

    var version: Int64 = 2020_02_07_17_47

    let docSDKVersion = "3.19.0"
    let reason = "新增fileEntry 的  iconKey, iconType, iconFSUnit 字段"
    func migrateDatabase(_ db: Connection) throws {
        DocsLogger.info("start mingraion \(version)", component: LogComponents.db)
        let table = Table("FileEntries")
        do {
            try db.run(table.addColumn(Expression<String?>(FileListServerKeys.iconKey.rawValue), defaultValue: nil))
            try db.run(table.addColumn(Expression<Int?>(FileListServerKeys.iconType.rawValue), defaultValue: nil))
            try db.run(table.addColumn(Expression<String?>(FileListServerKeys.iconFSUnit.rawValue), defaultValue: nil))

        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .fileListMigrationProgress)
            DocsLogger.error("Migration error", extraInfo: ["version": version, "table": "FileEntries"], error: error, component: LogComponents.db)
        }
    }
}

struct FileEntryMigration6: DocsMigration {
    var version: Int64 = 2020_04_22_14_59

    let docSDKVersion = "3.24.0"
    let reason = "新增fileEntry 的 manuOfflineSyncStatus 字段"
    func migrateDatabase(_ db: Connection) throws {
        DocsLogger.info("start mingraion \(version)", component: LogComponents.db)
        let table = Table("FileEntries")
        do {
            try db.run(table.addColumn(Expression<Int?>(ManualOfflineFile.syncStatusKey), defaultValue: nil))
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .fileListMigrationProgress)
            DocsLogger.error("Migration error", extraInfo: ["version": version, "table": "FileEntries"], error: error, component: LogComponents.db)
        }
    }

}

struct FileEntryMigration7: DocsMigration {
    var version: Int64 = 2021_03_31_14_59

    let docSDKVersion = "3.47.0"
    let reason = "新增fileEntry 的 ownerType 字段"
    func migrateDatabase(_ db: Connection) throws {
        DocsLogger.info("start mingraion \(version)", component: LogComponents.db)
        let table = Table("FileEntries")
        do {
            try db.run(table.addColumn(Expression<Int?>(FileListServerKeys.ownerType.rawValue), defaultValue: nil))
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .fileListMigrationProgress)
            DocsLogger.error("Migration error", extraInfo: ["version": version, "table": "FileEntries"], error: error, component: LogComponents.db)
        }
    }
}

struct FileEntryMigration8: DocsMigration {
    var version: Int64 = 2021_05_26_14_59

    let docSDKVersion = "4.2.0"
    let reason = "新增fileEntry NodeTokenTree nodeToObjTokenMap SpecialToken 的 node_type 字段"
    func migrateDatabase(_ db: Connection) throws {
        DocsLogger.info("start mingraion \(version)", component: LogComponents.db)
        let table = Table("FileEntries")
        let nodeTokenTreeTable = Table("NodeTokenTree")
        let nodeToObjTokenMapTable = Table("nodeToObjTokenMap")
        let specialTokenTable = Table("SpecialToken")
        do {
            try db.run(table.addColumn(Expression<Int?>(FileListServerKeys.nodeType.rawValue), defaultValue: nil))
            try db.run(nodeTokenTreeTable.addColumn(Expression<Int?>(FileListServerKeys.nodeType.rawValue), defaultValue: nil))
            try db.run(nodeToObjTokenMapTable.addColumn(Expression<Int?>(FileListServerKeys.nodeType.rawValue), defaultValue: nil))
            try db.run(specialTokenTable.addColumn(Expression<Int?>(FileListServerKeys.nodeType.rawValue), defaultValue: nil))
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .fileListMigrationProgress)
            DocsLogger.error("Migration error", extraInfo: ["version": version, "table": "FileEntries"], error: error, component: LogComponents.db)
        }
    }
}

struct FileEntryMigration9: DocsMigration {
    var version: Int64 = 2021_11_26_14_59

    let docSDKVersion = "5.3.0"
    let reason = "SpaceEntry 新增密级标签 secureLabelName 字段"
    func migrateDatabase(_ db: Connection) throws {
        DocsLogger.info("start mingraion \(version)", component: LogComponents.db)
        let table = Table("FileEntries")
        do {
            try db.run(table.addColumn(Expression<String?>(FileListServerKeys.secureLabelName.rawValue), defaultValue: nil))
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .fileListMigrationProgress)
            DocsLogger.error("Migration error", extraInfo: ["version": version, "table": "FileEntries"], error: error, component: LogComponents.db)
        }
    }
}

struct FileEntryMigration10: DocsMigration {
    var version: Int64 = 2022_01_17_19_57

    let docSDKVersion = "5.7.0"
    let reason = "SpaceEntry 新增秘钥删除 secretKeyDelete 字段"
    func migrateDatabase(_ db: Connection) throws {
        DocsLogger.info("start mingraion \(version)", component: LogComponents.db)
        let table = Table("FileEntries")
        let shortcutTable = Table("ShortCutFileEntriesTable")
        do {
            try db.run(table.addColumn(Expression<Bool?>(FileListServerKeys.secretKeyDelete.rawValue), defaultValue: nil))
            try db.run(shortcutTable.addColumn(Expression<Bool?>(FileListServerKeys.secretKeyDelete.rawValue), defaultValue: nil))
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .fileListMigrationProgress)
            DocsLogger.error("Migration error", extraInfo: ["version": version, "table": "FileEntries"], error: error, component: LogComponents.db)
        }
    }
}

struct FileEntryMigration11: DocsMigration {
    var version: Int64 = 2022_07_06_16_40

    let docSDKVersion = "5.18.0"
    let reason = "SpaceEntry 新增 workspace 互通 obj_node_token 和 obj_biz_type 字段"
    func migrateDatabase(_ db: Connection) throws {
        DocsLogger.info("start mingraion \(version)", component: LogComponents.db)
        let table = Table("FileEntries")
        let shortcutTable = Table("ShortCutFileEntriesTable")
        do {
            try db.run(table.addColumn(Expression<Int?>(FileListServerKeys.objBizType.rawValue), defaultValue: nil))
            try db.run(table.addColumn(Expression<String?>(FileListServerKeys.bizNodeToken.rawValue), defaultValue: nil))
            try db.run(shortcutTable.addColumn(Expression<Int?>(FileListServerKeys.objBizType.rawValue), defaultValue: nil))
            try db.run(shortcutTable.addColumn(Expression<String?>(FileListServerKeys.bizNodeToken.rawValue), defaultValue: nil))
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .fileListMigrationProgress)
            DocsLogger.error("Migration error", extraInfo: ["version": version, "table": "FileEntries"], error: error, component: LogComponents.db)
        }
    }
}

struct FileEntryMigration12: DocsMigration {
    var version: Int64 = 2023_06_08_14_25
    
    let docSDKVersion: String = "6.8.0"
    let reason: String = "SpaceEntry add realToken field for using objToken can find real wikiEntry"
    func migrateDatabase(_ db: Connection) throws {
        DocsLogger.info("start mingraion \(version)", component: LogComponents.db)
        let table = Table("FileEntries")
        do {
            try db.run(table.addColumn(Expression<String>(FileListNativeKeys.realToken.rawValue), defaultValue: ""))
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .fileListMigrationProgress)
            DocsLogger.error("Migration error", extraInfo: ["version": version, "table": "FileEntries"], error: error, component: LogComponents.db)
        }
    }
}

struct FileEntryMigration13: DocsMigration {
    var version: Int64 = 2023_07_06_15_25

    let docSDKVersion: String = "6.10.0"
    let reason: String = "SpaceEntry add star_time field for subtitle in favorite list"
    func migrateDatabase(_ db: Connection) throws {
        DocsLogger.info("start mingraion \(version)", component: LogComponents.db)
        let table = Table("FileEntries")
        do {
            try db.run(table.addColumn(Expression<TimeInterval?>(FileListServerKeys.favoriteTime.rawValue),
                                       defaultValue: nil))
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .fileListMigrationProgress)
            DocsLogger.error("Migration error", extraInfo: ["version": version, "table": "FileEntries"], error: error, component: LogComponents.db)
        }
    }
}

struct FileEntryMigration14: DocsMigration {
    var version: Int64 = 2023_07_19_14_58

    let docSDKVersion: String = "6.10.0"
    let reason: String = "SpaceEntry add icon_info field for subtitle in favorite list"
    func migrateDatabase(_ db: Connection) throws {
        DocsLogger.info("start mingraion \(version)", component: LogComponents.db)
        let table = Table("FileEntries")
        do {
            try db.run(table.addColumn(Expression<String?>(FileListServerKeys.iconInfo.rawValue),
                                       defaultValue: nil))
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .fileListMigrationProgress)
            DocsLogger.error("Migration error", extraInfo: ["version": version, "table": "FileEntries"], error: error, component: LogComponents.db)
        }
    }
}

private protocol DocsMigration: Migration {

    /// 这次升级属于哪个版本
    var docSDKVersion: String { get }

    /// 这是升级做了什么事情
    var reason: String { get }
}
