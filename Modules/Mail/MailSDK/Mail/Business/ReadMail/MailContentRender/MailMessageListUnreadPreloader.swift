//
//  MailMessageListUnreadPreloadHandler.swift
//  MailSDK
//
//  Created by zhaoxiongbin on 2021/6/16.
//

import Foundation
import RxSwift
import WebKit
import UniverseDesignTheme
import ThreadSafeDataStructure
import RxRelay

protocol MailMessagePreloadItem {
    var threadID: String { get }
    var currentLabelID: String { get }
    var isUnread: Bool { get }
    var lastmessageTime: Int64 { get }
}

extension MailThreadListCellViewModel: MailMessagePreloadItem {}

class MailMessageListUnreadPreloader: NSObject {
    struct PreloadResult {
        var mailItem: MailItem
        var bodyHtml: String?
        var rustStartAndEnd: (start: Int, end: Int)?
        var parseStartAndEnd: (start: Int, end: Int)?
        var logParams = [String: Any]()
        var fromDB: Int {
            if let fromNet = logParams[MailTracker.GET_RUST_DATA_FROM_NET] as? Int, fromNet == 1 {
                return 0
            } else {
                return 1
            }
        }
    }

    // result: ThreadId: BodyHtml
    private var preloadedBodyHtmlDict = ThreadSafeDictionary<String, PreloadResult>()
    private var preloadingThreads = ThreadSafeSet<String>()

    private var queueBag = DisposeBag()
    private let preloadOperationQueue = OperationQueue()
    private let preloadUnderlyingQueue = DispatchQueue(label: "readmail.unreadpreload", qos: .default)
    private var currentLabelID: String?
    private var startHandler: (() -> Void)?
    private let dataService = MailMessageListDataService()
    private let userID: String
    private let settingConfig: MailSettingConfigProxy?
    private let preloadServices: MailPreloadServicesProtocol
    private let messageLabels = ThreadSafeDictionary<String, String>()

    init(userID: String, settingConfig: MailSettingConfigProxy?, preloadServices: MailPreloadServicesProtocol) {
        self.userID = userID
        self.settingConfig = settingConfig
        self.preloadServices = preloadServices
        preloadOperationQueue.underlyingQueue = preloadUnderlyingQueue
        preloadOperationQueue.maxConcurrentOperationCount = 1
        preloadOperationQueue.isSuspended = false
        super.init()
    }

