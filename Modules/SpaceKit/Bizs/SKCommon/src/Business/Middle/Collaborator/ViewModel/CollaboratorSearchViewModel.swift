//
//  CollaboratorSearchViewModel.swift
//  SKCommon
//
//  Created by liweiye on 2020/9/1.
//

import Foundation
import SKFoundation
import SwiftyJSON
import RxSwift
import RxCocoa
import SKResource
import UniverseDesignIcon
import UniverseDesignColor
import SKInfra

public final class CollaboratorSearchViewModel {

    // UI 数据
    var invitationDatas: [CollaboratorInvitationCellItem] = []
    var existedCollaborators: [Collaborator] = []
    var selectedItems = [Collaborator]()
    var naviBarTitle: String
    private(set) var fileModel: CollaboratorFileModel
    let lastPageLabel: String? // 协作者请求的分页参数，传入就代表之前在 entry panel 请求到的协作者数据不完整，需要这边继续请求剩余的协作者
    private let permissionManager = DocsContainer.shared.resolve(PermissionManager.self)!
    // 网络请求
    private var fetchVisibleUserGroupRequest: DocsRequest<JSON>?
    private(set) var visibleUserGroups: [Collaborator] = []
    private let isInVideoConference: Bool

    var userPermissions: UserPermissionAbility?
    var publicPermisson: PublicPermissionMeta?

    var shouldShowInvitationTableView: Bool {
        return !self.invitationDatas.isEmpty
    }
    var invitationTableViewHeight: Int {
        return 52 * self.invitationDatas.count
    }

    lazy var inviteModeConfig: CollaboratorInviteModeConfig = {
        return CollaboratorInviteModeConfig.config(with: self.publicPermisson,
                                                       userPermisson: self.userPermissions,
                                                       isBizDoc: fileModel.docsType.isBizDoc)
    }()

    public private(set) var isBitableAdvancedPermissions: Bool = false
    private(set) var bitablePermissonRule: BitablePermissionRule?

    private var inviteSource: CollaboratorInviteSource

    var invitationDataChanged: (() -> Void)?
    
    /// 知识库成员
    let wikiMembers: [Collaborator]?
    
    var isEmailSharingEnabled: Bool {
        let enabledDocType: [ShareDocsType] = [.doc, .sheet, .bitable, .mindnote, .wiki, .docX, .file, .slides, .sync]
        let isEnabledType = enabledDocType.contains(where: { $0 == fileModel.docsType })
        let isV2 = fileModel.spaceSingleContainer || fileModel.wikiV2SingleContainer
        if UserScopeNoChangeFG.PLF.mailSharingEnable && isV2 && isEnabledType && !isBitableAdvancedPermissions && !isInVideoConference {
            return true
        }
        return false
    }

    public init(existedCollaborators: [Collaborator],
                selectedItems: [Collaborator],
                wikiMembers: [Collaborator]? = nil,
                fileModel: CollaboratorFileModel,
                lastPageLabel: String?,
                statistics: CollaboratorStatistics? = nil,
                userPermission: UserPermissionAbility?,
                publicPermisson: PublicPermissionMeta?,
                inviteSource: CollaboratorInviteSource = .sharePanel,
                isBitableAdvancedPermissions: Bool = false,
                bitablePermissonRule: BitablePermissionRule? = nil,
                isInVideoConference: Bool = false) {
        self.fileModel = fileModel
        self.existedCollaborators = existedCollaborators
        self.selectedItems = selectedItems
        self.wikiMembers = wikiMembers
        self.lastPageLabel = lastPageLabel
        self.inviteSource = inviteSource
        self.isInVideoConference = isInVideoConference
        if fileModel.isForm {
            self.naviBarTitle = BundleI18n.SKResource.Bitable_Form_AddCollaborator
        } else if fileModel.isBitableSubShare {
            self.naviBarTitle = BundleI18n.SKResource.Bitable_Share_AddViewers_Title
        } else {
            self.naviBarTitle = BundleI18n.SKResource.LarkCCM_Docs_InviteCollaborators_Menu_Mob
        }
        self.requestRemainingCollaboratorsIfNedd()
        self.userPermissions = userPermission
        self.publicPermisson = publicPermisson
        self.isBitableAdvancedPermissions = isBitableAdvancedPermissions
        self.bitablePermissonRule = bitablePermissonRule
        initInvitationDatas()
        initUserGroupData()
    }

    private func initInvitationDatas() {
        // 组织架构FG
        if CollaboratorUtils.addDepartmentEnable(source: inviteSource, docsType: fileModel.docsType) {
            let organizationItem = CollaboratorInvitationCellItem(cellType: .organization,
                                                                  title: BundleI18n.SKResource.Doc_Permission_AddUserSelctDepartmentTitle,
                                                                  iconImage: BundleResources.SKResource.Common.Collaborator.icon_organization_outlined)
            invitationDatas.append(organizationItem)
        }
    }

