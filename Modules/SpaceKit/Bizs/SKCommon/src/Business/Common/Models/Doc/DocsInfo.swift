//  Created by Songwen Ding on 2018/5/14.
// swiftlint:disable file_length

import SKFoundation
import SKResource
import SwiftyJSON
import UniverseDesignIcon
import UniverseDesignEmpty
import UniverseDesignColor
import CoreGraphics
import SpaceInterface
import SKInfra
import LarkDocsIcon
import ThreadSafeDataStructure
import UniverseDesignTheme

public typealias CustomIcon = SpaceEntry.CustomIcon
public typealias IconType = SpaceEntry.IconType

public final class DocsInfo {
    public var type: DocsType // 在 wiki 的场景下，不能正确反应真实文件类型。如果要考虑 wiki 场景下的真实文件类型，请使用 -inherentType 接口
    public var objToken: FileListDefine.ObjToken
    //MARK: urlToken、urlType
    //含义：文档链接里携带的token和type，例如wiki链接则urlType是.wiki，docX链接urlType是.docX
    //除离线同步完成由fakeToken转为realToken外，其他时候保持不变
    public var urlToken: FileListDefine.ObjToken
    public var urlType: DocsType
    public var revision: Int?
    public var title: String?
    public var creator: String?
    public var creatorID: String?
    public var ownerID: String?
    public var tenantID: String?
    public var createTime: TimeInterval?
    public var serverTime: TimeInterval?
    public var createDate: String?
    public var editor: String?
    public var editTime: TimeInterval?
    public var delete: Bool?
    public var shareUrl: String?
    public var ownerName: String?
    public var version: Int? //文档 meta 操作次数
    ///快捷方式为1
    public var nodeType: Int?
    ///新旧类型区分(文档和文件夹都有)
    public var ownerType: Int?
    ///打开文档来源(主要是埋点用，目前只判断了docs_feed场景，如果其他入口判断，请在OpenDocsFrom增加对应值)
    public var openDocsFrom: OpenDocsFrom = .other

