//
//  DocsTracker+common.swift
//  SKCommon
//
//  Created by guoqp on 2021/6/3.
//

import Foundation
import SKFoundation
import SpaceInterface

extension DocsTracker {
    public static func pageViewFor(module: PageModule) -> String {
        switch module {
        case .home:
            return "ccm_space_home_page_view"
        case .personal:
            return "ccm_space_personal_page_view"
        case .shared:
            return "ccm_space_shared_page_view"
        case .favorites:
            return "ccm_space_favorites_page_view"
        case .offline:
            return "ccm_space_offline_page_view"
        case .personalFolderRoot, .sharedFolderRoot, .personalSubFolder, .sharedSubFolder:
            return "ccm_space_folder_view"
        default:
            return "none"
        }
    }
}

public final class SpaceBizParameter {
    public var module: PageModule
    private(set) public var containerID: String?
    private(set) public var containerType: String?
    private(set) public var fileID: String?
    private(set) public var fileType: DocsType?
    private(set) public var driveType: String?
    public var shortcutId: String?
    public var originInWiki: Bool?

    public var ownerID: String?
    public var ownerTenantID: String?

    public var params: [String: String] {
        var dic: [String: String] = [:]
        dic["module"] = module.rawValue
        if let subModule = module.subRawValue {
            dic["sub_module"] = subModule
        } else {
            dic["sub_module"] = "none"
        }
        if let id = fileID {
            dic["file_id"] = DocsTracker.encrypt(id: id)
        } else {
            dic["file_id"] = "none"
        }
        if let type = fileType {
            dic["file_type"] = type.name
        } else {
            dic["file_type"] = "none"
        }
        if let id = containerID {
            dic["container_id"] = DocsTracker.encrypt(id: id)
        } else {
            dic["container_id"] = "none"
        }
        if let type = containerType {
            dic["container_type"] = type
        } else {
            dic["container_type"] = "none"
        }
        if let type = driveType {
            dic["sub_file_type"] = type
        } else {
            dic["sub_file_type"] = "none"
        }
        if let shortcutId = shortcutId {
            dic["shortcut_id"] = DocsTracker.encrypt(id: shortcutId)
            dic["is_shortcut"] = "true"
        } else {
            dic["shortcut_id"] = "none"
            dic["is_shortcut"] = "false"
        }
        if let originInWiki = originInWiki {
            dic["original_location"] = originInWiki ? "wiki" : "space"
            dic["original_docs_container"] = originInWiki ? "wiki" : "space"
        }
        dic["app_form"] = "none"
        if case let .baseHomePage(context) = module {
            dic["container_env"] = context.containerEnv.rawValue
            dic["base_hp_from"] = context.baseHpFrom
            dic["hp_version"] = context.version.rawValue
        }
        if let ownerID {
            dic["owner_id"] = DocsTracker.encrypt(id: ownerID)
        }
        if let ownerTenantID {
            dic["owner_tenant_id"] = DocsTracker.encrypt(id: ownerTenantID)
        }
        return dic
    }
    public init(module: PageModule) {
        self.module = module
    }
    public convenience init(module: PageModule, fileID: String, fileType: DocsType) {
        self.init(module: module)
        self.fileID = fileID
        self.fileType = fileType
    }

    public convenience init(module: PageModule, entry: SpaceEntry) {
        self.init(module: module)
        self.fileID = entry.objToken
        self.fileType = entry.docsType
        if let folder = entry as? FolderEntry {
            self.folderType = folder.folderType
        }
        if let file = entry as? DriveEntry {
            self.driveType = file.fileType ?? "image"
        }
        if entry.isShortCut {
            self.shortcutId = DocsTracker.encrypt(id: entry.nodeToken)
        }
    }

    public convenience init(module: PageModule, entry: SpaceEntry, containerID: String, containerType: DocsType) {
        self.init(module: module, entry: entry)
        self.containerID = containerID
        self.containerType = containerType.name
    }

