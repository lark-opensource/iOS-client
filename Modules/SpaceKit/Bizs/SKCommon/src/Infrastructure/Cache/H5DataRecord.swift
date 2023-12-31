//
//  H5DataRecord.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/8/26.
//
// 来自前端的，需要保存在本地的数据

import SKFoundation
import SpaceInterface

public enum H5DataRecordFrom: Int {
    case cacheFromUnKnown = 0
    case cacheFromPreload = 1
    case cacheFromWeb = 2
    case cacheHasBeenHitFromPreload = 3 //cache来自于预加载且已被命中过

    public var isFromPreload: Bool {
        return self == .cacheFromPreload || self == .cacheHasBeenHitFromPreload
    }
    
    public var name: String {
        var str = ""
        switch self {
        case .cacheFromPreload :
            str = "preload"
        case .cacheFromWeb :
            str = "web"
        case .cacheHasBeenHitFromPreload:
            str = "preload_has_been_hit"
        default:
            str = "unknow"
        }
        return str
    }
}

public struct H5DataRecord {
    public let objToken: FileListDefine.ObjToken
    public let key: String
    public let needSync: Bool
    public var payload: NSCoding?
    public let type: DocsType?
    public var updateTime: TimeInterval?
    public var accessTime: TimeInterval?
    var saveInfo: SaveInfo?
    var readInfo: ReadInfo = ReadInfo()
    private var isClientVar: Bool {
        return key.isClientVarKey
    }
    private var isHtmlCache: Bool {
        return key.hasSuffix(DocsType.htmlCacheKey)
    }
    
    public private(set) var cacheFrom: H5DataRecordFrom

    var shouldCacheInMemory: Bool {
        return isClientVar || isHtmlCache || key.hasSuffix("sync_to_source")
    }
    
    var filePathIfExist: SKFilePath {
        return H5DataRecord.payLoadFilePathIfExist(objToken: objToken, md5Key: key.md5())
    }

    static func payLoadFilePathIfExist(objToken: FileListDefine.ObjToken, md5Key: String) -> SKFilePath {
        let cacheDir = SKFilePath.clientVarCacheDir
        return cacheDir.appendingRelativePath(objToken).appendingRelativePath(md5Key)
    }

    public init(objToken: FileListDefine.ObjToken,
                key: String, needSync: Bool,
                payload: NSCoding?,
                type: DocsType?,
                updateTime: TimeInterval? = nil,
                accessTime: TimeInterval? = nil,
                cacheFrom: H5DataRecordFrom = .cacheFromUnKnown) {
        self.objToken = objToken
        self.key = key
        self.needSync = needSync
        self.payload = payload
        self.type = type
        self.updateTime = updateTime
        self.accessTime = accessTime
        self.cacheFrom = cacheFrom
        if key.isClientVarKey {
            if let stringPayload = payload as? String,
               stringPayload.isEmpty {
                DocsLogger.error("setH5Record, empty String,token=\(objToken.encryptToken)", component: LogComponents.newCache)
                self.payload = nil //过滤掉空字符串的clientVar
            } else if let dicPayload = payload as? [String: Any],
                      dicPayload.count == 0 {
                DocsLogger.error("setH5Record, empty Dic,token=\(objToken.encryptToken)", component: LogComponents.newCache)
                self.payload = nil //过滤掉空字典的clientVar
            }
        }
    }
    
    mutating func updateCacheFrom(_ from: H5DataRecordFrom) {
        cacheFrom = from
    }
}

extension H5DataRecord {
    struct SaveInfo {
        var isBigData = false
        // 只有保存时候用，其他时候不要使用
        var encodedData: Data?
    }

    struct ReadInfo {
        var dataCount: Int = 0
    }
}

public struct H5DataRecordKey: Hashable {
    let objToken: FileListDefine.ObjToken
    let key: String

    public init(objToken: FileListDefine.ObjToken, key: String) {
        self.objToken = objToken
        self.key = key
    }
}

public struct ClientVarMetaData: Equatable {
    let objToken: FileListDefine.ObjToken
    var needSync: Bool {
        return !needSynckeys.isEmpty
    }
    public var hasClientVar: Bool = false
    //record.key's md5!
    var needSynckeys = Set<String>()

    init(objToken: FileListDefine.ObjToken) {
        self.objToken = objToken
    }

    func updatingBy(_ record: H5DataRecord) -> (hasChange: Bool, newMetaData: ClientVarMetaData) {
        var newMetaData = self
        var hasChange = false
        if record.key.isClientVarKey {
            newMetaData.hasClientVar = (record.payload != nil)
            if newMetaData.hasClientVar != hasClientVar {
                hasChange = true
            }
        }

        let md5Key = record.key.md5()
        if record.needSync {
            newMetaData.needSynckeys.insert(md5Key)
        } else {
            newMetaData.needSynckeys.remove(md5Key)
        }
        return (hasChange, newMetaData)
    }
}