    /// 快捷方式
    public var isShortCut: Bool {
        return (nodeType == 1)
    }
    ///单容器节点
    public var isSingleContainerNode: Bool {
        return (ownerType == singleContainerOwnerTypeValue)
    }
    public var displayName: String {
        let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self)
        let user = dataCenterAPI?.userInfo(for: ownerID ?? "")
        return user?.nameForDisplay() ?? ""
    }
    
    /// 别名，优先级最高，支持多语言
    public var ownerAliasInfo: UserAliasInfo?
    /// 模板owner别名
    public var ownerDisplayName: String {
        if let displayName = ownerAliasInfo?.currentLanguageDisplayName {
            return displayName
        } else {
            return ownerName ?? ""
        }
    }
    public var isOwner: Bool {
        let userID = User.current.info?.userID
        guard userID != nil, self.ownerID != nil else { return false }
        return userID == self.ownerID
    }
    /// 收藏标识
    public var pined: Bool = false
    public var stared: Bool = false
    /// 文档更新订阅标识
    public var subscribed: Bool = false
    /// 文档评论更新订阅标识
    public var subscribedComment: Bool = false
    /// Drive
    public var fileType: String?
    /// 仅用于埋点，来自哪个模块
    public var fromModule: String?
     /// 仅用于埋点，来自哪个子模块
    public var fromSubmodule: String?
    public var isEnableTranslate: Bool?
    public var translationContext: TranslationContext?

    /// 小程序中的id ，CCM默认是nil
    public var appId: String?
    public var commentUser: CommentUser?

    // 以下这两个信息是从列表传递过来的，如果是直接url打开，则为nil
    public var isExternal: Bool?

    // Folder
    public var shareFolderInfo: FolderEntry.ShareFolderInfo?
    public var shareVersion: Int?
    public var folderType: FolderType?

    public var mindnoteInfo: MindnoteInfo?
    public var wikiInfo: WikiInfo?
    public var isInVideoConference: Bool?
    // 自定义icon
    public var customIcon: CustomIcon?
    public var defaultIcon: UIImage?
    
    //新的自定义icon信息
    public var iconInfo: String?

    // 密级信息
    public var secLabel: SecretLevel?
    // 密级名称
    public var secLabelName: String?
    public var secretLevelName: String? {
        if let secretTitle = secLabel?.label.name, !secretTitle.isEmpty {
            return secretTitle
        }
        return secLabelName
    }

    // meta接口密钥删除(title的密钥)
    public var titleSecureKeyDeleted: Bool = false
    
    public var objId: String?

    public private(set) var encryptedObjToken: String
    
    /// 模板类型
    public private(set) var templateType: TemplateType?

    /// 需要打印token时，用这个属性，不会泄漏真实token
    public var objTokenInLog: String {
        return encryptedObjToken
    }
    
    /// 版本信息相关
    public var versionInfo: VersionInfo?
    public var isVersion: Bool {
        return versionInfo != nil
    }
    // 文档容器信息
    public private(set) var containerInfo: WorkspaceCrossNetworkAPI.ContainerInfo?
    // containerInfo 没拉到时固定为 false
    public var isFromPhoenix: Bool {
        containerInfo?.containerType == .phoenix
    }

    /// 影子Drvie文件的id
    public var shadowFileId: String?
    /// 原始文档是否Drive文件（目前仅IM的Excel文件用Sheet打开场景）
    public var isOriginDriveFile: Bool {
        shadowFileId != nil
    }

    /// 文档新鲜度信息
    public var freshInfo: FreshInfo?
    
    public var syncBlocksConfig = SyncBlocksConfig()
    
    /// 一事一档关联信息
    public var references: [AssociateAppModel.ReferencesModel]?

    public init(type: DocsType, objToken: String) {
        self.objToken = objToken
        self.type = type
        self.urlToken = objToken
        self.urlType = type
        self.encryptedObjToken = DocsTracker.encrypt(id: objToken)
    }

    func updateIconInfo(_ customIcon: CustomIcon) {
        checkIfNeedNotifyIconKeyHasChanged(with: customIcon, oldIcon: self.customIcon)
        self.customIcon = customIcon
    }
    
    public func setTemplateType(_ value: TemplateType?) {
        templateType = value
    }

    public func update(containerInfo: WorkspaceCrossNetworkAPI.ContainerInfo) {
        self.containerInfo = containerInfo
    }

    public func updatePhoenixShareURLIfNeed() {
        guard isFromPhoenix else { return }
        guard let urlString = shareUrl,
              let url = URL(string: urlString) else {
            return
        }
        let phoenixURL = WorkspaceCrossRouter.redirectPhoenixURL(spaceURL: url)
        shareUrl = phoenixURL.absoluteString
    }

    private func checkIfNeedNotifyIconKeyHasChanged(with newIcon: CustomIcon, oldIcon: CustomIcon?) {
        guard newIcon != oldIcon else {
            DocsLogger.info("custom icon not changed")
            return
        }
        guard let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self) else {
            return
        }
        dataCenterAPI.update(customIcon: newIcon, for: objToken)
        NotificationCenter.default.post(name: Notification.Name.Docs.docsInfoIconKeyUpdated, object: self)
    }
}

extension DocsInfo {
    public var thumbnailStr: String {
        return OpenAPI.docs.baseUrl + "/file/f/cdp-\(type.name)-\(objToken)~noop/"
    }
}

extension DocsInfo {
    // 用于埋点
    public func getAppForm() -> String {
        var appForm = "none"
        if self.isInVideoConference ?? false {
            appForm = "vc"
        } else {
            if self.openDocsFrom == .docsfeed {
                appForm = self.openDocsFrom.rawValue
            }
        }
        return appForm
    }
}

extension DocsInfo: Hashable {
    public static func == (lhs: DocsInfo, rhs: DocsInfo) -> Bool {
        guard lhs.type.rawValue == rhs.type.rawValue else { return false }
        guard lhs.objToken == rhs.objToken else { return false }
        return true
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(type.rawValue)
        hasher.combine(objToken)
    }
}

// MARK: - Wiki 相关
public extension DocsInfo {
    var isFromWiki: Bool {
        return wikiInfo != nil
    }

    // 以后请使用这个变量，它考虑了 wiki 的场景
    var inherentType: DocsType {
        if let wikiInfo = wikiInfo {
            return wikiInfo.docsType
        } else {
            return type
        }
    }
    // 文档内容相关的token，预加载等场景，文档的真实token
    var token: FileListDefine.ObjToken {
        if let versionInfo = versionInfo {
            return versionInfo.versionToken
        } else if let wikiInfo = wikiInfo {
            return wikiInfo.objToken
        } else {
            return objToken
        }
    }
    
    struct TokenType: OptionSet {
        public let rawValue: Int
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        public static let sync = TokenType(rawValue: 1 << 0)
        public static let version = TokenType(rawValue: 1 << 1)
    }

