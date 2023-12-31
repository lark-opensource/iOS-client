//
//  MailDataSource.swift
//  MailSDK
//
//  Created by 谭志远 on 2019/6/14.
//

import Foundation
import RxSwift
import LarkUIKit
import LKCommonsLogging
import RustPB

struct MailItem {
    var feedCardId: String = ""
    var feedMessageItems: [FromViewMailMessageItem] = []
    var threadId: String
    var messageItems: [MailMessageItem] = []
    var composeDrafts: [MailClientDraft]
    var labels: [MailClientLabel]
    var code: MailPermissionCode
    let isExternal: Bool
    var isFlagged: Bool
    var isRead: Bool
    var isLastPage: Bool
    init(feedCardId: String = "",
         feedMessageItems: [FromViewMailMessageItem] = [],
         threadId: String,
         messageItems: [MailMessageItem],
         composeDrafts: [MailClientDraft],
         labels: [MailClientLabel],
         code: MailPermissionCode,
         isExternal: Bool,
         isFlagged: Bool,
         isRead: Bool,
         isLastPage: Bool) {
        self.feedCardId = feedCardId
        self.feedMessageItems = feedMessageItems
        self.threadId = threadId
        self.composeDrafts = composeDrafts
        self.labels = labels
        self.code = code
        self.isExternal = isExternal
        self.isFlagged = isFlagged
        self.isRead = isRead
        self.isLastPage = isLastPage
        if feedMessageItems.isEmpty {
            self.messageItems = messageItems
        } else {
            self.messageItems = self.feedItemsTransToMessageItems(feedItems: feedMessageItems)
        }
    }
    
    func feedItemsTransToMessageItems(feedItems: [FromViewMailMessageItem] ) -> [MailMessageItem] {
        return feedItems.map { $0.item }
    }
    
    /// 是否需要隐藏星标.
    var shouldHideFlag = false
    ///是否需要隐藏 message item 的 menu 按钮.
    var shouldHideContextMenu = false
    /// eml 强制显示 BCC.
    var shouldForceDisplayBcc = false
    /// 点击地址时强制弹出卡片.
    var shouldForcePopActionSheet = false
        
    var securityInfos: [ThreadSecurity] {
        messageItems.map { $0.message.security }
    }
        
    var isAllFromAuthorized: Bool {
        messageItems.allSatisfy { $0.message.security.isFromAuthorized }
    }
    
    
    var feedsecurityInfos: [ThreadSecurity] {
        feedMessageItems.map { $0.item.message.security }
    }
    var feedIsAllFromAuthorized: Bool {
        feedMessageItems.allSatisfy { $0.item.message.security.isFromAuthorized }
    }
    func getFeedMessageItem(by msgId: String) -> FromViewMailMessageItem? {
        if msgId.isEmpty {
            return nil
        }
        return feedMessageItems.first { $0.item.message.id == msgId }
    }
    
   
    
