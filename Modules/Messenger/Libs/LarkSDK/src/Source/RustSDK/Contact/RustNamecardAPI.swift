//
//  RustNamecardAPI.swift
//  LarkSDK
//
//  Created by 夏汝震 on 2021/4/16.
//

import Foundation
import RustPB
import RxSwift
import LKCommonsLogging
import LarkModel
import LarkSDKInterface
import ServerPB

final class RustNamecardAPI: LarkAPI, NamecardAPI {

    private let disposeBag = DisposeBag()

    private static let logger = Logger.log(RustNamecardAPI.self, category: "RustSDK.Namecard")

    /// 分页获取联系人列表
    /// @params id: 联系人id
    /// @params accountID: 联系人所属账号id
    /// @params limit: 拉取数量
    func getNamecardList(namecardId: String?, accountID: String, limit: Int) -> Observable<NameCardList> {
        var request = RustPB.Email_Client_V1_GetNamecardListRequest()
        request.accountID = accountID
        request.namecardID = namecardId ?? "0"
        request.limit = UInt32(limit)
        return client.sendAsyncRequest(
            request,
            transform: { (response: RustPB.Email_Client_V1_GetNamecardListResponse) -> NameCardList in
                let list = response.list
                .map { (nameCardPB) -> NameCardInfo in
                    return NameCardInfo.transform(nameCardListPB: nameCardPB)
                }
                let nameCardList = NameCardList(list: list, hasMore: response.more)
                return nameCardList
            })
    }

    /// 添加联系人个人信息
    /// @params namecardInfo: 描述联系人的结构体
    /// @params accountID: 联系人所属账号id
    func setSingleNamecard(namecardInfo: RustPB.Email_Client_V1_NamecardMetaInfo, accountID: String) -> Observable<RustPB.Email_Client_V1_SetSingleNamecardResponse> {
        var request = RustPB.Email_Client_V1_SetSingleNamecardRequest()
        request.accountID = accountID
        request.namecardInfo = namecardInfo
        return client.sendAsyncRequest(request)
    }

    /// 更新联系人信息
    /// @params namecard: 描述联系人的结构体
    /// @params accountID: 联系人所属账号id
    func updateSingleNamecard(namecard: RustPB.Email_Client_V1_NamecardMetaInfo, accountID: String) -> Observable<RustPB.Email_Client_V1_UpdateSingleNamecardResponse> {
        var request = RustPB.Email_Client_V1_UpdateSingleNamecardRequest()
        request.namecard = namecard
        request.accountID = accountID
        return client.sendAsyncRequest(request)
    }

    /// 删除联系人
    /// @params id: 联系人id
    /// @params accountID: 联系人所属账号id
    func deleteSingleNamecard(_ id: String, accountID: String, address: String) -> Observable<RustPB.Email_Client_V1_DeleteSingleNamecardResponse> {
        var request = RustPB.Email_Client_V1_DeleteSingleNamecardRequest()
        request.namecardID = id
        request.accountID = accountID
        request.emailAddress = address
        return client.sendAsyncRequest(request)
    }

    /// 获取联系人信息
    /// @params id: 联系人id
    func getNamecardsByID(_ id: String, accountID: String) -> Observable<RustPB.Email_Client_V1_NamecardMetaInfo?> {
        var request = RustPB.Email_Client_V1_GetNamecardsByIDsRequest()
        request.namecardIds = [id]
        request.accountID = accountID
        return client.sendAsyncRequest(
            request,
            transform: { (res: RustPB.Email_Client_V1_GetNamecardsByIDsResponse) -> RustPB.Email_Client_V1_NamecardMetaInfo? in
                return res.namecards[id]
            })
    }

