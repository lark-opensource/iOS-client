//
//  PKMMetaAccessor.swift
//  TTMicroApp
//
//  Created by Nicholas Tau on 2022/11/17.
//

import FMDB
import LarkOPInterface
import LKCommonsLogging
import Foundation
import OPSDK
import RustSDK

private let log = Logger.oplog(PKMMetaAccessor.self, category: "PKMMetaAccessor")

/// meta本地存取器
class PKMMetaAccessor {

    /// 内部私有的数据库实例，请勿直接使用
    private var internalDBQueue: FMDatabaseQueue?
    // internalDBQueue 初始化/释放 的锁
    private let internalDBLock = NSLock()
    /// 数据库
    private var dbQueue: FMDatabaseQueue? {
        defer {
            internalDBLock.unlock()
        }
        internalDBLock.lock()
        if internalDBQueue == nil {
            internalDBQueue = (BDPModuleManager(of: self.pkmType.toAppType())
                                .resolveModule(with: BDPStorageModuleProtocol.self) as? BDPStorageModuleProtocol)?
                .sharedLocalFileManager()
                .dbQueue
            internalDBQueue?.inTransaction({ (db, rollback) in
                let createReleaseMetaTableResult = db.executeUpdate(pkm_CreateReleaseMetaTable, withArgumentsIn: [])
                if !createReleaseMetaTableResult {
                    let operror = db
                        .lastError()
                        .newOPError(
                            monitorCode: CommonMonitorCodeMeta
                                .meta_db_error,
                            message: "CreateReleaseMetaTable failed, will rollback"
                        )
                    rollback.pointee = true
                    assertionFailureWithLog(operror)
                    return
                }
                let createPreviewMetaTableResult = db.executeUpdate(pkm_CreatePreviewMetaTable, withArgumentsIn: [])
                if !createPreviewMetaTableResult {
                    let operror = db
                        .lastError()
                        .newOPError(
                            monitorCode: CommonMonitorCodeMeta
                                .meta_db_error,
                            message: "CreatePreviewMetaTable failed, will rollback"
                        )
                    rollback.pointee = true
                    assertionFailureWithLog(operror)
                }
            })
        }
        return internalDBQueue
    }

    /// 应用类型，外部传入
    private let pkmType: PKMType
    
    //是否是预览数据表
    
    //小程序为了兼容从 metaContext->uniqueID里取versionType的逻辑
    //有可能直接在save/query 的逻辑参数里传 isPreview。这种情况 self.isPreview 就是空的
    //总结：初始化时 isPreview 有值，则用这个。否则用调用API时入参的 isPreview
    private let isPreview: Bool?

    /// meta本地存取器初始化方法
    /// - Parameters:
    ///   - type: 应用类型
    public init(type: PKMType, isPreview: Bool? = nil) {
        self.pkmType = type
        self.isPreview = isPreview
        if type == .unknow {
            let operror = OPError.error(monitorCode: CommonMonitorCodeMeta.meta_db_error, message: "metaLocalAccessorPKM init error with unknown type")
            assertionFailureWithLog(operror)
        }
    }
    
    public func saveMetaWith(baseMeta: (PKMBaseMetaProtocol&PKMBaseMetaDBProtocol), successBlock:((NSNumber) -> Void)? = nil) -> OPError? {
        let packageName = (baseMeta as? PKMBaseMetaPkgProtocol)?.packageName() ?? ""
        return self.saveMetaWith(baseMeta.identifier,
                                 bizType: baseMeta.bizType,
                                 meta: baseMeta.originalJSONString,
                                 metaFrom: baseMeta.metaFrom,
                                 appID: baseMeta.pkmID.appID,
                                 appVersion: baseMeta.appVersion,
                                 packageName: packageName,
                                 isPreview: baseMeta.isPreview,
                                 successBlock:successBlock)
    }
    
    public func saveMetaWith(_ identifier: String, bizType:String, meta: String, metaFrom: Int, appID: String, appVersion: String, packageName: String, isPreview: Bool, successBlock:((NSNumber) -> Void)? = nil ) -> OPError? {
        let commonMsg = "identifier:\(identifier),isPreview:\(isPreview) bizType:\(bizType) version:\(appVersion)"
        let sql = (self.isPreview ?? isPreview) ? pkm_UpdatePreviewMetaTable : pkm_UpdateReleaseMetaTable
        var opError: OPError? = nil
        //  使用key存取meta
        let update_time = NSNumber(value: Int(Date().timeIntervalSince1970 * 1000))
        self.dbQueue?.inDatabase({ (db) in
            let saveMetaResult = db.executeUpdate(sql, withVAList: getVaList([identifier,
                                                                              bizType,
                                                                              meta,
                                                                              metaFrom,
                                                                              appID,
                                                                              appVersion,
                                                                              packageName,
                                                                              "", update_time]))
            if saveMetaResult {
                log.info("save local metas success" + commonMsg, tag: BDPTag.metaLocalAccessorPKM)
                successBlock?(update_time)
            } else {
                opError = db
                    .lastError()
                    .newOPError(
                        monitorCode: CommonMonitorCodeMeta
                            .meta_db_error,
                        message: "save meta failed" + commonMsg
                    )
                assertionFailureWithLog(opError)
            }
        })
        return opError
    }
    
