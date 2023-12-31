//  Created by Songwen on 2018/9/10.


import Foundation
import SKInfra

// MARK: - 文件夹权限协作者相关协议(单容器版本)
extension OpenAPI.APIPath {
    /*
     ****以下是单容器版本新接口****
     https://bytedance.feishu.cn/docs/doccnaVN8u5AB9A6OYoHeA1ZnHn#
     */
    // 获取文件夹公共权限
    public static let getShareFolderPublicPermission = "/api/suite/permission/space/setting/"
    // 获取文件夹公共权限v2
    public static let getShareFolderPublicPermissionV2 = "/api/suite/permission/space/setting.v2/"
    
    // 更新文件夹公共权限
    public static let updateShareFolderPublicPermission = "/api/suite/permission/space/setting/update/"
    // 更新文件夹公共权限v2
    public static let updateShareFolderPublicPermissionV2 = "/api/suite/permission/space/setting/update.v2/"
    
    // 获取共享文件夹用户权限
    public static let getShareFolderUserPermission = "/api/suite/permission/space/collaborator/perm/"
    
    // 共享文件夹获取协作者列表
    public static let getShareFolderCollaborators = "/api/suite/permission/space/collaborators/"
    
    // 文件夹(普通+共享)添加协作者
    public static let addFolderCollaborator = "/api/suite/permission/space/collaborators/create/"
    
    // 更新共享文件夹协作者权限
    public static let updateShareFolderCollaboratorPermission = "/api/suite/permission/space/collaborators/update/"
    
    // 删除共享文件夹协作者权限
    public static let deleteShareFolderCollaborator = "/api/suite/permission/space/collaborators/delete/"
    
    // 共享文件夹转移Owner
    public static let transferShareFolderOwner = "/api/suite/permission/space/collaborators/transfer/"
    
    // 申请文件夹权限
    public static let applyFolderPermission = "/api/suite/permission/space/apply_permission/"
    
    // 共享文件夹解锁
    public static let unlockShareFolder = "/api/suite/permission/space/unlock/"
    
    // 判断共享文件夹修改公共权限是否触发加锁
    public static let checkLockByUpdateShareFolderPublicPermission = "/api/suite/permission/space/check_lock/public/update/"
    
    // 判断共享文件夹更新协作者权限是否触发加锁
    public static let checkLockByUpdateShareFolderCollaboratorPermission = "/api/suite/permission/space/check_lock/collaborators/update/"
    
    // 判断共享文件夹删除协作者是否触发加锁
    public static let checkLockByDeleteShareFolderCollaborator = "/api/suite/permission/space/check_lock/collaborators/delete/"
    
    // 创建密码
    public static let createPasswordForShareFolder = "/api/suite/permission/space/password/create/"
    
    // 刷新密码
    public static let refreshPasswordForShareFolder = "/api/suite/permission/space/password/refresh/"
    
    // 输入密码
    public static let inputPasswordForShareFolder = "/api/suite/permission/space/password/input/"
    
    // 删除密码
    public static let deletePasswordForShareFolder = "/api/suite/permission/space/password/delete/"
    
    // 批量查询用户是否已经是文件夹协作者
    public static let collaboratorsExistForShareFolder = "/api/suite/permission/space/collaborators/exist/"
    
    // 判断文档/文件夹是否是我的空间下一级根目录
    public static let checkSpaceRoot = "/api/explorer/v2/is_space_root/"
}

// MARK: - bizs文档权限协作者相关协议
// https://bytedance.feishu.cn/docs/doccnxFXgiN2w9NmEccqLKMVaH1#
extension OpenAPI.APIPath {
    // 获取文档公共权限
    public static let suitePermissionPublic = "/api/suite/permission/public.v3/"

    // 获取文档公共权限v4
    public static let suitePermissionPublicV4 = "/api/suite/permission/public.v4/"
    
    // 更新文档公共权限
    public static let suitePermissionPublicUpdate = "/api/suite/permission/public/update.v3/"

    // 更新文档公共权限v4
    public static let suitePermissionPublicUpdateV4 = "/api/suite/permission/public/update.v4/"
    
    // 更新文档公共权限v5
    public static let suitePermissionPublicUpdateV5 = "/api/suite/permission/public/update.v5/"
    
    // 获取文档用户权限v4
    public static let suitePermissonDocumentActionsState = "/api/suite/permission/document/actions/state/"
    
    // 文档获取协作者列表
    public static let suitePermissionCollaboratorsV2 = "/api/suite/permission/members.v2/"

    // 获取协作者列表数量
    public static let suitePermissionCollaboratorsCount = "/api/suite/permission/members/count/"
    
