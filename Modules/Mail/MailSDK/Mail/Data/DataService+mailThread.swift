//
//  DataService+mailThread.swift
//  MailSDK
//
//  Created by tefeng liu on 2019/7/28.
//

import Foundation
import RustPB
import RxSwift
import SwiftProtobuf
import Homeric
import ServerPB

protocol DataReadMailResponse {
    var messageItems: [MailMessageItem] { get }
    var drafts: [MailClientDraft] { get }
    var labels: [MailClientLabel] { get }
    var securityInfos: [ThreadSecurity] { get }
    var code: MailPermissionCode { get }
    var isExternal: Bool { get }
    var isFlagged: Bool { get }
    var isRead: Bool { get }
    var labelIds: [String] { get }
    var notInDatabase: Bool { get }
    var isLastPage: Bool { get }
}

extension Email_Client_V1_MailGetMessageListResponse: DataReadMailResponse {
    var securityInfos: [ThreadSecurity] {
        messageItems.map { $0.message.security }
    }
}

struct DataServiceForwardInfo {
    let cardId: String
    let ownerUserId: String
}

// MARK: - 拉取 MailList 等相关方法
extension DataService {
    static let defaultFetchLength: Int64 = 20

    func getMailUnreadCount() -> Observable<Email_Client_V1_MailGetUnreadCountResponse> {
       let req = Email_Client_V1_MailGetUnreadCountRequest()
       return sendAsyncRequest(req, transform: { (response: Email_Client_V1_MailGetUnreadCountResponse) -> Email_Client_V1_MailGetUnreadCountResponse in
            return response
        }).observeOn(MainScheduler.instance)
    }

    func getAllAccountUnreadCount() -> Observable<Email_Client_V1_MailGetUnreadCountResponse> {
        var req = Email_Client_V1_MailGetUnreadCountRequest()
        req.fetchUnreadCountMap = true
        return sendAsyncRequest(req, transform: { (response: Email_Client_V1_MailGetUnreadCountResponse) -> Email_Client_V1_MailGetUnreadCountResponse in
             return response
         }).observeOn(MainScheduler.instance)
    }

    /// 根据URL下载文件
    ///
    /// - Parameters:
    ///   - remoteUrl: 远程下载地址
    ///   - localPath: 本地路径
    ///   - priority: 下载优先级 不传默认为0， 低优先级传小于0的数值
    ///   - slice: 是否启动分片下载，可以实现缓存下载，需要后台支持http range。
    /// - Returns: key
    func downloadNormal(remoteUrl: String,
                        localPath: String,
                        fileSize: String? = nil,
                        slice: Bool = false) -> Observable<Space_Drive_V1_DownloadNormalResponse> {
        var request = Space_Drive_V1_DownloadNormalRequest()
        request.remoteURL = remoteUrl
        request.localPath = localPath
        request.withSlice = slice
        request.priority = .max
        if let size = fileSize {
            request.fileSize = size
        }
        return sendAsyncRequest(request, transform: { (response: Space_Drive_V1_DownloadNormalResponse) -> Space_Drive_V1_DownloadNormalResponse in
            return response
        }).observeOn(MainScheduler.instance)
    }

    func getLabelThreadsEnough(timeStamp: Int64 = 0,
                               labelId: String,
                               filterType: MailThreadFilterType,
                               length: Int64 = DataService.defaultFetchLength) -> Observable<Email_Client_V1_MailGetLabelThreadsEnoughResponse> {
        var request = Email_Client_V1_MailGetLabelThreadsEnoughRequest()
        request.labelID = labelId
        request.newestTimestamp = timeStamp
        request.length = length
        request.filterType = filterType

        return sendAsyncRequest(request, transform: { (response: Email_Client_V1_MailGetLabelThreadsEnoughResponse) -> Email_Client_V1_MailGetLabelThreadsEnoughResponse in
            return response
        }).observeOn(MainScheduler.instance)
    }

    func getOutBoxMessageState() -> Observable<[OutBoxMessageInfo]> {
        let request = Email_Client_V1_MailGetOutboxMessageStateRequest()
        return sendAsyncRequest(request, transform: { (response: Email_Client_V1_MailGetOutboxMessageStateResponse) -> [OutBoxMessageInfo] in
            return response.messageInfo
        }).observeOn(MainScheduler.instance)
    }

