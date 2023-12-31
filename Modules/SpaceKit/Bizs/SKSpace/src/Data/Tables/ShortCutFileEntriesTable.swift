//
//  NewFileEntrisTable.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/7/8.
// SpaceEntry 的表
// 主值 objToken，列为各个属性

import SQLite
import Foundation
import SwiftyJSON
import SKFoundation
import SKCommon
import SpaceInterface

public final class ShortCutFileEntriesTable {
    var db: Connection?
    let table: Table!
    private let name = Expression<String?>("name")
    private let token = Expression<String>("token")
    private let objtoken = Expression<String>("obj_token")
    private let type = Expression<Int>("type")
    private let openTime = Expression<TimeInterval?>("open_time")
    private let ownerID = Expression<String?>("create_uid")
    private let editUid = Expression<String?>("edit_uid")
    private let editTime = Expression<TimeInterval?>("edit_time")
    private let createTime = Expression<TimeInterval?>("add_time")// recent，没有add_time
    private let urlStr = Expression<String?>("url")
    private let extra = Expression<String?>("extra")
    private let shareTime = Expression<TimeInterval?>("share_time")
    private let thumbnail = Expression<String?>("thumbnail")
    private let needSync = Expression<Bool?>(DocsOfflineSyncManager.needSyncKey)
    private let isTop = Expression<Bool>("is_top")
    private let isPined = Expression<Bool>("is_pined")
    private let isStared = Expression<Bool>("is_stared")
    private let myEditTime = Expression<TimeInterval?>("my_edit_time")
    private let activityTime = Expression<TimeInterval?>("activity_time")
    private let isSetManuOffline = Expression<Bool?>(ManualOfflineFile.isSetManuOfflineKey)
    private let hadShownManuStatus = Expression<Bool?>(ManualOfflineFile.hadShownManuStatusKey)
    private let addManuOfflineTime = Expression<TimeInterval?>(ManualOfflineFile.addManuOfflineTimeKey)
    private let manuOfflineSynStatus = Expression<Int?>(ManualOfflineFile.syncStatusKey)
    private let thumbnailExtra = Expression<String?>(FileListServerKeys.thumbnailExtra.rawValue)

    // 定义成UInt64, 没有遵守Value协议，组件报错
    private let fileSize = Expression<Int64>(ManualOfflineFile.fileSizeKey)
    private let shareVersion = Expression<Int?>(FileListServerKeys.shareVersion.rawValue)
    private let ownerType = Expression<Int?>(FileListServerKeys.ownerType.rawValue)
    private let nodeType = Expression<Int?>(FileListServerKeys.nodeType.rawValue)

    public let iconKey = Expression<String?>(FileListServerKeys.iconKey.rawValue)
    public let iconType = Expression<Int?>(FileListServerKeys.iconType.rawValue)
    public let iconFSUnit = Expression<String?>(FileListServerKeys.iconFSUnit.rawValue)

    public let secretKeyDelete = Expression<Bool?>(FileListServerKeys.secretKeyDelete.rawValue)

    private let docConnection: DocsDBConnectionProvidor

