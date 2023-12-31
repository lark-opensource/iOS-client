//
//  BlockitEntity.swift
//  Blockit
//
//  Created by 夏汝震 on 2020/10/10.
//

import SwiftyJSON
import LarkFoundation
import OPSDK
import OPBlockInterface
import LarkLocalizations
// MARK: - BlockInfo

// 致力于构造一个通用的结构
public final class BlockInfo: Hashable, Equatable, Codable {
    public let blockID: String //: Encodable {domain}-{uuid}
    public let blockTypeID: String // 指定渲染方式，需要在平台注册
    public let sourceLink: String // 溯源+跳转
    public var sourceData: String? // 描述block本体信息，提供渲染所需要的数据
    public let sourceMeta: String // 通过sourceMeta拉取sourceData进行渲染
    public var i18nPreview: String? // Block 的图片预览，降级显示的方案
    public let i18nSummary: String // 摘要信息预览, sourceData的简略版，用于给别的业务方使用，是为了防止理解sourceData结构, 降级显示的方案。

    public init(blockID: String,
                blockTypeID: String,
                sourceLink: String,
                sourceData: String? = nil,
                sourceMeta: String,
                i18nPreview: String? = nil,
                i18nSummary: String) {
        self.blockID = blockID
        self.blockTypeID = blockTypeID
        self.sourceLink = sourceLink
        self.sourceData = sourceData
        self.sourceMeta = sourceMeta
        self.i18nPreview = i18nPreview
        self.i18nSummary = i18nSummary
    }

    public static func == (lhs: BlockInfo, rhs: BlockInfo) -> Bool {
        return lhs === rhs
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(blockID)
        hasher.combine(blockTypeID)
        hasher.combine(sourceLink)
        hasher.combine(sourceData)
        hasher.combine(sourceMeta)
        hasher.combine(i18nPreview)
        hasher.combine(i18nSummary)
    }

    public func toDictionary() -> [AnyHashable: Any] {
        toOPInfo().toDictionary()
    }
   
    // 目前先脏 blockInfo，后面全面迁移至 OPBlockInfo
    public func toOPInfo() -> OPBlockInfo {
        let sourceDataObject: [AnyHashable: Any]
        if let sourceDataString = sourceData, let sourceData = sourceDataString.data(using: .utf8) {
            sourceDataObject = ((try? JSONSerialization.jsonObject(with: sourceData, options: .allowFragments)) as? [AnyHashable: Any]) ?? [:]
        } else {
            sourceDataObject = [:]
        }
        
        let sourceMetaObject: [AnyHashable: Any]
        if let sourceMeta = sourceMeta.data(using: .utf8) {
            sourceMetaObject = ((try? JSONSerialization.jsonObject(with: sourceMeta, options: .allowFragments)) as? [AnyHashable: Any]) ?? [:]
        } else {
            sourceMetaObject = [:]
        }
        return OPBlockInfo(blockID: blockID,
                           blockTypeID: blockTypeID,
                           sourceLink: sourceLink,
                           sourceData: sourceDataObject,
                           sourceMeta: sourceMetaObject,
                           i18nPreview: i18nPreview ?? "",
                           i18nSummary: i18nSummary)
    }
}

public struct BlockCursorInfo {
    public let cursor: String
    public let count: Int
    func toDictionary() -> [AnyHashable: Any] {
        [
            "cursor": cursor,
            "count": count
        ]
    }
}
// MARK: - BlockDetailReqParam
public struct BlockDetailReqParam {
    private let larkVersion = Utils.appVersion
    public let hostType: String
    public let cursorInfo: BlockCursorInfo?
    public init(hostType: String, cursorInfo: BlockCursorInfo? = nil) {
        self.hostType = hostType
        self.cursorInfo = cursorInfo
    }
    func toDictionary() -> [String: Any] {
        var result: [String: Any] = [
            "hostType": hostType,
            "larkVersion": larkVersion,
        ]
        if let cursorInfo = cursorInfo {
            result["cursorInfo"] = cursorInfo.toDictionary()
        }
        return result
    }
}


// MARK: - BlockDetail
public struct BlockDetail: Codable {
    public let appId: String
    public let appName: [String: String]
    public let blockTypeId: String
    public let category: String
    public let desc: [String: String]
    public let key: String
    public let mobileIcon: String
    public let name: [String: String]
    public let descImage: [String: String]?
}

