//
//  Connection+Docs.swift
//  snapkit
//
//  Created by chenhuaguan on 2019/11/1.
//  Copyright © 2019 chenhuaguan. All rights reserved.
//

import Foundation
import SQLite
import SQLCipher
import os.signpost
import SKFoundation
import SKInfra

extension Connection {

    enum CipherVersion: String {
        case versionV3
        case versionV4
        case versionLark  //主端sdk采用的加密配置
    }

    public enum FromSource: String {
        case unknown
        case fileList
        case newCache
        case wikiList
        case driveMeta
        case lynx
        case workspaceRouteTable
        case btUploadCache
    }

    private class func encryptKey(fromsource: FromSource = .unknown) -> String? {
        guard let userId = User.current.info?.userID, userId.isEmpty == false else {
            DocsLogger.info("encryptKey userID is nil=\(User.current.info?.userID ?? "nil")", component: LogComponents.db)
            return nil
        }
        let uidWithSalt = userId + "you nerver know"
        let md5Uid = uidWithSalt.md5()
        var result = md5Uid
        var pre: String = ""
        var end: String = ""
        if result.count > 15 {
            result = String(result.prefix(15))
            pre = String(result.prefix(3))
            end = String(result.suffix(3))
            DocsLogger.info("fromesource \(fromsource) theKey: \(pre)*\(end)", component: LogComponents.db)
        }
        #if DEBUG
        DocsLogger.info("fromesource \(fromsource) theKey \(result)", component: LogComponents.db)
        #else
        DocsLogger.info("fromesource \(fromsource) theKey: \(pre)*\(end)", component: LogComponents.db)
        #endif
        return result
    }

    /// 尝试对数据库加密
    /// params: sourcePath 未加密的数据库路径，如果是新建的数据库，sourcePath传nil
    /// params: targetPath 加密后的数据库路径，不能为nil
    /// return: (Bool, Connection?) 前者表面是否已加密，后者是数据库Connection，如果Connection为空说明异常了
    /// ps:     如果加密成功，会删掉sourcePath下的明文数据库
    public class func getEncryptDatabase(unEncryptPath: SKFilePath?, encryptPath: SKFilePath, readonly: Bool = false, fromsource: FromSource = .unknown) -> (Bool, Connection?) {
        var dbConnection: Connection?
        let unEncryptExist = unEncryptPath != nil && unEncryptPath?.exists == true
        let encryptExist = encryptPath.exists
        var resultPath: SKFilePath
        var useEncrypt: Bool = encryptExist

        let logStr = "db setup source=\(fromsource), encryptExist=\(encryptExist), unEncryptExist=\(unEncryptExist)"
        DocsLogger.info(logStr, component: LogComponents.db)

        if !encryptExist, unEncryptExist, let unEncryptPath = unEncryptPath {
            if Connection.innerEncryptDatabase(sourcePath: unEncryptPath, targetPath: encryptPath, fromsource: fromsource) {
                useEncrypt = true
                resultPath = encryptPath
            } else {
                useEncrypt = false
                resultPath = unEncryptPath
            }
        } else {
            useEncrypt = true
            resultPath = encryptPath
        }

        let logStr2 = """
        [SKFilePath]
        prepare connection, source=\(fromsource), useEncrypt=\(useEncrypt)
        resultPath=\(encryptPath.pathString)
        """
        DocsLogger.info(logStr2, component: LogComponents.db)
//        #if DEBUG
//        useEncrypt = false
//        resultPath = unEncryptPath!
//        #endif
        do {
            dbConnection = try Connection(resultPath.pathString, readonly: readonly)

            DocsLogger.info("[SKFilePath] connection open, source=\(fromsource), useEncrypt=\(useEncrypt),ok~", component: LogComponents.db)
        } catch {
            DocsLogger.info("[SKFilePath] connection open, source=\(fromsource) failed!", error: error, component: LogComponents.db)
            spaceAssertionFailure("[SKFilePath] connection, source=\(fromsource) failed!")
        }

        var setKeyOk = true
        if useEncrypt, let dbConnection = dbConnection, let key = Connection.encryptKey(fromsource: fromsource) {
            setKeyOk = Connection.setKeyWithRightCipherVersion(db: dbConnection, key: key, fromsource: fromsource, filePath: encryptPath)
            if unEncryptExist, setKeyOk, let unEncryptPath = unEncryptPath {
                do {
                    try unEncryptPath.removeItem()
                } catch let error {
                    DocsLogger.error("[SKFilePath] connection removeItem; source=\(fromsource) failed!", error: error, component: LogComponents.db)
                }
            }
            let cipherVersion = Connection.cipherVersion(connection: dbConnection)
            DocsLogger.info("[SKFilePath] cipherVersion=\(cipherVersion ?? "")", component: LogComponents.db)
        }