    /// 垃圾邮件顶部提示
    var spamMailTip: String {
        guard FeatureManager.open(.newSpamPolicy) ||
                FeatureManager.open(.blockSender) else {
            return ""
        }
        func __findType(items: [MailMessageItem]) -> (Email_Client_V1_SpamBannerType, String) {
            // banner优先级顺序,数值越低，优先级越高
            let typeMap = [Email_Client_V1_SpamBannerType.userReport: 0,
                           Email_Client_V1_SpamBannerType.userRule: 1,
                           Email_Client_V1_SpamBannerType.blockDomain: 2,
                           Email_Client_V1_SpamBannerType.blockAddress: 3,
                           Email_Client_V1_SpamBannerType.userBlock: 4,
                           Email_Client_V1_SpamBannerType.antiSpam: 5]
            var resType = Email_Client_V1_SpamBannerType.notSpam
            var resValue = 100
            var resInfo = ""
            for item in items {
                for type in item.message.security.spamBannerType {
                    if let value = typeMap[type], value < resValue {
                        resValue = value
                        resType = type
                        if !item.message.security.spamBannerInfo.isEmpty {
                            resInfo = item.message.security.spamBannerInfo
                        }
                    }
                }
            }
            return (resType, resInfo)
        }
        let (resType, resInfo) = __findType(items: messageItems)
        switch resType {
            case .userReport:
                guard FeatureManager.open(.newSpamPolicy) else { return "" }
                return messageItems.count > 1
                ? BundleI18n.MailSDK.Mail_MarkedSpamBeforeConversation_Notice
                : BundleI18n.MailSDK.Mail_MarkedSpamBefore_Notice
            case .userBlock:
                guard FeatureManager.open(.newSpamPolicy) else { return "" }
                let mailAddresses = messageItems.map({ $0.message.from.address }).filter({!$0.isEmpty}).unique
                if mailAddresses.isEmpty {
                    return ""
                } else {
                    var str = mailAddresses[0]
                    if mailAddresses.count > 1 {
                        str += "、\(mailAddresses[1])"
                    }

                    return mailAddresses.count > 1
                    ? BundleI18n.MailSDK.Mail_SpamSenderBoforePlural_IOS_Notice2(mailAddresses.count, str)
                    : BundleI18n.MailSDK.Mail_SpamSenderBoforePlural_IOS_Notice1(str)
                }
            case .antiSpam:
                guard FeatureManager.open(.newSpamPolicy) else { return "" }
                return BundleI18n.MailSDK.Mail_IdentifiedbySimilar_Notice
            case .userRule:
                guard FeatureManager.open(.newSpamPolicy) else { return "" }
                return BundleI18n.MailSDK.Mail_SendtoSpambyFilter_Notice(BundleI18n.MailSDK.Mail_SendtoSpambyFilter_Link)
            case .blockDomain:
                guard FeatureManager.open(.blockSender) else { return "" }
                return BundleI18n.MailSDK.Mail_Spam_YouveBlockedTheDomain_Banner(domain: resInfo)
            case .blockAddress:
                guard FeatureManager.open(.blockSender) else { return "" }
                return BundleI18n.MailSDK.Mail_Spam_YouveBlockedTheSender_Banner(sender: resInfo)
            case .notSpam:
                fallthrough
            @unknown default:
                return ""
        }
    }
    

    func getMessageItem(by msgId: String) -> MailMessageItem? {
        if msgId.isEmpty {
            return nil
        }
        return messageItems.first { $0.message.id == msgId }
    }

    var shouldLazyLoadMessage: Bool {
        let lazyLoadMessageLimit = ProviderManager.default.commonSettingProvider?.IntValue(key: "lazyLoadLimit") ?? 0
        let shouldLazyLoad = FeatureManager.open(.readMailLazyLoadItem) && self.messageItems.count > lazyLoadMessageLimit
        MailMessageListController.logger.info("lazyLoadMessage \(shouldLazyLoad): \(self.messageItems.count) > \(lazyLoadMessageLimit)")
        return shouldLazyLoad
    }

    var oldestMessage: MailMessageItem? {
        guard var oldest = messageItems.first else { return nil }
        for item in messageItems where item.message.createdTimestamp < oldest.message.createdTimestamp {
            oldest = item
        }
        return oldest
    }

    var oldestSubject: String {
        return oldestMessage?.message.subject ?? ""
    }

    var displaySubject: String {
        let subject = oldestSubject.components(separatedBy: .newlines).joined(separator: " ")
        return subject.isEmpty ? BundleI18n.MailSDK.Mail_ThreadList_TitleEmpty : subject
    }


    func mailSubjectCover() -> MailSubjectCover? {
        guard let first = messageItems.first, !first.message.coverInfo.isEmpty, FeatureManager.open(.mailCover) else {
            return nil
        }
        return MailSubjectCover.decode(from: first.message.coverInfo)
    }
}

final class MailDataSource {
    static let shared = MailDataSource()

    var fetcher: DataService? {
        return MailDataServiceFactory.commonDataService
    }

