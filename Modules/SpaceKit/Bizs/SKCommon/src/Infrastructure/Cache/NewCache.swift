//
//  NewCache.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/8/27.
//  

import SKFoundation
import SQLite
import YYCache
import os
import RxSwift
import CryptoSwift
import ThreadSafeDataStructure
import Foundation
import SpaceInterface
import SKInfra

public typealias NewCacheDataHandler = (Swift.Result<Void, Error>) -> Void

final class NewCache {
    static let shard = NewCache(cipher: DocsCipher(userId: User.current.info?.userID ?? "userID", tenentId: User.current.info?.tenantID ?? "tenentId"))
    var sql: ClientVarSqlTableManager? = ClientVarSqlTableManager()
    private var fileQueue: DispatchQueue = {
        let queue = DispatchQueue(label: "com.bytedance.net.newcache.fileOperation")
        return queue
    }()
    //多线程会访问字典，可能会crash，内部来做保护
    var cachedDictQueue = DispatchQueue(label: "com.bytedance.net.newcache.cachedDict")

    //手动离线操作缓存迁移工作queue
    let manuOfflineQueue = DispatchQueue(label: "com.bytedance.net.newcache.manuOfflineQueue", qos: DispatchQoS.background)

    lazy var fileManuOfflineManager: FileManualOfflineManagerAPI? = DocsContainer.shared.resolve(FileManualOfflineManagerAPI.self)

    var imageCache: NCImageCacheManager? = NCImageCacheManager()
    // 存放一些东西在内存里，加快速度
    var clientVarCache = DocValueCache<H5DataRecordKey, H5DataRecord>()
    var metaDataCache = [FileListDefine.ObjToken: ClientVarMetaData]()
    private var aesCipher: Cipher?
    private let bigFileThreshold = 60 * 1024 // 60K 以上认为是大文件
    private let bigFileThresholdV2 = 300 * 1024 //300K 以上认为是大文件
    private let performanceLog = OSLog(subsystem: "com.doc.bytedance", category: "newcache")
    private var readSequenceID: UInt = 0
    private var currentSaveToFileWorkItem: DispatchWorkItem?
    private var isSavingToFile: Bool = false
    private var waitWorkItem: SafeDictionary<H5DataRecordKey, DispatchWorkItem> = [:] + .readWriteLock
    
    private var serializer: NewCacheSerializer?
    
    // 只能通过shared来访问，只被初始化一次
    private init() {
    }

    init(cipher: DocsCipher?) {
        do {
            self.aesCipher = try cipher?.generateAES()
        } catch {

        }
    }

    func userDidLogin() {
        serializer = NewCacheSerializer(userID: User.current.info?.userID ?? "")
        if UserScopeNoChangeFG.LJW.cipherUpdatedInRealtimeEnabled {
            let cipher =  DocsCipher(userId: User.current.info?.userID ?? "userID", tenentId: User.current.info?.tenantID ?? "tenentId")
            do {
                self.aesCipher = try cipher.generateAES()
            } catch {
                DocsLogger.error("create aesCipher error", component: LogComponents.newCache)
            }
        }
        sql?.userDidLogin()
        imageCache?.clientVarSql = sql
        fileManuOfflineManager?.addObserver(self)
    }

    func userDidLogout() {
        sql?.userDidLogout()
        cachedDictQueue.async {
            self.metaDataCache.removeAll()
            self.clientVarCache = DocValueCache<H5DataRecordKey, H5DataRecord>()
        }
    }

    func getMetaDataRecordBy(_ objToken: FileListDefine.ObjToken) -> ClientVarMetaData {
        return cachedDictQueue.sync {
            // 1: 内存缓存
            var metaData = metaDataCache[objToken]
            if metaData != nil {
                return metaData!
            }
            // 2. 从数据库中读，更新到内存里
            metaData = getClientVarMetaInfoFromDBBy(objToken)

            if metaData == nil {
                // 3. 数据库中没有，生成一个新的
                metaData = ClientVarMetaData(objToken: objToken)
            }
            // 4. 更新到内存里，并返回
            metaDataCache[objToken] = metaData
            return metaData!
        }
    }
    
    func getAllNeedSyncToken() -> Set<String> {
        return cachedDictQueue.sync {
            return getAllNeedSyncToken()
        }
    }

