//
//  DocsType.swift
//  SpaceKit
//
//  Created by xurunkang on 2019/1/25.
//  swiftlint:disable file_length
import Foundation
import RustPB
import SKFoundation
import SKResource
import LarkReleaseConfig
import UniverseDesignIcon
import SpaceInterface

public typealias PBDocsType = RustPB.Basic_V1_Doc.TypeEnum

extension DocsType {
    public var isUnknownType: Bool {
        if case .unknown = self {
            return true
        }
        return false
    }

    public var isSupportedType: Bool {
        return DocsType.allSupportTypes.contains(self)
    }

    /// 是否支持离线创建
    public var isSupportOfflineCreate: Bool {
        var supportOfflineCreateTypes: [DocsType] = [.doc, .sheet, .mindnote, .docX]
        return supportOfflineCreateTypes.contains(self)
    }

    /// 是否支持同步状态展示
    public var isSupportSyncStatus: Bool {
        let supportOfflineCreateTypes: [DocsType] = [.doc, .docX, .sheet, .mindnote, .wiki]
        return supportOfflineCreateTypes.contains(self)
    }

    public static var allSupportTypes: [DocsType] {
        let types: [DocsType] =  [.folder, .trash, .doc, .docX, .wiki, .sheet, .myFolder, .bitable, .mindnote, .file, .slides, .wikiCatalog, .sync, .baseAdd]
        return types
    }

    /// 是否支持多窗口
    public var isSupportNewScene: Bool {
        [.doc, .sheet, .wiki, .slides, .mindnote, .file, .bitable, .docX].contains(self)
    }

    @available(*, deprecated, message: "Use enabledByFeatureGating instead")
    /// 是否在 API->SpaceEntry 时屏蔽数据
    public var isBlockedType: Bool {
        return DocsType.isNeedBlockType(type: self)
    }

    @available(*, deprecated, message: "Use DocsType.enableDocTypeDependOnFeatureGating(type:) instead")
    public static func isNeedBlockType(type: DocsType) -> Bool {
        switch type {
        case .bitable: return !type.enabledByFeatureGating // 只在 SaaS 下 GA，私有化部署看 FG
        case .mindnote: return !mindnoteEnabled
        case .file: return false
        case .slides: return false
        case .wiki: return false
        default: return false
        }
    }

    public var enabledByFeatureGating: Bool {
        return Self.enableDocTypeDependOnFeatureGating(type: self)
    }

    /// 根据FeatureGating判断文档类型是否可用
    /// 已有的isNeedBlockType只列举了几种，并且默认是可以使用的，应该默认不能用才对;
    /// 还有，不能加 default 这个方法
    /// 为了保证旧功能不受影响，新功能没有问题，并且以后新增类型强制写FG判断，新写此方法
    /// by --litao
    /// - Parameter type: 文档类型
    /// - Returns: 是否可用
    public static func enableDocTypeDependOnFeatureGating(type: DocsType) -> Bool {
        switch type {
        case .bitable: return ReleaseConfig.isPrivateKA ? LKFeatureGating.bitableEnable : true // 只在 SaaS 下 GA，私有化部署看 FG
        case .baseAdd: return ReleaseConfig.isPrivateKA ? LKFeatureGating.bitableEnable : true
        case .mindnote: return mindnoteEnabled
        case .slides: return UserScopeNoChangeFG.LJW.slidesEnabled
        case .file, .mediaFile, .imMsgFile: return true
        case .doc, .docX, .folder, .trash, .sheet, .myFolder: return true
        case .sync: return UserScopeNoChangeFG.LJW.syncBlockSeparatePageEnabled
        case .wiki: return true
        case .wikiCatalog: return false
        case .unknown, .minutes, .whiteboard: return false // 屏蔽未知类型
        }
    }

    public init?(url: URL) {
        // 判断是否是合法 URL
        guard URLValidator.isDocsURL(url) else { return nil }
        if let type = DocsUrlUtil.getFileType(from: url) {
            self = type
        } else {
            return nil
        }
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.rawValue)
    }

    /// 允许使用离线JS文件的类型
    public static let typesCanUseLocalResources: Set<DocsType> = [.doc, .sheet, .mindnote, .slides, .wiki, .docX, .bitable, .baseAdd, .sync]
}

