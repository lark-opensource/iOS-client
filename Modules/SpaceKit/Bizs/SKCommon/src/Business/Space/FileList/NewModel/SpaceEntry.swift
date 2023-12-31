//
//  SpaceEntry.swift
//  SKCommon
//
//  Created by guoqp on 2020/9/8.
//  swiftlint:disable line_length file_length type_body_length

import Foundation
import SwiftyJSON
import SKFoundation
import SKResource
import HandyJSON
import ThreadSafeDataStructure
import UniverseDesignIcon
import SpaceInterface
import SKInfra
import LarkDocsIcon

public let singleContainerOwnerTypeValue = 5
public let defaultOwnerType = 0
public let oldFolderOwnerType = 0
public let oldShareFolderOwnerType = 1
private let ownerTenantIDKey = "ownerTenantID"
private let ownerTenantNameKey = "ownerTenantName"


open class SpaceEntry {

    // MARK: - 服务端下发
    //https://bytedance.feishu.cn/wiki/wikcntfSVCqSRdPMup9TCEz2Qld
    /// 后台返回的 name 字段
    public private(set) var realName: String?
    /// 打开文档时，唯一id（文章对应的 URL）
    public let objToken: FileListDefine.ObjToken
    /// 和后台交互时，唯一id（删除、移动等）
    public private(set) var nodeToken: FileListDefine.NodeToken
    /// 文档类型
    public private(set) var type: DocsType
    /// 浏览时间
    public private(set) var openTime: TimeInterval?
    /// 文件拥有者的ID
    public private(set) var ownerID: String?

    /// 最后一个编辑这篇文档的人的uid
    public private(set) var editUid: String?
    public private(set) var editorName: String?
    public private(set) var expireTime: TimeInterval?
    /// 添加时间，用于 共享-文件，共享-文件夹中显示
    public private(set) var addTime: TimeInterval?
    /// 编辑文档时间戳
    public private(set) var editTime: TimeInterval?
    /// 创建文档时间戳
    public private(set) var createTime: TimeInterval? //协议返回中有"create_time"字段，需要确认含义、是否需要
    /// 仅用于与我共享的文档列表，显示分享时间
    public private(set) var shareTime: TimeInterval?
    /// 最近操作-最近修改
    public private(set) var myEditTime: TimeInterval? // my_edit_time
    /// 最近操作-全部
    public private(set) var activityTime: TimeInterval? //activity_time
    /// 添加到收藏的时间
    public private(set) var favoriteTime: TimeInterval? // star_time
    /// 用于浏览器打开的url
    public private(set) var shareUrl: String?
    public private(set) var originUrl: String?
    ///缩略图url
    public private(set) var thumbnailUrl: String?
    ///头像url
    public private(set) var ownerAvatarUrl: String?
    /// 是否置顶
    public private(set) var pined: Bool = false
    /// 是否收藏
    public private(set) var stared: Bool = false
    /// 是否收藏
    public var subscribed: Bool = false
    /// 是否置顶
    public private(set) var isTop: Bool = false
    /// 创建这篇文档的人的uid
    public private(set) var createUid: String?
    /// 缩略图加密信息：https://bytedance.feishu.cn/space/doc/doccn5osI4Zl6jXHR0Oyjb3DgRd
    public private(set) var thumbnailExtra: [String: Any]?
    /// 额外信息
    public private(set) var extra: [String: Any]?
    ///自定义icon
    public private(set) var customIcon: CustomIcon?

    public private(set) var objID: Int?
    /// 文件拥有者的名字(会优先用别名)
    public private(set) var owner: String?
    /// 父节点的nodeToken
    public private(set) var parent: String?
    ///快捷方式为1
    public private(set) var nodeType: Int?
    ///新旧类型区分(文档和文件夹都有)
    public private(set) var ownerType: Int = defaultOwnerType
    /// 密级标签名字
    public private(set) var secureLabelName: String?
    ///密级级别
    public private(set) var secureLabeLevel: Int?
    ///密级ID
    public private(set) var secureLabelId: String?
    /// 获取密级详情的错误码
    public private(set) var secLabelCode: SecretLevelCode = .empty
    /// 是否可以设置密级
    public private(set) var canSetSecLabel: CanSetSecLabel = .no
    /// 秘钥是否被删除
    public private(set) var secretKeyDelete: Bool?
    /// shortcut本体是否被删除
    public private(set) var deleteFlag: Int?
    /// 自定义icon组件显示信息
    public private(set) var iconInfo: String?
    

