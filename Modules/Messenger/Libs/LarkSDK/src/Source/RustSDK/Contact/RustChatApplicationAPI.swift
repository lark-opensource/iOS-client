//
//  RustChatApplicationAPI.swift
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
import LKCommonsLogging
import ServerPB

final class RustChatApplicationAPI: LarkAPI, ChatApplicationAPI {
    private static let logger = Logger.log(RustChatApplicationAPI.self)

    func getChatApplications(cursor: String,
                             count: Int,
                             type: RustPB.Basic_V1_ChatApplication.TypeEnum,
                             getType: GetType,
                             chatId: String) -> Observable<ChatApplicationGroup> {
        var request = RustPB.Im_V1_GetChatApplicationsRequest()
        request.cursor = cursor
        request.count = Int32(count)
        request.type = type
        request.getType = RustPB.Im_V1_GetChatApplicationsRequest.GetType(rawValue: Int(getType.rawValue)) ?? .before
        request.chatID = chatId

        return self.client.sendAsyncRequest(request, transform: { (response: RustPB.Im_V1_GetChatApplicationsResponse) -> ChatApplicationGroup in
            let applications = response.applications
                .filter({ (application) -> Bool in
                    return application.status != .deleted
                }).map({ (application) -> ChatApplication in
                    return ChatApplication.transform(pb: application)
                })
            RustChatApplicationAPI.logger.info("response count: \(response.applications.count), result count: \(applications.count)")

            var responseApplicationIds = response.applications.compactMap { $0.id }
            var resultApplicationIds = applications.compactMap { $0.id }
            RustChatApplicationAPI.logger.info("response application ids: \(responseApplicationIds), result application ids: \(resultApplicationIds)")

            return ChatApplicationGroup(applications: applications, hasMore: response.hasMore_p)
        }).subscribeOn(scheduler)
    }

    func sendChatApplication(token: String?,
                             chatID: String?,
                             reason: String?,
                             userID: String?,
                             userAlias: String?,
                             source: Source?,
                             useAction: Bool?) -> Observable<RustPB.Im_V1_SendChatApplicationResponse> {
        var request = RustPB.Im_V1_SendChatApplicationRequest()

        if let token = token {
            request.token = token
        }
        if let chatID = chatID {
            request.chatID = chatID
        }
        if let reason = reason {
            request.extraMessage = reason
        }
        if let userID = userID {
            request.userID = userID
        }
        if let userAlias = userAlias {
            request.userAlias = userAlias
        }
        if let source = source {
            request.sender = source.sender
            request.senderID = source.senderID
            request.sourceName = source.sourceName
            request.subSourceType = source.subSourceType
            request.sourceID = source.sourceID
            if source.sourceType != .unknownSource {
                request.source = source.sourceType
            }
        }
        if let useAction = useAction {
            request.useTnsCrossBrandAction = useAction
        }
        request.expectStyle = .styleTypeAlert
        return self.client.sendAsyncRequest(request)
    }

    func processChatApplication(id: String, result: RustPB.Basic_V1_ChatApplication.Status, authSync: Bool) -> Observable<Void> {
        var request = RustPB.Im_V1_ProcessChatApplicationRequest()
        request.id = id
        request.status = result
        request.authSync = authSync
        return self.client.sendAsyncRequest(request)
    }

    func processChatApplication(userId: String, result: RustPB.Basic_V1_ChatApplication.Status) -> Observable<Void> {
        var request = RustPB.Im_V1_ProcessChatApplicationRequest()
        request.userID = userId
        request.status = result
        return self.client.sendAsyncRequest(request)
    }
    func updateChatApplicationMeRead() -> Observable<Void> {
        var request = RustPB.Im_V1_UpdateChatApplicationMeReadRequest()
        request.applicationIds = []
        request.readAllApplications = true
        return self.client.sendAsyncRequest(request)
    }

    func getChatApplicationBadge() -> Observable<ChatApplicationBadege> {
        let request = RustPB.Im_V1_GetChatApplicationBadgeRequest()
        return self.client.sendAsyncRequest(request, transform: { (response: RustPB.Im_V1_GetChatApplicationBadgeResponse) -> ChatApplicationBadege in
            return ChatApplicationBadege(chatBadge: Int(response.chatBadge), friendBadge: Int(response.friendBadge))
        })
    }

    func fetchInviteLinkInfoFromServer() -> Observable<RustPB.Im_V2_GetContactTokenResponse> {
        let request = RustPB.Im_V2_GetContactTokenRequest()
        return self.client.sendAsyncRequest(request)
    }

    func fetchInviteLinkInfoFromLocal() -> Observable<RustPB.Im_V2_GetContactTokenResponse> {
        var request = RustPB.Im_V2_GetContactTokenRequest()
        request.strategy = .local
        return self.client.sendAsyncRequest(request)
    }