// 对外接口
extension DocsType {

    public var path: String {
        var str = ""
        switch self {
        case .folder:
            str = "/folder/"
        case .trash:
            str = "/trash/"
        case .doc:
            str = "/doc/"
        case .sheet:
            str = "/sheet/"
        case .bitable:
            str = "/bitable/"
        case .mindnote:
            str = "/mindnote/"
        case .file:
            str = "/file/"
        case .slides:
            str = "/slides/"
        case .myFolder:
            spaceAssertionFailure()
            str = "/"
        case .wiki:
            str = "/wiki/"
        case .docX:
            str = "/docx/"
        default:
            break
        }
        return str
    }


    public var i18Name: String {
        var str = ""
        switch self {
        // Docs
        case .doc, .docX: str = BundleI18n.SKResource.Doc_Facade_Document
        // Folder
        case .folder: str = BundleI18n.SKResource.Doc_Facade_Folder
        // Sheet
        case .sheet: str = BundleI18n.SKResource.Doc_Facade_CreateSheet
        // Mindnote
        case .mindnote: str = BundleI18n.SKResource.Doc_Facade_MindNote
        // Drive
        case .file: str = BundleI18n.SKResource.Doc_Facade_UploadFile
        // MediaFile
        case .mediaFile: str = BundleI18n.SKResource.Doc_Facade_UploadMedia
        // Slide
        case .slides: str = BundleI18n.SKResource.LarkCCM_Slides_ProductName
        // Bitable
        case .bitable: str = BundleI18n.SKResource.Doc_Facade_Bitable
        // wiki
        case .wiki: str = BundleI18n.SKResource.Doc_Facade_Wiki
        // Unsupported
        default:
            break
        }
        return str
    }

    public var isOpenByWebview: Bool {
        return [.doc, .sheet, .bitable, .mindnote, .slides, .wiki, .docX, .sync].contains(self)
    }

    static let htmlCacheKey = "doc_cached_html"
    public var htmlCachedKey: String? {
        guard isOpenByWebview else { return nil }
        return DocsType.htmlCacheKey
    }

    public var offLineEnable: Bool { [.doc, .sheet, .mindnote, .file, .folder, .wiki, .docX].contains(self) }
    
    /// 判断wiki对应的单品是否支持用wiki打开，如果不支持跳转到不支持兜底界面
    public var isSupportedWikiType: Bool {
        var supportedType: [DocsType] = [.doc, .docX, .sheet, .file]

        if LKFeatureGating.mindnoteEnable {
            supportedType.append(.mindnote)
        }

        if LKFeatureGating.bitableEnable {
            supportedType.append(.bitable)
        }
        
        if UserScopeNoChangeFG.LJW.slidesEnabled {
            supportedType.append(.slides)
        }
        return supportedType.contains(self)
    }

    private var supportOrentationTypes: [DocsType] {
        var types: [DocsType] = [.sheet, .bitable, .slides]
        if LKFeatureGating.enableScreenViewHorizental { types.append(.docX) }
        if UserScopeNoChangeFG.GXY.mindnoteSupportScreenViewHorizental { types.append(.mindnote) }
        return types
    }

    public var landscapeWhenEnteringVCFollow: Bool { supportOrentationTypes.contains(self) }
    public var landscapeHideNavBarEnteringVCFollow: Bool { self == .sheet || self == .bitable }
    
    // 文档打开过程中，支持的转屏方向可以改变（如：前端给到的支持方向）
    public var changeOrientationsEnable: Bool { supportOrentationTypes.contains(self) || self == .doc || self == .docX }

    public var supportCommentWhenLandscape: Bool { 
        [.docX].contains(self) && LKFeatureGating.enableScreenViewHorizental || 
        [.mindnote].contains(self) && UserScopeNoChangeFG.GXY.mindnoteSupportScreenViewHorizental || 
        self == .slides 
    }