    // MARK: - 业务扩展var
    /// 是否设置了离线缓存
    public var isSetManuOffline = false
    /// 是否显示过手动离线中的状态了，如果显示过了，后续同步不再显示
    public var hadShownManuStatus = false
    /// 添加离线的时间
    public var addManuOfflineTime: TimeInterval?
    ///当前文档的同步状态，默认是没有在同步
    public var syncStatus = SyncStatus(upSyncStatus: .none, downloadStatus: .none)
    /// 是否在同步
    public var isSyncing = false
    /// 文档的实体objToken, wiki下是真实token，而非wikiToken
    public var realToken: String { objToken }

    public var canOpenWhenOffline: Bool {
        // 密钥删除状态，禁止离线打开
        guard secretKeyDelete != true else {
            return false
        }
        guard type.offLineEnable else {
            return false
        }
        return preloadKey.hasClientVar || objToken.isFakeToken
    }

    // 是否允许设置手动离线
    public var canSetManualOffline: Bool {
        // 密钥删除状态，禁止设置手动离线
        guard secretKeyDelete != true else {
            return false
        }
        return ManualOfflineConfig.enableFileType(type)
    }

    /// 快捷方式
    public var isShortCut: Bool {
        return (nodeType == 1)
    }
    
    /// 是否共享文件夹，FolderEntry 进行重写
    public var isShareFolder: Bool {
        return false
    }

    ///单容器节点
    public var isSingleContainerNode: Bool {
        return (ownerType == singleContainerOwnerTypeValue)
    }

    ///外部标签
    public var external: Bool {
        if let dic = extra, let external = dic["is_external"] as? Bool {
            return external
        }
        return false
    }
    
    /// 自定义关联组织标签
    public var organizationTagValue: String? {
        if let dic = extra,
           let displayTag = dic["display_tag"] as? [String: Any],
           let tagValue = displayTag["tag_value"] as? String {
            return tagValue
        }
        return nil
    }

    /// 是否被标记为模板
    public var hasTemplateTag: Bool {
        if let dic = extra, let templateType = dic["template_type"] as? Int {
            // 0 表示非模板，其他值表示模板类型，这里暂时不关心具体的类型
            return templateType != 0
        }
        return false
    }

    /// 是否允许在最近列表里展示
    public var isEnableShowInList: Bool {
        guard isSupportedType() else {
            DocsLogger.info("entity is unSupportType for \(DocsTracker.encrypt(id: objToken))")
            // 未知类型过滤掉
            return false
        }
        if type == .slides {
            //产品要求slides在列表中不被fg屏蔽
            return true
        }
        return type.enabledByFeatureGating
    }

    /// 是否在Space容器中
    /// 收藏一篇space文档，记作A收藏，再将这篇space文档移到wiki，接着再收藏这个wiki文档，记作B收藏。此时收藏列表会同时出现A、B两条记录，A记录是异常的，操作移动会失败。在extra结构体中新增biz_type字段，1：表示space容器，2：表示wiki容器，-1：表示不存在容器或者未知类型， A收藏记录返回的biz_type会等于-1，B收藏记录返回的biz_type会等于2
    /// extra 结构体中biz_type字段，1：表示space容器，2：表示wiki容器，-1：表示不存在容器或者未知类型
    public var contentExistInSpace: Bool {
        if let bizType = extra?["biz_type"] as? Int {
            return bizType == 1
        }
        return true
    }

    // MARK: Space & Wiki 互通
    // 仅 shortcut 有值，表明指向的文档是否在 wiki 中，1 表示在 space，2 表示在 wiki
    public private(set) var objBizType: Int?
    // 仅 shortcut 有值，若指向的文档在 wiki 中，这里可以取到 wiki token
    public private(set) var bizNodeToken: String?