    init(_ docConnection: DocsDBConnectionProvidor = Connection.docs) {
        self.docConnection = docConnection
        table = Table("ShortCutFileEntriesTable")
        db = docConnection.file
        DocsLogger.info("ShortCutFileEntriesTable init with db \(String(describing: db)) ")
        do {
            try db?.run(createTableCMD())
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error)
            DocsLogger.error("create ShortCutFileEntriesTable error", error: error, component: LogComponents.db)
        }
    }

    func createTableCMD() -> String {
        return table.create(ifNotExists: true) { tbl in
            tbl.column(token, primaryKey: true)
            tbl.column(objtoken)
            tbl.column(name)
            tbl.column(type)
            tbl.column(openTime)
            tbl.column(ownerID)
            tbl.column(editUid)
            tbl.column(editTime)
            tbl.column(createTime)
            tbl.column(urlStr)
            tbl.column(extra)
            tbl.column(shareTime)
            tbl.column(thumbnail)
            tbl.column(needSync)
            tbl.column(isTop)
            tbl.column(isPined)
            tbl.column(isStared)
            tbl.column(myEditTime)
            tbl.column(activityTime)
            tbl.column(isSetManuOffline)
            tbl.column(fileSize)
            tbl.column(hadShownManuStatus)
            tbl.column(addManuOfflineTime)
            tbl.column(manuOfflineSynStatus)
            tbl.column(shareVersion)
            tbl.column(ownerType)
            tbl.column(nodeType)
            tbl.column(thumbnailExtra)
            tbl.column(iconKey)
            tbl.column(iconType)
            tbl.column(iconFSUnit)
            tbl.column(secretKeyDelete)
        }
    }

    func getFileEntries(_ tokens: [String]) -> [SpaceEntry] {
        var entries = [SpaceEntry]()
        do {
            let query = table.filter(tokens.contains(token))
            guard let records = try db?.prepareRowIterator(query).map({ $0 }) else {
                DocsLogger.info("db is nil or err occur")
                return entries
            }

            for record in records {
                let typeOri = DocsTableUtil.getOriColumn(type, record: record)
                let tokenOri = DocsTableUtil.getOriColumn(token, record: record)
                guard let typeReal = typeOri, tokenOri != nil else {
                    DocsLogger.info("get unrecognized doctype from db")
                    continue
                }
                let docType = DocsType(rawValue: typeReal)
                let fileEntry = parseFileData(record, for: docType)
                entries.append(fileEntry)
            }
        } catch {
            DocsLogger.error("数据库相关", error: error, component: LogComponents.db)
            DBErrorStatistics.dbStatisticsFor(error: error)
        }
        DocsLogger.debug("$DB-SpaceEntry 从DB取出fileEntry：\(entries.count)")
        return entries
    }


    private func insert(_ fileEntry: SpaceEntry) {
        do {
            var extraString: String?
            if let data = try? JSONSerialization.data(withJSONObject: fileEntry.extra ?? [:], options: []) {
                extraString = String(data: data, encoding: String.Encoding.utf8)
            }

            var thumbExtraString: String?
            if let thumbExtraObj = fileEntry.thumbnailExtra {
                if JSONSerialization.isValidJSONObject(thumbExtraObj),
                   let data = try? JSONSerialization.data(withJSONObject: thumbExtraObj, options: []) {
                    thumbExtraString = String(data: data, encoding: String.Encoding.utf8)
                } else {
                    DocsLogger.error("fileEntry.thumbnailExtra encode err \(String(describing: fileEntry.thumbnailExtra))", component: LogComponents.db)
                    DBErrorStatistics.dbCustomerReport(errorCode: .jsonEncodeErrer, msg: "fileEntry.thumbnailExtra encode")
                    spaceAssertionFailure()
                }
            }

            var iconType = SpaceEntry.IconType.unknow.rawValue
            if  let iconTypeRealValue = fileEntry.customIcon?.iconType.rawValue {
                iconType = iconTypeRealValue
            }

            let fileSize = Int64(fileEntry.fileSize)
            let insert = table.insert(or: .replace,
                                      self.name <- fileEntry.name,
                                      self.objtoken <- fileEntry.objToken,
                                      self.token <- fileEntry.nodeToken,
                                      self.type <- fileEntry.type.rawValue,
                                      self.openTime <- fileEntry.openTime,
                                      self.ownerID <- fileEntry.ownerID,
                                      self.editUid <- fileEntry.editUid,
                                      self.editTime <- fileEntry.editTime,
                                      self.urlStr <- fileEntry.shareUrl,
                                      self.createTime <- fileEntry.createTime,
                                      self.extra <- extraString,
                                      self.needSync <- fileEntry.isSyncing,
                                      self.shareTime <- fileEntry.shareTime,
                                      self.isStared <- fileEntry.stared,
                                      self.isPined <- fileEntry.pined,
                                      self.isTop <- fileEntry.isTop,
                                      self.thumbnail <- fileEntry.thumbnailUrl,
                                      self.isSetManuOffline <- fileEntry.isSetManuOffline,
                                      self.fileSize <- fileSize,
                                      self.hadShownManuStatus <- fileEntry.hadShownManuStatus,
                                      self.activityTime <- fileEntry.activityTime,
                                      self.myEditTime <- fileEntry.myEditTime,
                                      self.addManuOfflineTime <- fileEntry.addManuOfflineTime,
                                      self.shareVersion <- fileEntry.shareVersion,
                                      self.ownerType <- fileEntry.ownerType,
                                      self.nodeType <- fileEntry.nodeType,
                                      self.thumbnailExtra <- thumbExtraString,
                                      self.iconKey <- fileEntry.customIcon?.iconKey,
                                      self.iconType <- iconType,
                                      self.iconFSUnit <- fileEntry.customIcon?.iconFSUnit,
                                      self.manuOfflineSynStatus <- fileEntry.syncStatus.downloadStatus.rawValue,
                                      self.secretKeyDelete <- fileEntry.secretKeyDelete

            )
            try db?.run(insert)
        } catch {
            DocsLogger.error("数据库相关", error: error, component: LogComponents.db)
            DBErrorStatistics.dbStatisticsFor(error: error)
        }
    }

    func insert(_ fileEntries: [SpaceEntry]) {
        //频繁的循环插入/删除操作导致内存增加，使用releasePool释放
        fileEntries.forEach { entry in
            autoreleasepool {
                insert(entry)
            }
        }
    }

    func update(_ fileEntries: [SpaceEntry]) {
        let beforeOptTime: TimeInterval = NSDate().timeIntervalSince1970
        delete(fileEntries)
        insert(fileEntries)
        let afterOptTime: TimeInterval = NSDate().timeIntervalSince1970
        DocsLogger.info("[db test] update file EntryCount\(fileEntries.count) - \(afterOptTime - beforeOptTime)", component: LogComponents.db)
    }

    func delete(_ fileEntries: [SpaceEntry]) {
        do {
            // 分段删除，因为会报错 too many SQL variables
            // https://stackoverflow.com/questions/7106016/too-many-sql-variables-error-in-django-witih-sqlite3
            var fileEntries = fileEntries
            var currentCount = fileEntries.count
            let sliceMaxCount = 100
            while currentCount > 0 {
                //频繁的循环插入/删除操作导致内存增加，使用releasePool释放
                try autoreleasepool {
                    //找到要删除的
                    let sliceCount = min(sliceMaxCount, currentCount)
                    let sliceToDelete = fileEntries.prefix(sliceCount)

                    //删除
                    let matched = table.filter(sliceToDelete.map { $0.nodeToken }.contains(token))
                    try db?.run(matched.delete())

                    //更新
                    fileEntries.removeFirst(sliceCount)
                    currentCount = fileEntries.count
                }
            }
        } catch {
            DocsLogger.error("删除 fileEntries 失败", error: error, component: LogComponents.db)
            DBErrorStatistics.dbStatisticsFor(error: error)
            spaceAssertionFailure()
        }
    }

    private func parseFileData(_ record: Row, for docType: DocsType) -> SpaceEntry {
        let fileEntry = SpaceEntryFactory.createEntry(type: docType, nodeToken: record[token], objToken: record[objtoken])
        var node: [String: Any] = [:]
        node["name"]            = DocsTableUtil.getOriColumn(name, record: record)
        node["open_time"]       = DocsTableUtil.getOriColumn(openTime, record: record)
        node["owner_id"]        = DocsTableUtil.getOriColumn(ownerID, record: record)
        node["edit_uid"]        = DocsTableUtil.getOriColumn(editUid, record: record)
        node["url"]             = DocsTableUtil.getOriColumn(urlStr, record: record)
        node["edit_time"]       = DocsTableUtil.getOriColumn(editTime, record: record)
        node["share_time"]      = DocsTableUtil.getOriColumn(shareTime, record: record)
        node["thumbnail"]       = DocsTableUtil.getOriColumn(thumbnail, record: record)
        node["create_time"]     = DocsTableUtil.getOriColumn(createTime, record: record)
        node["is_pined"]        = DocsTableUtil.getOriColumn(isPined, record: record)
        node["is_stared"]       = DocsTableUtil.getOriColumn(isStared, record: record)
        node["is_top"]          = DocsTableUtil.getOriColumn(isTop, record: record)
        node["my_edit_time"]    = DocsTableUtil.getOriColumn(myEditTime, record: record)
        node["activity_time"]   = DocsTableUtil.getOriColumn(activityTime, record: record)
        
        // 注意！: 后面新增的字段都必须用safeGetColumn获取数据
        node[ManualOfflineFile.isSetManuOfflineKey]         = DocsTableUtil.safeGetColumn(column: isSetManuOffline, record: record)
        node[ManualOfflineFile.hadShownManuStatusKey]       = DocsTableUtil.safeGetColumn(column: hadShownManuStatus, record: record)
        node[DocsOfflineSyncManager.needSyncKey]            = DocsTableUtil.safeGetColumn(column: needSync, record: record)
        node[ManualOfflineFile.fileSizeKey]                 = UInt64(DocsTableUtil.safeGetColumn(column: fileSize, record: record) ?? 0)
        node[ManualOfflineFile.addManuOfflineTimeKey]       = DocsTableUtil.safeGetColumn(column: addManuOfflineTime, record: record)
        node[ManualOfflineFile.syncStatusKey]               = DocsTableUtil.safeGetColumn(column: manuOfflineSynStatus, record: record)
        
        node[FileListServerKeys.shareVersion.rawValue]      = DocsTableUtil.safeGetColumn(column: shareVersion, record: record)
        node[FileListServerKeys.ownerType.rawValue]         = DocsTableUtil.safeGetColumn(column: ownerType, record: record)
        node[FileListServerKeys.nodeType.rawValue]        = DocsTableUtil.safeGetColumn(column: nodeType, record: record)


        node[FileListServerKeys.iconKey.rawValue]           = DocsTableUtil.safeGetColumn(column: iconKey, record: record)
        node[FileListServerKeys.iconType.rawValue]          = DocsTableUtil.safeGetColumn(column: iconType, record: record)
        node[FileListServerKeys.iconFSUnit.rawValue]        = DocsTableUtil.safeGetColumn(column: iconFSUnit, record: record)
        node[FileListServerKeys.secretKeyDelete.rawValue]   = DocsTableUtil.safeGetColumn(column: secretKeyDelete, record: record)

        let extraColumn = DocsTableUtil.safeGetColumn(column: extra, record: record)
        if let jsonData = extraColumn?.data(using: .utf8), let dic = try? JSONSerialization.jsonObject(with: jsonData, options: .mutableLeaves) as? [String: Any] {
            node["extra"] = dic
        }
        
        let thumbnailExtraColumn = DocsTableUtil.safeGetColumn(column: thumbnailExtra, record: record)
        if let jsonData = thumbnailExtraColumn?.data(using: .utf8), let dic = try? JSONSerialization.jsonObject(with: jsonData, options: .mutableLeaves) as? [String: Any] {
            node[FileListServerKeys.thumbnailExtra.rawValue] = dic
        }

        fileEntry.updatePropertiesFrom(JSON(node))
        return fileEntry
    }
}
