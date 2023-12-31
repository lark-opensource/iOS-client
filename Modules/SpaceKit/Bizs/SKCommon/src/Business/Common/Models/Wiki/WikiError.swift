//
//  WikiError.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2019/9/23.
//  swiftlint:disable operator_usage_whitespace

import SKUIKit
import SKResource

// 错误码： https://bytedance.feishu.cn/space/doc/doccnlCCqFgO2daFKJF3Ca#
public enum WikiErrorCode: Int {
    case invalidWiki                = 3 // wiki节点无效
    case ownerAccountSuspended      = 920003005 // 文档 owner 已离职
    case parentSourceNotExist       = 920004001
    case sourceNotExist             = 920004002
    case parentPermFail             = 920004003
    case permFail                   = 920004004
    case forbiddenCircle            = 920004005
    case forbiddenReAdd             = 920004006
    case spacePermFail              = 920004007 // 如果是拉clientVar接口返回的错误码，表示wiki无权限，docs有权限
    case spaceForbiddenReAdd        = 920004008
    case spaceInvalidLink           = 920004009
    case spaceUpdateObjPermFail     = 920004010
    case tenantQuotaUnavaliableCode = 920004011
    case nodePermFailCode           = 920004012 //没有wiki节点权限
    case typeUnsupportedCode        = 920004013 //类型还不支持，如sheet,mindnote等
    case taskTooHeavyCode           = 920004014 //任务过大，如导入文件夹传入的文件夹下内容过大
    case starSpaceNumLimited        = 920004024 //收藏知识库数量达到上限
    case applyReachLimit            = 920004106 // 申请达到上限
    case applyForbiddenByAdmin      = 920004107 // 由于管理员设置，目标无法收到通知
    case noAvailableAuthorizedUser  = 920004109 // 所有管理员都已离职
    case noPermissionToApplyMove    = 920004112 // 没有权限申请移动，无法获取
    case wikiAlreadyInSpace         = 920004117 // 文档已在 space 中
    case spaceTargetPermFail        = 920004118 // 没有 space 目标位置节点的权限
    case spaceTargetNotExist        = 920004119 // space 目标节点不存在
    case dataLockedForMigration     = 900004230 // 数据迁移中，内容被锁定
    case unavailableForCrossTenantGeo = 900004510 // 合规-同品牌的跨租户跨Geo
    case unavailableForCrossBrand   = 900004511 // 合规-跨品牌不允许
    case operateNodeNoPerm          = 233525001 // 删除/恢复操作的节点没权限
    case operateSubNodeNoPerm       = 233525002 // 删除/恢复操作节点的子节点没权限
    case operationNeedApply         = 233525003 // 删除、移动权限不足，需要申请
    case parentNodeNoPerm           = 233525204 // 移动失败，没有父节点权限
    case targetNodeNoPerm           = 233525305 // 移动失败，没有目标节点权限
    case auditError                 = 10009     // 机器审核不过
    case reportError                = 10013     // 人工审核不过 或者被举报
    case spaceOutOfStorage          = 11001     // 租户容量超出限制
    case networkError               = -1
    case spaceDeleted               = 801
    case versionTokenOtherFail      = 999_999_999 // 非后端返回，客户端自定义的版本默认错误码
    case versionEditionIdLengthErr  = 528_010_000 // edtion_id长度不合法
    case versionNotPermission       = 528_021_002 // 权限不通过
    case versionEditionIdForbidden  = 528_032_011 // edtion_id不合法
    case sourceDelete               = 528_032_012 // 文档已删除
    case sourceNotFound             = 528_021_015 // 源文档不存在
    case versionNotFound            = 528_021_016 // 版本文档不存在
    case nodesCountLimitExceed      = 233_525_007 // 节点数量超限
    case nodeHasBeenDeleted         = 920_004_123 // 节点被删除，可恢复
    case nodePhysicalDeleted        = 920_004_121 // 节点被物理删除
    case cacDeleteBlcked            = 900099011 //删除被cac管控
    public var pageErrorDescription: String {
        switch self {
        case .parentSourceNotExist, .invalidWiki, .sourceNotExist, .nodeHasBeenDeleted, .nodePhysicalDeleted, .sourceDelete:
            return BundleI18n.SKResource.CreationMobile_Wiki_PageDeleted_Toast
        case .spaceDeleted:
            return BundleI18n.SKResource.CreationMobile_wiki_DeleteWiki_deleted_return_toast
        case .parentPermFail, .spacePermFail, .nodePermFailCode:
            return BundleI18n.SKResource.Doc_Wiki_PageNoPermission
        case .permFail:
            return BundleI18n.SKResource.Doc_Wiki_EnterWorkspaceNoPermission
        case .versionNotFound:
            return BundleI18n.SKResource.LarkCCM_Docx_VersionMgmt_Deleted
        case .sourceNotFound:
            return BundleI18n.SKResource.Doc_Wiki_PageRemovedText
        default:
            return BundleI18n.SKResource.Doc_Wiki_Tree_LoadError
        }
    }