        let sqliteVersion = Connection.sqliteVersion(connection: dbConnection)
        DocsLogger.info("[SKFilePath] sqliteVersion=\(sqliteVersion ?? "")", component: LogComponents.db)
        return setKeyOk ? (useEncrypt, dbConnection) : (useEncrypt, nil)
    }

    class func innerEncryptDatabase(sourcePath: SKFilePath, targetPath: SKFilePath, fromsource: FromSource = .unknown) -> Bool {
        guard let key = Connection.encryptKey(fromsource: fromsource) else {
            return false
        }
        let sql = "PRAGMA cipher_default_compatibility = 3; ATTACH DATABASE '\(targetPath)' AS encrypted KEY '\(key)';"
        let exportSql = "SELECT sqlcipher_export('encrypted');"
        let detachSql = "DETACH DATABASE encrypted;"
        var dbConnection: Connection?
        var suc: Bool = false
        do {
            dbConnection = try Connection(sourcePath.pathString)
            try dbConnection?.execute(sql)
            try dbConnection?.execute(exportSql)
            try dbConnection?.execute(detachSql)
            DocsLogger.info("[SKFilePath] innerEncryptDatabase source=\(fromsource),successfull!", component: LogComponents.db)
            suc = true
        } catch let error {
            _ = deleteSourceFileIfMalformed(filePath: sourcePath, errorIn: error, fromsource: fromsource)
            DocsLogger.info("[SKFilePath] innerEncryptDatabase source=\(fromsource),Fail!", error: error, component: LogComponents.db)
            spaceAssertionFailure("encryptDb Fail")
            suc = false
        }

        if !suc {
            do {
                DocsLogger.info("[SKFilePath] innerEncryptDatabase source=\(fromsource), delete failed cipher file", component: LogComponents.db)
                try targetPath.removeItem()
            } catch {
                DocsLogger.error("[SKFilePath] delete targetPath error \(fromsource)", error: error, component: LogComponents.db)
                spaceAssertionFailure("delete targetPath error \(fromsource)")
            }
        }
        return suc
    }

    ///由于之前rust给SQLCipher库设置了全局参数cipher_default_compatibility=3； 而且rust和我们创建数据库的时序是不固定的，导致线上可能存在SQLCipher3.x、SQLCipher4.x, Lark.x(主端自定义参数)三个版本数据库
    private class func setKeyWithRightCipherVersion(db: Connection, key: String, fromsource: FromSource = .unknown, filePath: SKFilePath?) -> Bool {
        var setKeyAndTestOk: Bool = false
        var err: Error?

        var curTryVersion = CipherVersion.versionV3
        var nextTryVersion = CipherVersion.versionV4
        var lastTryVersion = CipherVersion.versionLark
        var versionConfigDic = CCMKeyValue.globalUserDefault.dictionary(forKey: UserDefaultKeys.sqlcipherVersionDic) ?? [:]
        let configVersion = (versionConfigDic[fromsource.rawValue] as? String) ?? ""
        switch configVersion {
        case CipherVersion.versionV4.rawValue:
            curTryVersion = CipherVersion.versionV4
            nextTryVersion = CipherVersion.versionV3
            lastTryVersion = CipherVersion.versionLark
        case CipherVersion.versionLark.rawValue:
            curTryVersion = CipherVersion.versionLark
            nextTryVersion = CipherVersion.versionV3
            lastTryVersion = CipherVersion.versionV4
        default:
            break
        }

        ///关闭cipher_memory_security
        do {
            try db.execute("PRAGMA cipher_memory_security = OFF;")
        } catch let error {
            DocsLogger.error("setCipherKey cipher_memory_security off; source=\(fromsource) failed!", error: error, component: LogComponents.db)
        }

        ///尝试curTryVersion版本
        (setKeyAndTestOk, _) = Connection.tryTheKeyWithVersion(curTryVersion, db: db, key: key, fromsource: fromsource)

        guard setKeyAndTestOk == false else {
            DocsLogger.info("setCipherKey configVersion=\(configVersion), curTryVersion = \(curTryVersion), source=\(fromsource), success=\(setKeyAndTestOk)!", component: LogComponents.db)
            versionConfigDic.updateValue(curTryVersion.rawValue, forKey: fromsource.rawValue)
            CCMKeyValue.globalUserDefault.setDictionary(versionConfigDic, forKey: UserDefaultKeys.sqlcipherVersionDic)
            return true
        }