    func getToken(include type: TokenType = [.sync, .version]) -> FileListDefine.ObjToken {
        if type.contains(.sync), urlType == .sync, UserScopeNoChangeFG.LJW.syncBlockPermissionEnabled {
            return urlToken
        } else if type.contains(.version), versionInfo != nil {
            return versionInfo?.versionToken ?? ""
        } else {
            return wikiInfo?.objToken ?? objToken
        }
    }
    
    func getType(include tokeType: TokenType = [.sync, .version]) -> DocsType {
        if tokeType.contains(.sync), urlType == .sync, UserScopeNoChangeFG.LJW.syncBlockPermissionEnabled {
            return urlType
        } else {
            return wikiInfo?.docsType ?? type
        }
    }
    
    func getMeta(include tokeType: TokenType = [.sync, .version]) -> SpaceMeta {
        if tokeType.contains(.sync), urlType == .sync, UserScopeNoChangeFG.LJW.syncBlockPermissionEnabled {
            return SpaceMeta(objToken: urlToken, objType: urlType)
        } else if tokeType.contains(.version), versionInfo != nil {
            return SpaceMeta(objToken: versionInfo?.versionToken ?? "", objType: wikiInfo?.docsType ?? type)
        } else {
            return SpaceMeta(objToken: wikiInfo?.objToken ?? objToken, objType: wikiInfo?.docsType ?? type)
        }
    }
    
    //MARK: originToken、originType
    //含义：在非同步块独立页场景，返回结果和token一致，代表文档的真实token，例如docX@wiki会返回.docX
    //除离线同步完成由fakeToken转为realToken外，其他时候保持不变
    //在同步块独立页场景，返回.sync
    //用法：用于区分同步块与docX类型
    //假如docX的一个特有功能（指sheet、bitable等文档不具有），同步块也同样需要支持，则需要用inherentType == .docX来判断；
    //假如docX的一个功能，同步块独立页并不需要支持，则需要用originType == .docX来判断；
    //docX和同步块产品一致性很高，大多数情况下是第一种场景
    var originToken: FileListDefine.ObjToken {
        urlType == .sync ? urlToken : token
    }
    
    var originType: DocsType {
        urlType == .sync ? .sync : inherentType
    }
    
    // 文档源token, wiki场景下并不是url中的token
    var sourceToken: FileListDefine.ObjToken {
        if let wikiInfo = wikiInfo {
            return wikiInfo.objToken
        } else {
            return objToken
        }
    }

    var isDoc: Bool {
        if let wikiInfo = wikiInfo {
            return wikiInfo.docsType == .doc
        } else {
            return type == .doc
        }
    }

    var isSheet: Bool {
        if let wikiInfo = wikiInfo {
            return wikiInfo.docsType == .sheet
        } else {
            return type == .sheet
        }
    }
}

// MARK: - 评论 相关
public extension DocsInfo {
    /// 评论是否是CCM文档模块内
    var isInCCMDocs: Bool {
        if appId != nil {
            return false
        }
        return true
    }
}

extension DocsInfo {
    public func checkIsSetManualOffline() -> Bool {
        guard let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self) else {
            return false
        }
        let manuOfflineObjTokens = dataCenterAPI.manualOfflineTokens
        var objToken = token
        if let wikiInfo {
            // space列表中Wiki文档的objToken是wikiToken, 不是实体的objToken
            objToken = wikiInfo.wikiToken
        }
        return manuOfflineObjTokens.first(where: { $0.token == objToken }) != nil
    }
}

extension DocsInfo {
    /// 在界面上显示的 name，目前用于详情页更多弹框新UI
    public var name: String {
        guard let title, !title.isEmpty else {
            return type.untitledString
        }
        return title
    }
}

extension DocsInfo {
    public var fileEntry: SpaceEntry {
        return SpaceEntryFactory.createEntryBy(docsInfo: self)
    }

    /// 用于更多菜单内的收藏、pin 操作和icon展示，目前是为了保证对 wiki 执行操作时，能够获取到 wiki 的 token 进行操作
    public var actualFileEntry: SpaceEntry {
        return SpaceEntryFactory.createActualFileEntryBy(docsInfo: self)
    }

    public func getActualFileEntry(completion: @escaping (SpaceEntry) -> Void) {
        SpaceEntryFactory.asyncCreateActualFileEntry(with: self, completion: completion)
    }

