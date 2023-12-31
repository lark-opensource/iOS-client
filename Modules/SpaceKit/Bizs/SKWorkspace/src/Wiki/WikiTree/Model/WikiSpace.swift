//
//  WikiSpace.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2019/9/26.
//  swiftlint:disable nesting operator_usage_whitespace

import Foundation
import SwiftyJSON
import SQLite
import SKCommon
import SKFoundation
import SKResource
import RxCocoa

/// Wiki 内使用的数据结构
public struct WikiSpace: Codable {

    public static var rootTokenCodingKey: CodingUserInfoKey? {
        CodingUserInfoKey(rawValue: "customRootToken")
    }

    public typealias SpaceID = String

    public struct Cover: Codable {

        let originPath: String
        let thumbnailPath: String
        let name: String
        public let isDarkStyle: Bool
        let rawColor: String

        enum CodingKeys: String, CodingKey {
            case originPath     = "origin"
            case thumbnailPath  = "thumbnail"
            case name           = "key"
            case isDarkStyle    = "is_graph_dark"
            case rawColor       = "color_value"
        }

        public var coverURL: URL? {
            return URL(string: originPath)
        }

        public var thumbnailURL: URL? {
            return URL(string: thumbnailPath)
        }

        public var backgroundColor: UIColor {
            if Scanner(string: rawColor).scanHexInt32(nil) {
                return UIColor.ud.rgb(rawColor)
            } else {
                return isDarkStyle ? UIColor.ud.N950.alwaysLight : UIColor.ud.N00.alwaysLight
            }

        }
        
        public init(originPath: String, thumbnailPath: String, name: String, isDarkStyle: Bool, rawColor: String) {
            self.originPath = originPath
            self.thumbnailPath = thumbnailPath
            self.name = name
            self.isDarkStyle = isDarkStyle
            self.rawColor = rawColor
        }
    }

    // 接口定义 https://bytedance.feishu.cn/wiki/wikcnHCKC3CgfES2YanG0nxCf0d
    public struct DisplayTag: Codable {
        public let tagType: Int
        public let tagValue: String
        enum CodingKeys: String, CodingKey {
            case tagType = "tag_type"
            case tagValue = "tag_value"
        }

        // 是否是企业公开、互联网公开类型
        public var isPublicType: Bool {
            // 1: 互联网公开，5：组织内公开
            tagType == 1 || tagType == 5
        }
    }
    
    public enum MigrateStatus: Int, Codable, Equatable {
        // 未开始迁移
        case pending = 0
        // 迁移中
        case migrating = 1
        // 已完成
        case completed = 2
    }

    public enum OwnerPermType: Int, Equatable {
        case defaultType   = 0 // 默认值
        case container = 1 // 容器权限
        case singlePage = 2 // 单页面权限
    }
    
    public enum OpenSharing: Int, Equatable {
        case notSetting = 0  // 未设置
        case open = 1        // 开启
        case close = 2       // 关闭
        case none
    }
    //知识库类型
    public enum SpaceType: Int, Codable, Equatable {
        case team = 0       // 团队
        case personal = 1   // 个人
        case library = 2    // 文档库
    }

    public var spaceID: String {
        spaceId ?? ""
    }
    public var spaceId: String?
    public let spaceName: String
    // 该知识库根节点wikiToken
    public let rootToken: String
    // 搜索场景没有 tenantID，且tenantID目前仅在目录树内使用，暂时标记为 optional
    public let tenantID: String?
    public let wikiDescription: String
    public var isStar: Bool? = false
    public let cover: Cover
    public let lastBrowseTime: TimeInterval?
    public let wikiScope: Int?
    public let ownerPermType: Int?
    // 是否正在升级中，1.0 升 2.0 状态，使用场景少，暂不存在数据库内
    public let migrateStatus: MigrateStatus?
    public let openSharing: Int?
    public let spaceType: SpaceType?
    public let createUID: String?
    public let displayTag: DisplayTag?
    public let iconInfo: WikiSpaceIconInfo?

