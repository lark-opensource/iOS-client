//
//  CollaboratorAnalytics.swift
//
//  Created by wangxin.sidney on 2018/5/22.
//

import Foundation
import SKFoundation
import SKInfra

/// Doc information that analytics use.
public struct CollaboratorAnalyticsFileInfo {
    let fileType: String
    let fileId: String

    public init(fileType: String, fileId: String) {
        self.fileType = fileType
        self.fileId = fileId
    }
}

enum GroupType: String {
    case search
    case recent
}

enum PermType: String {
    case edit
    case view
    case erase
}

enum CollaboratorActionType: String {
    case delete
    case change
    case add
}

// 埋点文档: https://bytedance.feishu.cn/docs/doccnW72InKkSsIKGxg00DiT5Tf#
public enum AuthErrorReason: String {
    case block
    case blocked
    case privacySetting = "privacy_setting"
    case adminSetting = "admin_setting"
    case moreThenLimited = "more_then_limited"
    case phoneInviteLimited = "phone_invite_limited"
    case others
}

public enum AuthErrorLocation: String {
    case invitedCollaborateBefore = "invited_collaborate_before"
    case invitedCollaborateAfter = "invited_collaborate_after"
    case mention
    case comment
    case embed
    case applyPermission = "apply_permission"
    case askOwner = "ask_owner"
    case sendLink = "send_link"
    case others
}

/// 协作者编辑的统计能力
protocol CollaboratorEditReportAbility {
    func reportShowingInvitePage()
    func reportShowCollaborateSettingPage()
    func clickedInvitingSearchBar(tenantParams: [String: String])
    func clickSelectPermInviter(groupType: GroupType, userType: CollaboratorStatistics.UserType, tenantParams: [String: String], collaboratorParams: [String: String])
    func clickCollaborateInviterNextStep(tenantParams: [String: String])
    func clickAlterCollaboratePerm(permType: PermType, tenantParams: [String: String], collaboratorParams: [String: String])
    func clickSendInviteBtn(info: CollaboratorStatistics.InviteDetail)
}

// 手机号分享的统计能力
protocol CollaboratorPhoneSearchAbility {
    func clickSwitchCountryCode()
}

// 联系人二期的统计能力
protocol CollaboratorContactV2Ability {
    func clickShareSearchResult(memberId: String, relationType: Bool)
    func clientAuthError(reason: AuthErrorReason, location: AuthErrorLocation)
}

/// 协作者入口的统计能力
public protocol CollaboratorManagerPanelReportAbility: AnyObject {
    func clickedAddCollaborate(tenantParams: [String: String])
}

/// Analytics helper class for collaborators
public final class CollaboratorStatistics {
    enum UserType: String {
        case user
        case chat
    }

    struct InviteDetail {
        var userCont = 0
        var charCount = 0
        var organizationCount = 0
        var larkInform = false
        var statusCode = 0
        var statusName = ""
        var tenantParams = [String: String]()
        var collaboratorParams = [String: String]()
        /// 分享目标用户id
        var collaborateId: String?
        /// 分享目标用户类型
        var collaborateType: String?
        /// 分享目标用户租户id
        var collaborateTenantId: String?
        /// 参数-被邀请用户账户类型
        var touserAccountType: String?
        /// 被邀请用户授权后权限
        var permSetAfter: String?
        /// 分享方式
        var shareMethodType: String?
        /// 是否是好友关系
        var relationType: String?
    }

    let docInfo: CollaboratorAnalyticsFileInfo
    let module: String

    public init(docInfo: CollaboratorAnalyticsFileInfo, module: String) {
        self.docInfo = docInfo
        self.module = module
    }

