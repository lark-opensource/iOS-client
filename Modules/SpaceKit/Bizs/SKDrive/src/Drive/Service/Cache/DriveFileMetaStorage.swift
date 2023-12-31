//
//  DriveFileMetaStorage.swift
//  SKDrive
//
//  Created by bupozhuang on 2021/12/27.
//

import Foundation
import SKCommon
import SKFoundation
import SQLite
import LarkFileKit

protocol DriveFileMetaStorage {
    typealias Record = DriveCache.Record
    typealias CacheType = DriveCacheService.CacheType
    // 通过token获取对应的文件版本号
    func getVersion(for token: String) throws -> String?
    // 通过token获取所有文件缓存记录
    func getRecords(for token: String) throws -> Set<Record>
    // 通过token和缓存类型获取对应的文件缓存记录，比如只获取离线缓存的record
    func getRecords(for token: String, cacheType: CacheType) throws -> Set<Record>
    func insert(record: Record) throws
    func insert(records: Set<Record>) throws 
    func deleteRecord(_ record: Record) throws
    func insertVersion(_ version: String, with token: String) throws
    func deleteVersion(with token: String) throws
    // 清空所有元数据
    func clean() throws
    func reset()
}
class DriveFileMetaDB: DriveFileMetaStorage {

    enum DBOperateAction: String {
        case migration
        case connectDB
    }
    typealias CacheType = DriveCacheService.CacheType
    typealias Record = DriveCache.Record
    typealias CacheError = DriveCacheService.CacheError
    // 存放配置用文件夹
    static let dbFolderPath = SKFilePath.driveLibraryDir.appendingRelativePath("cache")
    static let dbName = "drive-meta-encrypt.sqlite"

    
    private var database: Connection?
    var dbConnection: Connection? {
        guard database == nil else {
            return database
        }
        database = createConnection()
        return database
    }
    private var recordTable: DriveRecordTable?
    private var tokenVersionMapTable: DriveTokenVersionTable?
        
    // 如果数据库连接失败，应用生命周期内的数据存储到内存，重启后丢失
    /// 记录 token 对应的最新 version，如果使用缓存的接口时没有传version，就会从这里找对应的version
    private var tokenVersionMap: [String: String] = [:]
    /// 记录 token 对应的所有 records，包括不同version、不同类型(preview/origin)的文件
    private var tokenRecordsMap: [String: Set<Record>] = [:]
    /// 记录一条 record 存储在哪个 storageType 内
    private var recordCacheMap: [Record: CacheType] = [:]

    func reset() {
        database = nil
    }
    private func setup(database: Connection) throws {
        let recordTable = DriveRecordTable(connection: database)
        try recordTable.setup()
        self.recordTable = recordTable

        let tokenVersionMapTable = DriveTokenVersionTable(connection: database)
        try tokenVersionMapTable.setup()
        self.tokenVersionMapTable = tokenVersionMapTable
    }
    // 通过token获取对应的文件版本号
    func getVersion(for token: String) throws -> String? {
        guard let dbConnection = dbConnection else {
            DocsLogger.driveInfo("DriveFileMetaStorage.DB ---  db failed use memory data")
            return tokenVersionMap[token]
        }
        guard let table = tokenVersionMapTable else {
            throw CacheError.createTableFailed
        }
        return try table.queryVersion(token: token)
    }
    
    // 通过token获取所有文件缓存记录
    func getRecords(for token: String) throws -> Set<Record> {
        guard let dbConnection = dbConnection else {
            DocsLogger.driveInfo("DriveFileMetaStorage.DB ---  db failed use memory data")
            return try getRecordsFromMemory(for: token)
        }
        guard let table = recordTable else {
            throw CacheError.createTableFailed
        }
        return try table.queryRecords(token: token)
    }
    
    func getRecords(for token: String, cacheType: CacheType) throws -> Set<Record> {
        guard let dbConnection = dbConnection else {
            DocsLogger.driveInfo("DriveFileMetaStorage.DB ---  db failed use memory data")
            return getRecordsFromMemory(for: token, cacheType: cacheType)
        }
        guard let recordTable = recordTable else {
            throw CacheError.createTableFailed
        }
        let records = try recordTable.queryRecords(token: token)
        let results = records.filter { r in
            return r.cacheType == cacheType
        }
        return results
    }

    
    func insert(record: Record) throws {
        guard let dbConnection = dbConnection else {
            DocsLogger.driveInfo("DriveFileMetaStorage.DB ---  db failed use memory data")
            insertToMemory(record: record)
            return
        }
        guard let table = recordTable else {
            throw CacheError.createTableFailed
        }
        var records = Set<Record>()
        records.insert(record)
        try table.insert(records: records)
    }
    
    func insert(records: Set<Record>) throws {
        guard let dbConnection = dbConnection else {
            DocsLogger.driveInfo("DriveFileMetaStorage.DB ---  db failed use memory data")
            insertToMemory(records: records)
            return
        }
        guard let table = recordTable else {
            throw CacheError.createTableFailed
        }
        try table.insert(records: records)
    }
    func deleteRecord(_ record: Record) throws {
        guard let dbConnection = dbConnection else {
            DocsLogger.driveInfo("DriveFileMetaStorage.DB ---  db failed use memory data")
            deleteRecordFromMemory(record)
            return
        }
        guard let table = recordTable else {
            throw CacheError.createTableFailed
        }
        try table.deleteRecord(record: record)

        let token = record.token
        if try getRecords(for: token).isEmpty {
            // 如果 token 对应的所有 records 为空，则清理 token 对应的记录
            try deleteVersion(with: token)
        }
    }
    