    enum CodingKeys: String, CodingKey {
        case spaceId            = "space_id"
        case spaceName          = "space_name"
        case wikiDescription    = "description"
        case isStar             = "is_star"
        case lastBrowseTime     = "browse_time"
        case cover              = "space_cover"
        case wikiScope          = "wiki_scope"
        case migrateStatus      = "migrate_status"
        case ownerPermType      = "owner_perm_type"
        case tenantID           = "tenant_id"
        case openSharing        = "open_sharing"
        case spaceType          = "space_type"
        case createUID          = "create_uid"
        case displayTag         = "display_tag"
        case rootToken          = "root_token"
        case iconInfo           = "space_icon_info"
    }
    
    public init(spaceId: String? = nil,
                spaceName: String,
                rootToken: String,
                tenantID: String? = nil,
                wikiDescription: String,
                isStar: Bool? = false,
                cover: WikiSpace.Cover,
                lastBrowseTime: TimeInterval? = nil,
                wikiScope: Int? = nil,
                ownerPermType: Int? = nil,
                migrateStatus: WikiSpace.MigrateStatus? = nil,
                openSharing: Int? = nil,
                spaceType: WikiSpace.SpaceType? = nil,
                createUID: String? = nil,
                displayTag: WikiSpace.DisplayTag? = nil,
                iconInfo: WikiSpaceIconInfo? = nil) {
        self.spaceId = spaceId
        self.spaceName = spaceName
        self.rootToken = rootToken
        self.tenantID = tenantID
        self.wikiDescription = wikiDescription
        self.isStar = isStar
        self.cover = cover
        self.lastBrowseTime = lastBrowseTime
        self.wikiScope = wikiScope
        self.ownerPermType = ownerPermType
        self.migrateStatus = migrateStatus
        self.openSharing = openSharing
        self.spaceType = spaceType
        self.createUID = createUID
        self.displayTag = displayTag
        self.iconInfo = iconInfo
    }


    public init(from decoder: Decoder) throws {
        let container: KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)

        self.spaceId = try container.decodeIfPresent(String.self, forKey: CodingKeys.spaceId)
        self.spaceName = try container.decode(String.self, forKey: CodingKeys.spaceName)
        self.wikiDescription = try container.decode(String.self, forKey: CodingKeys.wikiDescription)
        self.isStar = try container.decodeIfPresent(Bool.self, forKey: CodingKeys.isStar)
        self.lastBrowseTime = try container.decodeIfPresent(TimeInterval.self, forKey: CodingKeys.lastBrowseTime)
        self.cover = try container.decode(Cover.self, forKey: CodingKeys.cover)
        self.wikiScope = try container.decodeIfPresent(Int.self, forKey: CodingKeys.wikiScope)
        self.migrateStatus = try container.decodeIfPresent(MigrateStatus.self, forKey: CodingKeys.migrateStatus)
        self.ownerPermType = try container.decodeIfPresent(Int.self, forKey: CodingKeys.ownerPermType)
        self.tenantID = try container.decodeIfPresent(String.self, forKey: CodingKeys.tenantID)
        self.openSharing = try container.decodeIfPresent(Int.self, forKey: CodingKeys.openSharing)
        self.spaceType = try container.decodeIfPresent(SpaceType.self, forKey: CodingKeys.spaceType)
        self.createUID = try container.decodeIfPresent(String.self, forKey: CodingKeys.createUID)
        self.displayTag = try container.decodeIfPresent(DisplayTag.self, forKey: CodingKeys.displayTag)
        self.iconInfo = try container.decodeIfPresent(WikiSpaceIconInfo.self, forKey: .iconInfo)
        
        do {
            let rootToken = try container.decode(String.self, forKey: CodingKeys.rootToken)
            self.rootToken = rootToken
        } catch {
            if let rootTokenKey = Self.rootTokenCodingKey,
               let rootToken = decoder.userInfo[rootTokenKey] as? String {
                self.rootToken = rootToken
            } else {
                throw error
            }
        }
    }
}

extension WikiSpace {
    public var isTreeContentCached: Driver<Bool> {
        WikiTreeCacheHandle.shared.loadTree(spaceID: spaceID, initialWikiToken: nil)
            .map { _ in true }
            .ifEmpty(default: false)
            .asDriver(onErrorJustReturn: false)
    }

    public var isPublic: Bool {
        return wikiScope == 1
    }

    public var sharingType: OpenSharing {
        guard let openSharing = openSharing else {
            return  .none
        }
        return OpenSharing(rawValue: openSharing) ?? .none
    }

    public var isLibraryOwner: Bool {
        spaceType == .library && createUID == User.current.info?.userID
    }

