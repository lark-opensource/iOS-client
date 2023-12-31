//
//  BTUploadingAttachInfoTable.swift
//  SKBitable
//
//  Created by ByteDance on 2022/10/17.
//

import SQLite
import SKFoundation
import SKCommon
import LarkDocsIcon

extension BTUploadMediaHelper.MediaInfo: Codable {
    var cachePath: URL {
        return storageURL.docs.urlByResolvingApplicationDirectory()
    }
    enum CodingKeys: String, CodingKey {
        case uniqueId
        case storageURL
        case name
        case driveType
        case byteSize
        case width
        case height
        case previewImage
        case destinationBaseID
        case callback
        case mountPoint
        case localPreview
    }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        uniqueId = try container.decode(String.self, forKey: CodingKeys.uniqueId)
        storageURL = try container.decode(URL.self, forKey: CodingKeys.storageURL)
        name = try container.decode(String.self, forKey: CodingKeys.name)
        let fileExt = try container.decode(String.self, forKey: CodingKeys.driveType)
        driveType = DriveFileType(fileExtension: fileExt)
        byteSize = try container.decode(Int.self, forKey: CodingKeys.byteSize)
        width = try container.decodeIfPresent(Int.self, forKey: CodingKeys.width)
        height = try container.decodeIfPresent(Int.self, forKey: CodingKeys.height)
        if let data = try container.decodeIfPresent(Data.self, forKey: CodingKeys.previewImage), let image = UIImage(data: data) {
            self.previewImage = image
        } else {
            self.previewImage = nil
        }
        destinationBaseID = try container.decode(String.self, forKey: CodingKeys.destinationBaseID)
        callback = try container.decode(String.self, forKey: CodingKeys.callback)
        mountPoint = try container.decode(BTUploadMountPoint.self, forKey: CodingKeys.mountPoint)
        localPreview = try container.decode(Bool.self, forKey: CodingKeys.localPreview)
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(uniqueId, forKey: CodingKeys.uniqueId)
        try container.encode(storageURL, forKey: CodingKeys.storageURL)
        try container.encode(name, forKey: CodingKeys.name)
        try container.encode(driveType.rawValue, forKey: CodingKeys.driveType)
        try container.encode(byteSize, forKey: CodingKeys.byteSize)
        try container.encodeIfPresent(width, forKey: CodingKeys.width)
        try container.encodeIfPresent(height, forKey: CodingKeys.height)
        let data = previewImage?.pngData()
        try container.encodeIfPresent(data, forKey: CodingKeys.previewImage)
        try container.encode(destinationBaseID, forKey: CodingKeys.destinationBaseID)
        try container.encode(callback, forKey: CodingKeys.callback)
        try container.encode(mountPoint, forKey: CodingKeys.mountPoint)
        try container.encode(localPreview, forKey: CodingKeys.localPreview)
    }
}

public struct BTUploadingAttachInfo: CustomStringConvertible {
    var originBaseID: String
    var originTableID: String
    var baseID: String
    var tableID: String
    var viewID: String
    var recordID: String
    var fieldID: String
    var attachInfoValue: Data
    var uploadKey: String
    var localtion: BTFieldLocation
    init(location: BTFieldLocation,
         attachInfoValue: Data,
         uploadKey: String) {
        self.originBaseID = location.originBaseID
        self.originTableID = location.originTableID
        self.baseID = location.baseID
        self.tableID = location.tableID
        self.viewID = location.viewID
        self.recordID = location.recordID
        self.fieldID = location.fieldID
        self.attachInfoValue = attachInfoValue
        self.localtion = location
        self.uploadKey = uploadKey
    }
    init(location: BTFieldLocation, mediaInfo: BTUploadMediaHelper.MediaInfo, uploadKey: String) throws {
        self.originBaseID = location.originBaseID
        self.originTableID = location.originTableID
        self.baseID = location.baseID
        self.tableID = location.tableID
        self.viewID = location.viewID
        self.recordID = location.recordID
        self.fieldID = location.fieldID
        self.uploadKey = uploadKey
        self.localtion = location
        self.attachInfoValue = try JSONEncoder().encode(mediaInfo)
    }
    
    public var description: String {
        return "uploadingInfo: originBaseID=\(originBaseID.encryptToken), originTableID=\(originTableID.encryptToken),uploadKey=\(uploadKey)"
    }
    
    func getMediaInfo() throws -> BTUploadMediaHelper.MediaInfo {
        try CodableUtility.decode(BTUploadMediaHelper.MediaInfo.self, data: attachInfoValue)
    }
}

final class BTUploadingAttachInfoTable {
    private let originBaseID = Expression<String>("originBaseID")
    private let originTableID = Expression<String>("originTableID")
    private let baseID = Expression<String>("baseID")
    private let tableID = Expression<String>("tableID")
    private let viewID = Expression<String>("viewID")
    private let recordID = Expression<String>("recordID")
    private let fieldID = Expression<String>("fieldID")
    private let attachInfoValue = Expression<Data>("attachInfoValue")
    private let uploadKey = Expression<String>("uploadKey")
    private var table: Table?
    init() {
    }

