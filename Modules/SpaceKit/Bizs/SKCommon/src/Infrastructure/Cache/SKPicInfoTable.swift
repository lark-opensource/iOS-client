//
//  SKPicInfoTable.swift
//  SKCommon
//
//  Created by chenhuaguan on 2020/8/26.
//

import SQLite
import SKFoundation
import SwiftyJSON

final class SKPicInfoTable {
    var table: Table?

    init() {
    }

    func createIfNotExistWithConnection(_ connection: Connection) {
        table = Table(CVSqlDefine.Table.picInfoData.rawValue)
        guard let table = table else {
            DocsLogger.info("picInfoData is nil", component: LogComponents.db)
            return
        }
        let createStr = table.create(ifNotExists: true) { tbl in
            tbl.column(CVSqlDefine.Pic.objToken)
            tbl.column(CVSqlDefine.Pic.picKey)
            tbl.column(CVSqlDefine.Pic.picType)
            tbl.column(CVSqlDefine.Pic.updateTime)
            tbl.column(CVSqlDefine.Pic.needUpLoad)
            tbl.column(CVSqlDefine.Pic.isDrive)
            tbl.primaryKey(CVSqlDefine.Pic.objToken, CVSqlDefine.Pic.picKey)
        }
        do {
            try connection.run(createStr)
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .cache)
            DocsLogger.error("创建picInfoData失败", error: error, component: LogComponents.db)
        }
    }

    func getPicInfoData(tokens: [FileListDefine.ObjToken], ignoreNeedUpload: Bool, with connection: Connection) -> [SKPicMapInfo]? {
        guard let table = table else {
            DocsLogger.info("picInfoData is nil", component: LogComponents.db)
            return nil
        }
        do {
            var picInfoArray: [SKPicMapInfo] = []
            let filter = ignoreNeedUpload ? table.filter(CVSqlDefine.Pic.needUpLoad == false && tokens.contains(CVSqlDefine.Pic.objToken)) : table.filter(tokens.contains(CVSqlDefine.Pic.objToken))
            let records = try connection.prepareRowIterator(filter).map({ $0 })
            for record in records {
                let objToken = DocsTableUtil.getNCOriColumn(CVSqlDefine.Pic.objToken, record: record)
                let picKey = DocsTableUtil.getNCOriColumn(CVSqlDefine.Pic.picKey, record: record)
                let picType = DocsTableUtil.getNCOriColumn(CVSqlDefine.Pic.picType, record: record)
                let needUpLoad = DocsTableUtil.getNCOriColumn(CVSqlDefine.Pic.needUpLoad, record: record)
                let updateTime = DocsTableUtil.getNCOriColumn(CVSqlDefine.Pic.updateTime, record: record)
                let isDrive = DocsTableUtil.getNCOriColumn(CVSqlDefine.Pic.isDrive, record: record)

                if let objToken = objToken, let picKey = picKey, let picType = picType, let needUpLoad = needUpLoad, let updateTime = updateTime {
                    let picInfo = SKPicMapInfo(objToken: objToken, picKey: picKey, picType: picType, needUpLoad: needUpLoad, isDrive: isDrive, updateTime: updateTime)
                    picInfoArray.append(picInfo)
                }
            }
            return picInfoArray
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .cache)
            DocsLogger.error("获取 picInfoData 失败", error: error, component: LogComponents.db)
            return nil
        }

    }

    func insert(_ picInfo: SKPicMapInfo, with connection: Connection) {
        guard let table = table else {
            DocsLogger.info("picInfoData is nil", component: LogComponents.db)
            return
        }
        do {
            let update = table.insert(or: .replace,
                                      CVSqlDefine.Pic.objToken <- picInfo.objToken,
                                      CVSqlDefine.Pic.picKey <- picInfo.picKey,
                                      CVSqlDefine.Pic.picType <- picInfo.picType,
                                      CVSqlDefine.Pic.needUpLoad <- picInfo.needUpLoad,
                                      CVSqlDefine.Pic.isDrive <- picInfo.isDrive,
                                      CVSqlDefine.Pic.updateTime <- picInfo.updateTime ?? Date.timeIntervalSinceReferenceDate)
            try connection.run(update)
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .cache)
            DocsLogger.error("插入picInfoData失败", error: error, component: LogComponents.db)
        }
    }

    /*
    func findNeedUploadPics(with connection: Connection) -> [SKPicMapInfo] {
        guard let table = table else {
            DocsLogger.info("findNeedUploadPics is nil", component: LogComponents.db)
            return []
        }
        do {
            var picInfoArray: [SKPicMapInfo] = []
            let filter = table.filter(CVSqlDefine.Pic.needUpLoad == true)
            let records = try connection.prepareRowIterator(filter).map({ $0 })
            for record in records {
                let objToken = DocsTableUtil.getNCOriColumn(CVSqlDefine.Pic.objToken, record: record)
                let picKey = DocsTableUtil.getNCOriColumn(CVSqlDefine.Pic.picKey, record: record)
                let picType = DocsTableUtil.getNCOriColumn(CVSqlDefine.Pic.picType, record: record)
                let needUpLoad = DocsTableUtil.getNCOriColumn(CVSqlDefine.Pic.needUpLoad, record: record)
                let updateTime = DocsTableUtil.getNCOriColumn(CVSqlDefine.Pic.updateTime, record: record)
                let isDrive = DocsTableUtil.getNCOriColumn(CVSqlDefine.Pic.isDrive, record: record)

                if let objToken = objToken, let picKey = picKey, let picType = picType, let needUpLoad = needUpLoad, let updateTime = updateTime {
                    let picInfo = SKPicMapInfo(objToken: objToken, picKey: picKey, picType: picType, needUpLoad: needUpLoad, isDrive: isDrive, updateTime: updateTime)
                    picInfoArray.append(picInfo)
                }
            }
            return picInfoArray
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .cache)
            DocsLogger.error("获取 findNeedUploadPics 失败", error: error, component: LogComponents.db)
            return []
        }
    }
     */

    func deleteItemsByObjToken(_ origToken: FileListDefine.ObjToken, connection: Connection) -> Bool {
        guard let table = table else {
            DocsLogger.info("picInfoData is nil", component: LogComponents.db)
            return false
        }
        do {
            //删除
            let matched = table.filter(CVSqlDefine.Pic.objToken == origToken)
            try connection.run(matched.delete())
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .cache)
            DocsLogger.error("deleteItemsByObjToken picInfoData", error: error, component: LogComponents.db)
            return false
        }
        return true
    }

//    func deleteItemsInfoArray(picInfoArray: [SKPicMapInfo], connection: Connection) -> Bool {
//        guard let table = table else {
//            DocsLogger.info("picInfoData is nil", component: LogComponents.db)
//            return false
//        }
//        do {
//            //删除
//            let picKeys = picInfoArray.map { $0.picKey }
//            let matched = table.filter(picKeys.contains(CVSqlDefine.Pic.picKey))
//            try connection.run(matched.delete())
//        } catch {
//            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .cache)
//            DocsLogger.error("deleteItemsByObjToken && picKey", error: error, component: LogComponents.db)
//            return false
//        }
//        return true
//    }
}
