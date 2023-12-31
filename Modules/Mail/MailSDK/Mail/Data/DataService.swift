//
//  DataService.swift
//  MailSDK
//
//  Created by tefeng liu on 2019/7/27.
//

import Foundation
import RxSwift
import SwiftProtobuf
import RustPB
import LKCommonsLogging
import ServerPB
import ThreadSafeDataStructure

final class DataService {
    // fetcher
    private var fetcher: DataServiceProxy

    // subject
    let disposeBag = DisposeBag()

    // helper
    static let logger = Logger.log(DataService.self, category: "Mail.DataService")

    // 子线程 Scheduler
    let dataScheduler = SerialDispatchQueueScheduler(qos: .userInteractive)

    var reqMap: SafeDictionary<String, Bool> = [:] + .readWriteLock

    // life circle
    init(fetcher: DataServiceProxy) {
        self.fetcher = fetcher
        configBlockReqs()
    }

    func configBlockReqs() {
        let blockReqs: [Any] = [Email_Client_V1_MailGetSmartInboxPreviewCardRequest.self,
                                Email_Client_V1_MailAddLabelRequest.self,
                                Email_Client_V1_MailDeleteLabelRequest.self,
                                Email_Client_V1_MailUpdateLabelRequest.self,
                                Email_V1_MailSendCardRequest.self,
                                Email_Client_V1_MailGetScheduleMessageCountRequest.self,
                                Email_Client_V1_MailTranslateMessagesRequest.self,
                                Email_Client_V1_MailGetSmartReplyRequest.self,
                                Email_Client_V1_MailGetDocsByUrlsRequest.self,
                                Email_Client_V1_MailUnsubscribeRequest.self,
                                // 写模块
                                Email_Client_V1_MailEditMessageRequest.self,
                                Email_Client_V1_MailRecallMessageRequest.self,
                                Email_Client_V1_MailGetRecallDetailRequest.self,
                                Email_Client_V1_MailCanSendExternalRequest.self,
                                Email_Client_V1_MailGetLargeFileCanShareToExternalRequest.self,
                                Email_Client_V1_MailDraftAppendLargeAttachmentRequest.self,
                                Email_Client_V1_MailCreateForwardMessageDraftRequest.self,
                                Email_Client_V1_MailReplyCalendarEventRequest.self,
                                Email_Client_V1_MailDeleteLargeFileRequest.self,
                                // 搜索
                                Email_Client_V1_MailAtContactRequest.self,
                                Email_Client_V1_MailMoveMultiLabelRequest.self,
                                Email_Client_V1_MailGetTenantDomainsRequest.self,
                                Email_Client_V1_MailLastVersionNewUserFlagRequest.self,
                                Email_Client_V1_MailGetTimeZoneByCityRequest.self]
        _ = blockReqs.map({ reqMap.updateValue(true, forKey: "\($0)") })
    }

    // fetcher
    func updateFetcher(_ fetcher: DataServiceProxy) {
        self.fetcher = fetcher
    }
}

extension DataService {

    // MARK: sync
    static func checkAccountValid(originAccountId: String,
                                  newAccountId: String,
                                  _ message: SwiftProtobuf.Message? = nil) -> Bool {
        if let message = message {
            // 部分 request 不需要 check account id
            if message is RustPB.Email_Client_V1_MailGetAccountRequest ||
                message is RustPB.Email_Client_V1_MailUpdateAccountRequest ||
                message is RustPB.Email_Client_V1_MailGetUnreadCountRequest ||
                message is RustPB.Email_Client_V1_MailGetAccountListRequest ||
                message is RustPB.Email_Client_V1_MailGetTenantDomainsRequest ||
                message is RustPB.Email_Client_V1_MailUpdateClientTabSettingRequest ||
                message is RustPB.Email_Client_V1_MailNoticeClientEventRequest ||
                message is RustPB.Email_Client_V1_MailGetOAuthURLRequest ||
                message is RustPB.Email_Client_V1_MailSwitchAccountRequest ||
                message is RustPB.Email_Client_V1_MailUpdateSignatureUsageRequest ||
                message is RustPB.Email_Client_V1_MailGetSignaturesRequest {
                return true
            }
        }
        if !originAccountId.isEmpty &&
            !newAccountId.isEmpty &&
            originAccountId != newAccountId {
            return false
        }
        return true
    }

