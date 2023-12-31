//
//  ClientVarSqlTableManager+Connection.swift
//  SpaceKit
//
//  Created by chenhuaguan on 2019/12/20.
//

import SKFoundation
import SQLite

extension ClientVarSqlTableManager {

    private func moveLegacyDBFolderIfNeeded() {
        let legacyPath = SKFilePath.legacyCacheDir
        let targetDir = SKFilePath.newCacheDir
        if legacyPath.exists {
            DocsLogger.info("newCache moveLegacyDBFolder start", extraInfo: nil, error: nil, component: LogComponents.newCache)
            let result = legacyPath.moveItem(to: targetDir, overwrite: true)
            DocsLogger.error("newCache moveLegacyDBFolder end= \(result)", extraInfo: nil, error: nil, component: LogComponents.newCache)
        }
    }

    func createWriteConnection() -> Connection? {
        guard let userId = User.current.info?.userID, !userId.isEmpty else {
            DocsLogger.info("create writeConection error", component: LogComponents.newCache)
            return nil
        }
        //如果有旧路径有数据库，先迁移到新路径下
        moveLegacyDBFolderIfNeeded()

        let (_, writeConection) = Connection.getEncryptDatabase(unEncryptPath: SKFilePath.metaSqlitePath, encryptPath: SKFilePath.metaSqlCipherPath, fromsource: .newCache)
        do {
            try writeConection?.execute("PRAGMA journal_mode=WAL;")
        } catch {
            spaceAssertionFailure("journal_mode=WAL Fail")
            DocsLogger.error("journal_mode=WAL Fail", extraInfo: nil, error: error, component: LogComponents.newCache)
        }
        createTablesIfNeeds(connection: writeConection)
        checkAndMigrateDB(connection: writeConection)
        return writeConection
    }

    func createReadConnection() -> Connection? {
        guard let userId = User.current.info?.userID, !userId.isEmpty else {
            DocsLogger.info("create readConnection error", component: LogComponents.newCache)
            return nil
        }
        //如果有旧路径有数据库，先迁移到新路径下
        moveLegacyDBFolderIfNeeded()

        let (_, readConection) = Connection.getEncryptDatabase(unEncryptPath: SKFilePath.metaSqlitePath, encryptPath: SKFilePath.metaSqlCipherPath, readonly: true, fromsource: .newCache)
        return readConection
    }


    private func createTablesIfNeeds(connection: Connection?) {
        if let connection = connection {
            rawDataTable.createIfNotExistWithConnection(connection)
            metaTable.createIfNotExistWithConnection(connection)
            picInfoTable.createIfNotExistWithConnection(connection)
            assetInfoTable.createIfNotExistWithConnection(connection)
        }
    }

    private func checkAndMigrateDB(connection: Connection?) {
        if let db = connection {
            _ = ClientVarSqliteMigrationManager(db: db)
        }
    }
}