    func getThreadListFromLocal(timeStamp: Int64,
                                labelId: String,
                                filterType: MailThreadFilterType,
                                length: Int64 = DataService.defaultFetchLength) -> Observable<Email_Client_V1_MailGetThreadListResponse> {
        var request = Email_Client_V1_MailGetThreadListRequest()
        request.labelID = labelId
        request.newestTimestamp = timeStamp
        request.length = length
        request.filterType = filterType

        return sendAsyncRequest(request, transform: { (response: Email_Client_V1_MailGetThreadListResponse) -> Email_Client_V1_MailGetThreadListResponse in
            return response
        }).observeOn(MainScheduler.instance)
    }

//    func getMessageFullBody(messageId: String) -> Observable<(messageId: String, bodyHtml: String)> {
//        var request = Email_Client_V1_MailGetMessageFullBodyRequest()
//        request.messageID = messageId
//        return sendAsyncRequest(request, transform: { (response: Email_Client_V1_MailGetMessageFullBodyResponse) -> (messageId: String, bodyHtml: String) in
//            return (messageId: response.messageID, bodyHtml: response.fullBodyHtml)
//        }).observeOn(MainScheduler.instance)
//    }

    func getMessageItem(messageId: String, isForward: Bool = false, feedCardId: String? = nil) -> Observable<Email_Client_V1_MailGetMessageItemResponse> {
        MailLogger.info("[mail_client_debug] getMessageItem messageId: \(messageId) isForward: \(isForward)")
        var request = Email_Client_V1_MailGetMessageItemRequest()
        request.messageID = messageId
        request.isForwardCard = isForward
        if let feedCardId = feedCardId {
            request.feedCardID = feedCardId
        }
        return sendAsyncRequest(request, transform: { (response: Email_Client_V1_MailGetMessageItemResponse) -> Email_Client_V1_MailGetMessageItemResponse in
            return response
        }).observeOn(MainScheduler.instance)
    }

    func getMessageOrDraftItem(messageId: String, ignoreConversationMode: Bool) -> Observable<Email_Client_V1_MailGetMessageOrDraftItemResponse> {
        var request = Email_Client_V1_MailGetMessageOrDraftItemRequest()
        request.messageID = messageId
        request.ignoreConversationMode = ignoreConversationMode
        return sendAsyncRequest(request, transform: { (response: Email_Client_V1_MailGetMessageOrDraftItemResponse) -> Email_Client_V1_MailGetMessageOrDraftItemResponse in
            return response
        }).observeOn(MainScheduler.instance)
    }

    func getMessageSuitableInfo(messageId: String, threadId: String, scene: Email_Client_V1_MailGetMessageSuitableInfoRequest.Scene) -> Observable<Email_Client_V1_MailGetMessageSuitableInfoResponse> {
        var request = Email_Client_V1_MailGetMessageSuitableInfoRequest()
        request.messageID = messageId
        request.threadID = threadId
        request.scene = scene
        return sendAsyncRequest(request, transform: { (response: Email_Client_V1_MailGetMessageSuitableInfoResponse) -> Email_Client_V1_MailGetMessageSuitableInfoResponse in
            return response
        }).observeOn(MainScheduler.instance)
    }

    func getMessageListFromLocal(threadId: String,
                                 labelId: String,
                                 newMessageIds: [String]?,
                                 forwardInfo: DataServiceForwardInfo? = nil) -> Observable<DataReadMailResponse> {
        let request: SwiftProtobuf.Message
        if let forward = forwardInfo {
            var req = Email_Client_V1_MailGetForwardMessageListRequest()
            req.cardID = forward.cardId
            req.ownerUserID = forward.ownerUserId
            request = req
        } else {
            var req = Email_Client_V1_MailGetMessageListRequest()
            req.threadID = threadId
            req.labelID = labelId
            if let messageIds = newMessageIds {
                req.newMessageIds = messageIds
            }
            request = req
        }
        return sendAsyncRequest(request, transform: { (response: Email_Client_V1_MailGetMessageListResponse) -> DataReadMailResponse in
            return response
        })
    }

