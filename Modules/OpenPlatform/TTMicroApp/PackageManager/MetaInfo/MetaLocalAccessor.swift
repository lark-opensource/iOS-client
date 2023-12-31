
//
//  MetaLocalAccessor.swift
//  Timor
//
//  Created by houjihu on 2020/6/8.
//

import FMDB
import LarkOPInterface
import LKCommonsLogging
import Foundation
import OPSDK

private let log = Logger.oplog(MetaLocalAccessor.self, category: "MetaLocalAccessor")
private let PKMTag = "PKM-MetaLocalAccessor:"

/// meta本地存取器
public final class MetaLocalAccessor {

    private let dispatchQueue = DispatchQueue(label: "com.lark.openplatform.meta.pkm")
    /// 内部私有的数据库实例，请勿直接使用
    private var internalDBQueue: FMDatabaseQueue?
    private var metaAccessor: PKMMetaAccessor?
    // internalDBQueue 初始化/释放 的锁
    private let internalDBLock = NSLock()
    /// 数据库
    private var dbQueue: FMDatabaseQueue? {
        defer {
            internalDBLock.unlock()
        }
        internalDBLock.lock()
        if internalDBQueue == nil {
            internalDBQueue = (BDPModuleManager(of: appType)
                                .resolveModule(with: BDPStorageModuleProtocol.self) as? BDPStorageModuleProtocol)?
                .sharedLocalFileManager()
                .dbQueue
            internalDBQueue?.inTransaction({ (db, rollback) in
                let createReleaseMetaTableResult = db.executeUpdate(bdp_CreateReleaseMetaTable, withArgumentsIn: [])
                if !createReleaseMetaTableResult {
                    let operror = db
                        .lastError()
                        .newOPError(
                            monitorCode: CommonMonitorCodeMeta
                                .meta_db_error,
                            message: "CreateReleaseMetaTable failed, will rollback"
                        )
                    rollback.pointee = true
                    assertionFailure("\(operror)")
                    return
                }
                let createPreviewMetaTableResult = db.executeUpdate(bdp_CreatePreviewMetaTable, withArgumentsIn: [])
                if !createPreviewMetaTableResult {
                    let operror = db
                        .lastError()
                        .newOPError(
                            monitorCode: CommonMonitorCodeMeta
                                .meta_db_error,
                            message: "CreatePreviewMetaTable failed, will rollback"
                        )
                    rollback.pointee = true
                    assertionFailure("\(operror)")
                }
            })
        }
        return internalDBQueue
    }

    /// 应用类型，外部传入
    private let appType: BDPType

    /// meta本地存取器初始化方法
    /// - Parameters:
    ///   - type: 应用类型
    public init(type: BDPType) {
        appType = type
        if type == .unknown {
            let operror = OPError.error(monitorCode: CommonMonitorCodeMeta.meta_db_error, message: "MetaLocalAccessor init error with unknown type")
            assertionFailure("\(operror)")
        }
        if appType == .gadget && OPSDKFeatureGating.enableDBUpgrade() {
            self.metaAccessor = PKMMetaAccessor(type: appType.toPKMType())
        }
    }

    /// 保存meta到本地
    /// - Parameters:
    ///   - versionType: 版本类型
    ///   - key: 键
    ///   - value: 值
    public func saveLocalMeta(with versionType: OPAppVersionType, key: String, value: String) -> OPError? {
        //        guard !key.isEmpty else {
        //            let errorMessage = "key for saving meta is nil, please check it"
        //            assertionFailure(errorMessage)
        //            BDPLogError(tag: .metaLocalAccessor, errorMessage)
        //            return
        //        }
        //        let sql = versionType == OPAppVersionTypeToString(.current) ? bdp_UpdateReleaseMetaTable : bdp_UpdatePreviewMetaTable
        //        //  使用key存取meta
        //        self.dbQueue?.inDatabase({ (db) in
        //            db?.executeUpdate(sql, withVAList: getVaList([key, value, NSNumber(value: Int(NSTimeIntervalSince1970 * 1000))]))
        //        })
        //        BDPLogInfo(tag: .metaLocalAccessor, "save local metas")
        return workaroundSaveLocalMeta(with: versionType, key: key, value: value, ts: NSNumber(value: Int(Date().timeIntervalSince1970 * 1000)))
    }

