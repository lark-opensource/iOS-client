//
//  DataService+MailClient.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2021/11/25.
//

import Foundation
import RustPB
import RxSwift
import SwiftProtobuf
import Homeric
import ServerPB

extension DataService {
    func getOauthUrl(provider: MailTripartiteProvider?, protocolConfig: Email_Client_V1_ProtocolConfig.ProtocolEnum?, address: String, accountID: String? = nil) -> Observable<Email_Client_V1_MailGetTripartiteAccountAuthUrlResponse> {
        MailLogger.info("[mail_client_token] providerConfig: \(protocolConfig ?? nil) address isEmpty: \(address.isEmpty) provider: \(provider ?? nil)")
        var request = Email_Client_V1_MailGetTripartiteAccountAuthUrlRequest()
        if let providerConfig = provider {
            request.provider = providerConfig
        }
        if let accID = accountID {
            request.accountID = accID
        }
        request.appLinkPath = "/client/mail/oauth"
        if let protoConfig = protocolConfig {
            request.protocol = protoConfig
        }
        if !address.isEmpty {
            request.address = address
        }
        return sendAsyncRequest(request, transform: {(response: Email_Client_V1_MailGetTripartiteAccountAuthUrlResponse) -> Email_Client_V1_MailGetTripartiteAccountAuthUrlResponse in
            DataService.logger.debug("[mail_client_token] getTripartiteOauthUrl success")
            return response
        }).observeOn(MainScheduler.instance)
    }
    // 三方账号创建 删除
    func createTripartiteAccount(taskID: String, account: MailTripartiteAccount, oauthParams: String? = nil) -> Observable<Email_Client_V1_MailCreateTripartiteAccountResponse> {
        var request = Email_Client_V1_MailCreateTripartiteAccountRequest()
        request.taskID = taskID
        request.account = account
        if let oauthParams = oauthParams {
            request.oauthParams = oauthParams
        }
        return sendAsyncRequest(request, transform: {(response: Email_Client_V1_MailCreateTripartiteAccountResponse) -> Email_Client_V1_MailCreateTripartiteAccountResponse in
            DataService.logger.debug("[mail_client] [mail_client_token] createTripartiteAccount success")
            return response
        }).observeOn(MainScheduler.instance)
    }

    func cancelCreateTripartiteAccount(taskID: String) -> Observable<Email_Client_V1_MailCancelCreateTripartiteAccountResponse> {
        var request = Email_Client_V1_MailCancelCreateTripartiteAccountRequest()
        request.taskID = taskID
        return sendAsyncRequest(request, transform: {(response: Email_Client_V1_MailCancelCreateTripartiteAccountResponse) -> Email_Client_V1_MailCancelCreateTripartiteAccountResponse in
            DataService.logger.debug("[mail_client] cancelCreateTripartiteAccount success")
            return response
        }).observeOn(MainScheduler.instance)
    }

    func deleteTripartiteAccount(accountID: String) -> Observable<Email_Client_V1_MailDeleteTripartiteAccountResponse> {
        var request = Email_Client_V1_MailDeleteTripartiteAccountRequest()
        request.accountID = accountID
        return sendAsyncRequest(request, transform: {(response: Email_Client_V1_MailDeleteTripartiteAccountResponse) -> Email_Client_V1_MailDeleteTripartiteAccountResponse in
            DataService.logger.debug("[mail_client] deleteTripartiteAccount success")
            return response
        }).observeOn(MainScheduler.instance)
    }

    // 三方账号配置管理
    func getTripartiteAccountConfig(accountID: String) -> Observable<Email_Client_V1_MailGetTripartiteAccountConfigResponse> {
        var request = Email_Client_V1_MailGetTripartiteAccountConfigRequest()
        request.accountID = accountID
        return sendAsyncRequest(request, transform: {(response: Email_Client_V1_MailGetTripartiteAccountConfigResponse) -> Email_Client_V1_MailGetTripartiteAccountConfigResponse in
            DataService.logger.debug("[mail_client] getTripartiteAccountConfig success")
            return response
        }).observeOn(MainScheduler.instance)
    }

    func updateTripartiteAccountConfig(accountID: String,
                                       taskID: String,
                                       receiver: Email_Client_V1_ProtocolConfig? = nil,
                                       sender: Email_Client_V1_ProtocolConfig? = nil,
                                       pass: Email_Client_V1_LoginPass? = nil,
                                       oauthParams: String? = nil) -> Observable<Email_Client_V1_MailUpdateTripartiteAccountResponse> {
        var request = Email_Client_V1_MailUpdateTripartiteAccountRequest()
        request.accountID = accountID
        request.taskID = taskID
        if let receiver = receiver {
            request.receiver = receiver
        }
        if let sender = sender {
            request.sender = sender
        }
        if let pass = pass {
            request.pass = pass
        }
        if let oauthParams = oauthParams {
            request.oauthParams = oauthParams
        }
        return sendAsyncRequest(request, transform: {(response: Email_Client_V1_MailUpdateTripartiteAccountResponse) -> Email_Client_V1_MailUpdateTripartiteAccountResponse in
            DataService.logger.debug("[mail_client] updateTripartiteAccountConfig success")
            return response
        }).observeOn(MainScheduler.instance)
    }

