//
//  SKShareEntity.swift
//  SKBrowser
//
//  Created by guoqp on 2021/1/1.
//
//  swiftlint:disable file_length

import Foundation
import SKFoundation
import SKResource
import SKInfra
import LarkDocsIcon
import SpaceInterface

// nolint: magic number
public enum BitableShareSubType: Int, Codable {
    case form = 1
    case view = 2
    case record = 3
    case dashboard_redirect = 4
    case dashboard = 5
    case addRecord = 6
    
    public var trackString: String {
        switch self {
        case .form:
            return "form"
        case .view:
            return "view"
        case .record:
            return "record"
        case .dashboard_redirect:
            return "dashboard_previous"
        case .dashboard:
            return "dashboard"
        case .addRecord:
            return "add_record"
        }
    }
}
// enable-lint: magic number

// nolint: magic number
private struct ShareDocsTypeRawValue {
    static let form: Int = 81
    static let view: Int = 82
    static let record: Int = 83
    static let dashboard_redirect: Int = 84
    static let dashboard: Int = 85
    static let addRecord: Int = 86
}
// enable-lint: magic number

// 为了摆脱对Space的DocsType依赖，重新定义一套适用于分享/权限的文档类型
// 分享/权限模块使用文档类型为ShareDocsType，不用DocsType，
// nolint: magic number
public enum ShareDocsType: Equatable, Hashable {
    case folder
    case doc
    case sheet
    case bitable
    case form //表单
    case bitableSub(_ subType: BitableShareSubType)
    case mindnote
    case file
    case slides
    case wiki
    case docX
    case minutes
    case sync
    case wikiCatalog
    case unknown(_ value: Int)
    public static let unknownDefaultType: ShareDocsType = .unknown(999)

    public init(rawValue: Int) {
        switch rawValue {
        case 0: do { self = .folder }
        case 2: do { self = .doc }
        case 3: do { self = .sheet }
        case 8: do { self = .bitable }
        case 80: do { self = .form }
        case ShareDocsTypeRawValue.form: do { self = .bitableSub(.form) }
        case ShareDocsTypeRawValue.view: do { self = .bitableSub(.view) }
        case ShareDocsTypeRawValue.record: do { self = .bitableSub(.record) }
        case ShareDocsTypeRawValue.dashboard_redirect: do { self = .bitableSub(.dashboard_redirect) }
        case ShareDocsTypeRawValue.dashboard: do { self = .bitableSub(.dashboard) }
        case ShareDocsTypeRawValue.addRecord: do { self = .bitableSub(.addRecord) }
        case 11: do { self = .mindnote }
        case 12: do { self = .file }
        case 30: do { self = .slides }
        case 16: do { self = .wiki }
        case 22: do { self = .docX }
        case 28: do { self = .minutes }
        case 44: do { self = .sync }
        case 111: do { self = .wikiCatalog }
        default: do { self = .unknown(rawValue) }
        }
    }
    
    public var rawValue: Int {
        switch self {
        case .folder:        return 0
        case .doc:           return 2
        case .sheet:         return 3
        case .bitable:       return 8
        case .form:       return 80
        case .bitableSub(let subType):
            switch subType {
            case .form: return 81
            case .view: return 82
            case .record: return 83
            case .dashboard_redirect: return 84
            case .dashboard: return 85
            case .addRecord: return 86
            }
        case .mindnote:      return 11
        case .file:          return 12
        case .slides:         return 30
        case .wiki:          return 16
        case .docX:          return 22
        case .minutes:       return 28
        case .sync:         return 44
        case .wikiCatalog:   return 111
        case .unknown(let v):   return v
        }
    }

    /// 针对Bitable子分享类型的临时修复rawValue，使用前务必理解上下文，预计 5.33 版本完整方案删除，详见 https://bytedance.feishu.cn/docx/CIvEdFrRNoMCDdxbHDkcgSnjnIb
    public var fixedRawValueForBitableSubType: Int {
        if case .bitableSub(let _) = self {
            // bitableSub 的 rawValue 应当是 ShareDocsType.form 相同的(80)
            return ShareDocsType.form.rawValue
        }
        return self.rawValue
    }
    
    public var fixedBitableSubType: Int? {
        switch self {
        case .form:
            // 旧的表单分享没有 BitableShareSubType，但是需要将这个类型传递到 lynx（和安卓逻辑保持一致）
            return BitableShareSubType.form.rawValue
        case .bitableSub(let subType):
            return subType.rawValue
        default:
            return nil
        }
    }