    // 当前用户与Owner是否同租户
    public var isSameTenantWithOwner: Bool {
        return self.tenantID == User.current.info?.tenantID
    }
    
    public func isSameTenantWithOwner(for token: String = "") -> Bool {
        if token.isEmpty || token == self.token {
            return self.isSameTenantWithOwner
        } else {
            return syncBlocksConfig.getTenantId(for: token) == User.current.info?.tenantID
        }
    }
}

// 多任务相关参数
extension DocsInfo {
    // 获取相关URL,  originUrl: 兼容表单分享 share/base 进入多任务
    public func urlForSuspendable(originUrl: URL? = nil) -> String {
        if DomainConfig.isNewDomain, let url = shareUrl, var components = URLComponents(string: url) {
            components.query = nil // 移除所有参数
            if let finalUrl = components.string {
                if isVersion, let versionInfo, let vurl = URL(string: finalUrl) { // 版本需要增加参数
                    return vurl.docs.addQuery(parameters: ["edition_id": versionInfo.version]).absoluteString
                }
                return finalUrl
            }
        }
        return DocsUrlUtil.url(type: type, token: objToken, originUrl: originUrl).absoluteString
    }

    // 获取相关Icon
    public var iconForSuspendable: UIImage? {
        let typeForIcon: DocsType
        if isFromWiki || type == .wiki {
            typeForIcon = inherentType
        } else {
            typeForIcon = originType
        }
        if typeForIcon == .file {
            let ext = SKFilePath.getFileExtension(from: name ?? "")
            let fileType = DriveFileType(fileExtension: ext)
            return fileType.roundImage
            ?? UDIcon.getIconByKey(.fileRoundUnknowColorful, size: CGSize(width: 48, height: 48))
        } else {
            return typeForIcon.iconForSuspendable
        }
    }

    public var iconTypeForTabContainable: UDIconType {
        let typeForIcon: DocsType
        if isFromWiki || type == .wiki {
            typeForIcon = inherentType
        } else {
            typeForIcon = originType
        }
        if typeForIcon == .file {
            let ext = SKFilePath.getFileExtension(from: name ?? "")
            let fileType = DriveFileType(fileExtension: ext)
            return fileType.squareColorfulImageKey ?? .fileUnknowColorful
        } else {
            return typeForIcon.squareColorfulIconKey
        }
    }
}

extension DocsInfo {
    /// 文档字体是否支持跟随Lark的设置 动态缩放
    public var fontZoomable: Bool {
        if UserScopeNoChangeFG.HYF.docFontZoomable {
            return self.inherentType == .doc || self.inherentType == .docX
        } else {
            return self.inherentType == .doc
        }
    }
    
    /// 文档被删除的 EmptyConfig
    public var emptyConfigForDeleted: UDEmptyConfig {
        if self.isFromWiki {
            return UDEmptyConfig(description: .init(descriptionText: BundleI18n.SKResource.Doc_Wiki_PageRemovedText),
                                 imageSize: 100,
                                 type: .loadingFailure)
        }
        let description = (type == .file || type == .mediaFile) ?
                BundleI18n.SKResource.Drive_Drive_FileDeleted : BundleI18n.SKResource.CreationMobile_ECM_DocsDeletedDesc
        return UDEmptyConfig(description: .init(descriptionText: description),
                             imageSize: 100,
                             type: .noContent)
    }

    /// 文档密钥被删除的 EmptyConfig
    public var emptyConfigForKeyDeleted: UDEmptyConfig {
        let config = UDEmptyConfig(description: .init(descriptionText: BundleI18n.SKResource.CreationDoc_Docs_KeyInvalidCanNotRead),
                             imageSize: 100,
                             type: .ccmDocumentKeyUnavailable)
        return config
    }
}

extension DocsInfo {
    /// 获取Block对应的租户ID （没找到则用宿主文档租户ID）
    /// - Parameter srcObjToken: Block源文档token
    public func getBlockTenantId(srcObjToken: String) -> String? {
        if let tid = self.syncBlocksConfig.getTenantId(for: srcObjToken) {
            return tid
        }
        return self.tenantID
    }
}

public struct MindnoteInfo {
    /// 是否是思维导图模式
    public var isMindMapType: Bool
    public init(isMindMapType: Bool) {
        self.isMindMapType = isMindMapType
    }
}

