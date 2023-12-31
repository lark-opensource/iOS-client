//
//  BTUploadAttachCacheManager.swift
//  SKBitable
//
//  Created by ByteDance on 2022/10/16.
//

import SKFoundation
import SQLite
import SKCommon

public protocol BTUploadAttachCacheCleanable {
    func userDidLogout()
    func clean()
}

final class BTUploadAttachCacheManager {
    let tableName = "Bitable_uploading_attachInfo"
    static let shared: BTUploadAttachCacheManager = BTUploadAttachCacheManager()
    var writeQueue = DispatchQueue(label: "com.bytedance.net.btCache.attach.write")
    lazy var table: BTUploadingAttachInfoTable = BTUploadingAttachInfoTable()
    private let connectLock = NSLock()
    private var _writeConection: Connection?
    var writeConection: Connection? {
        connectLock.lock()
        defer {
            connectLock.unlock()
        }
        guard _writeConection == nil else {
            return _writeConection
        }
        _writeConection = createWriteConnection()
        return _writeConection
    }

    private var _readConnection: Connection?
    var readConnection: Connection? {
        //需要先创建writeConection，因为需要数据库升级
        _ = writeConection

        connectLock.lock()
        defer {
            connectLock.unlock()
        }
        guard _readConnection == nil else {
            return _readConnection
        }
        _readConnection = createReadConnection()
        return _readConnection
    }
    func createWriteConnection() -> Connection? {
        guard UserScopeNoChangeFG.ZYZ.btUploadAttachRestorable else {
            DocsLogger.info("[ACTION] resume task disable", component: LogComponents.btUploadCache)
            return nil
        }
        guard let userId = User.current.info?.userID, !userId.isEmpty else {
            DocsLogger.info("create writeConection error", component: LogComponents.btUploadCache)
            return nil
        }

        let (_, writeConection) = Connection.getEncryptDatabase(unEncryptPath: nil,
                                                                encryptPath: SKFilePath.bitableUploadAttachCacheDir, fromsource: .btUploadCache)
        do {
            try writeConection?.execute("PRAGMA journal_mode=WAL;")
        } catch {
            spaceAssertionFailure("journal_mode=WAL Fail")
            DocsLogger.error("journal_mode=WAL Fail", extraInfo: nil, error: error, component: LogComponents.btUploadCache)
        }
        createTablesIfNeeds(connection: writeConection)
        return writeConection
    }

    func createReadConnection() -> Connection? {
        guard UserScopeNoChangeFG.ZYZ.btUploadAttachRestorable else {
            DocsLogger.info("[ACTION] resume task disable", component: LogComponents.btUploadCache)
            return nil
        }
        guard let userId = User.current.info?.userID, !userId.isEmpty else {
            DocsLogger.info("create readConnection error", component: LogComponents.btUploadCache)
            return nil
        }

        let (_, readConection) = Connection.getEncryptDatabase(unEncryptPath: nil, encryptPath: SKFilePath.bitableUploadAttachCacheDir, readonly: true, fromsource: .btUploadCache)
        return readConection
    }
    
    func getUploadingAttachInfos(with originBaseID: String, tableID: String = "") -> [BTUploadingAttachInfo] {
        guard let readConnection = self.readConnection else {
            DocsLogger.error("getUploadingAttachInfos, readConnection.isNil", component: LogComponents.btUploadCache)
            return []
        }
        let infos = self.table.getUploadingAttachInfos(with: originBaseID, tableID: tableID, db: readConnection)
        return infos
    }
    
    func insert(location: BTFieldLocation, mediaInfo: BTUploadMediaHelper.MediaInfo, uploadKey: String) {
        writeQueue.async {
            guard let writeConection = self.writeConection else {
                DocsLogger.error("getUploadingAttachInfos, writeConection.isNil", component: LogComponents.btUploadCache)
                return
            }
            
            self.table.insert(location: location,
                              mediaInfo: mediaInfo,
                              uploadKey: uploadKey,
                              db: writeConection)
        }
    }
    
    func delete(with baseOriginID: String, uploadKey: String) {
        writeQueue.async {
            guard let writeConection = self.writeConection else {
                DocsLogger.error("getUploadingAttachInfos, writeConection.isNil", component: LogComponents.btUploadCache)
                return
            }
            
            self.table.delete(with: baseOriginID, uploadaKey: uploadKey, db: writeConection)
        }
    }
    
    private func createTablesIfNeeds(connection: Connection?) {
        if let connection = connection {
            table.createIfNotExistWithConnection(name: tableName, connection: connection)
        }
    }
}

extension BTUploadAttachCacheManager: BTUploadAttachCacheCleanable {
    func clean() {
        writeQueue.async {
            guard let writeConection = self.writeConection else {
                DocsLogger.error("getUploadingAttachInfos, writeConection.isNil", component: LogComponents.btUploadCache)
                return
            }
            self.table.deleteAll(db: writeConection)
        }
    }
    
    // 切换租户重置connection
    func userDidLogout() {
        connectLock.lock()
        defer {
            connectLock.unlock()
        }
        _writeConection = nil
        _readConnection = nil
    }
}
