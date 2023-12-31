//
//  PermissionStatistics.swift
//  SKCommon
//
//  Created by CJ on 2021/4/29.
//
//  swiftlint:disable file_length type_body_length type_name pattern_matching_keywords

// 权限埋点文档: https://bytedance.feishu.cn/docs/doccn5lPZE6l6pbReSIrhzZZxSh
import Foundation
import SKFoundation
import SKInfra

/// 更改权限选项
public enum PermissionSelectOption: String {
    case fullAccess = "full_access"
    case edit
    case read
    case setOwner = "set_owner"
    case remove
    case noAccess = "no_access"
    case cancel
    case delete
}

/// 加锁原因
public enum LockReason: String {
    case reduceCollaborators = "reduce_collaborators"
    case reduceRermissions = "reduce_permissions"
    case reduceSharelink = "reduce_sharelink"
    case reduceSearch = "reduce_search"
    case externalSwitch = "external_switch"
    case unknown = "none"
}

/// 权限设置页面选项
public enum PermissionSettingOption: String {
    case read
    case edit
    case all
    case insideOrganization = "inside_organization"
    case anyoneLark = "anyone_lark"
    case myself
    case fullAccess = "full_access"
    case open = "true"
    case close = "false"
}

/// 开启互联网访问弹窗场景
public enum OpenLinkSharePromptFromScene: String {
    case share = "from_share"
    case shareLink = "from_share_link"
}

/// AskOwner半屏面板出现场景
public enum AskOwnerFromScene: String {
    case imCard = "im_card"
    case addCollaborator = "add_collaborator"
}

/// 分享页面click对应action
public enum SharePageClickAction: String {
    case restore
    case inviteCollaborator = "invite_collaborator"
    case manageCollaborator = "manage_collaborator"
    case shareLink = "share_link"
    case set
    case shareLark = "share_lark"
    case shareWechat = "share_wechat"
    case copyLink = "copy_link"
    case imageShare = "image_share"
    case shareWechatMoments = "share_wechat_moments"
    case shareQq = "share_qq"
    case click_qrcode
    case download_qrcode
    case shareWeibo = "share_weibo"
    case shareBytedanceMoments = "share_bytedance_moments"
    case shareMore = "share_more"
    // 开启表单数据收集
    case openBitable = "open"
    // 关闭表单数据收集
    case closeBitable = "close"
    // 进入表单填写设置
    case bitableLimitSet = "limit_set"
    // 进入 Bitable 高级权限设置
    case bitableAdPermSetting = "bitable_premium_permission_go_check"
}

/// 协作者管理页面click对应action
public enum CollaboratorManagementPageClickAction: String {
    case back
    case restore
    case changePermission = "change_permission"
    case addCollaborator = "add_collaborator"
    case delete  //删除协作者
}

/// 搜索协作者页面click对应action
public enum SearchCollaboratorPageClickAction: String {
    case close
    case next
    case search
    case organization
    case userGroup = "dynamic_user_group"
    case addressBook = "address_book"
}

/// 权限设置页面click对应action
public enum PermissionSettingPageClickAction: String {
    case back
    case `switch` = "switch"
    case commentSet = "comment_set"
    case shareSet = "share_set"
    case securitySet = "security_set"
    case `return` = "return"
    case isShareOutside = "is_share_outside"
    case isOnlyFaShareOutSide = "is_only_fa_share_outside"
    case addCollaboratorSet = "add_collaborator_set"
    case fileCopySet = "file_copy_set"
    case fileSecuritySet = "file_security_set"
    case fileCommentSet = "file_comment_set"
    case collaboratorProfileListSet = "collaborator_profile_list_set"
    case chooseFullAccess = "full_access"
    case chooseEdit = "edit"
    case chooseRead = "read"
    case onlyInsideOrganizationSwitch = "only_inside_organization"
    case allowShareRelatedTenant = "allow_share_related_tenant"
    case isOnlyFAShareRelatedTenant = "is_only_fa_share_related_tenant"
}

/// 链接分享设置页面click对应action
public enum LinkShareSettingPageClickAction: String {
    case back
    case onlyCollaborator = "only_collaborator"
    case organizationRead = "organization_read"
    case organizationEdit = "organization_edit"
    case internetRead = "internet_read"
    case internetEdit = "internet_edit"
    case partnerTenantRead = "related_tenant_read"
    case PartnerTenantEdit = "related_tenant_edit"
    case openPassword = "open_password"
    case changePassword = "change_password"
    case copyLinkAndPassword = "copy_link_and_password"
    case organizationSearch = "organization_search"
    case internetSearch = "internet_search"
}

public enum CopyLinkAlertClickAction: String {
    case cancel
    case copyLinkAndPassword = "copy_link_and_password"
    case copyLink = "copy_link"
}

public struct ReportPermissionCollaboratorListClick {
    public let click: ClickAction
    public let target: DocsTracker.EventType
    public let permSetBefore: PermissionSelectOption
    public let permSetAfter: PermissionSelectOption
    public let collaborateType: Int
    public let objectUid: String
}

public struct ReportPermissionSelectContactClick {
    public let shareType: ShareDocsType
    public let click: ClickAction
    public let target: DocsTracker.EventType
    public let isAddNotes: Bool?
    public let isSendNotice: Bool?
    public let isAllowChildAccess: Bool
    public let userList: [[String: Any]]?
}

public struct ReportPermissionCollaboratorClick {
    public let shareType: ShareDocsType
    public let click: CollaboratorManagementPageClickAction
    public let isHasPageCollaborator: Bool
    public let isSinglePage: Bool
    public let target: DocsTracker.EventType
    public let collaborateType: Int?
    public let objectUid: String?
    public let tooltipsType: Int?
    
}

public struct ReportPermissionCollaboratorSetOwnerClick {
    public let click: ClickAction
    public let target: DocsTracker.EventType
    public let collaborateType: Int
    public let objectUid: String
    public let isInsideTransfer: Bool
    public let isFirstGradeChange: Bool
    
}

public struct ReportPermissionAskOwnerClick {
    public let click: ClickAction
    public let target: DocsTracker.EventType
    public let fromScene: AskOwnerFromScene
    public let listType: PermissionSelectOption
    public let isAddNotes: Bool
    public let userList: [[String: Any]]
    
}

/// 上报分享面板打开耗时 https://bytedance.feishu.cn/wiki/wikcn5t6aZamnYA6rJPHyTPVubd
/// - Parameters:
///   - t1: 点击按钮响应耗时
///   - t2: 初始化耗时
///   - t3: 网络请求耗时
///   - t4: 填充UI数据耗时
///   - firstViewTime: 首帧显示耗时
///   - costTime: 总耗时
///   - openType: 打开类型
///   - isRetry: 是否重试
///   - source: 来源
///   - isMinutes: 是否是妙计
public struct ReportPermissionPerformanceShareOpenTime{
    public let t1: Int
    public let t2: Int
    public let t3: Int
    public let t4: Int
    public let firstViewTime: Int
    public let costTime: Int
    public let openType: String
    public let isRetry: Bool
    public let source: Int
    public let isMinutes: Bool
}

public struct ReportPermissionSecuritySettingClick{
    public let target: String
    public let securityId: String
    public let isSecurityDemotion: Bool
    public let isSingleApply: Bool
    public let isOriginalLevel: Bool
}

/// 通用click事件
public enum ClickAction: String {
    case close
    case optionList = "option_list"
    case invite
    case confirm
    case cancel
    case restore
    case back
    case share
    case transfer
    case applyPermission = "apply_permission"
    case apply
    case sendRequest = "send_request"
    case search
    case next
    case nextLevel = "next_level"
    case delete
    case sendLink = "send_link"
    case maybeLater = "maybe_later"
    case turnOn = "turn_on"
    case gotIt = "got_it"
    case `true` = "true"
    case send
}

/// 高级权限申请点击事件
public enum AdPermApplyClickType {
    /// 点击了 xx(所有者)
    case owner_name
    /// 点击了备注输入框
    case comment
    /// 点击了申请按钮
    case apply(isSuccess: Bool, isComment: Bool)
    /// 点击了了解更多
    case tooltips
    
    var reportValue: [String: Any]? {
        switch self {
        case .owner_name:
            return [
                "click": "owner_name"
            ]
        case .comment:
            return [
                "click": "comment",
                "target": "none"
            ]
        case .apply(let isSuccess, let isComment):
            return [
                "click": "apply",
                "target": "none",
                "is_success": isSuccess ? "true" : "false",
                "is_comment": isComment ? "true" : "false"
            ]
        case .tooltips:
            return [
                "click": "know_more",
            ]
        }
    }
}

/// 表单业务公参
public final class BitableParameters {

    public enum BitableType: String {
        //云空间内独立创建的Bitable
        case app = "bitable_app"
        //云文档Doc内嵌Bitable
        case docBlock = "bitable_doc_block"
        //云文档Sheet内嵌Bitable
        case sheetBlock = "bitable_sheet_block"
    }

    public enum ViewType: String {
        case grid //表格视图
        case kanban  //看板视图
        case gallery //画册视图
        case gantt //甘特图
        case form  //表单
    }

