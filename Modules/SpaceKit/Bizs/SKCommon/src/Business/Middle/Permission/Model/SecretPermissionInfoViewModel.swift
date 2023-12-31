//
//  SecretPermissionInfoViewModel.swift
//  SKCommon
//
//  Created by tanyunpeng on 2023/4/20.
//  


import Foundation
import SKFoundation
import SKInfra
import SwiftyJSON
import SKResource



public final class SecretPermissionInfoViewModel {
    //表头数据
    var cols: [String] = []
    
    var rowsValue: [[DataEntity]] = []
    public private(set) var dataSource: [SecretLevelItem] = []
    private var fetchLabelListRequest: DocsRequest<JSON>?
    public let level: SecretLevel
    public let token: String
    public private(set) var wikiToken: String?
    public let type: Int
    public private(set) var permStatistic: PermissionStatistics?
    public private(set) var userPermission: UserPermissionAbility?
    private let viewFrom: PermissionStatistics.SecuritySettingViewFrom
    private let securityType: PermissionStatistics.SecuritySettingType
    public private(set) var labelList: SecretLevelLabelList?
    
    public init(level: SecretLevel, wikiToken: String?, token: String, type: Int, permStatistic: PermissionStatistics?, viewFrom: PermissionStatistics.SecuritySettingViewFrom) {
        self.level = level
        self.wikiToken = wikiToken
        self.token = token
        self.type = type
        self.permStatistic = permStatistic
        self.userPermission = DocsContainer.shared.resolve(PermissionManager.self)?.getUserPermissions(for: token)
        self.viewFrom = viewFrom
        switch level.code {
        case .success:
            self.securityType = .normal(securityId: DocsTracker.encrypt(id: level.label.id))
        case .createFail, .requestFail:
            self.securityType = .failed
        default:
            self.securityType = .none
        }
    }
    public func request(completion: ((Bool) -> Void)?) {
        fetchLabelList { _, _ in
            completion?(self.verifyData())
        }
    }
    
    public func fetchLabelList(completion: ((SecretLevelLabelList?, Error?) -> Void)?) {
        fetchLabelListRequest = SecretLevelLabelList.fetchLabelList(completion: { [weak self] list, error in
            guard let self = self else { return }
            if let list = list, !list.labels.isEmpty {
                list.labels.forEach { $0.isDefault = ($0.id == self.level.defaultLabelId) }
                self.labelList = list
            }
            completion?(list, error)
        })
    }
    