public struct BlockInfoReq {
    public let blockTypeID: String
    public let sourceMeta: String
    public let sourceData: String
    public init(blockTypeID: String, sourceMeta: String = "{}", sourceData: String = "{}") {
        self.blockTypeID = blockTypeID
        self.sourceData = sourceData
        self.sourceMeta = sourceMeta
    }
    func toDictionary() -> [String: String] {
        [
            "blockTypeID" : blockTypeID,
            "sourceData" : sourceData,
            "sourceMeta" : sourceMeta
        ]
    }
}

// MARK: - BatchGetItemTags
public struct BasicTagInfo: Encodable {
    public let tagId: String // 标签id
    public let name: String // 标签名
    public let description: String // 标签描述
    public let owners: [BatchGrantRecord] // 标签所有人
    public var owner: BatchGrantRecord? // 端上自己定义的字段，标签所属人
    /// 标签权限类型
    public let permissionType: TagPermissionType
    /// 协作者数量
    public let teamworkerCount: String

    public init(json: JSON) {
        self.tagId = json["tagId"].stringValue
        self.name = json["name"].stringValue
        self.description = json["description"].stringValue
        self.owners = json["owners"].arrayValue.map { BatchGrantRecord(json: $0) }
        self.owner = owners.first(where: { $0.type == .user })
        self.permissionType = TagPermissionType(rawValue: json["permissionType"].intValue) ?? .default
        self.teamworkerCount = json["teamworkerCount"].stringValue
    }
}

public struct BatchGrantRecord: Encodable {
    public let type: GrantRecordType // 实体类型 无需关心
    public let id: String // 实体ID 无需关心
    public let name: [String: String] // 实体名称
    public let avatarUrl: String // 实体头像
    public let subName: [String: String] // 实体副标题
    public var i18nName: String = "" // 端上定义的name

    public init(json: JSON) {
        self.type = GrantRecordType(rawValue: json["type"].intValue) ?? .none
        self.id = json["id"].stringValue
        self.name = (json["name"].dictionaryObject ?? [:]) as? [String: String] ?? ["": ""]
        self.avatarUrl = json["avatarUrl"].stringValue
        self.subName = (json["subName"].dictionaryObject ?? [:]) as? [String: String] ?? ["": ""]
        let language = LanguageManager.currentLanguage.localeIdentifier.lowercased().replacingOccurrences(of: "_", with: "-")
        for (key, value) in name {
            if language.contains(key.lowercased()) {
                self.i18nName = value
                break
            }
        }
    }
}

public struct TagInstance: Encodable {
    public let instanceId: String // tag实例的id
    public let tagInfo: BasicTagInfo // tag基础信息
    public let deletable: Bool // 能否删除这个标签
    public let viewable: Bool // 能否查看这个标签
    public let appLink: String // 跳转applink链接
    public let isSubscribed: Bool // 是否收藏

    public init(json: JSON) {
        self.instanceId = json["instanceId"].stringValue
        self.tagInfo = BasicTagInfo(json: json["tagInfo"])
        self.deletable = json["deletable"].boolValue
        self.viewable = json["viewable"].boolValue
        self.appLink = json["appLink"].stringValue
        self.isSubscribed = json["isSubscribed"].boolValue
    }
}

public struct ItemTags: Encodable {
    public let uniqId: String // block_id
    public let tags: [TagInstance]

    public init(json: JSON) {
        self.uniqId = json["uniqId"].stringValue
        self.tags = json["tags"].arrayValue.map { TagInstance(json: $0) }
    }
}

public struct BatchGetItemTagsResponse: Encodable {
    public let itemsTags: [String: ItemTags] // 以uniqId为key

    public init(json: JSON) {
        self.itemsTags = json["itemsTags"].dictionaryValue.mapValues({ (json) in
            return ItemTags(json: json)
        })
    }
}

public struct BatchGetItemTagsResponseWrap: Encodable {
    public let code: String
    public let msg: String
    public let data: BatchGetItemTagsResponse

    public init(json: JSON) {
        self.code = json["code"].stringValue
        self.msg = json["msg"].stringValue
        self.data = BatchGetItemTagsResponse(json: json["data"])
    }
}

// MARK: - CreateTagAndAddItem
public enum TagType: Int, Encodable {
    case unknown = 0
    case kvTag = 2
}