    var bitableType: BitableType
    var isFullScreen: Bool
    var bitableId: String
    var tableId: String
    var viewId: String
    var viewType: ViewType

    var parameters: [String: Any] {
        var parameters = [String: Any]()
        parameters["bitable_type"] = bitableType.rawValue
        parameters["is_full_screen"] = isFullScreen ? "true" : "false"
        parameters["bitable_id"] = DocsTracker.encrypt(id: bitableId)
        parameters["table_id"] = tableId
        parameters["view_id"] = viewId
        parameters["view_type"] = viewType.rawValue
        return parameters
    }

    public init(bitableType: BitableType,
                isFullScreen: Bool,
                bitableId: String,
                tableId: String,
                viewId: String,
                viewType: ViewType) {

        self.bitableType = bitableType
        self.isFullScreen = isFullScreen
        self.bitableId = bitableId
        self.tableId = tableId
        self.viewId = viewId
        self.viewType = viewType
    }

}

/// ccm公共参数
public final class CcmCommonParameters {
    enum Module: String {
        case doc = "doc"
        case docx = "docx"
        case sheet = "sheet"
        case wiki = "wiki"
        case mindnote = "mindnote"
        case bitable = "bitable"
        case slides = "slides"
        case drive = "drive"
        case home = "home"
        case wikiHome = "wiki_home"
        case wikiSpace = "wiki_space"
        case shared = "shared"
        case personal = "personal"
        case favorites = "favorites"
        case trash = "trash"
        case template = "template"
        case personalFolderRoot = "personal_folder_root"
        case sharedFolderRoot = "shared_folder_root"
        case personalSubFolder = "personal_subfolder"
        case sharedSubFolder = "shared_subfolder"
        case todo = "todo"
        case offline = "offline"
        case unknown = "none"
    }
    
//    public enum SubModule: String {
//        case recent = "recent"
//        case quickAccess = "quick_access"
//        case allWiki = "all_wiki"
//        case favorites = "favorites"
//        case trash = "trash"
//        case sharedFolder = "shared_folder"
//        case sharetome = "sharetome"
//        case personalFolder = "personal_folder"
//        case belongtome = "belongtome"
//        case unknown = "none"
//    }
    
    var fileId: String
    var fileType: String
    var appForm: String
    var subFileType: String
    var module: String
    var subModule: String
    var isOwner: Bool?
    var userPermRole: Int
    var userPermissionRawValue: Int // 即将废弃
    var userPermission: String? // 后端给的 action json string
    var publicPermission: String // 后端给的 json string
    var containerId: String
    var containerType: String
    var bitableParameters: BitableParameters?
    
    
    public init(fileId: String,
                fileType: String,
                appForm: String? = nil,
                subFileType: String? = nil,
                module: String,
                subModule: String? = nil,
                userPermRole: Int?,
                userPermissionRawValue: Int?,
                userPermission: [String: Any]? = nil,
                publicPermission: String?,
                containerId: String? = nil,
                containerType: String? = nil,
                bitableParameters: BitableParameters? = nil) {
        self.fileId = fileId
        self.fileType = fileType
        self.appForm = appForm ?? "none"
        if let subFileType = subFileType, !subFileType.isEmpty {
            self.subFileType = subFileType
        } else {
            self.subFileType = "none"
        }
        self.module = module
        self.subModule = subModule ?? "none"
        self.userPermRole = userPermRole ?? 0
        self.userPermissionRawValue = userPermissionRawValue ?? 0
        if let userPermission = userPermission, let jsonString = userPermission.toJSONString() {
            self.userPermission = jsonString
            self.isOwner = userPermission["is_owner"] as? Bool
        }
        self.publicPermission = publicPermission ?? "none"
        if let containerId = containerId {
            self.containerId = DocsTracker.encrypt(id: containerId)
        } else {
            self.containerId = "none"
        }
        self.containerType = containerType ?? "none"
        self.bitableParameters = bitableParameters
    }
    
    public func update(userPermRole: Int?, userPermissionRawValue: Int?) {
        if let userPermRole = userPermRole {
            self.userPermRole = userPermRole
        }
        if let userPermissionRawValue = userPermissionRawValue {
            self.userPermissionRawValue = userPermissionRawValue
        }
    }

    public func update(publicPermission: String?) {
        if let publicPermission = publicPermission {
            self.publicPermission = publicPermission
        }
    }
}

private extension ShareDocsType {
    var isFormShare: Bool {
        self == .form || self == .bitableSub(.form)
    }
}

public final class PermissionStatistics {
    public static let shared = PermissionStatistics(ccmCommonParameters: CcmCommonParameters(
        fileId: "",
        fileType: "",
        module: "",
        userPermRole: nil,
        userPermissionRawValue: nil,
        publicPermission: nil
    ))
    private var docsInfo: DocsInfo?
    private var userPermission: UserPermissionAbility?
    private var publicPermission: PublicPermissionMeta?
    
    public static var isFormV2 = false
    public static var formEditable: Bool?
    
    public var ccmCommonParameters: CcmCommonParameters
    public init(ccmCommonParameters: CcmCommonParameters) {
        self.ccmCommonParameters = ccmCommonParameters
    }
    
    public convenience init(docsInfo: DocsInfo) {
        let permissionManager = DocsContainer.shared.resolve(PermissionManager.self)!
        let publicPermission = permissionManager.getPublicPermissionMeta(token: docsInfo.objToken)
        let userPermission = permissionManager.getUserPermissions(for: docsInfo.objToken)
        let ccmCommonParameters = CcmCommonParameters(fileId: docsInfo.encryptedObjToken,
                                                      fileType: docsInfo.type.name,
                                                      appForm: (docsInfo.isInVideoConference == true) ? "vc" : "none",
                                                      subFileType: docsInfo.fileType,
                                                      module: docsInfo.type.name,
                                                      userPermRole: userPermission?.permRoleValue,
                                                      userPermissionRawValue: userPermission?.rawValue,
                                                      publicPermission: publicPermission?.rawValue)
        self.init(ccmCommonParameters: ccmCommonParameters)
        self.docsInfo = docsInfo
        self.userPermission = userPermission
        self.publicPermission = publicPermission
    }
    
    public func updateCcmCommonParameters(docsInfo: DocsInfo, userPermission: UserPermissionAbility?, publicPermission: PublicPermissionMeta?) {
        self.docsInfo = docsInfo
        self.userPermission = userPermission
        self.publicPermission = publicPermission
        self.ccmCommonParameters = CcmCommonParameters(fileId: docsInfo.encryptedObjToken,
                                                       fileType: docsInfo.type.name,
                                                       appForm: (docsInfo.isInVideoConference == true) ? "vc" : "none",
                                                       subFileType: docsInfo.fileType,
                                                       module: docsInfo.type.name,
                                                       userPermRole: userPermission?.permRoleValue,
                                                       userPermissionRawValue: userPermission?.rawValue,
                                                       publicPermission: publicPermission?.rawValue)
    }
    
    func addCommonParameters(params: inout [String: Any],
                             ccmCommonParameters: CcmCommonParameters) {
        params["file_id"] = ccmCommonParameters.fileId
        params["file_type"] = ccmCommonParameters.fileType
        params["permission_obj_type"] = ccmCommonParameters.fileType
        params["app_form"] = ccmCommonParameters.appForm
        params["sub_file_type"] = ccmCommonParameters.subFileType
        params["module"] = ccmCommonParameters.module
        params["sub_module"] = ccmCommonParameters.subModule
        if ccmCommonParameters.fileType == "folder" {
            params["user_permission_folder"] = ccmCommonParameters.userPermRole
            params["folder_permission"] = ccmCommonParameters.publicPermission
        } else {
            params["user_permission"] = ccmCommonParameters.userPermissionRawValue // 旧的写法
            if let userPermission = ccmCommonParameters.userPermission { // 新的写法，仅当 ccmCommonParams 被注入新值时才替换
                params["user_permission"] = userPermission
            }
            if let isOwner = ccmCommonParameters.isOwner {
                params["is_owner"] = isOwner ? "true" : "false"
            }
            params["file_permission"] = ccmCommonParameters.publicPermission
        }
        params["container_id"] = ccmCommonParameters.containerId
        params["container_type"] = ccmCommonParameters.containerType

        //bitable
        params.merge(other: ccmCommonParameters.bitableParameters?.parameters ?? [:])
    }

    var commonParameters: [String: Any] {
        var params: [String: Any] = [:]
        addCommonParameters(params: &params, ccmCommonParameters: ccmCommonParameters)
        return params
    }
    
    public func reportDocsCopyClick(isSuccess: Bool) {
        let isAuthByLeader = userPermission?.actions[.copy]?.authReason == .leaderCopy ? "true" : "false"
        let parameters = [
            "click": "block_action",
            "action_type": "copy",
            "target": "none",
            "is_success": isSuccess ? "true" : "false",
            "is_auth_by_leader": isAuthByLeader
        ]
        report(event: .docsGlobalCopyClick, with: parameters)
    }
    
    public func reportAdPermApplyView() {
        report(event: .premiumPermissionApplicationView, with: nil)
    }
    
    public func reportAdPermApplyClick(_ type: AdPermApplyClickType) {
        report(event: .premiumPermissionApplicationClick, with: type.reportValue)
    }
    