    /// 获取本地名片夹联系人的profile信息
    /// @params namecardId: 联系人namecardId
    /// @params email: 联系人email地址
    /// @params accountID: 联系人所属账号id
    func getLocalNamecardProfile(_ namecardId: String, email: String, accountID: String) -> Observable<NameCardUserProfile> {
        var query = RustPB.Email_Client_V1_QueryCondition()
        if !namecardId.isEmpty {
            query.namecardID = namecardId
        } else if !email.isEmpty {
            query.email = email
        }
        var request = RustPB.Email_Client_V1_GetNamecardProfileRequest()
        request.accountID = accountID
        request.queryCondition = query
        request.syncDataStrategy = .local
        return client.sendAsyncRequest(request)
    }

    /// 获取联系人的profile信息
    /// @params id: 联系人id
    /// @params strategy: 数据获取策略
    /// @params accountID: 联系人所属账号id
    func getRemoteNamecardProfile(_ namecardId: String, email: String, accountID: String) -> Observable<NameCardUserProfile> {
        var query = RustPB.Email_Client_V1_QueryCondition()
        if !namecardId.isEmpty {
            query.namecardID = namecardId
        } else if !email.isEmpty {
            query.email = email
        }
        var request = RustPB.Email_Client_V1_GetNamecardProfileRequest()
        request.accountID = accountID
        request.queryCondition = query
        request.syncDataStrategy = .forceServer
        return client.sendAsyncRequest(request)
    }

    /// 是否展示管理邮件组tab
    func getMailContactGroupTabShowStatus() -> Observable<Bool> {
        let request = RustPB.Email_Client_V1_MailContactTabStatusRequest()
        return client.sendAsyncRequest(request) { (res: RustPB.Email_Client_V1_MailContactTabStatusResponse) -> Bool in
            return res.showManageMailGroups
        }
    }

    /// 获取我管理的邮件组列表
    /// - Parameters:
    ///  - source: 请求类型
    func getMailManagedGroups(source: MailContactRequestSource) -> Observable<([Email_Client_V1_MailGroup], MailContactRequestSource)> {
        var request = RustPB.Email_Client_V1_MailManagedGroupsRequest()
        request.reqSource = source
        return client.sendAsyncRequest(request) { (res: RustPB.Email_Client_V1_MailManagedGroupsResponse) -> ([Email_Client_V1_MailGroup], MailContactRequestSource) in
            return (res.groupList, res.respSource)
        }
    }

    /// 获取邮件组详情
    /// - Parameters:
    ///   - groupId: 邮件组id
    ///   - source: 请求类型
    func getMailGroupDetail(_ groupId: Int,
                            source: MailContactRequestSource) -> Observable<RustPB.Email_Client_V1_MailGroupDetailResponse> {
        var request = RustPB.Email_Client_V1_MailGroupDetailRequest()
        request.groupID = Int64(groupId)
        request.reqSource = source
        return client.sendAsyncRequest(request)
    }

    /// 分页获取
    /// - Parameters:
    ///   - groupId: 群id
    ///   - accountID: 邮件组所属账号id
    ///   - index: 分页下标
    ///   - pageSize: 每页个数
    ///   - indexToken: token
    ///   - role: 群成员 / 管理员
    ///   - source: 请求类型
    func getMailGroupMembersList(_ groupId: Int,
                                 pageSize: Int,
                                 indexToken: String,
                                 role: RustPB.Email_Client_V1_MailGroupRole,
                                 source: MailContactRequestSource) -> Observable<RustPB.Email_Client_V1_MailGroupMembersResponse> {
        var request = RustPB.Email_Client_V1_MailGroupMembersRequest()
        request.groupID = Int64(groupId)
        request.pageSize = Int64(pageSize)
        request.indexToken = indexToken
        request.role = role
        request.reqSource = source
        return client.sendAsyncRequest(request)
    }