    public func reloadDataSoure() {
        guard let labelList = labelList else { return }
        let items: [SecretLevelItem] = labelList.labels.compactMap({ label in
            let selected = (level.label.id == label.id)
            let item = SecretLevelItem(title: label.name, subTitle: label.description, description: label.controllDes, selected: selected, levelLabel: label)
            return item
        })
        dataSource = items
        var headerRow = [BundleI18n.SKResource.LarkCCM_Workspace_Security_Settings_Title]
        var contentFirstRow = [DataEntity(text: BundleI18n.SKResource.LarkCCM_Workspace_SecuritySet_LinkSharing_Title, isImage: false, isRight: false)]
        var contentSecondRow = [DataEntity(text: BundleI18n.SKResource.LarkCCM_Workspace_SecuritySet_SharingRange_Title, isImage: false, isRight: false)]
        var contentThirdRow = [DataEntity(text: BundleI18n.SKResource.LarkCCM_Workspace_SecuritySet_ExtSharing_Title, isImage: false, isRight: false)]
        var contentFourthRow = [DataEntity(text: BundleI18n.SKResource.LarkCCM_Workspace_SecuritySet_WhoShare_Title, isImage: false, isRight: false)]
        var contentFifthRow = [DataEntity(text: BundleI18n.SKResource.LarkCCM_Workspace_SecuritySet_InviteCollab_Title, isImage: false, isRight: false)]
        var contentSixthRow = [DataEntity(text: BundleI18n.SKResource.LarkCCM_Workspace_SecuritySet_WhoCanCopy_Title, isImage: false, isRight: false)]
        var dupDownLoadTitle = BundleI18n.SKResource.LarkCCM_Workspace_SecuritySet_Copy_Title
        if UserScopeNoChangeFG.PLF.securityLevelSplitCopyEnable {
            dupDownLoadTitle = BundleI18n.SKResource.LarkCCM_Workspace_SecuritySet_WhoCanDupDownLoad_Title
        }
        var contentSeventhRow = [DataEntity(text: dupDownLoadTitle, isImage: false, isRight: false)]
        var contentEighthRow = [DataEntity(text: BundleI18n.SKResource.LarkCCM_Workspace_SecuritySet_Comment_Title, isImage: false, isRight: false)]
        
        for (index, levelLabel) in dataSource.enumerated() {
            headerRow.append(dataSource[index].title)
            contentFirstRow.append(DataEntity(text: "", isImage: true, isRight: levelLabel.levelLabel.control.linkShareEntity != .close))
            contentSecondRow.append(DataEntity(text: getLinkShareText(row: index), isImage: false, isRight: false))
            contentThirdRow.append(DataEntity(text: "", isImage: true, isRight: levelLabel.levelLabel.control.externalAccess != false))
            contentFourthRow.append(DataEntity(text: getExternalAccessText(row: index), isImage: false, isRight: false))
            contentFifthRow.append(DataEntity(text: getWhoCanAddCollaborator(row: index), isImage: false, isRight: false))
            contentSixthRow.append(DataEntity(text: getWhoCanCopy(row: index), isImage: false, isRight: false))
            contentSeventhRow.append(DataEntity(text: getWhoCanPrintAndDownload(row: index), isImage: false, isRight: false))
            contentEighthRow.append(DataEntity(text: getWhoCommentText(row: index), isImage: false, isRight: false))
        }

        setColumns(columns: headerRow)
        addRowValue(row:contentFirstRow)
        addRowValue(row:contentSecondRow)
        addRowValue(row:contentThirdRow)
        addRowValue(row:contentFourthRow)
        addRowValue(row:contentFifthRow)
        if UserScopeNoChangeFG.PLF.securityLevelSplitCopyEnable {
            addRowValue(row:contentSixthRow)
        }
        addRowValue(row:contentSeventhRow)
        addRowValue(row:contentEighthRow, isFinish: true)
    }
    
    //设置列头数据
    func setColumns(columns: [String]) {
        cols = columns
    }
    
    func addRowValue(row: [DataEntity], isFinish: Bool = false) {
        rowsValue.append(row)
    }
    
    private func verifyData() -> Bool {
        guard let labelList = labelList else {
            return false
        }
        return !labelList.labels.isEmpty
    }
    
    private func getExternalAccessText(row: Int) -> String{
        if dataSource[row].levelLabel.control.externalAccess == false {
            return BundleI18n.SKResource.LarkCCM_Workspace_SecuritySet_Off_Status
        } else {
            if dataSource[row].levelLabel.control.woCanExternalShareByPermission == .fullAccess {
                return BundleI18n.SKResource.LarkCCM_Workspace_SecuritySet_CanManage
            } else if dataSource[row].levelLabel.control.woCanExternalShareByPermission == .read {
                return BundleI18n.SKResource.LarkCCM_Workspace_SecuritySet_Unlimited
            } else {
                return BundleI18n.SKResource.LarkCCM_Workspace_SecuritySet_Unlimited
            }
        }
    }
    
    private func getLinkShareText(row: Int) -> String{
        switch dataSource[row].levelLabel.control.linkShareEntity {
        case .close:
            return BundleI18n.SKResource.LarkCCM_Workspace_SecuritySet_Off_Status
        case .tenantCanRead:
            return BundleI18n.SKResource.LarkCCM_Workspace_SecuritySet_ViewPermInOrg
        case .tenantCanEdit:
            return BundleI18n.SKResource.LarkCCM_Workspace_SecuritySet_EditPermInOrg
        case .anyoneCanRead:
            return BundleI18n.SKResource.LarkCCM_Workspace_SecuritySet_CanView
        case .anyoneCanEdit:
            return BundleI18n.SKResource.LarkCCM_Workspace_SecuritySet_CanEdit
        default:
            return BundleI18n.SKResource.LarkCCM_Workspace_SecuritySet_Unlimited
        }
    }
    