    func cancelOAuthAccount(taskID: String) -> Observable<Email_Client_V1_MailCancelOAuthAccountTaskResponse> {
        var request = Email_Client_V1_MailCancelOAuthAccountTaskRequest()
        request.taskID = taskID
        return sendAsyncRequest(request, transform: {(response: Email_Client_V1_MailCancelOAuthAccountTaskResponse) -> Email_Client_V1_MailCancelOAuthAccountTaskResponse in
            DataService.logger.debug("[mail_client_token] cancelOAuthAccount success")
            return response
        }).observeOn(MainScheduler.instance)
    }

    func getOldestMessage() -> Observable<Email_Client_V1_MailIMAPMigrationGetOldestMessageResponse> {
        let request = Email_Client_V1_MailIMAPMigrationGetOldestMessageRequest()
        return sendAsyncRequest(request, transform: {(response: Email_Client_V1_MailIMAPMigrationGetOldestMessageResponse) -> Email_Client_V1_MailIMAPMigrationGetOldestMessageResponse in
            DataService.logger.debug("[mail_client]  imap_migration getOldestMessage success")
            return response
        }).observeOn(MainScheduler.instance)
    }

    func addSignature(accountID: String, signature: MailSignature) -> Observable<Email_Client_V1_MailAddSignatureResponse> {
        var request = Email_Client_V1_MailAddSignatureRequest()
        request.accountID = accountID
        request.signature = signature
        return sendAsyncRequest(request, transform: {(response: Email_Client_V1_MailAddSignatureResponse) -> Email_Client_V1_MailAddSignatureResponse in
            DataService.logger.debug("[mail_client] addSignature success")
            return response
        }).observeOn(MainScheduler.instance)
    }

    func updateSignature(accountID: String, signature: MailSignature) -> Observable<Email_Client_V1_MailUpdateSignatureResponse> {
        var request = Email_Client_V1_MailUpdateSignatureRequest()
        request.accountID = accountID
        request.signature = signature
        return sendAsyncRequest(request, transform: {(response: Email_Client_V1_MailUpdateSignatureResponse) -> Email_Client_V1_MailUpdateSignatureResponse in
            DataService.logger.debug("[mail_client] updateSignature success")
            return response
        }).observeOn(MainScheduler.instance)
    }

    func deleteSignature(accountID: String, signatureId: String) -> Observable<Email_Client_V1_MailDeleteSignatureResponse> {
        var request = Email_Client_V1_MailDeleteSignatureRequest()
        request.accountID = accountID
        request.signatureID = signatureId
        return sendAsyncRequest(request, transform: {(response: Email_Client_V1_MailDeleteSignatureResponse) -> Email_Client_V1_MailDeleteSignatureResponse in
            DataService.logger.debug("[mail_client] deleteSignature success")
            return response
        }).observeOn(MainScheduler.instance)
    }

    func mailDownload(token: String, messageID: String, isInlineImage: Bool) -> Observable<Email_Client_V1_MailDownloadFileResponse> {
        MailLogger.info("[mail_client_download] mailDownload token: \(token) messageID: \(messageID) isInlineImage: \(isInlineImage)")
        var req = Email_Client_V1_MailDownloadFileRequest()
        req.token = token
        req.messageID = messageID
        req.isInlineImage = isInlineImage
        return sendAsyncRequest(req, transform: { (response: Email_Client_V1_MailDownloadFileResponse) in
            DataService.logger.debug("mailDownload")
            return response
        }).observeOn(MainScheduler.instance)
    }

    func mailUpload(path: String, messageID: String) -> Observable<Email_Client_V1_MailUploadFileResponse> {
        MailLogger.info("[mail_client_upload] mailUpload path: \(path) messageID: \(messageID)")
        var req = Email_Client_V1_MailUploadFileRequest()
        req.path = path
        req.messageID = messageID
        return sendAsyncRequest(req, transform: { (response: Email_Client_V1_MailUploadFileResponse) in
            DataService.logger.debug("mailUpload")
            return response
        }).observeOn(MainScheduler.instance)
    }

    func mailCancelDownload(respKey: String) -> Observable<Email_Client_V1_MailCancelDownloadFileResponse> {
        MailLogger.info("[mail_client_download] cancelDownload respKey: \(respKey)")
        var req = Email_Client_V1_MailCancelDownloadFileRequest()
        req.reqID = respKey
        return sendAsyncRequest(req, transform: { (response: Email_Client_V1_MailCancelDownloadFileResponse) in
            DataService.logger.debug("mailCancelDownload")
            return response
        }).observeOn(MainScheduler.instance)
    }

    func getSyncRange(accountID: String) -> Observable<Email_Client_V1_MailGetTripartiteSyncRangeResponse> {
        var req = Email_Client_V1_MailGetTripartiteSyncRangeRequest()
        req.accountID = accountID
        return sendAsyncRequest(req, transform: { (response: Email_Client_V1_MailGetTripartiteSyncRangeResponse) in
            DataService.logger.debug("[mail_client_eas] getSyncRange")
            return response
        }).observeOn(MainScheduler.instance)
    }

    func setSyncRange(accountID: String, range: Email_Client_V1_SyncRange) -> Observable<Email_Client_V1_MailSetTripartiteSyncRangeResponse> {
        var req = Email_Client_V1_MailSetTripartiteSyncRangeRequest()
        req.accountID = accountID
        req.range = range
        return sendAsyncRequest(req, transform: { (response: Email_Client_V1_MailSetTripartiteSyncRangeResponse) in
            DataService.logger.debug("[mail_client_eas] setSyncRange")
            return response
        }).observeOn(MainScheduler.instance)
    }
}

