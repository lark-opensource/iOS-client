//
//  RawDataTable.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/8/26.
//  
//  存储前端setData来的数据

import SQLite
import SKFoundation
import SwiftyJSON
import SpaceInterface

final class RawDataTable {
    var table: Table?

    init() {
    }

    func createIfNotExistWithConnection(_ connection: Connection) {
        table = Table(CVSqlDefine.Table.rawData.rawValue)
        guard let table = table else {
            DocsLogger.info("RawDataTable is nil", component: LogComponents.db)
            return
        }
        let createStr = table.create(ifNotExists: true) { tbl in
            tbl.column(CVSqlDefine.Rd.objToken)
            tbl.column(CVSqlDefine.Rd.key)
            tbl.column(CVSqlDefine.Rd.needSync)
            tbl.column(CVSqlDefine.Rd.type)
            tbl.column(CVSqlDefine.Rd.data)
            tbl.column(CVSqlDefine.Rd.dataSize)
            tbl.column(CVSqlDefine.Rd.updateTime)
            tbl.column(CVSqlDefine.Rd.accessTime)
            tbl.column(CVSqlDefine.Rd.needPreload)
            tbl.column(CVSqlDefine.Rd.cacheFrom)
            tbl.primaryKey(CVSqlDefine.Rd.objToken, CVSqlDefine.Rd.key)
        }
        do {
            try connection.run(createStr)
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .cache)
            DocsLogger.error("创建数据库失败", error: error, component: LogComponents.db)
        }
    }

    func getH5DataRecord(by recordKey: H5DataRecordKey, with connection: Connection) -> H5DataRecord? {
        guard let table = table else {
            DocsLogger.info("RawDataTable is nil", component: LogComponents.db)
            return nil
        }
        do {
            let filter = table.filter(CVSqlDefine.Rd.objToken == recordKey.objToken && CVSqlDefine.Rd.key == recordKey.key.md5())
            let records = try connection.prepareRowIterator(filter).map({ $0 })
            for record in records {
                let needSyncValue = DocsTableUtil.getNCOriColumn(CVSqlDefine.Rd.needSync, record: record) ?? false
                let dataValue = DocsTableUtil.getNCOriColumn(CVSqlDefine.Rd.data, record: record)
                let typeValue = DocsTableUtil.getNCOriColumn(CVSqlDefine.Rd.type, record: record)
                let docsType = (typeValue == nil) ? nil : DocsType(rawValue: typeValue!)
                let unArchived = dataValue.map { NewCache.shard.unifyDecodeData($0) } as? NSCoding
                let cacheFrom = DocsTableUtil.getNCOriColumn(CVSqlDefine.Rd.cacheFrom, record: record) ?? 0
                var h5Record = H5DataRecord(objToken: recordKey.objToken, key: recordKey.key, needSync: needSyncValue, payload: unArchived, type: docsType, cacheFrom: H5DataRecordFrom(rawValue: cacheFrom) ?? .cacheFromUnKnown)
                if recordKey.key.isClientVarKey {
                    h5Record.updateTime = DocsTableUtil.getNCOriColumn(CVSqlDefine.Rd.updateTime, record: record)
                    h5Record.accessTime = DocsTableUtil.getNCOriColumn(CVSqlDefine.Rd.accessTime, record: record)
                }
                h5Record.readInfo.dataCount = dataValue?.count ?? 0
                return h5Record
            }
            return nil
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .cache)
            DocsLogger.error("获取H5DataRecord失败", error: error, component: LogComponents.db)
            return nil
        }
    }
    
    func getNoSSRDataRecord(by count: Int, with connection: Connection, doctype: DocsType, queryMaxCount: Int, limitDaysCount: Int) -> [H5DataRecord] {
        guard let table = table else {
            DocsLogger.info("RawDataTable is nil", component: LogComponents.db)
            return []
        }
        
        var resultData: [H5DataRecord] = []
        do {
            let filter = table.filter(CVSqlDefine.Rd.type == doctype.rawValue)
            let records = try connection.prepareRowIterator(filter).map({ $0 })
            for record in records {
                let dataValue = DocsTableUtil.getNCOriColumn(CVSqlDefine.Rd.data, record: record)
                let unArchived = dataValue.map { NewCache.shard.unifyDecodeData($0) } as? NSCoding
                let objToken = DocsTableUtil.getNCOriColumn(CVSqlDefine.Rd.objToken, record: record)
                let recordKey = DocsTableUtil.getNCOriColumn(CVSqlDefine.Rd.key, record: record)
                let updateTime = DocsTableUtil.getNCOriColumn(CVSqlDefine.Rd.updateTime, record: record)
                let cacheFrom = DocsTableUtil.getNCOriColumn(CVSqlDefine.Rd.cacheFrom, record: record) ?? 0
                var needPreload = DocsTableUtil.getNCOriColumn(CVSqlDefine.Rd.needPreload, record: record) ?? true
                if needPreload,
                   unArchived == nil,
                    let updateTime = updateTime,
                   (Date.timeIntervalSinceReferenceDate - updateTime) < Double(limitDaysCount) * 24 * 60 * 60,
                    let objToken = objToken, let recordKey = recordKey, objToken.isFakeToken == false {
                    let needSyncValue = DocsTableUtil.getNCOriColumn(CVSqlDefine.Rd.needSync, record: record) ?? false
                    let typeValue = DocsTableUtil.getNCOriColumn(CVSqlDefine.Rd.type, record: record)
                    let docsType = (typeValue == nil) ? nil : DocsType(rawValue: typeValue!)
                    var h5Record = H5DataRecord(objToken: objToken, key: recordKey, needSync: needSyncValue, payload: unArchived, type: docsType, cacheFrom: H5DataRecordFrom(rawValue: cacheFrom) ?? .cacheFromUnKnown)
                    h5Record.readInfo.dataCount = dataValue?.count ?? 0
                    resultData.append(h5Record)
                    if resultData.count >= count{
                        return resultData
                    }
                }
            }
            return resultData
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .cache)
            DocsLogger.error("get No SSR Record fail", error: error, component: LogComponents.db)
            return []
        }
    }
    
    func setUpdateTime(by recordKey: H5DataRecordKey, with connection: Connection) {
        guard let table = table else {
            DocsLogger.info("RawDataTable is nil", component: LogComponents.db)
            return
        }
        do {
            let md5Key = recordKey.key.md5()
            let filter = table.filter(CVSqlDefine.Rd.objToken == recordKey.objToken && CVSqlDefine.Rd.key == md5Key)
            let update = filter.update(CVSqlDefine.Rd.updateTime <- Date.timeIntervalSinceReferenceDate)
            try connection.run(update)
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .cache)
            DocsLogger.error("setUpdateTime fail", error: error, component: LogComponents.db)
        }
    }

    func updateAccessTime(by recordKey: H5DataRecordKey, size: Int?, with connection: Connection) {
        guard let table = table else {
            DocsLogger.info("RawDataTable is nil", component: LogComponents.db)
            return
        }
        do {
            let md5Key = recordKey.key.md5()
            let filter = table.filter(CVSqlDefine.Rd.objToken == recordKey.objToken && CVSqlDefine.Rd.key == md5Key)
            if let dataSize = size {
                let update = filter.update(CVSqlDefine.Rd.accessTime <- Date.timeIntervalSinceReferenceDate,
                                           CVSqlDefine.Rd.dataSize <- dataSize)
                try connection.run(update)

            } else {
                let update = filter.update(CVSqlDefine.Rd.accessTime <- Date.timeIntervalSinceReferenceDate)
                try connection.run(update)
            }
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .cache)
            DocsLogger.error("updateAccessTime fail", error: error, component: LogComponents.db)
        }
    }
    
    func updatePreload(by recordKey: H5DataRecordKey, preload: Bool, doctype: DocsType, with connection: Connection) {
        guard let table = table else {
            DocsLogger.info("RawDataTable is nil", component: LogComponents.db)
            return
        }
        do {
            let filter = table.filter(CVSqlDefine.Rd.objToken == recordKey.objToken && CVSqlDefine.Rd.type == doctype.rawValue)
            let update = filter.update(CVSqlDefine.Rd.needPreload <- preload)
            try connection.run(update)
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .cache)
            DocsLogger.error("updatePreload fail", error: error, component: LogComponents.db)
        }
    }
    
    func updateCacheFrom(by recordKey: H5DataRecordKey, cacheFrom: Int, with connection: Connection) {
        guard let table = table else {
            DocsLogger.info("RawDataTable is nil", component: LogComponents.db)
            return
        }
        do {
            let filter = table.filter(CVSqlDefine.Rd.objToken == recordKey.objToken && CVSqlDefine.Rd.key == recordKey.key.md5())
            let update = filter.update(CVSqlDefine.Rd.cacheFrom <- cacheFrom)
            try connection.run(update)
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .cache)
            DocsLogger.error("update cacheFrom fail", error: error, component: LogComponents.db)
        }
    }

    func getNeedSyncChannelsBy(_ inObjToken: FileListDefine.ObjToken, with connection: Connection) -> Set<String> {
        guard let table = table else {
            DocsLogger.info("RawDataTable is nil", component: LogComponents.db)
            return []
        }
        do {
            let filter = table.filter(CVSqlDefine.Rd.objToken == inObjToken)
            let records = try connection.prepareRowIterator(filter).map({ $0 })
            var needSyncChannels = Set<String>()
            for record in records {
                let channel = DocsTableUtil.getNCOriColumn(CVSqlDefine.Rd.key, record: record)
                let needSyncValue = DocsTableUtil.getNCOriColumn(CVSqlDefine.Rd.needSync, record: record)
                if let needSyncValue = needSyncValue, let channel = channel, needSyncValue == true {
                    needSyncChannels.insert(channel)
                }
            }
            return needSyncChannels
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .cache)
            DocsLogger.error("获取H5DataRecord失败", error: error, component: LogComponents.db)
            return []
        }
    }
    
    func getNeedSyncTokens(with connection: Connection) -> Set<String> {
        guard let table = table else {
            DocsLogger.info("RawDataTable is nil", component: LogComponents.db)
            return []
        }
        do {
            let filter = table.filter(CVSqlDefine.Rd.needSync == true)
            let records = try connection.prepareRowIterator(filter).map({ $0 })
            var tokens = Set<String>()
            for record in records {
                if let token = DocsTableUtil.getNCOriColumn(CVSqlDefine.Rd.objToken, record: record) {
                    tokens.insert(token)
                }
            }
            return tokens
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .cache)
            DocsLogger.error("获取H5DataRecord失败", error: error, component: LogComponents.db)
            return []
        }
    }

    func update(_ record: H5DataRecord, with connection: Connection) throws {
        guard let table = table else {
            DocsLogger.error("RawDataTable is nil", component: LogComponents.db)
            throw(NSError(domain: "RawDataTable is nil", code: 1))
        }
        do {
            let md5Key = record.key.md5()
            if record.payload == nil {
                let filter = table.filter(CVSqlDefine.Rd.objToken == record.objToken && CVSqlDefine.Rd.key == md5Key)
                try connection.run(filter.delete())
            } else {
                let isBigData = record.saveInfo?.isBigData ?? false
                let editTime = Date.timeIntervalSinceReferenceDate
                let dataInDB: Data? = isBigData ? nil : record.saveInfo?.encodedData
                var cacheFrom = record.cacheFrom.rawValue
                if UserScopeNoChangeFG.GXY.docsFeedPreloadCentralizedEnable, (record.key.isClientVarKey || record.key.hasSuffix(DocsType.htmlCacheKey))
                {
                    // 读出原来字段,以第一次来源为准
                    let filter = table.filter(CVSqlDefine.Rd.objToken == record.objToken && CVSqlDefine.Rd.key == md5Key)
                    let records = try connection.prepareRowIterator(filter).map({ $0 })
                    for record in records {
                        if let cacheFromDB = DocsTableUtil.getNCOriColumn(CVSqlDefine.Rd.cacheFrom, record: record), cacheFromDB != H5DataRecordFrom.cacheFromUnKnown.rawValue, cacheFrom != H5DataRecordFrom.cacheFromPreload.rawValue {
                            //以第一次来源为准，但若数据来自于预加载，则cacheFrom应更新为预加载来源
                            cacheFrom = cacheFromDB
                            break
                        }
                    }
                    let update = table.insert(or: .replace,
                                              CVSqlDefine.Rd.objToken <- record.objToken,
                                              CVSqlDefine.Rd.needSync <- record.needSync,
                                              CVSqlDefine.Rd.key <- md5Key,
                                              CVSqlDefine.Rd.data <- dataInDB,
                                              CVSqlDefine.Rd.type <- record.type?.rawValue,
                                              CVSqlDefine.Rd.dataSize <- record.saveInfo?.encodedData?.count,
                                              CVSqlDefine.Rd.updateTime <- editTime,
                                              CVSqlDefine.Rd.accessTime <- editTime,
                                              CVSqlDefine.Rd.cacheFrom <- cacheFrom
                                              )
                    try connection.run(update)
                } else {
                    let update = table.insert(or: .replace,
                                              CVSqlDefine.Rd.objToken <- record.objToken,
                                              CVSqlDefine.Rd.needSync <- record.needSync,
                                              CVSqlDefine.Rd.key <- md5Key,
                                              CVSqlDefine.Rd.data <- dataInDB,
                                              CVSqlDefine.Rd.type <- record.type?.rawValue,
                                              CVSqlDefine.Rd.dataSize <- record.saveInfo?.encodedData?.count,
                                              CVSqlDefine.Rd.updateTime <- editTime,
                                              CVSqlDefine.Rd.accessTime <- editTime
                                              )
                    try connection.run(update)
                }
            }
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .cache)
            DocsLogger.error("insert H5DataRecord", error: error, component: LogComponents.db)
            throw error
        }
    }

    func changeObjToken(_ orig: FileListDefine.ObjToken, to target: FileListDefine.ObjToken, with connection: Connection) {
        guard let table = table else {
            DocsLogger.info("RawDataTable is nil", component: LogComponents.db)
            return
        }
        do {
            let filter = table.filter(CVSqlDefine.Rd.objToken == orig)
            let update = filter.update(CVSqlDefine.Rd.objToken <- target)
            try connection.run(update)
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .cache)
            DocsLogger.error("changeObjToken fail", error: error, component: LogComponents.db)
        }
    }

    func deleteItemsByObjToken(_ origToken: FileListDefine.ObjToken, connection: Connection) -> Bool {
        guard let table = table else {
            DocsLogger.info("RawDataTable is nil", component: LogComponents.db)
            return false
        }
        do {
            //删除
            let matched = table.filter(CVSqlDefine.Rd.objToken == origToken)
            try connection.run(matched.delete())
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .cache)
            DocsLogger.error("deleteItemsByObjToken", error: error, component: LogComponents.db)
            return false
        }
        return true
    }