    func getMessageListFromRemote(threadId: String, labelId: String, forwardInfo: DataServiceForwardInfo?, newMessageIds: [String]?) -> Observable<DataReadMailResponse> {
        let request: SwiftProtobuf.Message
        if let forward = forwardInfo {
            var req = Email_Client_V1_MailGetForwardMessageListFromNetRequest()
            req.cardID = forward.cardId
            req.ownerUserID = forward.ownerUserId
            request = req
        } else {
            var req = Email_Client_V1_MailGetMessageListFromNetRequest()
            req.threadID = threadId
            req.labelID = labelId
            if let messageIds = newMessageIds {
                req.newMessageIds = messageIds
            }
            request = req
        }
        return sendAsyncRequest(request, transform: { (response: Email_Client_V1_MailGetMessageListResponse) -> DataReadMailResponse in
            return response
        })
    }

    func getCalendarEventDetail(_ messageIds: [String]) -> Observable<[String: MailCalendarEventInfo]> {
        var request = Email_Client_V1_MailCalendarEventInfoRequest()
        request.messageIds = messageIds
        return sendAsyncRequest(request, transform: { (response: Email_Client_V1_MailCalendarEventInfoResponse) -> [String: MailCalendarEventInfo] in
            return response.calendarEventCard
        })
    }

    func getMailThreadItemRequest(labelId: String, threadId: String) -> Observable<MailThreadItem> {
        var request = Email_Client_V1_MailGetThreadItemRequest()
        request.labelID = labelId
        request.threadID = threadId
        return sendAsyncRequest(request, transform: { (response: Email_Client_V1_MailGetThreadItemResponse) -> MailThreadItem in
            return response.threadItem
        }).observeOn(MainScheduler.instance)
    }

    func getMailMultiThreadItemsRequest(fromLabel: String, threadIds: [String], sortTimeCursor: Int64 = 0) -> Observable<(threadItems: [MailThreadItem], disappearedThreadIds: [String])> {
        var request = Email_Client_V1_MailGetMultiThreadItemsRequest()
        request.fromLabel = fromLabel
        request.threadIds = threadIds
        request.sortTimeCursor = sortTimeCursor
        return sendAsyncRequest(request, transform: { (response: Email_Client_V1_MailGetMultiThreadItemsResponse) -> (threadItems: [MailThreadItem], disappearedThreadIds: [String]) in
            return (threadItems: response.threadItems, disappearedThreadIds: response.disappearedThreadIds)
        }).observeOn(MainScheduler.instance)
    }

    func getDraftItem(draftID: String) -> Observable<MailDraft> {
        MailTracker.startRecordTimeConsuming(event: Homeric.MAIL_DEV_SEND_GETDRAFTITEM_COST_TIME, params: nil)
        var request = Email_Client_V1_MailGetDraftItemRequest()
        request.draftID = draftID
        return sendAsyncRequest(request, transform: { (response: Email_Client_V1_MailGetDraftItemResponse) -> MailDraft in
            let draft = MailDraft(with: response.draft)
            MailTracker.endRecordTimeConsuming(event: Homeric.MAIL_DEV_SEND_GETDRAFTITEM_COST_TIME, params: nil)
            return draft
        }).observeOn(MainScheduler.instance)
    }

    func getCurrentAccount(fetchDb: Bool = true) -> Observable<Email_Client_V1_MailGetAccountResponse> {
        var request = Email_Client_V1_MailGetAccountRequest()
        request.fetchDb = fetchDb
        request.fetchCurrentAccount = true
        return sendAsyncRequest(request, transform: {(response: Email_Client_V1_MailGetAccountResponse) -> Email_Client_V1_MailGetAccountResponse in
            if response.account.accountSelected.isSelected, response.account.isValid() {
                DataService.logger.debug( "getCurrentAccount suc: value = \(response.account.mailAccountID)")
                Store.settingData.updateCachedCurrentAccount(response.account, pushChange: false) // 单纯的Get请求不该触发SettingChangePush
            } else {
                DataService.logger.debug( "getCurrentAccount error: value = \(response.account.mailAccountID) is not selected")
                // 补充一个兜底逻辑，切换到有效账号
                Store.settingData.switchToAvailableAccountIfNeeded()
            }

            return response
        }).observeOn(MainScheduler.instance)
    }