    public var isLibrary: Bool {
        spaceType == .library
    }
}

extension WikiSpace: Comparable {
    public static func < (lhs: WikiSpace, rhs: WikiSpace) -> Bool {
        let lhsBrowseTime = lhs.lastBrowseTime ?? 0
        let rhsBrowseTime = rhs.lastBrowseTime ?? 0
        if lhsBrowseTime == rhsBrowseTime {
            return lhs.spaceName > rhs.spaceName
        } else {
            return lhsBrowseTime < rhsBrowseTime
        }
    }

    public static func == (lhs: WikiSpace, rhs: WikiSpace) -> Bool {
        return lhs.spaceID == rhs.spaceID
    }
}

class WikiSpaceTable {
    private let spaceID             = Expression<String>("space_id")
    private let spaceName           = Expression<String>("space_name")
    private let wikiDescription     = Expression<String>("description")
    private let isStar              = Expression<Bool>("isStar")
    private let lastBrowseTime      = Expression<TimeInterval>("browse_time")

    private let coverOriginPath     = Expression<String>("cover_origin_path")
    private let coverThumbnailPath  = Expression<String>("cover_thumbnail_path")
    private let coverName           = Expression<String>("cover_name")
    private let coverIsDarkStyle    = Expression<Bool>("cover_is_dark_style")
    private let coverRawColor       = Expression<String>("cover_color")
    private let wikiScope           = Expression<Int>("wiki_scope")
    private let tenantID            = Expression<String?>("tenant_id")
    private let openSharing         = Expression<Int?>("open_sharing")
    private let spaceType           = Expression<Int?>("space_type")
    private let createUID           = Expression<String?>("create_uid")
    private let displayTagType      = Expression<Int?>("display_tag_type")
    private let displayTagValue     = Expression<String?>("display_tag_value")
    private let rootToken           = Expression<String>("root_token")
    private let iconInfoType        = Expression<Int?>("icon_info_type")
    private let iconInfoKey         = Expression<String?>("icon_info_key")

    private let db: Connection
    private let table: Table

    private var createTableCMD: String {
        let command = table.create(ifNotExists: true) { t in
            t.column(spaceID, primaryKey: true)
            t.column(spaceName)
            t.column(wikiDescription)
            t.column(isStar)
            t.column(lastBrowseTime)

            t.column(coverOriginPath)
            t.column(coverThumbnailPath)
            t.column(coverName)
            t.column(coverIsDarkStyle)
            t.column(coverRawColor)
            t.column(wikiScope)
            t.column(tenantID)
            t.column(spaceType)
            t.column(createUID)
            t.column(openSharing)
            t.column(displayTagType)
            t.column(displayTagValue)
            t.column(rootToken)
            t.column(iconInfoType)
            t.column(iconInfoKey)
        }
        return command
    }

    private var createIndexCMD: String {
        let sortIndexQuery = table.createIndex(isStar.desc, lastBrowseTime.desc, ifNotExists: true)
        return sortIndexQuery
    }

    init(connection: Connection, tableName: String = "wiki_space_v2") {
        db = connection
        table = Table(tableName)
    }

    func setup() throws {
        try db.run(createTableCMD)
    }