    // shortcut 指向的内容是否在 wiki 中
    public var originInWiki: Bool {
        guard isShortCut else { return false }
        return objBizType == 2
    }

    /// 缩略图加密信息的格式化出来方便使用
    public var thumbExtraInfo: SpaceThumbnailInfo.ExtraInfo?

    /// 存储分类var
    public let storedExtensionProperty: SafeDictionary<String, Any> = [:] + .readWriteLock


    public init(type: DocsType, nodeToken: FileListDefine.NodeToken, objToken: FileListDefine.ObjToken) {
        switch type {
        case .trash, .mediaFile:
            spaceAssertionFailure("@guoqingping 不应该出现 type = \(type)")
        default: break
        }
        self.type = type
        self.nodeToken = nodeToken
        self.objToken = objToken
    }

    public func equalTo(_ another: SpaceEntry) -> Bool {
        return type == another.type &&
            pined == another.pined &&
            stared == another.stared &&
            isTop == another.isTop &&
            nodeToken == another.nodeToken &&
            objToken == another.objToken &&
            name == another.name &&
            createUid == another.createUid &&
            createTime == another.createTime &&
            editTime == another.editTime &&
            editUid == another.editUid &&
            addTime == another.addTime &&
            openTime == another.openTime &&
            editorName == another.editorName &&
            expireTime == another.expireTime &&
            shareTime == another.shareTime &&
            owner == another.owner &&
            ownerID == another.ownerID &&
            parent == another.parent &&
            objID == another.objID &&
            shareUrl == another.shareUrl &&
            thumbnailUrl == another.thumbnailUrl &&
            ownerAvatarUrl == another.ownerAvatarUrl &&
            isOffline == another.isOffline &&
            isExternal == another.isExternal &&
            hasPermission == another.hasPermission &&
            isSyncing == another.isSyncing &&
            myEditTime == another.myEditTime &&
            activityTime == another.activityTime &&
            favoriteTime == another.favoriteTime &&
            isSetManuOffline == another.isSetManuOffline &&
            hadShownManuStatus == another.hadShownManuStatus &&
            addManuOfflineTime == another.addManuOfflineTime &&
            syncStatus == another.syncStatus &&
            customIcon == another.customIcon &&
            ownerType == another.ownerType &&
            nodeType == another.nodeType &&
            secureLabelName == another.secureLabelName &&
            secureLabeLevel == another.secureLabeLevel &&
            secureLabelId == another.secureLabelId &&
            secLabelCode == another.secLabelCode &&
            canSetSecLabel == another.canSetSecLabel &&
            secretKeyDelete == another.secretKeyDelete &&
            objBizType == another.objBizType &&
            bizNodeToken == another.bizNodeToken &&
            deleteFlag == another.deleteFlag &&
            iconInfo == another.iconInfo
    }

    /// 除了 newNodeToken 和 newObjToken改变，其他都复制一份，生成一个新的实例。
    /// 对应的值是nil，那么就不修改
    public func makeCopy(newNodeToken: String? = nil, newObjToken: String? = nil) -> SpaceEntry {
        let newObjToken = newObjToken ?? self.objToken
        let targetNodeToken = newNodeToken ?? self.nodeToken
        let another = SpaceEntryFactory.createEntry(type: type, nodeToken: targetNodeToken, objToken: newObjToken)
        another.pined = pined
        another.stared = stared
        another.isTop = isTop
        another.realName = realName
        another.createUid = createUid
        another.createTime = createTime
        another.editTime = editTime
        another.editUid = editUid
        another.addTime = addTime
        another.openTime = openTime
        another.editorName = editorName
        another.expireTime = expireTime
        another.shareTime = shareTime
        another.owner = owner
        another.ownerID = ownerID
        another.parent = parent
        another.objID = objID
        another.shareUrl = shareUrl
        another.originUrl = originUrl
        another.thumbnailUrl = thumbnailUrl
        another.ownerAvatarUrl = ownerAvatarUrl
        another.isSyncing = isSyncing
        another.myEditTime = myEditTime
        another.activityTime = activityTime
        another.favoriteTime = favoriteTime
        another.isSetManuOffline = isSetManuOffline
        another.hadShownManuStatus = hadShownManuStatus
        another.addManuOfflineTime = addManuOfflineTime
        another.syncStatus = syncStatus
        another.extra = extra
        another.thumbnailExtra = thumbnailExtra
        another.thumbExtraInfo = thumbExtraInfo
        another.customIcon = customIcon
        another.ownerType = ownerType
        another.nodeType = nodeType
        another.secureLabelName = secureLabelName
        another.secureLabeLevel = secureLabeLevel
        another.secureLabelId = secureLabelId
        another.secLabelCode = secLabelCode
        another.canSetSecLabel = canSetSecLabel
        another.secretKeyDelete = secretKeyDelete
        another.objBizType = objBizType
        another.bizNodeToken = bizNodeToken
        another.deleteFlag = deleteFlag
        another.iconInfo = iconInfo

        storedExtensionProperty.forEach { another.updateStoredExtensionProperty(key: $0, value: $1) }
        if another.isShortCut || another.type == .folder {
            if another.nodeToken.isEmpty {
                DocsLogger.warning("nodeToken is nil")
            }
        }
        return another
    }

