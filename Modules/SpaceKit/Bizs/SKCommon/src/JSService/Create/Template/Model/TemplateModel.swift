//
//  TemplateModel.swift
//  SKCommon
//
//  Created by 邱沛 on 2020/9/16.
//
// swiftlint:disable file_length

import SKFoundation
import SKResource
import SpaceInterface
import SKInfra

public enum TemplateMainType: Int {
    case gallery = 0
    case custom
    case business
    
    func toPageType() -> TemplateCenterTracker.PageType {
        switch self {
        case .gallery: return .systemCenter
        case .custom: return .userCenter
        case .business: return .businessCenter
        }
    }
}
public extension TemplateMainType {
    init?(string: String) {
        switch string {
        case "gallery": self = .gallery
        case "custom": self = .custom
        case "corporate": self = .business
        default: return nil
        }
    }
}

// 单个类别的所有的模板
public struct TemplateCategory: Codable {
    var name: String
    var categoryId: Int?
    var templates: [TemplateModel]
    enum CodingKeys: String, CodingKey {
        case name
        case templates
        case categoryId = "category_id"
    }
    /// 由于历史实现和过渡阶段，有的ID没法完全动态下发，先写死在端上
    public enum SpecialCategoryId: Int {
        case mine = 5
        case sharedWithMe = 6
        case newYear = 1104  // 2021年新年活动模板
    }
}

public struct GalleryTemplateCategoriesInfo: Codable {
    var cateMetas: [TemplateCategoryMeta]? // 分类数组
    var tmplMetaDict: [String: TemplateModel]? // 模板id：模板详细信息
    var cateIdToTmplIds: [String: [String]]? // 分类id：模板id数组
    var recommendTmplIds: [String]? // 推荐模板id数组
    enum CodingKeys: String, CodingKey {
        case cateMetas = "category_metas"
        case tmplMetaDict = "template_metas"
        case cateIdToTmplIds = "template_list"
        case recommendTmplIds = "recommend_list"
    }
}

public struct TemplateCategoryMeta: Codable {
    var name: String
    var categoryId: String
    enum CodingKeys: String, CodingKey {
        case name
        case categoryId = "category_id"
    }
}

// 单个模板的结构
public final class TemplateModel: Codable, Equatable {
    public static func == (lhs: TemplateModel, rhs: TemplateModel) -> Bool {
        return lhs.objType == rhs.objType && lhs.objToken == rhs.objToken && lhs.id == rhs.id && lhs.name == rhs.name
    }
    
    /// 自定义模版下的分组标记
    public enum Tag: Int {
        /// 我的模版
        case customOwn = 5
        /// 与我共享模版
        case customShare = 6
    }
    
    public enum Source: Int, Codable {
        case createBlankDocs = -2 // 新建空白文档
        case emptyData = -1 // 空数据
        case system = 1 // 系统模版
        case custom = 2 // 自定义模版
        case business = 3 // 企业模版
        
        func trackValue() -> String? {
            switch self {
            case .system: return "pgc"
            case .custom: return "ugc"
            case .business: return "egc"
            default: return nil
            }
        }
    }
    
    enum Style: Equatable {
        case normal
        case emptyData                 // 过滤后无模板显示的样式
        case createBlankDocs            // 新建空白文档
    }

    public struct RenderConfig: Codable {
        let shouldShowTopBorder: Bool
        let topBorderColor: String

        enum CodingKeys: String, CodingKey {
            case shouldShowTopBorder = "show_top_border"
            case topBorderColor = "top_border_color"
        }

        static let `default` = RenderConfig(shouldShowTopBorder: false, topBorderColor: "")
    }

    struct ThumbnailInfo: Codable {
        let type: Int // 加密类型
        let thumbnailUrl: String // 加密缩略图url,优先使用
        let decryptKey: String // 解密密钥

        enum CodingKeys: String, CodingKey {
            case type
            case thumbnailUrl = "thumbnail"
            case decryptKey = "decrypt_key"
        }