    // 迁移数据库专用的方法，workaround，等待这个函数删掉之后把上面的注释打开即可，记得改为OPError
    public func workaroundSaveLocalMeta(with versionType: OPAppVersionType, key: String, value: String, ts: NSNumber) -> OPError? {
        let commonMsg = ", versionType:\(versionType) key:\(key) ts:\(ts)"
        guard !key.isEmpty else {
            let opError = OPError.error(monitorCode: CommonMonitorCodeMeta.invalid_params, message: "key for saving meta is nil, please check it" + commonMsg)
            assertionFailure("\(opError)")
            return opError
        }
        let sql = versionType == .current ? bdp_UpdateReleaseMetaTable : bdp_UpdatePreviewMetaTable
        var opError: OPError? = nil
        //  使用key存取meta
        self.dbQueue?.inDatabase({ (db) in
            let saveMetaResult = db.executeUpdate(sql, withVAList: getVaList([key, value, ts]))
            if saveMetaResult {
                log.info("save local metas success" + commonMsg, tag: BDPTag.metaLocalAccessor)
            } else {
                opError = db
                    .lastError()
                    .newOPError(
                        monitorCode: CommonMonitorCodeMeta
                            .meta_db_error,
                        message: "save meta failed" + commonMsg
                    )
                assertionFailure("\(opError)")
            }
        })
        //是不是需要写入的场景，且开关已经开启
        if let _ = self.metaAccessor,
           OPSDKFeatureGating.enableDBUpgrade() {
            //同时在新的数据库里写入
            dispatchQueue.async {
                log.info("\(PKMTag) begin to save local metas")
                let uniqueID = OPAppUniqueID(appID: key, identifier: nil, versionType: versionType, appType:self.appType)
                let metaContext = MetaContext(uniqueID: uniqueID, token: nil)
                self.saveMetaToPKMDBWithContext(value, metaContext: metaContext)
            }
        }
        return opError
    }
    
    private func saveMetaToPKMDBWithContext(_ metaJSONString: String, metaContext: MetaContext){
        let provider = GadgetMetaProvider(type: .gadget)
        if let gadgetMeta = try? provider.buildMetaModel(with: metaJSONString, context: metaContext) as? GadgetMeta {
            //新架构走PKMAppPool
            if OPSDKFeatureGating.pkmLoadMetaAndPkgEnable() && self.metaAccessor != nil {
                //通过应用池存储包信息
                log.info("\(PKMTag) try to save meta with apppool")
                let appPool = PKMAppPoolManager.sharedInstance.appPoolWith(pkmType: .gadget)
                _ = appPool.add(apps: [gadgetMeta])
            } else {
                if let error = self.metaAccessor?.saveMetaWith(baseMeta: gadgetMeta) {
                    log.error("saveMetaToPKMDBWithContext with error:\(error)")
                }
            }
            log.info("\(PKMTag) end to save local metas, successfully")
        } else {
            //不可能走到这里，除非 buildMetaModel 内部逻辑变化
            log.error("\(PKMTag) type cast error")
        }
    }

    /// 尝试获取meta磁盘缓存
    /// - Parameter context: meta请求上下文
    /// 返回Meta的JSON string
    public func getLocalMeta(with context: MetaContext) -> String? {
        guard let (metaJson, _) = getLocalMetaAndTimestamp(with: context) else {
            return nil
        }
        return metaJson
    }
    
    /// 获取本地AppID相关的所有meta信息，且返回 metaJSON
    public func getLocalMetaListWithTimestamp(with context: MetaContext) -> [(String, NSNumber)] {
        return getLocalMetasWithTimestamp(with: context)
    }

    /// 尝试获取meta磁盘缓存
    /// - Parameter context: meta请求上下文
    /// 返回(Meta的JSON string，上次更新的本地时间戳, 单位: 毫秒)
    public func getLocalMetaAndTimestamp(with context: MetaContext) -> (String, NSNumber)? {
        let results =  getLocalMetasWithTimestamp(with: context)
        return results.count > 0 ? results.first : nil
    }
    
    private func getLocalMetasWithTimestamp(with context: MetaContext) -> [(String, NSNumber)] {
        //  基本参数校验
        assert(context != nil, "context for request meta is nil, please check it")
        //如果开关打开，先尝试走新的数据存储表
        if let metaAccessor = self.metaAccessor,
           OPSDKFeatureGating.enableDBUpgrade() {
            log.info("\(PKMTag) try to find metas from PKM table")
            //新架构走PKMAppPool
            if OPSDKFeatureGating.pkmLoadMetaAndPkgEnable() {
                //通过应用池存储包信息
                log.info("\(PKMTag) try to get meta from apppool")
                let appPool = PKMAppPoolManager.sharedInstance.appPoolWith(pkmType: .gadget)
                let appID = context.uniqueID.appID
                let identifier = context.uniqueID.identifier
                if let allAppList = appPool.allApps(PKMUniqueID(appID: appID, identifier: identifier))[appID]?.compactMap { ($0.originalJSONString, $0.lastUpdateTime ?? 0) } {
                    return allAppList
                }
            } else {
                let results = metaAccessor.getAllMetasWithTimestampBy(context.uniqueID.appID)
                if results.isEmpty == false {
                    log.info("\(PKMTag) return metas from PKM table")
                    return results
                }
            }
        }
        let sql = context.uniqueID.versionType == .current ? bdp_QueryReleaseMetaTable : bdp_QueryPreviewMetaTable
        //  数据库取本地meta
        var metaJsonStrs : [(String, NSNumber)] = []
        dbQueue?.inDatabase({ (db) in
            let rs = db.executeQuery(sql, withVAList: getVaList([context.uniqueID.identifier]))
            while let rs = rs,
                  rs.next() {
                let metaJsonStr  = rs.string(forColumnIndex: 0)
                let ts = rs.longLongInt(forColumnIndex: 1) as? NSNumber ?? NSNumber(value: Int(Date().timeIntervalSince1970 * 1000))
                if let metaJsonStr = metaJsonStr {
                    metaJsonStrs.append((metaJsonStr, ts))
                }
            }
            rs?.close() //  文档写了通常情况无需调用，但是要和老代码保持完全的一致
        })
        if metaJsonStrs.count == 0 {
            //  无meta缓存
            log.info(BDPTag.metaLocalAccessor, tag: "identifier:\(context.uniqueID.identifier) has no local meta")
        }
        log.info("get local meta jsonstr from db success, identifier: \(context.uniqueID.identifier)", tag: BDPTag.metaLocalAccessor)
        //如果走到了兜底的逻辑，需要把老的数据写入到新的PKM表里
        if let _ = self.metaAccessor,
           OPSDKFeatureGating.enableDBUpgrade() {
            log.info("\(PKMTag) try to save metas to PKM table")
            self.dispatchQueue.async {
                metaJsonStrs.forEach { metaJSONString, ts in
                    self.saveMetaToPKMDBWithContext(metaJSONString, metaContext: context)
                }
            }
        }
        return metaJsonStrs
    }