    func setH5Record(_ record: H5DataRecord, needLog: Bool, completion: NewCacheDataHandler?) {
        guard sql?.writeConection != nil else {
            DocsLogger.error("setH5Record no writeConnection", component: LogComponents.newCache)
            completion?(.failure(NSError(domain: "setH5Record no writeConnection", code: 1)))
            return
        }
        // 如有必要更新metaData
        let rawMetaData = getMetaDataRecordBy(record.objToken)
        let (metaDataChange, modifiedMetaData) = rawMetaData.updatingBy(record)
        cachedDictQueue.async {
            self.metaDataCache[record.objToken] = modifiedMetaData
            if record.shouldCacheInMemory {
                let recordKey = H5DataRecordKey(objToken: record.objToken, key: record.key)
                // 以第一次的from为准
                var upadateRecord = record
                if let oriRecord = self.clientVarCache[recordKey], oriRecord.cacheFrom != .cacheFromUnKnown {
                    upadateRecord.updateCacheFrom(oriRecord.cacheFrom)
                }
                self.clientVarCache[recordKey] = upadateRecord
                let updateTime = Date().timeIntervalSinceReferenceDate
                self.clientVarCache[recordKey]?.updateTime = updateTime
            }
        }
        sql?.writeQueue.async {
            autoreleasepool {
                if let connection = self.sql?.writeConection {
                    if metaDataChange {
                        self.sql?.metaTable.insert(modifiedMetaData, with: connection)
                    }
                    // 根据数据大小，判断存储到数据库/文件
                    var recordSave = record
                    recordSave.saveInfo = H5DataRecord.SaveInfo()
                    var data: Data?
                    if let payload = record.payload {
                        do {
                            data = try self.serializer?.encodeObject(payload)
                        } catch let error {
                            let errmsg: String = {
                                let nsErr = error as NSError
                                return "\(nsErr.code):\(nsErr.domain)"
                            }()
                            let errMsg = "setH5Record, archived Data,token=\(DocsTracker.encrypt(id: record.objToken)),key=\(record.key) err:\(errmsg)"
                            DocsLogger.error(errMsg, component: LogComponents.newCache)
                            completion?(.failure(NSError(domain: errMsg, code: 1)))
                        }
                    }
                    recordSave.saveInfo?.encodedData = data
                    if needLog {
                        let fixCount = 10
                        DocsLogger.info("Web set data, token: \(record.objToken.encryptToken), key: \(record.key.prefix(fixCount) + "***" + record.key.suffix(fixCount)), dataCount: \(data?.count ?? 0), payload is nil: \(recordSave.payload == nil), needSync: \(record.needSync)", component: LogComponents.newCache)
                    }
                    recordSave.saveInfo?.isBigData = (data?.count ?? 0) > self.bigFileThresholdV2
                    if recordSave.saveInfo?.isBigData ?? false {
                        self.saveToFileV2(recordSave, resultHandler: completion)
                        //大文件时关注文件是否存储成功，忽略数据库结果，不对error进行catch
                        try? self.sql?.rawDataTable.update(recordSave, with: connection)
                    } else {
                        do {
                            try self.sql?.rawDataTable.update(recordSave, with: connection)
                            completion?(.success(()))
                        } catch {
                            //对于需要检查错误的重要数据，数据库存储失败时再尝试存一次文件
                            if completion != nil, UserScopeNoChangeFG.LJW.dbErrorOpt {
                                self.saveToFileV2(recordSave, resultHandler: nil)
                            }
                            completion?(.failure(error))
                        }
                    }
                    // 如果数据是nil，要移除文件
                    if recordSave.payload == nil {
                        try? recordSave.filePathIfExist.removeItem()
                    }
                } else {
                    DocsLogger.info("setH5Record no writeConnection", component: LogComponents.newCache)
                    completion?(.failure(NSError(domain: "setH5Record no writeConnection", code: 1)))
                }
            }
        }
    }