    func getPrimaryAccount(fetchDb: Bool = true) -> Observable<Email_Client_V1_MailGetAccountResponse> {
        DataService.logger.info("[mail_client] getPrimaryAccount")
        var request = Email_Client_V1_MailGetAccountRequest()
        request.fetchDb = fetchDb
        request.fetchCurrentAccount = false
        return sendAsyncRequest(request, transform: {(response: Email_Client_V1_MailGetAccountResponse) -> Email_Client_V1_MailGetAccountResponse in
            DataService.logger.info("[mail_init] [mail_client] getPrimaryAccount fetchDb: \(fetchDb) \(response.account.mailAccountID) \(response.account.sharedAccounts.map({ $0.mailAccountID })) \(response.account.sharedAccounts.map({ $0.isShared })) \(response.account.sharedAccounts.map({ $0.mailSetting.userType }))")
            Store.settingData.updatePrimaryAcc(response.account)
            if let currentAcc = ([response.account] + response.account.sharedAccounts).first(where: { $0.accountSelected.isSelected }) {
                Store.settingData.updateCachedCurrentAccount(currentAcc, pushChange: false)
            }
            Store.settingData.updateAccountInfos(of: response.account)
            Store.settingData.updateAccountList([response.account] + response.account.sharedAccounts)
            return response
        }).observeOn(MainScheduler.instance)
    }

    func switchMailAccount(to accountId: String) -> Observable<Email_Client_V1_MailSwitchAccountResponse> {
        var request = Email_Client_V1_MailSwitchAccountRequest()
        request.accountID = accountId

        return sendAsyncRequest(request, transform: {(response: Email_Client_V1_MailSwitchAccountResponse) -> Email_Client_V1_MailSwitchAccountResponse in
            return response
            })
            .observeOn(MainScheduler.instance)
            .map({ (res) -> Email_Client_V1_MailSwitchAccountResponse in
                var resp = Email_Client_V1_MailSwitchAccountResponse()
                resp.account = res.account
                DataService.logger.info(
                    "switchMailAccount suc: to = \(resp.account.mailAccountID)"
                )
                // Make sure account related cache in Store is cleared before rerendering MailHomeController and fetching data from store
                Store.handleMailAccountChanged()
                if resp.account.mailAccountID == accountId {
                    Store.settingData.updateCachedCurrentAccount(resp.account)
                    Store.settingData.acceptCurrentAccountChange()
                }
                return resp
            })
    }

    func getForwardMsgDraft(msgID: String,
                            ownerId: String,
                            timestamp: Int64,
                            cardID: String,
                            action: Email_Client_V1_MailCreateDraftRequest.CreateDraftAction,
                            languageId: String?) -> Observable<Email_Client_V1_MailCreateForwardMessageDraftResponse> {
        var request = Email_Client_V1_MailCreateForwardMessageDraftRequest()
        request.ownerUserID = ownerId
        request.messageID = msgID
        request.action = action
        request.cardID = cardID
        request.needSignature = !FeatureManager.realTimeOpen(.enterpriseSignature) || Store.settingData.mailClient
        request.timeText = getQuoteTimeText(timestamp: timestamp, languageId: languageId)

        return sendAsyncRequest(request, transform: {(response: Email_Client_V1_MailCreateForwardMessageDraftResponse) in
            return response
        }).observeOn(MainScheduler.instance)
    }

    func updateMailAccount(_ account: Email_Client_V1_MailAccount) -> Observable<Void> {
        var request = Email_Client_V1_MailUpdateAccountRequest()
        request.account = account
        DataService.logger.debug("call updateMailAccount id: \(account.mailAccountID) address: \(account.accountAddress)")
        return sendAsyncRequest(request, transform: {(response: Email_Client_V1_MailUpdateAccountResponse) in
            DataService.logger.debug("updateMailAccount suc id: \(account.mailAccountID) address: \(account.accountAddress)")
        }).observeOn(MainScheduler.instance)
    }

    func getLabels() -> Observable<Email_Client_V1_MailGetLabelsResponse> {
        let request = Email_Client_V1_MailGetLabelsRequest()
        return sendAsyncRequest(request, transform: {( response: Email_Client_V1_MailGetLabelsResponse) in
            DataService.logger.debug(
                "get labels success = \(response.labels.count)"
            )
            var newLabels = response.labels
//            var label = Email_Client_V1_Label()
//            label.id = "ltf";
//            label.name = "LTF";
//            label.modelType = .folder
//            label.parentID = Mail_LabelId_Inbox
//            label.userOrderedIndex = 2
//            newLabels.append(label)
            var newResp = response
            newResp.labels = newLabels
            return newResp
        }).observeOn(MainScheduler.instance)
    }