    public convenience init(module: PageModule, fileID: String, fileType: DocsType, driveType: String) {
        self.init(module: module, fileID: fileID, fileType: fileType)
        self.driveType = driveType
    }
    public convenience init(module: PageModule, fileID: String, fileType: DocsType, driveType: String, containerID: String, containerType: DocsType) {
        self.init(module: module, fileID: fileID, fileType: fileType, driveType: driveType)
        self.containerID = containerID
        self.containerType = containerType.name
    }

    public convenience init(module: PageModule, containerID: String, containerType: DocsType) {
        self.init(module: module)
        self.containerID = containerID
        self.containerType = containerType.name
    }

    public convenience init(module: PageModule, fileID: String, fileType: DocsType, originInWiki: Bool) {
        self.init(module: module, fileID: fileID, fileType: fileType)
        self.originInWiki = originInWiki
    }

    public var folderType: FolderType? //文件夹类型
    var folderLevel: Int = 0
    public var isBlank: Bool = false //是否空白页
    public var isFolder: Bool {
        return folderType != nil
    }
    public var isShareFolder: Bool {
        switch module {
        case .sharedFolderRoot, .sharedSubFolder, .shareFolderV2Root:
            return true
        default:
            return false
        }
    }
    public var isSubFolder: Bool { containerID != nil && isFolder }

    public func update(fileID: String?, fileType: DocsType?, driveType: String? = nil) {
        self.fileID = fileID
        self.fileType = fileType
        self.driveType = driveType
    }
}

///新建view上的点击
public enum CreateNewClickParameter {
    case docs(type: DocsType, toTemplateCenter: Bool)
    case folder
    case imageUpload
    case fileUpload
    case templatesMore
    case templates(template: TemplateModel, fileType: DocsType, fileToken: String)
    case bitableHome
    case baseTemplates
    case baseNew(targetFileToken: String)
    case baseFormNew(targetFileToken: String)
    case baseHomePageNewSurvey
    case spaceHomePageNewSurvey
    case wikiHomePageNewSurvey
    case other

    ///一级参数
    public var clickValue: String {
        switch self {
        case let .docs(type, _):
            switch type {
            case .doc: return "docs"
            case .sheet: return "sheets"
            case .bitable: return "bitable"
            case .mindnote: return "mindnotes"
            case .docX: return "docx"
            default:
                spaceAssertionFailure("未支持的类型")
                return ""
            }
        case .folder: return "folder"
        case .imageUpload: return "image_upload"
        case .fileUpload: return "file_upload"
        case .templatesMore: return "templates_more"
        case .templates: return "templates"
        case .bitableHome: return "creat_new"
        case .baseTemplates: return "templates"
        case .baseNew: return "new_base"
        case .baseFormNew: return "new_form"
        case .baseHomePageNewSurvey : return "new_form_templates"
        case .spaceHomePageNewSurvey : return "new_form_templates"
        case .wikiHomePageNewSurvey : return "new_form_templates"
        case .other: return "other"
        }
    }

    ///二级参数
    public var targetValue: String {
        switch self {
        case let .docs(type: _, toTemplateCenter):
            return toTemplateCenter ? "ccm_template_systemcenter_view" : "ccm_docs_page_view"
        case .folder: return "ccm_space_folder_view"
        case .imageUpload, .fileUpload: return "ccm_space_file_choose_view"
        case .templatesMore: return "ccm_template_systemcenter_view"
        case .templates: return "ccm_template_preview_view"
        case .bitableHome: return "ccm_template_systemcenter_view"
        case .baseTemplates: return "none"
        case .baseNew: return "ccm_bitable_content_page_view"
        case .baseFormNew: return "ccm_bitable_content_page_view"
        case .baseHomePageNewSurvey : return "ccm_template_systemcenter_view"
        case .spaceHomePageNewSurvey : return "ccm_template_systemcenter_view"
        case .wikiHomePageNewSurvey : return "ccm_template_systemcenter_view"
        case .other: return ""
        }
    }

    static func param(for docType: DocsType) -> Self {
        switch docType {
        case .doc, .sheet, .mindnote, .bitable, .docX:
            return .docs(type: docType, toTemplateCenter: false)
        case .folder:
            return .folder
        default:
            return .other
        }
    }