    public func transform() -> DocsInfo {
        let info = DocsInfo(type: type, objToken: objToken)
        info.title = name
        info.creatorID = createUid
        info.editTime = editTime
        info.createTime = createTime
        info.editor = editorName
        info.ownerID = ownerID
        info.pined = pined
        info.stared = stared
        info.shareUrl = shareUrl
        if originInWiki, let wikiToken = bizNodeToken, let shareUrl = shareUrl, let url = URL(string: shareUrl) {
            // 本体在 wiki 的 space shortcut，复制链接时替换成 wiki url
            let wikiURL = WorkspaceCrossRouter.redirect(spaceURL: url, wikiToken: wikiToken)
            info.shareUrl = wikiURL.absoluteString
        }
        info.fileType = fileType
        info.ownerName = owner
        info.defaultIcon = defaultIcon
        info.customIcon = customIcon
        info.subscribed = subscribed
        info.nodeType = nodeType
        info.ownerType = ownerType
        info.secLabelName = secureLabelName
        info.titleSecureKeyDeleted = secretKeyDelete ?? false
        let date = Date(timeIntervalSince1970: self.createTime ?? 0)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        info.createDate = formatter.string(from: date)

        info.fromModule = fromModule
        info.fromSubmodule = fromSubmodule
        if let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self) {
            dataCenterAPI.userInfoFor(ownerID ?? "", callBack: { docsInfo in
                info.tenantID = docsInfo?.tenantID
            })
        }