    func getThreadsAddresses(threadIDs: [String], fromLabel: String, onlyUnauthorized: Bool) -> Observable<[(String, Bool)]> {
        var request = Email_Client_V1_MailGetAddressRequest()
        request.threadIds = threadIDs
        request.labelID = fromLabel
        request.onlyUnauthorized = onlyUnauthorized

        return sendAsyncRequest(request, transform: { (response: Email_Client_V1_MailGetAddressResponse) in
            DataService.logger.debug(
                "get threads addresses success = \(response.address.count)"
            )
            return response.address.map({ ($0.address, $0.isExternal) }).filter({ !$0.0.isEmpty })
        }).observeOn(MainScheduler.instance)
    }

    func multiMutLabelForThread(threadIds: [String],
                                messageIds: [String]? = nil,
                                addLabelIds: [String],
                                removeLabelIds: [String],
                                fromLabelID: String,
                                feedCardId: String? = nil,
                                ignoreUnauthorized: Bool = false,
                                reportType: Email_Client_V1_ReportType? = nil) -> Observable<Email_Client_V1_MailMutMultiLabelResponse> {
        var request = Email_Client_V1_MailMutMultiLabelRequest()
        if let feedCardId = feedCardId {
            request.feedCardID = feedCardId
        }
        request.threadIds = threadIds
        request.addLabelIds = addLabelIds
        request.removeLabelIds = removeLabelIds
        request.fromLabel = fromLabelID
        request.ignoreUnauthorizedFrom = ignoreUnauthorized
        if let messageIds = messageIds {
            request.messageIds = messageIds
        }
        if let reportType = reportType {
            request.reportType = reportType
        }
        return sendAsyncRequest(request, transform: { (response: Email_Client_V1_MailMutMultiLabelResponse) in
            DataService.logger.debug("""
                multi mut label for threadIds: \(threadIds)
            messageIds: \(messageIds),
            add: \(addLabelIds)
            remove: \(removeLabelIds)
            fromLabel: \(fromLabelID),
            reportType: \(String(describing: reportType)),
            uuid: \(response.uuid)
            """)
            return response
        }).observeOn(MainScheduler.instance)
    }

    func multiDeleteDraftForThread(threadIds: [String], fromLabelID: String) -> Observable<Void> {
        var request = Email_Client_V1_MailDeleteMultiDraftsRequest()
        request.threadIds = threadIds
        request.fromLabel = fromLabelID
        return sendAsyncRequest(request, transform: { (response: Email_Client_V1_MailDeleteMultiDraftResponse) in
            DataService.logger.debug("multi delete draft for thread")
        }).observeOn(MainScheduler.instance)
    }

    func updateThreadReadStatus(threadID: String, fromlabel: String, read: Bool) -> Observable<Email_Client_V1_MailMutMultiLabelResponse> {
        var request = Email_Client_V1_MailMutMultiLabelRequest()
        request.threadIds = [threadID]
        request.fromLabel = fromlabel
        if read {
            request.removeLabelIds = [Mail_LabelId_UNREAD]
        } else {
            request.addLabelIds = [Mail_LabelId_UNREAD]
        }
        return sendAsyncRequest(request).do(onNext: { (res) in
            DataService.logger.debug("updateThreadReadStatus success: threadId: \(threadID) res: \(res.debugDescription)")
        }, onError: { (error) in
            DataService.logger.debug("updateThreadReadStatus fail: threadId: \(threadID) error: \(error)")
        }).observeOn(MainScheduler.instance)
    }

    func moveMultiLabelRequest(threadIds: [String], fromLabel: String, toLabel: String,
                               ignoreUnauthorized: Bool = false,
                               reportType: Email_Client_V1_ReportType? = nil) -> Observable<Void> {
        var request = Email_Client_V1_MailMoveMultiLabelRequest()
        request.threadIds = threadIds
        request.fromLabel = fromLabel
        request.toLabel = toLabel
        request.ignoreUnauthorizedFrom = ignoreUnauthorized
        reportType.map { request.reportType = $0 }
        return sendAsyncRequest(request).do(onNext: { (res) in
            DataService.logger.debug("moveMultiLabel success: threadIds: \(threadIds) fromLabel: \(fromLabel), toLabel: \(toLabel)")
        }).observeOn(MainScheduler.instance)
    }