    private func initUserGroupData() {
        let isSingleContainer = fileModel.spaceSingleContainer || fileModel.wikiV2SingleContainer
        let placeholderContext = CollaboratorUtils.PlaceHolderContext(
            source: inviteSource,
            docsType: fileModel.docsType,
            isForm: fileModel.isForm,
            isBitableAdvancedPermissions: isBitableAdvancedPermissions,
            isSingleContainer: isSingleContainer,
            isSameTenant: fileModel.isSameTenantWithOwner,
            isEmailSharingEnabled: isEmailSharingEnabled)
        let userGroupEnable = CollaboratorUtils.addUserGroupEnable(context: placeholderContext)
        guard userGroupEnable else {
            return
        }
        let params: [String: Any]
        // 发请求拉可见用户组
        if UserScopeNoChangeFG.TYP.permissionUserGroup {
            params = ["scene_type": 1,
                     "group_type": 0]
        } else {
            params = ["scene_type": 1]
        }
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.fetchVisibleUserGroup, params: params)
            .set(method: .GET)
        fetchVisibleUserGroupRequest = request
        request.start { [weak self] data, error in
            if let error = error {
                DocsLogger.error("fetch visible user group failed", error: error)
                return
            }
            guard let self = self else { return }
            guard let data = data,
                  let groupsData = data["data"]["visible_groups"].array else {
                      DocsLogger.info("cannot get user group")
                      return
                  }
            let groups = groupsData.compactMap { json -> Collaborator? in
                guard let name = json["name"].string,
                      let groupID = json["group_id"].string else {
                          return nil
                }
                let groupType = json["group_type"].int ?? UserGroupType.userGroupDynamic.rawValue
                let userGroupType = UserGroupType(rawValue: groupType) ?? .userGroupDynamic
                return Collaborator(rawValue: userGroupType.collaboratorType,
                                    userID: groupID, name: name,
                                    avatarURL: "https://lf3-static.bytednsdoc.com/obj/eden-cn/bfupeups/icon/icon_user_group.png",
                                    avatarImage: nil,
                                    imageKey: "",
                                    userPermissions: UserPermissionMask(rawValue: 1),
                                    groupDescription: nil)
            }
            self.handle(visibleUserGroups: groups)
        }
    }

    public func handle(visibleUserGroups: [Collaborator]) {
        // 这个函数之前没单元测试导致覆盖率问题，临时加上public补一下覆盖问题
        // Forms 邀请填写者页面不显示用户组入口
        if fileModel.notShowUserGroupCell { return }
        guard !visibleUserGroups.isEmpty else { return }
        self.visibleUserGroups = visibleUserGroups
        let userGroupItem = CollaboratorInvitationCellItem(cellType: .userGroup,
                                                           title: BundleI18n.SKResource.CreationMobile_ECM_Add_UserGroup_Tab,
                                                           iconImage: UDIcon.groupOutlined.ud.withTintColor(UDColor.colorfulPurple))
        self.invitationDatas.append(userGroupItem)
        invitationDataChanged?()
    }

    // 请求剩余的协作者
    private func requestRemainingCollaboratorsIfNedd() {
        guard let pageLabel = lastPageLabel else {
            DocsLogger.error("pageLabel or fileInfo is nil!")
            return
        }
        permissionManager.fetchCollaborators(
            token: fileModel.objToken,
            type: fileModel.docsType.rawValue,
            shouldFetchNextPage: true,
            lastPageLabel: pageLabel,
            collaboratorSource: .defaultType
        ) { [weak self, unowned permissionManager] _, error in
            guard let self = self else { return }
            guard error == nil else {
                DocsLogger.error("fetchCollaborators failed!", extraInfo: nil, error: error, component: nil)
                return
            }
            guard let updatedCollaborators = permissionManager.getCollaborators(for: self.fileModel.objToken,
                                                                                collaboratorSource: .defaultType) else {
                DocsLogger.error("getCollaborators failed!")
                return
            }
            self.existedCollaborators = updatedCollaborators
        }
    }

    func requestUserPermission() {
        guard fileModel.docsType == .folder else {
            DocsLogger.info("docType is not folder or invalid file")
            return
        }
        
        if fileModel.spaceSingleContainer {
            requestShareFolderUserPermission()
        } else if fileModel.isOldShareFolder, !fileModel.spaceID.isEmpty {
            requestUserPermissionForShareFolder(fileModel.spaceID)
        } else if fileModel.isCommonFolder {//我的文件夹默认有编辑权限
            userPermissions = UserPermissionMask.mockPermisson()
        } else {
            DocsLogger.info("folder is not old share folder or spaceID is nil")
        }
    }

    private func requestShareFolderUserPermission() {
        let token = fileModel.objToken
        permissionManager.requestShareFolderUserPermission(token: token, actions: []) { [weak self] (permissions, error) in
            guard let self = self else { return }
            guard let permissions = permissions, error == nil else {
                DocsLogger.error("CollaboratorSearchViewModel fetch share folder user permission failed (sc)", error: error, component: LogComponents.permission)
                return
            }
            DocsLogger.info("CollaboratorSearchViewModel fetch share folder user permission success (sc)", component: LogComponents.permission)
            self.userPermissions = permissions
        }
    }
    
    private func requestUserPermissionForShareFolder(_ spaceID: String) {
        permissionManager.getShareFolderUserPermissionRequest(spaceID: spaceID, token: fileModel.objToken) { [weak self] (permissions, error) in
            guard (error as? URLError)?.errorCode != NSURLErrorCancelled else { return }
            guard let permissions = permissions, error == nil else { return }
            self?.userPermissions = permissions
        }
    }
}
