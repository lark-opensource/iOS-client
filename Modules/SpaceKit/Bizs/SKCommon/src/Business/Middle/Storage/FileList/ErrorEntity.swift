//
//  ErrorEntity.swift
//  SpaceKit
//
//  Created by litao_dev on 2019/5/24.
//  

import Foundation
import SKResource

// document: https://bytedance.feishu.cn/space/doc/doccnGiUJ5PJxrzusD40m1#
public enum ExplorerErrorCode: Int {
    case moveCantMoveShare = 4103
    case moveDontHaveSharePermission = 4104
    case moveHasShareFolderAlready = 4114
    case administratorCloseShare = 10004
    case maxCollaboratorsLimit = 10014
    //不支持邀请外部用户
    case notSupportInviteExternal = 870601
    // 数据迁移期间，内容被锁定
    case dataLockDuringUpgrade = 4202
    //数据迁移期间，禁止写操作
    case dataUpgradeLocked = 10040
    //1.0转移文件夹同时转移子节点，子节点数量过多提示
    case maximumNumberOfChildNodes = 151211001
    //公共权限缩权失败
    case publicPermInvalidUpdate = 10011
    /// 机器审核不过
    case auditError = 10009
    /// 人工审核不过 或者被举报
    case reportError = 10013
}

public struct ErrorEntity {
    public let code: ExplorerErrorCode
    public let wording: String
    public init(code: ExplorerErrorCode, folderName: String) {
        self.code = code
        switch code {
        case .moveCantMoveShare:
            self.wording = BundleI18n.SKResource.Doc_List_MoveFailedCantMoveToShare
        case .moveDontHaveSharePermission:
            self.wording = BundleI18n.SKResource.Doc_List_MoveFailedNoSharePermission(folderName)
        case .moveHasShareFolderAlready:
            self.wording = BundleI18n.SKResource.Doc_Share_ShareForbidden(folderName)
        case .administratorCloseShare:
            self.wording = BundleI18n.SKResource.Doc_Share_AdministratorCloseShare
        case .notSupportInviteExternal:
            self.wording = User.current.info?.isToC == true
                ? BundleI18n.SKResource.Doc_Share_NotSupportEnterpriseUser
                : BundleI18n.SKResource.Doc_Share_NotSupportExternalUser
        case .maxCollaboratorsLimit:
            self.wording = BundleI18n.SKResource.CreationMobile_ECM_MaxCollaboratorsToast
        case .dataUpgradeLocked, .dataLockDuringUpgrade:
            self.wording = BundleI18n.SKResource.CreationMobile_DataUpgrade_Locked_toast
        case .maximumNumberOfChildNodes:
            self.wording = BundleI18n.SKResource.CreationMobile_transfer_my_tooMany
        case .publicPermInvalidUpdate:
            self.wording = BundleI18n.SKResource.CreationMobile_Wiki_SharePanel_InheritSettings
        case .auditError:
            self.wording = BundleI18n.SKResource.Drive_Drive_OpeationFailByPolicy()
        case .reportError:
            self.wording = BundleI18n.SKResource.Drive_Drive_DiscardedFileHint()
        }
    }
}