    public func reportPermissionManagementCollaboratorListView(collaborateType: Int, objectUid: String) {
        var parameters: [String: Any] = [:]
        parameters["collaborate_type"] = collaborateType
        parameters["object_uid"] = DocsTracker.encrypt(id: objectUid)
        report(event: .permissionManagementCollaboratorListView, with: parameters)
    }
    
    public func reportPermissionManagementCollaboratorListClick(context: ReportPermissionCollaboratorListClick) {
        var parameters: [String: Any] = [:]
        parameters["click"] = context.click.rawValue
        parameters["target"] = context.target.rawValue
        parameters["perm_set_before"] = context.permSetBefore.rawValue
        parameters["perm_set_after"] = context.permSetAfter.rawValue
        parameters["collaborate_type"] = context.collaborateType
        parameters["object_uid"] = DocsTracker.encrypt(id: context.objectUid)
        report(event: .permissionManagementCollaboratorListClick, with: parameters)
    }
    
    public func reportPermissionSelectContactClick(context: ReportPermissionSelectContactClick) {
        var parameters: [String: Any] = [:]
        parameters["click"] = context.click.rawValue
        parameters["target"] = context.target.rawValue

        if let isAddNotes = context.isAddNotes {
            parameters["is_add_notes"] = isAddNotes ? "true" : "false"
        }
        if let isSendNotice = context.isSendNotice {
            parameters["is_send_notice"] = isSendNotice ? "true" : "false"
        }
        if let userList = context.userList {
            parameters["user_list"] = objectToString(object: userList)
        }
        parameters["is_allow_child_access"] = context.isAllowChildAccess ? "true" : "false"
        let event: DocsTracker.EventType = (context.shareType.isFormShare) ? .bitableFormPermissionSelectContactClick : .permissionSelectContactClick
        report(event: event, with: parameters)
    }
    
    public func reportPermissionChangeAlertClick(click: ClickAction, target: DocsTracker.EventType) {
        var parameters: [String: Any] = [:]
        parameters["click"] = click.rawValue
        parameters["target"] = target.rawValue
        report(event: .permissionChangeAlertClick, with: parameters)
    }
    

    public func reportLockAlertClick(click: ClickAction,
                                     target: DocsTracker.EventType,
                                     reason: LockReason,
                                     collaborateType: Int? = nil,
                                     objectUid: String? = nil) {
        var parameters: [String: Any] = [:]
        parameters["click"] = click.rawValue
        parameters["target"] = target.rawValue
        parameters["reason"] = reason.rawValue
        if let collaborateType = collaborateType {
            parameters["collaborate_type"] = collaborateType
        }
        if let objectUid = objectUid {
            parameters["object_uid"] = DocsTracker.encrypt(id: objectUid)
        }
        report(event: .lockAlertClick, with: parameters)
    }
    
    public func reportPermissionShareClick(shareType: ShareDocsType, click: SharePageClickAction, target: DocsTracker.EventType, hasCover: Bool? = nil) {
        var parameters: [String: Any] = [:]
        parameters["click"] = click.rawValue
        parameters["target"] = target.rawValue
        if let hasCover = hasCover {
            parameters["cover_type"] = hasCover ? "default" : "upload"
        }
        let event: DocsTracker.EventType = (shareType.isFormShare) ? .bitableFormPermissionClick : .permissionShareClick
        if shareType.isFormShare {
            if Self.isFormV2 {
                parameters["form_version"] = "form_v2"
                if let edit = Self.formEditable {
                    if edit {
                        parameters["form_permission"] = "edit"
                    } else {
                        parameters["form_permission"] = "read"
                    }
                }
                
            }
        }
        report(event: event, with: parameters)
    }
    
    public func reportPermissionShareQrcodeClick(shareType: ShareDocsType, click: String, individual: Bool) {
        if shareType == .bitableSub(.addRecord) {
            var parameters: [String: Any] = [:]
            parameters["click"] = click
            parameters["target"] = "none"
            parameters["type"] = individual ? "individual_page" : "inside_base"
            report(event: .bitableAddRecordQrcodeClick, with: parameters)
        }
    }
    
    public func reportPermissionShareQrcodeView(shareType: ShareDocsType, individual: Bool) {
        if shareType == .bitableSub(.addRecord) {
            var parameters: [String: Any] = [:]
            parameters["type"] = individual ? "individual_page" : "inside_base"
            report(event: .bitableAddRecordQrcodeView, with: parameters)
        }
    }

    
    public func reportPermissionManagementCollaboratorClick(context: ReportPermissionCollaboratorClick) {
        var parameters: [String: Any] = [:]
        parameters["click"] = context.click.rawValue
        parameters["target"] = context.target.rawValue
        if let collaborateType = context.collaborateType {
            parameters["collaborate_type"] = collaborateType
            switch context.tooltipsType {
            case 1:
                parameters["wiki_member_type"] = "read_group"
            case 2:
                parameters["wiki_member_type"] = "edit_group"
            default: break
            }
        }
        if let objectUid = context.objectUid {
            parameters["object_uid"] = DocsTracker.encrypt(id: objectUid)
        }
        parameters["is_has_page_collaborator"] = context.isHasPageCollaborator ? true : false
        parameters["view_title"] = context.isSinglePage ? "current_page" : "current_and_child_page"
        let event: DocsTracker.EventType = (context.shareType.isFormShare) ? .bitableFormPermissionCollaboratorClick : .permissionManagementCollaboratorClick
        report(event: event, with: parameters)
    }

    //表单删除填写者确认弹框
    public func reportBitableFormCollaboratorDeleteView() {
        report(event: .bitableFormCollaboratorDeleteView, with: nil)
    }

    //表单删除填写者 确认弹框click
    public func reportBitableFormCollaboratorDeleteClick(isDelete: Bool) {
        var parameters: [String: Any] = [:]
        parameters["click"] = isDelete ? "delete" : "cancel"
        parameters["target"] = DocsTracker.EventType.noneTargetView.rawValue
        report(event: .bitableFormCollaboratorDeleteClick, with: parameters)
    }
    
    public func reportLockRestoreAlertClick(click: ClickAction, target: DocsTracker.EventType) {
        var parameters: [String: Any] = [:]
        parameters["click"] = click.rawValue
        parameters["target"] = target.rawValue
        report(event: .lockRestoreAlertClick, with: parameters)
    }
    
    public func reportPermissionAddCollaboratorClick(click: SearchCollaboratorPageClickAction,
                                                     num: String? = nil,
                                                     target: DocsTracker.EventType,
                                                     userList: [[String: Any]]? = nil) {
        var parameters: [String: Any] = [:]
        parameters["click"] = click.rawValue
        if let num = num {
            parameters["num"] = num
        }
        parameters["target"] = target.rawValue
        if let userList = userList {
            parameters["user_list"] = objectToString(object: userList)
        }
        report(event: .permissionAddCollaboratorClick, with: parameters)
    }
    
    public func reportPermissionSetClick(click: PermissionSettingPageClickAction,
                                         option: PermissionSettingOption? = nil,
                                         canCross: Bool? = nil,
                                         params: [String: Any]? = nil,
                                         target: DocsTracker.EventType) {
        var parameters: [String: Any] = [:]
        parameters["click"] = click.rawValue
        if let option = option {
            parameters["list_type"] = option.rawValue
        }
        if let canCross = canCross {
            parameters["is_share_outside_organization"] = canCross ? "true" : "false"
        }
        parameters.merge(other: params)
        parameters["target"] = target.rawValue
        report(event: .permissionSetClick, with: parameters)
    }

    public func reportPermissionSetClick(event: DocsTracker.EventType,
                                         click: PermissionSettingPageClickAction,
                                         permSetBefore: PermissionSettingOption? = nil,
                                         permSetAfter: PermissionSettingOption? = nil,
                                         target: DocsTracker.EventType) {
        var parameters: [String: Any] = [:]
        parameters["click"] = click.rawValue
        if let before = permSetBefore, let after = permSetAfter {
            parameters["perm_set_before"] = before.rawValue
            parameters["perm_set_after"] = after.rawValue
        }
        parameters["target"] = target.rawValue
        report(event: event, with: parameters)
    }
    
    public func reportPermissionShareWechatClick(click: ClickAction, target: DocsTracker.EventType) {
        var parameters: [String: Any] = [:]
        parameters["click"] = click.rawValue
        parameters["target"] = target.rawValue
        report(event: .permissionShareWechatClick, with: parameters)
    }
    
    public func reportPermissionShareEncryptedLinkClick(shareType: ShareDocsType,
                                                        click: LinkShareSettingPageClickAction,
                                                        target: DocsTracker.EventType,
                                                        openPassword: Bool? = nil) {
        var parameters: [String: Any] = [:]
        parameters["click"] = click.rawValue
        parameters["target"] = target.rawValue
        if let openPassword = openPassword {
            parameters["open_password_type"] = openPassword ? "true" : "false"
        }

        let event: DocsTracker.EventType = (shareType.isFormShare) ? .bitableFormLimitSetClick : .permissionShareEncryptedLinkClick
        report(event: event, with: parameters)
    }
    
