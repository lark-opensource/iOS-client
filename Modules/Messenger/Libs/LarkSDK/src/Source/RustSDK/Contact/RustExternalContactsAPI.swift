//
//  RustExternalContactsAPI.swift
//  LarkSDK
//
//  Created by 姚启灏 on 2018/8/14.
//

import Foundation
import RustPB
import LarkSDKInterface
import LarkModel
import RxSwift
import RxCocoa

final class RustExternalContactsAPI: LarkAPI, ExternalContactsAPI {
    func fetchExternalContacts(cursor: String, count: Int) -> Observable<ExternalContacts> {
        var request = RustPB.Im_V1_GetContactsRequest()
        request.cursor = cursor
        request.count = Int32(count)
        return self.client.sendAsyncRequest(request, transform: { (response: RustPB.Im_V1_GetContactsResponse) -> ExternalContacts in
            let contacts = response.contacts
                .filter({ (PBContact) -> Bool in return !PBContact.isDeleted })
                .map({ (PBContact) -> Contact in
                    let contact = Contact.transform(pb: PBContact)
                    if let pbChatter = response.entity.chatters[contact.chatterId] {
                        let chatter = LarkModel.Chatter.transform(pb: pbChatter)
                        contact.chatter = chatter
                    }
                    return contact
                })
            let externalContacts = ExternalContacts(contacts: contacts, hasMore: response.hasMore_p)
            return externalContacts
        })
    }

    func deleteContact(userId: String) -> Observable<Void> {
        var request = RustPB.Im_V1_DeleteContactRequest()
        request.userID = userId
        return self.client.sendAsyncRequest(request)
    }

    func fetchTenant(tenantIds: [String]) -> Observable<[Tenant]> {
        var request = RustPB.Contact_V1_MGetTenantsRequest()
        // fixbug：目前有小程序可修改租户名，故应每次都从服务端获取数据，保证租户名正确
        request.syncDataStrategy = .forceServer
        request.tenantIds = tenantIds
        return self.client.sendAsyncRequest(request, transform: { (response: RustPB.Contact_V1_MGetTenantsResponse) -> [Tenant] in
            var tenants: [Tenant] = []
            tenantIds.forEach({ (id) in
                if let PBTenant = response.entity.tenants[id] {
                    tenants.append(Tenant.transform(pb: PBTenant))
                }
            })
            return tenants
        })
    }

    func getTenant(tenantIds: [String]) -> Observable<[Tenant]> {
        var request = RustPB.Contact_V1_MGetTenantsRequest()
        request.syncDataStrategy = .tryLocal
        request.tenantIds = tenantIds
        return self.client.sendAsyncRequest(request, transform: { (response: RustPB.Contact_V1_MGetTenantsResponse) -> [Tenant] in
            var tenants: [Tenant] = []
            tenantIds.forEach({ (id) in
                if let PBTenant = response.entity.tenants[id] {
                    tenants.append(Tenant.transform(pb: PBTenant))
                }
            })
            return tenants
        })
    }

    func fetchExternalContacts(with chatID: String?, businessScene: Basic_V1_Auth_ActionType?, cursor: String, count: Int) -> Observable<ExternalContactsWithChatterIds> {
        var request = RustPB.Contact_V1_GetContactsCombineChatRequest()
        if let chatID = chatID {
            request.chatID = chatID
        }
        if let scene = businessScene {
            request.businessScene = scene
        }
        request.cursor = cursor
        request.count = Int32(count)
        return self.client.sendAsyncRequest(request, transform: { (response: RustPB.Contact_V1_GetContactsCombineChatResponse) -> ExternalContactsWithChatterIds in
            let contacts = response.contacts
                .filter { (pBContact) -> Bool in return !pBContact.isDeleted }
                .map { (pBContact) -> Contact in
                    let contact = Contact.transform(pb: pBContact)
                    if let pBChatter = response.entity.chatters[contact.chatterId] {
                        let chatter = LarkModel.Chatter.transform(pb: pBChatter)
                        contact.chatter = chatter
                    }
                    return contact
                }
            let externalContacts = ExternalContacts(contacts: contacts, hasMore: response.hasMore_p)
            let externalContactsWithChatterIds = ExternalContactsWithChatterIds(
                externalContacts: externalContacts,
                chatterIDs: response.inChatChatterIds,
                deniedReasons: response.authResult.deniedReasons
            )
            return externalContactsWithChatterIds
        })
    }