    func changeTokenFrom(_ origToken: FileListDefine.ObjToken, to targetToken: FileListDefine.ObjToken) {
        guard sql?.writeQueue != nil else {
            DocsLogger.error("changeTokenFrom no writeQueue", component: LogComponents.newCache)
            return
        }
        sql?.writeQueue.sync {
            guard let connection = self.sql?.writeConection else { return }
            self.sql?.rawDataTable.changeObjToken(origToken, to: targetToken, with: connection)
            self.sql?.metaTable.changeObjToken(origToken, to: targetToken, with: connection)
        }
        cachedDictQueue.sync {
            self.metaDataCache[targetToken] = metaDataCache[origToken]
            self.metaDataCache[origToken] = nil
        }
        self.fileQueue.sync {
            let sourceDir = SKFilePath.clientVarCacheDir.appendingRelativePath(origToken)
            if sourceDir.exists {
                let targetDir = SKFilePath.clientVarCacheDir.appendingRelativePath(targetToken)
                sourceDir.moveItem(to: targetDir, overwrite: true)
            }
        }
        let fakeToken = origToken.isFakeToken ? origToken : ""
        DocsLogger.info("change token complete from \(fakeToken))", component: LogComponents.newCache)
    }

    private func saveToFile(_ recordSave: H5DataRecord, completion: (() -> Void)? = nil, resultHandler: NewCacheDataHandler? = nil) {
        defer {
            self.isSavingToFile = false
            completion?()
        }
        docExpectOnQueue(fileQueue)
        let writeUrl = recordSave.filePathIfExist
        guard let aesCipher = self.aesCipher else {
            DocsLogger.info("aesCipher is nil")
            resultHandler?(.failure(NSError(domain: "aesCipher is nil", code: 1)))
            return
        }
        do {
            self.isSavingToFile = true
            try writeUrl.deletingLastPathComponent.createDirectory(withIntermediateDirectories: true)
            guard let tmpData = try recordSave.saveInfo?.encodedData?.encrypt(cipher: aesCipher) else {
                return
            }
            //TODO: huangzhikai 看下上面调用deletingLastPathComponent 会不会有问题
            try tmpData.write(to: writeUrl)
            resultHandler?(.success(()))
        } catch let error {
            let errmsg: String = {
                let nsErr = error as NSError
                return "\(nsErr.code):\(nsErr.domain)"
            }()
            DocsLogger.info("save H5DataRecord to file fail, err=\(errmsg)", component: LogComponents.newCache)
            resultHandler?(.failure(NSError(domain: errmsg, code: 1)))
        }
    }

    private func saveToFileV2(_ recordSave: H5DataRecord, resultHandler: NewCacheDataHandler?) {
        let recordKey = H5DataRecordKey(objToken: recordSave.objToken, key: recordSave.key)
        if self.isSavingToFile {
            DocsLogger.info("replace waitWorkItem datacount= \(recordSave.saveInfo?.encodedData?.count ?? 0)", component: LogComponents.newCache)
            let nextWorkItem = DispatchWorkItem { [weak self] in
                DocsLogger.info("start execute waitWorkItem datacount= \(recordSave.saveInfo?.encodedData?.count ?? 0)", component: LogComponents.newCache)
                self?.saveToFile(recordSave, completion: { [weak self] in
                    self?.saveNextWorkItemToFile(recordKey)
                }, resultHandler: resultHandler)
            }
            nextWorkItem.notify(queue: DispatchQueue.main) {
                if nextWorkItem.isCancelled {
                    resultHandler?(.success(()))
                }
            }
            if let workItem = self.waitWorkItem[recordKey] {
                workItem.cancel()
            }
            self.waitWorkItem[recordKey] = nextWorkItem
        } else {
            self.currentSaveToFileWorkItem = DispatchWorkItem { [weak self] in
                DocsLogger.info("start execute current workItem datacount= \(recordSave.saveInfo?.encodedData?.count ?? 0)", component: LogComponents.newCache)
                self?.saveToFile(recordSave, completion: { [weak self] in
                    self?.saveNextWorkItemToFile(recordKey)
                }, resultHandler: resultHandler)
            }
            if let currentSaveToFileWorkItem = self.currentSaveToFileWorkItem {
                self.fileQueue.async(execute: currentSaveToFileWorkItem)
            }
        }
    }