    func getDraftItem(draftID: String) -> Observable<MailDraft> {
        guard let fetcher = fetcher else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        return fetcher.getDraftItem(draftID: draftID).observeOn(MainScheduler.instance)
    }
    
    func getMessageItem(messageId: String, isForward: Bool = false, feedCardId: String) -> Observable<(Email_Client_V1_FromViewMessageItem?, String)> {
        guard let fetcher = fetcher else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        return fetcher.getMessageItem(messageId: messageId, isForward: isForward, feedCardId: feedCardId)
            .map({ (res) -> (Email_Client_V1_FromViewMessageItem?, String) in
                return (res.hasFeedMsgItem ? res.feedMsgItem : nil, messageId)
            })
    }
    
    func getFromItem(feedCardId: String, messageOrDraftIds:[String]) -> Observable<Email_Client_V1_MailMGetFromItemResponse>{
        guard let fetcher = fetcher else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        return fetcher.getFromItem(feedCardId: feedCardId, messageOrDraftIds: messageOrDraftIds)
    }

    func getMassageItem(messageId: String, isForward: Bool = false) -> Observable<MailMessageItem> {
        guard let fetcher = fetcher else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        return fetcher.getMessageItem(messageId: messageId, isForward: isForward)
        .map({ (res) -> MailMessageItem in
            var item = MailMessageItem()
            item.message = res.message
            item.drafts = []
            item.index = 0
            return item
        })
    }

    func getMessageOrDraft(messageId: String, ignoreConversationMode: Bool) -> Observable<MailMessageItem> {
        guard let fetcher = fetcher else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        let dataProvider = fetcher.getMessageOrDraftItem(messageId: messageId,
                                                         ignoreConversationMode: ignoreConversationMode)
        return Observable.zip(dataProvider, tagDataProvider).map { (res, _) -> MailMessageItem in
            var item = MailMessageItem()
            item.message = res.message
            item.drafts = []
            item.index = 0
            return item
        }
    }

    /// 获取Label tag数据
    private var tagDataProvider: Observable<Void> {
        if MailTagDataManager.shared.tagDic.value.keys.isEmpty {
            // fetchTag when empty
            return getLabelsFromDB().do(onNext: { (labels) in
                MailLogger.info("[mail_tag_opt] initData label order from rust \(labels.map({ $0.labelId }).joined(separator: ", "))")
                MailTagDataManager.shared.updateTags(labels.map({ $0.toPBModel() }))
            }).catchError { (error) in
                MailLogger.error("[mail_tag_opt] error: \(error)")
                return Observable.just([])
            }.map { _ -> Void in
                return Void()
            }
        } else {
            return Observable.just(Void())
        }
    }
    
    func getDraftsBtn(feedCardId: String) -> Observable<([MailFeedDraftItem], Bool)> {
        guard let fetcher = fetcher else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        return fetcher.getDraftsBtn(feedCardId: feedCardId)
            .map { (res) -> ([MailFeedDraftItem], Bool) in
            return (res.draftItems, res.hasMore_p)
        }
    }
    
    func getDraftFromFeed(feedCardId: String,
                          timestamp: Int64) -> Observable<([MailFeedDraftItem], Bool)> {
        guard let fetcher = fetcher else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        return fetcher.mailGetFromView(feedCardId: feedCardId,
                                       timestampOperator: false,
                                       timestamp: timestamp,
                                       forceGetFromNet: false,
                                       isDraft: true)
        .map { (res) -> ([MailFeedDraftItem], Bool) in
            return (res.draftItems, res.hasMore_p)
        }
    }
    