        static let `default` = ThumbnailInfo(type: 0, thumbnailUrl: "", decryptKey: "")

        var isAvailable: Bool {
            return !thumbnailUrl.isEmpty && !decryptKey.isEmpty
        }
    }

    enum BottomLabelType {
        case systemRecommend(Int)           // 1   系统推荐的模板，显示有多少人用过
        case createAt(Double)               // 2   创建于
        case shared(String)                 // 3   其他人分享给我的，含企业模板
        case useAt(Double)                  // 4   xx月xx日使用过
        case updateAt(Double)               // 5   修改于
        case hidden                        //隐藏副标题
    }
    
    enum BottomLabelTypeValue: Int {
        case systemRecommend = 1
        case createTime = 2
        case shared = 3
        case useAt = 4
        case updateAt = 5
        case hidden = 10001 //隐藏副标题，非server返回值
    }

    
    enum DisplayType: Int {
        case themeCover = 1 // PM、运营在后台配置的主题模板封面
        case thumbnail = 2  // 模板内容缩略图
        case manuSettedThumbnail = 3 // PM认为2类型显示出来的样子不符合预期时，在后台手动设置给某个模板的封面图，非加密；目前只有系统模板列表才有
    }
    
    public enum TemplateType: Int, Codable {
        case normal = 1// 普通单模版
        case collection = 2 // 场景化模版，多个相关模版的合辑
        case ecology = 4 // 生态模板
    }
    
    struct Extra: Codable {
        let colletionId: String?
        enum CodingKeys: String, CodingKey {
            case colletionId = "collection_id"
        }
    }
    
    enum EffectiveStatus: Int, Codable {
        case normal = 0// 正常
        case cipherDeleted = 1// 密钥删除
    }
    
    // 权限点位
    enum PermissionPoint: Int {
        case normal = 1// 权限点位1，功能正常
        case limited = 2// 权限点位2，只能展示标题，不允许展示缩略图、预览、使用
        case noPerceiveAndPreview = 3 // 不可见 & 不能预览。 后端基本不会返回
    }

    // require
    public let id: String
    let name: String
    public let objToken: String
    let objType: Int

    // option
    private(set) var source: Source?
    private(set) var coverHeight: Double?
    private(set) var coverToken: String?
    private(set) var renderConfig: RenderConfig?
    private(set) var showTimeType: Int?    // create:1  update:2  share:3
    private(set) var shareTime: Double?
    private(set) var createTime: Double?
    private(set) var updateTime: Double?
    private(set) var lastUsedTime: Double?
    private(set) var operationalLabelUrl: String? // 运营标签，就是展示在左上角的那个icon
    private(set) var heat: Int? // 使用热度，usecount
    private(set) var displayType: Int? // 1:封面图；2:缩略图；3: 后台特殊处理的缩略图，非加密
    private(set) var thumbnailExtra: ThumbnailInfo? // 缩略图url加密信息
    private(set) var description: String?
    private(set) var coverDownloadUrl: String?
    //底部展示类型；1:官方模版：使用量；2我的模版:创建时间；3与我共享&企业模版:分享人；5修改于:修改时间
    var bottomLabelType: Int?
    private(set) var fromUserId: String? // 有谁分享的
    private(set) var boxColorShadow: String? // 模板阴影颜色
    private(set) var author: String?
    private(set) var opLabelUrlV2: String? // 运营标签V2
    private(set) var type: TemplateType?
    private(set) var extra: Extra?
    private(set) var effectiveStatus: EffectiveStatus?
    private(set) var actionPreviewAndPerceive: Int?
    private(set) var icon: String?
    
    /// 用于区分在自定义模版下面的分组
    public var tag: Tag?
    
    var sharerInfo: TemplateSharer?
    var titleParam: CreateDocTitleParams?