    func insertVersion(_ version: String, with token: String) throws {
        guard let dbConnection = dbConnection else {
            DocsLogger.driveInfo("DriveFileMetaStorage.DB ---  db failed use memory data")
            insertVersionToMemory(version, with: token)
            return
        }
        guard let table = tokenVersionMapTable else {
            throw CacheError.createTableFailed
        }
        try table.insert(tokenVersionMap: [token: version])
    }
    
    func insertVersion(tokenVersionMap: [String: String]) throws {
        guard let dbConnection = dbConnection else {
            DocsLogger.driveInfo("DriveFileMetaStorage.DB ---  db failed use memory data")
            for (token, version) in tokenVersionMap {
                insertVersionToMemory(version, with: token)
            }
            return
        }
        guard let table = tokenVersionMapTable else {
            throw CacheError.createTableFailed
        }
        try table.insert(tokenVersionMap: tokenVersionMap)
    }
    
    func deleteVersion(with token: String) throws {
        guard let dbConnection = dbConnection else {
            DocsLogger.driveInfo("DriveFileMetaStorage.DB ---  db failed use memory data")
            deleteVersionFromMemory(with: token)
            return
        }
        guard let table = tokenVersionMapTable else {
            throw CacheError.createTableFailed
        }
        try table.delete(token: token)
    }
    
    func clean() throws {
        try recordTable?.deleteAll()
        try tokenVersionMapTable?.deleteAll()
        tokenVersionMap = [:]
        tokenRecordsMap = [:]
        recordCacheMap = [:]
    }
    
    private func getRecordsFromMemory(for token: String, cacheType: CacheType) -> Set<Record> {
        guard let recordsForToken = tokenRecordsMap[token] else {
            DocsLogger.driveInfo("DriveFileMetaStorage.DB ---  move out manual offline failed, not file found for token", extraInfo: ["token": DocsTracker.encrypt(id: token)])
            return []
        }
        let recordsForType = recordsForToken.filter {
            guard let type = recordCacheMap[$0] else { return false }
            return type == cacheType
        }
        return recordsForType
    }
    
    // 通过token获取所有文件缓存记录
    func getRecordsFromMemory(for token: String) throws -> Set<Record> {
        guard let recordsForToken = tokenRecordsMap[token] else { throw CacheError.recordsNotFound }
        return recordsForToken
    }
    
    func insertToMemory(record: Record) {
        let token = record.token
        var records = tokenRecordsMap[token] ?? []
        records.insert(record)
        tokenRecordsMap[token] = records
        recordCacheMap[record] = record.cacheType
    }
    
    func insertToMemory(records: Set<Record>) {
        for r in records {
           insertToMemory(record: r)
        }
    }
    func deleteRecordFromMemory(_ record: Record) {
        recordCacheMap[record] = nil
        let token = record.token
        guard var records = try? getRecordsFromMemory(for: token) else {
            return
        }
        records.remove(record)
        if records.isEmpty {
            /// 如果 token 对应的所有 records 为空，则清理 token 对应的记录
            tokenRecordsMap[token] = nil
            tokenVersionMap[token] = nil
        } else {
            tokenRecordsMap[token] = records
        }
    }
    func insertVersionToMemory(_ version: String, with token: String) {
        tokenVersionMap[token] = version
    }
    func deleteVersionFromMemory(with token: String) {
        tokenVersionMap[token] = nil
    }
    
    private func reportAction(_ action: DBOperateAction, success: Bool, costTime: Int) {
        var params = [AnyHashable: Any]()
        params["action"] = action.rawValue
        params["is_success"] = success ? 1 : 0
        params["costTime"] = costTime
        #if DEBUG
        DocsLogger.driveInfo("DriveFileMetaStorage.DB --- report \(params.debugDescription)")
        #endif
        DocsTracker.newLog(event: DocsTracker.EventType.driveMetaDBOperate.rawValue, parameters: params)
    }
    
    private func createConnection() -> Connection? {
        guard let userId = User.current.info?.userID, !userId.isEmpty else {
            DocsLogger.driveInfo("DriveFileMetaStorage.DB --- create Conection error")
            return nil
        }
        let dbFolderPath = Self.dbFolderPath.appendingRelativePath(userId)
        dbFolderPath.createDirectoryIfNeeded()
        let dbFilePath = dbFolderPath.appendingRelativePath(Self.dbName)
        let (_, connection) = Connection.getEncryptDatabase(unEncryptPath: nil,
                                                            encryptPath: dbFilePath,
                                                            readonly: false,
                                                            fromsource: .driveMeta)
        var dbError: Error?
        if let db = connection {
            do {
                try setup(database: db)
                reportAction(.connectDB, success: true, costTime: 0)
            } catch {
                spaceAssertionFailure("DriveFileMetaStorage.DB ---  db error when reload data: \(error)")
                database = nil
                try? dbFilePath.removeItem()
                dbError = error
                reportAction(.connectDB, success: false, costTime: 0)
            }
        } else {
            do {
                try dbFilePath.removeItem()
            } catch {
                DocsLogger.error("DriveFileMetaStorage.DB ---  remove db file failed", error: error)
            }
            reportAction(.connectDB, success: false, costTime: 0)
            spaceAssertionFailure("DriveFileMetaStorage.DB ---  db error when get encrypt database")
        }
        DocsLogger.driveInfo("DriveFileMetaStorage.DB ---  storage setup complete")
        return connection
    }
}