public struct CreateTagAndAddItemRequest: Encodable {
    public let tagName: String // Tag的名字
    public let tagType: TagType // tag的类型
    public let uniqId: String // deprecated
    public let blockInfo: BlockInfo // block信息
    public let context: String?
    /// 标签权限类型
    public let permissionType: TagPermissionType
    /// 标签场景（按场景创建时需要传入）
    public let scene: TagScene

    public init(tagName: String,
                tagType: TagType,
                uniqId: String,
                blockInfo: BlockInfo,
                context: String? = nil,
                permissionType: TagPermissionType = .private,
                scene: TagScene = .default
                ) {
        self.tagName = tagName
        self.tagType = tagType
        self.uniqId = uniqId
        self.blockInfo = blockInfo
        self.context = context
        self.permissionType = permissionType
        self.scene = scene
    }
}

/// 标签的基本信息
public struct Tag: Encodable {
    public let tagId: String // 标签id
    public let name: String // 标签名
    public let namespaceId: String // 作用域id
    public let description: String // 标签描述
    public let creatorId: String // 标签创建人id
    public let type: TagType // tag的类型
    public let createdAt: String // 创建时间,ms时间戳
    public let updatedAt: String // 更新时间,ms时间戳
    public let version: String // 对应tag的版本
    public let tagPermissionSetting: Int // 标签权限设置,1:所有人可编辑,2：指定人可编辑，3：指定人可编辑或查看
    /// 标签权限类型
    public let tagPermissionType: TagPermissionType

    public init(json: JSON) {
        self.tagId = json["tagId"].stringValue
        self.name = json["name"].stringValue
        self.namespaceId = json["namespaceId"].stringValue
        self.description = json["description"].stringValue
        self.creatorId = json["creatorId"].stringValue
        self.type = TagType(rawValue: json["tagType"].intValue) ?? .unknown
        self.createdAt = json["created_at"].stringValue
        self.updatedAt = json["updated_at"].stringValue
        self.version = json["version"].stringValue
        self.tagPermissionSetting = json["tagPermissionSetting"].intValue
        self.tagPermissionType = TagPermissionType(rawValue: json["tagPermissionType"].intValue) ?? .default
    }
}

public struct CreateTagAndAddItemResponse: Encodable {
    public let tagInfo: Tag
    public let latestItemTags: ItemTags

    public init(json: JSON) {
        self.tagInfo = Tag(json: json["tagInfo"])
        self.latestItemTags = ItemTags(json: json["latestItemTags"])
    }
}

public struct CreateTagAndAddItemResponseWrap: Encodable {
    public let code: String
    public let msg: String
    public let data: CreateTagAndAddItemResponse

    public init(json: JSON) {
        self.code = json["code"].stringValue
        self.msg = json["msg"].stringValue
        self.data = CreateTagAndAddItemResponse(json: json["data"])
    }
}

// MARK: - BatchTagAction

public struct RemoveTagAction: Encodable {
    public let tagType: TagType //标签类型
    public let tagId: String // 标签id
    public let tagInstanceId: String // 标签实例id

    public init(tagType: TagType,
                tagId: String,
                tagInstanceId: String) {
        self.tagType = tagType
        self.tagId = tagId
        self.tagInstanceId = tagInstanceId
    }
}

public struct UpdateTagAction: Encodable {
    public let tagType: TagType // 标签类型
    public let tagId: String // 标签id
    public let tagInstanceId: String // 标签实例id

    public init(tagType: TagType,
                tagId: String,
                tagInstanceId: String) {
        self.tagType = tagType
        self.tagId = tagId
        self.tagInstanceId = tagInstanceId
    }
}

public struct AddTagAction: Encodable {
    public let tagType: TagType // 标签类型
    public let tagId: String // 标签id

    public init(tagType: TagType,
                tagId: String) {
        self.tagType = tagType
        self.tagId = tagId
    }
}

public struct ItemTagAction: Encodable {
    public let blockInfo: BlockInfo // block信息
    public let uniqId: String // deprecated, 唯一id,比如block_id
    public let tagsAdding: [AddTagAction] // 待添加的tag
    public let tagsUpdating: [UpdateTagAction] // 待更新的tag 暂时用不到
    public let tagsRemoving: [RemoveTagAction] // 带移除的tag

