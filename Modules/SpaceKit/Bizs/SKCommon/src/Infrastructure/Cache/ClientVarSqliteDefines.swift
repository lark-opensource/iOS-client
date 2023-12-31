//
//  ClientVarSqliteDefines.swift
//  SpaceKit
//
//  Created by chenhuaguan on 2019/12/22.
//

import Foundation
import SQLite

struct CVSqlDefine {

    enum Table: String {
        case fileMetaData = "FileMetaData"
        case rawData = "RawData"
        case picInfoData = "PicInfoData"
        case assetInfoData = "assetInfoData"
    }

    struct Rd {
        //rawData Table
        static let objToken = Expression<String>("objToken")
        static let key = Expression<String>("key")
        static let needSync = Expression<Bool>("needSync")
        static let type = Expression<Int?>("type")
        static let data = Expression<Data?>("data")
        static let dataSize = Expression<Int?>("dataSize")
        static let updateTime = Expression<TimeInterval?>("updateTime")
        static let accessTime = Expression<TimeInterval?>("accessTime")
        static let needPreload = Expression<Bool?>("needPreload")
        static let cacheFrom = Expression<Int?>("cacheFrom")
    }

    struct Mt {
        //fileMetaData Table
        static let objToken = Expression<String>("objToken")
        static let hasClientVar = Expression<Bool>("hasClientVar")
        static let updateTime = Expression<Double>("updateTime")
    }

    struct Pic {
        //picInfoData Table
        static let objToken = Expression<String>("objToken")
        static let picKey = Expression<String>("picKey")
        static let picType = Expression<Int>("picType")
        static let needUpLoad = Expression<Bool>("needUpLoad")
        static let isDrive = Expression<Bool?>("isDrive")
        static let updateTime = Expression<Double>("updateTime")
    }

    struct Asset {
        //Asset Table
        static let objToken = Expression<String>("objToken")
        static let uuid = Expression<String>("uuid")
        static let fileToken = Expression<String>("fileToken")
        static let picType = Expression<String>("picType")
        static let cacheKey = Expression<String>("cacheKey")
        static let sourceUrl = Expression<String>("sourceUrl")
        static let uploadKey = Expression<String>("uploadKey")
        static let assetType = Expression<String>("assetType")
        static let fileSize = Expression<Int>("fileSize")
        static let source = Expression<String>("source")
        static let backupDouble = Expression<Double?>("backup_Double")
        static let backupInt1 = Expression<Int?>("backup_Int1")
        static let backupStr1 = Expression<String?>("backup_Str1")
        static let backupStr2 = Expression<String?>("backup_Str2")
    }

    struct SqlGroupInfo {
        let objToken: FileListDefine.ObjToken
        let maxSync: Bool
        let groupDataSize: Int
        let maxAccessTime: TimeInterval?
        init(objToken: FileListDefine.ObjToken, maxSync: Bool, groupDataSize: Int, maxAccessTime: TimeInterval?) {
            self.objToken = objToken
            self.maxSync = maxSync
            self.groupDataSize = groupDataSize
            self.maxAccessTime = maxAccessTime
        }
    }

//    struct SqlSyncItem {
//        let objToken: FileListDefine.ObjToken
//        let md5Key: String
//        var payload: NSCoding?
//        init(objToken: FileListDefine.ObjToken, md5Key: String, payload: NSCoding?) {
//            self.objToken = objToken
//            self.md5Key = md5Key
//            self.payload = payload
//        }
//    }
}