    /// 未读预加载策略优化
    func startPreloadFor(datasource: [MailMessagePreloadItem], currentLabelID: String, pageWidth: CGFloat, paddingTop: CGFloat,
                         templateRender: MailMessageListTemplateRender, threadChangeDetail: [String : MailThreadChanegDetail]? = nil) {
        guard FeatureManager.open(.unreadPreloadMail) else {
            return
        }
        if let changeDetail = threadChangeDetail, self.currentLabelID == currentLabelID, FeatureManager.open(.unreadPreloadMailOpt) {
            // 只对前20封邮件进行preload
            let maxCount = 20
            let totalDropCount = max(datasource.count - maxCount, 0)
            // 只预加载N封邮件,后台配置，默认为4
            let preloadMaxCount = self.settingConfig?.preloadConfig?.newMailPreloadCount ?? 4
            let unreadItems = datasource.dropLast(totalDropCount).filter({ $0.isUnread })
            let unreadInfoDic = Dictionary(uniqueKeysWithValues: unreadItems.map { ($0.threadID, $0.lastmessageTime) }) //.values.sorted{ $0 > $1 }
            MailLogger.info("MailUnreadPreload opt start datasource count: \(datasource.count) unread count: \(unreadInfoDic.count) changeDetail.keys: \(changeDetail.keys.count)")
            guard !unreadItems.isEmpty && self.preloadingThreads.count() < preloadMaxCount else {
                MailLogger.info("MailUnreadPreload preloadOperation is full")
                return
            }
            /// 对已缓存数据做diff，如果change里面有大量新增
            for threadID in changeDetail.keys {
                if let change = changeDetail[threadID] {

                    MailLogger.info("MailUnreadPreload change detail: \(change) threadID: \(threadID)")
                    switch change {
                    case .add, .update:
                        var needCheckReplace: Bool = {
                            if change == .update {
                                return !clear(threadID: threadID)
                            } else {
                                return true
                            }
                        }()
                        let preloadingThread = datasource.filter({ preloadingThreads.contains($0.threadID) })
                        let preloadedThread = datasource.filter({ preloadedBodyHtmlDict.all().keys.contains($0.threadID) })
                        if preloadingThread.count + preloadedThread.count >= preloadMaxCount &&
                            !preloadingThreads.contains(threadID) &&
                            !preloadedBodyHtmlDict.all().keys.contains(threadID) && needCheckReplace { // 检测是否需要替换预加载队列元素
                            if let addThread = datasource.first(where: { $0.threadID == threadID }) {
                                if let preloadingOldestThread = preloadingThread.min(by: { $0.lastmessageTime < $1.lastmessageTime }), // !preloadingThread.isEmpty,
                                    addThread.lastmessageTime > preloadingOldestThread.lastmessageTime {
                                    MailLogger.info("MailUnreadPreload update preloading list")
                                    self.clear(threadID: preloadingOldestThread.threadID)
                                    self.insert(threadID: threadID, currentLabelID: currentLabelID, pageWidth: pageWidth,
                                                paddingTop: paddingTop, templateRender: templateRender)
                                } else if let preloadedOldestThread = preloadedThread.min(by: { $0.lastmessageTime < $1.lastmessageTime }),
                                            addThread.lastmessageTime > preloadedOldestThread.lastmessageTime {
                                    MailLogger.info("MailUnreadPreload update preloaded dict")
                                    self.clear(threadID: preloadedOldestThread.threadID)
                                    self.insert(threadID: threadID, currentLabelID: currentLabelID, pageWidth: pageWidth,
                                                paddingTop: paddingTop, templateRender: templateRender)
                                } else {
                                    // do nothing
                                    MailLogger.info("MailUnreadPreload new thread but not lastest")
                                }
                            } else {
                                // 如果缺失时间戳信息则无法精准对比
                                MailLogger.info("MailUnreadPreload insert")
                                self.insert(threadID: threadID, currentLabelID: currentLabelID, pageWidth: pageWidth,
                                            paddingTop: paddingTop, templateRender: templateRender)
                            }
                        } else {
                            self.insert(threadID: threadID, currentLabelID: currentLabelID, pageWidth: pageWidth,
                                        paddingTop: paddingTop, templateRender: templateRender)
                        }
                    case .delete:
                        let inPreloadTask = preloadingThreads.contains(threadID) || preloadedBodyHtmlDict.all().keys.contains(threadID)
                        let hadClearPreloadTask = inPreloadTask && self.clear(threadID: threadID)
                        if hadClearPreloadTask || !inPreloadTask {
                            // 清理后可以再新增补位的预加载任务，从列表前面顺找
                            if let nextUnreadThread = unreadItems.first(where: { !preloadingThreads.contains($0.threadID) && !preloadedBodyHtmlDict.all().keys.contains($0.threadID) }) {
                                MailLogger.info("MailUnreadPreload preloaded next thread after delete")
                                self.insert(threadID: nextUnreadThread.threadID, currentLabelID: currentLabelID, pageWidth: pageWidth,
                                            paddingTop: paddingTop, templateRender: templateRender)
                            } else {
                                MailLogger.info("MailUnreadPreload no need to preloaded next thread after delete")
                            }
                        }
                    default:
                        startPreloadFor(datasource: datasource, currentLabelID: currentLabelID, pageWidth: pageWidth,
                                        paddingTop: paddingTop, templateRender: templateRender)
                    }
                }
            }
        } else {
            startPreloadFor(datasource: datasource, currentLabelID: currentLabelID, pageWidth: pageWidth,
                            paddingTop: paddingTop, templateRender: templateRender)
        }
    }

    /// 开始未读预加载
    private func startPreloadFor(datasource: [MailMessagePreloadItem], currentLabelID: String, pageWidth: CGFloat, paddingTop: CGFloat, templateRender: MailMessageListTemplateRender) {
        guard FeatureManager.open(.unreadPreloadMail) else {
            return
        }
        MailLogger.info("MailUnreadPreload start")
        clear()
        self.currentLabelID = currentLabelID

        preloadOperationQueue.addOperation { [weak self] in
            guard let self = self else { return }
            // 只对前20封邮件进行preload
            let maxCount = 20
            let totalDropCount = max(datasource.count - maxCount, 0)
            // 只预加载N封邮件,后台配置，默认为4
            let preloadMaxCount = self.settingConfig?.preloadConfig?.newMailPreloadCount ?? 4
            let unreadItems = datasource.dropLast(totalDropCount).filter({ $0.isUnread })
            if !unreadItems.isEmpty && self.preloadingThreads.count() < preloadMaxCount {
                for item in unreadItems where self.preloadingThreads.count() < preloadMaxCount && !self.preloadingThreads.contains(item.threadID) {
                    self.preloadingThreads.insert(item.threadID)
                    MailLogger.info("MailUnreadPreload t_id: \(item.threadID)")
                    self.preloadFor(threadId: item.threadID,
                                    labelId: currentLabelID,
                                    pageWidth: pageWidth,
                                    paddingTop: paddingTop,
                                    render: templateRender)
                }
            }
        }
    }