public struct WikiInfo: Hashable {
    public let wikiToken: String
    public let objToken: String
    public let docsType: DocsType
    public var spaceId: String
    public let shareUrl: String? // 会在预加载时保存供前端使用，仅在 space 预加载才有值
    public var sortId: Double?
    public struct WikiNodeState: Hashable, Codable {
        public var canStar: Bool = true
        public var canDelete: Bool = false
        public var showDelete: Bool = false
        public var showSingleDelete: Bool = false
        public var canCopy: Bool = false
        public var canMove: Bool = false
        public var isLocked: Bool = false
        public var canShortcut: Bool = false
        public var isStar: Bool = false
        public var isExplorerStar: Bool = false
        public var isExplorerPin: Bool = false
        public var isShortcut: Bool = false
        public var hasChild: Bool = false
        public var parentIsRoot: Bool = false
        public var nodeMovePermission: Bool = false
        public var parentMovePermission: Bool = false
        public var shortcutWikiToken: String?
        public var shortcutSpaceID: String?
        public var parentWikiToken: String?
        public var originIsExternal: Bool = false
        public var showMove: Bool = false
        public var url: String?
    }
    public var wikiNodeState = WikiNodeState()

    public init(wikiToken: String,
                objToken: String,
                docsType: DocsType,
                spaceId: String,
                shareUrl: String? = nil) {
        self.wikiToken = wikiToken
        self.objToken = objToken
        self.docsType = docsType
        self.spaceId = spaceId
        self.shareUrl = shareUrl
    }

    public var dictValue: [String: Any] {
        return ["code": 0,
                "message": "",
                "data": ["wiki_token": wikiToken,
                         "obj_token": objToken,
                         "obj_type": docsType.rawValue,
                         "space_id": spaceId,
                         "url": shareUrl]
        ]
    }

    public var wikiMeta: WikiMeta {
        WikiMeta(wikiToken: wikiToken, spaceID: spaceId)
    }
}

public struct VersionInfo {
    public let objToken: String         // 源文档token
    public let versionToken: String     // 版本token
    public let version: String          // 版本
    public var name: String?            // 名字
    public var create_time: UInt64?
    public var update_time: UInt64?
    private var creator_name: String?
    private var creator_name_en: String?
    private var aliasInfo: UserAliasInfo?
    
    public init(objToken: String,
                versionToken: String,
                version: String,
                name: String?,
                create_time: UInt64?,
                update_time: UInt64?,
                creator_name: String?,
                creator_name_en: String?,
                aliasInfo: UserAliasInfo? = nil
                ) {
        self.objToken = objToken
        self.versionToken = versionToken
        self.version = version
        self.name = name
        self.create_time = create_time
        self.update_time = update_time
        self.creator_name = creator_name
        self.creator_name_en = creator_name_en
        self.aliasInfo = aliasInfo
    }
    
    /// 根据语言设置显示的名字
    public var localizedCreateName: String {
        if let displayName = aliasInfo?.currentLanguageDisplayName {
            return displayName
        }
        switch DocsSDK.currentLanguage {
        case .zh_CN, .zh_HK, .zh_TW:
            return creator_name ?? ""
        default:
            return creator_name_en ?? ""
        }
    }
}

public struct FreshInfo: Codable {
    public var freshStatus: FreshStatus
    public let updateTime: TimeInterval?
    public let operatorId: String?
    /// 配置的过期时间，"已是最新"状态会用到
    public var deadlineTime: TimeInterval?
    /// 当前文档反馈过期的人数
    public let feedbackNum: Int?
    /// 后端配置"可能过期"状态的阈值
    public let mayExpireNum: Int?

    private enum CodingKeys: String, CodingKey {
        case freshStatus = "fresh_status"
        case updateTime = "update_time"
        case operatorId = "operator_id"
        case deadlineTime = "deadline_time"
        case feedbackNum = "feed_back_num"
        case mayExpireNum = "may_expire_show_num"
    }

    public init?(data: [String: Any]) {
        guard
            let data = try? JSONSerialization.data(withJSONObject: data, options: []),
            let freshInfo = try? JSONDecoder().decode(FreshInfo.self, from: data) else {
            DocsLogger.warning("init freshInfo fail")
            return nil
        }
        self = freshInfo
    }

    /// 是否真的"可能过期"了，结合反馈人数判断
    public func isActuallMaybeOutdated() -> Bool {
        guard let feedbackNum = feedbackNum, let mayExpireNum = mayExpireNum else {
            return freshStatus == .maybeOutdated
        }
        return freshStatus == .maybeOutdated && feedbackNum >= mayExpireNum
    }