        if let folder = self as? FolderEntry {
            info.shareFolderInfo = folder.shareFolderInfo
            info.shareVersion = folder.shareVersion
            info.folderType = folder.folderType
        }
        return info
    }

    public func updateStoredExtensionProperty(key k: String, value v: Any) {
        self.storedExtensionProperty[k] = v
    }

    public func updateHiddenStatus(_ hidden: Bool) {
        self.isHiddenStatus = hidden
    }
    public func updatePinedStatus(_ pined: Bool) {
        self.pined = pined
    }
    public func updateStaredStatus(_ stared: Bool) {
        self.stared = stared
    }
    public func updateShareURL(_ url: String?) {
        self.shareUrl = url
    }
    public func updateOriginURL(_ url: String?) {
        self.originUrl = url
    }
    public func updateIconInfo(_ iconInfo: String?) {
        self.iconInfo = iconInfo
    }
    public func updateTopStatus(_ isTop: Bool) {
        self.isTop = isTop
    }
    public func updateName(_ name: String?) {
        self.realName = name
    }
    public func updateCreateUid(_ uid: String?) {
        self.createUid = uid
    }
    public func updateMyEditTime(_ time: TimeInterval?) {
        self.myEditTime = time
    }
    internal func updateOpenTime(_ time: TimeInterval?) {
        self.openTime = time
    }
    internal func updateActivityTime(_ time: TimeInterval?) {
        self.activityTime = time
    }
    public func updateFavoriteTime(_ time: TimeInterval?) {
        self.favoriteTime = time
    }
    internal func updateShareTime(_ time: TimeInterval?) {
        self.shareTime = time
    }
    public func updateOwnerID(_ id: String?) {
        self.ownerID = id
    }
    public func updateAddTime(_ time: TimeInterval?) {
        self.addTime = time
    }
    public func updateOwner(_ owner: String?) {
        self.owner = owner
    }
    public func updateExtraValue(_ extra: [String: Any]?) {
        self.extra = extra
        self.updateExtra()
    }
    public func updateEditTime(_ time: TimeInterval?) {
        self.editTime = time
    }
    public func updateCreateTime(_ time: TimeInterval?) {
        self.createTime = time
    }
    public func updateEditUid(_ uid: String?) {
        self.editUid = uid
    }
    public func updateParent(_ parent: String?) {
        self.parent = parent
    }
    internal func updateEditorName(_ name: String?) {
        self.editorName = name
    }
    public func updateCustomIcon(_ customIcon: CustomIcon) {
        self.customIcon = customIcon
    }
    public func updateOwnerType(_ ownerType: Int) {
        self.ownerType = ownerType
    }
    public func updateNodeType(_ nodeType: Int?) {
        self.nodeType = nodeType
    }
    public func updateThumbnailExtra(_ thumbnailExtra: [String: Any]?) {
        self.thumbnailExtra = thumbnailExtra
        self.updateThumbExtraInfo()
    }

    public func update(secureLabelName: String?) {
        self.secureLabelName = secureLabelName
    }

    public func update(secLabelCode: SecretLevelCode) {
        self.secLabelCode = secLabelCode
    }

    public func update(secretKeyDelete: Bool?) {
        self.secretKeyDelete = secretKeyDelete
    }

    public func update(nodeToken: String) {
        self.nodeToken = nodeToken
    }

    public var preloadKey: PreloadKey {
        return PreloadKey(objToken: objToken,
                          type: type,
                          driveFileType: DriveFileType(fileExtension: fileType))
    }

    public var defaultIcon: UIImage {
        guard isSupportedType() else {
            return UDIcon.getIconByKeyNoLimitSize(.fileRoundUnknowColorful)
        }
        switch type {
        case .folder:
            spaceAssertionFailure("Should be override by FolderEntry")
            return UDIcon.getIconByKeyNoLimitSize(.fileFolderColorful)
        case .trash:
            spaceAssertionFailure("Trash type should not exist.")
            return UDIcon.getIconByKeyNoLimitSize(.fileRoundUnknowColorful)
        case .myFolder:
            spaceAssertionFailure("Should be override by FolderEntry")
            return UDIcon.getIconByKeyNoLimitSize(.fileFolderColorful)
        case .file:
            spaceAssertionFailure("Should be override by DriveEntry")
            return UDIcon.getIconByKeyNoLimitSize(.fileRoundImageColorful)
        case .wiki, .wikiCatalog:
            spaceAssertionFailure("Should be override by WikiEntry")
            return UDIcon.getIconByKeyNoLimitSize(.fileRoundDocColorful)
        case .mediaFile:
            spaceAssertionFailure("Should be override by DriveEntry")
            return UDIcon.getIconByKeyNoLimitSize(.fileRoundImageColorful)
        case .minutes:
            return UIImage()
        default:
            return UDIcon.getIconByKeyNoLimitSize(type.roundColorfulIconKey)
        }
    }

    // 彩色方形不规则图案
    public var colorfulIcon: UIImage {
        guard isSupportedType() else {
            return UDIcon.getIconByKeyNoLimitSize(.fileUnknowColorful)
        }
        switch type {
        case .folder:
            spaceAssertionFailure("Should be override by FolderEntry")
            return UDIcon.getIconByKeyNoLimitSize(.fileFolderColorful)
        case .trash:
            spaceAssertionFailure("Trash type should not exist.")
            return UDIcon.getIconByKeyNoLimitSize(.fileUnknowColorful)
        case .myFolder:
            spaceAssertionFailure("Should be override by FolderEntry")
            return UDIcon.getIconByKeyNoLimitSize(.fileFolderColorful)
        case .file:
            spaceAssertionFailure("Should be override by DriveEntry")
            return UDIcon.getIconByKeyNoLimitSize(.fileImageColorful)
        case .wiki, .wikiCatalog:
            spaceAssertionFailure("Should be override by WikiEntry")
            return UDIcon.getIconByKeyNoLimitSize(.fileDocColorful)
        case .mediaFile:
            spaceAssertionFailure("Should be override by DriveEntry")
            return UDIcon.getIconByKeyNoLimitSize(.fileImageColorful)
        case .minutes:
            return UIImage()
        default:
            return UDIcon.getIconByKeyNoLimitSize(type.squareColorfulIconKey)
        }
    }

    /// Quick Access 上使用的 icon
    public var quickAccessImage: UIImage? {
        defaultIcon
    }
}

