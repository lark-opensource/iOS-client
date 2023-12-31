//
//  DataService+Reaction.swift
//  MailSDK
//
//  Created by tefeng liu on 2022/5/30.
//

import Foundation
import RustPB
import RxSwift
import ServerPB

typealias MailAddressNameRequest = RustPB.Email_Client_V1_GetAddressNameRequest
typealias MailAddressNameResponse = RustPB.Email_Client_V1_GetAddressNameResponse

typealias AddressRequestItem = RustPB.Email_Client_V1_AddressNameRequestItem
typealias AddressResponseItem = RustPB.Email_Client_V1_AddressName


typealias MailAIGetTaskReq = ServerPB_Mail_ai_MailAIActionGetTaskParamsRequest
typealias MailAIGetTaskResp = ServerPB_Mail_ai_MailAIActionGetTaskParamsResponse
typealias MailAIGetDraftReq = ServerPB_Mail_ai_MailAIActionGetDraftContentRequest
typealias MailAIGetDraftResp = ServerPB_Mail_ai_MailAIActionGetDraftContentResponse

typealias MailMarkAllReadReq = RustPB.Email_Client_V1_MailMutMultiLabelRequest
typealias MailMarkAllReadResp = RustPB.Email_Client_V1_MailMutMultiLabelResponse
typealias ThreadMsgsItem = RustPB.Email_Client_V1_MailMutMultiLabelRequest.ThreadMsgs


extension DataService {
    func getMailAddressNames(addressList: [AddressRequestItem]) -> Observable<MailAddressNameResponse> {
        var req = Email_Client_V1_GetAddressNameRequest()
        req.addressList = addressList
        return sendAsyncRequest(req).observeOn(MainScheduler.instance)
    }
    func getMailAddressNamesAsync(addressList: [AddressRequestItem]) -> Observable<MailAddressNameResponse> {
        var req = Email_Client_V1_GetAddressNameRequest()
        req.addressList = addressList
        if MailMessageListViewsPool.fpsOpt {
            return sendAsyncRequest(req)
        } else {
            return sendAsyncRequest(req).observeOn(MainScheduler.instance)
        }
    }
}

extension DataService {
    func getAITaskId(id: String) -> Observable<MailAIGetTaskResp> {
        var req = MailAIGetTaskReq()
        req.id = id
        return sendPassThroughAsyncRequest(req,
                                            serCommand: .mailAiActionGetTaskParams).observeOn(MainScheduler.instance).map { (resp: MailAIGetTaskResp) ->
            MailAIGetTaskResp in
            return resp
        }
    }
    func getAIDraftContent(id: String) -> Observable<MailAIGetDraftResp> {
        var req = MailAIGetDraftReq()
        req.id = id
        return sendPassThroughAsyncRequest(req,
                                            serCommand: .mailAiActionGetDraftContent).observeOn(MainScheduler.instance).map { (resp: MailAIGetDraftResp) ->
            MailAIGetDraftResp in
            return resp
        }
    }
    
    func markAllRead(msgArray: [ThreadMsgsItem]) -> Observable<MailMarkAllReadResp> {
        var request = MailMarkAllReadReq()
        request.fromLabel = "INBOX"
        request.threadMsgs = msgArray
        request.removeLabelIds = [Mail_LabelId_UNREAD]
        return sendAsyncRequest(request).observeOn(MainScheduler.instance).map { (resp: MailMarkAllReadResp) ->
            MailMarkAllReadResp in
            return resp
        }
    }
}