        ///尝试nextTryVersion版本
        (setKeyAndTestOk, _) = Connection.tryTheKeyWithVersion(nextTryVersion, db: db, key: key, fromsource: fromsource)

        guard setKeyAndTestOk == false else {
            DocsLogger.info("setCipherKey configVersion=\(configVersion), nextTryVersion = \(nextTryVersion), source=\(fromsource), success=\(setKeyAndTestOk)!", component: LogComponents.db)
            versionConfigDic.updateValue(nextTryVersion.rawValue, forKey: fromsource.rawValue)
            CCMKeyValue.globalUserDefault.setDictionary(versionConfigDic, forKey: UserDefaultKeys.sqlcipherVersionDic)
            return true
        }

        ///尝试lastTryVersion版本
        (setKeyAndTestOk, err) = Connection.tryTheKeyWithVersion(lastTryVersion, db: db, key: key, fromsource: fromsource)

        if setKeyAndTestOk == false, let err = err {
            DocsLogger.error("setCipherKey configVersion=\(configVersion), lastTryVersion = \(lastTryVersion), test; source=\(fromsource) failed!", error: err, component: LogComponents.db)
            ///如果都失败删掉数据库
            _ = deleteSourceFileIfSetKeyFailed(filePath: filePath, errorIn: err, fromsource: fromsource)
            spaceAssertionFailure("connection,useKey source=\(fromsource) failed!")
            switch fromsource {
                case .fileList:
                    DBErrorStatistics.dbStatisticsFor(error: err, fromSource: DbErrorFromSource.cypherDbWithKeyFileList)
                case .newCache:
                    DBErrorStatistics.dbStatisticsFor(error: err, fromSource: DbErrorFromSource.cypherDbWithKeyCache)
                default: break
            }
        } else {
            DocsLogger.info("setCipherKey  configVersion=\(configVersion), lastTryVersion = \(lastTryVersion), source=\(fromsource), success=\(setKeyAndTestOk)", component: LogComponents.db)
            versionConfigDic.updateValue(lastTryVersion.rawValue, forKey: fromsource.rawValue)
            CCMKeyValue.globalUserDefault.setDictionary(versionConfigDic, forKey: UserDefaultKeys.sqlcipherVersionDic)
        }
        return setKeyAndTestOk
    }

    private class func tryTheKeyWithVersion(_ version: CipherVersion, db: Connection, key: String, fromsource: FromSource = .unknown) -> (Bool, Error?) {
        var setKeyAndTestOk: Bool = false
        var err: Error?
        ///尝试SQLCipher的version版本
        do {
            try Connection.key(key, connection: db)
            var sql = "PRAGMA cipher_compatibility = 3;"
            switch version {
            case .versionV3:
                sql = "PRAGMA cipher_compatibility = 3;"
            case .versionV4:
                sql = "PRAGMA cipher_compatibility = 4;"
            case .versionLark:
                sql = "PRAGMA cipher_compatibility = 3;PRAGMA cipher_use_hmac = OFF;PRAGMA kdf_iter = 4000;PRAGMA cipher_page_size = 1024;"
            }
            try db.execute(sql)
        } catch let error {
            err = error
            DocsLogger.error("setCipherKey version = \(version), set key; source=\(fromsource) failed!", error: error, component: LogComponents.db)
        }

        //测试看是否ok
        do {
            try db.execute("SELECT count(*) FROM sqlite_master;")
            setKeyAndTestOk = true
        } catch let error {
            err = error
            setKeyAndTestOk = false
            DocsLogger.error("setCipherKey version = \(version), test; source=\(fromsource) failed!", error: error, component: LogComponents.db)
        }

        return (setKeyAndTestOk, err)
    }

    private class func deleteSourceFileIfSetKeyFailed(filePath: SKFilePath?, errorIn: Error?, fromsource: FromSource) -> Bool {
        guard let filePath = filePath else {
            return false
        }
        var msg: String = ""
        var code: Int = 0
        var shouldDelSourceFile = false
        if let sqlErr = errorIn as? SQLite.Result {
            switch sqlErr {
            case let .error(message, cd, _) :
                msg = message
                code = Int(cd)
            }
        }

        var failedCountDic = CCMKeyValue.globalUserDefault.dictionary(forKey: UserDefaultKeys.sqlcipherKeyFailCount) ?? [:]
        var failedCount = (failedCountDic[fromsource.rawValue] as? Int) ?? 0
        failedCount += 1

        DocsLogger.info("[SKFilePath] deleteSourceFileIfSetKeyFailed, source=\(fromsource), count=\(failedCount)", component: LogComponents.db)

        switch fromsource {
            case .fileList:
                shouldDelSourceFile = failedCount > 2
            case .newCache:
                shouldDelSourceFile = failedCount > 4
            default: shouldDelSourceFile = failedCount > 6
        }