    // 文档添加协作者
    public static let suitePermissionCollaboratorsCreate = "/api/suite/permission/members/create/"
    
    // 更新文档协作者权限v2
    public static let suitePermissionCollaboratorsUpdateV2 = "/api/suite/permission.v2/members/update/"
    
    // 删除文档协作者权限
    public static let suitePermissionCollaboratorsDelete = "/api/suite/permission/members/delete/"
    
    // 文档转移Owner
    public static let suitePermissionTransferFileOwner = "/api/suite/permission/members/transfer/"
    
    // 新增协作者时对搜索结果批量查询该文档权限
    public static let suitePermissionUserMget = "/api/suite/permission/user/mget/"
    
    // 文档 ask owner
    public static let askOwnerForInviteCollaborator = "/api/suite/permission/ask_owner/members/create/"
    
    // 文档 send link
    public static let sendLinkForInviteCollaborator = "/api/suite/permission/members/share/"
    
    // 批量获取当前用户对多个文档的权限
    public static let suitePermissionObjects = "/api/suite/permission/objects/"

    /*
     ****以下是单容器版本新增接口****
     https://bytedance.feishu.cn/docs/doccnxFXgiN2w9NmEccqLKMVaH1
     */
    // bizs文档解锁
    public static let unlockFile = "/api/suite/permission/unlock/"
    
    // 判断bizs文档修改公共权限是否触发加锁
    public static let checkLockByUpdateFilePublicPermission = "/api/suite/permission/check_lock/public/update/"
    
    // 判断bizs文档更新协作者权限是否触发加锁
    public static let checkLockByUpdateFileCollaboratorPermission = "/api/suite/permission/check_lock/members/update/"
    
    // 判断bizs文档删除协作者是否触发加锁
    public static let checkLockByDeleteFileCollaborator = "/api/suite/permission/check_lock/members/delete/"

    // 同步块获取协作者列表
    public static let suitePermissionBlockCollaborators = "/api/suite/permission/synced_block/members/"
}

// MARK: - 其他协议
extension OpenAPI.APIPath {
    // 批量查询用户是否已经是协作者
    public static let suitePermissionCollaboratorsExist = "/api/suite/permission/members/exist.v2/"

    // MARK: 搜索协作者
    public static let searchPermissionCandidates = "/api/search/permission_candidates/" // 搜索lark用户或群
    
    // 生成邮箱身份信息
    public static let generateEmailInfo = "/api/user/email_info/generate/"
    
    // 创建邮箱邀请关系
    public static let emailInviteRelation = "/api/user/email_invite_relation/create/"

    // MARK: 单品Docs
    // 根据手机号搜索用户
    public static let searchShareUser = "/api/share/search/"
    public static let shareConvert = "/api/share/convert/"

    // MARK: 分享密码
    public static let suitePermissionPasswordCreate = "/api/suite/permission/password/create/"
    public static let suitePermissionPasswordDelete = "/api/suite/permission/password/delete/"
    public static let suitePermissionPasswordRefresh = "/api/suite/permission/password/refresh/"
    public static let suitePermissionPasswordInput = "/api/suite/permission/password/input/"

    public static let suitePermissionPasswordRandom = "/api/suite/permission/password/random/"
    public static let suitePermissionPasswordCommit = "/api/suite/permission/password/commit/"

    // MARK: 组织架构
    public static let searchVisibleDepartment = "/api/suite/visible_department/"

    // MARK: 联系方式注册用户接口
    public static let userContactRegister = "/api/user/contact/register/"

}
// MARK: ******以下协议即将废弃，等待下线******

// MARK: - 文件夹权限协作者相关协议
// 单容器数据洗好后，这部分可删除，只保留单容器版本协议
extension OpenAPI.APIPath {
    // MARK: 旧共享文件夹
    // 协作者相关
    public static let explorerSpaceMget = "/api/suite/permission/share_space/members/" // 查询旧共享文件夹成员
    public static let explorerSpaceAdd = "/api/explorer/space/add/" // 文件夹邀请协作者
    public static let explorerSpaceRemove = "/api/explorer/space/remove/" // 文件夹删除协作者
    
    // 权限相关
    public static let suitePermissionShareSpaceCollaboratorPerm = "/api/suite/permission/share_space/member/perm/" // 查询协作者权限
    public static let suitePermissionShareSpaceCollaboratorUpdate  = "/api/suite/permission/share_space/member/update/" // 更新协作者权限
    public static let suitePermissionShareSpaceSet = "/api/suite/permission/share_space/setting/get/" // 文件夹查询公共权限
    public static let suitePermissionShareSpaceSetUpdate  = "/api/suite/permission/share_space/setting/update/" // 文件夹更新公共权限
    public static let suitePermissionTransferFolderOwner = "/api/suite/permission/share_space/transfer_owner/" // folder 权限转移
}