    var bottomLabelShowType: BottomLabelType {
        let sysType: BottomLabelType = .systemRecommend(heat ?? 0)
        guard let type = bottomLabelType else {
//            spaceAssertionFailure("使用了新样式，需要后台给出底部标签怎么展示")
            return sysType
        }
        switch type {
        case BottomLabelTypeValue.systemRecommend.rawValue:
            return sysType
        case BottomLabelTypeValue.createTime.rawValue:
            return .createAt(createTime ?? 0)
        case BottomLabelTypeValue.shared.rawValue:
            if let sharerInfo = sharerInfo {
                return .shared(sharerInfo.displayName)
            }
            return .shared("")
        case BottomLabelTypeValue.useAt.rawValue:
            return .useAt(lastUsedTime ?? 0)
        case BottomLabelTypeValue.updateAt.rawValue:
            return .updateAt(updateTime ?? 0)
        case BottomLabelTypeValue.hidden.rawValue:
            return .hidden
        default: return sysType
        }
    }

    enum CodingKeys: String, CodingKey {
        case coverHeight = "cover_height"
        case coverToken = "cover_token"
        case createTime = "create_time"
        case id
        case type = "template_type"
        case name
        case objToken = "obj_token"
        case objType = "obj_type"
        case renderConfig = "render_config"
        case updateTime = "update_time"
        case lastUsedTime = "last_used_time"
        case source
        case shareTime = "share_time"
        case showTimeType = "show_time_type"
        case operationalLabelUrl = "operational_label_url"
        case heat
        case displayType = "display_type"
        case thumbnailExtra = "thumbnail_extra"
        case description
        case coverDownloadUrl = "cover_download_url"
        case bottomLabelType = "bottom_label_type"
        case fromUserId = "from_user_id"
        case boxColorShadow = "box_color_shadow"
        case author
        case opLabelUrlV2 = "op_label_url_v2"
        case extra
        case effectiveStatus = "effective_status"
        case actionPreviewAndPerceive = "action_preview_and_perceive"
        case icon = "icon"
    }

    lazy var secretKey: String? = {
        let dict = CCMKeyValue.globalUserDefault.dictionary(forKey: encryptThumbnailKey)
        let secretKey = dict?["secretKey"] as? String
        DocsLogger.debug("👀get secretKey: \(objToken) - \(secretKey ?? "")")
        return secretKey
    }()

    lazy var secretCoverUrl: String? = {
        let dict = CCMKeyValue.globalUserDefault.dictionary(forKey: encryptThumbnailKey)
        let secretCoverUrl = dict?["secretCoverUrl"] as? String
        DocsLogger.debug("👀get secretCoverUrl: \(objToken) - \(secretCoverUrl ?? "")")
        return secretCoverUrl
    }()

    var isThemeAvailable: Bool {
        if let type = DisplayType(rawValue: displayType ?? 0),
           type == .themeCover {
            return true
        }
        return false
    }
    
    var imageDisplayType: DisplayType {
        guard let displayType = displayType,
              let type = DisplayType(rawValue: displayType) else {
            return .thumbnail
        }
        return type
    }
    
    var displayTitle: String {
        var finalName: String = name
        if let effectiveStatus = effectiveStatus {
            switch effectiveStatus {
            case .normal: finalName = name
            case .cipherDeleted: finalName = BundleI18n.SKResource.CreationDoc_Template_KeyInvalid
            }
        }
        if finalName.isEmpty {
            switch docsType {
            case .doc, .docX: finalName = BundleI18n.SKResource.Doc_Facade_UntitledDocument
            case .sheet: finalName = BundleI18n.SKResource.Doc_Facade_UntitledSheet
            case .bitable: finalName = BundleI18n.SKResource.Doc_Facade_UntitledBitable
            case .mindnote: finalName = BundleI18n.SKResource.Doc_Facade_UntitledMindnote
            default:
                break
            }
        }
        return finalName
    }
    
    public var usedCount: Int? {
        return heat
    }
    
    public var templateSource: String?

