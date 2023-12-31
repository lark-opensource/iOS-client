//
//  DriveRecordTable.swift
//  SKDrive
//
//  Created by bupozhuang on 2021/12/28.
//

import Foundation
import SKCommon
import SKFoundation
import SQLite

class DriveRecordTable {
    typealias Record = DriveCache.Record
    typealias CacheType = DriveCacheService.CacheType
    private let recordID = Expression<String>("record_id")
    private let token = Expression<String>("token")
    private let version = Expression<String>("version")
    private let recordType = Expression<String>("record_type")
    private let originName = Expression<String>("origin_name")
    private let originFileSize = Expression<Int64?>("origin_file_size")
    private let fileType = Expression<String?>("file_type")
    private let cacheType = Expression<String>("cache_type")
    
    private let db: Connection
    private let table: Table
    
    private var createTableCMD: String {
        let command = table.create(ifNotExists: true) { t in
            t.column(recordID, primaryKey: true)
            t.column(token)
            t.column(version)
            t.column(recordType)
            t.column(originName)
            t.column(originFileSize)
            t.column(fileType)
            t.column(cacheType)
        }
        return command
    }
    
    init(connection: Connection, tableName: String = "drive_records") {
        db = connection
        table = Table(tableName)
    }
    
    func setup() throws {
        try db.run(createTableCMD)
    }
        
    func insert(records: Set<DriveCache.Record>) throws {
        do {
            try db.transaction {
                for record in records {
                    let query = insertQuery(record)
                    try db.run(query)
                }
            }
        } catch {
            DocsLogger.error("DriveFileMetaStorage.DB ---  db error when insert Record", error: error)
            throw error
        }
    }
    
    func deleteAll() throws {
        do {
            try db.run(table.delete())
        } catch {
            DocsLogger.error("DriveFileMetaStorage.DB ---  db error when delete all records", error: error)
            throw error
        }
    }

    func deleteRecord(record: Record) throws {
        do {
            let rows = table.filter(self.recordID == record.fileID)
            try db.run(rows.delete())
        } catch {
            DocsLogger.error("DriveFileMetaStorage.DB ---  db error when delete record",
                             extraInfo: ["token": DocsTracker.encrypt(id: record.token)],
                             error: error)
            throw error
        }
    }
    
    func queryRecords(token: String) throws -> Set<Record> {
        var records: Set<Record> = []
        do {
            let rows = try db.prepare(table.where(self.token == token))
            for r in rows {
                let record = parse(record: r)
                records.insert(record)
            }
            DocsLogger.driveInfo("DriveFileMetaStorage.DB ---  records count \(records.count)")
            return records
        } catch {
            spaceAssertionFailure("DriveFileMetaStorage.DB ---  db error when get all records \(error)")
            throw error
        }
    }
    
    private func parse(record: Row) -> Record {
        let token = record[self.token]
        let version = record[self.version]
        let recordType = DriveCacheType(with: record[self.recordType])
        let originName = record[self.originName]
        let fileType = record[self.fileType]
        let sizeUInt64: UInt64?
        if let originFileSize = record[self.originFileSize] {
            sizeUInt64 = UInt64(exactly: originFileSize)
        } else {
            sizeUInt64 = nil
        }
        
        let cacheTypeString = record[self.cacheType]
        let cacheType = CacheType(rawValue: cacheTypeString) ?? CacheType.transient

        return Record(token: token,
                      version: version,
                      recordType: recordType,
                      originName: originName,
                      originFileSize: sizeUInt64,
                      fileType: fileType,
                      cacheType: cacheType)
        
    }
    
    private func insertQuery(_ record: Record) -> Insert {
        let sizeInt64: Int64?
        if let originFileSize = record.originFileSize {
            sizeInt64 = Int64(exactly: originFileSize)
        } else {
            sizeInt64 = nil
        }
        let query = table.insert(or: .replace,
                                 self.recordID <- record.fileID,
                                 self.token <- record.token,
                                 self.version <- record.version,
                                 self.recordType <- record.recordType.identifier,
                                 self.originName <- record.originName,
                                 self.originFileSize <- sizeInt64,
                                 self.fileType <- record.fileType,
                                 self.cacheType <- record.cacheType.rawValue)
        return query
    }
}

class DriveTokenVersionTable {
    private let db: Connection
    private let table: Table
    
    private let token = Expression<String>("token")
    private let version = Expression<String>("version")
    
    private var createTableCMD: String {
        let command = table.create(ifNotExists: true) { t in
            t.column(token, primaryKey: true)
            t.column(version)
        }
        return command
    }
    
    init(connection: Connection, tableName: String = "drive_token_version_map") {
        db = connection
        table = Table(tableName)
    }
    
    func setup() throws {
        try db.run(createTableCMD)
    }
    
    func insert(tokenVersionMap: [String: String]) throws {
        do {
            try db.transaction {
                for (token, version) in tokenVersionMap {
                    let query = insertQuery(token: token, version: version)
                    try db.run(query)
                }
            }
        } catch {
            DocsLogger.error("DriveFileMetaStorage.DB ---  db error when insert token version map", error: error)
            throw error
        }
    }

    
    func deleteAll() throws {
        do {
            try db.run(table.delete())
        } catch {
            DocsLogger.error("DriveFileMetaStorage.DB ---  db error when delete all token version map", error: error)
            throw error
        }
    }

    func delete(token: String) throws {
        do {
            let rows = table.filter(self.token == token)
            try db.run(rows.delete())
        } catch {
            DocsLogger.error("DriveFileMetaStorage.DB ---  db error when delete record",
                             extraInfo: ["token": DocsTracker.encrypt(id: token)],
                             error: error)
            throw error
        }
    }
    
    func queryVersion(token: String) throws -> String? {
        do {
            let rows = try db.prepare(table.filter(self.token == token)).map({ $0 })
            guard let row = rows.first else {
                DocsLogger.driveInfo("DriveFileMetaStorage.DB ---  version not found")
                return nil
            }
            let version = row[self.version]
            DocsLogger.debug("DriveFileMetaStorage.DB ---  token version  \(version)")
            return version
        } catch {
            spaceAssertionFailure("DriveFileMetaStorage.DB ---  db error when get all records \(error)")
            throw error
        }
    }
    
    private func insertQuery(token: String, version: String) -> Insert {
        let query = table.insert(or: .replace,
                                 self.token <- token,
                                 self.version <- version)
        return query
    }
}
