//
//  LynxDBManager.swift
//  SKCommon
//
//  Created by 曾浩泓 on 2022/4/3.
//  

import SQLite
import RxSwift
import Foundation
import SKFoundation

class LynxDBManager {
    static let shared = LynxDBManager()
    private let kvTable = KVTable()
    private var _db: Connection?
    private var db: Connection? {
        lock.lock()
        defer { lock.unlock() }
        
        if _db == nil {
            _db = createConnection()
        }
        return _db
    }
    private let lock = NSLock()
    
    /// 同步更新业务下的key对应的value。
    /// value不为nil时：如果业务已存在key对应的value，则更新value，
    /// 不存在则插入。
    /// value为nil时，将删除记录。
    /// - Parameters:
    ///   - value: 值
    ///   - key: 键
    ///   - biz: 业务名
    /// - Returns: 是否成功
    @discardableResult
    func update(value: String?, key: String, for biz: String) -> Bool {
        guard let db = db else {
            return false
        }
        if let value = value {
            do {
                try kvTable.insertOrReplace(value: value, key: key, biz: biz, with: db)
                return true
            } catch {
                DocsLogger.error("insert or replace fail", error: error, component: LogComponents.lynx)
                spaceAssertionFailure("insert or replace fail")
                return false
            }
        } else {
            do {
                try kvTable.delete(key: key, biz: biz, with: db)
                return true
            } catch {
                DocsLogger.error("delete key fail", error: error, component: LogComponents.lynx)
                spaceAssertionFailure("delete key fail")
                return false
            }
        }
    }
    
    /// 同步获取业务下key对应的value
    /// - Parameters:
    ///   - key: 键
    ///   - biz: 业务名
    /// - Returns: 值
    func value(of key: String, for biz: String) -> String? {
        guard let db = db else {
            return nil
        }
        do {
            return try kvTable.value(of: key, biz: biz, db: db)
        } catch {
            DocsLogger.error("read value fail", error: error, component: LogComponents.lynx)
            spaceAssertionFailure("read value fail")
            return nil
        }
    }
    
    private func createConnection() -> Connection? {
        let folder = LynxIOHelper.Path.getEncryptDBFolderPath_(for: LynxEnvManager.bizID)
        if !folder.exists {
            do {
                try folder.createDirectory(withIntermediateDirectories: true)
            } catch {
                DocsLogger.error("create db folder fail", error: error, component: LogComponents.lynx)
                spaceAssertionFailure("create db folder fail")
                return nil
            }
        }
        let (_, conection) = Connection.getEncryptDatabase(unEncryptPath: nil, encryptPath: LynxIOHelper.Path.getEncryptDBFilePath_(for: LynxEnvManager.bizID), fromsource: .lynx)
        createTablesIfNeeds(connection: conection)
        return conection
    }
    
    private func createTablesIfNeeds(connection: Connection?) {
        guard let connection = connection else {
            return
        }
        kvTable.createIfNotExist(connection)
    }
}
extension Reactive where Base: LynxDBManager {
    /// 异步获取业务下key对应的value
    /// - Parameters:
    ///   - key: 键
    ///   - biz: 业务名
    /// - Returns:
    func value(of key: String, for biz: String) -> Observable<String> {
        return Observable.create { observer in
            if let value = base.value(of: key, for: biz) {
                observer.onNext(value)
                observer.onCompleted()
            } else {
                observer.onError(NSError())
            }
            return Disposables.create()
        }
    }
    /// 异步更新业务下的key对应的value。
    /// value不为nil时：如果业务已存在key对应的value，则更新value，
    /// 不存在则插入。
    /// value为nil时，将删除记录。
    /// 注意：不支持取消操作
    /// - Parameters:
    ///   - value: 值
    ///   - key: 键
    ///   - biz: 业务名
    /// - Returns: 是否成功
    @discardableResult
    func update(value: String?, key: String, for biz: String) -> Observable<Bool> {
        return Observable.create { observer in
            let success = base.update(value: value, key: key, for: biz)
            observer.onNext(success)
            observer.onCompleted()
            return Disposables.create()
        }
    }
}
extension LynxDBManager: ReactiveCompatible {}

final class KVTable {
    private var table: Table?
    func createIfNotExist(_ connection: Connection) {
        table = Table("key_value")
        guard let table = table else {
            DocsLogger.info("KVTable is nil", component: LogComponents.lynx)
            return
        }
        
        let createStr = table.create(ifNotExists: true) { t in
            t.column(Column.business)
            t.column(Column.key)
            t.column(Column.value)
            t.column(Column.accessTime)
            t.primaryKey(Column.business, Column.key)
        }
        do {
            try connection.run(createStr)
        } catch {
            DocsLogger.error("kv_cache create table error", error: error, component: LogComponents.lynx)
        }
    }
    
    func insertOrReplace(value: String, key: String, biz: String, with db: Connection) throws {
        guard let table = table else {
            return
        }
        let accessTime: Int64 = Int64(Date().timeIntervalSince1970 * 1000.0)
        try db.run(table.insert(or: .replace, Column.value <- value, Column.key <- key, Column.business <- biz, Column.accessTime <- accessTime))
    }
    func value(of key: String, biz: String, db: Connection) throws -> String? {
        guard let table = table else {
            return nil
        }

        let query = table.select(Column.value)
            .filter(Column.key == key && Column.business == biz)
            .limit(1)
        let first = try db.prepare(query).first { _ in true }
        return first?[Column.value]
    }
    func delete(key: String, biz: String, with db: Connection) throws {
        guard let table = table else {
            return
        }
        let record = table.filter( Column.key == key && Column.business == biz )
        try db.run(record.delete())
    }
    
    
    struct Column {
        static let accessTime = Expression<Int64>("access_time")
        static let business = Expression<String>("business")
        static let key = Expression<String>("key")
        static let value = Expression<String>("value")
    }
}