    func insert(threadID: String, currentLabelID: String, pageWidth: CGFloat, paddingTop: CGFloat, templateRender: MailMessageListTemplateRender) {
        let preloadMaxCount = self.settingConfig?.preloadConfig?.newMailPreloadCount ?? 4
        guard !self.preloadingThreads.contains(threadID) && !self.preloadedBodyHtmlDict.all().keys.contains(threadID) else {
            MailLogger.info("MailUnreadPreload repeat insert: \(threadID) preloadingCount: \(self.preloadingThreads.count())")
            return
        }
        guard self.preloadingThreads.count() < preloadMaxCount && self.preloadedBodyHtmlDict.all().values.count < preloadMaxCount else {
            MailLogger.info("MailUnreadPreload fail insert: \(threadID) because list full")
            return
        }
        preloadingThreads.insert(threadID)
        preloadOperationQueue.addOperation { [weak self] in
            guard let self = self else { return }
            MailLogger.info("MailUnreadPreload t_id: \(threadID)")
            self.preloadFor(threadId: threadID,
                            labelId: currentLabelID,
                            pageWidth: pageWidth,
                            paddingTop: paddingTop,
                            render: templateRender)
        }
    }

    @discardableResult
    func clear(threadID: String) -> Bool {
        MailLogger.info("MailUnreadPreload clear - threadID: \(threadID)")
        if preloadingThreads.contains(threadID) {
            preloadOperationQueue.cancelAllOperations()
            preloadingThreads.remove(threadID)
            preloadOperationQueue.addOperation { [weak self] in
                self?.queueBag = DisposeBag()
            }
            return true
        } else {
            if preloadedBodyHtmlDict.removeValue(forKey: threadID) == nil {
                MailLogger.warning("MailUnreadPreload clear not exist preload Cache")
                return false
            }
            MailLogger.info("MailUnreadPreload clear finish \(preloadedBodyHtmlDict.all().keys)")
            return true
        }
    }

    func clear() {
        MailLogger.info("MailUnreadPreload clear")
        preloadOperationQueue.cancelAllOperations()
        preloadingThreads.removeAll()
        preloadedBodyHtmlDict.removeAll()
        preloadOperationQueue.addOperation { [weak self] in
            MailLogger.info("MailUnreadPreload queueBag reset")
            self?.queueBag = DisposeBag()
        }
    }

    func getResultFor(threadID: String) -> PreloadResult? {
        let result = preloadedBodyHtmlDict[threadID]
        preloadedBodyHtmlDict[threadID] = nil
        return result
    }
    
    func hasResultFor(threadID: String) -> Bool {
        preloadedBodyHtmlDict[threadID] != nil
    }

    func clearResultFor(threadID: String) {
        preloadingThreads.remove(threadID)
        _ = preloadedBodyHtmlDict.removeValue(forKey: threadID)
    }