    /// 是否展示新鲜度标签
    public func shouldShowFreshStatusLabel(isInTopBar: Bool = false) -> Bool {
        switch freshStatus {
        case .maybeOutdated:
            return isActuallMaybeOutdated()
        case .outdated, .newest:
            return true
        case .undecide:
            // more 面板顶部位置不显示"未设置"标签
            return !isInTopBar
        }
    }
}

/// 文档新鲜度
public enum FreshStatus: Int, Codable, CaseIterable {
    /// 未设置
    case undecide = 0
    /// 可能过期
    case maybeOutdated = 1
    /// 已过期
    case outdated = 2
    /// 已是最新
    case newest = 3

    var name: String {
        switch self {
        case .undecide:
            return BundleI18n.SKResource.LarkCCM_CM_Verify_NotSet_Radio
        case .maybeOutdated:
            return BundleI18n.SKResource.LarkCCM_CM_Verify_MayBeOutdate_Radio
        case .outdated:
            return BundleI18n.SKResource.LarkCCM_CM_Verify_Outdated_Radio
        case .newest:
            return BundleI18n.SKResource.LarkCCM_CM_Verify_UpToDate_Radio
        }
    }
    var icon: UIImage? {
        switch self {
        case .undecide:
            return nil
        case .maybeOutdated:
            return UDIcon.warningColorful
        case .outdated:
            return UDIcon.noFilled.ud.withTintColor(UDColor.iconN3)
        case .newest:
            return UDIcon.verifyFilled.ud.withTintColor(UDColor.functionSuccess500)
        }
    }
    /// 当前状态是否需要展示"反馈文档过期"选项
    var shouldShowFeedbackEntry: Bool {
        switch self {
        case .maybeOutdated, .undecide:
            return true
        case .outdated, .newest:
            return false
        }
    }
    /// 点击More面板"文档时效性"选项的埋点信息
    var statisticValue: String {
        switch self {
        case .undecide:
            return "docs_timeliness_no_setting"
        case .maybeOutdated:
            return "docs_timeliness_maybe_overdue"
        case .outdated:
            return "docs_timeliness_overdue"
        case .newest:
            return "docs_timeliness_newest"
        }
    }
    /// 点击设置时效性时动作埋点信息
    var statisticValueForClickAction: String {
        switch self {
        case .undecide:
            return "cancel_mark"
        case .maybeOutdated:
            return "maybeOutdated"
        case .outdated:
            return "mark_overdue"
        case .newest:
            return "newest"
        }
    }
    /// 取消设置状态时的文案
    var cancelStatusInfo: String {
        switch self {
        case .undecide, .outdated, .newest:
            return BundleI18n.SKResource.LarkCCM_CM_Verify_CancelStatus_Description(self.name)
        case .maybeOutdated:
            return BundleI18n.SKResource.LarkCCM_CM_Verify_UpToDate_Confirm_Description
        }
    }
}

public struct SyncBlocksConfig {
    
    private var blocksInfo: ThreadSafeDataStructure.SafeDictionary<String, BlockInfo> = [:] + .semaphore
    
    public func updateInfo(_ token: String, _ type: Int, _ tenantId: String) {
        blocksInfo.updateValue(BlockInfo(type: DocsType(rawValue: type), creatorTenantId: tenantId), forKey: token)
    }
    
    func getTenantId(for token: String) -> String? {
        return blocksInfo[token]?.creatorTenantId
    }
    
}

struct BlockInfo {
    var type: DocsType
    var creatorTenantId: String
}

// 文档打开来源
public enum OpenDocsFrom: String {
    case docsfeed = "docs_feed"
    case baseInstructionDocx = "base_instruction_docx"   // Base 中作为 LinkedBlock 加载
    case other
}

extension DocsInfo {
    /// 新的模板类型
    public enum TemplateType: Int {
        case normal = 0 // 普通文档，非模板
        case pgcTemplate = 1 // 系统模板
        case ugcTemplate = 2 // 自定义模板
        case egcTemplate = 3 // 企业模板

        public var isTemplate: Bool {
            return self != .normal
        }
    }
}

// MARK: - comment
extension DocsInfo: CommentDocsInfo {
    /// 当前评论的用户唯一ID，在Docs中即是当前登录的用户ID，小程序为openId
    var commentUserId: String? {
        var userId = commentUser?.id
        if userId == nil {
            userId = User.current.info?.userID
        }
        return userId
    }
}