    public func reportPermissionManagementCollaboratorSetOwnerClick(transferObjectType: TransferObjectType, context: ReportPermissionCollaboratorSetOwnerClick) {
        var parameters: [String: Any] = [:]
        parameters["transfer_object_type"] = transferObjectType.rawValue
        parameters["click"] = context.click.rawValue
        parameters["target"] = context.target.rawValue
        parameters["collaborate_type"] = context.collaborateType
        parameters["is_inside_transfer"] = context.isInsideTransfer
        parameters["object_uid"] = DocsTracker.encrypt(id: context.objectUid)
        parameters["is_first_grade_change"] = context.isFirstGradeChange ? "true" : "false"
        report(event: .permissionManagementCollaboratorSetOwnerClick, with: parameters)
    }
    
    public func reportPermissionPromptClick(click: ClickAction,
                                            target: DocsTracker.EventType,
                                            fromScene: OpenLinkSharePromptFromScene) {
        var parameters: [String: Any] = [:]
        parameters["click"] = click.rawValue
        parameters["target"] = target.rawValue
        parameters["from_scene"] = fromScene.rawValue
        report(event: .permissionPromptClick, with: parameters)
    }

    public enum ApplyReason: String {
        case applyUserPermission = "apply_permission"
        case applyAuditExempt = "admin_forbidden"
    }

    public func reportPermissionWithoutPermissionClick(click: ClickAction,
                                                       target: DocsTracker.EventType,
                                                       triggerReason: ApplyReason,
                                                       applyList: PermissionSelectOption? = nil,
                                                       isAddNotes: Bool? = nil) {
        var parameters: [String: Any] = [:]
        parameters["click"] = click.rawValue
        parameters["target"] = target.rawValue
        parameters["trigger_reason"] = triggerReason.rawValue
        if let applyList = applyList {
            parameters["apply_list"] = applyList.rawValue
        }
        if let isAddNotes = isAddNotes {
            parameters["is_add_notes"] = isAddNotes ? "true" : "false"
        }
        report(event: .permissionWithoutPermissionClick, with: parameters)
    }
    
    public func reportPermissionCopyLinkClick(click: CopyLinkAlertClickAction, target: DocsTracker.EventType) {
        var parameters: [String: Any] = [:]
        parameters["click"] = click.rawValue
        parameters["target"] = target.rawValue
        report(event: .permissionCopyLinkClick, with: parameters)
    }
    
    public func reportPermissionReadWithoutEditClick(click: ClickAction,
                                                     target: DocsTracker.EventType,
                                                     isAddNotes: Bool) {
        var parameters: [String: Any] = [:]
        parameters["click"] = click.rawValue
        parameters["target"] = target.rawValue
        parameters["is_add_notes"] = isAddNotes ? "true" : "false"
        report(event: .permissionReadWithoutEditClick, with: parameters)
    }
    
    public func reportPermissionAskOwnerClick(context: ReportPermissionAskOwnerClick) {
        var parameters: [String: Any] = [:]
        parameters["click"] = context.click.rawValue
        parameters["target"] = context.target.rawValue
        parameters["from_scene"] = context.fromScene.rawValue
        parameters["list_type"] = context.listType.rawValue
        parameters["is_leave_message"] = context.isAddNotes ? "true" : "false"
        parameters["user_list"] = objectToString(object: context.userList)
        report(event: .permissionAskOwnerClick, with: parameters)
    }
    
    public func reportPermissionAskOwnerTypeClick(click: PermissionSelectOption,
                                                  target: DocsTracker.EventType,
                                                  fromScene: AskOwnerFromScene, userList: [[String: Any]]) {
        var parameters: [String: Any] = [:]
        parameters["click"] = click.rawValue
        parameters["target"] = target.rawValue
        parameters["from_scene"] = fromScene.rawValue
        parameters["user_list"] = objectToString(object: userList)
        report(event: .permissionAskOwnerTypeClick, with: parameters)
    }
    
    public func reportPermissionShareAskOwnerClick(click: ClickAction,
                                                   target: DocsTracker.EventType,
                                                   isAddNotes: Bool? = nil,
                                                   userList: [[String: Any]]? = nil) {
        var parameters: [String: Any] = [:]
        parameters["click"] = click.rawValue
        parameters["target"] = target.rawValue
        if let isAddNotes = isAddNotes {
            parameters["is_add_notes"] = isAddNotes ? "true" : "false"
        }
        if let userList = userList {
            parameters["user_list"] = objectToString(object: userList)
        }
        report(event: .permissionShareAskOwnerClick, with: parameters)
    }
    
    public func reportPermissionShareAskOwnerTypeClick(click: PermissionSelectOption,
                                                       target: DocsTracker.EventType,
                                                       collaborateType: Int,
                                                       objectUid: String) {
        var parameters: [String: Any] = [:]
        parameters["click"] = click.rawValue
        parameters["target"] = target.rawValue
        parameters["collaborate_type"] = collaborateType
        parameters["object_uid"] = DocsTracker.encrypt(id: objectUid)
        report(event: .permissionShareAskOwnerTypeClick, with: parameters)
    }
    
    public func reportPermissionOrganizationAuthorizeClick(click: ClickAction, target: DocsTracker.EventType, userList: [[String: Any]]? = nil) {
        var parameters: [String: Any] = [:]
        parameters["click"] = click.rawValue
        parameters["target"] = target.rawValue
        if let userList = userList {
            parameters["user_list"] = objectToString(object: userList)
        }
        report(event: .permissionOrganizationAuthorizeClick, with: parameters)
    }

    public func reportPermissionUserGroupAuthorizeClick(click: ClickAction, target: DocsTracker.EventType, userList: [[String: Any]]? = nil) {
        var parameters: [String: Any] = [:]
        parameters["click"] = click.rawValue
        parameters["target"] = target.rawValue
        if let userList = userList {
            parameters["user_list"] = objectToString(object: userList)
        }
        report(event: .permissionDynamicUserGroupAuthorizeClick, with: parameters)
    }
    
    public func reportPermissionUnableToApplyClick(click: ClickAction, target: DocsTracker.EventType) {
        var parameters: [String: Any] = [:]
        parameters["click"] = click.rawValue
        parameters["target"] = target.rawValue
        report(event: .permissionUnableToApplyClick, with: parameters)
    }
    
    public func reportPermissionSendLinkClick(click: ClickAction,
                                              target: DocsTracker.EventType,
                                              isAddNotes: Bool? = nil,
                                              userList: [[String: Any]]? = nil) {
        var parameters: [String: Any] = [:]
        parameters["click"] = click.rawValue
        parameters["target"] = target.rawValue

        if let isAddNotes = isAddNotes {
            parameters["is_add_notes"] = isAddNotes ? "true" : "false"
        }
        if let userList = userList {
            parameters["user_list"] = objectToString(object: userList)
        }
        report(event: .permissionSendLinkClick, with: parameters)
    }
    
    public func reportPermissionSharePublicAccessClick(click: ClickAction, target: DocsTracker.EventType) {
        var parameters: [String: Any] = [:]
        parameters["click"] = click.rawValue
        parameters["target"] = target.rawValue
        report(event: .permissionSharePublicAccessClick, with: parameters)
    }
    
    public func reportPermissionOwnerTurnedOffPromptClick(click: ClickAction, target: DocsTracker.EventType) {
        var parameters: [String: Any] = [:]
        parameters["click"] = click.rawValue
        parameters["target"] = target.rawValue
        report(event: .permissionOwnerTurnedOffPromptClick, with: parameters)
    }
    
    public func reportPermissionShareAtPeopleClick(click: ClickAction,
                                                   target: DocsTracker.EventType,
                                                   isSendNotice: Bool? = nil) {
        var parameters: [String: Any] = [:]
        parameters["click"] = click.rawValue
        parameters["target"] = target.rawValue
        if let isSendNotice = isSendNotice {
            parameters["is_send_notice"] = isSendNotice ? "true" : "false"
        }
        report(event: .permissionShareAtPeopleClick, with: parameters)
    }
    
    public func reportPermissionCommentWithoutPermissionClick(click: ClickAction, target: DocsTracker.EventType) {
        var parameters: [String: Any] = [:]
        parameters["click"] = click.rawValue
        parameters["target"] = target.rawValue
        report(event: .permissionCommentWithoutPermissionClick, with: parameters)
    }