//    func getChangeSetAndNeedSyncItem(connection: Connection) -> [CVSqlDefine.SqlSyncItem] {
//        guard let table = table else {
//            DocsLogger.info("RawDataTable is nil", component: LogComponents.db)
//            return []
//        }
//        do {
//            var sqlItems = [CVSqlDefine.SqlSyncItem]()
//            let md5Key = String.docsChangeSetKey.md5()
//            let query = table.select(CVSqlDefine.Rd.objToken, CVSqlDefine.Rd.data)
//                .filter(CVSqlDefine.Rd.needSync == true && CVSqlDefine.Rd.key == md5Key)
//            let records = try connection.prepareRowIterator(query).map({ $0 })
//            for record in records {
//                let objToken = DocsTableUtil.getNCOriColumn(CVSqlDefine.Rd.objToken, record: record)
//                let dataValue = DocsTableUtil.getNCOriColumn(CVSqlDefine.Rd.data, record: record)
//                if let objToken = objToken {
//                    let unArchived = dataValue.map { NSKeyedUnarchiver.unarchiveObject(with: $0) } as? NSCoding
//                    let item = CVSqlDefine.SqlSyncItem(objToken: objToken, md5Key: md5Key, payload: unArchived)
//                    sqlItems.append(item)
//                }
//            }
//            return sqlItems
//        } catch {
//            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .cache)
//            DocsLogger.error("getChangeSetAndNeedSyncItem", error: error, component: LogComponents.db)
//            return []
//        }
//    }

    func getItemsOrderByAscTimeInTokenGroup(maxCount: Int, connection: Connection, manuOfflineTokens: [FileListDefine.ObjToken]) -> [CVSqlDefine.SqlGroupInfo] {
        guard let table = table else {
            DocsLogger.info("RawDataTable is nil", component: LogComponents.db)
            return []
        }
        do {
            var sqlItems = [CVSqlDefine.SqlGroupInfo]()
            let maxAccessTimeInGroup = CVSqlDefine.Rd.accessTime.max
            let maxSync = CVSqlDefine.Rd.needSync.max
            let sumOfDataSize = CVSqlDefine.Rd.dataSize.sum
            let query = table.select(CVSqlDefine.Rd.objToken, maxSync, sumOfDataSize, maxAccessTimeInGroup)
                .group(CVSqlDefine.Rd.objToken, having: (maxSync == false) && (manuOfflineTokens.contains(CVSqlDefine.Rd.objToken) == false))
                .order(maxAccessTimeInGroup)
                .limit(maxCount)
            let records = try connection.prepareRowIterator(query).map({ $0 })
            for record in records {
                let objToken = DocsTableUtil.getNCOriColumn(CVSqlDefine.Rd.objToken, record: record)
                if let objToken = objToken {
                    let maxSyncValue = DocsTableUtil.getNCOriColumn(maxSync, record: record) ?? false
                    let groupDataSize = DocsTableUtil.safeGetColumn(column: sumOfDataSize, record: record) ?? 0
                    let maxAccessTime = DocsTableUtil.safeGetColumn(column: maxAccessTimeInGroup, record: record)
                    let itemRecord = CVSqlDefine.SqlGroupInfo(objToken: objToken, maxSync: maxSyncValue, groupDataSize: groupDataSize, maxAccessTime: maxAccessTime)
                    sqlItems.append(itemRecord)
                }
            }
            return sqlItems
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .cache)
            DocsLogger.error("getItemsOrderByAscTimeInTokenGroup", error: error, component: LogComponents.db)
            return []
        }
    }

    func getTotalDataSize(connection: Connection, manuOfflineTokens: [FileListDefine.ObjToken]) -> Int? {
        guard let table = table else {
            DocsLogger.info("RawDataTable is nil", component: LogComponents.db)
            return nil
        }
        do {
            let sumOfDataSize = CVSqlDefine.Rd.dataSize.sum
            //let query = table.select(sumOfDataSize).filter(CVSqlDefine.Rd.needSync == false)
            let sum = try connection.scalar(table.select(sumOfDataSize).filter((CVSqlDefine.Rd.needSync == false) && (manuOfflineTokens.contains(CVSqlDefine.Rd.objToken) == false)))
            return sum
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .cache)
            DocsLogger.error("getTotalDataSize", error: error, component: LogComponents.db)
            return nil
        }
    }

}