    func updateMailGroupInfo(_ groupId: Int,
                             accountID: String,
                             permission: MailContactGroup.PermissionType?,
                             addMember: [RustPB.Email_Client_V1_MailGroupMember]?,
                             deletedMember: [RustPB.Email_Client_V1_MailGroupMember]?,
                             addManager: [RustPB.Email_Client_V1_MailGroupManager]?,
                             deletedManager: [RustPB.Email_Client_V1_MailGroupManager]?,
                             addPermissionMember: [RustPB.Email_Client_V1_MailGroupPermissionMember]?,
                             deletePermissionMember: [RustPB.Email_Client_V1_MailGroupPermissionMember]?) -> Observable<MailGroupUpdateResponse> {
        var request = RustPB.Email_Client_V1_MailUpdateGroupRequest()
        request.groupID = Int64(groupId)
        if let permis = permission {
            request.permissionType = permis
        }
        if let add = addMember {
            request.addedMember = add
        }
        if let deleteMem = deletedMember {
            request.deletedMembers = deleteMem
        }
        if let addMem = deletedMember {
            request.addedMember = addMem
        }
        if let deleteMana = deletedManager {
            request.deletedManagerMembers = deleteMana
        }
        if let addMana = addManager {
            request.addedManagerMembers = addMana
        }
        if let addPermiss = addPermissionMember {
            request.addedPermissionMembers = addPermiss
        }
        if let deletePermiss = deletePermissionMember {
            request.deletedPermissionMembers = deletePermiss
        }
        return client.sendAsyncRequest(request)
    }

    func updateMailRemark(_ groupId: Int, description: String) -> Observable<()> {
        var request = RustPB.Email_Client_V1_MailUpdateGroupRequest()
        request.groupID = Int64(groupId)
        request.description_p = description
        return client.sendAsyncRequest(request)
    }

    // swiftlint:disable closure_parameter_position
    func getSharedEmailAccountsList(indexToken: String, pageSize: Int, source: MailContactRequestSource) -> Observable < (hasMore: Bool,
                                                                                      indexToken: String,
                                                                                      [MailSharedEmailAccount])> {
        var request = RustPB.Email_Client_V1_MailSharedEmailAccountsRequest()
        request.indexToken = indexToken
        request.pageSize = Int64(pageSize)
        return client.sendAsyncRequest(request) {
            (res: RustPB.Email_Client_V1_MailSharedEmailAccountsResponse) -> (Bool, String, [MailSharedEmailAccount]) in
            return (res.hasMore_p, res.indexToken, res.accounts)
        }
    }
    // swiftlint:enable closure_parameter_position

    func mailCheckGroupMemberIsExist(groupId: Int,
                                     member: [MailGroupMember]?,
                                     manager: [MailGroupManager]?,
                                     permissionMember: [MailGroupPermissionMember]?) -> Observable < (existMember: [MailGroupMember],
                                                                                                  existManager: [MailGroupManager],
                                                                                                  existPermissionMember: [MailGroupPermissionMember])> {
        var request = RustPB.Email_Client_V1_MailCheckGroupMemberExistenceRequest()
        request.groupID = Int64(groupId)
        if let m = member {
            request.members = m
        }
        if let m = manager {
            request.managers = m
        }
        if let m = permissionMember {
            request.permissionMembers = m
        }
        return client.sendAsyncRequest(request) { (response: Email_Client_V1_MailCheckGroupMemberExistenceResponse) in
            return (response.existedMembers, response.existedManagers, response.existedPermissionMembers)
        }
    }

    func checkEmailIsAlreadyInGroupMembers(groupId: Int, email: String) -> Observable<(Bool)> {
        var request = ServerPB.ServerPB_Mails_CheckMailGroupMemberInfoRequest()
        request.groupID = Int64(groupId)
        request.mailAddressList = [email]
        return client.sendPassThroughAsyncRequest(request, serCommand: .mailCheckGroupMemberInfo)
            .map { (response: ServerPB.ServerPB_Mails_CheckMailGroupMemberInfoResponse) in
                return !response.memberList.isEmpty && response.memberList[0].status == .wrong
            }
    }

    func getEmailsMembersInfo(groupId: Int, email: [String]) -> Observable<[ServerPB_Mail_entities_MailGroupMember]> {
        var request = ServerPB.ServerPB_Mails_CheckMailGroupMemberInfoRequest()
        request.groupID = Int64(groupId)
        request.mailAddressList = email
        return client.sendPassThroughAsyncRequest(request, serCommand: .mailCheckGroupMemberInfo)
            .map { (response: ServerPB.ServerPB_Mails_CheckMailGroupMemberInfoResponse) in
                return response.memberList
            }
    }