    // MARK: Async
    func sendAsyncRequest<R: SwiftProtobuf.Message>(_ request: SwiftProtobuf.Message) -> Observable<R> {
        let event = getEventStartWithRequest(request)
        if needBlock(request) {
            return Observable<R>.create({ observer -> Disposable in
                observer.onError(NSError(domain: "", code: 1, userInfo: nil))
                return Disposables.create()
            })
        }
        let originAccountId = DataService.currentAccountID
        return fetcher.sendAsyncRequest(request, mailAccountId: originAccountId).flatMap { [weak self] (resp: R) -> Observable<R> in
            let newAccountId = DataService.currentAccountID
            let valid = DataService.checkAccountValid(originAccountId: originAccountId,
                                          newAccountId: newAccountId, request)
            if valid {
                return .just(resp)
            } else {
                let cmd = self?.fetcher.extractCommand(fromRequest: request)
                DataService.logger.error("[accountid_check] origin=\(originAccountId),new=\(newAccountId),cmd=\(cmd)")
                return .empty()
            }
        }.do(onNext: { [weak self] (_) in
            self?.commonHandlerSuccess(request: request, event: event)
        }, onError: { [weak self] error in
            self?.commonHandleError(request: request, error: error, event: event)
        })
    }

    func sendAsyncRequest(_ request: SwiftProtobuf.Message) -> Observable<Void> {
        let event = getEventStartWithRequest(request)
        let originAccountId = DataService.currentAccountID
        
        return fetcher.sendAsyncRequest(request, mailAccountId: originAccountId).flatMap { [weak self] (_) -> Observable<Void> in
            let newAccountId = DataService.currentAccountID
            let valid = DataService.checkAccountValid(originAccountId: originAccountId,
                                          newAccountId: newAccountId, request)
            if valid {
                return .just(())
            } else {
                let cmd = self?.fetcher.extractCommand(fromRequest: request)
                DataService.logger.error("[accountid_check] origin=\(originAccountId),new=\(newAccountId),cmd=\(cmd)")
                return .empty()
            }
        }.do(onNext: { [weak self] (_) in
            self?.commonHandlerSuccess(request: request, event: event)
        }, onError: { [weak self] error in
            self?.commonHandleError(request: request, error: error, event: event)
        })
    }

    func sendAsyncRequest<R: SwiftProtobuf.Message, U>(
        _ request: SwiftProtobuf.Message,
        transform: @escaping(R) throws -> U
        ) -> Observable<U> {
        let event = getEventStartWithRequest(request)
        if needBlock(request) {
            return Observable<U>.create({ observer -> Disposable in
                observer.onError(NSError(domain: "", code: 1, userInfo: nil))
                return Disposables.create()
            })
        }
        let originAccountId = DataService.currentAccountID
        return fetcher.sendAsyncRequest(request,
                                        mailAccountId: originAccountId,
                                        transform: transform).flatMap { [weak self] (resp: U) -> Observable<U> in
            let newAccountId = DataService.currentAccountID
            let valid = DataService.checkAccountValid(originAccountId: originAccountId,
                                          newAccountId: newAccountId, request)
            if valid {
                return .just(resp)
            } else {
                let cmd = self?.fetcher.extractCommand(fromRequest: request)
                DataService.logger.error("[accountid_check] origin=\(originAccountId),new=\(newAccountId),cmd=\(cmd)")
                return .empty()
            }
        }.do(onNext: { [weak self] (_) in
            self?.commonHandlerSuccess(request: request, event: event)
        }, onError: { [weak self] error in
            self?.commonHandleError(request: request, error: error, event: event)
        })
    }

    func sendSyncRequest<R: SwiftProtobuf.Message, U>(
        _ request: SwiftProtobuf.Message,
        transform: @escaping(R) throws -> U
    ) throws -> U {
        if needBlock(request) {
            throw NSError(domain: "", code: 1, userInfo: nil)
        }
        return try fetcher.sendSyncRequest(request, transform: transform)
    }

