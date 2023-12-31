//
//  NamecardAPI.swift
//  LarkSDKInterface
//
//  Created by 夏汝震 on 2021/4/16.
//

import Foundation
import RxSwift
import LarkModel
import LarkContainer
import RustPB
import ServerPB

public typealias NameCardUserProfile = RustPB.Email_Client_V1_GetNamecardProfileResponse
public typealias MailContactGroup = RustPB.Email_Client_V1_MailGroup
public typealias MailContactRequestSource = RustPB.Email_Client_V1_ClientRequestSource
public typealias MailSharedEmailAccount = RustPB.Email_Client_V1_SharedEmailAccount
public typealias MailGroupRole = RustPB.Email_Client_V1_MailGroupRole
public typealias MailGroupMember = RustPB.Email_Client_V1_MailGroupMember
public typealias MailGroupManager = RustPB.Email_Client_V1_MailGroupManager
public typealias MailGroupPermissionMember = RustPB.Email_Client_V1_MailGroupPermissionMember
public typealias MailGroupUpdateResponse = RustPB.Email_Client_V1_MailUpdateGroupResponse

public struct NameCardList {
    public var list: [NameCardInfo]
    public var hasMore: Bool

    public init(list: [NameCardInfo], hasMore: Bool) {
        self.list = list
        self.hasMore = hasMore
    }
}

public final class NameCardInfo {
    // swiftlint:disable identifier_name
    public var namecardId: String
    public var name: String
    public var companyName: String
    public var avatarKey: String
    public var phone: RustPB.Email_Client_V1_Phone
    public var email: String
    // 备注
    public var note: String
    // 职务
    public var title: String
    // 标签
    public var tag: String
    public var isCustomAvatar: Bool
    public var indexStr: String

    public init(namecardId: String,
                name: String,
                companyName: String,
                avatarKey: String,
                phone: RustPB.Email_Client_V1_Phone,
                email: String,
                note: String,
                title: String,
                tag: String,
                isCustomAvatar: Bool,
                indexStr: String) {
        self.namecardId = namecardId
        self.name = name
        self.companyName = companyName
        self.avatarKey = avatarKey
        self.phone = phone
        self.email = email
        self.note = note
        self.title = title
        self.tag = tag
        self.isCustomAvatar = isCustomAvatar
        self.indexStr = indexStr
    }

    public static func transform(nameCardListPB: RustPB.Email_Client_V1_NamecardMetaInfo) -> NameCardInfo {
        return NameCardInfo(namecardId: nameCardListPB.namecardID,
                            name: nameCardListPB.name,
                            companyName: nameCardListPB.companyName,
                            avatarKey: nameCardListPB.avatarKey,
                            phone: nameCardListPB.phone,
                            email: nameCardListPB.email,
                            note: nameCardListPB.extra,
                            title: nameCardListPB.title,
                            tag: nameCardListPB.group,
                            isCustomAvatar: nameCardListPB.isCustomAvatar,
                            indexStr: nameCardListPB.indexStr)
    }
    // swiftlint:enable identifier_name
}

public struct MailAccountBriefInfo: Equatable {
    public let userType: Int
    public let address: String
    public let accountID: String
    public let isMainAccount: Bool
    public var nameCardTotalCount: Int
    public let mailGroupTotalCount: Int

    public static let empty = MailAccountBriefInfo(userType: -1, address: "", accountID: "", isMainAccount: false, nameCardTotalCount: 0, mailGroupTotalCount: 0)

    public static func transform(from pb: RustPB.Email_Client_V1_GetMailContactMetaResponse.MailContactMeta) -> MailAccountBriefInfo {
        return MailAccountBriefInfo(userType: Int(pb.userType),
                                    address: pb.address,
                                    accountID: pb.accountID,
                                    isMainAccount: pb.isMainAccount,
                                    nameCardTotalCount: Int(pb.nameCardTotalCount),
                                    mailGroupTotalCount: Int(pb.mailGroupTotalCount))
    }
}

public struct MailContactChangedPush: PushMessage {
    public let briefInfos: [MailAccountBriefInfo]

    public init(briefInfos: [MailAccountBriefInfo]) {
        self.briefInfos = briefInfos
    }
}

public struct MailShareAccountChangedPush: PushMessage {
    public init() {}
}

public protocol NamecardAPI {
    /// 分页获取联系人列表
    /// @params id: 联系人id
    /// @params accountID: 联系人所属账号id
    /// @params limit: 拉取数量
    func getNamecardList(namecardId: String?, accountID: String, limit: Int) -> Observable<NameCardList>

    /// 添加联系人个人信息
    /// @params namecardInfo: 描述联系人的结构体
    /// @params accountID: 联系人所属账号id
    func setSingleNamecard(namecardInfo: RustPB.Email_Client_V1_NamecardMetaInfo, accountID: String) -> Observable<RustPB.Email_Client_V1_SetSingleNamecardResponse>

    /// 更新联系人信息
    /// @params namecard: 描述联系人的结构体
    /// @params accountID: 联系人所属账号id
    func updateSingleNamecard(namecard: RustPB.Email_Client_V1_NamecardMetaInfo, accountID: String) -> Observable<RustPB.Email_Client_V1_UpdateSingleNamecardResponse>

    /// 删除联系人
    /// @params id: 联系人id
    /// @params accountID: 联系人所属账号id
    func deleteSingleNamecard(_ id: String, accountID: String, address: String) -> Observable<RustPB.Email_Client_V1_DeleteSingleNamecardResponse>