    func fetchInviteGuideContext() -> Observable<ServerPB.ServerPB_Flow_TrySetUGEventStateResponse> {
        var request = ServerPB.ServerPB_Flow_TrySetUGEventStateRequest()
        request.bizKey = "guide_add_contact"
        request.newStates = "1"
        return self.client.sendPassThroughAsyncRequest(request, serCommand: .trySetUgEventState)
    }

    func getMyPromotionLink() -> Observable<String> {
        let request = RustPB.Contact_V1_GetMyPromotionLinkRequest()
        return self.client.sendAsyncRequest(request, transform: { (response: RustPB.Contact_V1_GetMyPromotionLinkResponse) -> String in
            return response.url
        })
    }

    func getPromotionRule() -> Observable<String> {
        let request = RustPB.Contact_V1_GetPromotionRuleRequest()
        return self.client.sendAsyncRequest(request, transform: { (response: RustPB.Contact_V1_GetPromotionRuleResponse) -> String in
            return response.text
        })
    }

    func invitationTenant(invitationType: RustPB.Contact_V1_SetBusinessInvitationRequest.TypeEnum, contactContent: String) -> Observable<TenantInvitationResult> {
        var request = RustPB.Contact_V1_SetBusinessInvitationRequest()
        request.type = invitationType
        request.contactContent = contactContent
        return self.client.sendAsyncRequest(request, transform: { (response: RustPB.Contact_V1_SetBusinessInvitationResponse) -> TenantInvitationResult in
            return TenantInvitationResult(success: response.success, url: response.url)
        })
    }

    func resetContactToken() -> Observable<String> {
        let request = RustPB.Im_V1_ResetContactTokenRequest()
        return self.client.sendAsyncRequest(request, transform: { (response: RustPB.Im_V1_ResetContactTokenResponse) -> String in
            return response.token
        })
    }

    func searchUser(contactContent: String) -> Observable<[UserProfile]> {
        var request = RustPB.Contact_V1_SearchUserByContactPointRequest()
        request.contactContent = contactContent
        return self.client.sendAsyncRequest(request, transform: { (response: RustPB.Contact_V1_SearchUserByContactPointResponse) -> [UserProfile] in
            let userProfiles = response.profiles.map({ (profileResponse) -> UserProfile in
                return UserProfile.transform(pb: profileResponse)
            })
            return userProfiles
        })
    }

    func searchUserWithActiveUser(contactContent: String) -> Observable<([UserProfile], String)> {
        var request = RustPB.Contact_V1_SearchUserByContactPointRequest()
        request.contactContent = contactContent
        return self.client.sendAsyncRequest(request, transform: { (response: RustPB.Contact_V1_SearchUserByContactPointResponse) -> ([UserProfile], String) in
            let userProfiles = response.profiles.map({ (profileResponse) -> UserProfile in
                return UserProfile.transform(pb: profileResponse)
            })
            return (userProfiles, response.activeUserID)
        })
    }

    func invitationUser(invitationType: RustPB.Contact_V1_SendUserInvitationRequest.TypeEnum, contactContent: String) -> Observable<InvitationResult> {
        var request = RustPB.Contact_V1_SendUserInvitationRequest()
        request.type = invitationType
        request.contactContent = contactContent
        return self.client.sendAsyncRequest(request, transform: { (response: RustPB.Contact_V1_SendUserInvitationResponse) -> InvitationResult in
            return InvitationResult(success: response.success, user: UserProfile.transform(pb: response.profile))
        })
    }

    func fetchMobileCode() -> Observable<MobileCodeData> {
        let request = RustPB.Statistics_V1_GetMobileCodeRequest()
        return self.client.sendAsyncRequest(request, transform: { (response: RustPB.Statistics_V1_GetMobileCodeResponse) -> MobileCodeData in
            let hotKeys = response.hotKeys.map({ (key) -> Int in
                return Int(key)
            })
            let mobileCodes = response.mobileCodes.map({ (mobileCode) -> MobileCode in
                return MobileCode(key: Int(mobileCode.key), name: mobileCode.name, enName: mobileCode.enName, code: mobileCode.code)
            })
            return MobileCodeData(hotKeys: hotKeys, mobileCodes: mobileCodes)
        })
    }

    func getAddressBookContactList(timelineMark: Int64? = nil,
                                   contactPoints: [String],
                                   strategy: SyncDataStrategy) -> Observable<AddressBookContactList> {
        var request = RustPB.Contact_V2_GetAddressBookContactListRequest()
        request.strategy = strategy
        if let timelineMark = timelineMark {
            request.timelineMark = timelineMark
        }
        request.contactPoints = contactPoints
        return self.client.sendAsyncRequest(request) { (resp) -> AddressBookContactList in
            return resp
        }.subscribeOn(scheduler)
    }
}