    public var expandErrorDescription: String {
        switch self {
        case .parentSourceNotExist, .sourceNotExist:
            return BundleI18n.SKResource.Doc_Wiki_ExpandFailPageRemoved
        case .parentPermFail, .permFail, .spacePermFail, .nodePermFailCode:
            return BundleI18n.SKResource.Doc_Wiki_ExpandFailNoPermission
        default:
            return BundleI18n.SKResource.Doc_Wiki_Tree_LoadError
        }
    }

    public var addErrorDescription: String {
        switch self {
        case .parentSourceNotExist, .sourceNotExist:
            return BundleI18n.SKResource.Doc_Wiki_CreateFailFatherRemoved
        case .parentPermFail, .permFail, .spacePermFail, .nodePermFailCode:
            return BundleI18n.SKResource.LarkCCM_Docs_ActionFailed_NoTargetPermission_Mob
        case .dataLockedForMigration:
            return BundleI18n.SKResource.CreationMobile_MultiGeo_900004230
        case .unavailableForCrossTenantGeo:
            return BundleI18n.SKResource.CreationMobile_MultiGeo_900004510
        case .unavailableForCrossBrand:
            return BundleI18n.SKResource.CreationMobile_MultiGeo_900004511
        case .auditError, .reportError:
            return BundleI18n.SKResource.Doc_Review_Fail_Rename
        default:
            return BundleI18n.SKResource.Doc_Wiki_Tree_LoadError
        }
    }

    public var createShortcutErrorDescription: String {
        switch self {
        case .parentSourceNotExist, .sourceNotExist:
            return BundleI18n.SKResource.Doc_Wiki_CreateFailFatherRemoved
        case .parentPermFail, .permFail, .spacePermFail, .nodePermFailCode:
            return BundleI18n.SKResource.CreationMobile_Wiki_Shortcuts_ShortcutsRule_Tooltip
        case .dataLockedForMigration:
            return BundleI18n.SKResource.CreationMobile_MultiGeo_900004230
        case .unavailableForCrossTenantGeo:
            return BundleI18n.SKResource.CreationMobile_MultiGeo_900004510
        case .unavailableForCrossBrand:
            return BundleI18n.SKResource.CreationMobile_MultiGeo_900004511
        default:
            return BundleI18n.SKResource.CreationMobile_Wiki_Shortcuts_UnableToCreate_Toast
        }
    }

    public var deleteErrorDescription: String {
        switch self {
        case .parentPermFail, .permFail, .spacePermFail, .nodePermFailCode, .operateNodeNoPerm:
            return BundleI18n.SKResource.CreationMobile_Wiki_NoPermissionToDelete_Toast
        case .operateSubNodeNoPerm:
            return BundleI18n.SKResource.CreationMobile_Wiki_CannotDeleteSubpages_Toast
        case .dataLockedForMigration:
            return BundleI18n.SKResource.CreationMobile_MultiGeo_900004230
        case .unavailableForCrossTenantGeo:
            return BundleI18n.SKResource.CreationMobile_MultiGeo_900004510
        case .unavailableForCrossBrand:
            return BundleI18n.SKResource.CreationMobile_MultiGeo_900004511
        default:
            return BundleI18n.SKResource.CreationMobile_Wiki_CannotRemove_Toast
        }
    }

    public func moveErrorDescription(pageName: String) -> String {
        switch self {
        case .parentSourceNotExist:
            return BundleI18n.SKResource.Doc_Wiki_MoveFailTargetRemoved
        case .sourceNotExist:
            return BundleI18n.SKResource.Doc_Wiki_MoveFailCurrentRemoved
        case .parentPermFail, .permFail, .spacePermFail, .nodePermFailCode, .targetNodeNoPerm:
            return BundleI18n.SKResource.LarkCCM_Docs_MoveToWiki_NoMovingPermission_Toast
        case .parentNodeNoPerm:
            return BundleI18n.SKResource.CreationMobile_Wiki_Permission_NoRemovePermission_Toast
        case .ownerAccountSuspended:
            return BundleI18n.SKResource.CreationMobile_Wiki_MoveToSpace_FailedToMove_OwnerLeft
        case .spaceTargetPermFail:
            return BundleI18n.SKResource.CreationMobile_Wiki_MoveToSpace_Error_NoPermissionOnSpaceTarget
        case .spaceTargetNotExist:
            return BundleI18n.SKResource.CreationMobile_Wiki_MoveToSpace_Error_SpaceTargetIsNotFound
        case .noPermissionToApplyMove:
            return BundleI18n.SKResource.CreationMobile_Wiki_MoveToSpace_UnableToMove_PermChange(pageName)
        case .applyReachLimit:
            return BundleI18n.SKResource.CreationMobile_Wiki_MoveToSpace_MaxRequest_Toast
        case .wikiAlreadyInSpace:
            return BundleI18n.SKResource.CreationMobile_Wiki_MoveToSpace_Error_AlreadyExistOnSpace
        case .noAvailableAuthorizedUser:
            return BundleI18n.SKResource.CreationMobile_Wiki_MoveToSpace_NoWorkspaceAdmin
        case .taskTooHeavyCode:
            return BundleI18n.SKResource.CreationMobile_Wiki_MoveToSpace_FailedToMove_TooManySubpages
        default:
            return BundleI18n.SKResource.Doc_Wiki_Tree_LoadError
        }
    }

