//
//  DataService+Attachment.swift
//  MailSDK
//
//  Created by ByteDance on 2023/5/17.
//

import Foundation
import RustPB
import RxSwift
import SwiftProtobuf
import Homeric
import ServerPB


extension DataService {
    static let pageSize: Int32 = 20
    func listLargeAttachmentRequest(_ orderFiled: MailOrderFiled, orderType: MailOrderType, sessionId: String, transferFolderKey: String, accountID: String) -> Observable<MailListLargeAttachmentResp> {
        var request = MailListLargeAttachmentReq()
        request.orderType = orderType
        request.orderFiled = orderFiled
        request.pageSize = DataService.pageSize // pm要求每页20条
        request.nextSessionID = sessionId
        request.transferFolderKey = transferFolderKey
        request.base = genRequestBaseWithAccountId(accountId: accountID)
        return sendPassThroughAsyncRequest(request, serCommand: .mailListLargeAttachment, mailAccountID: accountID).observeOn(MainScheduler.instance).map {(resp:MailListLargeAttachmentResp) -> MailListLargeAttachmentResp in
            return resp
        }
    }
    
    func deleteLargeAttachmentRequest(_ fileTokenList: [String], isDraftDelete: Bool, meessageBizID: String) -> Observable<MailDeleteLargeAttachmentResp> {
        var request = MailDeleteLargeAttachmentReq()
        request.fileTokenList = fileTokenList
        request.isDraftDelete = isDraftDelete
        request.mailMessageBizID = meessageBizID
        request.base = genRequestBase()
        return sendPassThroughAsyncRequest(request, serCommand: .mailMultiDeleteLargeAttachment).observeOn(MainScheduler.instance).map {(resp:MailDeleteLargeAttachmentResp) -> MailDeleteLargeAttachmentResp in
            return resp
        }
    }
    
    func largeAttachmentCapacityRequest(accountID: String) -> Observable<MailLargeAttachmentCapacityResp> {
        var request = MailLargeAttachmentCapacityReq()
        request.base = genRequestBaseWithAccountId(accountId: accountID)
        return sendPassThroughAsyncRequest(request, serCommand: .mailGetLargeAttachmentCapacity, mailAccountID: accountID).observeOn(MainScheduler.instance).map{(resp:MailLargeAttachmentCapacityResp) -> MailLargeAttachmentCapacityResp in
            return resp
        }
    }
    // 容量限制查询
    func checkAttachmentMountPermissionRequest(attachmentsSize: Int64) -> Observable<MailCheckAttachmentMountPermissionResp> {
        var request = MailCheckAttachmentMountPermissionReq()
        request.attachmentSize = attachmentsSize
        return sendPassThroughAsyncRequest(request, serCommand:.mailCheckAttachmentMountPermission).observeOn(MainScheduler.instance).map{(resp:MailCheckAttachmentMountPermissionResp) ->
            MailCheckAttachmentMountPermissionResp in
            return resp
        }
    }
}