    private func report(event: DocsTracker.EventType, with extra: [AnyHashable: Any]?) {
        // have comunicated with tangyipeng, omited many parameters comparing with android
        var parameters: [AnyHashable: Any] = [AnyHashable("file_type"): docInfo.fileType,
                                             AnyHashable("file_id"): DocsTracker.encrypt(id: docInfo.fileId)]
        if let extraMap = extra {
            for item in extraMap {
                parameters[item.key] = item.value
            }
        }
        DocsTracker.log(enumEvent: event, parameters: parameters)
    }

    public static func getCollaboratorParams(tenantId: String?) -> [String: String] {
        var params = [String: String]()
        guard let tenantId = tenantId else { return params }
        params["collab_tenant_id"] = DocsTracker.encrypt(id: tenantId)
        params["collab_is_cross_tenant"] = (tenantId != User.current.info?.tenantID) ? "true" : "false"
        return params
    }

    public static func getTenantParams(ownerId: String?) -> [String: String] {
        var params = [String: String]()
        let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self)
        if let ownerID = ownerId, let fileTenantID = dataCenterAPI?.userInfo(for: ownerID)?.tenantID {
            params["file_tenant_id"] = DocsTracker.encrypt(id: fileTenantID)
            let isCrossTenant = fileTenantID == User.current.info?.tenantID ? "false" : "true"
            params["file_is_cross_tenant"] = isCrossTenant
        }
        return params
    }
}

extension CollaboratorStatistics: ShareAssistReportAbility {
    /// report having shown the share page in bottom
    public func reportShowSharePage() {
        report(event: .showSharePage, with: nil)
    }

    /// report sharing actions
    public func reportDidShare(to: ShareAssistType, params: [String: String]) {
        var platform = "lark"
        switch to {
        case .feishu:
            platform = "lark"
        case .fileLink:
            platform = "copy"
        case .passwordLink:
            platform = "copy"
        case .snapshot:
            platform = "gene_long_image"
        case .more:
            platform = "more"
        case .wechat:
            platform = "wechat"
        case .wechatMoment:
            platform = "weixin_article"
        case .qq:
            platform = "qq"
        case .weibo:
            platform = "weibo"
        case .qrcode:
            platform = "click_qrcode"
        default: ()
        }
        var extra = [AnyHashable("to_platform"): platform]
        
        extra.merge(other: params)
        report(event: .share, with: extra)
    }
}

extension CollaboratorStatistics: CollaboratorManagerPanelReportAbility {
    /// report clicking plus button to add collaborator
    public func clickedAddCollaborate(tenantParams: [String: String]) {
        report(event: .clickAddCollaborate, with: tenantParams)
    }
}

extension CollaboratorStatistics: CollaboratorEditReportAbility {

    /// report showing inviting page
    func reportShowingInvitePage() {
        report(event: .showInviteItemPage, with: nil)
    }

    /// report showing collaborators list page
    func reportShowCollaborateSettingPage() {
        report(event: .showCollaborateSettingPage, with: nil)
    }

    /// report clicked search bar in inviting user page
    func clickedInvitingSearchBar(tenantParams: [String: String]) {
        report(event: .clickInviteSearchBar, with: tenantParams)
    }

    func clickSelectPermInviter(groupType: GroupType, userType: CollaboratorStatistics.UserType, tenantParams: [String: String], collaboratorParams: [String: String]) {
        var params: [String: Any] = ["group": groupType.rawValue,
                                        "collaborate_type": userType.rawValue]
        params.merge(other: tenantParams)
        params.merge(other: collaboratorParams)
        report(event: .clickSelectPermInviter, with: params)
    }

    func clickCollaborateInviterNextStep(tenantParams: [String: String]) {
        report(event: .clickCollaborateInviterNextStep, with: tenantParams)
    }
    
    func clickShowCollaborateSearch(tenantParams: [String: String]) {
        report(event: .clickAddCollaborate, with: tenantParams)
    }

    func clickAlterCollaboratePerm(permType: PermType, tenantParams: [String: String], collaboratorParams: [String: String]) {
        var params: [String: Any] = ["perm_type": permType.rawValue]
        params.merge(other: tenantParams)
        params.merge(other: collaboratorParams)
        report(event: .clickAlterCollaboratePerm, with: params)
    }