    //meta path for some type
    public var path: String {
        var str = ""
        switch self {
        case .folder:
            str = "/folder/"
        case .sheet:
            str = "/sheet/"
        case .bitable:
            str = "/bitable/"
        default:
            break
        }
        return str
    }

    public var name: String {
        var str = ""
        switch self {
        case .folder:
            str = "folder"
        case .doc:
            str = "doc"
        case .sheet:
            str = "sheet"
        case .bitable, .bitableSub:
            str = "bitable"
        case .form:
            str = "bitable"
        case .mindnote:
            str = "mindnote"
        case .file:
            str = "file"
        case .slides:
            str = "slides"
        case .wiki, .wikiCatalog:
            str = "wiki"
        case .docX:
            str = "docx"
        case .minutes:
            str = "minutes"
        case .sync:
            str = "sync"
        default:
            str = "unknow"
        }
        return str
    }

    public var i18Name: String {
        var str = ""
        switch self {
        case .doc, .docX: str = BundleI18n.SKResource.Doc_Facade_Document
        case .folder: str = BundleI18n.SKResource.Doc_Facade_Folder
        case .sheet: str = BundleI18n.SKResource.Doc_Facade_CreateSheet
        case .mindnote: str = BundleI18n.SKResource.Doc_Facade_MindNote
        case .file: str = BundleI18n.SKResource.Doc_Facade_UploadFile
        case .slides: str = BundleI18n.SKResource.LarkCCM_Slides_ProductName
        case .bitable, .bitableSub: str = BundleI18n.SKResource.Doc_Facade_Bitable
        case .wiki, .wikiCatalog: str = BundleI18n.SKResource.Doc_Facade_Wiki
        default:
            str = BundleI18n.SKResource.Doc_Facade_Document
        }
        return str
    }
    static private var bizTypes: [ShareDocsType] = [.doc, .sheet, .bitable, .form, .wiki,
                                                    .file, .mindnote, .slides, .docX, .minutes, .sync, .wikiCatalog]
    public var isBizDoc: Bool {
        if case .bitableSub = self {
            return true
        }
        return ShareDocsType.bizTypes.contains(self)
    }
    
    /// 是否为 Bitable 子类分享类型（表单V2、仪表盘等）
    public var isBitableSubType: Bool {
        switch self {
        case .bitableSub: return true
        default: return false
        }
    }
}

/// 分享流程中的 callback（可能会传递给第三方，回调时分享 vc 实际可能已经销毁，无法通过 vc.delegate 实现）
public protocol SKShareHandlerProvider: AnyObject {
    /// 分享到飞书会话的结果回调
    var shareToLarkHandler: ShareToLarkService.ContentType.TextShareCallback? { get }
}

public extension SKShareHandlerProvider {
    var shareToLarkHandler: ShareToLarkService.ContentType.TextShareCallback? { nil }
}

// 表单相关的回调合并到这里，避免 SKShareEntity 无须扩张
public final class FormsCallbackBlocks {
    
    public var noticeMeClick: ((Bool) -> Void)?
    
    //表单有附件字段
    public var formHasAttachmentField: (() -> Bool) = { false }

    //表单有用户字段
    public var formHasUserField: (() -> Bool) = { false }
    public var formHasLinkField: (() -> Bool) = { false }
    
    //表单分享成功后的Toast提示
    public var formShareSuccessTip: (() -> String?) = { nil }

    //表单埋点上报
    public var formEventTracing: () -> Void = {}
    
}

// enable-lint: magic number

public final class SKShareEntity {
    public private(set) var objToken: String
    public private(set) var type: ShareDocsType
    public private(set) var isOwner: Bool
    public private(set) var displayName: String //owner name
    public private(set) var ownerID: String
    public private(set) var tenantID: String
    public private(set) var title: String
    public private(set) var shareUrl: String
    public private(set) var formShareFormMeta: FormShareMeta?
    public private(set) var bitableShareEntity: BitableShareEntity?
    public var formsShareModel: FormsShareModel?
    public var isOldForm = false
    public private(set) var scPasteImmunity: Bool
    
    public var bitableAdPermInfo: BitableBridgeData?
    
    public var formsCallbackBlocks = FormsCallbackBlocks()
    
    /// 分享发起者可以实现一些事件监听，这些回调可能在分享过程读取后传递给第三方，回调时不依赖 shareVC 的生命周期
    public weak var shareHandlerProvider: SKShareHandlerProvider?
    ///允许密码分享
    public var enableShareWithPassWord: Bool
    ///允许转移owner
    public var enableTransferOwner: Bool
    ///分享面板仅展示底部 分享渠道 这一列,目前仅模板一键分享用到
    public var onlyShowSocialShareComponent: Bool