    private func preloadFor(threadId: String, labelId: String,
                            pageWidth: CGFloat, paddingTop: CGFloat, render: MailMessageListTemplateRender) {
        let getRustStart = MailTracker.getCurrentTime()
        if labelId == Mail_LabelId_SEARCH_TRASH_AND_SPAM {
            dataService.loadMailItem(threadId: threadId, labelId: labelId, messageId: nil, forwardInfo: nil)
                .subscribe(onNext: { [weak self] mailItem, isFromNet in
                    guard let self = self else { return }
                    guard !mailItem.messageItems.isEmpty else {
                        MailLogger.error("MailUnreadPreload response with empty message item, threadId: \(threadId), labelId: \(labelId), isFromNet: \(isFromNet)")
                        return
                    }
                    let getRustEnd = MailTracker.getCurrentTime()
                    let messageLabel = BehaviorRelay<(String, String)?>(value: nil)
//                    let messageLabels: SafeAtomic<[String: String]> = [:] + .readWriteLock
                    _ = mailItem.messageItems.map({
                        let messageItem = $0
                        Store.fetcher?.getMessageSuitableInfo(messageId: messageItem.message.id, threadId: threadId, scene: .readMessage)
                            .subscribe(onNext: { (resp) in
                                MailLogger.info("MailUnreadPreload getMessageSuitableLabel msgID: \(messageItem.message.id) label: \(resp.label)")
                                messageLabel.accept((messageItem.message.id, resp.label))
                                //messageLabels.updateValue(resp.label, forKey: messageItem.message.id)
                            }, onError: { (error) in
                                MailLogger.info("MailUnreadPreload getMessageSuitableLabel error: \(error)")
                            }).disposed(by: self.queueBag)
                    })
                    messageLabel.asObservable().subscribe(onNext: { messageLabelInfo in
                        guard let messageLabelInfo = messageLabelInfo else { return }
                        self.messageLabels.updateValue(messageLabelInfo.1, forKey: messageLabelInfo.0)
                        if self.messageLabels.all().keys.count == mailItem.messageItems.count {
                            MailLogger.info("MailUnreadPreload getMessageSuitableLabel messageLabels: \(self.messageLabels.value)")
                            let fromLabel = MsgListLabelHelper.resetFromLabelIfNeeded(labelId, msgLabels: self.messageLabels.all())
                            self.startParseHtml(mailItem: mailItem, isFromNet: isFromNet, labelId: fromLabel,
                                                pageWidth: pageWidth, paddingTop: paddingTop,
                                                getMailStartAndEnd: (getRustStart, getRustEnd), templateRender: render)
                        }
                    }).disposed(by: self.queueBag)
                }, onError: { e in
                    MailLogger.error("MailUnreadPreload rustError t_id: \(threadId), \(e)")
                }).disposed(by: self.queueBag)
        } else {
            dataService.loadMailItem(threadId: threadId, labelId: labelId, messageId: nil, forwardInfo: nil)
                .subscribe(onNext: { [weak self] mailItem, isFromNet in
                    guard !mailItem.messageItems.isEmpty else {
                        MailLogger.error("MailUnreadPreload response with empty message item, threadId: \(threadId), labelId: \(labelId), isFromNet: \(isFromNet)")
                        return
                    }
                    MailTracker.log(event: "email_unread_preloader_load_message_dev",
                                    params: [MailTracker.THREAD_ID: threadId, MailTracker.GET_RUST_DATA_FROM_NET: isFromNet ? 1 : 0])
                    let getRustEnd = MailTracker.getCurrentTime()
                    self?.startParseHtml(mailItem: mailItem, isFromNet: isFromNet, labelId: labelId,
                                         pageWidth: pageWidth, paddingTop: paddingTop,
                                         getMailStartAndEnd: (getRustStart, getRustEnd), templateRender: render)
                }, onError: { e in
                    MailLogger.error("MailUnreadPreload rustError t_id: \(threadId), \(e)")
                }).disposed(by: queueBag)
        }
    }

    private func preloadImagesIfNeed(mailItem: MailItem) {
        let images = mailItem.messageItems.flatMap { item in
            return item.message.images
        }
        // start preload for new image
        preloadServices.preloadImages(images: images, source: .newMessage)
    }