extension SpaceEntry {
    public var isOffline: Bool {
        return objToken.isFakeToken
    }
    public var isExternal: Bool {
        guard let extra = extra else { return false }
        //is_external表示这篇文档是否可以被外部租户看到，而不是是否是外部租户的，
        //是否对外文件夹
        return extra["is_external"] as? Bool ?? false
    }
    public var hasPermission: Bool {
        //对当前fileEntry是否有权限，外部租户无权限时显示 “无权限文件”
        if let extra = extra, extra.keys.contains("has_perm") {
            return extra["has_perm"] as? Bool ?? false
        }
        return true
    }

    public var name: String {
        if secretKeyDelete == true {
            return BundleI18n.SKResource.CreationDoc_Docs_KeyInvalidTitle
        }
        return Self.displayName(title: realName, type: type)
    }

    public static func displayName(title: String?, type: DocsType) -> String {
        guard let realName = title, !realName.isEmpty else {
            if type == .file {
                return "" // drive需要业务判断是否显示缓存文件名
            }
            return type.untitledString
        }
        return realName
    }

    public var thumbnailURL: String? {
        if let url = thumbnailUrl, !url.isEmpty {
            return thumbnailUrl
        } else {
            // 兼容pin/list  下发json thumbnail结构变化
            return extra?["thumbnail"] as? String
        }
    }

    public var noPermIcon: UIImage? {
        return UDIcon.getIconByKeyNoLimitSize(.fileRoundNopermissionColorful)
    }
    
    public var originDeleted: Bool {
        return deleteFlag != 0
    }
}



extension SpaceEntry {
    public struct CustomIcon: Equatable {
        /// 自定义icon的key
        public var iconKey: String
        /// 自定义icon的type
        public var iconType: IconType
        /// 自定义icon的unit, file storage unit
        public var iconFSUnit: String
        public static func == (lhs: CustomIcon, rhs: CustomIcon) -> Bool {
            return lhs.iconKey == rhs.iconKey &&
                lhs.iconType == rhs.iconType &&
                lhs.iconFSUnit == rhs.iconFSUnit
        }
    }
    /// 自定义图片的类型
    public enum IconType: Int, HandyJSONEnum, Codable {
        case unknow = 0
        case emoji = 1
        case image = 2
        case custom = 3 // The image uploaded by user

        // Internal defined enum
        case remove = 1024 // Icon选择面板移除选项

        static let supportedShowingTypes: [IconType] = [.image, .custom, .remove]

        /// 判断当前是否是支持显示的类型，一开始支持图片、自定义的图，加这个是为了考虑以后兼容新的类型，在老的客户端上至少能正常显示默认图
        public var isCurSupported: Bool {
            return false
//            guard LKFeatureGating.docsDIYIconEnabled else { return false }
//            return IconType.supportedShowingTypes.contains(self)
        }
    }
}