    func getMessageListFromFeed(feedCardId: String,
                                timestampOperator: Bool,
                                timestamp: Int64,
                                forceGetFromNet: Bool,
                                isDraft: Bool) -> Observable<(MailItem, Bool)> {
        guard let fetcher = fetcher else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        let dataProvider = fetcher.mailGetFromView(feedCardId: feedCardId,
                                                   timestampOperator: timestampOperator,
                                                   timestamp: timestamp,
                                                   forceGetFromNet: forceGetFromNet,
                                                   isDraft: isDraft)
        return Observable.zip(dataProvider, tagDataProvider).map { (res, _) -> (MailItem, Bool) in
                let mailItem = MailItem(feedCardId: feedCardId,
                                        feedMessageItems: res.msgItems,
                                        threadId: "",
                                        messageItems: [],
                                        composeDrafts: [],
                                        labels: [],
                                        code: .none,
                                        isExternal: true,
                                        isFlagged: false,
                                        isRead: false,
                                        isLastPage: false)
                return (mailItem, res.hasMore_p)
        }
    }

    typealias ReadMailLocalResponse = (mailItem: MailItem, notInDB: Bool)
    func getMessageListFromLocal(threadId: String,
                                 labelId: String,
                                 newMessageIds: [String]?,
                                 forwardInfo: DataServiceForwardInfo? = nil) -> Observable<ReadMailLocalResponse> {
        guard let fetcher = fetcher else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        let dataProvider = fetcher.getMessageListFromLocal(threadId: threadId, labelId: labelId, newMessageIds: newMessageIds, forwardInfo: forwardInfo)
        return Observable.zip(dataProvider, tagDataProvider).map { (res, _) in
            let mailItem = MailItem(threadId: threadId,
                                    messageItems: res.messageItems,
                                    composeDrafts: res.drafts,
                                    labels: MailTagDataManager.shared.getTagModels(res.labelIds),
                                    code: res.code,
                                    isExternal: res.isExternal,
                                    isFlagged: res.isFlagged,
                                    isRead: res.isRead,
                                    isLastPage: res.isLastPage)
            return (mailItem, res.notInDatabase)
        }
    }

    func getMessageListFromRemote(threadId: String, labelId: String, forwardInfo: DataServiceForwardInfo?, newMessageIds: [String]?) -> Observable<MailItem> {
        guard let fetcher = fetcher else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        let dataProvider = fetcher.getMessageListFromRemote(threadId: threadId, labelId: labelId, forwardInfo: forwardInfo, newMessageIds: newMessageIds)
        return Observable.zip(dataProvider, tagDataProvider).map { (res, _) -> MailItem in
            return MailItem(threadId: threadId,
                            messageItems: res.messageItems,
                            composeDrafts: res.drafts,
                            labels: MailTagDataManager.shared.getTagModels(res.labelIds),
                            code: res.code,
                            isExternal: res.isExternal,
                            isFlagged: res.isFlagged,
                            isRead: res.isRead,
                            isLastPage: res.isLastPage)
        }
    }

    func getCalendarEventDetail(_ messageIds: [String]) -> Observable<[String: MailCalendarEventInfo]> {
        guard let fetcher = fetcher else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        return fetcher.getCalendarEventDetail(messageIds)
    }

    func getLabelsFromDB() -> Observable<[MailFilterLabelCellModel]> {
        guard let fetcher = fetcher else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        MailLogger.info("[mail_home] [mail_client] coexist account getLabelsFromDB")
        return fetcher.getLabels()
            .observeOn(MainScheduler.instance)
            .map { (response) -> [MailFilterLabelCellModel] in
                var models = response.labels.map({ (pbLabelModel) -> MailFilterLabelCellModel in
                    MailFilterLabelCellModel(pbModel: pbLabelModel)
                }).sorted(by: { $0.userOrderedIndex < $1.userOrderedIndex })
                var labelSort: [MailFilterLabelCellModel] = []
                labelSort = MailLabelArrangeManager.sortLabels(models)
               if Store.settingData.folderOpen() {
                    return FolderTree.getSortedListWithNodePath(FolderTree.build(labelSort).rootNode)
               } else {
                   return labelSort
               }
            }
    }

    func multiMutLabelForThread(threadIds: [String], messageIds: [String]? = nil, addLabelIds: [String], removeLabelIds: [String], fromLabelID: String) -> Observable<Email_Client_V1_MailMutMultiLabelResponse> {
        guard let fetcher = fetcher else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        MailLogger.info("multiMutLabelForThread request for thread: \(threadIds) add: \(addLabelIds)., remove \(removeLabelIds)")
        return fetcher.multiMutLabelForThread(threadIds: threadIds, messageIds: messageIds, addLabelIds: addLabelIds, removeLabelIds: removeLabelIds, fromLabelID: fromLabelID)
   }

