//
//  Recommend.swift
//  SpaceKit
//
//  Created by nine on 2018/3/14.
//

import Foundation
import SwiftyJSON
import RxRelay
import SKUIKit
import SKResource
import SKFoundation
import SpaceInterface

/// 推荐的内容是什么。用户/doc/sheet/。。。
public enum RecommendType: Int {
    case user = 0
    case doc = 1
    case folder = 2
    case sheet = 3
    case chat = 5
    case group = 6
    case bitable = 8
    case mindnote = 11
    case file = 12
    case slides = 30
    case wiki = 16
    case docx = 22

    var typeStr: String {
        switch self {
        case .user:
            return "users"
        case .doc, .sheet, .bitable, .mindnote, .file, .slides, .wiki, .docx:
            return "notes"
        case .group:
            return "groups"
        case .chat:
            return "chats"
        case .folder:
            spaceAssertionFailure("folder not in use")
            return "folder"
        }
    }
}

public final class RecommendData {
    private var id: String?
    private var avatarUrl: String?
    public private(set) var content: String?
    private var desc: String?
    public private(set) var token: String
    private var owner: String?
    private(set) var type: RecommendType
    public private(set) var url: String?
    private(set) var editTime: TimeInterval?
    private(set) var department: String?
    public var userCnName: String?
    public var userEnName: String?
    public var aliasInfo: UserAliasInfo?
    // 国际化后的别名
    public var displayName: String {
        if let displayName = aliasInfo?.currentLanguageDisplayName {
            return displayName
        } else {
            return realName ?? ""
        }
    }
    public var name: String?
    public private(set) var isExternal: Bool = false
    public private(set) var isCrossTenant: Bool = false
    private(set) var notNotify: Bool = false
    private var rawDictionary: [String: Any] = [String: Any]()
    private var source: Int? // 来源，后台返回的。即为啥会出现在这里。可能是来自最近搜索/最近@过
    public private(set) var hasJoinChat: Bool = false //如果是用户，是否不在当前群聊里
    public var requestSource: AtDataSource.RequestSource?
    private(set) var iconInfo: IconInfo?
    private var imageDownloader: AvatarImageView?
    private(set) var subType: RecommendType? // wiki类型下具体的类型，用来区分是wikidoc/wikisheet
    private var tenantId: Int?
    private(set) var unionId: String?
    public var displayTag: DisplayTagSimpleInfo? // 显示关联标签
    public var iconInfoMeta: String? //自定义icon显示数据

    public final class IconInfo: MentionIconInfo {
        public let type: SpaceEntry.IconType
        public let key: String
        public let fsunit: String
        public var image: BehaviorRelay<UIImage?> = BehaviorRelay<UIImage?>(value: nil)
        private var imageDownloader: AvatarImageView?
        public init(type: SpaceEntry.IconType, key: String, fsunit: String) {
            self.type = type
            self.key = key
            self.fsunit = fsunit
            if Thread.isMainThread {
                downloadImage()
            } else {
                DispatchQueue.main.async {
                    self.downloadImage()
                }
            }
        }
        public var typeValue: Int {
            return type.rawValue
        }
        
        public var typeIsCurSupported: Bool {
            return type.isCurSupported
        }

        public func downloadImage(placeholder: UIImage? = nil, image: UIImage? = nil) {
            self.imageDownloader = AvatarImageView()
            imageDownloader?.set(avatarKey: key,
                                 fsUnit: fsunit,
                                 placeholder: nil,
                                 image: nil,
                                 completion: { [weak self] result in
                                    self?.image.accept(try? result.get().image)
                                    self?.imageDownloader = nil
            })
        }
    }

    /// 搜索时输入的关键字
    private(set) var keyword: String
    
    public var avatarKey: String?

    public init(withToken token: String, keyword: String, type: RecommendType, infos: JSON) {
        self.token = token
        self.keyword = keyword
        self.type = type
        self.desc = infos["desc"].string
        self.owner = infos["owner"].string
        self.editTime = infos["edit_time"].double
        self.department = infos["department"].string
        self.userCnName = infos["cn_name"].string
        self.userEnName = infos["en_name"].string
        self.aliasInfo = UserAliasInfo(json: infos["display_name"])
        self.isExternal = infos["is_external"].boolValue
        self.isCrossTenant = infos["is_cross_tenant"].boolValue
        self.source = infos["source"].int
        self.content = infos["title"].string ?? infos["name"].string
        self.avatarUrl = infos["avatar_url"].string ?? ""
        self.url = infos["url"].string ?? infos["avatar_url"].string
        self.hasJoinChat = infos["has_join_chat"].boolValue
        self.id = infos["id"].string ?? ""
        self.notNotify = infos["not_notify"].bool ?? false
        self.tenantId = infos["tenant_id"].int
        self.iconInfoMeta = infos["icon_info"].string
        if let subType = infos["sub_type"].int {
            self.subType = RecommendType(rawValue: subType)
        }
        if let iconTypeValue = infos["icon_type"].int,
            let iconType = SpaceEntry.IconType(rawValue: iconTypeValue),
            let iconKey = infos["icon_key"].string,
            let iconFsunit = infos["icon_fsunit"].string {
            self.iconInfo = IconInfo(type: iconType, key: iconKey, fsunit: iconFsunit)
        }
        self.unionId = infos["union_id"].string
        
        if let tagJson = infos["display_tag"] as? JSON {
            self.displayTag = DisplayTagSimpleInfo(json: tagJson)
        }
        
        self.name = infos["name"].string
        if UserScopeNoChangeFG.WJS.bitableFieldGroupNewEditPanel {
            self.avatarKey = infos["rust_avatar_key"].string
        }
    }