    /// 删除本地meta
    /// - Parameter contexts: meta请求上下文
    public func removeMetas(with contexts: [MetaContext]) {
        //  必备参数校验
        assert(contexts != nil, "contexts for remove meta is nil, please check it")
        guard !contexts.isEmpty else {
            let msg = "contexts for remove meta is empty, please check it"
            let opError = OPError.error(monitorCode: CommonMonitorCodeMeta.invalid_params, message: msg)
            assertionFailure("\(opError)")
            return
        }
        //  调用存储模块进行本地meta删除
        contexts.forEach { (context) in
            if OPSDKFeatureGating.shouldKeepDataWith(context.uniqueID) {
               log.info("delete logic return, identifier: \(context.uniqueID.identifier)", tag: BDPTag.metaLocalAccessor)
               return
            }
            let key = context.uniqueID.identifier
            let sql = context.uniqueID.versionType == .current ? bdp_DeleteReleaseMetaTable : bdp_DeletePreviewMetaTable
            //  删除本地meta
            self.dbQueue?.inDatabase({ (db) in
                let deleteMetaResult = db.executeUpdate(sql, withVAList: getVaList([key]))
                if deleteMetaResult {
                    log.info("delete local meta success, identifier: \(context.uniqueID.identifier)", tag: BDPTag.metaLocalAccessor)
                } else {
                    let operror = db
                        .lastError()
                        .newOPError(
                            monitorCode: CommonMonitorCodeMeta
                                .meta_db_error,
                            message: "delete local meta failed, identifier: \(context.uniqueID.identifier)"
                        )
                    assertionFailure("\(operror)")
                }
            })
        }
    }
    
    /// 获取本地所有meta
    public func getAllMetas() -> [String]{
        return getAllMetasWithTimestamp().map{$0.0}
    }
    public func getAllMetasWithTimestamp() -> [(String, NSNumber)]{
        var metaJsonStrs : [(String, NSNumber)] = []
        dbQueue?.inDatabase({ (db) in
            let rs = db.executeQuery(bdp_QueryAllReleaseMetaTable, withVAList: getVaList([]))
            while let rs = rs,
                rs.next() {
                let metaJsonStr  = rs.string(forColumnIndex: 0)
                let ts = rs.longLongInt(forColumnIndex: 1) as? NSNumber ?? NSNumber(value: Int(Date().timeIntervalSince1970 * 1000))
                if let metaJsonStr = metaJsonStr {
                    metaJsonStrs.append((metaJsonStr, ts))
                }
            }
            rs?.close()
        })
        return metaJsonStrs
    }

    /// 清除本地所有meta
    public func removeAllMetas() {
        //  删表
        dbQueue?.inDatabase({ (db) in
            let removeAllReleaseMetasResult = db.executeUpdate(bdp_ClearReleaseMetaTable, withVAList: getVaList([]))
            if removeAllReleaseMetasResult {
                log.info("delete all release local meta success", tag: BDPTag.metaLocalAccessor)
            } else {
                let operror = db
                    .lastError()
                    .newOPError(
                        monitorCode: CommonMonitorCodeMeta
                            .meta_db_error,
                        message: "delete all release local meta failed"
                    )
                assertionFailure("\(operror)")
            }
            let removeAllPreviewMetasResult = db.executeUpdate(bdp_ClearPreviewMetaTable, withVAList: getVaList([]))
            if removeAllPreviewMetasResult {
                log.info("delete all preview local meta success", tag: BDPTag.metaLocalAccessor)
            } else {
                let operror = db
                    .lastError()
                    .newOPError(
                        monitorCode: CommonMonitorCodeMeta
                            .meta_db_error,
                        message: "delete all preview local meta failed"
                    )
                assertionFailure("\(operror)")
            }
        })
    }

    /// 清除数据库实例
    public func closeDBQueue() {
        defer {
            internalDBLock.unlock()
        }
        internalDBLock.lock()
        internalDBQueue?.close()
        internalDBQueue = nil
    }
}