    func clickEraseCollaboratePermPopup(permission: Collaborator, fileInfo:
                                                                (createTime: TimeInterval,
                                                                 createDate: String,
                                                                 creatorID: String)) {
        var params: [String: Any] = ["action": "popup"]
        params.merge(other: getEraseCollaboratePermParams(permission, fileInfo: fileInfo))
        report(event: .clickEraseCollaboratePerm, with: params)
    }

    func clickEraseCollaboratePermConfirm(permission: Collaborator, fileInfo:
                                                                    (createTime: TimeInterval,
                                                                    createDate: String,
                                                                    creatorID: String)) {
        var params: [String: Any] = ["action": "confirm_remove"]
        params.merge(other: getEraseCollaboratePermParams(permission, fileInfo: fileInfo))
        report(event: .clickEraseCollaboratePerm, with: params)
    }

    private func getEraseCollaboratePermParams(_ permission: Collaborator,
                                               fileInfo:
                                                (createTime: TimeInterval,
                                                 createDate: String,
                                                 creatorID: String)) -> [String: Any] {
        var params: [String: Any] = [:]
        params["is_owner"] = permission.isOwner ? "true" : "false"
        if fileInfo.createTime > 0 {
            params["create_time"] = String(fileInfo.createTime)
        }
        if !fileInfo.createDate.isEmpty {
            let createDate = fileInfo.createDate
            params["create_date"] = createDate
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd"
            if let date = dateFormatter.date(from: createDate) {
                let sinceNow = date.timeIntervalSinceNow
                params["from_create_date"] = Int(ceil(sinceNow / 60 / 60 / 24))
            }
        }
        if !fileInfo.creatorID.isEmpty {
            params["create_uid"] = DocsTracker.encrypt(id: fileInfo.creatorID)
                
        }
        params["collaborate_id"] = permission.userID
        /// collaborate_type
        if let type = permission.type {
            if type == .user || type == .larkUser {
                params["collaborate_type"] = "user"
            } else if type == .group {
                params["collaborate_type"] = "chat"
            } else if type == .folder {
                params["collaborate_type"] = "share_space"
            } else if type == .meeting {
                params["collaborate_type"] = "calendar_event"
            }
        }
        params["erase_before_perm"] = "edit_perm"
        return params
    }

    //进入发送链接页面
    func openSendLinkPageStatis(source: String,
                                module: String,
                                fileType: String,
                                fileId: String) {
        let params: [String: Any] = ["source": source,
                                     "module": module,
                                     "file_type": fileType,
                                     "file_id": DocsTracker.encrypt(id: fileId)]
        report(event: .showSendlinkPage, with: params)

    }

    //无分享权限、链接分享on 发送链接
    func sendLinkForInviteCollaboratorStatistics(source: String,
                                                 module: String,
                                                 fileType: String,
                                                 fileId: String) {
        let params: [String: Any] = ["source": source,
                                     "module": module,
                                     "file_type": fileType,
                                     "file_id": DocsTracker.encrypt(id: fileId)]
        report(event: .clickToSendLinkOperation, with: params)
    }
    //进入请求所有者共享页面
    func openAskOwnerPageStatistics(source: String,
                                    module: String,
                                    fileType: String,
                                    fileId: String) {
        let params: [String: Any] = ["source": source,
                                     "action": "share",
                                     "module": module,
                                     "file_type": fileType,
                                     "file_id": DocsTracker.encrypt(id: fileId)]
        report(event: .showAskOwnerpage, with: params)
    }

    //无分享权限、链接分享off 请求所有者共享
    func askOwnerForInviteCollaboratorStatistics(source: String,
                                                 module: String,
                                                 fileType: String,
                                                 fileId: String) {
        let params: [String: Any] = ["source": source,
                                     "action": "share",
                                     "module": module,
                                     "file_type": fileType,
                                     "file_id": DocsTracker.encrypt(id: fileId)]
        report(event: .clickToAskOwnerOperation, with: params)
    }