    public private(set) var createTime: TimeInterval
    public private(set) var createDate: String
    public private(set) var creatorID: String

    public private(set) var shareFolderInfo: FolderEntry.ShareFolderInfo?
    public private(set) var shareVersion: Int?
    public private(set) var folderType: FolderType?

    public var isFromWiki: Bool {
        self.wikiInfo != nil
    }
    public private(set) var fileType: String

    public private(set) var encryptedObjToken: String

    public private(set) var defaultIcon: UIImage?
    public var wikiV2SingleContainer: Bool = false //是否是wiki2.0
    public var spaceSingleContainer: Bool = false // 是否是单容器版本

    public let wikiInfo: WikiInfo?
    
    public let versionInfo: VersionInfo?
    public let isFromPhoenix: Bool

    public var isFolder: Bool {
        folderType != nil
    }

    public var isv2Folder: Bool {
        return isFolder && spaceSingleContainer
    }

    public var spaceID: String {
        guard let id = shareFolderInfo?.spaceID else {
            return ""
        }
        return id
    }

    public var isShareFolderRoot: Bool {
        return shareFolderInfo?.shareRoot ?? false
    }

    public var isShareFolder: Bool {
        if let folderType = folderType,
           folderType.isShareFolder {
            return true
        }
        return false
    }

    public var isOldShareFolder: Bool {
        if let folderType = folderType,
           folderType.isOldShareFolder {
            return true
        }
        return false
    }
    public var isCommonFolder: Bool {
        if let folderType = folderType,
           !folderType.isShareFolder {
            return true
        }
        return false
    }

    public var isSameTenantWithOwner: Bool {
        return self.tenantID == User.current.info?.tenantID
    }
    
    public var isVersion: Bool {
        return self.versionInfo != nil
    }
    
    public init(objToken: String,
                type: Int,
                title: String = "",
                isOwner: Bool = false,
                ownerID: String = "",
                displayName: String = "",
                shareFolderInfo: FolderEntry.ShareFolderInfo? = nil,
                shareVersion: Int? = nil,
                folderType: FolderType? = nil,
                tenantID: String = "",
                createTime: TimeInterval = 0,
                createDate: String = "",
                creatorID: String = "",
                wikiInfo: WikiInfo? = nil,
                isFromPhoenix: Bool = false,
                shareUrl: String = "",
                fileType: String = "",
                defaultIcon: UIImage? = nil,
                wikiV2SingleContainer: Bool = false,
                spaceSingleContainer: Bool = false,
                enableShareWithPassWord: Bool = true,
                enableTransferOwner: Bool = true,
                onlyShowSocialShareComponent: Bool = false,
                formShareMeta: FormShareMeta? = nil,
                versionInfo: VersionInfo? = nil,
                scPasteImmunity: Bool = false,
                bitableShareEntity: BitableShareEntity? = nil
    ) {
        self.objToken = objToken
        self.type = ShareDocsType(rawValue: type)
        self.title = title
        self.isOwner = isOwner
        self.displayName = displayName
        self.ownerID = ownerID
        self.tenantID = tenantID
        self.createTime = createTime
        self.createDate = createDate
        self.creatorID = creatorID
        self.folderType = folderType
        self.shareUrl = shareUrl
        self.defaultIcon = defaultIcon
        self.fileType = fileType
        self.shareFolderInfo = shareFolderInfo
        self.shareVersion = shareVersion
        self.encryptedObjToken = DocsTracker.encrypt(id: objToken)
        self.wikiV2SingleContainer = wikiV2SingleContainer
        self.spaceSingleContainer = spaceSingleContainer
        self.wikiInfo = wikiInfo
        self.isFromPhoenix = isFromPhoenix
        self.enableTransferOwner = enableTransferOwner
        self.enableShareWithPassWord = enableShareWithPassWord
        self.onlyShowSocialShareComponent = onlyShowSocialShareComponent
        self.formShareFormMeta = formShareMeta
        self.versionInfo = versionInfo
        self.scPasteImmunity = scPasteImmunity
        self.bitableShareEntity = bitableShareEntity
        if self.type == .form {
            spaceAssert(formShareMeta != nil, "formShareFormMeta must not nil while type is form")
        }
        if case .bitableSub = self.type {
            spaceAssert(bitableShareEntity != nil, "bitableShareEntity must not be nil while type is bitableSub")
        }
    }