    private func startParseHtml(mailItem: MailItem, isFromNet: Bool,
                                labelId: String, pageWidth: CGFloat,
                                paddingTop: CGFloat, getMailStartAndEnd: (Int, Int),
                                templateRender: MailMessageListTemplateRender) {
        let parseStart = MailTracker.getCurrentTime()
        updatePreloadResult(mailItem: mailItem, html: nil, rustStartAndEnd: getMailStartAndEnd, parseHtmlStartAndEnd: nil, logParams: nil)

        let titleHeight: CGFloat
        var optimizeFeat = ""
        if MailMessageListTemplateRender.enableNativeRender {
            var cover: MailReadTitleViewConfig.CoverImageInfo? = nil
            if let info = mailItem.mailSubjectCover() {
                cover = MailReadTitleViewConfig.CoverImageInfo(subjectCover: info)
            }
            let fromLabelID = MsgListLabelHelper.resetFromLabelIfNeeded(labelId, msgLabels: messageLabels.all())
            let config = MailReadTitleViewConfig(title: mailItem.displaySubject,
                                                 fromLabel: labelId,
                                                 labels: mailItem.labels,
                                                 isExternal: mailItem.isExternal,
                                                 translatedInfo: nil,
                                                 coverImageInfo: cover,
                                                 spamMailTip: mailItem.spamMailTip)
            titleHeight = MailReadTitleView.calcViewSizeAndLabelsFrame(config: config,
                                                                       attributedString: nil,
                                                                       containerWidth: pageWidth)
            .viewSize.height
        } else {
            titleHeight = 0
        }
        let renderModel = MailMessageListRenderModel(mailItem: mailItem,
                                                     subject: mailItem.oldestSubject,
                                                     pageWidth: pageWidth,
                                                     userID: userID,
                                                     threadId: mailItem.threadId,
                                                     atLabelId: labelId,
                                                     locateMessageId: nil,
                                                     isFromChat: false,
                                                     keyword: nil,
                                                     paddingTop: paddingTop,
                                                     isFullReadMessage: false,
                                                     lazyLoadMessage: mailItem.shouldLazyLoadMessage,
                                                     titleHeight: titleHeight,
                                                     openProtectedMode: false,
                                                     featureManager: templateRender.accountContext.featureManager,
                                                     statFromType: .threadList,
                                                     fromNotice: false, 
                                                     importantContactsAddresses: [],
                                                     isPushNewMessage: false)
        templateRender.renderMessageListHtml(by: renderModel).subscribe(onNext: { [weak self] result in
            let parseEnd = MailTracker.getCurrentTime()
            let hasBigMessage = mailItem.messageItems.first(where: { $0.message.isBodyClipped == true }) != nil
            var logParams: [String: Any] = [MailTracker.MESSAGE_COUNT: mailItem.messageItems.count,
                                            MailTracker.THREAD_ID: mailItem.threadId,
                                            MailTracker.HAS_BIG_MESSAGE: hasBigMessage ? 1 : 0,
                                            MailTracker.GET_RUST_DATA_FROM_NET: isFromNet ? 1 : 0,
                                            MailTracker.FROM_NOTIFICATION: 0,
                                            MailTracker.IS_READ: mailItem.isRead ? 1 : 0,
                                            MailTracker.FROM_READ_MORE: 0,
                                            MailTracker.THREAD_BODY_LENGTH: result.html.utf8.count / 1024]
            optimizeFeat += "unreadpreload"
            if mailItem.shouldLazyLoadMessage {
                optimizeFeat += "lazyloadmessage"
            }
            let kvStore = MailKVStore(space: .global, mSpace: .global)
            let isContentAlwaysLight = kvStore.value(forKey: "mail_contentSwitch_isLight") ?? false
            if FeatureManager.open(FeatureKey(fgKey: .darkMode, openInMailClient: true)),
                #available(iOS 13.0, *),
               UDThemeManager.getRealUserInterfaceStyle() == .dark,
               !isContentAlwaysLight {
                optimizeFeat += "darkmode"
            }
            
            if FeatureManager.open(.scaleOptimize, openInMailClient: true) {
                optimizeFeat += "scaleoptimize"
            }
            if FeatureManager.open(.scalePerformance, openInMailClient: true) {
                optimizeFeat += "scalePerformance"
            }
            logParams[MailTracker.OPTIMIZE_FEAT] = optimizeFeat
            self?.updatePreloadResult(mailItem: mailItem, html: result.html, rustStartAndEnd: getMailStartAndEnd, parseHtmlStartAndEnd: (parseStart, parseEnd), logParams: logParams)
            // preload images after preload htmlbody
            self?.preloadImagesIfNeed(mailItem: mailItem)
        }, onError: { e in
            MailLogger.error("MailUnreadPreload parseError t_id: \(mailItem.threadId), \(e)")
        }).disposed(by: queueBag)
    }

    private func updatePreloadResult(mailItem: MailItem, html: String?, rustStartAndEnd: (Int, Int)?, parseHtmlStartAndEnd: (Int, Int)?, logParams: [String: Any]?) {
        var res: PreloadResult
        if var result = preloadedBodyHtmlDict[mailItem.threadId] {
            result.mailItem = mailItem
            result.bodyHtml = html
            result.rustStartAndEnd = rustStartAndEnd
            result.parseStartAndEnd = parseHtmlStartAndEnd
            res = result
        } else {
            let result = PreloadResult(mailItem: mailItem, bodyHtml: html, rustStartAndEnd: rustStartAndEnd, parseStartAndEnd: parseHtmlStartAndEnd)
            res = result
        }

        res.logParams.merge(other: logParams)
        preloadedBodyHtmlDict[mailItem.threadId] = res

        if html != nil {
            MailLogger.info("MailUnreadPreload finish t_id: \(mailItem.threadId)")
            //displaySubject: \(mailItem.displaySubject) preloadedBodyHtmlDict values: \(preloadedBodyHtmlDict.safeDict.values.map({ $0.bodyHtml?.count ?? 0 })) \(preloadedBodyHtmlDict.safeDict.values.map({ $0.mailItem.displaySubject }))")
            MailMessageListController.logStartTime(name: "preload finished for \(mailItem.threadId)")
            if FeatureManager.open(.unreadPreloadMailOpt, openInMailClient: true) {
                preloadingThreads.remove(mailItem.threadId)
            }
        }
    }
}