    /// 获取外部联系人列表
    /// @params strategy: 数据拉取策略，支持 local 和 forceServer
    /// @params offset: 从哪个偏移位置开始拉取, 默认从 0 开始拉
    /// @params limitCount: 一次取多少条数据
    func getNewExternalContactList(strategy: RustPB.Basic_V1_SyncDataStrategy? = .forceServer,
                                offset: Int? = nil,
                                limitCount: Int? = nil) -> Observable<NewExternalContacts> {
        var request = RustPB.Contact_V2_GetExternalContactListRequest()
        if let strategy = strategy {
            request.strategy = strategy
        }
        if let offset = offset {
            request.offset = Int64(offset)
        }
        if let limitCount = limitCount {
            request.limit = Int64(limitCount)
        }
        return self.client.sendAsyncRequest(
            request,
            transform: { (response: RustPB.Contact_V2_GetExternalContactListResponse) -> NewExternalContacts in
                let contacts = response.contacts
                    .map { (contact) -> ContactInfo in
                        return ContactInfo.transform(contactInfoPB: contact)
                    }
                let externalContacts = NewExternalContacts(contactInfos: contacts)
                return externalContacts
            })
    }

    func fetchExternalContactsWithCollaborationAuth(
        with chatID: String? = nil,
        actionType: RustPB.Basic_V1_Auth_ActionType? = nil,
        offset: Int? = nil,
        count: Int? = nil
    ) -> Observable<NewExternalContactsWithChatterIds> {
        var request = RustPB.Contact_V2_GetExternContactsCombineAuthInfoRequest()
        if let chatID = chatID {
            request.chatID = chatID
        }
        if let offset = offset {
            request.offset = Int32(offset)
        }
        if let count = count {
            request.limit = Int64(count)
        }
        if let actionType = actionType {
            request.actionType = actionType
        }
        return self.client.sendAsyncRequest(
            request,
            transform: { (response: RustPB.Contact_V2_GetExternContactsCombineAuthInfoResponse) -> NewExternalContactsWithChatterIds in
                let contacts = response.contacts
                    .map { (contact) -> NewSelectExternalContact in
                        let contactInfo = ContactInfo.transform(contactInfoPB: contact)
                        var selectExternalContact = NewSelectExternalContact(contactInfo: contactInfo)
                        if let pBChatter = response.entity.chatters[contact.userInfo.userID] {
                            let chatter = LarkModel.Chatter.transform(pb: pBChatter)
                            selectExternalContact.chatter = chatter
                            if let deniedReason = response.id2DeniedReason[contact.userInfo.userID] {
                                selectExternalContact.deniedReason = deniedReason
                            }
                        }
                        return selectExternalContact
                    }
                let externalContactsWithChatterIds = NewExternalContactsWithChatterIds(selectExternalContacts: contacts, chatterIDs: response.inChatChatterIds, hasMore: response.hasMore_p)
                return externalContactsWithChatterIds
            })
    }

    /// 屏蔽/取消屏蔽
    func setupUserBlockUserRequest(blockUserId: String, blockStatus: Bool) -> Observable<SetupBlockUserResponse> {
        var request = SetupBlockUserRequest()
        request.blockUserID = blockUserId
        request.blockStatus = blockStatus

        return self.client.sendAsyncRequest(request)
    }

    /// 关闭联系人的好友申请 Banner
    func ignoreContactApplyRequest(userId: String) -> Observable<IgnoreContactApplyResponse> {
        var request = IgnoreContactApplyRequest()
        request.targetUserID = userId

        return self.client.sendAsyncRequest(request)
    }

    // 获取外部用户的关系
    func fetchUserRelationRequest(userId: String) -> Observable<FetchUserRelationResponse> {
        var request = FetchUserRelationRequest()
        request.targetUserID = userId

        return self.client.sendAsyncRequest(request)
    }

    /// 批量发送好友申请
    func mSendContactApplicationRequest(userIds: [String],
                                        extraMessage: String? = nil,
                                        sourceInfos: [String: RustPB.Contact_V2_SourceInfo]
    ) -> Observable<MSendContactApplicationResponse> {
        var request = MSendContactApplicationRequest()
        request.userIds = userIds
        request.sourceInfos = sourceInfos

        return self.client.sendAsyncRequest(request)
    }

    // 批量查询外部联系人的chatId
    func checkP2PChatsExistByUserRequest(chatterIds: [String]) -> Observable<CheckP2PChatsExistByUserResponse> {
        var request = CheckP2PChatsExistByUserRequest()
        request.chatterIds = chatterIds

        return self.client.sendAsyncRequest(request)
    }
}