    public init(createTime: Double,
         id: String,
         name: String,
         objToken: String,
         objType: Int,
         updateTime: Double,
         source: Source,
         coverHeight: Double? = nil,
         coverToken: String? = nil,
         renderConfig: RenderConfig? = nil,
         noFilterView: UIView? = nil) {
        self.createTime = createTime
        self.id = id
        self.name = name
        self.objToken = objToken
        self.objType = objType
        self.updateTime = updateTime
        self.source = source

        self.coverHeight = coverHeight
        self.coverToken = coverToken
        self.renderConfig = renderConfig
        self.type = .normal
    }
    
    func toExternalItem() -> TemplateItem {
        let item = TemplateItem(id: self.id,
                                name: self.name,
                                objToken: self.objToken,
                                objType: self.objType)
        return item
    }

    public func shouldUseNewForm() -> Bool {
        guard let source = self.templateSource else{
            return false
        }
        return source == TemplateCenterTracker.TemplateSource.lark_survey.rawValue || source == TemplateCenterTracker.TemplateSource.baseHomepageLarkSurvey.rawValue || source == TemplateCenterTracker.TemplateSource.spaceHomepageLarkSurvey.rawValue || source == TemplateCenterTracker.TemplateSource.wikiHomepageLarkSurvey.rawValue
    }

    public func newFormEnumberType() -> TemplateCenterTracker.TemplateSource? {
        guard let source = self.templateSource else{
            return nil
        }
        if source == TemplateCenterTracker.TemplateSource.lark_survey.rawValue {
            return TemplateCenterTracker.TemplateSource.init(enterSource: source, source: .larkSurvey)
        }else if source == TemplateCenterTracker.TemplateSource.baseHomepageLarkSurvey.rawValue {
            return TemplateCenterTracker.TemplateSource.init(enterSource: source, source: .baseHomepageLarkSurvey)
        }else if source == TemplateCenterTracker.TemplateSource.spaceHomepageLarkSurvey.rawValue {
            return TemplateCenterTracker.TemplateSource.init(enterSource: source, source: .spaceHomepageLarkSurvey)
        }else{
            return nil
        }
    }
}

extension TemplateModel {
    /// ForStatistics
    public var templateMainType: TemplateMainType {
        switch source {
        case .system: return .gallery
        case .custom: return .custom
        case .business: return .business
        default:
            assertionFailure("新增了类型，要新增定义，统计埋点也要check一下")
            return .custom // 这样会把templatObjToken加密
        }
    }
}
extension TemplateModel {
    // calculate property
    var docsType: DocsType {
        DocsType(rawValue: objType)
    }

    var style: Style {
        if source == .emptyData {
            return .emptyData
        } else if source == .createBlankDocs {
            return .createBlankDocs
        }
        return .normal
    }

    var coverUrl: String {
        let context = NetConfig.shared.sessionFor(.default, trafficType: .default)
        let host = context.host
        return host + OpenAPI.APIPath.driveOriginalFileDownload + (coverToken ?? "")
    }

    var shouldShowTime: Bool {
        showTimeType != nil
    }

    var showTime: Double {
        if let type = showTimeType {
            switch type {
            case 1:
                return createTime ?? 0
            case 2:
                return updateTime ?? 0
            case 3:
                return shareTime ?? 0
            default:
                spaceAssertionFailure("template showtime undefine type")
                return 0
            }
        } else {
            spaceAssertionFailure("should not use show time")
            return 0
        }
    }

    var hasShowThumbnailPermission: Bool {
        if let actionPreviewAndPerceive = actionPreviewAndPerceive,
           let point = PermissionPoint(rawValue: actionPreviewAndPerceive) {
            return point == .normal
        }
        return true
    }
    
    // custom thumnail, use by custom templates and business templates
    var useEncryptThumbnail: Bool {
        source == .custom || source == .business
    }

    var encryptThumbnailKey: String {
        "com.bytedance.docs.template-\(objType)-\(objToken)"
    }

    static var emptyData: TemplateModel {
        return TemplateModel(
            createTime: 0, id: "", name: "", objToken: "",
            objType: 0, updateTime: 0, source: .emptyData
        )
    }
}

