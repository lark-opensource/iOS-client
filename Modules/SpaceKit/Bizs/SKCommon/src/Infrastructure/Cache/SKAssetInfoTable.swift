//
//  SKAssetInfoTable.swift
//  SKCommon
//
//  Created by chenhuaguan on 2020/12/2.
// swiftlint:disable line_length

import SQLite
import SKFoundation
import SwiftyJSON
import SpaceInterface

extension SKAssetInfo: CustomStringConvertible {
    public var description: String {
        return "PicMapInfo: objToken=\(objToken.encryptToken), fileToken=\(fileToken.encryptToken),uploadKey=\(uploadKey), assetType=\(assetType)"
    }
}

final class SKAssetInfoTable {
    var table: Table?

    init() {
    }

    func createIfNotExistWithConnection(_ connection: Connection) {
        table = Table(CVSqlDefine.Table.assetInfoData.rawValue)
        guard let table = table else {
            DocsLogger.info("assetInfoData is nil", component: LogComponents.db)
            return
        }

        let createStr = table.create(ifNotExists: true) { tbl in
            tbl.column(CVSqlDefine.Asset.objToken)
            tbl.column(CVSqlDefine.Asset.uuid)
            tbl.column(CVSqlDefine.Asset.fileToken)
            tbl.column(CVSqlDefine.Asset.picType)
            tbl.column(CVSqlDefine.Asset.cacheKey)
            tbl.column(CVSqlDefine.Asset.sourceUrl)
            tbl.column(CVSqlDefine.Asset.uploadKey)
            tbl.column(CVSqlDefine.Asset.assetType)
            tbl.column(CVSqlDefine.Asset.fileSize)
            tbl.column(CVSqlDefine.Asset.source)
            tbl.column(CVSqlDefine.Asset.backupDouble)
            tbl.column(CVSqlDefine.Asset.backupInt1)
            tbl.column(CVSqlDefine.Asset.backupStr1)
            tbl.column(CVSqlDefine.Asset.backupStr2)
            tbl.primaryKey(CVSqlDefine.Asset.objToken, CVSqlDefine.Asset.uuid, CVSqlDefine.Asset.fileToken, CVSqlDefine.Asset.sourceUrl)
        }
        do {
            try connection.run(createStr)
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .cache)
            DocsLogger.error("创建AssetTable失败", error: error, component: LogComponents.db)
        }
    }