    func moveToFolderRequest(threadIds: [String], fromID: String, toFolder: String,
                             ignoreUnauthorized: Bool = false,
                             reportType: Email_Client_V1_ReportType? = nil) -> Observable<Email_Client_V1_MailMoveToFolderResponse> {
        var request = Email_Client_V1_MailMoveToFolderRequest()
        request.threadIds = threadIds
        request.fromID = fromID
        request.toFolder = toFolder
        request.ignoreUnauthorizedFrom = ignoreUnauthorized
        reportType.map { request.reportType = $0 }
        return sendAsyncRequest(request).do(onNext: { _ in
            DataService.logger.debug("moveToFolder success: threadIds: \(threadIds) fromID: \(fromID), toFolder: \(toFolder)")
        }).observeOn(MainScheduler.instance)
    }


    func mailGetDocsPermModels(docsUrlStrings: [String], requestPermissions: Bool) -> Observable<Email_Client_V1_MailGetDocsByUrlsResponse> {
        var req = Email_Client_V1_MailGetDocsByUrlsRequest()
        req.urls = docsUrlStrings
        req.requestPerms = requestPermissions ? [.view, .edit, .manageCollaborator] : []
        return sendAsyncRequest(req).do(onNext: { _ in
            DataService.logger.debug("mail getDocsModel success")
        }).observeOn(MainScheduler.instance)
    }

    func recallMessage(id: String) -> Observable<Void> {
        var req = Email_Client_V1_MailRecallMessageRequest()
        req.messageID = id
        return sendAsyncRequest(req).do(onNext: { (_) in
            DataService.logger.debug("mail recalled success")
        }).observeOn(MainScheduler.instance)
    }

    func unsubscribeMessage(id: String, threadID: String) -> Observable<Email_Client_V1_MailUnsubscribeResponse> {
        var request = Email_Client_V1_MailUnsubscribeRequest()
        request.messageBizID = id
        request.threadBizID = threadID
        return sendAsyncRequest(request).do(onNext: { _ in
        DataService.logger.debug("mail unsubscribe success: messageId: \(id) threadID: \(threadID)")
        }).observeOn(MainScheduler.instance)
    }

    func getRecallDetail(for messageId: String) -> Observable<Email_Client_V1_MailGetRecallDetailResponse> {
        var req = Email_Client_V1_MailGetRecallDetailRequest()
        req.messageID = messageId
        return sendAsyncRequest(req).do(onNext: { (res) in
            DataService.logger.debug("getRecallDetail success: messageId: \(messageId)")
        }).observeOn(MainScheduler.instance).do(onNext: { _ in
            DataService.logger.info("get recall detail succ")
        }, onError: { error in
            DataService.logger.error("get recall detail failed", error: error)
        })
    }

    func mailReplyCalendarEvent(eventServerID: String, mailID: String, option: MailCalendarEventReplyOption) -> Observable<Email_Client_V1_MailReplyCalendarEventResponse> {
        var request = Email_Client_V1_MailReplyCalendarEventRequest()
        request.eventServerID = eventServerID
        request.operation = option
        request.mailID = mailID
        return sendAsyncRequest(request, transform: { (response: Email_Client_V1_MailReplyCalendarEventResponse) -> Email_Client_V1_MailReplyCalendarEventResponse in
            return response
        }).observeOn(MainScheduler.instance)
    }

    // mail migration detail
    func getMailMigrationDetails() -> Observable<Email_Client_V1_MailGetMigrationDetailsResponse> {
        let request = Email_Client_V1_MailGetMigrationDetailsRequest()
        return sendAsyncRequest(request, transform: { (response: Email_Client_V1_MailGetMigrationDetailsResponse) -> Email_Client_V1_MailGetMigrationDetailsResponse in
            DataService.logger.debug("get mail migration details")
            return response
        }).observeOn(MainScheduler.instance)
    }