    /// 尝试获取meta磁盘缓存
    /// - Parameter context: meta请求上下文
    /// 返回Meta的JSON string
    public func getLocalMetaBy(_ appID: String) -> String? {
        guard let (metaJson, _) = getLocalMetaAndTimestampBy(appID) else {
            return nil
        }
        return metaJson
    }
    
    /// 获取本地AppID相关的所有meta信息，且返回 metaJSON
    public func getLocalMetaAndTimestampBy(_ appID: String) -> (String, NSNumber)? {
        let results =  getLocalMetaListWithTimestampBy(appID)
        if let first = results.first {
            return (first.1, first.5)
        }
        return nil
    }
    
    private func getLocalMetaListWithTimestampBy(_ appID: String?, isPreview: Bool = false)-> [(String, String, String, String, String?, NSNumber)] {
        //如果不传 appID，则代表需要获取所有的数据
        let shouldQueryWithAppID = appID != nil
        let queryReleaseSQL = shouldQueryWithAppID ? pkm_QueryAllReleaseMetaTableWithAppId : pkm_QueryAllReleaseMetaTable
        let queryPreviewSQL = shouldQueryWithAppID ? pkm_QueryAllPreviewMetaTableWithAppId : pkm_QueryAllPreviewMetaTable
        let sql = (self.isPreview ?? isPreview) ? queryPreviewSQL : queryReleaseSQL
        //  数据库取本地meta
        var metaJsonStrs : [(String, String, String, String, String?, NSNumber)] = []
        dbQueue?.inDatabase({ (db) in
            //appIO为空时，查select *，不指定appID，vaList为空字符串
            var vaList:[String] = []
            if let appID = appID { vaList = [appID] }
            let rs = db.executeQuery(sql, withVAList: getVaList(vaList))
            while let rs = rs,
                  rs.next() {
                    //业务类型
                guard let bizType = rs.string(forColumn: "biz_type"),
                      //原始JSON
                      let  metaJsonStr  = rs.string(forColumn: "meta"),
                      //应用ID
                      let appID  = rs.string(forColumn: "app_id"),
                      //应用版本
                      let appVersion  = rs.string(forColumn: "app_version") else {
                    log.error("appID:\(appID) with excetion value, unexcepted null", tag: BDPTag.metaLocalAccessorPKM)
                    return
                }
                //包名，非开放应用可能为空
                let pkgName  = rs.string(forColumn: "pkg_name")
                let lastUpdateTime = rs.longLongInt(forColumn:"update_time") as? NSNumber ?? NSNumber(value: Int(Date().timeIntervalSince1970 * 1000))
                metaJsonStrs.append((bizType, metaJsonStr, appID, appVersion, pkgName, lastUpdateTime))
            }
            rs?.close() //  文档写了通常情况无需调用，但是要和老代码保持完全的一致
        })
        if metaJsonStrs.count == 0 {
            //  无meta缓存
            log.info("appID:\(appID) has no local meta" , tag:BDPTag.metaLocalAccessorPKM)
        }
        log.info("get local meta jsonstr from db success, identifier: \(appID)", tag: BDPTag.metaLocalAccessorPKM)
        return metaJsonStrs
    }

    /// 删除本地meta
    /// - Parameter contexts: meta请求上下文
    public func removeMetas(metas: [PKMBaseMetaProtocol&PKMBaseMetaDBProtocol]) {
        //  必备参数校验
        guard !metas.isEmpty else {
            let msg = "metas for remove meta is empty, please check it"
            let opError = OPError.error(monitorCode: CommonMonitorCodeMeta.invalid_params, message: msg)
            assertionFailureWithLog(opError)
            return
        }
        log.info("starting to remove Metas with count:\(metas.count)", tag: BDPTag.metaLocalAccessorPKM)
        //  调用存储模块进行本地meta删除
        metas.forEach { (meta) in
            let sql = (self.isPreview ?? meta.isPreview) ? pkm_DeletePreviewMetaTableWithAppIdAndVersion : pkm_DeleteReleaseMetaTableWithAppIdAndVersion;
            //  删除本地meta
            self.dbQueue?.inDatabase({ (db) in
                let deleteMetaResult = db.executeUpdate(sql, withVAList: getVaList([meta.pkmID.appID, meta.appVersion]))
                if deleteMetaResult {
                    log.info("delete local meta success, meta: \(meta.originalJSONString)", tag: BDPTag.metaLocalAccessorPKM)
                } else {
                    let operror = db
                        .lastError()
                        .newOPError(
                            monitorCode: CommonMonitorCodeMeta
                                .meta_db_error,
                            message: "delete local meta failed, identifier: \(meta.identifier)"
                        )
                    assertionFailureWithLog(operror)
                }
            })
        }
    }
    