    private var localizedName: String? {
        displayName
    }
}

// MARK: - recommendData -> AtInfo
extension RecommendData {

    /// 正文暂不支持别名，因此这里还要继续提供真名的写入方法，等正文支持真名后，可下掉下方代码
    private var realName: String? {
        if (Locale.preferredLanguages.first ?? Locale.current.identifier).hasPrefix("zh") {
            return userCnName
        } else {
            return userEnName?.isEmpty == false ? userEnName : userCnName
        }
    }

    /// 正文暂不支持别名，因此这里还要继续提供真名的写入方法，等正文支持真名后，可下掉下方代码
    var contentToShowForRealName: String {
        if type == .user, let realName { return realName }
        if let content, !content.isEmpty { return content }
        switch type {
        case .doc: return BundleI18n.SKResource.Doc_Facade_UntitledDocument
        case .sheet: return BundleI18n.SKResource.Doc_Facade_UntitledSheet
        case .bitable: return BundleI18n.SKResource.Doc_Facade_UntitledBitable
        case .mindnote: return BundleI18n.SKResource.Doc_Facade_UntitledMindnote
        case .slides: return BundleI18n.SKResource.LarkCCM_Slides_Untitled
        case .wiki: return BundleI18n.SKResource.Doc_Wiki_UntitledPage
        case .docx: return BundleI18n.SKResource.Doc_Facade_UntitledDocument
        default:
            spaceAssertionFailure("not supported"); return ""
        }
    }

    var derivedAtInfo: AtInfo? {
        guard let atUrl = url else { return nil }
        let atType = AtType(rawValue: type.rawValue) ?? .unknown
        //正文暂不支持别名，这里写入文档时还是要用真名，等正文支持别名后，这里可以改为使用 contentToShow
        let atInfo = AtInfo(type: atType, href: atUrl, token: token, at: contentToShowForRealName)
        if source != nil {
            atInfo.recommendReason = AtInfo.RecommendReason(rawValue: source!)
        }
        atInfo.keyword = keyword
        atInfo.enName = userEnName
        atInfo.name = userCnName
        atInfo.iconInfo = iconInfo
        atInfo.isExternal = isExternal
        atInfo.id = id

        atInfo.department = department
        atInfo.avatarUrl = avatarUrl
        atInfo.unionId = unionId
        atInfo.name = name
        if let typeValue = subType?.rawValue {
            atInfo.subType = AtType(rawValue: typeValue)
        }
        atInfo.iconInfoMeta = iconInfoMeta
        return atInfo
    }

    var contentToShow: String {
        if type == .user, localizedName != nil { return localizedName! }
        if content != nil, content!.isEmpty == false { return content! }
        switch type {
        case .doc: return BundleI18n.SKResource.Doc_Facade_UntitledDocument
        case .sheet: return BundleI18n.SKResource.Doc_Facade_UntitledSheet
        case .bitable: return BundleI18n.SKResource.Doc_Facade_UntitledBitable
        case .mindnote: return BundleI18n.SKResource.Doc_Facade_UntitledMindnote
        case .slides: return BundleI18n.SKResource.LarkCCM_Slides_Untitled
        case .wiki: return BundleI18n.SKResource.Doc_Wiki_UntitledPage
        case .docx: return BundleI18n.SKResource.Doc_Facade_UntitledDocument
        default:
            spaceAssertionFailure("not supported"); return ""
        }
    }

    /// 文档中输入@时，回调给前端，dict表示
    var dictionaryForJSCallback: [String: Any] {
        var dict = [String: Any]()
        dict["content"]      = contentToShow.toBase64()
        dict["department"]   = department?.toBase64()
        dict["desc"]         = desc?.toBase64()
        dict["token"]        = token
        dict["owner"]        = owner
        dict["type"]         = type.rawValue
        dict["url"]          = url
        dict["edit_time"]    = editTime
        dict["source"]       = source
        dict["name"]         = name
        dict["en_name"]      = userEnName
        dict["cn_name"]      = userCnName
        dict["display_name"] = aliasInfo?.dictionaryRepresentation
        dict["id"]           = id ?? ""
        dict["is_external"]  = isExternal
        dict["avatar_url"]   = avatarUrl
        dict["not_notify"]   = notNotify
        dict["sub_type"]     = subType?.rawValue ?? 0
        if let tenantId = tenantId {
            dict["tenant_id"]   = String(tenantId)
        }
        if let iconInfo = iconInfo {
            dict["icon_key"]     = iconInfo.key
            dict["icon_type"]    = iconInfo.type.rawValue
            dict["icon_fsunit"]  = iconInfo.fsunit
        }
        if  let iconInfoMeta = iconInfoMeta {
            dict["icon_info"] = iconInfoMeta
        }
        return dict
    }
}