    func createIfNotExistWithConnection(name: String, connection: Connection) {
        table = Table(name)
        guard let table = table else {
            DocsLogger.info("BitableUploadingAttachmentInfo is nil", component: LogComponents.btUploadCache)
            return
        }

        let createStr = table.create(ifNotExists: true) { tbl in
            tbl.column(originBaseID)
            tbl.column(originTableID)
            tbl.column(baseID)
            tbl.column(tableID)
            tbl.column(viewID)
            tbl.column(recordID)
            tbl.column(fieldID)
            tbl.column(attachInfoValue)
            tbl.column(uploadKey)
            tbl.primaryKey(originBaseID, uploadKey)
        }
        do {
            try connection.run(createStr)
        } catch {
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .cache)
            DocsLogger.error("create BTUploadingAttachInfoTable failed", error: error, component: LogComponents.btUploadCache)
        }
    }

    func getUploadingAttachInfos(with originBaseID: String, tableID: String, db: Connection) -> [BTUploadingAttachInfo] {
        guard let table = table else {
            DocsLogger.info("Asset Table is nil", component: LogComponents.btUploadCache)
            return []
        }
        
        var infos = [BTUploadingAttachInfo]()
        let express: Expression<Bool>
        if !tableID.isEmpty {
            express = Expression(self.originBaseID == originBaseID && self.tableID == tableID)
        } else {
            express = Expression(self.originBaseID == originBaseID)
        }
        do {
            let rows = try db.prepare(table.where(express))
            for r in rows {
                if let info = parse(row: r) {
                    infos.append(info)
                }
            }
            DocsLogger.info("BTUploadingAttachInfoTable ---  records count \(infos.count)", component: LogComponents.btUploadCache)
            return infos
        } catch {
            spaceAssertionFailure("BTUploadingAttachInfoTable ---  db error when get all records \(error)")
            return infos
        }
    }
    
    func insert(location: BTFieldLocation, mediaInfo: BTUploadMediaHelper.MediaInfo, uploadKey: String, db: Connection) {
        DocsLogger.info("BTUploadingAttachInfoTable -- baseID: \(location.originBaseID.encryptToken), uploadKey: \(uploadKey)")
        guard let table = table else {
            DocsLogger.error("BTUploadingAttachInfoTable -- db or table not exist", component: LogComponents.btUploadCache)
            return
        }
        do {
            let info = try BTUploadingAttachInfo(location: location,
                                                 mediaInfo: mediaInfo,
                                                 uploadKey: uploadKey)
            do {
                try db.transaction {
                    if let query = insertQuery(info) {
                        try db.run(query)
                    }
                }
            } catch {
                DocsLogger.error("BTUploadingAttachInfoTable ---  db error when insert Record", error: error, component: LogComponents.btUploadCache)
            }
        } catch {
            DocsLogger.error("BTUploadingAttachInfoTable ---  init BTUploadingAttachInfoTable failed", error: error, component: LogComponents.btUploadCache)
        }
    }
    
    func delete(with originBaseID: String, uploadaKey: String, db: Connection) {
        guard let table = table else {
            DocsLogger.info("BTUploadingAttachInfoTable --- Asset Table is nil", component: LogComponents.btUploadCache)
            return
        }
        do {
            let rows = table.filter(self.originBaseID == originBaseID && self.uploadKey == uploadaKey)
            try db.run(rows.delete())
        } catch {
            DocsLogger.error("BTUploadingAttachInfoTable ---   db error when delete record",
                             extraInfo: ["originBaseID": DocsTracker.encrypt(id: originBaseID)],
                             error: error)
        }
    }
    
    func deleteAll(db: Connection) {
        guard let table = table else {
            DocsLogger.info("BTUploadingAttachInfoTable --- Asset Table is nil", component: LogComponents.btUploadCache)
            return
        }
        do {
            let delete = table.delete()
            try db.run(delete)
        } catch {
            DocsLogger.error("BTUploadingAttachInfoTable --- delete error", error: error, component: LogComponents.btUploadCache)
        }
    }
    
    private func parse(row: Row) -> BTUploadingAttachInfo? {
        let location = BTFieldLocation(originBaseID: row[self.originBaseID],
                                       originTableID: row[self.originTableID],
                                       baseID: row[self.baseID],
                                       tableID: row[self.tableID],
                                       viewID: row[self.viewID],
                                       recordID: row[self.recordID],
                                       fieldID: row[self.fieldID])
        let data = row[self.attachInfoValue]
        return BTUploadingAttachInfo(location: location, attachInfoValue: data, uploadKey: row[self.uploadKey])
    }
    private func insertQuery(_ info: BTUploadingAttachInfo) -> Insert? {
        guard let table = table else {
            DocsLogger.error("BTUploadingAttachInfoTable ---  table nil", component: LogComponents.btUploadCache)
            return nil
        }
        let query = table.insert(or: .replace,
                                 self.originBaseID <- info.originBaseID,
                                 self.originTableID <- info.originTableID,
                                 self.baseID <- info.baseID,
                                 self.viewID <- info.viewID,
                                 self.fieldID <- info.fieldID,
                                 self.tableID <- info.tableID,
                                 self.recordID <- info.recordID,
                                 self.attachInfoValue <- info.attachInfoValue,
                                 self.uploadKey <- info.uploadKey)
        return query
    }
}
