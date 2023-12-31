//
//  DataService+mailToFeed.swift
//  MailSDK
//
//  Created by ByteDance on 2023/11/14.
//

import Foundation
import RustPB
import RxSwift
import SwiftProtobuf
import Homeric
import ServerPB

extension DataService {
    static let defaultPageSize: Int64 = 20
    // Feed进IM 关注接口
    func updateFollowStatus(action: Email_Client_V1_FollowAction, followeeList: [Email_Client_V1_FolloweeInfo]) -> Observable<([Email_Client_V1_FolloweeInfo])> {
        var request = Email_Client_V1_MailUpdateFollowStatusRequest()
        request.action = action
        request.followeeList = followeeList
        
        return sendAsyncRequest(request, transform: { (response: Email_Client_V1_MailUpdateFollowStatusResponse) -> ([Email_Client_V1_FolloweeInfo]) in
            return response.followeeList
        }).observeOn(MainScheduler.instance)
    }
    
    // Feed进IM 获取Feed入口，只传一个pageSize
    func getDraftsBtn(feedCardId: String) -> Observable<Email_Client_V1_MailGetFromViewResponse> {
        var request = Email_Client_V1_MailGetFromViewRequest()
        request.feedCardID = feedCardId
        request.pageSize = 1
        request.forceGetFromNet = false
        request.isDraft = true
        var orderParmsParams = Email_Client_V1_OrderParams()
        orderParmsParams.timestamp = 0
        orderParmsParams.timestampOperator = .olderThan
        request.orderParams = orderParmsParams
        return sendAsyncRequest(request, transform: { (response: Email_Client_V1_MailGetFromViewResponse) -> (Email_Client_V1_MailGetFromViewResponse) in
            return response
        }).observeOn(MainScheduler.instance)
    }
    
    // Feed进IM 获取Feed读信列表, timestampOperator
    func mailGetFromView(feedCardId: String,
                         timestampOperator: Bool,
                         timestamp: Int64,
                         forceGetFromNet: Bool,
                         isDraft: Bool) -> Observable<Email_Client_V1_MailGetFromViewResponse> {
        MailLogger.info("[mail_feed] mailGetFromView")
        var request = Email_Client_V1_MailGetFromViewRequest()
        request.feedCardID = feedCardId
        request.pageSize = DataService.defaultPageSize
        request.forceGetFromNet = forceGetFromNet
        request.isDraft = isDraft
        var orderParmsParams = Email_Client_V1_OrderParams()
        orderParmsParams.timestamp = timestamp
        orderParmsParams.timestampOperator = timestampOperator ? .newerThan : .olderThan
        request.orderParams = orderParmsParams
        return sendAsyncRequest(request, transform: { (response: Email_Client_V1_MailGetFromViewResponse) -> (Email_Client_V1_MailGetFromViewResponse) in
            return response
        }).observeOn(MainScheduler.instance)
    }
    
    // 获取feed name和邮箱
    func getFollowingListByID(feedCardId: String) -> Observable<(String, String)> {
        var request = Email_Client_V1_MailGetFollowingListByIDRequest()
        request.feedCardIds = [feedCardId]
        request.followType = .externalEmailAddress
        return sendAsyncRequest(request, transform: { (response: Email_Client_V1_MailGetFollowingListByIDResponse) -> (String, String) in
            guard let followee = response.followeeList.first else { return ("", "") }
            return (followee.name, followee.followeeID.externalMailAddress.mailAddress)
        }).observeOn(MainScheduler.instance)
    }

    func getFromItem(feedCardId: String, messageOrDraftIds: [String]) ->
        Observable<Email_Client_V1_MailMGetFromItemResponse> {
        var request = Email_Client_V1_MailMGetFromItemRequest()
            request.ids = messageOrDraftIds
            request.needClip = true
            request.feedCardID = feedCardId
        return sendAsyncRequest(request, transform: { (response: Email_Client_V1_MailMGetFromItemResponse) -> Email_Client_V1_MailMGetFromItemResponse in
            return response
        }).observeOn(MainScheduler.instance)
    }
    
    func getBlockedAddresses(addresses: [String]) -> Observable<[String]> {
        var request = Email_Client_V1_MailGetBlockedAddressesRequest()
        request.addresses = addresses
        return sendAsyncRequest(request, transform: { (response: Email_Client_V1_MailGetBlockedAddressesResponse) -> [String] in
            return response.blockedAddresses
        }).observeOn(MainScheduler.instance)
    }
    
    func getOutBoxMessageStateInFeed(feedCardID: String, messageIDs: [String]) -> Observable<[OutBoxMessageInfo]> {
        var request = Email_Client_V1_MailGetOutboxMessageStateRequest()
        request.feedCardID = feedCardID
        if !messageIDs.isEmpty {
            request.messageIds = messageIDs
        }
        return sendAsyncRequest(request, transform: { (response: Email_Client_V1_MailGetOutboxMessageStateResponse) -> [OutBoxMessageInfo] in
            return response.messageInfo
        }).observeOn(MainScheduler.instance)
    }
    // 获取重要联系人推荐
    func getMailImportantContacts(addresses: [String]) -> Observable<[String]> {
        var request = Email_Client_V1_MailImportantContactsRequest()
        request.action = .get
        request.addresses = addresses
        return sendAsyncRequest(request, transform: { (response: Email_Client_V1_MailImportantContactsResponse) -> [String] in
            return response.addresses
        }).observeOn(MainScheduler.instance)
    }
    // 统计联系人接口
    func statsMailImportantContacts(addresses: [String]) -> Observable<[String]>  {
        var request = Email_Client_V1_MailImportantContactsRequest()
        request.action = .stats
        request.addresses = addresses
        return sendAsyncRequest(request, transform: { (response: Email_Client_V1_MailImportantContactsResponse) -> [String] in
            return response.addresses
        }).observeOn(MainScheduler.instance)
    }
    // 取消联系人推荐
    func banMailImportantContacts(addresses: [String]) -> Observable<[String]>  {
        var request = Email_Client_V1_MailImportantContactsRequest()
        request.action = .ban
        request.addresses = addresses
        return sendAsyncRequest(request, transform: { (response: Email_Client_V1_MailImportantContactsResponse) -> [String] in
            return response.addresses
        }).observeOn(MainScheduler.instance)
    }
}