    public func getAllMetasDESCByTimestampBy(_ appID: String) -> [String] {
        return self.getAllMetasWithDetailDESCByTimestampBy(appID).compactMap { $0.1 }
        //只需要返回原始 meta string 数据即可
    }
    
    //返回数据库表中的所有字段【根据更新时间戳排序】
    // biz_type, meta, app_id, app_version, pkg_name, update_time"
    public func getAllMetasWithDetailDESCByTimestampBy(_ appID: String? = nil) -> [(String, String, String, String, String?, NSNumber)] {
        return self.getLocalMetaListWithTimestampBy(appID).sorted { first, second in
            //按照时间戳大小进行排序，时间戳大的排在前面（Tuple的[5]为 timestamp）
            Int64(truncating: first.5) > Int64(truncating: second.5)
        }
    }
    
    /// 获取本地所有meta【仅返回JSON String】
    public func getAllMetasWithBy(appID: String) -> [String]{
        return getAllMetasWithTimestampBy(appID).map{$0.0}
    }
    public func getAllMetasWithTimestampBy(_ appID: String) -> [(String, NSNumber)]{
        var metaJsonStrs : [(String, NSNumber)] = []
        dbQueue?.inDatabase({ (db) in
            let rs = db.executeQuery(pkm_QueryAllReleaseMetaTableWithAppId, withVAList: getVaList([appID]))
            while let rs = rs,
                rs.next() {
                let metaJsonStr  = rs.string(forColumnIndex: 1)
                let ts = rs.longLongInt(forColumnIndex: 5) as? NSNumber ?? NSNumber(value: Int(Date().timeIntervalSince1970 * 1000))
                if let metaJsonStr = metaJsonStr {
                    metaJsonStrs.append((metaJsonStr, ts))
                }
            }
            rs?.close()
        })
        return metaJsonStrs
    }
    /// 根据appID，清理所有appID相同的数据
    /// 清除本地所有meta
    public func removeAllMetasBy(_ appID: String) {
        //  删表
        dbQueue?.inDatabase({ (db) in
            let removeAllReleaseMetasResult = db.executeUpdate(pkm_DeleteReleaseMetaTableWithAppId, withVAList: getVaList([appID]))
            if removeAllReleaseMetasResult {
                log.info("delete all release local meta with appID:\(appID) success", tag: BDPTag.metaLocalAccessorPKM)
            } else {
                let operror = db
                    .lastError()
                    .newOPError(
                        monitorCode: CommonMonitorCodeMeta
                            .meta_db_error,
                        message: "delete all release local meta failed"
                    )
                assertionFailureWithLog(operror)
            }
            let removeAllPreviewMetasResult = db.executeUpdate(pkm_DeletePreviewMetaTableWithAppId, withVAList: getVaList([appID]))
            if removeAllPreviewMetasResult {
                log.info("delete all preview local meta with appID:\(appID) success", tag: BDPTag.metaLocalAccessorPKM)
            } else {
                let operror = db
                    .lastError()
                    .newOPError(
                        monitorCode: CommonMonitorCodeMeta
                            .meta_db_error,
                        message: "delete all preview local meta failed"
                    )
                assertionFailureWithLog(operror)
            }
        })
    }
    
    public func getCount() -> UInt64 {
        var count: UInt64 = 0
        dbQueue?.inDatabase({ (db) in
            let sql = (self.isPreview ?? false) ? pkm_CountAllPreviewMetaTable : pkm_CountAllReleaseMetaTable
            let rs = db.executeQuery(sql, withVAList: getVaList([]))
            while let rs = rs,
                rs.next() {
                count  = rs.unsignedLongLongInt(forColumnIndex: 0)
            }
            rs?.close()
        })
        return count
    }

    /// 清除本地所有meta
    public func removeAllMetas() {
        //  删表
        dbQueue?.inDatabase({ (db) in
            let removeAllReleaseMetasResult = db.executeUpdate(pkm_ClearReleaseMetaTable, withVAList: getVaList([]))
            if removeAllReleaseMetasResult {
                log.info("delete all release local meta success", tag: BDPTag.metaLocalAccessorPKM)
            } else {
                let operror = db
                    .lastError()
                    .newOPError(
                        monitorCode: CommonMonitorCodeMeta
                            .meta_db_error,
                        message: "delete all release local meta failed"
                    )
                assertionFailureWithLog(operror)
            }
            let removeAllPreviewMetasResult = db.executeUpdate(pkm_ClearPreviewMetaTable, withVAList: getVaList([]))
            if removeAllPreviewMetasResult {
                log.info("delete all preview local meta success", tag: BDPTag.metaLocalAccessorPKM)
            } else {
                let operror = db
                    .lastError()
                    .newOPError(
                        monitorCode: CommonMonitorCodeMeta
                            .meta_db_error,
                        message: "delete all preview local meta failed"
                    )
                assertionFailureWithLog(operror)
            }
        })
    }
    
    private func assertionFailureWithLog(_ error: OPError?) {
        log.error("fetch image url failed \(error)")
        assertionFailure("\(error)")
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