    // 评论支持横屏fg，后期删除，需要两个fg都删除，切记、切记、切记不能只删除一个
    public static var commentSupportLandscapaeFg: Bool {
        LKFeatureGating.enableScreenViewHorizental || UserScopeNoChangeFG.GXY.mindnoteSupportScreenViewHorizental
    }
    // 统计上报、2、3级面板适配了横屏
    public var supportLandscapeShow: Bool { [.docX, .mindnote, .slides].contains(self) }
    public var alwaysOrientationsEnable: Bool { supportOrentationTypes.contains(self) }

    public var editMenuInteractionEnable: Bool { [.docX, .doc, .mindnote, .sheet].contains(self) }
    
    public var needCheckRestoreFromDeleted: Bool {
        switch self {
        case .sync: 
            //同步块的删除不可通过删除页面的恢复按钮恢复
            return false
        default: 
            return true
        }
    }

    public func clientVarKey(_ user: User = User.current) -> String {
        switch self {
        case .doc: return (user.info?.cacheKeyPrefix ?? "") + "CLIENT_VARS"
        case .sheet: return (user.info?.cacheKeyPrefix ?? "") + "SHEET_CLIENT_VARS"
        case .mindnote: return (user.info?.cacheKeyPrefix ?? "") + "MINDNOTE_CLIENT_VARS"
        case .slides: return (user.info?.cacheKeyPrefix ?? "") + "SLIDE_CLIENT_VARS"
        case .docX: return (user.info?.cacheKeyPrefix ?? "") + "CLIENT_VARS"
        case .bitable: return (user.info?.cacheKeyPrefix ?? "") + "BITABLE_CLIENT_VARS"
        case .wiki:
            spaceAssertionFailure("should not get/set wikiInfo by clientvar key @peipei, use wikiInfoKey")
            return ""
        default:
            spaceAssertionFailure("not supported type")
            return ""
        }
    }

    public var wikiInfoKey: String {
        guard self == .wiki else {
            spaceAssertionFailure("should not get wikiInfoKey by other type")
            return ""
        }
        return (User.current.info?.cacheKeyPrefix ?? "") + "WIKI_INFO"
    }
}

extension DocsType {
    
    public init(pbDocsType: PBDocsType) {
        switch pbDocsType {
        case .unknown:
            self = .unknownDefaultType
        case .doc:
            self = .doc
        case .sheet:
            self = .sheet
        case .bitable:
            self = .bitable
        case .mindnote:
            self = .mindnote
        case .file:
            self = .file
        case .slides:
            self = .slides
        case .slide: // 基本不会再走这里，直接当作slides
            self = .slides
        case .docx:
            self = .docX
        case .wiki:
            self = .wiki
        case .folder:
            self = .folder
        case .catalog:
            self = .wikiCatalog
        case .shortcut:
            self = .spaceShortcut
        case .docxSyncedBlock:
            self = .sync  
        default: // https://bytedance.feishu.cn/wiki/H6Qhwt4fTiXqGskS9rHcoDe6nsb
            self = .unknownDefaultType
        }
    }

    public init?(pbDocsTypeRawValue: Int) {
        guard let pbDocsType = PBDocsType(rawValue: pbDocsTypeRawValue) else {
            return nil
        }
        self.init(pbDocsType: pbDocsType)
    }
}

extension DocsType {
    public var fileTypeForSta: String {
        var fileType = ""

        switch self {
        case .doc:
            fileType = "doc"
        case .sheet:
            fileType = "sheet"
        case .slides:
            fileType = "slides"
        case .bitable:
            fileType = "bitable"
        case .mindnote:
            fileType = "mindnote"
        case .file:
            fileType = "file"
        case .folder:
            fileType = "folder"
        case .wiki:
            fileType = "wiki"
        case .docX:
            fileType = "docx"
        case .sync:
            fileType = "sync"
        default:
            ()
        }
        return fileType
    }
}

extension DocsType {
    /// 根据配置中心，动态下发的产品名称，目前用于 打开文档的url path替换和匹配工作
    /// 比如doc 叫docs, bitable 叫 base
    /// 为了以后能够动态修改，path，此后所有版本都能打开文档
    var productName: String {
        var productName = self.name
        if H5UrlPathConfig.enable { // FG总开关
            productName = H5UrlPathConfig.latestName(of: self)
        }
        return productName
    }
}