extension SpaceEntry {
    ///needCover  增量更新还是全量更新。 最近列表explorer下发数据时全量更新，协同推送数据时增量更新
    public func updatePropertiesFrom(_ json: JSON, needCover: Bool = true) {
        json["type"].mapIfExists {
            if let value = $0.int {
                self.type = DocsType(rawValue: value)
            }
        }
        json["name"].mapIfExists { self.realName = $0.string }
        json["create_uid"].mapIfExists { self.createUid = $0.string }
        json["edit_uid"].mapIfExists { self.editUid = $0.string }
        json["edit_time"].mapIfExists { self.editTime = $0.double }
        json["create_time"].mapIfExists { self.createTime = $0.double }
        json["add_time"].mapIfExists { self.addTime = $0.double }
        json["open_time"].mapIfExists { self.openTime = $0.double }
        json["editor_name"].mapIfExists { self.editorName = $0.string }
        json["expire_time"].mapIfExists { self.expireTime = $0.double }
        json["obj_id"].mapIfExists { self.objID = $0.int }
        json["url"].mapIfExists { self.shareUrl = $0.string }
        json["url"].mapIfExists { self.originUrl = $0.string }
        json["share_time"].mapIfExists { self.shareTime = $0.double }
        json["extra"].mapIfExists { self.extra = $0.dictionaryObject }
        json["owner"].mapIfExists { self.owner = $0.string }
        json["owner_id"].mapIfExists { self.ownerID = $0.string }
        json["parent"].mapIfExists { self.parent = $0.string }
        json["is_pined"].mapIfExists { self.pined = $0.boolValue }
        json["is_stared"].mapIfExists { self.stared = $0.boolValue }
        json["is_top"].mapIfExists { self.isTop = $0.boolValue }
        json["my_edit_time"].mapIfExists { self.myEditTime = $0.double }
        json["activity_time"].mapIfExists { self.activityTime = $0.double }
        json[FileListServerKeys.favoriteTime.rawValue].mapIfExists { self.favoriteTime = $0.double }
        json["node_type"].mapIfExists { self.nodeType = $0.intValue }
        json[FileListServerKeys.ownerType.rawValue].mapIfExists { self.ownerType = $0.int ?? defaultOwnerType }
        json[FileListServerKeys.shareVersion.rawValue].mapIfExists { self.shareVersion = $0.int }
        json[FileListServerKeys.isHiddenStatus.rawValue].mapIfExists { self.isHiddenStatus = $0.boolValue }
        json[FileListServerKeys.deleteFlag.rawValue].mapIfExists { self.deleteFlag = $0.int }

        if let iconKey = json[FileListServerKeys.iconKey.rawValue].string,
           !iconKey.isEmpty,
            let iconFSUnit = json[FileListServerKeys.iconFSUnit.rawValue].string,
            let iconTypeValue = json[FileListServerKeys.iconType.rawValue].int,
            let iconType = IconType(rawValue: iconTypeValue) {
            self.customIcon = CustomIcon(iconKey: iconKey, iconType: iconType, iconFSUnit: iconFSUnit)
        }

        json[ManualOfflineFile.isSetManuOfflineKey].mapIfExists { self.isSetManuOffline = $0.boolValue }
        json[DocsOfflineSyncManager.needSyncKey].mapIfExists { self.isSyncing = $0.boolValue }
        json[ManualOfflineFile.fileSizeKey].mapIfExists { self.fileSize = $0.uInt64Value }
        json[ManualOfflineFile.hadShownManuStatusKey].mapIfExists { self.hadShownManuStatus = $0.boolValue }
        json[ManualOfflineFile.addManuOfflineTimeKey].mapIfExists { self.addManuOfflineTime = $0.double }
        json[ManualOfflineFile.syncStatusKey].mapIfExists {
            let downloadStatus = DownloadStatus(rawValue: $0.intValue) ?? .none
            self.syncStatus = self.syncStatus.modifingDownLoadStatus(downloadStatus)
        }

        if needCover {
            self.thumbnailUrl = json["thumbnail"].string
            self.thumbnailExtra = json[FileListServerKeys.thumbnailExtra.rawValue].dictionaryObject
            self.secureLabelName = json[FileListServerKeys.secureLabelName.rawValue].string
            self.secureLabeLevel = json[FileListServerKeys.secureLabelLevel.rawValue].int
            self.secureLabelId = json[FileListServerKeys.secureLabelId.rawValue].string
            if let code = json[FileListServerKeys.secureLabelCode.rawValue].int,
                let secLabelCode = SecretLevelCode(rawValue: code) {
                self.secLabelCode = secLabelCode
            } else {
                self.secLabelCode = .empty
            }
            if let code = json[FileListServerKeys.canSetSecLabel.rawValue].int,
               let canSetSecLabel = CanSetSecLabel(rawValue: code) {
                self.canSetSecLabel = canSetSecLabel
            } else {
                self.canSetSecLabel = .no
            }
            self.secretKeyDelete = json[FileListServerKeys.secretKeyDelete.rawValue].bool
            self.objBizType = json[FileListServerKeys.objBizType.rawValue].int
            self.bizNodeToken = json[FileListServerKeys.bizNodeToken.rawValue].string
            self.iconInfo = json[FileListServerKeys.iconInfo.rawValue].string
        } else {
            json["thumbnail"].mapIfExists { self.thumbnailUrl = $0.string }
            json[FileListServerKeys.thumbnailExtra.rawValue].mapIfExists { self.thumbnailExtra = $0.dictionaryObject }
            json[FileListServerKeys.secureLabelName.rawValue].mapIfExists { secureLabelName = $0.string }
            json[FileListServerKeys.secureLabelLevel.rawValue].mapIfExists { secureLabeLevel = $0.int }
            json[FileListServerKeys.secureLabelId.rawValue].mapIfExists { secureLabelId = $0.string }
            json[FileListServerKeys.secureLabelCode.rawValue].mapIfExists {
                secLabelCode = SecretLevelCode(rawValue: $0.intValue) ?? .empty
            }
            json[FileListServerKeys.canSetSecLabel.rawValue].mapIfExists {
                canSetSecLabel = CanSetSecLabel(rawValue: $0.intValue) ?? .no
            }
            json[FileListServerKeys.secretKeyDelete.rawValue].mapIfExists { secretKeyDelete = $0.bool }
            json[FileListServerKeys.objBizType.rawValue].mapIfExists { objBizType = $0.int }
            json[FileListServerKeys.bizNodeToken.rawValue].mapIfExists { bizNodeToken = $0.string }
            json[FileListServerKeys.iconInfo.rawValue].mapIfExists { self.iconInfo = $0.string }
        }

        /// 将缩略图加密数据格式化好，方便使用
        updateThumbExtraInfo()
        updateExtra()
    }