    public func reportPermissionOrganizationAuthorizeSendNoticeClick(click: ClickAction,
                                                                     target: DocsTracker.EventType,
                                                                     isAddNotes: Bool? = nil,
                                                                     userList: [[String: Any]]? = nil) {
        var parameters: [String: Any] = [:]
        parameters["click"] = click.rawValue
        parameters["target"] = target.rawValue
        if let isAddNotes = isAddNotes {
            parameters["is_add_notes"] = isAddNotes ? "true" : "false"
        }
        if let userList = userList {
            parameters["user_list"] = objectToString(object: userList)
        }
        report(event: .permissionOrganizationAuthorizeSendNoticeClick, with: parameters)
    }
    
    
    /// 上报分享面板打开耗时 https://bytedance.feishu.cn/wiki/wikcn5t6aZamnYA6rJPHyTPVubd
    /// - Parameters:
    ///   - t1: 点击按钮响应耗时
    ///   - t2: 初始化耗时
    ///   - t3: 网络请求耗时
    ///   - t4: 填充UI数据耗时
    ///   - firstViewTime: 首帧显示耗时
    ///   - costTime: 总耗时
    ///   - openType: 打开类型
    ///   - isRetry: 是否重试
    ///   - source: 来源
    ///   - isMinutes: 是否是妙计
    func reportPermissionPerformanceShareOpenTime(context: ReportPermissionPerformanceShareOpenTime) {
        let parameters: [String: Any] = [
            "t1": context.t1,
            "t2": context.t2,
            "t3": context.t3,
            "t4": context.t4,
            "first_view_time": context.firstViewTime,
            "cost_time": context.costTime,
            "open_type": context.openType,
            "is_retry": context.isRetry ? 1 : 0,
            "source": context.source,
            "is_minutes": context.isMinutes ? 1 : 0
        ]
        report(event: .permissionPerformanceShareOpenTime, with: parameters)
    }
    
    /// 上报分享面板的打开结果
    /// - Parameters:
    ///   - isSuccessful: 是否成功
    ///   - openType: 打开类型
    ///   - isRetry: 是否重试
    ///   - source: 来源
    ///   - isMinutes: 是否是妙计
    func reportPermissionPerformanceShareOpenFinish(isSuccessful: Bool,
                                                    openType: String,
                                                    isRetry: Bool,
                                                    source: Int,
                                                    isMinutes: Bool,
                                                    errorCode: Int?) {
        var parameters: [String: Any] = [
            "is_successful": isSuccessful ? 1 : 0,
            "open_type": openType,
            "is_retry": isRetry ? 1 : 0,
            "source": source,
            "is_minutes": isMinutes ? 1 : 0
        ]
        if let errorCode {
            parameters["error_code"] = errorCode
        }
        report(event: .permissionPerformanceShareOpenFinish, with: parameters)
    }
    
    public func report(event: DocsTracker.EventType, with extraParams: [String: Any]?) {
        var parameters: [String: Any] = [:]
        addCommonParameters(params: &parameters, ccmCommonParameters: self.ccmCommonParameters)
        if let extraParams = extraParams {
            for item in extraParams {
                parameters[item.key] = item.value
            }
        }
        DocsTracker.newLog(enumEvent: event, parameters: parameters)
    }
    
    private func objectToString(object: Any) -> String {
        var result: String = ""
        do {
            let data = try JSONSerialization.data(withJSONObject: object, options: .prettyPrinted)
            result = String(data: data, encoding: String.Encoding.utf8) ?? ""
        } catch {
            result = ""
        }
        return result
    }
}

extension PermissionStatistics {
    public func reportPermissionShareClickInBitableSingleCardContext(shareType: ShareDocsType, click: SharePageClickAction, target: DocsTracker.EventType) {
        var parameters: [String: Any] = [:]
        parameters["click"] = click.rawValue
        parameters["target"] = target.rawValue
        var event: DocsTracker.EventType = .permissionShareClick
        if click == .download_qrcode, case let .bitableSub(subType) = shareType, subType == .record {
            parameters["share_type"] = "record"
            event = .bitableExternalPermissionClick
        }
        report(event: event, with: parameters)
    }
}

extension PermissionStatistics {
    public func reportPermissionChangeAlertView() {
        report(event: .permissionChangeAlertView, with: nil)
    }
    
    public func reportLockAlertView(reason: LockReason,
                                    collaborateType: Int? = nil,
                                    objectUid: String? = nil) {
        var parameters: [String: Any] = [:]
        parameters["reason"] = reason.rawValue
        if let collaborateType = collaborateType {
            parameters["collaborate_type"] = collaborateType
        }
        if let objectUid = objectUid {
            parameters["object_uid"] = DocsTracker.encrypt(id: objectUid)
        }
        report(event: .lockAlertView, with: parameters)
    }
    
    public func reportLockRestoreView() {
        report(event: .lockRestoreView, with: nil)
    }
    
    public func reportPermissionShareView() {
        report(event: .permissionShareView, with: nil)
    }
    
    public func reportPermissionManagementCollaboratorView(shareType: ShareDocsType, isHasPageCollaborator: Bool) {
        let event: DocsTracker.EventType = (shareType.isFormShare) ? .bitableFormPermissionCollaboratorView : .permissionManagementCollaboratorView
        report(event: event, with: ["is_has_page_collaborator": isHasPageCollaborator ? true : false])
    }
    
    public func reportPermissionAddCollaboratorView() {
        report(event: .permissionAddCollaboratorView, with: nil)
    }
    
    public func reportPermissionSelectContactView(shareType: ShareDocsType, userList: [[String: Any]]) {
        var parameters: [String: Any] = [:]
        parameters["user_list"] = objectToString(object: userList)

        let event: DocsTracker.EventType = (shareType.isFormShare) ? .bitableFormPermissionSelectContactView : .permissionSelectContactView
        report(event: event, with: parameters)
    }
    
    public func reportPermissionSetView(isNewSetMenu: Bool) {
        report(event: .permissionSetView, with: ["is_new_set_menu": isNewSetMenu ? "true" : "false"])
    }

    public func reportPermissionAddCollaboratorSetView() {
        report(event: .ccmPermissionAddCollaboratorSetView, with: nil)
    }

    public func reportPermissionFileCopySetView() {
        report(event: .ccmPermissionFileCopySetView, with: nil)
    }
    
    public func reportPermissionFileSecuritySetView() {
        report(event: .ccmPermissionFileSecuritySetView, with: nil)
    }

    public func reportPermissionFileCommentSetView() {
        report(event: .ccPermissionFileCommentSetView, with: nil)
    }
    
    public func reportPermissionCollaboratorProfileSetView() {
        report(event: .ccmPermissionCollaboratorProfileListSetView, with: nil)
    }
    
    public func reportPermissionNoCollaboratorProfileListView() {
        report(event: .ccmPermissionNoCollaboratorProfileListView, with: nil)
    }
    
    public func reportPermissionShareLarkView() {
        report(event: .permissionShareLarkView, with: nil)
    }
    
    public func reportPermissionShareWechatView() {
        report(event: .permissionShareWechatView, with: nil)
    }
    
    public func reportPermissionShareEncryptedLinkView(shareEntity: SKShareEntity) {
        if let subType = shareEntity.bitableSubType {
            DocsTracker.newLog(enumEvent: .bitableExternalPermissionLimitSetView, parameters: ["share_type": subType.trackString])
        }
        let event: DocsTracker.EventType = (shareEntity.type.isFormShare) ? .bitableFormLimitSetView : .permissionShareEncryptedLinkView
        report(event: event, with: nil)
    }
    
    func reportPermissionShareEditClick(shareEntity: SKShareEntity, editLinkInfo: EditLinkInfo) {
        if let bitableSubType = shareEntity.bitableSubType {
            var type = ""
            switch editLinkInfo.chosenType {
            case .orgRead:
                type = "organization_view"
            case .partnerRead, .close:
                type = "only_collaborator_view"
            case .anyoneRead:
                type = "internet_view"
            default:
                break
            }
            DocsTracker.newLog(enumEvent: .bitableExternalPermissionLimitSetClick, parameters: ["share_type": bitableSubType.trackString,
                                                                                                "click": type])
        }
    }

    public enum TransferObjectType: String {
        case doc = "only_doc"
        case folderv1 = "folder1"
        case folderv2 = "folder2"
    }
    public func reportPermissionManagementCollaboratorSetOwnerView(transferObjectType: TransferObjectType,
                                                                   collaborateType: Int,
                                                                   objectUid: String,
                                                                   isFirstGradeChange: Bool) {
        var parameters: [String: Any] = [:]
        parameters["transfer_object_type"] = transferObjectType.rawValue
        parameters["collaborate_type"] = collaborateType
        parameters["object_uid"] = DocsTracker.encrypt(id: objectUid)
        parameters["is_first_grade_change"] = isFirstGradeChange ? "true" : "false"
        report(event: .permissionManagementCollaboratorSetOwnerView, with: parameters)
    }
    
    public func reportPermissionPromptView(fromScene: OpenLinkSharePromptFromScene) {
        var parameters: [String: Any] = [:]
        parameters["from_scene"] = fromScene.rawValue
        report(event: .permissionPromptView, with: parameters)
    }
    
    public func reportPermissionWithoutPermissionView(triggerReason: ApplyReason) {
        report(event: .permissionWithoutPermissionView, with: ["trigger_reason": triggerReason.rawValue])
    }
    
    public func reportPermissionReadWithoutEditView() {
        report(event: .permissionReadWithoutEditView, with: nil)
    }
    
    public func reportPermissionCopyLinkView() {
        report(event: .permissionCopyLinkView, with: nil)
    }
    
    public func reportPermissionAskOwnerView(fromScene: AskOwnerFromScene, userList: [[String: Any]]) {
        var parameters: [String: Any] = [:]
        parameters["from_scene"] = fromScene.rawValue
        parameters["user_list"] = objectToString(object: userList)
        report(event: .permissionAskOwnerView, with: parameters)
    }
    