        if shouldDelSourceFile == true {
            failedCount = 0
            DocsLogger.info("[SKFilePath] deleteSourceFileIfSetKeyFailed, source=\(fromsource), delete", component: LogComponents.db)
            deleteSourceFile(filePath: filePath, code: code, msg: msg, fromsource: fromsource)
        }

        failedCountDic.updateValue(failedCount, forKey: fromsource.rawValue)
        CCMKeyValue.globalUserDefault.setDictionary(failedCountDic, forKey: UserDefaultKeys.sqlcipherKeyFailCount)

        return shouldDelSourceFile
    }

    private class func deleteSourceFileIfMalformed(filePath: SKFilePath, errorIn: Error, fromsource: FromSource) -> Bool {
        var msg: String = ""
        var code: Int = 0
        var shouldDelSourceFile = false
        if let sqlErr = errorIn as? SQLite.Result {
            switch sqlErr {
            case let .error(message, cd, _) :
                msg = message
                code = Int(cd)
                if message.contains("malformed") {
                    shouldDelSourceFile = true
                }
            }
        } else if let sqlErr = errorIn as? Connection.DbCipherResult {
            switch sqlErr {
            case let .error(message, cd, _) :
                msg = message
                code = Int(cd)
                if message.contains("malformed") {
                    shouldDelSourceFile = true
                }
            }
        }

        if shouldDelSourceFile == true {
            DocsLogger.info("[SKFilePath] deleteSourceFileIfMalformed, source=\(fromsource)", component: LogComponents.db)
            deleteSourceFile(filePath: filePath, code: code, msg: msg, fromsource: fromsource)
        }
        return shouldDelSourceFile
    }

    private class func deleteSourceFile(filePath: SKFilePath, code: Int, msg: String, fromsource: FromSource) {
        do {
            DocsLogger.info("[SKFilePath] deleteSourceFile source=\(fromsource), code=\(code),msg=\(msg)", component: LogComponents.db)
            try filePath.removeItem()
        } catch {
            DocsLogger.error("[SKFilePath] deleteSourceFile error \(fromsource)", error: error, component: LogComponents.db)
        }

        switch fromsource {
        case .fileList:
            DBErrorStatistics.dbCustomerReport(errorCode: code, msg: msg, fromSource: DbErrorFromSource.cypherInnerFileList)
        case .newCache:
            DBErrorStatistics.dbCustomerReport(errorCode: code, msg: msg, fromSource: DbErrorFromSource.cypherInnerCache)
        default: break
        }
    }


    static var performCount: Int = 1
    static let performanceLog = OSLog(subsystem: "com.doc.bytedance", category: "Connection+Encrypt")

}

extension Connection {
    /// - Returns: the SQLCipher version
    class func cipherVersion(connection: Connection?) -> String? {
        return (try? connection?.scalar("PRAGMA cipher_version")) as? String
    }

    class func sqliteVersion(connection: Connection?) -> String? {
        return (try? connection?.scalar("SELECT sqlite_version()")) as? String
    }

    class func key(_ key: String, connection: Connection?, db: String = "main") throws {
        try _key_v2(connection: connection, db: db, keyPointer: key, keySize: key.utf8.count)
    }

    // MARK: - private
    class private func _key_v2(connection: Connection?, db: String, keyPointer: UnsafePointer<UInt8>, keySize: Int) throws {
        try check(sqlite3_key_v2(connection?.handle, db, keyPointer, Int32(keySize)), connection: connection)
    }

    class private func _rekey_v2(connection: Connection?, db: String, keyPointer: UnsafePointer<UInt8>, keySize: Int) throws {
        try check(sqlite3_rekey_v2(connection?.handle, db, keyPointer, Int32(keySize)), connection: connection)
    }

    @discardableResult
    fileprivate class func check(_ resultCode: Int32, connection: Connection?, statement: Statement? = nil) throws -> Int32 {
        guard let connection = connection, let error = DbCipherResult(errorCode: resultCode, connection: connection, statement: statement) else {
            return resultCode
        }
        throw error
    }

    enum DbCipherResult: Error {
        fileprivate static let successCodes: Set = [SQLITE_OK, SQLITE_ROW, SQLITE_DONE]
        case error(message: String, code: Int32, statement: Statement?)
        init?(errorCode: Int32, connection: Connection, statement: Statement? = nil) {
            guard !DbCipherResult.successCodes.contains(errorCode) else { return nil }
            let message = String(cString: sqlite3_errmsg(connection.handle))
            self = .error(message: message, code: errorCode, statement: statement)
        }
    }
}