    func refreshThreadList(label_id: String,
                           filterType: MailThreadFilterType,
                           first_timestamp: Int64,
                           length: Int64 = DataService.defaultFetchLength,
                           enableDebounce: Bool = false) -> Observable<Email_Client_V1_MailRefreshThreadListResponse> {
        var request = Email_Client_V1_MailRefreshThreadListRequest()
        request.labelID = label_id
        request.filterType = filterType
        request.firstThreadTimestamp = first_timestamp
        request.length = length
        request.enableDebounce = enableDebounce

        return sendAsyncRequest(request, transform: { (response: Email_Client_V1_MailRefreshThreadListResponse) in
            DataService.logger.debug("refresh for thread")
            return response
        }).observeOn(MainScheduler.instance)
    }

    func getPreviewCard(label_id: String) -> Observable<Email_Client_V1_MailGetNewMessagePreviewCardResponse> {
        var request = Email_Client_V1_MailGetNewMessagePreviewCardRequest()
        request.labelID = label_id
        return sendAsyncRequest(request, transform: { (response: Email_Client_V1_MailGetNewMessagePreviewCardResponse) in
            DataService.logger.debug("get preview card")
            return response
        }).observeOn(MainScheduler.instance)
    }

    func postUserConsumingGuide(keys: [String]) -> Observable<Onboarding_V1_PostUserConsumingGuideResponse> {
        var request = Onboarding_V1_PostUserConsumingGuideRequest()
        request.keys = keys
        return sendAsyncRequest(request, transform: { (response: Onboarding_V1_PostUserConsumingGuideResponse) in
            DataService.logger.debug("post user consuming guide")
            return response
        }).observeOn(MainScheduler.instance)
    }

    func selectAll(labelID: String, maxTimestamp: Int64, addLabelIds: [String]) -> Observable<Email_Client_V1_MailSelectAllResponse> {
        var request = Email_Client_V1_MailSelectAllRequest()
        request.labelID = labelID
        request.maxTimestamp = maxTimestamp
        request.addLabelIds = addLabelIds
        return sendAsyncRequest(request, transform: { (response: Email_Client_V1_MailSelectAllResponse) in
            DataService.logger.debug("selectAll")
            return response
        }).observeOn(MainScheduler.instance)
    }
    func getChatter(userID: String) -> Observable<Contact_V1_GetUserProfileResponse> {
        var request = Contact_V1_GetUserProfileRequest()
        request.userID = userID
        return sendAsyncRequest(request, transform: { (response: Contact_V1_GetUserProfileResponse) in
            DataService.logger.debug("getChatters")
            return response
        }).observeOn(MainScheduler.instance)
    }

    func openPreviewMail(instanceCode: String) -> Observable<Email_Client_V1_MailOpenEmlResponse> {
        var req = Email_Client_V1_MailPreviewEmlOnlineRequest()
        req.instanceCode = instanceCode
        return sendAsyncRequest(req, transform: { (response: Email_Client_V1_MailOpenEmlResponse) in
            DataService.logger.info("openPreviewMail finish")
            return response
        }).observeOn(MainScheduler.instance)
    }

    func openEml(localPath: String) -> Observable<Email_Client_V1_MailOpenEmlResponse> {
        var req = Email_Client_V1_MailOpenEmlRequest()
        req.localPath = localPath

        return sendAsyncRequest(req, transform: { (response: Email_Client_V1_MailOpenEmlResponse) in
            DataService.logger.debug("openEml")
            return response
        }).observeOn(MainScheduler.instance)
    }

    func clearEmlTmpFiles(token: String) -> Observable<Email_Client_V1_MailClearEmlTmpFilesResponse> {
        var req = Email_Client_V1_MailClearEmlTmpFilesRequest()
        req.token = token

        return sendAsyncRequest(req, transform: { (response: Email_Client_V1_MailClearEmlTmpFilesResponse) in
            DataService.logger.debug("clearEmlTmpFiles")
            return response
        }).observeOn(MainScheduler.instance)
    }

    func manageStrangerThread(type: Email_Client_V1_MailManageStrangerRequest.ManageType, threadIds: [String]?, isSelectAll: Bool, maxTimestamp: Int64?, fromList: [String]?) -> Observable<Email_Client_V1_MailManageStrangerResponse> {
        var req = Email_Client_V1_MailManageStrangerRequest()
        req.manageType = type
        if let threadIds = threadIds {
            req.threadIds = threadIds
        }
        req.isSelectAll = isSelectAll
        if let maxTimestamp = maxTimestamp {
            req.maxTimestamp = maxTimestamp
        }
        if let fromList = fromList {
            req.fromList = fromList
        }

        return sendAsyncRequest(req, transform: { (response: Email_Client_V1_MailManageStrangerResponse) in
            DataService.logger.debug("[mail_stranger] manageStrangerThread")
            return response
        }).observeOn(MainScheduler.instance)
    }