    public func reportPermissionAskOwnerTypeView(fromScene: AskOwnerFromScene) {
        var parameters: [String: Any] = [:]
        parameters["from_scene"] = fromScene.rawValue
        report(event: .permissionAskOwnerTypeView, with: parameters)
    }
    
    public func reportAddUserGroupAuthorizeView() {
        var parameters: [String: Any] = [:]
        parameters["user_group"] = "True"
        report(event: .permissionAddCollaboratorGroupView, with: parameters)
    }
    
    public func reportPermissionShareAskOwnerView(userList: [[String: Any]]) {
        var parameters: [String: Any] = [:]
        parameters["user_list"] = objectToString(object: userList)
        report(event: .permissionShareAskOwnerView, with: parameters)
    }
    
    public func reportPermissionShareAskOwnerTypeView(collaborateType: Int, objectUid: String) {
        var parameters: [String: Any] = [:]
        parameters["collaborate_type"] = collaborateType
        parameters["object_uid"] = DocsTracker.encrypt(id: objectUid)
        report(event: .permissionShareAskOwnerTypeView, with: parameters)
    }
    
    public func reportPermissionOrganizationAuthorizeView() {
        report(event: .permissionOrganizationAuthorizeView, with: nil)
    }
    
    public func reportPermissionOrganizationAuthorizeSearchView() {
        report(event: .permissionOrganizationAuthorizeSearchView, with: nil)
    }

    public func reportPermissionUserGroupAuthorizeView() {
        report(event: .permissionDynamicUserGroupAuthorizeView, with: nil)
    }

    public func reportPermissionUserGroupAuthorizeSearchView() {
        report(event: .permissionDynamicUserGroupAuthorizeSearchView, with: nil)
    }

    public func reportPermissionUnableToApplyView() {
        report(event: .permissionUnableToApplyView, with: nil)
    }
    
    public func reportPermissionSendLinkView(userList: [[String: Any]]) {
        var parameters: [String: Any] = [:]
        parameters["user_list"] = objectToString(object: userList)
        report(event: .permissionSendLinkView, with: parameters)
    }
    
    public func reportPermissionSharePublicAccessView() {
        report(event: .permissionSharePublicAccessView, with: nil)
    }
    
    public func reportPermissionShareAtPeopleView() {
        report(event: .permissionShareAtPeopleView, with: nil)
    }
    
    public func reportPermissionOwnerTurnedOffPromptView() {
        report(event: .permissionOwnerTurnedOffPromptView, with: nil)
    }
    
    public func reportPermissionCommentWithoutPermissionView() {
        report(event: .permissionCommentWithoutPermissionView, with: nil)
    }

    public func reportPermissionOrganizationAuthorizeSendNoticeView(with: [String: Any]? = nil) {
        report(event: .permissionOrganizationAuthorizeSendNoticeView, with: with)
    }
}

//多维表格高级权限埋点
extension PermissionStatistics {

    public func reportBitablePremiumPermissionSettingView(isTemplate: Bool? = nil) {
        var param = [String: Any]()
        if let val = isTemplate {
            param = ["is_template": val ? "true" : "false"]
        }
        report(event: .ccmBitablePremiumPermissionSettingView, with: param)
    }
    
    public func reportBitableAdPermSwitchOpenSuccess() {
        report(event: .ccmBitablePremiumPermissionEntrance, with: ["action": "open"])
    }

    public enum BitablePremiumPermissionSettingClickAction: String {
        case permissionRulesetting = "permission_rulesetting"
        case addCollaborator = "add_collaborator"
        case manageCollaborator = "manage_collaborator"
        case back
        case adPermTurnOff = "turn_off"
        case upgrade = "upgrade"
        case roleDistributionByDefault = "role_distribution_by_default"


        var target: DocsTracker.EventType {
            switch self {
            case .permissionRulesetting:
                return DocsTracker.EventType.ccmBitablePremiumPermissionRulesettingView
            case .addCollaborator:
                return DocsTracker.EventType.permissionAddCollaboratorView
            case .manageCollaborator:
                return DocsTracker.EventType.ccmBitablePremiumPermissionManageCollaboratorView
            case .back:
                return DocsTracker.EventType.noneTargetView
            case .adPermTurnOff:
                return DocsTracker.EventType.ccmBitablePremiumPermissionDeleteView
            case .upgrade:
                return DocsTracker.EventType.noneTargetView
            case .roleDistributionByDefault:
                return DocsTracker.EventType.noneTargetView
            }
        }
    }

    public func reportBitablePremiumPermissionSettingClick(
        action: BitablePremiumPermissionSettingClickAction,
        isTemplate: Bool? = nil,
        params: [String: Any]? = nil
    ) {
        var parameters: [String: Any] = [:]
        parameters["click"] = action.rawValue
        parameters["target"] = action.target.rawValue
        if let isTemp = isTemplate {
            parameters["is_template"] = isTemp ? "true" : "false"
        }
        parameters.merge(other: params)
        report(event: .ccmBitablePremiumPermissionSettingClick, with: parameters)
    }
    public func reportBitablePremiumPermissionRulesettingView() {
        report(event: .ccmBitablePremiumPermissionRulesettingView, with: nil)
    }
    public func reportBitablePremiumPermissionInviteCollaboratorView() {
        report(event: .ccmBitablePremiumPermissionInviteCollaboratorView, with: nil)
    }

    public enum BitablePremiumPermissionInviteCollaboratorClickAction: String {
        case remove
        case invite
        case back
    }
    public func reportBitablePremiumPermissionInviteCollaboratorClick(action: BitablePremiumPermissionInviteCollaboratorClickAction, params: [String: Any]? = nil) {
        var parameters: [String: Any] = [:]
        parameters["click"] = action.rawValue
        parameters["target"] = DocsTracker.EventType.noneTargetView.rawValue
        parameters.merge(other: params)
        report(event: .ccmBitablePremiumPermissionInviteCollaboratorClick, with: parameters)
    }
    public func reportBitablePremiumPermissionManageCollaboratorView() {
        report(event: .ccmBitablePremiumPermissionManageCollaboratorView, with: nil)
    }
    public enum BitablePremiumPermissionManageCollaboratorClickAction: String {
        case remove = "remove"
        case addCollaboratorIcon = "add_collaborator_icon"
        case addCollaboratorButton = "add_collaborator_button"
        case back

        var target: DocsTracker.EventType {
            switch self {
            case .remove:
                return DocsTracker.EventType.ccmBitablePremiumPermissionRemoveConfirmView
            case .addCollaboratorIcon, .addCollaboratorButton:
                return DocsTracker.EventType.permissionAddCollaboratorView
            case .back:
                return DocsTracker.EventType.noneTargetView
            }
        }
    }
    public func reportBitablePremiumPermissionManageCollaboratorClick(action: BitablePremiumPermissionManageCollaboratorClickAction, params: [String: Any]? = nil) {
        var parameters: [String: Any] = [:]
        parameters["click"] = action.rawValue
        parameters["target"] = action.target.rawValue
        parameters.merge(other: params)
        report(event: .ccmBitablePremiumPermissionManageCollaboratorClick, with: parameters)
    }
    public func reportBitablePremiumPermissionRemoveConfirmView() {
        report(event: .ccmBitablePremiumPermissionRemoveConfirmView, with: nil)
    }

    public enum BitablePremiumPermissionRemoveConfirmClickAction: String {
        case cancel
        case confirm
    }
    public func reportBitablePremiumPermissionRemoveConfirmClick(action: BitablePremiumPermissionRemoveConfirmClickAction, params: [String: Any]? = nil) {
        var parameters: [String: Any] = [:]
        parameters["click"] = action.rawValue
        parameters["target"] = DocsTracker.EventType.noneTargetView.rawValue
        parameters.merge(other: params)
        report(event: .ccmBitablePremiumPermissionRemoveConfirmClick, with: parameters)
      }
    public func reportBitablePremiumPermissionBackendUpgradeTipsView() {
        report(event: .ccmBitablePremiumPermissionBackendUpgradeTipsView, with: nil)
    }
    public func reportBitablePremiumPermissionCalculationTypeView(params: [String: Any]) {
        report(event: .ccmBitablePremiumPermissionCalculationTypeView, with: params)
    }
    public func reportBitablePremiumPermissionCalculationTypeClick(params: [String: Any]) {
        report(event: .ccmBitablePremiumPermissionCalculationTypeClick, with: params)
    }
}
// wiki单页面
extension PermissionStatistics {
    public func reportPermissionScopeChangeView() {
        report(event: .permissionScopeChangeView, with: nil)
    }

    public enum PermissionScopeViewTriggerLocation: String {
        case linkShare = "link_share"
        case permissionSet = "permission_set"
    }
    public enum PermissionScopeOption: String {
        case container = "current_and_child_page"
        case singlePage = "current_page"
    }
    public func reportPermissionScopeChangeClick(click: ClickAction,
                                                 triggerLocation: PermissionScopeViewTriggerLocation,
                                                 scopeOption: PermissionScopeOption,
                                                 isLock: Bool) {
        var parameters: [String: Any] = [:]
        parameters["click"] = click.rawValue
        parameters["target"] = .none
        parameters["permission_scope"] = scopeOption.rawValue
        parameters["trigger_location"] = triggerLocation.rawValue
        parameters["is_lock_notify"] = isLock ? "true" : "false"
        report(event: .permissionScopeChangeClick, with: parameters)
    }
    public func reportPermissionChangeShareLinkClick() {

    }
}