    func checkServerMailGroupPermission() -> Observable<Bool> {
        var request = ServerPB.ServerPB_Mails_CheckUserGroupPermissionRequest()
        return client.sendPassThroughAsyncRequest(request, serCommand: .mailCheckUserGroupPermission)
            .map { (response: ServerPB.ServerPB_Mails_CheckUserGroupPermissionResponse) in
                return response.hasGroupManagementPermission_p
            }
    }

    /// 获取当前账号的所有邮箱账号及邮箱账号下的联系人和群组数量
    func getAllMailAccountDetail(latest: Bool) -> Observable<[MailAccountBriefInfo]> {
        var briefRequest = RustPB.Email_Client_V1_GetMailContactMetaRequest()
        briefRequest.latest = latest
        let briefResponse = client.sendAsyncRequest(
            briefRequest,
            transform: { (response: RustPB.Email_Client_V1_GetMailContactMetaResponse) -> [MailAccountBriefInfo] in
                return response.meta.map({ MailAccountBriefInfo.transform(from: $0) })
            }
        )

        let listResponse = getMailAccountList()

        return Observable.zip(briefResponse, listResponse).map({ [weak self] (infos: [MailAccountBriefInfo], addresses: [String]) -> [MailAccountBriefInfo] in
            guard let self = self else { return infos }
            return self.sortInfos(infos, accountList: addresses)
        })
    }

    func sortMailAccountInfos(_ infos: [MailAccountBriefInfo]) -> Observable<[MailAccountBriefInfo]> {
        return getMailAccountList().map({ [weak self] (accountList: [String]) -> [MailAccountBriefInfo] in
            guard let self = self else { return infos }
            return self.sortInfos(infos, accountList: accountList)
        })
    }

    /// 获取当前邮箱账号类型
    func getCurrentMailAccountType() -> Observable<String> {
        var listRequest = RustPB.Email_Client_V1_MailGetAccountRequest()
        listRequest.fetchDb = true
        listRequest.fetchCurrentAccount = true
        return client.sendAsyncRequest(
            listRequest,
            transform: {(response: Email_Client_V1_MailGetAccountResponse) -> String in
                switch response.account.mailSetting.userType {
                case .larkServer, .larkServerUnbind, .gmailApiClient, .exchangeApiClient:
                    return "lms"
                case .oauthClient, .newUser:
                    return "gmailClient"
                case .exchangeClient, .exchangeClientNewUser:
                    return "exchangeClient"
                case .tripartiteClient:
                    return "imap"
                @unknown default:
                    return "None"
                }
            })
    }

    private func getMailAccountList() -> Observable<[String]> {
        var listRequest = RustPB.Email_Client_V1_MailGetAccountRequest()
        listRequest.fetchDb = true
        listRequest.fetchCurrentAccount = false
        return client.sendAsyncRequest(
            listRequest,
            transform: {(response: Email_Client_V1_MailGetAccountResponse) -> [String] in
                var result = [response.account.accountAddress]
                result.append(contentsOf: response.account.sharedAccounts.map({ $0.accountAddress }))
                return result
            })
    }

    // 联系人邮箱账号顺序需要和邮箱设置保持一致
    private func sortInfos(_ infos: [MailAccountBriefInfo], accountList: [String]) -> [MailAccountBriefInfo] {
        var result = [MailAccountBriefInfo]()
        var infoMap = [String: MailAccountBriefInfo]()
        infos.map({ infoMap[$0.address] = $0 })
        for address in accountList {
            guard !address.isEmpty, let info = infoMap[address] else { continue }
            result.append(info)
        }
        infos.filter({ $0.address.isEmpty }).forEach({ result.insert($0, at: 0) })
        return result
    }
}