    /// 获取联系人信息
    /// @params id: 联系人id
    /// @params accountID: 联系人所属邮箱账号id
    func getNamecardsByID(_ id: String, accountID: String) -> Observable<RustPB.Email_Client_V1_NamecardMetaInfo?>

    /// 获取本地名片夹联系人的profile信息
    /// @params namecardId: 联系人Id
    /// @params email: 联系人邮箱地址
    /// @params accountID: 联系人所属账号id
    func getLocalNamecardProfile(_ namecardId: String, email: String, accountID: String) -> Observable<NameCardUserProfile>

    /// 获取远程名片夹联系人的profile信息
    /// @params namecardId: 联系人Id
    /// @params email: 联系人邮箱地址
    /// @params accountID: 联系人所属账号id
    func getRemoteNamecardProfile(_ namecardId: String, email: String, accountID: String) -> Observable<NameCardUserProfile>

    /// 是否展示管理邮件组tabgetMailGroupMembersList
    func getMailContactGroupTabShowStatus() -> Observable<Bool>

    /// 获取我管理的邮件组列表
    /// - Parameters:
    ///  - source: 请求类型
    func getMailManagedGroups(source: MailContactRequestSource) -> Observable<([Email_Client_V1_MailGroup], MailContactRequestSource)>

    /// 获取邮件组详情
    /// - Parameters:
    ///   - groupId: 邮件组id
    ///   - source: 请求类型
    func getMailGroupDetail(_ groupId: Int, source: MailContactRequestSource) -> Observable<RustPB.Email_Client_V1_MailGroupDetailResponse>

    /// 分页获取
    /// - Parameters:
    ///   - groupId: 群id
    ///   - pageSize: 每页个数
    ///   - indexToken: token
    ///   - role: 群成员 / 管理员
    ///   - source: 请求类型
    func getMailGroupMembersList(_ groupId: Int,
                                 pageSize: Int,
                                 indexToken: String,
                                 role: RustPB.Email_Client_V1_MailGroupRole,
                                 source: MailContactRequestSource) -> Observable<RustPB.Email_Client_V1_MailGroupMembersResponse>

    /// <#Description#>
    /// - Parameters:   - 对DEPARTMENT，memberID就是departmentID，对USER，memberID就是userID, COMPANY类型没有memberID
    ///   - groupId: 邮件组id
    ///   - permission: 权限类型
    ///   - addMember: 必填字段：【member_id】【mail_address】【member_type】
    ///   - deletedMember: 必填字段：【member_id】【mail_address】【member_type】
    ///   - addManager: 必填字段：【user_id】
    ///   - deletedManager: 必填字段：【user_id】
    ///   - addPermissionMember: addPermissionMember description
    ///   - deletePermissionMember: deletePermissionMember description
    func updateMailGroupInfo(_ groupId: Int,
                             accountID: String,
                             permission: MailContactGroup.PermissionType?,
                             addMember: [RustPB.Email_Client_V1_MailGroupMember]?,
                             deletedMember: [RustPB.Email_Client_V1_MailGroupMember]?,
                             addManager: [RustPB.Email_Client_V1_MailGroupManager]?,
                             deletedManager: [RustPB.Email_Client_V1_MailGroupManager]?,
                             addPermissionMember: [RustPB.Email_Client_V1_MailGroupPermissionMember]?,
                             deletePermissionMember: [RustPB.Email_Client_V1_MailGroupPermissionMember]?) -> Observable<MailGroupUpdateResponse>

    /// 修改描述
    /// - Parameter description: 描述
    func updateMailRemark(_ groupId: Int, description: String) -> Observable<()>

    func getSharedEmailAccountsList(indexToken: String,
                                    pageSize: Int,
                                    source: MailContactRequestSource) -> Observable < (hasMore: Bool,
                                                                                     indexToken: String,
                                                                                     [MailSharedEmailAccount])>

    func mailCheckGroupMemberIsExist(groupId: Int,
                                     member: [MailGroupMember]?,
                                     manager: [MailGroupManager]?,
                                     permissionMember: [MailGroupPermissionMember]?) -> Observable < (existMember: [MailGroupMember],
                                                                                                  existManager: [MailGroupManager],
                                                                                                  existPermissionMember: [MailGroupPermissionMember])>
    // 失焦，透传，需要用到serverPB

    /// 检查邮件地址是否已经在群成员里，用到了透传接口。
    /// - Parameters:
    ///   - groupId: 邮件组id
    ///   - email: 邮件地址
    func checkEmailIsAlreadyInGroupMembers(groupId: Int, email: String) -> Observable<(Bool)>

    /// 检查邮件地址的信息
    /// - Returns: 详细信息
    func getEmailsMembersInfo(groupId: Int, email: [String]) -> Observable<[ServerPB_Mail_entities_MailGroupMember]>

    //MAIL_CHECK_USER_GROUP_PERMISSION
    func checkServerMailGroupPermission() -> Observable<Bool>

    /// 获取当前账号的所有邮箱账号及邮箱账号下的联系人和群组数量
    func getAllMailAccountDetail(latest: Bool) -> Observable<[MailAccountBriefInfo]>

    /// 根据邮箱顺序排列邮箱账号
    func sortMailAccountInfos(_ infos: [MailAccountBriefInfo]) -> Observable<[MailAccountBriefInfo]>

    /// 获取当前邮箱账号类型
    func getCurrentMailAccountType() -> Observable<String>
}