//文档密级管控
extension PermissionStatistics {
    /// 密级设置页面打开来源
    public enum SecuritySettingViewFrom: String {
        /// 密级banner
        case banner = "from_banner"
        /// More菜单里的密级设置项
        case moreMenu = "from_docs_more_menu"
        /// NavigationBar上的密级Icon
        case upperIcon = "from_left_upper"
        /// 权限设置
        case permSetting = "from_permission_setting"
    }
    
    /// 文档当前密级
    public enum SecuritySettingType {
        /// 当前文档没有设置密级
        case none
        /// 获取默认密级失败
        case failed
        /// 当前有密级时上报具体的密级id
        case normal(securityId: String)
    }
    
    /// 密级点击动作
    public enum SecurityClickAction: String {
        /// 设置密级
        case securitySetting = "security_setting"
        /// 了解更多
        case knowDetail = "know_detail"
        /// 确认修改密级
        case apply = "apply"
        /// 取消修改密级
        case cancel = "cancel"
        case checking = "checking"
        /// 查看密级权限
        case viewSecurityInfo = "view_security_info"
        /// 点击修改密级选项
        case clickSecurityLevel = "click_security_level"
    }
    
    public func reportPermissionSecuritySettingView(viewFrom: SecuritySettingViewFrom,
                                                    securityType: SecuritySettingType,
                                                    isSecurityDemotion: Bool,
                                                    isSingleApply: Bool) {
        var parameters: [String: Any] = [:]
        switch securityType {
        case .none:
            parameters["security_type"] = "none"
        case .failed:
            parameters["security_type"] = "acquisition_ailed"
        case .normal(let securityId):
            parameters["security_type"] = securityId
            parameters["security_id"] = securityId
        }
        parameters["view_from"] = viewFrom.rawValue
        parameters["is_security_demotion"] = isSecurityDemotion ? "true" : "false"
        parameters["is_single_apply"] = isSingleApply ? "true" : "false"
        report(event: .ccmPermissionSecuritySettingView, with: parameters)
    }

    public func reportPermissionSecuritySettingClick(context: ReportPermissionSecuritySettingClick, viewFrom: SecuritySettingViewFrom, click: SecurityClickAction,  securityType: SecuritySettingType) {
        var parameters: [String: Any] = [:]
        parameters["click"] = click.rawValue
        parameters["target"] = context.target
        switch securityType {
        case .none:
            parameters["security_type"] = "none"
        case .failed:
            parameters["security_type"] = "acquisition_ailed"
        case .normal(let securityId):
            parameters["security_type"] = securityId
            parameters["security_id"] = securityId
        }
        if !context.securityId.isEmpty {
            parameters["security_id"] = context.securityId
        }
        parameters["view_from"] = viewFrom.rawValue
        parameters["is_security_demotion"] = context.isSecurityDemotion ? "true" : "false"
        parameters["is_single_apply"] = context.isSingleApply ? "true" : "false"
        parameters["is_original_level"] = context.isOriginalLevel ? "true" : "false"
        report(event: .ccmPermissionSecuritySettingClick, with: parameters)
    }
    
    public func reportPermissionSecuritySettingClickModify(isHaveChangePerm: Bool) {
        var parameters: [String: Any] = [:]
        parameters["is_have_change_perm"] = isHaveChangePerm ? "true" : "false"
        report(event: .ccmPermissionSecuritySettingClick, with: parameters)
    }
    
    public func reportPermissionSecurityDemotionView(isCheckOpen: Bool) {
        var parameters: [String: Any] = [:]
        parameters["is_check_open"] = isCheckOpen ? "true" : "false"
        report(event: .ccmPermissionSecurityDemotionView, with: parameters)
    }

    public func reportPermissionSecurityDemotionClick(click: SecurityClickAction, target: String, isCheckOpen: Bool) {
        var parameters: [String: Any] = [:]
        parameters["click"] = click.rawValue
        parameters["target"] = target
        parameters["is_check_open"] = isCheckOpen ? "true" : "false"
        report(event: .ccmPermissionSecurityDemotionClick, with: parameters)
    }

    ///降级审批记录页
    public func reportCcmPermissionSecurityResubmitToastView(isSingleApply: Bool, viewFrom: String) {
        var parameters: [String: Any] = [:]
        parameters["view_from"] = viewFrom
        parameters["is_single_apply"] = isSingleApply ? "true" : "false"
        report(event: .ccmPermissionSecurityResubmitToastView, with: parameters)
    }
    ///降级审批记录页上的点击事件
    func reportCcmPermissionSecurityResubmitToastClick(click: String, target: String, isSingleApply: Bool, viewFrom: String) {
        var parameters: [String: Any] = [:]
        parameters["click"] = click
        parameters["is_single_apply"] = isSingleApply ? "true" : "false"
        parameters["view_from"] = viewFrom
        parameters["target"] = target
        report(event: .ccmPermissionSecurityResubmitToastClick, with: parameters)
    }
    ///重复提交申请提示弹窗
    func reportCcmPermissionSecurityDemotionResubmitView(isSingleApply: Bool, isIncludeOwn: Bool) {
        var parameters: [String: Any] = [:]
        parameters["is_single_apply"] = isSingleApply ? "true" : "false"
        parameters["is_include_own"] = isIncludeOwn ? "true" : "false"
        report(event: .ccmPermissionSecurityDemotionResubmitView, with: parameters)
    }
    ///重复提交申请提示弹窗上的点击
    func reportCcmPermissionSecurityDemotionResubmitClick(click: String, target: String, isSingleApply: Bool, isIncludeOwn: Bool) {
        var parameters: [String: Any] = [:]
        parameters["click"] = click
        parameters["is_single_apply"] = isSingleApply ? "true" : "false"
        parameters["is_include_own"] = isIncludeOwn ? "true" : "false"
        parameters["target"] = target
        report(event: .ccmPermissionSecurityDemotionResubmitClick, with: parameters)
    }
    ///密级降级修改结束后的弹窗
    func reportCcmPermissionSecurityDemotionResultView(ifSuccess: Bool) {
        var parameters: [String: Any] = [:]
        parameters["if_success"] = ifSuccess ? "true" : "false"
        report(event: .ccmPermissionSecurityDemotionResultView, with: parameters)
    }
    ///密级降级修改成功弹窗上的点击
    func reportCcmPermissionSecurityDemotionResultClick(click: String, target: String) {
        var parameters: [String: Any] = [:]
        parameters["click"] = click
        parameters["target"] = target
        report(event: .ccmPermissionSecurityDemotionResultClick, with: parameters)
    }

    ///导航栏密级按钮点击事件
    public func reportNavigationBarPermissionSecurityButtonClick() {
        var parameters: [String: Any] = [:]
        parameters["click"] = "security_setting"
        parameters["target"] = DocsTracker.EventType.ccmPermissionSecuritySettingView.rawValue
        report(event: .navigationBarClick, with: parameters)
    }
    
    ///more面板密级选项点击事件
    public func reportMoreMenuPermissionSecurityButtonClick() {
        var parameters: [String: Any] = [:]
        parameters["click"] = "security_setting"
        parameters["target"] = DocsTracker.EventType.ccmPermissionSecuritySettingView.rawValue
        report(event: .spaceDocsMoreMenuClick, with: parameters)
    }
    
    ///文档设置页面的密级入口点击事件
    public func reportPermissionSetPermissionSecurityButtonClick() {
        var parameters: [String: Any] = [:]
        parameters["click"] = "security_setting"
        parameters["target"] = DocsTracker.EventType.ccmPermissionSecuritySettingView.rawValue
        report(event: .permissionSetClick, with: parameters)
    }
    
    ///用户未确认密级（文档有默认密级，但未获得用户确认）或未设置密级时，文档详情上方新增banner提示view
    public func reportPermissionSecurityDocsBannerView(hasDefaultSecretLevel: Bool) {
        var parameters: [String: Any] = [:]
        parameters["triggle_reason"] = hasDefaultSecretLevel ? "have_default_no_setting" : "no_default_no_setting"
        report(event: .ccmPermissionSecurityDocsBannerView, with: parameters)
    }
    
    ///推荐打标出现时上报
    public func reportPermissionRecommendBannerView(isCompulsoryLabeling: Bool) {
        var parameters: [String: Any] = [:]
        parameters["is_compulsory_labeling"] = isCompulsoryLabeling ? "true" : "false"
        report(event: .scsFileRecommendedLabelBannerView, with: parameters)
    }
    
