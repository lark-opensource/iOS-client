//
//  MetaTable.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/8/27.
//  
//  存储从前端设置的数据里解析出来的元数据

import SQLite
import SKFoundation
import SwiftyJSON

final class FileMetaDataTable {
    var table: Table?
    
    init() {
    }
    
    func createIfNotExistWithConnection(_ connection: Connection) {
        table = Table(CVSqlDefine.Table.fileMetaData.rawValue)
        guard let table = table else {
            DocsLogger.info("fileMetaData is nil", component: LogComponents.db)
            return
        }
        let createStr = table.create(ifNotExists: true) { tbl in
            tbl.column(CVSqlDefine.Mt.objToken)
            tbl.column(CVSqlDefine.Mt.hasClientVar)
            tbl.column(CVSqlDefine.Mt.updateTime)
            tbl.primaryKey(CVSqlDefine.Mt.objToken)
        }
        do {
            try connection.run(createStr)
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .cache)
            DocsLogger.error("创建FileMetaDataTable失败", error: error, component: LogComponents.db)
        }
    }

    func getMetaData(by targetObjToken: FileListDefine.ObjToken, with connection: Connection) -> ClientVarMetaData? {
        guard let table = table else {
            DocsLogger.info("fileMetaData is nil", component: LogComponents.db)
            return nil
        }
        do {
            var metaData: ClientVarMetaData?
            let filter = table.filter(CVSqlDefine.Mt.objToken == targetObjToken)
            let records = try connection.prepareRowIterator(filter).map({ $0 })
            for record in records {
                metaData = ClientVarMetaData(objToken: targetObjToken)
                let hasClientValue = DocsTableUtil.getNCOriColumn(CVSqlDefine.Mt.hasClientVar, record: record)
                if let hasClientValue = hasClientValue {
                    metaData?.hasClientVar = hasClientValue
                }
                break
            }
            return metaData
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .cache)
            DocsLogger.error("获取 ClientVarMetaData 失败", error: error, component: LogComponents.db)
            return nil
        }

    }

    func insert(_ record: ClientVarMetaData, with connection: Connection) {
        guard let table = table else {
            DocsLogger.info("fileMetaData is nil", component: LogComponents.db)
            return
        }
        do {
            let update = table.insert(or: .replace,
                                      CVSqlDefine.Mt.objToken <- record.objToken,
                                      CVSqlDefine.Mt.hasClientVar <- record.hasClientVar,
                                      CVSqlDefine.Mt.updateTime <- Date.timeIntervalSinceReferenceDate)
            try connection.run(update)
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .cache)
            DocsLogger.error("插入ClientVarMetaData失败", error: error, component: LogComponents.db)
        }
    }

    func changeObjToken(_ orig: FileListDefine.ObjToken, to target: FileListDefine.ObjToken, with connection: Connection) {
        guard let table = table else {
            DocsLogger.info("fileMetaData is nil", component: LogComponents.db)
            return
        }
        do {
            let filter = table.filter(CVSqlDefine.Mt.objToken == orig)
            let update = filter.update(CVSqlDefine.Mt.objToken <- target)
            try connection.run(update)
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .cache)
            DocsLogger.error("changeObjToken fail", error: error, component: LogComponents.db)
        }
    }

    func deleteItemsByObjToken(_ origToken: FileListDefine.ObjToken, connection: Connection) -> Bool {
        guard let table = table else {
            DocsLogger.info("fileMetaData is nil", component: LogComponents.db)
            return false
        }
        do {
            //删除
            let matched = table.filter(CVSqlDefine.Rd.objToken == origToken)
            try connection.run(matched.delete())
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .cache)
            DocsLogger.error("deleteItemsByObjToken fileMetaData", error: error, component: LogComponents.db)
            return false
        }
        return true
    }
}