    public static func bizParameter(for folderToken: String, module: PageModule) -> SpaceBizParameter {
        if folderToken.isEmpty {
            return SpaceBizParameter(module: module)
        } else {
            return SpaceBizParameter(module: module, containerID: folderToken, containerType: .folder)
        }
    }
}

extension DocsTracker {
    ///新建view
    static func reportSpaceCreateNewView(bizParms: SpaceBizParameter) {
        DocsTracker.log(enumEvent: .spaceCreateNewView, parameters: bizParms.params)
    }

    ///新建view上的点击
    static func reportSpaceCreateNewClick(enumEvent: EventType = .spaceCreateNewClick, params: CreateNewClickParameter, bizParms: SpaceBizParameter, userNewLog: Bool = false) {
        if case .other = params { return }
        var dic: [String: Any] = ["click": params.clickValue, "target": params.targetValue.isEmpty ? "none" : params.targetValue]
        if case let .templates(template, fileType, fileToken) = params {
            dic["template_token"] = template.objToken
            dic["template_name"] = template.name
            dic["template_type"] = template.source?.trackValue()
            dic["create_file_type"] = fileType.name
            dic["file_id"] = fileToken.encryptToken
            dic[DocsTracker.Params.nonSensitiveToken] = true
        } else if case let .baseNew(targetFileToken) = params {
            dic["target_file_id"] = targetFileToken.encryptToken
        } else if case let .baseFormNew(targetFileToken) = params {
            dic["target_file_id"] = targetFileToken.encryptToken
        }
        dic.merge(other: bizParms.params)
        if userNewLog {
            DocsTracker.newLog(enumEvent: enumEvent, parameters: dic)
        } else {
            DocsTracker.log(enumEvent: enumEvent, parameters: dic)
        }
    }
}

///新建文件夹view上的点击
enum CreateNewFolderClickParameter {
    case cancel(_ isShareFolder: Bool, target: DocsTracker.EventType)
    case create(_ isShareFolder: Bool, target: DocsTracker.EventType)

    ///一级参数
    var clickValue: String {
        switch self {
        case .cancel: return "cancel"
        case .create: return "create"
        }
    }

    static func eventType(for module: PageModule) -> DocsTracker.EventType {
        switch module {
        case .home:
            return .spaceHomePageView
        case .personal:
            return .spacePersonalPageView
        case .shared:
            return .spaceSharedPageView
        case .favorites:
            return .spaceFavoritesPageView
        case .offline:
            return .spaceOfflinePageView
        default:
            return .spaceFolderView
        }
    }
}

extension DocsTracker {
    ///新建文件夹view
    static func reportSpaceCreateNewFolderView(_ isShareFolder: Bool, bizParms: SpaceBizParameter) {
        var dic = ["is_shared_folder": String(isShareFolder)]
        dic.merge(other: bizParms.params)
        DocsTracker.log(enumEvent: .spaceCreateNewFolderView, parameters: dic)
    }
    ///新建文件夹view上的点击
    static func reportSpaceCreateNewFolderClick(params: CreateNewFolderClickParameter, bizParms: SpaceBizParameter) {
        var dic: [String: Any] = ["click": params.clickValue]
        dic.merge(other: bizParms.params)
        switch params {
        case let .cancel(isShareFolder, target):
            dic["is_shared_folder"] = String(isShareFolder)
            dic["target"] = target.rawValue
        case let .create(isShareFolder, target):
            dic["is_shared_folder"] = String(isShareFolder)
            dic["target"] = target.rawValue
        }
        DocsTracker.log(enumEvent: .spaceCreateNewFolderClick, parameters: dic)
    }
}
///选择文件view上的点击
public enum FileChooseClickParameter {
    case confirm(fileType: String)
    case cancel
    ///一级参数
    var clickValue: String {
        switch self {
        case .cancel: return "cancel"
        case .confirm: return "confirm"
        }
    }
}