    func sendPassThroughAsyncRequest<R: SwiftProtobuf.Message>(_ request: SwiftProtobuf.Message, serCommand: ServerPB_Improto_Command) -> Observable<R> {
        let event = getEventStartWithRequest(request)
        let originAccountId = DataService.currentAccountID
        return fetcher.sendPassThroughAsyncRequest(request,
                                                   serCommand: serCommand).flatMap { [weak self] (resp: R) -> Observable<R> in
            let newAccountId = DataService.currentAccountID
            let valid = DataService.checkAccountValid(originAccountId: originAccountId,
                                          newAccountId: newAccountId, request)
            if valid {
                return .just(resp)
            } else {
                let cmd = self?.fetcher.extractCommand(fromRequest: request)
                DataService.logger.error("[accountid_check] origin=\(originAccountId),new=\(newAccountId),cmd=\(cmd)")
                return .empty()
            }
        }.do(onNext: {[weak self] (_) in
            self?.commonHandlerSuccess(request: request, event: event)
        }, onError: { [weak self] error in
            self?.commonHandleError(request: request, error: error, event: event)
        })
    }
    
    func sendPassThroughAsyncRequest<R: SwiftProtobuf.Message>(_ request: SwiftProtobuf.Message, serCommand: ServerPB_Improto_Command, mailAccountID: String) -> Observable<R> {
        let event = getEventStartWithRequest(request)
        let originAccountId = mailAccountID
        return fetcher.sendPassThroughAsyncRequest(request,
                                                   serCommand: serCommand,
                                                   mailAccountId: originAccountId).flatMap { [weak self] (resp: R) -> Observable<R> in
            let newAccountId = mailAccountID
            let valid = DataService.checkAccountValid(originAccountId: originAccountId,
                                          newAccountId: newAccountId, request)
            if valid {
                return .just(resp)
            } else {
                let cmd = self?.fetcher.extractCommand(fromRequest: request)
                DataService.logger.error("[accountid_check] origin=\(originAccountId),new=\(newAccountId),cmd=\(cmd)")
                return .empty()
            }
        }.do(onNext: {[weak self] (_) in
            self?.commonHandlerSuccess(request: request, event: event)
        }, onError: { [weak self] error in
            self?.commonHandleError(request: request, error: error, event: event)
        })
    }

    func needBlock(_ request: SwiftProtobuf.Message) -> Bool {
        guard Store.settingData.mailClient else { return false }
        let reqKey = "\(request)".reqKey
        if let needBlock = reqMap[reqKey] {
            if needBlock {
                MailLogger.info("[mail_client_req] needBlock request: \(reqKey)")
            }
            return needBlock
        } else {
            return false
        }
    }

    static var currentAccountID: String {
        return Store.settingData.getCachedCurrentAccountAlignRust(fetchNet: false)?.mailAccountID ?? ""
    }
}

extension String {
    var reqKey: String {
        let splitRange = range(of: ":\n")
        if let splitIndex = splitRange?.lowerBound {
            let count: Int = distance(from: startIndex, to: splitIndex)
            let index = index(startIndex, offsetBy: count)
            return String(prefix(upTo: index)).replacingOccurrences(of: "RustPB.", with: "")
        }
        return self
    }
}

// MARK: error handler
extension DataService {
    private func commonHandleError(request: SwiftProtobuf.Message, error: Error, event: MailAPMEventSingle.RustCall) {
        let cmd = self.fetcher.extractCommand(fromRequest: request)
        asyncRunInMainThread {
            DataService.logger.error("Mail send request to rust service failed error: \(error), cmd=\(cmd)")
            event.endParams.append(MailAPMEventSingle.RustCall.EndParam.error_message(error.getMessage() ?? ""))
            event.endParams.appendError(errorCode: error.mailErrorCode, errorMessage: error.getMessage())
            event.endParams.append(MailAPMEventConstant.CommonParam.status_rust_fail)
            event.postEnd()
        }
    }

    private func commonHandlerSuccess(request: SwiftProtobuf.Message, event: MailAPMEventSingle.RustCall) {
        asyncRunInMainThread {
            event.endParams.append(MailAPMEventConstant.CommonParam.status_success)
            event.postEnd()
        }
    }

    private func getEventStartWithRequest(_ request: SwiftProtobuf.Message) -> MailAPMEventSingle.RustCall {
        let command = fetcher.extractCommand(fromRequest: request)
        let event = MailAPMEventSingle.RustCall()
        event.endParams.append(MailAPMEventSingle.RustCall.EndParam.command(String(command.rawValue)))
        event.markPostStart()
        return event
    }
}