    public init(blockInfo: BlockInfo,
                uniqId: String,
                tagsAdding: [AddTagAction],
                tagsUpdating: [UpdateTagAction],
                tagsRemoving: [RemoveTagAction]) {
        self.blockInfo = blockInfo
        self.uniqId = uniqId
        self.tagsAdding = tagsAdding
        self.tagsUpdating = tagsUpdating
        self.tagsRemoving = tagsRemoving
    }
}

public struct BatchTagActionResponse: Encodable {
    public let latestItemTags: [String: ItemTags] // 批量操作结果,以uniqId为key

    public init(json: JSON) {
        self.latestItemTags = json["latestItemTags"].dictionaryValue.mapValues({ (json) in
            return ItemTags(json: json)
        })
    }
}

public struct BatchTagActionResponseWrap: Encodable {
    public let code: String
    public let msg: String
    public let data: BatchTagActionResponse

    public init(json: JSON) {
        self.code = json["code"].stringValue
        self.msg = json["msg"].stringValue
        self.data = BatchTagActionResponse(json: json["data"])
    }
}

// MARK: - BatchTagAction

public enum Role: Int, Encodable {
    case none = 0
    case owner = 1
    case member = 2
    case viewer = 3
}

public enum GrantRecordType: Int, Encodable {
    case none = 0
    case user = 1
    case department = 2
    case leader = 3
    case brother = 4
    case tenantAdmin = 5
    case appAdmin = 6
    case vGroup = 7
    /// targetId是群聊ID，规则限定该群下所有用户
    case chat = 9
    case group = 101
    case entity = 102
}

public struct GrantRecord: Encodable {
    public let grantRecordType: GrantRecordType // 实体类型 无需关心
    public let grantRecordId: String // 实体ID 无需关心
    public let name: [String: String] // 实体名称
    public let avatarUrl: String // 实体头像
    public let subName: [String: String] // 实体副标题
    public let role: Role // 实体角色 1-owner 2-member 3-viewer
    public var i18nName: String = "" // 端上定义的name

    public init(json: JSON) {
        self.grantRecordType = GrantRecordType(rawValue: json["grantRecordType"].intValue) ?? .none
        self.grantRecordId = json["grantRecordId"].stringValue
        self.name = (json["name"].dictionaryObject ?? [:]) as? [String: String] ?? ["": ""]
        self.avatarUrl = json["avatarUrl"].stringValue
        self.subName = (json["subName"].dictionaryObject ?? [:]) as? [String: String] ?? ["": ""]
        self.role = Role(rawValue: json["role"].intValue) ?? .none
        let language = LanguageManager.currentLanguage.localeIdentifier.lowercased().replacingOccurrences(of: "_", with: "-")
        for (key, value) in name {
            if language.contains(key.lowercased()) {
                self.i18nName = value
                break
            }
        }
    }
}

/// 标签权限类型字段，标签的创建、更新、查询时需要带上
public enum TagPermissionType: Int, Encodable {
    /// 历史数据
    case `default` = 0
    /// 公开
    case `public` = 1
    /// 私有
    case `private` = 2
}

/// 创建标签时的场景枚举
public enum TagScene: Int, Encodable {
    case `default` = 0
    /// 项目协作
    case teamwork = 1
    /// 团队知识
    case teamKnowledge = 2
    /// 个人收藏
    case privateCollection = 3
    /// 公共话题
    case publicTopic = 4
}

public struct TagStruct: Encodable {
    public let id: String
    public let name: String
    public let subscribed: Bool // 是否收藏
    public let unavailable: Bool
    public let hasAdded: Bool
    public let owners: [GrantRecord]
    public var owner: GrantRecord? // 标签所属人
    /// 标签权限类型
    public let permissionType: TagPermissionType
    /// 协作者数量
    public let teamworkerCount: String

    public init(id: String,
                name: String,
                subscribed: Bool,
                unavailable: Bool,
                hasAdded: Bool,
                owners: [GrantRecord],
                permissionType: TagPermissionType = .private,
                teamworkerCount: String = "0"
                ) {
        self.id = id
        self.name = name
        self.subscribed = subscribed
        self.unavailable = unavailable
        self.hasAdded = hasAdded
        self.owners = owners
        self.permissionType = permissionType
        self.teamworkerCount = teamworkerCount
    }