    private func saveNextWorkItemToFile(_ recordKey: H5DataRecordKey) {
        if waitWorkItem.values.isEmpty {
            waitWorkItem.removeAll()
            DocsLogger.info("waitWorkItem is nil", component: LogComponents.newCache)
            return
        }

        if let workItem = self.waitWorkItem[recordKey] {
            DocsLogger.info("execute same key waitWorkItem", component: LogComponents.newCache)
            self.fileQueue.async(execute: workItem)
            self.waitWorkItem.removeValue(forKey: recordKey)
        } else if !self.waitWorkItem.isEmpty {
            DocsLogger.info("execute other key waitWorkItem", component: LogComponents.newCache)
            if let key = self.waitWorkItem.keys.first as? H5DataRecordKey, let workItem = self.waitWorkItem[key] as? DispatchWorkItem {
                self.fileQueue.async(execute: workItem)
                self.waitWorkItem.removeValue(forKey: key)
            }
        }
    }
    
    func getH5RecordBy(_ key: H5DataRecordKey) -> H5DataRecord? {
        return getH5RecordBy(key, onlyCache: false)
    }

    func getH5RecordBy(_ key: H5DataRecordKey, onlyCache: Bool) -> H5DataRecord? {
        guard let connection = sql?.readConnection else {
            DocsLogger.error("getH5RecordBy no readConnection", component: LogComponents.newCache)
            return nil
        }
        #if DEBUG
        readSequenceID += 1
        markReadBegin(sequence: readSequenceID)
        #endif
        var fromDB = true
        var dataCount: Int = 0
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            let endTime = CFAbsoluteTimeGetCurrent()
            markReadFinish(sequence: readSequenceID, key: "\(key.objToken):\(key.key)", dataCount: UInt(dataCount), fromDB: fromDB, costTime: (endTime - startTime))
        }

        var cachedResult: H5DataRecord?
        cachedDictQueue.sync {
            cachedResult = clientVarCache[key]
        }

        if cachedResult != nil {
            return cachedResult
        }

        var result = sql?.rawDataTable.getH5DataRecord(by: key, with: connection)
        guard let aesCipher = self.aesCipher else {
            return nil
        }
        