extension DocsTracker {
    ///选择文件view
    static func reportSpaceFileChooseView(bizParms: SpaceBizParameter) {
        DocsTracker.log(enumEvent: .spaceFileChooseView, parameters: bizParms.params)
    }
    ///选择文件view上的点击
    public static var isSpaceOrWikiUpload = false
    public static func reportSpaceFileChooseClick(params: FileChooseClickParameter, bizParms: SpaceBizParameter, mountPoint: String) {
        var dic: [String: Any] = ["click": params.clickValue,
                                  "add_mode": "click_upload",
                                  "file_num": 1,
                                  "mount_point": mountPoint]
        dic.merge(other: bizParms.params)
        switch params {
        case let .confirm(fileType):
            dic["file_type"] = fileType
        default: break
        }
        dic["target"] = pageViewFor(module: bizParms.module)
        DocsTracker.log(enumEvent: .spaceFileChooseClick, parameters: dic)
    }
}

extension DocsTracker {
//    ///文档详情页里右上角“…”点击后的view
//    static func reportSpaceDocsMoreMenuView(bizParms: SpaceBizParameter, docsInfo: DocsInfo) {
//        let isFollowUpdate = docsInfo.subscribed
//        let isFollowComment = CommentSubScribeCache.getCommentSubScribe(docsInfo)
//        var params = ["is_follow_update": String(isFollowUpdate),
//                      "is_follow_comment": String(isFollowComment)]
//        params.merge(other: bizParms.params)
//        DocsTracker.log(enumEvent: .spaceDocsMoreMenuView, parameters: params)
//    }

    public static func reportDriveDownload(event: DocsTracker.EventType, mountPoint: String, fileToken: String, fileType: String) {
        var params: [String: Any] = ["mount_point": mountPoint, "file_id": encrypt(id: fileToken), "file_type": fileType]
        if event == .driveDownloadBeginClick {
            params["click"] = "download"
            params["target"] = "none"
        }
        DocsTracker.newLog(enumEvent: event, parameters: params)
    }

    public static func reportDriveUploadFinish(mountPoint: String, isSuccess: Bool, fileToken: String, fileName: String) {
        let fileType = SKFilePath.getFileExtension(from: fileName)
        let params: [String: Any] = ["mount_point": mountPoint,
                                     "is_successful": "\(isSuccess)",
                                     "file_num": 1,
                                     "file_id": encrypt(id: fileToken),
                                     "file_type": fileType ?? ""]
        DocsTracker.newLog(enumEvent: .driveUploadFinishView, parameters: params)
    }

//    public static func getCurrentUploadMoudle(mountPoint: String, token: String?) -> PageModule? {
//        if mountPoint.contains("docx") {
//            return .docx
//        } else if mountPoint.contains("doc") {
//            return .doc
//        } else if mountPoint.contains("sheet") {
//            return .sheet
//        } else if mountPoint.contains("mindnote") {
//            return .mindnote
//        } else if mountPoint.contains("bitable") {
//            return .bitable
//        } else if mountPoint.contains("email") {
//            return .email
//        } else if mountPoint.contains("calendar") {
//            return .calendar
//        } else if mountPoint.contains("comment") {
//            return mouduleTypeOfCommentImage(token: token)
//        } else {
//            return nil
//        }
//    }

    public static func mouduleTypeOfCommentImage(token: String?) -> PageModule? {
        guard let token = token else { return nil }
        if token.isEmpty || token.count < 4 {
            DocsLogger.error("the comments of file token is wrong")
            return nil
        }

        let prefix = token.prefix(3)
        if prefix == "doc" {
            return .doc
        } else if prefix == "dox" {
            return .docx
        } else if prefix == "sht" {
            return .sheet
        } else if prefix == "bmn" {
            return .mindnote
        } else if prefix == "bas" {
            return .bitable
        } else if prefix == "wik" {
            return .wiki
        } else {
            return nil
        }
    }
}

extension DocsTracker {
    ///文件重命名click
    public static func reportSpaceDriveRenameClick(click: String, bizParms: SpaceBizParameter) {
        var params: [String: Any] = ["click": "\(click)"]
        params.merge(other: bizParms.params)
        DocsTracker.newLog(enumEvent: .spaceDriveRenameClick, parameters: params)
    }
}