    func cancelLongTask(sessionID: String) -> Observable<Email_Client_V1_MailCancelLongRunningTaskResponse> {
        var req = Email_Client_V1_MailCancelLongRunningTaskRequest()
        req.sessionID = sessionID
        return sendAsyncRequest(req, transform: { (response: Email_Client_V1_MailCancelLongRunningTaskResponse) in
            DataService.logger.debug("[mail_stranger] cancelLongTask")
            return response
        }).observeOn(MainScheduler.instance)
    }

    func getLongTaskStatus(sessionID: String) -> Observable<Email_Client_V1_MailGetLongRunningTaskResponse> {
        var req = Email_Client_V1_MailGetLongRunningTaskRequest()
        req.sessionID = sessionID
        return sendAsyncRequest(req, transform: { (response: Email_Client_V1_MailGetLongRunningTaskResponse) in
            DataService.logger.debug("[mail_stranger] getLongTask")
            return response
        }).observeOn(MainScheduler.instance)
    }

    func checkMessageHasDraft(messageID: String) -> Observable<Bool> {
        var request = Email_Client_V1_MailGetIsNewDraftBeforeCreateRequest()
        request.originMessageID = messageID
        return sendAsyncRequest(request, transform: { (response: Email_Client_V1_MailGetIsNewDraftBeforeCreateResponse) in
            return !response.isNew
        }).observeOn(MainScheduler.instance)
    }

    func rewriteHTMLImageURL(html: String) throws -> (String, Bool) {
        var request = Email_Client_V1_MailRewriteHTMLImgUrlRequest()
        request.html = html
        return try sendSyncRequest(request) { (response: Email_Client_V1_MailRewriteHTMLImgUrlResponse) in
            return (response.html, response.hasWebImg_p)
        }
    }
}

// messageSendStatus
extension DataService {
    func genRequestBase() -> ServerRequestBase {
        var base = ServerRequestBase()
        if let account = Store.settingData.getCachedCurrentAccount(), account.isShared {
            var shareAccount = ServerShareEmailAccount()
            shareAccount.userID = Int64(account.mailAccountID) ?? 0
            shareAccount.emailAddress = account.accountAddress
            shareAccount.emailName = account.accountName
            shareAccount.accessToken = account.accountToken
            base.sharedEmailAccount = shareAccount
        }
        return base
    }

    func genRequestBaseWithAccountId(accountId: String) -> ServerRequestBase {
        var base = ServerRequestBase()
        if let account = Store.settingData.getCachedAccountList()?.first(where: { $0.mailAccountID == accountId }), account.isShared {
            var shareAccount = ServerShareEmailAccount()
            shareAccount.userID = Int64(account.mailAccountID) ?? 0
            shareAccount.emailAddress = account.accountAddress
            shareAccount.emailName = account.accountName
            shareAccount.accessToken = account.accountToken
            base.sharedEmailAccount = shareAccount
        }
        return base
    }

    func getMessageSendStatus(messageId: String) ->
    Observable<SendStatusByMessageIDResp> {
        var request = SendStatusByMessageIDRequest()
        request.base = genRequestBase()
        request.messageBizID = messageId
        return sendPassThroughAsyncRequest(request,
                                           serCommand: .mailGetMessageSendStatus).observeOn(MainScheduler.instance).map { (resp: SendStatusByMessageIDResp) ->
                                            SendStatusByMessageIDResp in
            return resp
        }
    }

    func updateCleanMessageStatus() -> Observable<MailUpdateCleanMessageStatusResp> {
        var request = MailUpdateCleanMessageStatusReq()
        request.base = genRequestBase()
        return sendPassThroughAsyncRequest(request,
                                           serCommand: .mailUpdateCleanMessageStatus).observeOn(MainScheduler.instance).map { (resp: MailUpdateCleanMessageStatusResp) ->
            MailUpdateCleanMessageStatusResp in
            return resp
        }
    }
}