        //如果只取缓存，则不读io
        if onlyCache == false, result != nil, result?.payload == nil {
            let filePath = result!.filePathIfExist
            self.fileQueue.sync {
                let fileData = try? Data.read(from: filePath).decrypt(cipher: aesCipher)
                result?.readInfo.dataCount = fileData?.count ?? 0
                DocsLogger.info("getH5RecordBy from file datacount= \(result?.readInfo.dataCount ?? 0)", component: LogComponents.newCache)
                var payload: NSCoding?
                if let fileData = fileData {
                    do {
                        payload = try self.serializer?.decodeData(fileData) as? NSCoding
                    } catch let error {
                        let errmsg: String = {
                            let nsErr = error as NSError
                            return "\(nsErr.code):\(nsErr.domain)"
                        }()
                        DocsLogger.error("getH5RecordBy, unarchivedObject Data,token=\(DocsTracker.encrypt(id: key.objToken)),key=\(key.key) err:\(errmsg)", component: LogComponents.newCache)
                    }
                }
                if payload == nil {
                    DocsLogger.info("unatchive error: readInfo.dataCount = \(result?.readInfo.dataCount) but payload is nil", component: LogComponents.newCache)
                }
                result?.payload = payload
                fromDB = false
            }
        }
        dataCount = result?.readInfo.dataCount ?? 0
        if result?.shouldCacheInMemory ?? false {
            cachedDictQueue.async {
                self.clientVarCache[key] = result
            }
        }
        /// update AccessTime
        if let writeConection = sql?.writeConection {
            sql?.writeQueue.async {
                self.sql?.rawDataTable.updateAccessTime(by: key, size: dataCount, with: writeConection)
            }
        }
        return result
    }
    
    struct ResultSource: OptionSet {
        let rawValue: Int
        init(rawValue: Int) {
            self.rawValue = rawValue
        }
        static let none = ResultSource(rawValue: 1 << 0)
        static let dataInDB = ResultSource(rawValue: 1 << 1)
        static let dataInFile = ResultSource(rawValue: 1 << 2)
        static let fakeDataInDB = ResultSource(rawValue: 1 << 3)
        static let fakeDataInFile = ResultSource(rawValue: 1 << 4)
    }
    
    func collectData(token: String, for key: String) -> [NSCoding] {
        guard let connection = sql?.readConnection else {
            DocsLogger.error("getH5RecordBy no readConnection when collect data", component: LogComponents.newCache)
            return []
        }
        var result: [NSCoding] = []
        var resultSource: ResultSource = .none
        defer {
            DocsLogger.info("collect data finish, data count is \(result.count), dataInDB: \(resultSource.contains(.dataInDB)), dataInFile: \(resultSource.contains(.dataInFile)), fakeDataInDB: \(resultSource.contains(.fakeDataInDB)), fakeDataInFile: \(resultSource.contains(.fakeDataInFile))", component: LogComponents.newCache)
        }
        ///获取fakeToken
        var fakeToken: String = ""
        if !token.isFakeToken {
            let recordKey = H5DataRecordKey(objToken: token, key: DocsOfflineSyncManager.tokenCacheKey)
            let payload = self.sql?.rawDataTable.getH5DataRecord(by: recordKey, with: connection)?.payload ??
            CacheService.configCache.object(forKey: token + DocsOfflineSyncManager.tokenCacheKey)
            fakeToken = payload as? String ?? ""
        }
        //获取数据库recordkey和文件路径filepath
        var recordKeys: [H5DataRecordKey] = [H5DataRecordKey(objToken: token, key: key)]
        let md5Key = key.md5()
        var filePaths: [SKFilePath] = [SKFilePath.clientVarCacheDir.appendingRelativePath(token).appendingRelativePath(md5Key)]
        if !fakeToken.isEmpty {
            DocsLogger.info("current doc has fakeToken cache", component: LogComponents.newCache)
            recordKeys.append(H5DataRecordKey(objToken: fakeToken, key: key))
            filePaths.append(SKFilePath.clientVarCacheDir.appendingRelativePath(fakeToken).appendingRelativePath(md5Key))
        }
        //获取数据库数据
        recordKeys.forEach { key in
            if let dataInDB = self.sql?.rawDataTable.getH5DataRecord(by: key, with: connection)?.payload {
                result.append(dataInDB)
                resultSource.insert(key.objToken.isFakeToken ? .fakeDataInDB : .dataInDB)
            }
        }
        //获取文件数据
        guard let aesCipher = self.aesCipher else {
            return result
        }
        filePaths.forEach { path in
            do {
                let data = try Data.read(from: path).decrypt(cipher: aesCipher)
                if let payload = try self.serializer?.decodeData(data) as? NSCoding {
                    result.append(payload)
                    resultSource.insert(path.pathString.contains("fake_") ? .fakeDataInFile : .dataInFile)
                }
            } catch let error {
                let errmsg: String = {
                    let nsErr = error as NSError
                    return "\(nsErr.code):\(nsErr.domain)"
                }()
                DocsLogger.error("collect data error,token=\(DocsTracker.encrypt(id: token)),key=\(key) err:\(errmsg)", component: LogComponents.newCache)
            }
        }
        return result
    }
     
    func updateNeedPreloadBy(_ key: H5DataRecordKey, needPreload: Bool, doctype: DocsType) {
        if let writeConection = sql?.writeConection {
            sql?.writeQueue.async {
                self.sql?.rawDataTable.updatePreload(by: key, preload: needPreload, doctype: doctype, with: writeConection)
            }
        } else {
            DocsLogger.error("updateNeedPreloadBy no writeConection", component: LogComponents.newCache)
        }
    }
    
    func updateCacheFrom(_ key: H5DataRecordKey, cacheFrom: H5DataRecordFrom) {
        cachedDictQueue.async {
            self.clientVarCache[key]?.updateCacheFrom(cacheFrom)
        }
        if let writeConection = sql?.writeConection {
            sql?.writeQueue.async {
                self.sql?.rawDataTable.updateCacheFrom(by: key, cacheFrom: cacheFrom.rawValue, with: writeConection)
            }
        } else {
            DocsLogger.error("update cacheFrom no writeConection", component: LogComponents.newCache)
        }
    }

    private func markReadBegin(sequence: UInt) {
        #if DEBUG
        guard #available(iOS 12.0, *) else {
            return
        }
        let signPostID = OSSignpostID(UInt64(sequence))
        os_signpost(.begin, log: performanceLog, name: "cache", signpostID: signPostID)
        #endif
    }

    private func markReadFinish(sequence: UInt, key: String, dataCount: UInt, fromDB: Bool, costTime: TimeInterval) {
        #if DEBUG
        guard #available(iOS 12.0, *) else {
            return
        }
        let signPostID = OSSignpostID(UInt64(sequence))
        os_signpost(.end, log: performanceLog, name: "cache", signpostID: signPostID, "%s, count: %llu, db: %d, interval: %f", key, dataCount, fromDB ? 1 : 0, costTime)
        #endif
    }

    private func getClientVarMetaInfoFromDBBy(_ objToken: FileListDefine.ObjToken) -> ClientVarMetaData? {
        guard let connection = sql?.readConnection else {
            DocsLogger.error("ClientVarMetaInfoFromDB no writeConnection", component: LogComponents.newCache)
            return nil
        }

        var metaData = sql?.metaTable.getMetaData(by: objToken, with: connection)
        if let needSyncChannels = sql?.rawDataTable.getNeedSyncChannelsBy(objToken, with: connection) {
            metaData?.needSynckeys = needSyncChannels
        }
        if objToken.isFakeToken {
            DocsLogger.debug("getClientVarMetaInfoFromDBBy \(objToken), metadata\(String(describing: metaData)), needSyncChannels \(metaData?.needSynckeys ?? [])", component: LogComponents.newCache)
        }
        return metaData
    }
    
    func getAllNeedSyncTokens() -> Set<String> {
        return sql?.getAllNeedSyncTokens() ?? []
    }

    func mapTokenAndPicKey(token: String?, picKey: String, picType: Int, needSync: Bool, isDrivePic: Bool?) {
        DocsLogger.debug("token=\(token ?? ""), picKey=\(picKey),picType=\(picType) needSync=\(needSync), isDrivePic=\(isDrivePic ?? false)", component: LogComponents.newCache)
        guard let objToken = token else {
            return
        }
        let picInfo = SKPicMapInfo(objToken: objToken, picKey: picKey, picType: picType, needUpLoad: needSync, isDrive: isDrivePic)
        self.sql?.mapTokenAndPicKey(picInfo: picInfo)
    }

    func getImage(byKey key: String, token: String?) -> NSCoding? {
        return imageCache?.object(forKey: key, token: token, needSync: nil)
    }

    func getImage(byKey key: String, token: String?, needSync: Bool) -> NSCoding? {
        return imageCache?.object(forKey: key, token: token, needSync: needSync)
    }

    func storeImage(_ data: NSCoding?, token: String?, forKey key: String, needSync: Bool) {
        mapTokenAndPicKey(token: token, picKey: key, picType: 0, needSync: needSync, isDrivePic: false)
        imageCache?.setObject(data, forKey: key, token: token, needSync: needSync)
    }

    func hasImge(forKey key: String, token: String?, needSync: Bool) -> Bool {
        return imageCache?.containsObject(forKey: key, token: token, needSync: needSync) ?? false
    }

    func hasImge(forKey key: String, token: String?) -> Bool {
        return imageCache?.containsObject(forKey: key, token: token, needSync: nil) ?? false
    }

    func removePic(forKey key: String, token: String?) {
        imageCache?.removePic(forKey: key, token: token)
    }

    func updateAsset(_ asset: SKAssetInfo) {
        self.sql?.updateAsset(asset)
    }
    func updateFileToken(uuid: String, fileToken: String, objToken: String?) {
        self.sql?.updateFileToken(uuid: uuid, fileToken: fileToken, objToken: objToken)
    }
    func getAssetWith(uuids: [String], objToken: String?) -> [SKAssetInfo] {
        return self.sql?.getAssetWith(uuids: uuids, objToken: objToken) ?? []
    }

    func getAssetWith(fileTokens: [String]) -> [SKAssetInfo] {
        return self.sql?.getAssetWith(fileTokens: fileTokens) ?? []
    }

    func migrateImageFromStoreToCache(key: String) {
        imageCache?.migrateImageFromStoreToCache(key: key)
    }
}