    ///推荐打标发生动作时上报
    public func reportPermissionRecommendBannerViewAction(isCompulsoryLabeling: Bool, action: String) {
        var parameters: [String: Any] = [:]
        parameters["is_compulsory_labeling"] = isCompulsoryLabeling ? "true" : "false"
        parameters["click"] = action
        report(event: .scsFileRecommendedLabelBannerClick, with: parameters)
    }
    ///用户未确认密级（文档有默认密级，但未获得用户确认）或未设置密级时，文档详情上方新增banner提示view上的点击
    public func reportPermissionSecurityDocsBannerClick(hasDefaultSecretLevel: Bool, action: SecurityClickAction) {
        var parameters: [String: Any] = [:]
        parameters["triggle_reason"] = hasDefaultSecretLevel ? "have_default_no_setting" : "no_default_no_setting"
        parameters["click"] = action.rawValue
        parameters["target"] = action == .securitySetting ? DocsTracker.EventType.ccmPermissionSecuritySettingView.rawValue : DocsTracker.EventType.noneTargetView.rawValue
        report(event: .ccmPermissionSecurityDocsBannerClick, with: parameters)
    }
}

//内嵌文档授权
///https://bytedance.feishu.cn/wiki/wikcn6NkIe4N9Nwj3e4TmTEXJKh?sheet=e4pzDu
extension PermissionStatistics {
    
    public enum PermissionCitedDocAuthorizeClickType {
        case allCancel
        case cancel
        case cancelAuthorize(objctId: String)
        case authorize(isAskOwner: Bool, objctId: String)
        case back
        case allAuthorize
    }
    
    enum PermissionCitedDocAuthorizePopUpType: String {
        case allAuthorize = "all_authorize"
        case allCancel = "all_cancel"
    }
    
    public func reportPermissionCitedDocAuthorizeView(isGroupChat: Bool) {
        var parameters: [String: Any] = [:]
        parameters["is_group_chat"] = isGroupChat ? "true" : "false"
        report(event: .ccmPermissionCitedDocAuthorizeView, with: parameters)
    }

    public func reportPermissionCitedDocAuthorizeClick(clickType: PermissionCitedDocAuthorizeClickType, isGroupChat: Bool) {
        var parameters: [String: Any] = [:]
        switch clickType {
        case .allCancel:
            parameters["click"] = "all_cancel"
            parameters["target"] = DocsTracker.EventType.noneTargetView.rawValue
        case .cancel:
            parameters["click"] = "cancel"
            parameters["target"] = DocsTracker.EventType.noneTargetView.rawValue
        case .cancelAuthorize(let objctId):
            parameters["click"] = "cancel_authorize"
            parameters["target"] = DocsTracker.EventType.noneTargetView.rawValue
            parameters["object_id"] = DocsTracker.encrypt(id: objctId)
        case .authorize(let isAskOwner, let objctId):
            parameters["click"] = "authorize"
            parameters["object_id"] = DocsTracker.encrypt(id: objctId)
            parameters["target"] = isAskOwner ? DocsTracker.EventType.permissionAskOwnerView.rawValue : DocsTracker.EventType.noneTargetView.rawValue
        case .back:
            parameters["click"] = "back"
            parameters["target"] = DocsTracker.EventType.noneTargetView.rawValue
        case .allAuthorize:
            parameters["click"] = "all_authorize"
            parameters["target"] = DocsTracker.EventType.noneTargetView.rawValue
        }
        parameters["is_group_chat"] = isGroupChat ? "true" : "false"
        report(event: .ccmPermissionCitedDocAuthorizeClick, with: parameters)
    }
    
    func reportPermissionCitedDocAllAuthorizeView(popUpType: PermissionCitedDocAuthorizePopUpType,
                                                  citedDocNum: Int,
                                                  isGroupChat: Bool) {
        var parameters: [String: Any] = [:]
        parameters["pop_up_type"] = popUpType.rawValue
        parameters["cited_doc_num"] = citedDocNum
        parameters["is_group_chat"] = isGroupChat ? "true" : "false"
        report(event: .ccmPermissionCitedDocAllAuthorizeView, with: parameters)
    }
    
    func reportPermissionCitedDocAllAuthorizeClick(isConfirm: Bool,
                                                  popUpType: PermissionCitedDocAuthorizePopUpType,
                                                  citedDocNum: Int,
                                                  isGroupChat: Bool) {
        var parameters: [String: Any] = [:]
        parameters["click"] = isConfirm ? "confirm" : "cancel"
        parameters["target"] = DocsTracker.EventType.noneTargetView.rawValue
        parameters["pop_up_type"] = popUpType.rawValue
        parameters["cited_doc_num"] = citedDocNum
        parameters["is_group_chat"] = isGroupChat ? "true" : "false"
        report(event: .ccmPermissionCitedDocAllAuthorizeClick, with: parameters)
    }
    
    public func reportDlpSecurityBannerHintView() {
        var parameters: [String: Any] = [:]
        parameters["is_owner"] = "true"
        parameters["is_magic_share"] = ccmCommonParameters.appForm == "vc" ? "true" : "false"
        report(event: .ccmDlpSecurityBannerHintView, with: parameters)
    }
    
    public func reportDlpSecurityBannerHintClick(isClose: Bool) {
        var parameters: [String: Any] = [:]
        parameters["is_owner"] = "true"
        parameters["click"] = isClose ? "close" : "dlp_referral"
        parameters["is_magic_share"] = ccmCommonParameters.appForm == "vc" ? "true" : "false"
        report(event: .ccmDlpSecurityBannerHintClick, with: parameters)
    }
    
    public func reportDlpSecurityInterceptToastView(action: DlpCheckAction,
                                                    status: DlpCheckStatus,
                                                    isSameTenant: Bool) {
        var parameters: [String: Any] = [:]
        parameters["trigger_reason"] = action.rawValue
        parameters["is_tenant_cross"] = isSameTenant ? "false" : "true"
        switch status {
        case .Detcting:
            parameters["trigger_opportunity"] = "before_checked"
        case .Sensitive, .Block, .Unknow:
            parameters["trigger_opportunity"] = "after_checked"
        case .Safe:
            return
        }
        report(event: .ccmDlpSecurityInterceptToastView, with: parameters)
    }
    
    public func reportDlpSecurityInterceptToastView(action: DlpCheckAction, dlpError: Error?) {
        guard let realError = dlpError as? DocsNetworkError else {
            return
        }
        reportDlpSecurityInterceptToastView(action: action, dlpErrorCode: realError.code.rawValue)
    }
    
    public func reportDlpSecurityInterceptToastView(action: DlpCheckAction, dlpErrorCode: Int) {
        guard let dlpErrorCode = DlpErrorCode(rawValue: dlpErrorCode) else {
            return
        }
        let isSameTenant: Bool
        let isBeforeChecked: Bool
        switch dlpErrorCode {
        case .dlpSameTenatDetcting:
            isSameTenant = true
            isBeforeChecked = true
        case .dlpExternalDetcting:
            isSameTenant = false
            isBeforeChecked = true
        case .dlpSameTenatSensitive:
            isSameTenant = true
            isBeforeChecked = false
        case .dlpExternalSensitive:
            isSameTenant = false
            isBeforeChecked = false
        }
        var parameters: [String: Any] = [:]
        parameters["trigger_reason"] = action.rawValue
        parameters["is_tenant_cross"] = isSameTenant ? "false" : "true"
        parameters["trigger_opportunity"] = isBeforeChecked ? "before_checked" : "after_checked"
        report(event: .ccmDlpSecurityInterceptToastView, with: parameters)
    }
    
    public func reportDlpInterceptResultView(action: DlpCheckAction, status: DlpCheckStatus) {
        var parameters: [String: Any] = [:]
        parameters["trigger_reason"] = action.rawValue
        parameters["is_default"] = "false"
        if status == .Sensitive {
            parameters["result"] = "false"
            parameters["intercept_reason"] = "DLP"
        } else {
            parameters["result"] = "true"
        }
        report(event: .ccmDlpInterceptResultView, with: parameters)
    }
    
    public func reportPermissionAutomaticPermView() {
        let parameters = [
            "toast_source": "superior_management_set"
        ]
        report(event: .ccmPermissionAutomaticPermView, with: parameters)
    }
    
    public enum PermissionAutomaticPermClickType: String {
        case securitySet = "security_set"
        case knowDetail = "know_detail"
        case noneRemind = "none_remind"
    }
    
    public func reportPermissionAutomaticPermClick(click: PermissionAutomaticPermClickType) {
        let parameters = [
            "toast_source": "superior_management_set",
            "click": click.rawValue,
            "target": DocsTracker.EventType.noneTargetView.rawValue
        ]
        report(event: .ccmPermissionAutomaticPermClick, with: parameters)
    }
    
    public func reportPermissionAutomaticPermFinishView() {
        report(event: .ccmPermissionAutomaticPermFinishView, with: nil)
    }

    public func reportImUrlRenderClick() {
        let parameters = [
            "component_id": "secretSetting",
            "click": "page_click",
            "target": DocsTracker.EventType.noneTargetView.rawValue
        ]
        report(event: .imUrlRenderClick, with: parameters)
    }
}

extension PermissionStatistics {
    public func reportBlockNotifyAlertView() {
        report(event: .permissionBlockNotifyAlertView, with: nil)
    }
    
    public func reportBlockNotifyAlertClick() {
        let params: [String: Any] = ["click": "known", "target": "none"]
        report(event: .permissionBlockNotifyAlertClick, with: params)
    }
}