    public init(json: JSON) {
        self.id = json["id"].stringValue
        self.name = json["name"].stringValue
        self.subscribed = json["subscribed"].boolValue
        self.unavailable = json["unavailable"].boolValue
        self.hasAdded = json["hasAdded"].boolValue
        self.owners = json["owners"].arrayValue.map { GrantRecord(json: $0) }
        self.owner = owners.first(where: { $0.role == .owner })
        self.permissionType = TagPermissionType(rawValue: json["permissionType"].intValue) ?? .default
        self.teamworkerCount = json["teamworkerCount"].stringValue
    }
}

public struct SearchTagsResponse: Encodable {
    public let tags: [TagStruct] // tag搜索结果
    public let needCreate: Bool // 需要显示【新建标签】

    public init(json: JSON) {
        self.tags = json["tags"].arrayValue.map { TagStruct(json: $0) }
        self.needCreate = json["needCreate"].boolValue
    }
}

public struct SearchTagsResponseWrap: Encodable {
    public let code: String
    public let msg: String
    public let data: SearchTagsResponse

    public init(json: JSON) {
        self.code = json["code"].stringValue
        self.msg = json["msg"].stringValue
        self.data = SearchTagsResponse(json: json["data"])
    }
}

// MARK: - SearchTagView
public struct SearchTagViewRequest: Encodable {
    // public let userId: Int64 // 当前登陆用户
    public let name: String // 搜索的标签名称
    public let isPreciseSearch: Bool? // 是否精确匹配，默认false（模糊匹配）

    public init(name: String,
                isPreciseSearch: Bool? = false) {
        self.name = name
        self.isPreciseSearch = isPreciseSearch
    }
}

public struct SearchTagViewResponseWrap: Encodable {
    public let code: String
    public let msg: String
    public let data: SearchTagViewResponse

    public init(json: JSON) {
        self.code = json["code"].stringValue
        self.msg = json["msg"].stringValue
        self.data = SearchTagViewResponse(json: json["data"])
    }
}

public struct SearchTagViewResponse: Encodable {
    public let tagViews: [TagViewStruct] // 搜索结果

    public init(json: JSON) {
        self.tagViews = json["tagViews"].arrayValue.map { TagViewStruct(json: $0) }
    }
}

public struct TagViewStruct: Encodable {
    public let id: String // 标签id
    public let name: String // 标签名称
    public let description: String // 描述信息
    public let isAvailable: Bool // 是否有权限查看
    public let isSubscribed: Bool // 是否收藏
    /// 标签权限类型
    public let permissionType: TagPermissionType
    /// 协作者数量
    public let teamworkerCount: String

    public init(json: JSON) {
        self.id = json["id"].stringValue
        self.name = json["name"].stringValue
        self.description = json["description"].stringValue
        self.isAvailable = json["isAvailable"].boolValue
        self.isSubscribed = json["isSubscribed"].boolValue
        self.permissionType = TagPermissionType(rawValue: json["permissionType"].intValue) ?? .default
        self.teamworkerCount = json["teamworkerCount"].stringValue
    }
}

public struct MentionItem {
    public var id: String
    public var content: String
    public var isAvailable: Bool

    public init(id: String, content: String, isAvailable: Bool) {
        self.id = id
        self.content = content
        self.isAvailable = isAvailable
    }
}


///TODELETE model为什么不拆分类，都写这里？

///定义见：https://bytedance.feishu.cn/docs/doccnJWEcnDj0drdefiQSlBxVKf#
public struct OpenMessageItemRes : Codable{
    public var content: String
    public var version:Int
    public var versionStr: String?=nil
    public init(json: JSON) {
        self.content = json["content"].stringValue
        self.version = json["version"].intValue
        self.versionStr = json["versionStr"].stringValue
    }
    public init(content:String, version:Int){
        self.content = content
        self.version = version
        self.versionStr = nil
    }
}

public struct OpenMessageRes : Codable{
    public let messages : [String : OpenMessageItemRes]
    
}

public struct BlockOnTypeMessageRes : Codable{
    public let command : String
    public let data : BlockOnTypeMessageData
}

public struct BlockOnTypeMessageData : Codable{
    public let header : BlockOnTypeMessageHeader
    public let event : String
}

public struct BlockOnTypeMessageHeader : Codable{
    public let logID : String
    public let blockID : String
    public let action : String
    public let version : Int
    public let versionStr : String
}

public struct BlockOnEntityData: Codable{
    public let header : BlockOnTypeMessageHeader
    public let event : BlockInfo
}

public struct BlockOnEntityMessageData:Codable{
    public let version: Int
    public let sourceData: String
}