    public func update(ownerInfo: UserInfo) {
        updateOwner(ownerInfo.nameForDisplay())
        ownerTenantName = ownerInfo.tenantName
        ownerTenantID = ownerInfo.tenantID
        ownerAvatarUrl = ownerInfo.avatarURL
    }

    private func updateThumbExtraInfo() {
        guard let thumExtraJson = self.thumbnailExtra else {
            self.thumbExtraInfo = nil
            return
        }
        self.thumbExtraInfo = SpaceThumbnailInfo.ExtraInfo(thumExtraJson)
    }
    
    @objc
    public func updateExtra() {}

    @objc
    public func isSupportedType() -> Bool {
        return type.isSupportedType
    }
}

extension SpaceEntry {
    // 数据哪个租户
    public var ownerTenantName: String? {
        get { return storedExtensionProperty[ownerTenantNameKey] as? String }
        set { updateStoredExtensionProperty(key: ownerTenantNameKey, value: newValue as Any) }
    }

    // 数据哪个租户,租户id
    public var ownerTenantID: String? {
        get { return storedExtensionProperty[ownerTenantIDKey] as? String }
        set { updateStoredExtensionProperty(key: ownerTenantIDKey, value: newValue as Any) }
    }
}

extension SpaceEntry: CustomStringConvertible {
    @objc public var description: String {
        return "objToken:\(objToken) type: \(type.name), name: \(String(describing: name)), openTime: \(String(describing: openTime)), editTime \(String(describing: editTime)), isStard: \(stared), istop: \(isTop), ispined: \(pined), nodeType: \(String(describing: nodeType)), needSync: \(isSyncing)"
    }
}
extension SpaceEntry: FolderEntryProtocol, DriveEntryProtocol, SimpleModeProtocol {
}
//列表页更多面板的埋点tracker
extension SpaceEntry {
    public var listMoreItemClickTracker: ListMoreItemClickTracker {
        ListMoreItemClickTracker(isShareFolder: isShareFolder, type: type, originInWiki: originInWiki)
    }
}