    private func parse(record: Row) -> WikiSpace {
        let spaceID             = record[self.spaceID]
        let spaceName           = record[self.spaceName]
        let wikiDescription     = record[self.wikiDescription]
        let isStar              = record[self.isStar]
        let lastBrowseTime      = record[self.lastBrowseTime]

        let coverOriginPath     = record[self.coverOriginPath]
        let coverThumbnailPath  = record[self.coverThumbnailPath]
        let coverName           = record[self.coverName]
        let coverIsDarkStyle    = record[self.coverIsDarkStyle]
        let coverRawColor       = record[self.coverRawColor]
        let wikiScope           = record[self.wikiScope]
        let tenantID            = record[self.tenantID]
        let openSharing         = record[self.openSharing]
        let spaceType           = record[self.spaceType]
        let createUID           = record[self.createUID]
        let displayTagType      = record[self.displayTagType]
        let displayTagValue     = record[self.displayTagValue]
        let rootToken           = record[self.rootToken]
        let iconInfoType        = record[self.iconInfoType]
        let iconInfoKey         = record[self.iconInfoKey]

        let cover = WikiSpace.Cover(originPath: coverOriginPath,
                                    thumbnailPath: coverThumbnailPath,
                                    name: coverName,
                                    isDarkStyle: coverIsDarkStyle,
                                    rawColor: coverRawColor)
        var wikiSpaceType: WikiSpace.SpaceType?
        if let spaceType {
            wikiSpaceType = WikiSpace.SpaceType(rawValue: spaceType)
        }

        let displayTag: WikiSpace.DisplayTag? = {
            if let displayTagValue, let displayTagType {
                return .init(tagType: displayTagType, tagValue: displayTagValue)
            } else {
                return nil
            }
        }()
        
        let iconInfo: WikiSpaceIconInfo? = {
            if let iconInfoType, let iconInfoKey {
                return .init(type: iconInfoType, key: iconInfoKey)
            }
            return nil
        }()

        let space = WikiSpace(spaceId: spaceID,
                              spaceName: spaceName,
                              rootToken: rootToken,
                              tenantID: tenantID,
                              wikiDescription: wikiDescription,
                              isStar: isStar,
                              cover: cover,
                              lastBrowseTime: lastBrowseTime,
                              wikiScope: wikiScope,
                              ownerPermType: 0,
                              migrateStatus: nil,
                              openSharing: openSharing,
                              spaceType: wikiSpaceType,
                              createUID: createUID,
                              displayTag: displayTag,
                              iconInfo: iconInfo)
        return space
    }

    private func insertQuery(with space: WikiSpace) -> Insert {
        let insertQuery = table.insert(or: .replace,
                                       self.spaceID <- space.spaceID,
                                       self.spaceName <- space.spaceName,
                                       self.wikiDescription <- space.wikiDescription,
                                       self.isStar <- space.isStar ?? false,
                                       self.lastBrowseTime <- space.lastBrowseTime ?? 0,
                                       self.coverOriginPath <- space.cover.originPath,
                                       self.coverThumbnailPath <- space.cover.thumbnailPath,
                                       self.coverName <- space.cover.name,
                                       self.coverIsDarkStyle <- space.cover.isDarkStyle,
                                       self.coverRawColor <- space.cover.rawColor,
                                       self.wikiScope <- space.wikiScope ?? 0,
                                       self.tenantID <- space.tenantID,
                                       self.openSharing <- space.openSharing,
                                       self.spaceType <- space.spaceType?.rawValue,
                                       self.createUID <- space.createUID,
                                       self.displayTagType <- space.displayTag?.tagType,
                                       self.displayTagValue <- space.displayTag?.tagValue,
                                       self.rootToken <- space.rootToken,
                                       self.iconInfoType <- space.iconInfo?.type,
                                       self.iconInfoKey <- space.iconInfo?.key)
        return insertQuery
    }

    func getSpace(_ spaceId: String) -> WikiSpace? {
        var spaces = [WikiSpace]()
        do {
            let records = try db.prepare(table.filter(self.spaceID == spaceId))
            spaces = records.map { record in
                parse(record: record)
            }
        } catch {
            DocsLogger.error("wiki.db.space --- db error when get space", error: error)
        }
        return spaces.first
    }

    func getAllSpaces() -> [WikiSpace] {
        var spaces = [WikiSpace]()
        do {
            let records = try db.prepare(table)
            spaces = records.map { record in
                parse(record: record)
            }
        } catch {
            DocsLogger.error("wiki.db.space --- db error when get all spaces", error: error)
        }
        return spaces
    }
    
    func getAllSpacesOfCurrentClass(with spaceIds: [String]) -> [WikiSpace] {
        var spaces = [WikiSpace]()
        spaceIds.forEach { id in
            // 列表展示的数据需要过滤掉文档库
            if let space = getSpace(id), !space.isLibrary {
                spaces.append(space)
            }
        }
        return spaces
    }

    func insert(space: WikiSpace) {
        do {
            let query = insertQuery(with: space)
            try db.run(query)
        } catch {
            DocsLogger.error("wiki.db.space --- db error when insert space record", error: error)
        }
    }

    func insert(spaces: [WikiSpace]) {
        spaces.forEach {
            insert(space: $0)
        }
    }

    func deleteAllSpaces() {
        do {
            try db.run(table.delete())
        } catch {
            DocsLogger.error("wiki.db.space --- db error when delete all spaces", error: error)
        }
    }
}