//表单接口
extension OpenAPI.APIPath {
    // 获取记录分享 token (meta)
    public static var getBaseRecordShareMeta: String {
        "/api/bitable/share/record"
    }
    //获取分享表单meta
    public static var getFormShareMetaPath: (_ baseToken: String) -> String = {
        return "/api/bitable/\($0)/share/meta/"
    }
    public static let updateFormMetaPath = "/api/bitable/share/flag/update/" // 开启/关闭分享表单

    //获取分享表单的权限设置
    public static var getFormPermissionSettingPath: (_ baseToken: String) -> String = {
        return "/api/bitable/\($0)/share/permission/"
    }
    //获取用户是否有分享表单的权限
    public static var getFormPermissionPath: (_ baseToken: String) -> String = {
        return "/api/bitable/\($0)/share/user_permission/"
    }

    public static let updateFormSharePermissionPath = "/api/bitable/share/permission/" // 设置表单填写权限
    //获取协作者列表
    public static var getFormPermissionMembersPath: (_ baseToken: String) -> String = {
        return "/api/bitable/\($0)/share/permission/members"
    }
    public static let inviteFormMembersPath = "/api/bitable/share/permission/members/create/" // 邀请协作者
    public static let deleteFormMembersPath = "/api/bitable/share/permission/members/delete/" // 删除协作者
}

//bitable高级权限
extension OpenAPI.APIPath {
    public static var getBitablePermissonRule: (_ baseToken: String) -> String = {
        return "/api/bitable/\($0)/roles"
    }
    public static var updateBitablePermissonRule: (_ baseToken: String) -> String = {
        return "/api/bitable/roles/\($0)/update"
    }
    public static var getBitablePermissonCostInfo: (_ baseToken: String) -> String = {
        return "/api/bitable/\($0)/perm_cost_info"
    }
    
    public static var updateBitablePermRoleFallbackConfig: (_ baseToken: String) -> String = {
        return "/api/bitable/default_access_config/\($0)/update"
    }
    
    public static var clearBitableAdPermMembers: (_ baseToken: String) -> String = {
        return "/api/bitable/roles/\($0)/clear_member"
    }
    // 申请高级权限
    public static var applyBitableAdPerm: (_ baseToken: String) -> String = {
        return "/api/bitable/permission/\($0)/apply"
    }
    // 获取高级权限能否申请状态
    public static var applyBitableAdPermCode: (_ baseToken: String) -> String = {
        return "/api/bitable/permission/\($0)/apply_permission_code"
    }
}

//内嵌文档授权
extension OpenAPI.APIPath {
    /// 获取内嵌文档列表
    public static var embedDocAuthList: (_ taskID: String) -> String = {
        return "/api/platform/doc/card/embeded/\($0)/obj/list"
    }
    /// 对内嵌文档进行批量授权
    public static let embededDocAuth = "/api/suite/permission/role/create"
    ///对文档进行批量取消授权
    public static let embededDocCancelAuth = "/api/suite/permission/role/delete"
    /// 记录内嵌文档授权状态
    public static var embedDocRecord: (_ taskID: String) -> String = {
        return "/api/platform/doc/card/embeded/\($0)/obj"
    }
    ///更新内嵌文档卡片状态
    public static var embededDocUpdateCard: (_ taskID: String) -> String = {
        return "/api/platform/doc/card/embeded/\($0)/count"
    }
    ///更新文档卡片状态
    public static var updateDocCard: (_ cardID: String) -> String = {
        return "/api/platform/doc/card/update/\($0)"
    }
}

// 投票
extension OpenAPI.APIPath {
    public static let pollOptionData = "/api/docx/poll/option/data"
}

// bitable homepage
extension OpenAPI.APIPath {
    public static let bitableGetHomepage = "/api/bitable/get_homepage"
}

extension OpenAPI.APIPath {
    // 获取添加记录分享 token (meta)
    public static var getBaseAddRecordShareMeta: (_ baseToken: String) -> String = {
        "/api/bitable/\($0)/add_record/token"
    }
    public static var getBaseAddRecordMeta: (_ shareToken: String) -> String = {
        return "/api/bitable/\($0)/add_record/meta"
    }
    public static var getBaseRecordMeta: (_ shareToken: String) -> String = {
        return "/api/bitable/\($0)/share/record"
    }
    public static var getBaseLinkContent: (_ baseToken: String) -> String = {
        return "/api/bitable/\($0)/link/content"
    }
    public static var mentionNotification: String = "/api/mention/notification/"
}