// MARK: client event
extension DataService {
    func noticeClientEvent(event: ClientEvent, folderID: String = "") -> Observable<Void> {
        var request = Email_Client_V1_MailNoticeClientEventRequest()
        request.event = event
        request.timestamp = Int64(1000 * Date().timeIntervalSince1970)
        request.extra = folderID
        return sendAsyncRequest(request, transform: { (response: Email_Client_V1_MailNoticeClientEventResponse) -> Void in
            DataService.logger.debug(
                "noticeClientEvent suc"
            )
        }).observeOn(MainScheduler.instance)
    }
}

// MARK: attachment
extension DataService {
    func fetchEmailDomain() -> Observable<Email_Client_V1_MailGetTenantDomainsResponse> {
        let request = Email_Client_V1_MailGetTenantDomainsRequest()
        return sendAsyncRequest(request, transform: { (res: Email_Client_V1_MailGetTenantDomainsResponse) in
            return res
            }).observeOn(MainScheduler.instance)
    }

    func checkIfLargeFileCanShare() -> Observable<Email_Client_V1_MailGetLargeFileCanShareToExternalResponse> {
        let request = Email_Client_V1_MailGetLargeFileCanShareToExternalRequest()
        return sendAsyncRequest(request, transform: { (res: Email_Client_V1_MailGetLargeFileCanShareToExternalResponse) in
            return res
            }).observeOn(MainScheduler.instance)
    }

    func deleteDriveFiles(tokens: [String]) -> Observable<Email_Client_V1_MailDeleteLargeFileResponse> {
        var request = Email_Client_V1_MailDeleteLargeFileRequest()
        request.tokens = tokens
        return sendAsyncRequest(request, transform: { (res: Email_Client_V1_MailDeleteLargeFileResponse) in
        return res
        }).observeOn(MainScheduler.instance)
    }

    func getAttachmentsRiskTag(_ fileTokenList: [String]) -> Observable<ServerPB_Compliance_MGetRiskTagByTokenResponse> {
        var request = ServerPB_Compliance_MGetRiskTagByTokenRequest()
        request.sourceTerminal = .mobile
        request.fileTokenList = fileTokenList
        return fetcher.sendPassThroughAsyncRequest(request, serCommand: .getFileRiskTagList).observeOn(MainScheduler.instance).map { (res: ServerPB_Compliance_MGetRiskTagByTokenResponse) -> ServerPB_Compliance_MGetRiskTagByTokenResponse in
            return res
        }
    }

    func getLargeAttachmentBannedInfo(_ fileTokenList: [String]) -> Observable<ServerPB_Mails_GetLargeAttachmentBannedInfoResponse> {
        var request = ServerPB_Mails_GetLargeAttachmentBannedInfoRequest()
        request.fileTokens = fileTokenList
        request.base = genRequestBase()
        return fetcher.sendPassThroughAsyncRequest(request, serCommand: .mailGetLargeAttachmentBannedInfo).observeOn(MainScheduler.instance).map { (res: ServerPB_Mails_GetLargeAttachmentBannedInfoResponse) -> ServerPB_Mails_GetLargeAttachmentBannedInfoResponse in
            return res
        }
    }

    func countLargeAttachmentPV(_ fileToken: String) -> Observable<ServerPB_Mails_CountLargeAttachmentPVResponse> {
        var request = ServerPB_Mails_CountLargeAttachmentPVRequest()
        request.fileToken = fileToken
        request.base = genRequestBase()
        return fetcher.sendPassThroughAsyncRequest(request, serCommand: .mailCountLargeAttachmentPv).observeOn(MainScheduler.instance).map { (res: ServerPB_Mails_CountLargeAttachmentPVResponse) -> ServerPB_Mails_CountLargeAttachmentPVResponse in
            return res
        }
    }
}

extension DataService {
    func sendHttpRequest(req: SendHttpRequest) -> Observable<SendHttpResponse> {
        return sendAsyncRequest(req, transform: { (res: SendHttpResponse) in
            return res
        }).observeOn(MainScheduler.instance)
    }
}