    public func updateFormMeta(formMeta: FormShareMeta) {
        let initialHost = formShareFormMeta?.shareHost
        self.formShareFormMeta = formMeta
        formShareFormMeta?.updateShareHost(initialHost)
        updateFormShareURl()
    }
    
    public func updateBitableShareMeta(_ meta: BitableShareMeta) {
        bitableShareEntity?.updateMeta(meta)
        if let url = bitableShareEntity?.shareUrl {
            shareUrl = url
        }
    }

    public func updateFormShareURl() {
        guard UserScopeNoChangeFG.ZYS.disableBarHiddenInPermView else {
            if let meta = formShareFormMeta, let url = meta.shareUrl {
                shareUrl = url
            }
            return
        }
        if let formMeta = self.formShareFormMeta, !formMeta.shareToken.isEmpty {
            shareUrl = "https://" + DomainConfig.userDomain + "/share/base/" + formMeta.shareToken
        }
    }

    public func updateOwnerID(newOwnerID: String) {
        self.ownerID = newOwnerID
    }

    public func updateIsOwner(isOwner: Bool) {
        self.isOwner = isOwner
    }

    public func updateByMeta(meta: ShareBizMeta) {
        if let url = meta.url, !url.isEmpty {
            self.shareUrl = url
        }
        if let title = meta.title, !title.isEmpty {
            self.title = title
        }
        if let ownerID = meta.ownerID, !ownerID.isEmpty {
            self.ownerID = ownerID
            self.isOwner = ownerID == User.current.info?.tenantID
        }
        if let ownerUserName = meta.ownerUserName, !ownerUserName.isEmpty {
            self.displayName = ownerUserName
        }
        if let tenantId = meta.tenantId, !tenantId.isEmpty {
            self.tenantID = tenantId
        }
    }
    
    public func updateShareURL(url: String) {
        self.shareUrl = url
    }

    /// 将一个DocsInfo转成SKShareEntry, 慎用 (优先使用SKShareEntity init 函数直接构造)
    public static func transformFrom(info docsInfo: DocsInfo) -> SKShareEntity {
        let wikiV2SingleContainer = docsInfo.isFromWiki
        let spaceSingleContainer = (docsInfo.ownerType == 5)
        let entry = SKShareEntity(objToken: docsInfo.objToken,
                                  type: docsInfo.type.rawValue,
                                  title: docsInfo.title ?? "",
                                  isOwner: docsInfo.isOwner,
                                  ownerID: docsInfo.ownerID ?? "",
                                  displayName: docsInfo.displayName,
                                  shareFolderInfo: docsInfo.shareFolderInfo,
                                  shareVersion: docsInfo.shareVersion,
                                  folderType: docsInfo.folderType,
                                  tenantID: docsInfo.tenantID ?? "",
                                  createTime: docsInfo.createTime ?? 0,
                                  createDate: docsInfo.createDate ?? "",
                                  creatorID: docsInfo.creatorID ?? "",
                                  wikiInfo: docsInfo.wikiInfo,
                                  isFromPhoenix: docsInfo.isFromPhoenix,
                                  shareUrl: docsInfo.shareUrl ?? "",
                                  fileType: docsInfo.fileType ?? "",
                                  defaultIcon: docsInfo.defaultIcon,
                                  wikiV2SingleContainer: wikiV2SingleContainer,
                                  spaceSingleContainer: spaceSingleContainer,
                                  enableShareWithPassWord: true,
                                  enableTransferOwner: true,
                                  versionInfo: docsInfo.versionInfo,
                                  scPasteImmunity: true)
        // 需要异步更新一下 tenantID
        if let ownerID = docsInfo.ownerID, docsInfo.tenantID == nil {
            if let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self) {
                dataCenterAPI.userInfoFor(ownerID, callBack: { docsInfo in
                    entry.tenantID = docsInfo?.tenantID ?? ""
                })
            }
        }
        return entry
    }
}

extension SKShareEntity {
    public var isForm: Bool {
        isFormV1 || isFormV2
    }

    public var isFormV1: Bool {
        type == .form
    }

    /// 是否为 Bitable 通用分享类型的表单分享
    public var isFormV2: Bool {
        type == .bitableSub(.form)
    }

    public var isSyncedBlock: Bool {
        type == .sync
    }

    public var isBitableSubShare: Bool {
        type.isBitableSubType
    }