    //改造来自旧的接口
    func clickSendInviteBtn(info: CollaboratorStatistics.InviteDetail) {
        var params: [String: Any] = ["collaborate_user_count": String(info.userCont),
                                     "collaborate_chat_count": String(info.charCount),
                                     "lark_inform": info.larkInform ? "true" : "false",
                                     "status_code": String(info.statusCode),
                                     "status_name": info.statusName,
                                     "product": DocsSDK.isInLarkDocsApp ? "spur" : "suite",
                                     "fromuser_collaborate_tenant_id": User.current.info?.tenantID as Any,
                                     "collaborate_id": info.collaborateId as Any,
                                     "collaborate_type": info.collaborateType as Any,
                                     "collaborate_tenant_id": info.collaborateTenantId as Any,
                                     "touser_account_type": info.touserAccountType as Any,
                                     "perm_set_after": info.permSetAfter as Any]
        params.merge(other: info.tenantParams)
        params.merge(other: info.collaboratorParams)
        report(event: .clickSendInviteBtn,
               with: params)
    }

    func clickEditRoleType(actionType: CollaboratorActionType, isCreate: Bool, objToken: String, collaborator: Collaborator) {
        let userTenantID = User.current.info?.tenantID
        var params: [String: Any] = ["file_tenant_id": DocsTracker.encrypt(id: userTenantID ?? ""),
                                     "role": "manager",
                                     "file_id": DocsTracker.encrypt(id: objToken),
                                     "file_type": "share_folder",
                                     "member_type": collaborator.type ?? "",
                                     "member_id": DocsTracker.encrypt(id: collaborator.userID)
        ]
        let changeParam = ["action": "change"]
        let deleteParam = ["action": "delete"]
        let addParam = ["action": "add"]
        switch actionType {
        case .change:
            params.merge(other: changeParam)
        case .delete:
            params.merge(other: deleteParam)
        case .add:
            params.merge(other: addParam)
        }
        let createParam = ["scene": "create_folder"]
        let manageParam = ["scene": "folder_manage"]
        if isCreate {
            params.merge(other: createParam)
        } else {
            params.merge(other: manageParam)
        }
        report(event: .shareFolderMember, with: params)
    }

    enum SearchType: String {
        case phone
        case nickname
    }

    func clickSearchInviter(resultUserIds: [String],
                            resultUserTypes: [String],
                            searchType: SearchType) {
        let params: [String: Any] = ["searchresult_user_id": resultUserIds.map({ DocsTracker.encrypt(id: $0) }).joined(separator: ","),
                                     "search_type": searchType.rawValue,
                                     "searchresult_user_type": resultUserTypes.joined(separator: ","),
                                     "product": DocsSDK.isInLarkDocsApp ? "spur" : "suite"]
        report(event: .clickSearchInviter, with: params)
    }
}

extension CollaboratorStatistics: CollaboratorPhoneSearchAbility {

    func clickSwitchCountryCode() {
        let params: [String: Any] = [:]
        report(event: .clickSwitchCountryCode, with: params)
    }
}

extension CollaboratorStatistics: CollaboratorContactV2Ability {

    func clickShareSearchResult(memberId: String, relationType: Bool) {
        let params: [String: Any] = ["member_id": DocsTracker.encrypt(id: memberId),
                                     "relation_type": String(relationType)]
        report(event: .clickShareSearchResult, with: params)
    }

    func clientAuthError(reason: AuthErrorReason, location: AuthErrorLocation) {
        let params: [String: Any] = ["file_id": DocsTracker.encrypt(id: docInfo.fileId),
                                     "reason": reason.rawValue,
                                     "module": module,
                                     "location": location.rawValue]
        report(event: .clientAuthError, with: params)
    }
}