    private func getWhoCanAddCollaborator(row: Int) -> String {
        if dataSource[row].levelLabel.control.woCanManageCollaboratorsByOrganization == .sameTenant {
            if dataSource[row].levelLabel.control.woCanManageCollaboratorsByPermission == .read {
                return BundleI18n.SKResource.LarkCCM_Workspace_SecuritySet_ViewPermInOrg
            } else if dataSource[row].levelLabel.control.woCanManageCollaboratorsByPermission == .edit {
                return BundleI18n.SKResource.LarkCCM_Workspace_SecuritySet_EditPermInOrg
            } else if dataSource[row].levelLabel.control.woCanManageCollaboratorsByPermission == .fullAccess {
                return BundleI18n.SKResource.LarkCCM_Workspace_SecuritySet_OrgManage
            }
        } else if dataSource[row].levelLabel.control.woCanManageCollaboratorsByOrganization == .anyone {
            if dataSource[row].levelLabel.control.woCanManageCollaboratorsByPermission == .read {
                return BundleI18n.SKResource.LarkCCM_Workspace_SecuritySet_CanView
            } else if dataSource[row].levelLabel.control.woCanManageCollaboratorsByPermission == .edit {
                return BundleI18n.SKResource.LarkCCM_Workspace_SecuritySet_CanEdit
            } else if dataSource[row].levelLabel.control.woCanManageCollaboratorsByPermission == .fullAccess {
                return BundleI18n.SKResource.LarkCCM_Workspace_SecuritySet_CanManage
            }
        }
        return BundleI18n.SKResource.LarkCCM_Workspace_SecuritySet_Unlimited
    }
    
    private func getWhoCanPrintAndDownload(row: Int) -> String {
        if dataSource[row].levelLabel.control.securityEntity == .userCanRead {
            return BundleI18n.SKResource.LarkCCM_Workspace_SecuritySet_CanView
        } else if dataSource[row].levelLabel.control.securityEntity == .userCanEdit {
            return BundleI18n.SKResource.LarkCCM_Workspace_SecuritySet_CanEdit
        } else if dataSource[row].levelLabel.control.securityEntity == .onlyMe {
            return BundleI18n.SKResource.LarkCCM_Workspace_SecuritySet_CanManage
        } else {
            return BundleI18n.SKResource.LarkCCM_Workspace_SecuritySet_Unlimited
        }
    }

    private func getWhoCanCopy(row: Int) -> String {
        if dataSource[row].levelLabel.control.copyEntity == .userCanRead {
            return BundleI18n.SKResource.LarkCCM_Workspace_SecuritySet_CanView
        } else if dataSource[row].levelLabel.control.copyEntity == .userCanEdit {
            return BundleI18n.SKResource.LarkCCM_Workspace_SecuritySet_CanEdit
        } else if dataSource[row].levelLabel.control.copyEntity == .onlyMe {
            return BundleI18n.SKResource.LarkCCM_Workspace_SecuritySet_CanManage
        } else {
            return BundleI18n.SKResource.LarkCCM_Workspace_SecuritySet_Unlimited
        }
    }
    
    private func getWhoCommentText(row: Int) -> String {
        if dataSource[row].levelLabel.control.commentEntity == .userCanRead {
            return BundleI18n.SKResource.LarkCCM_Workspace_SecuritySet_CanView
        } else if dataSource[row].levelLabel.control.commentEntity == .userCanEdit {
            return BundleI18n.SKResource.LarkCCM_Workspace_SecuritySet_CanEdit
        } else {
            return BundleI18n.SKResource.LarkCCM_Workspace_SecuritySet_Unlimited
        }
    }
}