//    func getAssetInfoData(tokens: [FileListDefine.ObjToken], with connection: Connection) -> [SKAssetInfo]? {
//        guard let table = table else {
//            DocsLogger.info("AssetTable is nil", component: LogComponents.db)
//            return nil
//        }
//        do {
//            var assetInfoArray: [SKAssetInfo] = []
//            let filter = table.filter(tokens.contains(CVSqlDefine.Asset.objToken))
//            let records = try connection.prepareRowIterator(filter).map({ $0 })
//            for record in records {
//                let objToken = DocsTableUtil.getNCOriColumn(CVSqlDefine.Asset.objToken, record: record)
//                let uuid = DocsTableUtil.getNCOriColumn(CVSqlDefine.Asset.uuid, record: record)
//                let fileToken = DocsTableUtil.getNCOriColumn(CVSqlDefine.Asset.fileToken, record: record)
//                let picType = DocsTableUtil.getNCOriColumn(CVSqlDefine.Asset.picType, record: record)
//                let cacheKey = DocsTableUtil.getNCOriColumn(CVSqlDefine.Asset.cacheKey, record: record)
//                let sourceUrl = DocsTableUtil.getNCOriColumn(CVSqlDefine.Asset.sourceUrl, record: record)
//                let uploadKey = DocsTableUtil.getNCOriColumn(CVSqlDefine.Asset.uploadKey, record: record)
//                let assetType = DocsTableUtil.getNCOriColumn(CVSqlDefine.Asset.assetType, record: record)
//                let fileSize = DocsTableUtil.getNCOriColumn(CVSqlDefine.Asset.fileSize, record: record)
//                let source = DocsTableUtil.getNCOriColumn(CVSqlDefine.Asset.source, record: record)
//
//                let assetInfo = SKAssetInfo(objToken: objToken, uuid: uuid, fileToken: fileToken, picType: picType, cacheKey: cacheKey, sourceUrl: sourceUrl, uploadKey: uploadKey, fileSize: fileSize, assetType: assetType, source: source)
//                assetInfoArray.append(assetInfo)
//            }
//            return assetInfoArray
//        } catch {
//            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .cache)
//            DocsLogger.error("获取 getAssetInfoData 失败", error: error, component: LogComponents.db)
//            return nil
//        }
//    }

    func getAssetInfoData(uuids: [String], objToken: String?, with connection: Connection) -> [SKAssetInfo]? {
        guard let table = table else {
            DocsLogger.info("AssetTable is nil", component: LogComponents.db)
            return nil
        }
        do {
            var assetInfoArray: [SKAssetInfo] = []
            var condition: SQLite.Expression<Bool> = uuids.contains(CVSqlDefine.Asset.uuid)
            if let objToken = objToken {
                condition = uuids.contains(CVSqlDefine.Asset.uuid) && CVSqlDefine.Asset.objToken == objToken
            }
            let filter = table.filter(condition)
            let records = try connection.prepareRowIterator(filter).map({ $0 })
            for record in records {
                let assetInfo = getAssetWithRecord(record)
                assetInfoArray.append(assetInfo)
            }
            return assetInfoArray
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .cache)
            DocsLogger.error("获取 getAssetInfoData 失败", error: error, component: LogComponents.db)
            return nil
        }
    }

    func getAssetInfoData(fileTokens: [String], with connection: Connection) -> [SKAssetInfo]? {
        guard let table = table else {
            DocsLogger.info("AssetTable is nil", component: LogComponents.db)
            return nil
        }
        do {
            var assetInfoArray: [SKAssetInfo] = []
            let filter = table.filter(fileTokens.contains(CVSqlDefine.Asset.fileToken))
            let records = try connection.prepareRowIterator(filter).map({ $0 })
            for record in records {
                let assetInfo = getAssetWithRecord(record)
                assetInfoArray.append(assetInfo)
            }
            return assetInfoArray
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .cache)
            DocsLogger.error("获取 getAssetInfoData 失败", error: error, component: LogComponents.db)
            return nil
        }
    }

    private func getAssetWithRecord(_ record: Row) -> SKAssetInfo {
        let objToken = DocsTableUtil.getNCOriColumn(CVSqlDefine.Asset.objToken, record: record)
        let uuid = DocsTableUtil.getNCOriColumn(CVSqlDefine.Asset.uuid, record: record)
        let fileToken = DocsTableUtil.getNCOriColumn(CVSqlDefine.Asset.fileToken, record: record)
        let picType = DocsTableUtil.getNCOriColumn(CVSqlDefine.Asset.picType, record: record)
        let cacheKey = DocsTableUtil.getNCOriColumn(CVSqlDefine.Asset.cacheKey, record: record)
        let sourceUrl = DocsTableUtil.getNCOriColumn(CVSqlDefine.Asset.sourceUrl, record: record)
        let uploadKey = DocsTableUtil.getNCOriColumn(CVSqlDefine.Asset.uploadKey, record: record)
        let assetType = DocsTableUtil.getNCOriColumn(CVSqlDefine.Asset.assetType, record: record)
        let fileSize = DocsTableUtil.getNCOriColumn(CVSqlDefine.Asset.fileSize, record: record)
        let source = DocsTableUtil.getNCOriColumn(CVSqlDefine.Asset.source, record: record)
        return SKAssetInfo(objToken: objToken, uuid: uuid, fileToken: fileToken, picType: picType, cacheKey: cacheKey, sourceUrl: sourceUrl, uploadKey: uploadKey, fileSize: fileSize, assetType: assetType, source: source)
    }

    func updateFileToken(uuid: String, fileToken: String, objToken: String?, with connection: Connection) {
        guard let table = table else {
            DocsLogger.info("AssetTable is nil", component: LogComponents.db)
            return
        }
        do {
            var condition: SQLite.Expression<Bool> = CVSqlDefine.Asset.uuid == uuid
            if let objToken = objToken {
                condition = CVSqlDefine.Asset.uuid == uuid && CVSqlDefine.Asset.objToken == objToken
            }
            let filter = table.filter(condition)
            let update = filter.update(CVSqlDefine.Asset.fileToken <- fileToken)
            try connection.run(update)
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .cache)
            DocsLogger.error("updateFileToken fail", error: error, component: LogComponents.db)
        }
    }

    func insert(_ assetInfo: SKAssetInfo, with connection: Connection) {
        guard let table = table else {
            DocsLogger.info("AssetTable is nil", component: LogComponents.db)
            return
        }
        do {
            let update = table.insert(or: .replace,
                                      CVSqlDefine.Asset.objToken <- assetInfo.objToken,
                                      CVSqlDefine.Asset.uuid <- assetInfo.uuid,
                                      CVSqlDefine.Asset.fileToken <- assetInfo.fileToken,
                                      CVSqlDefine.Asset.picType <- assetInfo.picType,
                                      CVSqlDefine.Asset.cacheKey <- assetInfo.cacheKey,
                                      CVSqlDefine.Asset.sourceUrl <- assetInfo.sourceUrl,
                                      CVSqlDefine.Asset.uploadKey <- assetInfo.uploadKey,
                                      CVSqlDefine.Asset.assetType <- assetInfo.assetType,
                                      CVSqlDefine.Asset.fileSize <- assetInfo.fileSize,
                                      CVSqlDefine.Asset.source <- assetInfo.source
                                     )
            try connection.run(update)
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .cache)
            DocsLogger.error("插入AssetTable失败", error: error, component: LogComponents.db)
        }
    }

//    func deleteItemsByObjToken(_ origToken: FileListDefine.ObjToken, connection: Connection) -> Bool {
//        guard let table = table else {
//            DocsLogger.info("AssetTable is nil", component: LogComponents.db)
//            return false
//        }
//        do {
//            //删除
//            let matched = table.filter(CVSqlDefine.Asset.objToken == origToken)
//            try connection.run(matched.delete())
//        } catch {
//            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .cache)
//            DocsLogger.error("deleteItemsByObjToken AssetTable", error: error, component: LogComponents.db)
//            return false
//        }
//        return true
//    }
}