    func mailGetDocsPermModel(docsUrlStrings: [String], requestPermissions: Bool) -> Observable<Email_Client_V1_MailGetDocsByUrlsResponse> {
        guard let fetcher = fetcher else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        return fetcher.mailGetDocsPermModels(docsUrlStrings: docsUrlStrings, requestPermissions: requestPermissions)
    }

    func moveMultiLabelRequest(threadIds: [String], fromLabel: String, toLabel: String,
                               ignoreUnauthorized: Bool = false,
                               reportType: Email_Client_V1_ReportType? = nil) -> Observable<Void> {
        guard let fetcher = fetcher else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        return fetcher.moveMultiLabelRequest(threadIds: threadIds, fromLabel: fromLabel, toLabel: toLabel, ignoreUnauthorized: ignoreUnauthorized, reportType: reportType)
    }

    func moveToFolderRequest(threadIds: [String], fromID: String, toFolder: String,
                             ignoreUnauthorized: Bool = false,
                             reportType: Email_Client_V1_ReportType? = nil) -> Observable<Email_Client_V1_MailMoveToFolderResponse> {
        guard let fetcher = fetcher else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        return fetcher.moveToFolderRequest(threadIds: threadIds, fromID: fromID, toFolder: toFolder, ignoreUnauthorized: ignoreUnauthorized, reportType: reportType)
    }

    func cancelScheduledSend(messageId: String?, threadIds: [String], feedCardID: String?) -> Observable<(Email_Client_V1_MailCancelScheduleSendResponse)> {
        guard let fetcher = fetcher else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        return fetcher.cancelScheduleSend(by: messageId, threadIds: threadIds, feedCardID: feedCardID)
    }

    func openEml(localPath: String) -> Observable<Email_Client_V1_MailOpenEmlResponse> {
        guard let fetcher = fetcher else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        return fetcher.openEml(localPath: localPath)
    }

    func clearEmlTmpFiles(token: String) -> Observable<Email_Client_V1_MailClearEmlTmpFilesResponse> {
        guard let fetcher = fetcher else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        return fetcher.clearEmlTmpFiles(token: token)
    }

    func mailDownloadRequest(token: String, messageID: String, isInlineImage: Bool) -> Observable<Email_Client_V1_MailDownloadFileResponse> {
        guard let fetcher = fetcher else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        return fetcher.mailDownload(token: token, messageID: messageID, isInlineImage: isInlineImage)
    }

    func mailUploadRequest(path: String, messageID: String) -> Observable<Email_Client_V1_MailUploadFileResponse> {
        guard let fetcher = fetcher else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        return fetcher.mailUpload(path: path, messageID: messageID)
    }

    func openPreviewMail(instanceCode: String) -> Observable<Email_Client_V1_MailOpenEmlResponse> {
        guard let fetcher = fetcher else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        return fetcher.openPreviewMail(instanceCode: instanceCode)
    }

    func fetchIsMessageImageBlocked(messageID: String) -> Observable<(String, Bool)> {
        guard let fetcher = fetcher else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }

        return fetcher.fetchIsMessageImageBlocked(messageID: messageID)
    }
    
    func fetchMessagesImageBlocked(messageFroms: [String], messageIDs: [String]) -> Observable<Email_Client_V1_MailGetIsImageAllowedResponse> {
        guard let fetcher = fetcher else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        
        return fetcher.fetchMessagesImageBlocked(messageFroms: messageFroms, messageIDs: messageIDs)
    }

    func addSenderToWebImageWhiteList(sender: [Email_Client_V1_Address]) -> Observable<Void> {
        guard let fetcher = fetcher else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        return fetcher.addSenderToWebImageWhiteList(sender: sender)
    }
}
