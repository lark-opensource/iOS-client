//
//  DataService+ Contact.swift
//  MailSDK
//
//  Created by tefeng liu on 2019/8/15.
//

import Foundation
import RustPB
import RxSwift
import ServerPB

struct ContactSearchInfo {
    let total: Int32
    let hasMore: Bool
    let fromLocal: Bool
    var searchSession: String? = nil
}

extension DataService {
    func mailAtContactSearch(keyword: String, session: String) -> Observable<(results: [Email_Client_V1_SearchMemberInfo], info: ContactSearchInfo)> {
        var request = Email_Client_V1_MailAtContactRequest()
        request.searchSession = session
        request.keyword = keyword
        return sendAsyncRequest(request, transform: { (response: Email_Client_V1_MailAtContactResponse) -> ([Email_Client_V1_SearchMemberInfo], ContactSearchInfo) in
            let info = ContactSearchInfo(total: Int32(response.members.count), hasMore: response.hasMore_p, fromLocal: false)
            return (response.members, info)
        }).observeOn(MainScheduler.instance)
    }

    func mailContactSearch(query: String, session: String, begin: Int32, end: Int32, groupEmailAccount: Email_Client_V1_GroupEmailAccount?) -> Observable<(results: [Email_Client_V1_MailContactSearchResult], info: ContactSearchInfo)> {
        var request = Email_Client_V1_MailContactSearchRequest()
        request.query = query
        request.begin = begin
        request.end = end
        if let groupEmailAccount = groupEmailAccount {
            request.groupEmailAccount = groupEmailAccount
        }
        request.searchSession = session
        return sendAsyncRequest(request, transform: { (response: Email_Client_V1_MailContactSearchResponse) -> ([Email_Client_V1_MailContactSearchResult], ContactSearchInfo) in
            let info = ContactSearchInfo(total: response.total, hasMore: response.hasMore_p, fromLocal: response.fromLocal, searchSession: response.searchSession)
            return (response.results, info)
        }).observeOn(MainScheduler.instance)
    }

    func mailAddressSearch(address: String, session: String) -> Observable<(results: [Email_Client_V1_MailContactSearchResult], info: ContactSearchInfo)> {
        var request = Email_Client_V1_MailContactSearchRequest()
        request.query = address
        request.begin = 0
        request.end = 3
        request.searchSession = session
        return sendAsyncRequest(request, transform: { (response: Email_Client_V1_MailContactSearchResponse) -> ([Email_Client_V1_MailContactSearchResult], ContactSearchInfo) in
            let info = ContactSearchInfo(total: response.total, hasMore: response.hasMore_p, fromLocal: response.fromLocal)
            return (response.results, info)
        }).observeOn(MainScheduler.instance)
    }

    /// 支持 saas 和 三方
    func mailDeleteExternContact(address: String) -> Observable<Email_Client_V1_MailDeleteContactResponse> {
        var request = Email_Client_V1_MailDeleteContactRequest()
        request.mailAddress = address
        return sendAsyncRequest(request).observeOn(MainScheduler.instance)
    }

    /// 透传，仅支持 saas
    func mailDeleteExternAddress(address: String) -> Observable<ServerPB_Mails_DeleteMailExternalContactResponse> {
        var request = ServerPB_Mails_DeleteMailExternalContactRequest()
        request.mailAddress = address
        request.base = genRequestBase()
        return sendPassThroughAsyncRequest(request,
                                            serCommand: .mailDeleteMailExternalContact).observeOn(MainScheduler.instance).map { (resp: ServerPB_Mails_DeleteMailExternalContactResponse) ->
                                            ServerPB_Mails_DeleteMailExternalContactResponse in
            return resp
        }
    }

    /// 获取Admin发信规模限制配置
    func mailGetRecipientCountLimit() -> Observable<Email_Client_V1_MailGetRecipientCountLimitResponse> {
        var request = Email_Client_V1_MailGetRecipientCountLimitRequest()
        return sendAsyncRequest(request).observeOn(MainScheduler.instance)
    }

    /// 获取收件人群组/邮件组人数
    func mailCheckGroupMemberCount(sessionID: String, groupInfos: [Email_Client_V1_GroupMemberCountInfo]) -> Observable<[Email_Client_V1_GroupMemberCountInfo]> {
        var request = Email_Client_V1_MailCheckGroupMemberCountRequest()
        request.sessionID = sessionID
        request.groupInfos = groupInfos
        return sendAsyncRequest(request, transform: { (response: Email_Client_V1_MailCheckGroupMemberCountResponse) -> ([Email_Client_V1_GroupMemberCountInfo]) in
            return response.groupInfos
        }).observeOn(MainScheduler.instance)
    }
}