    /// 是否为 Bitable 仪表盘分享
    public var isBitableDashboradShare: Bool {
        switch type {
        case .bitableSub(.dashboard), .bitableSub(.dashboard_redirect):
            return true
        default:
            return false
        }
    }

    /// 如果是 Bitable 子类分享，返回子类类型；否则返回空
    public var bitableSubType: BitableShareSubType? {
        if case .bitableSub(let subType) = type {
            return subType
        }
        return nil
    }

    public var formCanShare: Bool {
        return formShareFormMeta?.canShare ?? false
    }

    public var shareToken: String? {
        switch type {
        case .form:
            return formShareFormMeta?.shareToken
        case .bitableSub:
            return bitableShareEntity?.meta?.shareToken
        default:
            DocsLogger.warning("shareToken is nil")
            return nil
        }
    }

    public var shareType: Int? {
        switch type {
        case .form:
            return formShareFormMeta?.shareType
        case .bitableSub:
            return bitableShareEntity?.meta?.shareType.rawValue
        default:
            DocsLogger.warning("shareType is nil")
            return nil
        }
    }

    public var bitableConstraintExternal: Bool {
        return bitableShareEntity?.meta?.constraintExternal ?? false
    }
}

extension SKShareEntity {
    /// 获取分享到微信小程序展示图片
    public func shareToMiniProgramImage() -> UIImage {
        let shareImageType = getShareImageType()
        return shareImageType.image
    }
    
    private func getShareImageType() -> ShareImageType {
        let result: ShareImageType
        if type == .file {
            var fileExtension = fileType
            if fileExtension.isEmpty {
                fileExtension = SKFilePath.getFileExtension(from: title) ?? ""
            }
            let driveFileType = DriveFileType(fileExtension: fileExtension)
            result = driveFileType.shareImageType
        } else {
            result = type.shareImageType
        }
        return result
    }
}

private enum ShareImageType {
    case doc
    case excel
    case image
    case mindnote
    case pdf
    case ppt
    case sheet
    case text
    case video
    case word
    case zip
    case unknow
    
    var image: UIImage {
        switch self {
        case .doc:
            return BundleResources.SKResource.Common.Share.icon_file_doc_illustration
        case .excel:
            return BundleResources.SKResource.Common.Share.icon_file_excel_illustration
        case .image:
            return BundleResources.SKResource.Common.Share.icon_file_image_illustration
        case .mindnote:
            return BundleResources.SKResource.Common.Share.icon_file_mindnote_illustration
        case .pdf:
            return BundleResources.SKResource.Common.Share.icon_file_pdf_illustration
        case .ppt:
            return BundleResources.SKResource.Common.Share.icon_file_ppt_illustration
        case .sheet:
            return BundleResources.SKResource.Common.Share.icon_file_sheet_illustration
        case .text:
            return BundleResources.SKResource.Common.Share.icon_file_text_illustration
        case .video:
            return BundleResources.SKResource.Common.Share.icon_file_video_illustration
        case .word:
            return BundleResources.SKResource.Common.Share.icon_file_word_illustration
        case .zip:
            return BundleResources.SKResource.Common.Share.icon_file_zip_illustration
        case .unknow:
            return BundleResources.SKResource.Common.Share.icon_file_unknow_illustration
        }
    }
}

private extension ShareDocsType {
    
    var shareImageType: ShareImageType {
        switch self {
        case .doc, .docX:
            return .doc
        case .sheet:
            return .sheet
        case .mindnote:
            return .mindnote
        case .slides, .bitable, .form, .bitableSub, .folder, .minutes, .file, .wiki, .sync, .wikiCatalog, .unknown:
            return .unknow
        }
    }
}

private extension DriveFileType {
    
    var shareImageType: ShareImageType {
        switch self {
        case .pdf:
            return .pdf
        case .csv:
            return .excel
        case _ where self.isExcel:
            return .excel
        case _ where self.isKeynote:
            return .ppt
        case _ where self.isPPT:
            return .ppt
        case _ where self.isCode, .log, .md:
            return .text
        case _ where self.isText:
            return .text
        case _ where self.isWord:
            return .word
        case _ where self.isArchive:
            return .zip
        case _ where self.isImage:
            return .image
        case _ where self.isVideo:
            return .video
        default:
            return .unknow
        }
    }
}

public final class ShareFeatureGating {
    public static func newPermissionSettingEnable(type: Int) -> Bool {
        let shareType = ShareDocsType(rawValue: type)
        switch shareType {
        case .form, .bitableSub, .folder, .unknown:
            return false
        default:
            return true
        }
    }
}