public protocol NewCacheAPI: SKImageCacheService, SimpleModeObserver {
    func getMetaDataRecordBy(_ objToken: FileListDefine.ObjToken) -> ClientVarMetaData
    func getAllNeedSyncTokens() -> Set<String>
    func setH5Record(_ record: H5DataRecord)
    func setH5Record(_ record: H5DataRecord, needLog: Bool, completion: NewCacheDataHandler?)

    func getH5RecordBy(_ key: H5DataRecordKey) -> H5DataRecord?
    func getH5RecordBy(_ key: H5DataRecordKey, onlyCache: Bool) -> H5DataRecord?
    func object(forKey mainKey: String, subKey: String) -> NSCoding?
    func set(object: NSCoding?, for objToken: FileListDefine.ObjToken, subkey: String, needSync: Bool, cacheFrom: H5DataRecordFrom?)

    func userDidLogout()
    func userDidLogin()
    //同步操作，转移某个token的所有内容
    func changeTokenFrom(_ origToken: FileListDefine.ObjToken, to targetToken: FileListDefine.ObjToken)

    func cacheSize() -> Observable<CleanResult>
    func cacheClean(maxSize: Int, ageLimit: Int, isUserTrigger: Bool) -> Observable<CleanResult>
    func cleanCancel()

    func updateAsset(_ asset: SKAssetInfo)
    func updateFileToken(uuid: String, fileToken: String, objToken: String?)
    func getAssetWith(uuids: [String], objToken: String?) -> [SKAssetInfo]
    func getAssetWith(fileTokens: [String]) -> [SKAssetInfo]
    func migrateImageFromStoreToCache(key: String)
    