enum TemplateError: Error {
    case parseDataError   // 数据解析失败，需要验证下后端返回的数据格式
    case getCacheError    // 取缓存失败，一般UI上不处理，可以忽略
    case customNoData     // 自定义模板还没有数据，需要有占位图
    case businessNoData   // 企业模板还没有数据，需要有占位图
    case filterTypeNoData // 过滤某一文档类型后无数据
    case themeNoData      // 主题模板列表为空
}

public struct TemplateSharer: Codable {
    let avatarUrl: String
    let enName: String
    let id: String
    let name: String
    let aliasInfo: UserAliasInfo?
    /// 国际化别名
    var displayName: String {
        if let displayName = aliasInfo?.currentLanguageDisplayName {
            return displayName
        } else {
            return enName
        }
    }

    enum Codingkeys: String, CodingKey {
        case avatarUrl = "avatar_url"
        case enName = "en_name"
        case id
        case name
        case aliasInfo = "display_name"
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: Codingkeys.self)
        self.avatarUrl = try values.decode(String.self, forKey: Codingkeys.avatarUrl)
        self.enName = try values.decode(String.self, forKey: Codingkeys.enName)
        self.id = try values.decode(String.self, forKey: Codingkeys.id)
        self.name = try values.decode(String.self, forKey: Codingkeys.name)
        self.aliasInfo = try? values.decodeIfPresent(UserAliasInfo.self, forKey: Codingkeys.aliasInfo)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Codingkeys.self)
        try container.encode(avatarUrl, forKey: Codingkeys.avatarUrl)
        try container.encode(enName, forKey: Codingkeys.enName)
        try container.encode(id, forKey: Codingkeys.id)
        try container.encode(name, forKey: Codingkeys.name)
        try container.encode(aliasInfo, forKey: Codingkeys.aliasInfo)
    }
}

struct TemplateSearchResult {
    var keyword: String
    var templates: [TemplateModel]
    var hasMore: Bool
    var buffer: String
    
    static func createEmptyResult() -> TemplateSearchResult {
        return TemplateSearchResult(
            keyword: "",
            templates: [],
            hasMore: false,
            buffer: ""
        )
    }
}

public struct TemplateSearchRecommend: Codable {
    enum Codingkeys: String, CodingKey {
        case name
    }
    let name: String
}

public struct TemplateBanner: Codable {
    enum CodingKeys: String, CodingKey {
        case bannerType = "banner_type"
        case imageUrl = "image_url"
        case imageToken = "image_token"
        case topicId = "topic_id"
        case templateId = "template_id"
        case objType = "obj_type"
        case objToken = "obj_token"
        case objTypeList = "obj_type_list"
        case jumpLinkUrl = "jump_link_url"
        case bannerId = "banner_id"
        case collectionId = "collection_id"
    }
    enum BannerType: Int {
        case singleTemplate = 1
        case topicTemplates = 2
        // 这种类型是，用户点击之后，把url抛给lark层面，让lark去router，运营需求
        case jumpLinkUrl = 3
        case templateCollectionList = 4
        case templateCollectionPreview = 5
    }
    let bannerType: Int // 1:模版；2:专题页面
    var imageUrl: String?
    let imageToken: String
    let topicId: Int
    let templateId: Int
    let objType: Int
    let objToken: String
    let objTypeList: [Int]?
    var jumpLinkUrl: String? // BannerType == .jumpLinkUrl 时才会有值
    var bannerId: Int? // 这个字段是后来新版加的，老的banner数据还在线上跑着，所以只能写成可选的，含义更加准确些
    var collectionId: String?
}
public struct TemplateThemeResult: Codable {
    enum Codingkeys: String, CodingKey {
        case banner
        case templates
    }
    let templateBanner: TemplateBanner?
    let templates: [TemplateModel]
}

extension TemplatePreviewBody {
    
    func toTemplateModel() -> TemplateModel {
        return TemplateModel(createTime: 0,
                             id: "",
                             name: "",
                             objToken: self.objToken,
                             objType: self.objType,
                             updateTime: 0,
                             source: .business)
    }
}