    public var renameErrorDescription: String {
        switch self {
        case .reportError, .auditError:
            return BundleI18n.SKResource.Doc_Review_Fail_Rename
        default:
            return BundleI18n.SKResource.Doc_Facade_RenameFailed
        }
    }

    public var makeCopyErrorDescription: String {
        switch self {
        case .parentPermFail, .permFail, .spacePermFail, .nodePermFailCode:
            return BundleI18n.SKResource.CreationMobile_Error_NoPerm_CompleteAction
        default:
            return BundleI18n.SKResource.CreationMobile_Wiki_CreateCopy_UnableToCreate_Toast
        }
    }

    public func moveToSpaceErrorDescription(pageName: String) -> String {
        switch self {
        case .ownerAccountSuspended:
            return BundleI18n.SKResource.CreationMobile_Wiki_MoveToSpace_FailedToMove_OwnerLeft
        case .spaceTargetPermFail, .nodePermFailCode:
            return BundleI18n.SKResource.CreationMobile_Wiki_MoveToSpace_Error_NoPermissionOnSpaceTarget
        case .noPermissionToApplyMove:
            return BundleI18n.SKResource.CreationMobile_Wiki_MoveToSpace_UnableToMove_PermChange(pageName)
        case .spaceTargetNotExist:
            return BundleI18n.SKResource.CreationMobile_Wiki_MoveToSpace_Error_SpaceTargetIsNotFound
        case .applyReachLimit:
            return BundleI18n.SKResource.CreationMobile_Wiki_MoveToSpace_MaxRequest_Toast
        case .wikiAlreadyInSpace:
            return BundleI18n.SKResource.CreationMobile_Wiki_MoveToSpace_Error_AlreadyExistOnSpace
        case .noAvailableAuthorizedUser:
            return BundleI18n.SKResource.CreationMobile_Wiki_MoveToSpace_NoWorkspaceAdmin
        case .taskTooHeavyCode:
            return BundleI18n.SKResource.CreationMobile_Wiki_MoveToSpace_FailedToMove_TooManySubpages
        default:
            return BundleI18n.SKResource.Doc_Wiki_Tree_LoadError
        }
    }

    public var failViewType: EmptyListPlaceholderView.EmptyType {
        switch self {
        case .spaceDeleted:
            return .noSupport
        case .permFail:
            return .noPermission
        case .sourceNotExist, .sourceDelete, .versionNotFound, .sourceNotFound, .nodeHasBeenDeleted, .nodePhysicalDeleted:
            return .fileDeleted
        default:
            return .openFileFail
        }
    }
}

public enum WikiError: Error, LocalizedError {
    case noNetwork
    case invalidDataError
    case dataParseError
    case serverError(code: Int)
    case getWikiNodeNotExist // wiki节点被删除，不可跳转到主页（从聊天链接进入无法得到homepage信息无法跳转）
    case getWikiNodeNotExistCanJump // wiki节点被删除，可跳转到wiki主页（从最近列表或者目录树进入wiki，带有homepage信息，可跳转)
    case getWikiNodeNoPermission  // 节点无权限，可跳转到wiki主页（从最近列表或者目录树进入wiki，带有homepage信息，可跳转)
    case invalidWikiError // 节点token无效
    case enterWorkspaceRemoved
    case enterWorkspaceNoPermission
    case storageAlreadyInitialized // wiki db 重复初始化
    case storageNotInitialized //用户态改造场景下 wiki db 还未初始化

    public var errorDescription: String? {
        switch self {
        case .noNetwork:
            return BundleI18n.SKResource.Doc_Facade_NetworkInterrutedRetry
        case .invalidDataError:
            return "invalid data"
        case .dataParseError:
            return "data parse error"
        case .serverError:
            // 服务端错误兜底文案
            return BundleI18n.SKResource.Doc_Wiki_Tree_LoadError
        case .getWikiNodeNotExist:
            return BundleI18n.SKResource.Doc_Wiki_PageRemovedText
        case .getWikiNodeNotExistCanJump:
            return BundleI18n.SKResource.Doc_Wiki_PageRemovedTextClickable
        case .invalidWikiError:
            return "invalid wiki token"
        case .enterWorkspaceRemoved:
            return BundleI18n.SKResource.Doc_Wiki_EnterWorkspaceRemoved
        case .enterWorkspaceNoPermission:
            return BundleI18n.SKResource.Doc_Wiki_EnterWorkspaceNoPermission
        case .getWikiNodeNoPermission:
            return BundleI18n.SKResource.Doc_Wiki_PageNoPermission
        case .storageAlreadyInitialized:
            return "WikiStorage is already initialized!"
        case .storageNotInitialized:
            return "WikiStorage has not be initialized!"

        }
    }
}