    //更新clientvar的更新时间
    func setClientVarUpdateTime(forKey mainKey: String, subKey: String)
    
    // 获取最近N个有clientVars数据但没有SSR的文档触发SSR的数据
    func getNoSSRTokens(count: Int, doctype: DocsType, queryMaxCount: Int, limitDaysCount: Int) -> [H5DataRecord]
    // 更新是否需要做预加载
    func updateNeedPreloadBy(_ key: H5DataRecordKey, needPreload: Bool, doctype: DocsType)
    // 更新cacheFrom
    func updateCacheFrom(_ key: H5DataRecordKey, cacheFrom: H5DataRecordFrom)
    func collectData(token: String, for key: String) -> [NSCoding]
}

extension NewCacheAPI {
    func set(object: NSCoding?, for objToken: FileListDefine.ObjToken, subkey: String, cacheFrom: H5DataRecordFrom?) {
        set(object: object, for: objToken, subkey: subkey, needSync: false, cacheFrom: cacheFrom)
    }
    func setH5Record(_ record: H5DataRecord) {
        setH5Record(record, needLog: false, completion: nil)
    }
}

extension NewCache: NewCacheAPI {
    
    func object(forKey mainKey: String, subKey: String) -> NSCoding? {
        let recordKey = H5DataRecordKey(objToken: mainKey, key: subKey)
        let object = getH5RecordBy(recordKey)?.payload
        return object
    }

    func set(object: NSCoding?, for objToken: FileListDefine.ObjToken, subkey: String, needSync: Bool, cacheFrom: H5DataRecordFrom?) {
        let h5record = H5DataRecord(objToken: objToken, key: subkey, needSync: needSync, payload: object, type: nil, cacheFrom: cacheFrom ?? .cacheFromUnKnown)
        setH5Record(h5record)
    }
    
    func setClientVarUpdateTime(forKey mainKey: String, subKey: String) {
        let recordKey = H5DataRecordKey(objToken: mainKey, key: subKey)
        if let writeConection = sql?.writeConection {
            sql?.writeQueue.async {
                self.sql?.rawDataTable.setUpdateTime(by: recordKey, with: writeConection)
            }
        }
    }
    
    func getNoSSRTokens(count: Int, doctype: DocsType, queryMaxCount: Int, limitDaysCount: Int) -> [H5DataRecord] {
        guard let connection = sql?.readConnection else {
            DocsLogger.error("getH5RecordBy no readConnection", component: LogComponents.newCache)
            return []
        }
        return sql?.rawDataTable.getNoSSRDataRecord(by: count, with: connection, doctype: doctype, queryMaxCount: queryMaxCount, limitDaysCount: limitDaysCount) ?? []
    }
}

///精简模式接口
extension NewCache: SimpleModeObserver {
    func deleteFilesInSimpleMode(_ files: [SimpleModeWillDeleteFile], completion: (() -> Void)?) {
        DocsLogger.info("NewCache start to clear data in simple mode", component: LogComponents.simpleMode)
        self.sql?.deleteFilesInSimpleMode(files, completion: completion)
    }
}

// MARK: 编解码优化
extension NewCache {
    /// 统一的解码方法
    func unifyDecodeData(_ data: Data) -> Any? {
        let output = try? serializer?.decodeData(data)
        return output
    }
}
