//
//  MailMessageListTemplateRender.swift
//  MailSDK
//
//  Created by majx on 2020/3/19.
//

import Foundation
import LarkLocalizations
import LarkFoundation
import LarkExtensions
import LKCommonsLogging
import RxSwift
import ThreadSafeDataStructure
import RustPB
import LarkFeatureGating
import UniverseDesignTheme
import LarkStorage

struct MailMessageListRenderModel {
    /// base properties
    var mailItem: MailItem
    var subject: String = ""
    var threadId: String = ""
    var avatar: String = ""
    var atLabelId: String = ""
    /// 点击 Bot 读信需定位到具体 message，其他场景无需定义
    var locateMessageId: String = ""
    var isFromChat: Bool
    var fromNotice: Bool
    var keyword: String = ""
    /// if page width changed( like after rotate screen), need render mail again
    var pageWidth: CGFloat
    /// if is this is a share mail, should get shareOwnerInfo before render
    var needRelocateCurrentLabel: Bool = false
    let paddingTop: CGFloat
    /// messageID: itemsCount
    fileprivate let contextMenuItemsCount: [String: Int]
    let isFullReadMessage: Bool
    let lazyLoadMessage: Bool
    let titleHeight: CGFloat
    let statFromType: MessageListStatInfo.FromType
    let openProtectedMode: Bool
    var messageLabels: [String: String] = [:]
    var importantContactsAddresses: [String] = []
    var isPushNewMessage: Bool = false // feed专用，默认为false，用于判断下拉上拉邮件与推送邮件是否需要展开
    init(mailItem: MailItem,
         subject: String,
         pageWidth: CGFloat,
         userID: String,
         threadId: String,
         atLabelId: String,
         locateMessageId: String?,
         isFromChat: Bool,
         keyword: String?,
         paddingTop: CGFloat,
         isFullReadMessage: Bool,
         lazyLoadMessage: Bool,
         titleHeight: CGFloat,
         openProtectedMode: Bool,
         featureManager: UserFeatureManager,
         statFromType: MessageListStatInfo.FromType,
         avatar: String = "",
         fromNotice: Bool,
         importantContactsAddresses: [String],
         isPushNewMessage: Bool) {
        self.mailItem = mailItem
        self.subject = subject
        self.myUserId = userID
        self.threadId = threadId
        self.atLabelId = atLabelId
        self.avatar = avatar
        self.locateMessageId = locateMessageId ?? ""
        self.pageWidth = pageWidth
        self.isFromChat = isFromChat
        self.keyword = keyword ?? ""
        self.paddingTop = paddingTop
        self.isFullReadMessage = isFullReadMessage
        self.lazyLoadMessage = lazyLoadMessage
        self.titleHeight = titleHeight
        self.statFromType = statFromType
        self.openProtectedMode = openProtectedMode
        self.fromNotice = fromNotice
        self.contextMenuItemsCount = MailMessageListRenderModel.contextMenuItemsCountFor(labelID: atLabelId, mailItem: mailItem, isFromChat: isFromChat, userID: userID, featureManager: featureManager)
        self.importantContactsAddresses = importantContactsAddresses
        self.isPushNewMessage = isPushNewMessage
    }

    /// computed properties
    var allLabels: [MailClientLabel] {
        return mailItem.labels
    }
    var threadLabels: [MailFilterLabelCellModel] {
        return mailItem.labels.map({ MailFilterLabelCellModel(pbModel: $0) })
    }
    var isActionable: Bool {
        return true
    }

    let myUserId: String

    /// 渲染时获取contextMenu个数，此时 isTranslated 为 false
    private static func contextMenuItemsCountFor(
        labelID: String,
        mailItem: MailItem,
        isFromChat: Bool,
        userID: String,
        featureManager: UserFeatureManager
    ) -> [String: Int] {
        var itemsCountMap = [String: Int]()
        for messageItem in mailItem.messageItems {
            let items = contextMenuItemsFor(atLabelID: labelID, mailItem: mailItem, messageItem: messageItem, isTranslated: false, isFromChat: isFromChat, userID: userID, featureManager: featureManager)
            itemsCountMap[messageItem.message.id] = items.count
        }
        return itemsCountMap
    }

    static func contextMenuItemsFor(
        atLabelID: String,
        mailItem: MailItem,
        messageItem: MailMessageItem,
        isTranslated: Bool,
        isFromChat: Bool,
        userID: String,
        featureManager: UserFeatureManager,
        needBlockTrash: Bool = false
    ) -> [MailContextActionItemType] {
        guard atLabelID != Mail_LabelId_Outbox else {
            return []
        }
        var items = [MailContextActionItemType]()

        if featureManager.open(.revertScale, openInMailClient: true) {
            items.append(.revertScale)
        }

        if atLabelID == Mail_LabelId_Stranger && FeatureManager.open(FeatureKey(fgKey: .stranger, openInMailClient: false)) {
            // reply
            items.append(.reply)

            // replyall
            if messageItem.message.canReplyAll {
                items.append(.replyAll)
            }

            if featureManager.open(FeatureKey(fgKey: .translation, openInMailClient: false)) {
                if isTranslated {
                    items.append(.turnOffTranslation)
                } else {
                    items.append(.translate)
                }
            }
            return items
        }

        let showSendChat: Bool

        if atLabelID == Mail_LabelId_SHARED {
            showSendChat = mailItem.code == .owner
        } else {
            if featureManager.open(.searchTrashSpam, openInMailClient: true) {
                showSendChat = !isFromChat && ![Mail_LabelId_Trash, Mail_LabelId_Spam].contains(atLabelID)
            } else {
                showSendChat = !isFromChat
            }

        }

        /// if is schedule send message
        if messageItem.message.scheduleSendTimestamp > 0 {
            items.append(.cancelScheduleSend)

            // translate
            if FeatureManager.open(.translation) {
                if isTranslated {
                    items.append(.turnOffTranslation)
                } else {
                    items.append(.translate)
                }
            }
            return items
        } else {
            // 打开所在会话
            if !mailItem.feedCardId.isEmpty && FeatureManager.open(FeatureKey(fgKey: .mailToFeed, openInMailClient: false)) && mailItem.threadId.isEmpty {
                items.append(.jumpToThread)
            }
            // reply
            items.append(.reply)

            // replyall
            if messageItem.message.canReplyAll {
                items.append(.replyAll)
            }

            // forward
            items.append(.forward)

            if featureManager.open(.emlAsAttachment, openInMailClient: false) {
                items.append(.emlAsAttachment)
            }

            if messageItem.isFromMe, !isFromChat, !Store.settingData.mailClient {
                items.append(.reEdit)
            }

            // recall
            if MailRecallManager.shared.shouldShowRecallAction(for: messageItem, myUserId: userID),
               !isFromChat, !Store.settingData.mailClient {
                items.append(.recall)
            }

            // translate
            if featureManager.open(.translation) {
                if isTranslated {
                    items.append(.turnOffTranslation)
                } else {
                    items.append(.translate)
                }
            }

            // sendToChat
            if showSendChat && !Store.settingData.mailClient {
                items.append(.forwardToChat)
            }

            if !needBlockTrash && atLabelID != Mail_LabelId_SEARCH && !isFromChat && featureManager.open(.trashMessage) {
                // sendToChat不展示单封删除入口
                if atLabelID == Mail_LabelId_Spam || atLabelID == Mail_LabelId_Trash {
                    // 单 Message 永久删除
                    items.append(.deleteMessagePermanently)
                } else {
                    // 单 Message Trash
                    items.append(.trashMessage)
                }
            }


            var labelIDs = mailItem.labels.map { (label) -> String in
                label.id
            }.filter { (label) in
                label != Mail_LabelId_Sent
            }

            // 如果只存在于发件箱，则不显示按钮(新增feed逻辑）
            if !mailItem.feedCardId.isEmpty {
                let fromViewMessageItem = mailItem.feedMessageItems.first(where: { $0.item.message.id == messageItem.message.id })
                if let fromViewLabelIDs = fromViewMessageItem?.labelIds,
                    !fromViewLabelIDs.isEmpty
                    && fromViewLabelIDs.first != Mail_LabelId_Sent
                    && FeatureManager.open(.blockSender, openInMailClient: false) {
                    items.append(.blockSender)
                }
            } else if atLabelID != Mail_LabelId_Sent && !labelIDs.isEmpty && !isFromChat &&
                FeatureManager.open(.blockSender, openInMailClient: false) {
                items.append(.blockSender)
            }

            // unsubscribe
            if MailUnsubscribeManager.shouldShowUnsubscribeMenu(for: messageItem) && !Store.settingData.mailClient {
                items.append(.unsubscribe)
            }
            return items
        }
    }

    func shouldShowDelegationInfo(for mail: MailMessageItem, accountContext: MailAccountContext) -> Bool {
        let fgOpen = accountContext.featureManager.open(FeatureKey(fgKey: .migrationDelegation, openInMailClient: false))
        let hasDelegation = mail.message.hasSenderDelegation
        var isDelegateForMyself = false
        if mail.message.senderDelegation.address == mail.message.from.address {
            isDelegateForMyself = true
        }
        let shouldShow = fgOpen && hasDelegation && !isDelegateForMyself
        MailLogger.info("[Mail_Migration_Delegation] check should show delegation messageId \(mail.message.id) should show: \(shouldShow) fgOpen:\(fgOpen) and hasDelegation:\(hasDelegation) isToMyself \(isDelegateForMyself) ")
        return shouldShow
    }

    func fetchAndUpdateCurrentInterceptedStateNew(
        renderModel: MailMessageListRenderModel,
        messageItems: [MailMessageItem],
        userID: String,
        labelID: String,
        dataManager: MailSettingManager,
        store: MailKVStore,
        from: MessageListStatInfo.FromType) -> [String] {
        let startTime = Date().timeIntervalSince1970 * 1000
        let queue = DispatchQueue(label: "interceptedImageblockQueue")
        let semaphore = DispatchSemaphore(value: 0)
        var result: [String] = []
        let messageIDs = MailInterceptWebImageHelper.filterInterceptedMessageIDs(
            messageItems: mailItem.messageItems,
            userID: userID,
            labelID: labelID,
            dataManager: Store.settingData,
            store: store,
            from: from)

        let messageFroms = MailInterceptWebImageHelper.filterInterceptedMessageFroms(
            messageItems: mailItem.messageItems,
            userID: userID,
            labelID: labelID,
            dataManager: Store.settingData,
            store: store,
            from: from)

        let withoutFromsMessageIDs = MailInterceptWebImageHelper.filterInterceptedMessageWithoutFromsIds(
            messageItems: mailItem.messageItems,
            userID: userID,
            labelID: labelID,
            dataManager: Store.settingData,
            store: store,
            from: from,
            fromsAddress: messageFroms)

        guard !messageIDs.isEmpty else { return [] }
            queue.sync {
                MailDataSource.shared.fetchMessagesImageBlocked(messageFroms: messageFroms, messageIDs: withoutFromsMessageIDs)
                    .subscribe(onNext: { resp in
                        let resultIDs = resp.allowedIds
                        let resultFromsToIDs = MailInterceptWebImageHelper.allowedfromsTomessageIDs(messageItems:mailItem.messageItems, froms: resp.allowedFroms)
                        let resultIdsSet = Set(resultIDs)
                        let resultFromsToIDsSet = Set(resultFromsToIDs)
                        let allowedMessageIdsSet = resultIdsSet.union(resultFromsToIDsSet)

                        var messageIDsSet = Set(messageIDs)
                        let blockMessageIDsSet = messageIDsSet.subtracting(allowedMessageIdsSet)
                        let blockMessageIDs = Array(blockMessageIDsSet)
                        let costTime = (Date().timeIntervalSince1970 * 1000) - startTime
                        MailTracker.log(event: "email_web_image_white_list_dev",
                                        params: ["total_msg_count": messageIDs.count,
                                                 "white_list_msg_count": allowedMessageIdsSet.count,
                                                 "black_list_msg_count": blockMessageIDsSet.count,
                                                 "get_intercept_msg_ids_time": costTime])
                        result = blockMessageIDs
                        semaphore.signal()
                    }, onError: { e in
                        MailLogger.error("Failed to fetch message intercepted state, error: \(e)")
                        result = messageIDs
                        semaphore.signal()
                    })
                semaphore.wait()
            }
        return result
    }
}

// MARK: - MailMessageListTemplateRender
class MailMessageListTemplateRender {

    /// 异步预加载render
    static func asyncPreloadRender(accountContext: MailAccountContext, _ initHandler: @escaping ((MailMessageListTemplateRender) -> Void)) {
        DispatchQueue.global(qos: .userInitiated).async {
            let render = MailMessageListTemplateRender(accountContext: accountContext)
            asyncRunInMainThread {
                initHandler(render)
                MailMessageListTemplateRender.logger.info("asyncPreloaded")
            }
        }
    }

    /// 是否开启同层首屏渲染
    static let enableNativeRender = NativeRenderService.shared.enable

    let serialQueue = DispatchQueue(label: "MailMessageListTemplateRender.Serial", qos: .userInitiated)

    internal static let logger = Logger.log(MailMessageListTemplateRender.self, category: "Module.MessageListRender")
    typealias RenderResult = (threadId: String, html: String)

    static let templateRegex = try? NSRegularExpression(pattern: "(\\$.*?\\$)+")
    private static let tableOpenRegex = try? NSRegularExpression(pattern: "<\\s*table[^>]*", options: .caseInsensitive)
    private static let tableCloseRegex = try? NSRegularExpression(pattern: "<\\s*\\/\\s*table\\s*>", options: .caseInsensitive)
    private static let imgCidRegex = try? NSRegularExpression(pattern: "<img.*?\\ssrc=\"(cid:.*?)\"", options: [.caseInsensitive, .dotMatchesLineSeparators])
	private static let imgHttpRegex = try? NSRegularExpression(pattern: "<[^>]*img[^>]*\\s*(src)\\s*=\\s*[\'\"]*https?:", options: .caseInsensitive)
    private static let tableHttpRegex = try? NSRegularExpression(pattern: "<[^>]*(td|th|table)[^>]*\\s*(background)\\s*=\\s*[\"\']?[^>]*https?:", options: .caseInsensitive)
    private static let styleAttrHttpRegex = try? NSRegularExpression(pattern: "<[^>]*style\\s*=\\s*\"[^>]*(background|background-image|content)\\s*:\\s*url\\(\\s*[\'\"]?\\s*https?://[^<]*>", options: .caseInsensitive)
    private static let styleTagHttpRegex = try? NSRegularExpression(pattern: "<style([\\s\\S]+?)</style>", options: .caseInsensitive)
    private static let styleElemHttpRegex = try? NSRegularExpression(pattern: "(background|background-image|content)\\s*:\\s*url\\(\\s*[\'\"]?\\s*(https?)://", options: .caseInsensitive)
    private static let whiteSpacePreNoWrapRegex = try? NSRegularExpression(pattern: "<[^>]*style\\s*=\\s*\"[^>]*white-space\\s*:\\s*(pre|nowrap)(\\s*[\";])", options: .caseInsensitive)
    private static let whiteSpacePreRegex = try? NSRegularExpression(pattern: "<[^>]*style\\s*=\\s*\"[^>]*white-space\\s*:\\s*(pre)(\\s*[\";])", options: .caseInsensitive)
    private static var templateMatches = ThreadSafeDataStructure.SafeDictionary<String, [(String, Range<String.Index>)]>(synchronization: .readWriteLock)

    lazy var renderQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "mail.messagelist.templaterender"
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInitiated
        return queue
    }()

    lazy var renderScheduler: OperationQueueScheduler = {
        let scheduler = OperationQueueScheduler(operationQueue: renderQueue)
        return scheduler
    }()

    var accountContext: MailAccountContext
    let template: MailMessageListTemplate
    let replaceComponentManager = MailMessageReplaceComponentManager()

    init(accountContext: MailAccountContext) {
        self.accountContext = accountContext
        self.template = MailMessageListTemplate()
        replaceComponentManager.addComponet(MailMessageCalendarReplaceComponent(serviceProvider: accountContext.provider))
        replaceComponentManager.setCurrentState(.getSection, params: template)
    }

    func getCalendarCardTemplate(mail: MailMessageItem) -> String {
        if let calendarComponent = replaceComponentManager.replaceComponents.compactMap({ $0 as? MailMessageCalendarReplaceComponent}).first {
            return calendarComponent.replaceForCalendarCard(mail: mail)
        }
        return ""
    }

    // 读本地内容区DM/LM的设置，true表示内容区始终LightMode，false跟随系统
    func isContentAlwaysLightMode() -> Bool {
        let kvStore = MailKVStore(space: .global, mSpace: .global)
        return kvStore.value(forKey: "mail_contentSwitch_isLight") ?? false
    }

    /// Proprocess html: 1, handle table div. 2, handle cid. 3. change white-space:pre to white-space:pre-wrap
    static func preprocessHtml(
        _ html: String,
        messageID: String,
        messageItem: MailMessageItem,
        isFromChat: Bool,
        sharedService: MailSharedServices
    ) -> String {
        assert(!Thread.isMainThread, "Should not preprocess HTML on Main Thread!!")

        let imageService = sharedService.imageService
        let featureManager = sharedService.featureManager
        var html = NSMutableString(string: html)
        let isScaleOptimize = featureManager.open(.scaleOptimize, openInMailClient: true)
        if !isScaleOptimize {
            // 开启优化后，不替换 mTableArea，由js处理
            tableOpenRegex?.replaceMatchesInString(string: html) { (match) -> String in
                let matchRange = match.range(at: 0)
                let orgTableHead = html.substring(with: matchRange)
                var res = "<div class='mTableArea'>"
                res.append(orgTableHead)
                return res
            }
            tableCloseRegex?.replaceMatchesInString(string: html, with: "</table></div>")
        }

        let map = imageService.htmlAdapter.createCidTokenMap(messageItem: messageItem)
        imgCidRegex?.replaceMatchesInString(string: html, matchIndex: 1) { (match) -> String in
            // replace "cid:xxx" with "token:yyy"
            let cidString = html.substring(with: match.range(at: 1))
            if let cid = cidString.split(separator: ":").last {
                if Store.settingData.mailClient && !isFromChat {
                    return imageService.imageAdapter.createTokenSchemeUrl(cid: String(cid),
                                                                                    messageId: messageID, cidTokenMap: map)
                } else {
                    return imageService.htmlAdapter.createTokenSchemeUrl(cid: String(cid), cidTokenMap: map)
                }
            }
            assert(false, "cannot replace cid with token")
            MailLogger.info("vvImage \(cidString.md5())_msgId\(messageID)")
            return cidString
        }
        // change white-space:pre to white-space:pre-wrap, in case content overflow
        let whiteSpaceRegex = isScaleOptimize ? whiteSpacePreRegex : whiteSpacePreNoWrapRegex;
        whiteSpaceRegex?.replaceMatchesInString(string: html, matchIndex: 1, block: { (match) -> String in
            let whiteSpaceValue = html.substring(with: match.range(at: 1))
            if whiteSpaceValue == "pre" {
                return "pre-wrap"
            } else if whiteSpaceValue == "nowrap" {
                return "normal"
            } else {
                return whiteSpaceValue
            }
        })

        let length = html.length

        if featureManager.open(.interceptWebImage, openInMailClient: true) {
            if featureManager.open(.sanitizeWebImage, openInMailClient: true) {
                let sanitizeStartTime = Date().timeIntervalSince1970 * 1000
                var hasWebImage = false
                do {
                    let result = try sharedService.dataService.rewriteHTMLImageURL(html: html as String)
                    hasWebImage = result.1
                    html = NSMutableString(string: result.0)
                } catch(let error) {
                    MailLogger.error("[Intercept-image] Failed to sanitize image URL, error: \(error)")
                }

                let sanitizeCostTime = (Date().timeIntervalSince1970 * 1000) - sanitizeStartTime

                MailTracker.log(event: "email_web_image_sanitize_result_dev",
                                params: ["sanitize_time": sanitizeCostTime,
                                         "has_web_image": hasWebImage ? "true" : "false"])

                let event = MailAPMEventSingle.WebImageSanitize()
                event.totalCostTime = sanitizeCostTime / 1000
                event.endParams.append(MailAPMEventSingle.WebImageSanitize.EndParam.has_web_image(hasWebImage ? "true" : "false"))
                event.endParams.append(MailAPMEventSingle.WebImageSanitize.EndParam.messageIDs("\(messageID);"))
                event.endParams.append(MailAPMEventConstant.CommonParam.status_success)
                event.markPostStart()
                event.postEnd()

                MailLogger.info("[Intercept-image] web image intercept sanitize cost time: \(sanitizeCostTime), length: \(length) hasWebImage: \(hasWebImage)")
            } else {

                let start = Date().timeIntervalSince1970 * 1000
                var imgCount = 0
                var tableCount = 0
                var styleAttr = 0
                var styleTag = 0

                // 匹配 src 是 http/https 的 img tag，替换 src 为 intercepted-data-src
                imgHttpRegex?.replaceMatchesInString(string: html, matchIndex: 1) { (_) -> String in
                    imgCount += 1
                    return "intercepted-data-src"
                }
                // 匹配 table、td、th 的 background src 是 http/https 的 tag，替换 background 为 intercepted-table-background
                tableHttpRegex?.replaceMatchesInString(string: html, matchIndex: 2) { (_) -> String in
                    tableCount += 1
                    return "intercepted-table-background"
                }
                // 匹配 style 属性有 background、background-image、content 且 src 是 http/https tag
                styleAttrHttpRegex?.replaceMatchesInString(string: html, matchIndex: 0) { (match) -> String in
                    // 替换 style 内 background、background-image、content 的 src 为 http + intercepted-data-url
                    let tagStr = NSMutableString(string: html.substring(with: match.range(at: 0)))
                    styleElemHttpRegex?.replaceMatchesInString(string: tagStr, matchIndex: 2) { (match) -> String in
                        if match.numberOfRanges > 2 {
                            styleAttr += 1
                            let matchStr = tagStr.substring(with: match.range(at: 2))
                            return matchStr + "intercepted-data-url"
                        }
                        return ""
                    }
                    return tagStr as String
                }
                // 匹配 style tag
                styleTagHttpRegex?.replaceMatchesInString(string: html, matchIndex: 0) { (match) -> String in
                    // 替换 style tag 内 background、background-image、content 的 src 为 http + intercepted-data-url
                    let styleStr = NSMutableString(string: html.substring(with: match.range(at: 0)))
                    styleElemHttpRegex?.replaceMatchesInString(string: styleStr, matchIndex: 2) { (match) -> String in
                        if match.numberOfRanges > 2 {
                            styleTag += 1
                            let matchStr = styleStr.substring(with: match.range(at: 2))
                            return matchStr + "intercepted-data-url"
                        }
                        return ""
                    }
                    return styleStr as String
                }

                let costTime = (Date().timeIntervalSince1970 * 1000) - start
                let hasWebImage = imgCount != 0 || tableCount != 0 || styleAttr != 0 || styleTag != 0

                MailTracker.log(event: "email_web_image_regex_result_dev",
                                params: ["regex_time": costTime,
                                         "has_web_image": hasWebImage ? "true" : "false"])

                MailLogger.info("[Intercept-image] web image intercept regexs cost time: \(costTime), length: \(length) img: \(imgCount), table: \(tableCount), styleAttr: \(styleAttr), styleTag: \(styleTag)")
            }
        }

        return html as String
    }

    func renderMessageListHtml(by renderModel: MailMessageListRenderModel) -> Observable<RenderResult> {
        return Observable<RenderResult>.create { [weak self] observer in
            MailMessageListTemplateRender.logger.debug("render template all start -----> ")
            let start = CACurrentMediaTime()
            self?.preprocessBodyHtml(by: renderModel, complate: { [weak self] (bodyHtml) in
                guard let `self` = self else { return }
                observer.onNext(RenderResult(threadId: renderModel.threadId, html: bodyHtml))
                observer.onCompleted()
                MailMessageListTemplateRender.logger.debug("render template all finish -----> cost: \(self.timeCost(start)) ms")
            })
            return Disposables.create()
        }.observeOn(self.renderScheduler)
    }

    private func preprocessBodyHtml(by renderModel: MailMessageListRenderModel, complate: @escaping (String) -> Void) {
        var start = CACurrentMediaTime()
        MailMessageListTemplateRender.logger.debug("render template bodyHtml start -----> ")
        let bodyHtml = template.sectionMain
        var mailModel = renderModel
        let unreadPreloadOpt = FeatureManager.open(.unreadPreloadMailOpt, openInMailClient: true)
        let queueGroup = DispatchGroup()
        let semaphore = DispatchSemaphore(value: 0)
        let preprocessQueue = DispatchQueue(label: "preprocessBodyHtml.preprocessQueue", qos: .userInitiated)
        let messageItemsCount = mailModel.mailItem.messageItems.count
        let htmlTableQueue = DispatchQueue(label: "preprocessBodyHtml.htmlTableQueue", qos: .userInitiated, attributes: .concurrent)
        for i in 0..<messageItemsCount {
            queueGroup.enter()
            htmlTableQueue.async(group: queueGroup) { [weak self] in
                guard let self = self else { return }
                var messageBodyHtml = ""
                var messageId = ""
                var newBodyHtml = ""
                preprocessQueue.sync {
                    messageBodyHtml = mailModel.mailItem.messageItems[i].message.bodyHtml
                    messageId = mailModel.mailItem.messageItems[i].message.id
                }
                newBodyHtml = MailMessageListTemplateRender.preprocessHtml(messageBodyHtml,
                                                                           messageID: messageId,
                                                                           messageItem: mailModel.mailItem.messageItems[i],
                                                                           isFromChat: mailModel.isFromChat,
                                                                           sharedService: self.accountContext.sharedServices)
                preprocessQueue.sync {
                    mailModel.mailItem.messageItems[i].message.bodyHtml = newBodyHtml
                }
                MailMessageListTemplateRender.logger.debug("render template preprocess table finish -----> cost: \((CACurrentMediaTime() - start) * 1000) ms")
                queueGroup.leave()
                semaphore.signal() // 任务完成时信号量加 1
            }
        }

        if unreadPreloadOpt {
            for _ in 0..<messageItemsCount {
                semaphore.wait()
            }
            MailMessageListTemplateRender.logger.debug("Replace benchmark: render template preprocessHtmlTable finish -----> cost: \(self.timeCost(start)) ms")
            start = CACurrentMediaTime()
            self.replaceForMain(by: mailModel, html: bodyHtml, complete: { [weak self] (bodyHtml) in
                guard let self = self else { return }
                MailMessageListTemplateRender.logger.debug("Replace benchmark: render template bodyHtml finish -----> cost: \(self.timeCost(start)) ms")
                complate(bodyHtml)
            })
        } else {
            queueGroup.notify(queue: preprocessQueue) { [weak self] in
                guard let `self` = self else { return }
                MailMessageListTemplateRender.logger.debug("Replace benchmark: render template preprocessHtmlTable finish -----> cost: \(self.timeCost(start)) ms")
                start = CACurrentMediaTime()
                self.replaceForMain(by: mailModel, html: bodyHtml, complete: { [weak self] (bodyHtml) in
                    guard let self = self else { return }
                    MailMessageListTemplateRender.logger.debug("Replace benchmark: render template bodyHtml finish -----> cost: \(self.timeCost(start)) ms")
                    complate(bodyHtml)
                })
            }
        }
    }

    private func filteredTemplateItem(templateStr: String, targetStr: String, showActions: Bool) -> String {
        if templateFilterKeys(isActionable: showActions).contains(templateStr) {
            return ""
        } else {
            return targetStr
        }
    }

    private func templateFilterKeys(isActionable: Bool) -> [String] {
        guard !isActionable else {
            return []
        }
        return [
            "message_labels"
        ]
    }

    private func timeCost(_ start: CFTimeInterval) -> CFTimeInterval {
        return (CACurrentMediaTime() - start) * 1000
    }
}

// MARK: - 模版HTML块创建方法
extension MailMessageListTemplateRender {
    func createMessageLabelItem(_ label: String, dirLTR: Bool, fontColor: String, bgColor: String, isGoogle: Bool = false) -> String {
        return replaceFor(template: template.sectionMessageLabelItem) { (key) -> String? in
            switch key {
            case "text_color":
                return fontColor.htmlEncoded
            case "bg_color":
                return bgColor.htmlEncoded
            case "label_text":
                return label.htmlEncoded
            case "label_dir":
                return dirLTR ? "ltr" : "rtl"
            case "isforward":
                return ""
            default:
                return nil
            }
        }
    }

    func createDraftItem(_ draft: MailDraft, mailItem: MailItem, myUserId: String) -> String {
        return replaceFor(template: template.sectionDraftItem) { (keyword) -> String? in
            switch keyword {
            case "message_id":
                let msgID: String
                msgID = draft.replyToMailID
                return msgID.htmlEncoded
            case "thread_id":
                return draft.threadID.htmlEncoded
            case "draft_id":
                return draft.id.htmlEncoded
            case "from_name":
                return draft.content.from.mailDisplayName
            case "from_address":
                return draft.content.from.address.htmlEncoded
            case "user_type":
                return String(Email_Client_V1_Address.LarkEntityType.user.rawValue)
            case "tenant_id":
                return draft.content.from.tenantId
            case "user_id":
                return draft.content.from.larkID
            case "message_list_avatar":
                let res: String
                let from = draft.content.from
                let type = from.type?.toLarkEntityType() ?? ContactType.unknown.toLarkEntityType()

                if MailMessageListTemplateRender.enableNativeRender {
                    res = replaceForFromNativeAvatar(userid: from.larkID, name: from.mailDisplayName,
                                                     address: from.address,
                                                     userType: type,
                                                     tenantId: from.tenantId,
                                                     isMe:false)
                } else {
                    res = replaceForFromAvatar(userid: from.larkID, userType: type)
                }
                return res
            case "body_plaint":
                return draft.content.bodySummary.replacingOccurrences(of: "'", with: "\\'").htmlEncoded
            case "draft_title":
                return BundleI18n.MailSDK.Mail_Normal_Draft.htmlEncoded
            case "show_draft_attachment_icon":
                return draft.attachmentCount > 0 ? "" : "hide"
            case "show_draft_delete_icon":
                return ""
//                return isShareEmail(mailItem: mailItem) && !isShareOwner(mailItem: mailItem) ? "hide" : ""
            default:
                return nil
            }
        }.replacingOccurrences(of: "\n", with: "")
    }
}

// MARK: - render options
// MARK: - 模版内容插值替换方法
extension MailMessageListTemplateRender {
    static func replaceFor(template: String, patternHandler: (String) -> String?) -> String {
        let matches: [(String, Range<String.Index>)]
        if let m = MailMessageListTemplateRender.templateMatches[template] {
            matches = m
        } else {
            matches = template.getTemplateItemMatches()
            MailMessageListTemplateRender.templateMatches[template] = matches
        }
        if matches.count > 0 {
            var result = ""
            var preRange: Range<String.Index>?
            for match in matches {
                if let preRange = preRange {
                    result.append(String(template[preRange.upperBound..<match.1.lowerBound]))
                } else {
                    result.append(String(template[..<match.1.lowerBound]))
                }
                if let patternMatch = patternHandler(match.0) {
                    result.append(patternMatch)
                } else {
                    MailLogger.error("MailMessageListTemplateRender keyword $\(match.0)$ not handled!!!")
                    //mailAssertionFailure("Template keyword $\(match.0)$ not handled!!!")
//                    result.append("$")
//                    result.append(match.0)
//                    result.append("$")

                }
                preRange = match.1
            }
            if let preRange = preRange, preRange.upperBound < template.endIndex {
                result = result + template[preRange.upperBound...]
            }
            return result
        } else {
            return template
        }
    }

    func replaceFor(template: String, patternHandler: (String) -> String?) -> String {
        return MailMessageListTemplateRender.replaceFor(template: template, patternHandler: patternHandler)
    }

    /// 入口
    private func replaceForMain(by renderModel: MailMessageListRenderModel, html: String, complete: @escaping (String) -> Void) {
        var isDarkMode = ""
        if accountContext.featureManager.open(FeatureKey(fgKey: .darkMode, openInMailClient: true)), #available(iOS 13.0, *), UDThemeManager.getRealUserInterfaceStyle() == .dark {
            isDarkMode = "dark"
        }
        // 陌生人卡片非会话模式下，会强制调整新邮件在顶部，tips则无法在顶部
        let canAtTop = !(renderModel.atLabelId == Mail_LabelId_Stranger && !(Store.settingData.getCachedCurrentSetting()?.enableConversationMode ?? true))
        let tipsAtTop = !(Store.settingData.getCachedCurrentSetting()?.mobileMessageDisplayRankMode ?? false) && canAtTop
        MailMessageListTemplateRender.logger.debug("render template main start ------>")
        let start = CACurrentMediaTime()
        let replaceQueue = DispatchQueue(label: "MailMessageListTemplateRender.replaceForMain", qos: .userInitiated, attributes: .concurrent)
        var stepStart = CACurrentMediaTime()
        replaceQueue.async { [weak self] in
            self?.replaceForMessageList(by: renderModel, isUpdate: false, complete: { (messageListHtml) in
                guard let self = self else { return }
                MailMessageListTemplateRender.logger.debug("render template get message list finish for \(renderModel.mailItem.messageItems.count) -----> cost:\(self.timeCost(stepStart)) ms ")
                stepStart = CACurrentMediaTime()
                let useNewQuoteStyle = self.accountContext.featureManager.open(.quoteStyle)
                let strangerStyle = self.accountContext.featureManager.open(.stranger) && renderModel.atLabelId == Mail_LabelId_Stranger
                let isShare = Store.settingData.getCachedCurrentAccount()?.isShared ?? true
                let isFeedCard = !renderModel.mailItem.feedCardId.isEmpty && self.accountContext.featureManager.open(FeatureKey(fgKey: .mailToFeed, openInMailClient: false))
                let bodyHtml = self.replaceFor(template: html) { (pattern) -> String? in
                    var target: String?
                    var shouldEncode = true
                    switch pattern {
                    case "message_loadmore_up":
                        shouldEncode = false
                        target = isFeedCard ? self.replaceFormessageLoadMore(messageLoadMoreId: "message_loadmore_up") : ""
                    case "message_loadmore_down":
                        shouldEncode = false
                        target = isFeedCard ? self.replaceFormessageLoadMore(messageLoadMoreId: "message_loadmore_down") : ""
                    case "feed_card_bottom_display":
                        target = isFeedCard ? "" : "display-none"
                    case "rootDarkClass": target = isDarkMode
                    case "header_title":  return self.headerTitleHandler(strangerStyle: strangerStyle, isFeedCard:isFeedCard, renderModel: renderModel)
                    case "stranger_card": return strangerStyle ? "stranger_card" : ""
                    case "has_more_top": return strangerStyle && tipsAtTop ? "has_more_top" : ""
                    case "has_more_bottom": return strangerStyle && !tipsAtTop ? "has_more_bottom" : ""
                    case "has_more_tips": return strangerStyle && !renderModel.mailItem.isLastPage ? BundleI18n.MailSDK.Mail_StrangerMail_MaximumMailsAllowSenderToViewAll_Toast(100) : ""
                    case "quote_expand_title": target = useNewQuoteStyle ? BundleI18n.MailSDK.Mail_Edit_ShowHistoryEmail : ""
                    case "quote_hide_title": target = useNewQuoteStyle ? BundleI18n.MailSDK.Mail_Edit_HideHistoryEmail : ""
                    case "is_mail_client": target = (Store.settingData.mailClient && !renderModel.isFromChat) ? "true" : ""
                    case "locate_to_expand": target = "true"
                    case "init_anchor_point": target = renderModel.isFullReadMessage ? "larkmail-readmore-anchor" : ""
                    case "body_padding_top": target = "\(renderModel.paddingTop)px"
                    case "header_display": target = "none"
                    case "native-title-height": target = self.nativeTitleHeightHandler(strangerStyle: strangerStyle, renderModel: renderModel)
                    case "feed_card": return isFeedCard ? "feed_card" : ""
                    case "ipad": return Display.pad ? "ipad" : ""
                    case "keyword":
                        shouldEncode = false
                        target = renderModel.keyword.isEmpty ? "": renderModel.keyword.replacingOccurrences(of: "'", with: "\\'")
                    case "my_user_id": target = renderModel.myUserId
                    case "me_wording": target = MailModelManager.shared.getUserName()
                    case "ownerwording":
                        shouldEncode = false
                        target = BundleI18n.MailSDK.Mail_DocPreview_Owner
                    case "rescale_on_resize": target = self.accountContext.featureManager.open(FeatureKey(fgKey: .rescaleOnResize, openInMailClient: true)) ? "true" : ""
                    case "optimizeImgDownload": target = self.accountContext.featureManager.open(FeatureKey(fgKey: .optimizeImgDownload, openInMailClient: true)) ? "true" : "false"
                    case "enableImageQueue":
                        target = self.accountContext.featureManager.open(FeatureKey(fgKey: .enableImageDownloadQueue, openInMailClient: true)) ? "true" : "false"
                    case "isNewMessageAtTop": return self.isNewMessageAtTopHandler()
                    case "lan": target = I18n.currentLanguageShortIdentifier()
                    case "screenWidth": target = "\(renderModel.pageWidth)"
                    case "screenHeight": target = "\(UIScreen.main.bounds.height)"
                    case "message_list":
                        shouldEncode = false
                        target = messageListHtml
                    case "share_tips_type": target = self.shareTipsTypeHandler(isFromChat: renderModel.isFromChat)
                    case "share_manage_button_text": target = BundleI18n.MailSDK.Mail_Share_ShareManageButton
                    case "share_check_button_text": target = BundleI18n.MailSDK.Mail_Share_CheckSharing
                    case "share_tips_wording": target = ""
                    case "myAddress": target = self.myAddressHandler()
                    case "translate_popover_title": return BundleI18n.MailSDK.Mail_Translations_OriginalText
                    case "translate_popover_subjectDetail": return BundleI18n.MailSDK.Mail_Cover_MobileSubjectDetails.replacingOccurrences(of: "'", with: "\\'").replacingOccurrences(of: "\"", with: "\\\"")
                    case "translate_popover_subjectDetail_original": return BundleI18n.MailSDK.Mail_Cover_MobileSubjectDetailsSourceText.replacingOccurrences(of: "'", with: "\\'").replacingOccurrences(of: "\"", with: "\\\"")
                    case "recommend-translate-button": return BundleI18n.MailSDK.Mail_Translations_Translate
                    case "thread-id": return renderModel.threadId
                    case "isPad": target = Display.pad ? "true" : ""
                    case "iOS-device": target = "iOS-device"
                    case "supportedSchemes": return MailCustomURLProtocolService.schemes.map({ $0.rawValue }).joined(separator: ",")
                    case "retryWording": target = BundleI18n.MailSDK.Email_RefreshPictureMobile_button
                    case "scaleOptimize": target = self.accountContext.featureManager.open(.scaleOptimize, openInMailClient: true) ? "true" : ""
                    case "scalePerformance": target = self.accountContext.featureManager.open(.scalePerformance, openInMailClient: true) ? "true" : ""
                    case "optimizeLargeMail": target = self.accountContext.featureManager.open(.optimizeLargeMail, openInMailClient: true) ? "true" : ""
                    case "longTextOptimize": target = self.accountContext.featureManager.open(.longTextOptimize, openInMailClient: true) ? "true" : ""
                    case "scaleMessageContent": target = ProviderManager.default.commonSettingProvider?.IntValue(key: "scaleMessageContent") == 1 ? "true" : ""
                    case "shouldLoadNativeRenderScript": target = "true"
                    case "isContentAlwaysLight": target = self.isContentAlwaysLightHandler()
                    case "darkModeFG": target = self.accountContext.featureManager.open(FeatureKey(fgKey: .darkMode, openInMailClient: true)) ? "true" : "false"
                    case "optimizeWebImageBlocking": target = self.accountContext.featureManager.open(.interceptWebImagePhase2, openInMailClient: true) ? "true" : ""
					case "interceptMessageIDs": return self.interceptMessageIDsHandler(renderModel: renderModel)
                    case "shouldInterceptImage": target = self.accountContext.featureManager.open(.interceptWebImage, openInMailClient: true) ? "true" : ""
                    case "spamMessageIDs": target = self.spamMessageIDsHandler(renderModel: renderModel)
                    case "fontWeightNormal": target = "font-weight: normal;"
                    case "fontNormalBase64": target = self.template.fontNormalBase64
                    case "fontWeightBold": target = "font-weight: bold;"
                    case "fontBoldBase64": target = self.template.fontBoldBase64
                    case "openProtectedMode": target = renderModel.openProtectedMode ? "true" : ""
                    #if IS_BYTEST_PACKAGE
                    case "extra_script":
                        MailLogger.info("MailCheckContent replace for extra_script")
                        shouldEncode = false
                        target = bytestCheckContentScript
                    #endif
                    default:
                        target = nil
                    }
                    return shouldEncode ? target?.htmlEncoded : target
                }
                MailMessageListTemplateRender.logger.debug("render template main finish ------> cost: \(self.timeCost(start)) ms")
                complete(bodyHtml)
            })
        }
    }

    func isContentAlwaysLightHandler() -> String {
        if self.accountContext.featureManager.open(FeatureKey(fgKey: .darkMode, openInMailClient: true)) {
            return self.isContentAlwaysLightMode() ? "true" : "false"
        } else {
            return "false"
        }
    }

    func myAddressHandler() -> String {
        if let address = Store.settingData.getCachedCurrentSetting()?.emailAlias.allAddresses.map({ $0.address }).joined(separator: ",") {
            return address
        } else {
            return self.accountContext.user.myMailAddress ?? ""
        }
    }

    func shareTipsTypeHandler(isFromChat: Bool) -> String {
        if isFromChat {
            return ""
        } else {
            return "unknown"
        }
    }

    func spamMessageIDsHandler(renderModel: MailMessageListRenderModel) -> String {
        if self.accountContext.featureManager.open(.interceptWebImage, openInMailClient: true) {
            if renderModel.atLabelId == Mail_LabelId_SEARCH_TRASH_AND_SPAM {
                return renderModel.messageLabels.filter({ $0.value == Mail_LabelId_Spam }).map({ $0.key }).joined(separator: ",")
            } else {
                return renderModel.atLabelId == Mail_LabelId_Spam ? renderModel.mailItem.messageItems.map { $0.message.id }.joined(separator: ",") : ""
            }
        } else {
            return ""
        }
    }

    func isNewMessageAtTopHandler() -> String {
        guard let mailAccount = Store.settingData.getCachedCurrentAccount() else {
            return ""
        }
        let latestAtTop = mailAccount.mailSetting.mobileMessageDisplayRankMode
        if latestAtTop {
            return "true"
        }else {
            return "false"
        }
    }

    func nativeTitleHeightHandler(strangerStyle: Bool, renderModel: MailMessageListRenderModel) -> String {
        if renderModel.atLabelId == Mail_LabelId_SEARCH_TRASH_AND_SPAM {
            if renderModel.messageLabels.values.filter({ $0 == Mail_LabelId_Spam }).count > 0 {
                return "\(renderModel.titleHeight)px"
            } else {
                return "0px"
            }
        } else if strangerStyle {
            return "0px"
        } else {
            return "\(renderModel.titleHeight)px"
        }
    }

    func headerTitleHandler(strangerStyle: Bool, isFeedCard: Bool, renderModel: MailMessageListRenderModel) -> String {
        if strangerStyle || isFeedCard {
            return ""
        } else {
            return self.replaceForHeaderTitle(mailItem: renderModel.mailItem,
                                              subject: renderModel.subject,
                                              isFromChat: renderModel.isFromChat,
                                              allLabels: renderModel.allLabels,
                                              isActionable: renderModel.isActionable,
                                              atLabelId: renderModel.atLabelId,
                                              nativeTitleHeight: renderModel.titleHeight,
                                              hasCover: renderModel.mailItem.mailSubjectCover() != nil)
        }
    }

    func interceptMessageIDsHandler(renderModel: MailMessageListRenderModel) -> String {
        if self.accountContext.featureManager.open(.interceptWebImagePhase2, openInMailClient: true) && self.accountContext.featureManager.open(.interceptWebImage, openInMailClient: true) {
            return renderModel.fetchAndUpdateCurrentInterceptedStateNew(
                renderModel:renderModel,
                messageItems: renderModel.mailItem.messageItems,
                userID: self.accountContext.user.userID,
                labelID: renderModel.atLabelId,
                dataManager: Store.settingData,
                store: self.accountContext.accountKVStore,
                from: renderModel.statFromType).joined(separator: ",")
        } else if self.accountContext.featureManager.open(.interceptWebImage, openInMailClient: true) {
            return MailInterceptWebImageHelper.filterInterceptedMessageIDs(
                messageItems: renderModel.mailItem.messageItems,
                userID: self.accountContext.user.userID,
                labelID: renderModel.atLabelId,
                dataManager: Store.settingData,
                store: self.accountContext.accountKVStore,
                from: renderModel.statFromType
            ).joined(separator: ",")
        } else {
            return ""
        }
    }

    func shouldReplaceRecallBanner(for mail: MailMessageItem, myUserId: String) -> Bool {
        let mailPending = mail.message.deliveryState == .pending
        let mailDelivered = mail.message.deliveryState == .delivered || mail.message.deliveryState == .sentToSelf
        let isRecalled = mail.message.deliveryState == .recall
        return MailRecallManager.shared.isRecallEnabled == true && mail.isFromMe && (mailDelivered || isRecalled || mailPending)
    }

    private func shouldReplaceScheduleBanner(for mail: MailMessageItem, myUserId: String) -> Bool {
        MailLogger.info("shouldReplaceScheduleBanner \(mail.message.id) scheduleSendTimestamp:\(mail.message.scheduleSendTimestamp)")
        return mail.message.scheduleSendTimestamp > 0
    }

    private func replaceForHeaderTitle(mailItem: MailItem,
                                       subject: String,
                                       isFromChat: Bool,
                                       allLabels: [MailClientLabel],
                                       isActionable: Bool,
                                       atLabelId: String,
                                       nativeTitleHeight: CGFloat,
                                       hasCover: Bool) -> String {
        if MailMessageListTemplateRender.enableNativeRender {
            return replaceFor(template: template.sectionNativeHeaderItem) { key in
                switch key {
                case "native-title-height":
                    return atLabelId == Mail_LabelId_Stranger && FeatureManager.open(.stranger, openInMailClient: false) ? "0px" : "\(nativeTitleHeight)px"
                default:
                    return nil
                }
            }
        } else {
            let templateString = hasCover ? template.sectionMessageCoverHeaderItem : template.sectionMessageHeaderItem
            return replaceFor(template: templateString) { key in
                var target: String?
                var shouldEncode = true
                switch key {
                case "subject":
                    target = subject.isEmpty ? BundleI18n.MailSDK.Mail_ThreadList_TitleEmpty : subject
                case "message-external-item":
                    target = mailItem.isExternal ? "message-external-item" : ""
                case "isforward":
                    target = isFromChat ? "isforward" : ""
                case "message_external":
                    target = mailItem.isExternal ? BundleI18n.MailSDK.Mail_SecurityWarning_External : ""
                case "message_labels":
                    shouldEncode = false
                    let targetStr = self.replaceForMessageLabels(allLabels, mailItem: mailItem, atLabelId: atLabelId)
                    target = self.filteredTemplateItem(templateStr: "message_labels",
                                                       targetStr: targetStr,
                                                       showActions: isActionable)
                case "mail_cover_token":
                    target = mailItem.mailSubjectCover()?.token ?? ""
                case "mail_cover_title_color":
                    target = mailItem.mailSubjectCover()?.subjectColorStr ?? ""
                case "cover_loading_wording":
                    target = BundleI18n.MailSDK.Mail_Cover_MobileLoading
                case "cover_loading_retry_wording":
                    target = BundleI18n.MailSDK.Mail_Cover_MobileLoadAgain
                default:
                    MailLogger.info("replaceheader key not handled: \(key)")
                }
                return shouldEncode ? target?.htmlEncoded : target
            }
        }
    }

    func replaceForBannerContainer(mail: MailMessageItem, myUserId: String, shouldReplaceRecall: Bool, atLabelID: String, fromChat: Bool, statFrom: MessageListStatInfo.FromType) -> String {
        let mailRecallState = MailRecallManager.shared.recallState(for: mail)
        let shouldReplaceSchedule = self.shouldReplaceScheduleBanner(for: mail, myUserId: myUserId)
        let displayRecallBanner = shouldReplaceRecall && mailRecallState != .none
        let displaySafeTipsBanner = mail.showSafeTipsBanner
        let displaySafeTipsNewBanner = mail.showSafeTipsNewBanner
        var displaySendStatusBanner = false
        if let setting = Store.settingData.getCachedCurrentSetting(),
           setting.userType == .larkServer &&
            accountContext.featureManager.open(.sendStatus) {
            displaySendStatusBanner = (mail.message.sendState != .unknownSendState || mail.message.deliveryState == .pending) && !displayRecallBanner
        }
        let priorityType = mail.message.systemLabels.toMailPriorityType()
        let displayPriorityBanner = accountContext.featureManager.open(.mailPriority, openInMailClient: false) && (priorityType == .high || priorityType == .low)
        let needReadReceipt = mail.message.systemLabels.contains(Mail_LabelId_ReadReceiptRequest) && atLabelID != Mail_LabelId_Spam
        let displayReadReceiptBanner = accountContext.featureManager.open(.readReceipt, openInMailClient: false) && needReadReceipt
        return replaceFor(template: template.sectionBannerContainer) { (keyword) -> String? in
            var target: String?
            switch keyword {
            case "banner-display-none":
                let hasBanner = displayRecallBanner || displaySafeTipsBanner || shouldReplaceSchedule || displaySendStatusBanner || displayPriorityBanner || displayReadReceiptBanner
                return hasBanner ? "" : "display-none"
            case "safe_tips_banner":
                target = self.replaceForSafetyTipsBanner(mail: mail, atLabelID: atLabelID, displaySafeTipsBanner: displaySafeTipsBanner, displaySafeTipsNewBanner: displaySafeTipsNewBanner, fromChat: fromChat)
            case "recall_message_banner":
                if shouldReplaceRecall {
                    target = self.replaceForRecallMessageBanner(state: mailRecallState, displayBanner: displayRecallBanner)
                } else {
                    target = ""
                }
            case "schedule_message_banner":
                if shouldReplaceSchedule {
                    let scheduleSendTimestamp = mail.message.scheduleSendTimestamp / 1000
                    target = self.replaceForScheduleMessageBanner(scheduleSendTimestamp: scheduleSendTimestamp)
                    MailLogger.info("mail message list show schedule timestamp \(scheduleSendTimestamp) msgId: \(mail.message.id)")
                } else {
                    target = ""
                }
            case "translating_hint":
                target = BundleI18n.MailSDK.Mail_Translations_Translatingthismessage.htmlEncoded
            case "translation-view-translation-button":
                target = BundleI18n.MailSDK.Mail_Translations_Viewtranslation.htmlEncoded
            case "translate-view-original-button-text":
                target = BundleI18n.MailSDK.Mail_Translations_Vieworiginal.htmlEncoded
            case "send_status_banner":
                if accountContext.featureManager.open(.sendStatus) {
                    target = self.replaceForSendStatusBanner(mail, needShow: displaySendStatusBanner)
                } else {
                    target = ""
                }
            case "priority_banner":
                if accountContext.featureManager.open(.mailPriority, openInMailClient: false) {
                    target = self.replaceForPriorityBanner(priorityType: priorityType)
                } else {
                    target = ""
                }
            case "intercept_tips_banner":
                if accountContext.featureManager.open(.interceptWebImage, openInMailClient: true) {
                    target = replaceForInterceptTipsBanner(statFrom: statFrom, hasSafetyBanner: mail.showSafeTipsBanner)
                } else {
                    target = ""
                }
            case "read_receipt_request_banner":
                if displayReadReceiptBanner {
                    target = replaceForReadReceiptTipsBanner(messageId: mail.message.id)
                    MailTracker.log(event: "email_read_receipt_banner_view",
                                    params: ["is_stranger": atLabelID == Mail_LabelId_Stranger ? "True" : "False",
                                             "label_item": atLabelID,
                                             "mail_account_type": Store.settingData.getMailAccountType()])
                } else {
                    target = ""
                }
            default: break
            }
            return target
        }
    }

    func replaceForItemContent(messageItem: MailMessageItem,
                               myUserId: String,
                               replaceRecall: Bool,
                               mailRecallState: MailRecallState,
                               atLabelID: String,
                               fromChat: Bool,
                               shouldForceDisplayBcc: Bool = false,
                               isFeedCard: Bool) -> String {
        let isContentLightAlways = isContentAlwaysLightMode()
        var shouldBeDarkMode = false
        if #available(iOS 13.0, *),
           accountContext.featureManager.open(FeatureKey(fgKey: .darkMode, openInMailClient: true)),
           !isContentLightAlways,
            UDThemeManager.getRealUserInterfaceStyle() == .dark {
            shouldBeDarkMode = true
        }
        return replaceFor(template: template.sectionItemContent) { (keyword) -> String? in
            var shouldEncode = true
            var target: String?
            let mailItem: MailItem? = nil
            let componetTarget = self.replaceComponentManager.setCurrentState(.replaceTemplate, params: (keyword, mailItem, messageItem)) as? String
            switch keyword {
            case "message-action-bar-container":
                shouldEncode = false
                target = isFeedCard && messageItem.message.deliveryState != .scheduled ? self.replaceForMessageActionBar() : ""
            case "attachment":
                shouldEncode = false
                target = self.replaceForAttachments(attachments: messageItem.message.attachments, msgId: messageItem.message.id, isFromChat: fromChat, isAtTop: false)
            case "top-attachment":
                shouldEncode = false
                target = self.replaceForAttachments(attachments: messageItem.message.attachments, msgId: messageItem.message.id, isFromChat: fromChat, isAtTop: true)
            case "content-container":
                shouldEncode = false
                let getMsgContent = {
                    return self.replaceForMessageContent(messageItem: messageItem, isDarkMode: shouldBeDarkMode)
                }
                if accountContext.featureManager.open(.scaleOptimize, openInMailClient: true) {
                    // 适配优化，需要将 messageContent 包在容器内
                    target = replaceFor(template: template.contentContainer) { (keyword) -> String? in
                        switch keyword {
                        case "container-content":
                            return getMsgContent()
                        case "invisible_for_dark":
                            return shouldBeDarkMode ? "invisible-for-dark" : ""
                        case "security_content_container":
                            return accountContext.featureManager.open(.isolateOverflowContent, openInMailClient: true) ? "security-content-container" : ""
                        case "scale_word_break": return self.accountContext.featureManager.open(.longTextOptimize, openInMailClient: true) ? "scale-word-break" : ""
                        default:
                            return nil
                        }
                    }
                } else {
                    target = getMsgContent()
                }
            case "contentAppearance":
                target = shouldBeDarkMode ? "dark" : "light"
            case "feed_card":
                target = isFeedCard ? "feed_card" : ""
            case "button_readmore":
                target = BundleI18n.MailSDK.Mail_Message_ReadMore
            case "is_body_clipped":
                target = messageItem.message.isBodyClipped ? "is_body_clipped" : ""
            case "body_clipped_max_width":
                target = Display.pad ? "body_clipped_max_width" : ""
            case "feed_card_schedule":
                // TODO: @chenyangfan 判断定时发送 done
                return isFeedCard && messageItem.message.deliveryState == .scheduled ? "feed_card_schedule" : ""
            default:
                target = nil
            }
            target = shouldEncode ? target?.htmlEncoded : target
            if let temp = componetTarget {
                if target == nil {
                    target = temp
                } else {
                    target?.append(temp)
                }
            }
            return target
        }
    }

    func replaceForMessageContent(messageItem: MailMessageItem, isDarkMode: Bool) -> String {
        return replaceFor(template: template.messageInnerContent) { (keyword) -> String? in
            switch keyword {
                case "invisible_for_dark":
                    //没有设置成始终为light，并且当前是darkmode，此时要走反色算法
                    return isDarkMode ? "invisible-for-dark" : ""
                case "message_content":
                    var target = messageItem.message.isBodyClipped ? "<!--" : ""
                    target.append(messageItem.message.bodyHtml)
                    if messageItem.message.isBodyClipped {
                        target.append("-->")
                    }
                    return target
                case "security_content_container":
                    return accountContext.featureManager.open(.isolateOverflowContent, openInMailClient: true) ? "security-content-container" : ""
                case "scale_word_break": return self.accountContext.featureManager.open(.longTextOptimize, openInMailClient: true) ? "scale-word-break" : ""
                default:
                    return nil
            }
        }
    }

    // nolint: long_function, cyclomatic complexity -- 包含一个较长的 switch case，不影响代码可读性
    func replaceForMessageList(by renderModel: MailMessageListRenderModel, isUpdate: Bool, complete: @escaping (String) -> Void) {
        let mailItem = renderModel.mailItem
        let myUserId = renderModel.myUserId
        let messagelistSection = template.sectionMessageListItem
        let messageItemDivider = template.sectionMessageItemDivider
        let contextMenuSection = template.sectionContextMenu
        let shouldForceDisplayBcc = mailItem.shouldForceDisplayBcc

        var stepStart = CACurrentMediaTime()
        MailMessageListTemplateRender.logger.debug("&&Template: getting keyword range backward finish -----> cost: \(timeCost(stepStart)) ms")

        let templateReplaceStart = CACurrentMediaTime()
        let messageItems = ThreadSafeDataStructure.SafeArray<String>([String](repeating: "", count: renderModel.mailItem.messageItems.count), synchronization: .readWriteLock)
        let notifyQueue = DispatchQueue.global(qos: .userInitiated)
        let queueGroup = DispatchGroup()
        let unreadPreloadOpt = FeatureManager.open(.unreadPreloadMailOpt, openInMailClient: true)
        let semaphore = DispatchSemaphore(value: 0)
        //默认为底部
        var latestAtBottom = false
        if let mailAccount = Store.settingData.getCachedCurrentAccount(){
        //mobileMessageDisplayRankMode为false表示最新邮件展示在底部
            latestAtBottom = !mailAccount.mailSetting.mobileMessageDisplayRankMode
            if !mailAccount.mailSetting.enableConversationMode && renderModel.atLabelId == Mail_LabelId_Stranger {
                latestAtBottom = false
            }
        }
        var isExistUnread = false
        var unreadIndex = -1
        for i in 0..<mailItem.messageItems.count {
            let messageQueue = DispatchQueue(label: "MailMessageListTemplateRender.MessageItem\(i)", qos: .userInitiated, attributes: .concurrent)
            queueGroup.enter()
            messageQueue.async(group: queueGroup, qos: .userInitiated) { [weak self] in
                guard let self = self else { return }
                let itemStart = CACurrentMediaTime()
                let mail = mailItem.messageItems[i]
                var feedIsExternal = false
                if let messageItem = mailItem.feedMessageItems[safe: i] {
                    feedIsExternal = messageItem.isExternal
                }
                let shouldReplaceRecall = self.shouldReplaceRecallBanner(for: mail, myUserId: myUserId)
                let mailRecallState = MailRecallManager.shared.recallState(for: mail)
                let foldNameList = self.replaceForToNames(mail: mail, shouldForceDisplayBcc: shouldForceDisplayBcc)
                let strangerStyle = self.accountContext.featureManager.open(.stranger) && renderModel.atLabelId == Mail_LabelId_Stranger
                let isShare = Store.settingData.getCachedCurrentAccount()?.isShared ?? true
                let isFeedCard = !renderModel.mailItem.feedCardId.isEmpty && self.accountContext.featureManager.open(FeatureKey(fgKey: .mailToFeed, openInMailClient: false))
                if !mail.message.isRead && !isExistUnread {//记录第一封未读的位置
                    isExistUnread = true
                    unreadIndex = i
                }
                // 展开邮件：1.最后一封 2.未读message 3.sendToChat默认展开 4.Bot读信 *feed场景不要这个 5. 陌生人读信也默认展开
                let isExpand = (!isUpdate && i == mailItem.messageItems.count - 1) || !mail.message.isRead || renderModel.isFromChat || renderModel.locateMessageId == mail.message.id || renderModel.atLabelId == Mail_LabelId_Stranger
                // 是否是重要联系人
                var canShowImportant = false
                var noMoreShowImportant = false
                var closeRecommendList: [String] = []
                if let tempNoMoreShowImportant : Bool = self.accountContext.accountKVStore.value(forKey: "MailFeedList.stopRecommend") {
                    noMoreShowImportant = tempNoMoreShowImportant
                }
                if let tempCloseRecommendList : [String] = self.accountContext.accountKVStore.value(forKey: "MailFeedList.closeRecommend") {
                    closeRecommendList = tempCloseRecommendList
                }
                var isValid = true
                // account is not vaild, dismiss the account detail setting page
                if let currentAccountValue = Store.settingData.currentAccount.value,
                    currentAccountValue.isValid() == false ||
                    currentAccountValue.isUnuse() == true {
                    isValid = false
                }
                canShowImportant = self.accountContext.featureManager.open(FeatureKey(fgKey: .mailToFeed, openInMailClient: false))
                    && !noMoreShowImportant
                    && renderModel.mailItem.feedCardId.isEmpty
                    && !closeRecommendList.contains(mail.message.from.address)
                    && isValid
                    && !isShare
                    && !strangerStyle
                MailMessageListTemplateRender.logger.debug("[mail_feed_isImportant] canShowImportant : \(canShowImportant), name:\(mail.message.from.mailDisplayNameNoMe)")
                // feed展开逻辑
                var feedIsExpand = false
                if isFeedCard && MailModelManager.shared.getGloballyEnterChatPosition() == 1 {
                    if let visibleListSet: [String : Data] = self.accountContext.accountKVStore.value(forKey: "MailFeedList.visualListData"),
                       let visibleListData: Data = visibleListSet[renderModel.mailItem.feedCardId],
                       let visibleList = try? JSONSerialization.jsonObject(with: visibleListData, options: []) as? [[String: Any]],
                       let visibleItem = visibleList.first(where: { item in
                           if let messageId = item["messageId"] as? String {
                               return messageId == mail.message.id
                           }
                           return false
                       }),
                       let lastIsExpand = visibleItem["isExpand"] as? Bool {
                        feedIsExpand = lastIsExpand || !mail.message.isRead || (!isUpdate && mailItem.messageItems.count == 1) || (isUpdate && renderModel.isPushNewMessage)
                    } else {
                        feedIsExpand = !mail.message.isRead || (!isUpdate && mailItem.messageItems.count == 1) || (isUpdate && renderModel.isPushNewMessage)
                        MailMessageListTemplateRender.logger.debug("test feedIsExpand : \(!mail.message.isRead), \(i)")
                    }
                } else {
                    feedIsExpand = isExpand || (isUpdate && renderModel.isPushNewMessage)// 新邮件update需要展开
                }
                let messageList = self.replaceFor(template: messagelistSection) { (keyword) -> String? in
                    var target: String?
                    var shouldEncode = true
                    let componetTarget = self.replaceComponentManager.setCurrentState(.replaceTemplate, params: (keyword, mailItem, mail)) as? String
                    switch keyword {
                    case "delegate_info":
                        if renderModel.shouldShowDelegationInfo(for: mail, accountContext: self.accountContext) {
                            var delegateName = ""
                            delegateName = mail.message.senderDelegation.displayName.htmlEncoded
                            if delegateName.isEmpty {
                                delegateName = mail.message.senderDelegation.name.htmlEncoded
                            }
                            let leftText = BundleI18n.MailSDK.Mail_SentByNameAddress_Part1_Text
                            let rightText = BundleI18n.MailSDK.Mail_SentByNameAddress_Part2_Text
                            target = leftText + delegateName + rightText
                        } else {
                            target = ""
                        }
                    case "delegation_hide":
                        if renderModel.shouldShowDelegationInfo(for: mail, accountContext: self.accountContext)  {
                            target = ""
                        } else {
                            target = "delegation_hide"
                        }
                    case "timestamp":
                        return "\(mail.message.createdTimestamp)"
                    case "centerFrom":
                        target = foldNameList.isEmpty ? "centerFrom" : ""
                    case "item-content":
                        shouldEncode = false
                        if !renderModel.lazyLoadMessage || isExpand || strangerStyle || feedIsExpand {
                            target = self.replaceForItemContent(messageItem: mail,
                                                                myUserId: myUserId,
                                                                replaceRecall: shouldReplaceRecall,
                                                                mailRecallState: mailRecallState,
                                                                atLabelID: renderModel.atLabelId,
                                                                fromChat: renderModel.isFromChat,
                                                                shouldForceDisplayBcc: shouldForceDisplayBcc,
                                                                isFeedCard: isFeedCard)
                        } else {
                            target = ""
                        }
                    case "message-draft-container":
                        shouldEncode = false
                        if let mailAccount = self.accountContext.mailAccount {
                            target = isFeedCard ? self.replaceForMessageDraftContainer(messageItem: mail, mailAccount: mailAccount) : ""
                        } else {
                            target = ""
                        }
                    case "important-contact-banner":
                        shouldEncode = false
                        // TODO: @chenyangfan 判断重要联系人场景 done
                        target = canShowImportant ? self.replaceForImportantContactBanner(importantContactName: mail.message.from.mailDisplayNameNoMe) : ""
                    case "message_id":
                        target = mail.message.id
                    case "message_locate":
                        // 定位代码
                        if isFeedCard && MailModelManager.shared.getGloballyEnterChatPosition() == 1 && renderModel.fromNotice == false,
                           let lastMessageIdSet: [String: String] = self.accountContext.accountKVStore.value(forKey: "MailFeedList.lastMessageId"),
                           let lastMessageId = lastMessageIdSet[renderModel.mailItem.feedCardId] {
                            target = mail.message.id == lastMessageId ? "locate" : ""
                        } else if isFeedCard && (MailModelManager.shared.getGloballyEnterChatPosition() == 2 || renderModel.fromNotice == true) {
                            if let newleastMessageId = mailItem.messageItems.max(by: {$0.message.createdTimestamp < $1.message.createdTimestamp})?.message.id {
                                target = mail.message.id == newleastMessageId ? "locate" : ""
                            }
                        } else {
                            target = mail.message.id == renderModel.locateMessageId ? "locate" : ""
                        }
                    case "message_expand":
                        if isFeedCard && MailModelManager.shared.getGloballyEnterChatPosition() == 1 { // feed & 定位到上次位置
                            target = feedIsExpand ? "expand" : ""
                        } else if isFeedCard { // feed & 定位到最新
                            target = feedIsExpand ? "expand" : ""
                        } else {
                            target = isExpand ? "expand" : ""
                        }
                    case "is_read":
                        target = mail.message.isRead ? "true" : "false"
                    case "from_name":
                        target = mail.message.from.mailDisplayNameNoMe
                    case "subject":
                        target = mail.message.subject.isEmpty ? BundleI18n.MailSDK.Mail_ThreadList_TitleEmpty : mail.message.subject
                    case "address_address":
                        target = mail.message.from.address.htmlEncoded
                    case "user_type":
                        target = String(mail.message.from.larkEntityType.rawValue)
                    case "tenant_id":
                        target = mail.message.from.tenantID
                    case "user_id":
                        target = mail.message.from.larkEntityIDString
                    case "fold_recipients_list":
                        shouldEncode = false
                        if !foldNameList.isEmpty {
                            target = self.relaceForNameListAndFromAddress(
                                nameList: foldNameList,
                                fromAddress: mail.message.from.address,
                                isSeparateSend: mail.message.isSendSeparately
                                && self.accountContext.featureManager.open(.sendSeparaly))
                        } else {
                            target = ""
                        }
                    case "context-menu":
                        shouldEncode = false
                        if mailItem.shouldHideContextMenu {
                            return ""
                        }
                        let menuItemsCount = renderModel.contextMenuItemsCount[mail.message.id] ?? 0
                        if menuItemsCount > 0 {
                            return contextMenuSection
                        } else {
                            return ""
                        }
                    case "message_list_avatar":
                        shouldEncode = false
                        let securityInfo = mail.message.security
                        let from = mail.message.from
                        if MailMessageListTemplateRender.enableNativeRender && renderModel.atLabelId != Mail_LabelId_Stranger {
                            let name = from.mailDisplayNameNoMe
                            target = self.replaceForFromNativeAvatar(userid: from.larkEntityIDString,
                                                                     name: name,
                                                                     address: from.address,
                                                                     userType: from.larkEntityType,
                                                                     tenantId: from.tenantID,
                                                                     avatar: renderModel.avatar,
                                                                     isFeedCard: isFeedCard,
                                                                     isMe: from.isMe)
                        } else {
                            target = self.replaceForFromAvatar(userid: from.larkEntityIDString, userType: from.larkEntityType)
                        }
                    case "follow_type":
                        let maiToFeedFG = self.accountContext.featureManager.open(FeatureKey(fgKey: .mailToFeed, openInMailClient: false))
                        var isValid = true
                        // account is not vaild, dismiss the account detail setting page
                        if let currentAccountValue = Store.settingData.currentAccount.value,
                            currentAccountValue.isValid() == false ||
                            currentAccountValue.isUnuse() == true {
                            isValid = false
                        }
                        if isFeedCard || !maiToFeedFG || strangerStyle || isShare || !isValid { // Feed卡片每个读信不展示关注入口
                            target = ""
                        } else if mail.message.from.isExternalUser && mail.message.from.followStatus == .followed && !isShare && maiToFeedFG {
                            target = "follow" // 展示关注
                        } else if mail.message.from.isExternalUser && mail.message.from.followStatus == .unfollowed && !isShare && maiToFeedFG {
                            target = "unfollow" // 展示未关注
                        }
                    case "reply_tag_type":
                        if FeatureManager.open(.repliedMark, openInMailClient: true) {
                            switch mail.message.displayReplyType {
                            case .reply:
                                target = "reply"
                            case .forward:
                                target = "forward"
                            @unknown default:
                                target = ""
                            }
                        } else {
                            target = ""
                        }
                    case "attachment_tag":
                        shouldEncode = false
                        target = self.replaceForAttachmentTag(mail: mail)
                    case "priority_tag":
                        shouldEncode = false
                        if self.accountContext.featureManager.open(.mailPriority, openInMailClient: false) {
                            target = self.replaceForPriorityTag(mail: mail)
                        } else {
                            target = ""
                        }
                    case "body_plaint":
                        target = mail.message.bodySummary
                    case "lan":
                        target = I18n.currentLanguageShortIdentifier()
                    case "format_message_time":
                        var timeString: String?
                        self.serialQueue.sync {
                            timeString = ProviderManager.default.timeFormatProvider?.relativeDate(mail.message.createdTimestamp / 1000, showTime: true)
                        }
                        target = timeString
                    case "recall_tag":
                        shouldEncode = false
                        if shouldReplaceRecall {
                            target = self.replaceForRecallTag(display: mailRecallState != .none)
                        } else {
                            target = ""
                        }
                    case "redirect_banner":
                        if renderModel.isFromChat {
                            return ""
                        } else {
                            return self.replaceForRedirectBanner(mail)
                        }
                    case "address_from_list":
                        shouldEncode = false
                        target = self.replaceForFromAddressListItem(mail: mail, by: renderModel, isSeparateSend: self.accountContext.featureManager.open(.sendSeparaly) && mail.message.isSendSeparately)
                    case "address_to_list":
                        if self.accountContext.featureManager.open(.sendSeparaly), mail.message.isSendSeparately {
                            return ""
                        } else {
                            shouldEncode = false
                            target = self.replaceForToAddressListItem(mail: mail)
                        }
                    case "address_cc_list":
                        if self.accountContext.featureManager.open(.sendSeparaly), mail.message.isSendSeparately {
                            return ""
                        } else {
                            shouldEncode = false
                            target = self.replaceForCCAddressListItem(mail: mail)
                        }
                    case "address_bcc_list":
                        if self.accountContext.featureManager.open(.sendSeparaly), mail.message.isSendSeparately {
                            return ""
                        } else {
                            shouldEncode = false
                            target = self.replaceForBCCAddressListItem(mail: mail, isSeparateSend: false, shouldForceDisplayBcc: shouldForceDisplayBcc)
                        }
                    case "address_separately_list":
                        guard mail.message.isSendSeparately, self.accountContext.featureManager.open(.sendSeparaly) else {
                            return ""
                        }
                        shouldEncode = false
                        target = self.replaceForBCCAddressListItem(mail: mail, isSeparateSend: true, shouldForceDisplayBcc: shouldForceDisplayBcc)
                    case "banner_container":
                        shouldEncode = false
                        target = self.replaceForBannerContainer(mail: mail, myUserId: myUserId, shouldReplaceRecall: shouldReplaceRecall, atLabelID: renderModel.atLabelId, fromChat: renderModel.isFromChat, statFrom: renderModel.statFromType)
                    case "stranger_card":
                        return strangerStyle ? "stranger_card" : ""
                    case "feed_card":
                        return isFeedCard  ? "feed_card" : ""
                    case "isforward":
                        target = renderModel.isFromChat ? "isforward" : ""
                    case "message-external-item":
                        if isFeedCard {
                            target = feedIsExternal && !mailItem.feedMessageItems.isEmpty ? "message-external-item" : ""
                        } else {
                            target = mailItem.isExternal ? "message-external-item" : ""
                        }
                    case "message_external":
                        if isFeedCard {
                            target = feedIsExternal && !mailItem.feedMessageItems.isEmpty ? BundleI18n.MailSDK.Mail_SecurityWarning_External : ""
                        } else {
                            target = mailItem.isExternal ? BundleI18n.MailSDK.Mail_SecurityWarning_External : ""
                        }
                    case "message_labels":
                        shouldEncode = false
                        var labelIds = [MailClientLabel]()
                        if (!mailItem.feedMessageItems.isEmpty && isFeedCard) {
                            let labelIdsStr = mailItem.feedMessageItems[i].labelIds
                            labelIds = MailTagDataManager.shared.getTagModels(labelIdsStr)
                            let atLabelId = mailItem.feedMessageItems[i].labelIds.first ?? ""
                            let targetStr = self.replaceForMessageLabels(labelIds, mailItem: mailItem, atLabelId: atLabelId)
                            target = self.filteredTemplateItem(templateStr: "message_labels",
                                                               targetStr: targetStr,
                                                               showActions: renderModel.isActionable)
                        }
                    default:
                        target = nil
                    }

                    target = shouldEncode ? target?.htmlEncoded : target
                    if let temp = componetTarget {
                        target?.append(temp)
                    }
                    return target
                }

                var draftItem = ""
                if let draft = mail.drafts.first, !isFeedCard {
                    stepStart = CACurrentMediaTime()
                    draftItem = self.replaceFor(template: self.template.sectionDraftItem, patternHandler: { (keyword) -> String? in
                        var target: String?
                        var shouldEncode = true
                        switch keyword {
                        case "message_id":
                            target = mail.message.id
                        case "thread_id":
                            target = mailItem.threadId
                        case "show_draft_attachment_icon":
                            if draft.attachments.count <= 0 {
                                target = "hide"
                            } else {
                                target = ""
                            }
                        case "draft_id":
                            target = draft.id
                        case "from_name":
                            target = draft.from.mailDisplayName
                        case "from_address":
                            target = draft.from.address
                        case "user_type":
                            target = String(draft.from.larkEntityType.rawValue)
                        case "tenant_id":
                            target = draft.from.tenantID
                        case "user_id":
                            target = myUserId
                        case "message_list_avatar":
                            shouldEncode = false
                            let from = draft.from
                            if MailMessageListTemplateRender.enableNativeRender && renderModel.atLabelId != Mail_LabelId_Stranger {
                                let name = from.mailDisplayNameNoMe
                                target = self.replaceForFromNativeAvatar(userid: from.larkEntityIDString,
                                                                         name: name,
                                                                         address: from.address,
                                                                         userType: from.larkEntityType,
                                                                         tenantId: from.tenantID,
                                                                         isFeedCard: isFeedCard,
                                                                         isMe: from.isMe)
                            } else {
                                target = self.replaceForFromAvatar(userid: from.larkEntityIDString, userType: from.larkEntityType)
                            }
                        case "body_plaint":
                            target = draft.bodySummary
                        case "draft_title":
                            target = BundleI18n.MailSDK.Mail_Normal_Draft
                        case "show_draft_delete_icon":
                            target = ""
//                            target = (isShareMail && !isShareOwner) ? "hide" : ""
                        case "stranger_card":
                            return strangerStyle ? "stranger_card" : ""
                        case "feed_card":
                            return isFeedCard ? "feed_card" : ""
                        default:
                            target = nil
                        }
                        return shouldEncode ? target?.htmlEncoded : target
                    })
                    MailMessageListTemplateRender.logger.debug("&&Template: render template message list - item - draft cost: \(self.timeCost(stepStart)) ms")
                }
                if latestAtBottom { //会话模式下的草稿也需要根据设置放置于回复邮件的上 或 下
                    messageItems[i] = messageList + draftItem
                } else {
                    messageItems[i] = draftItem + messageList
                }
                MailMessageListTemplateRender.logger.debug("&&Template: render template message list - item - item#\(i) cost: \(self.timeCost(itemStart)) ms")
                queueGroup.leave()
                semaphore.signal()
            }
        }

        if unreadPreloadOpt {
            for _ in 0..<mailItem.messageItems.count {
                semaphore.wait()
            }
            complete(self.processResult(mailItem: mailItem, messageItems: messageItems, isUpdate: isUpdate,
                                        unreadIndex: unreadIndex, latestAtBottom: latestAtBottom,
                                        messageItemDivider: messageItemDivider, templateReplaceStart: templateReplaceStart))
        } else {
            queueGroup.notify(queue: notifyQueue) { [weak self] in
                guard let `self` = self else { return }
                complete(self.processResult(mailItem: mailItem, messageItems: messageItems, isUpdate: isUpdate,
                                            unreadIndex: unreadIndex, latestAtBottom: latestAtBottom,
                                            messageItemDivider: messageItemDivider, templateReplaceStart: templateReplaceStart))
            }
        }
    }

    private func processResult(mailItem: MailItem, messageItems: ThreadSafeDataStructure.SafeArray<String>,
                               isUpdate: Bool, unreadIndex: Int, latestAtBottom: Bool,
                               messageItemDivider: String,  templateReplaceStart: CFTimeInterval) -> String {
        var dividerItem = ""
        // 初始化会话 MesaageList 带分割线，会话中实时更新插入新的邮件 item 不带分割线
        // 所有邮件均已读 unreadIndex == -1，分割线隐藏，但需带到模板上（后续新邮件进来可以显示）
        // 所有邮件均未读 unreadIndex == 0，不带分割线（后续新邮件进来也不显示）
        if !isUpdate, unreadIndex != 0 {
            let unreadCount = mailItem.messageItems.count - unreadIndex
            let dividerText = latestAtBottom ? BundleI18n.MailSDK.Mail_BelowNewEmails_Text(unreadCount) : BundleI18n.MailSDK.Mail_AboveNewEmails_Text(unreadCount)
            dividerItem = self.replaceFor(template: messageItemDivider){ (keyword) -> String? in
                var target: String?
                switch keyword {
                case "hide":
                    target = unreadIndex > 0 ? "" : "hide"
                case "singular_text":
                    target = latestAtBottom ? BundleI18n.MailSDK.Mail_BelowNewEmails_Text(1) : BundleI18n.MailSDK.Mail_AboveNewEmails_Text(1)
                case "plural_text":
                    target = latestAtBottom ? BundleI18n.MailSDK.Mail_BelowNewEmails_Text(2) : BundleI18n.MailSDK.Mail_AboveNewEmails_Text(2)
                case "message_item_divider_text":
                    target = unreadIndex > 0 ? dividerText : ""
                default:
                    target = nil
                }
                return target
            }
        }
        MailMessageListTemplateRender.logger.debug("&&Template: replacing template finish -----> cost: \(self.timeCost(templateReplaceStart)) ms")
        var count = 0
        var result = messageItems.reduce("") {(res, message) -> String in
            count += 1
            if latestAtBottom {
                if (count - 1) == unreadIndex {
                    return res + dividerItem + message
                } else {
                    return res + message
                }
            } else {
                if (count - 1) == unreadIndex {
                    return message + dividerItem + res
                } else {
                    return message + res
                }
            }
        }
        // 所有邮件都是已读时，在最后加上分割线
        if unreadIndex == -1 {
            if latestAtBottom {
                result = result + dividerItem
            } else {
                result = dividerItem + result
            }
        }
        return result
    }

    private func replaceForRedirectBanner(_ messageItem: MailMessageItem) -> String {
        var info: String?
        switch messageItem.message.redirectType {
        case .noneRedirect:
            return ""
        case .to:
            info = BundleI18n.MailSDK.Mail_DataProtection_SendRedirectedDesc
        case .cc:
            info = BundleI18n.MailSDK.Mail_DataProtection_CCToYouDesc
        case .bcc:
            info = BundleI18n.MailSDK.Mail_DataProtection_SendBCCToYouDesc
        @unknown default:
            return ""
        }
        return replaceFor(template: template.sectionRedirectBanner) { key in
            switch key {
            case "redirect-title":
                return BundleI18n.MailSDK.Mail_DataProtection_SendRedirected
            case "redirect-info":
                return info ?? BundleI18n.MailSDK.Mail_DataProtection_SendRedirectedDesc
            default:
                return nil
            }
        }
    }

    func replaceForSendStatusBanner(_ messageItem: MailMessageItem, needShow: Bool) -> String {
        var hideArrow = false
        if !MailMessageListController.checkSendStatusDurationValid(
            timestamp: TimeInterval(messageItem.message.createdTimestamp / 1000)) {
            hideArrow = true
        } else if messageItem.message.deliveryState == .pending {
            hideArrow = true
        }
        return replaceFor(template: template.sectionSendStatusBanner) { key in
            let sendStatus = messageItem.message.sendState
            switch key {
            case "showSuccess":
                return sendStatus == .allSuccess ? "showSuccess" : ""
            case "showFail":
                return  sendStatus == .allFail ? "showFail" : ""
            case "showPartFail":
                return  sendStatus == .partialFail ? "showPartFail" : ""
            case "showRefresh":
                return sendStatus == .delivering ||
                    sendStatus == .partialSuccess ||
                    messageItem.message.deliveryState == .pending ? "showRefresh" : ""
            case "sendStatusText":
                if messageItem.message.deliveryState == .pending {
                    return BundleI18n.MailSDK.Mail_Send_Sending
                }
                switch sendStatus {
                case .allFail:
                    return BundleI18n.MailSDK.Mail_Send_FailedToSend
                case .allSuccess:
                    return BundleI18n.MailSDK.Mail_Send_SendSuccess
                case .delivering:
                    return BundleI18n.MailSDK.Mail_Send_Sending
                case .partialFail:
                    return BundleI18n.MailSDK.Mail_Send_PartFailedToSend
                case .partialSuccess:
                    return BundleI18n.MailSDK.Mail_Send_SendingPartSuccess
                case .unknownSendState:
                    fallthrough
                @unknown default:
                    return ""
                }
            case "hideArrow":
                return hideArrow ? "hideArrow" : ""
            case "showSendStatusBanner":
                return needShow ? "showSendStatusBanner" : ""
            default:
                return nil
            }
        }
    }

    private func replaceForMessageLabels(_ allLabels: [MailClientLabel], mailItem: MailItem, atLabelId: String) -> String {
        var messageLabels = ""
        let filterLabels = MailMessageListLabelsFilter.filterLabels(allLabels,
                                                                    atLabelId: atLabelId,
                                                                    permission: mailItem.code,
                                                                    useCssColor: true)
        for label in filterLabels {
            /// 邮件协作fg关闭时，不显示 share label
            if label.id == Mail_LabelId_UNREAD || label.id == Mail_LabelId_Unknow {
                continue
            }
            messageLabels = messageLabels + createMessageLabelItem(label.displayLongName,
                                                                   dirLTR: label.parentID.isEmpty,
                                                                   fontColor: label.displayFontColor,
                                                                   bgColor: label.displayBgColor,
                                                                   isGoogle: label.labelModelMailClientType == .googleMail)
        }
        return messageLabels
    }

    private func replaceForFromAvatar(userid: String, userType: Email_Client_V1_Address.LarkEntityType) -> String {
        // 邮件组不展示个人头像，不传LarkID
        let userid = userType.isGroupOrEnterpriseMailGroup ? "" : userid
        let avatarpath = MailModelManager.shared.getAvatar(userid: userid)
        if avatarpath.isEmpty {
            return ""
        } else if !AbsPath(avatarpath).exists {
            MailModelManager.shared.removeAvatar(userid: userid)
            return ""
        } else {
            return replaceFor(template: template.sectionMessageListAvatar, patternHandler: { (keyword) -> String? in
                switch keyword {
                case "avatar_url":
                    return avatarpath.htmlEncoded
                default:
                    return ""
                }
            })
        }
    }

    func relaceForNameListAndFromAddress(nameList: String, fromAddress: String, isSeparateSend: Bool) -> String {
        return replaceFor(template: template.sectionFoldRecipientsList, patternHandler: { (keyword) -> String? in
            switch keyword {
            case "to_name_list_fold":
                return nameList
            case "from_address":
                return fromAddress.htmlEncoded
            case "mail_receiver":
                return (isSeparateSend ? BundleI18n.MailSDK.Mail_Compose_SendSeparatelyTo : BundleI18n.MailSDK.Mail_Normal_Receiver) + " "
            default:
                return nil
            }
        })
    }

    private func replaceForAttachmentTag(mail: MailMessageItem) -> String {
        if mail.message.attachments.count > 0 {
            return replaceFor(template: template.sectionAttachmentTag) { (key) -> String? in
                switch key {
                case "attachments_count":
                    return "\(mail.message.attachments.count)"
                default:
                    return nil
                }
            }
        }
        return ""
    }

    private func replaceForPriorityTag(mail: MailMessageItem) -> String {
        switch mail.message.systemLabels.toMailPriorityType() {
        case .high:
            return replaceFor(template: template.sectionPriorityTag) { (key) -> String? in
                switch key {
                case "show_high":
                    return "show-high"
                default:
                    return nil
                }
            }
        case .low:
            return replaceFor(template: template.sectionPriorityTag) { (key) -> String? in
                switch key {
                case "show_low":
                    return "show-low"
                default:
                    return nil
                }
            }
        default:
            return ""
        }
    }

    private func replaceForPriorityBanner(priorityType: MailPriorityType) -> String {
        switch priorityType {
        case .high:
            return replaceFor(template: template.sectionPriorityBanner) { (key) -> String? in
                switch key {
                case "show_high":
                    return "show-high"
                case "priority_text":
                    return MailPriorityType.high.toBannerText()
                default:
                    return nil
                }
            }
        case .low:
            return replaceFor(template: template.sectionPriorityBanner) { (key) -> String? in
                switch key {
                case "show_low":
                    return "show-low"
                case "priority_text":
                    return MailPriorityType.low.toBannerText()
                default:
                    return nil
                }
            }
        default:
            return ""
        }
    }

    private func replaceForSafetyTipsBanner(mail: MailMessageItem, atLabelID: String, displaySafeTipsBanner: Bool, displaySafeTipsNewBanner: Bool, fromChat: Bool) -> String {
        if !displaySafeTipsBanner {
            // 不展示 banner
            return ""
        } else {
            return replaceFor(template: template.setionSafeTipsMessageBanner, patternHandler: { (keyword) -> String? in
                switch keyword {
                case "safety-title-display-none":
                    return displaySafeTipsNewBanner ? "" : "display-none"
                case "safe_tips_title":
                    if displaySafeTipsNewBanner {
                        switch mail.message.security.riskBannerLevel {
                        case .warning1:
                            return BundleI18n.MailSDK.Mail_Shared_SpamEmailCaution_Notice_Title
                        case .danger:
                            return BundleI18n.MailSDK.Mail_Shared_SpamEmailAlert_Notice_Title
                        case .info:
                            return ""
                        @unknown default:
                            return ""
                        }
                    }
                    return nil
                case "safety-tip-banner-bg-color":
                    if displaySafeTipsNewBanner {
                        switch mail.message.security.riskBannerLevel {
                        case .warning1:
                            return "color-tips-warning"
                        case .danger:
                            return "color-tips-danger"
                        case .info:
                            return "color-tips-default"
                        @unknown default:
                            return ""
                        }
                    } else {
                        return "color-tips-default"
                    }
                case "showDefault":
                    return mail.message.security.riskBannerLevel == .info || !displaySafeTipsNewBanner ? "showDefault": ""
                case "showWarning":
                    return mail.message.security.riskBannerLevel == .warning1 && displaySafeTipsNewBanner ? "showWarning": ""
                case "showDanger":
                    return mail.message.security.riskBannerLevel == .danger && displaySafeTipsNewBanner ? "showDanger": ""
                case "safe_tips_wording":
                    var wording: String?
                    if displaySafeTipsNewBanner {
                        switch mail.message.security.riskBannerReason {
                        case .impersonateDomain:
                            wording = BundleI18n.MailSDK.Mail_Shared_SpamEmaillAlert_SimilarDomain_Desc(mail.message.from.domain).htmlEncoded
                        case .impersonateKpName:
                            wording =  BundleI18n.MailSDK.Mail_Shared_SpamEmailCaution_FakeIdentity_Desc(mail.message.from.mailDisplayNameNoMeNoNameUpdate).htmlEncoded
                        case .unauthInternal:
                            wording =  BundleI18n.MailSDK.Mail_Shared_SpamEmailCaution_UnverifiedID_Desc.htmlEncoded
                        case .unauthExternal:
                            wording =  BundleI18n.MailSDK.Mail_Shared_SpamEmailCaution_UnverifiedID_Desc.htmlEncoded
                        case .maliciousURL:
                            wording = BundleI18n.MailSDK.Mail_Shared_SpamEailAlert_RiskyLink_Desc.htmlEncoded
                        case .maliciousAttachment:
                            wording = BundleI18n.MailSDK.Mail_Shared_SpamEmaillAlert_HarmfulAttachment_Desc.htmlEncoded
                        case .phishing1:
                            wording = BundleI18n.MailSDK.Mail_Shared_SpamEmailAlert_StealInfo_Desc.htmlEncoded
                        case .impersonatePartner:
                            wording = BundleI18n.MailSDK.Mail_Shared_SpamEmailCaution_SimilarCorrespondence_Desc(mail.message.from.domain).htmlEncoded
                        case .externalEncryptionAttachment:
                            wording = BundleI18n.MailSDK.Mail_Shared_SpamEmailCaution_SecureAttachment_Desc.htmlEncoded
                        case .default:
                            wording = BundleI18n.MailSDK.Mail_Shared_SpamEmaiCaution_HighRisk_Desc
                        @unknown default:
                            wording = BundleI18n.MailSDK.Mail_Shared_SpamEmaiCaution_HighRisk_Desc
                        }
                    } else {
                        switch mail.message.security.riskBannerReason {
                        case .impersonateDomain:
                            wording = BundleI18n.MailSDK.Email_SpamWarningDomainSpoofing_Banner(mail.message.from.domain).htmlEncoded
                        case .impersonateKpName:
                            wording =  BundleI18n.MailSDK.Email_SpamWarningEmplyeeNameSpoofing_Banner(mail.message.from.mailDisplayNameNoMeNoNameUpdate).htmlEncoded
                        case .unauthInternal:
                            wording =  BundleI18n.MailSDK.Email_SpamWarningSimilarDomainSpoofing_Banner(mail.message.from.domain).htmlEncoded
                        case .unauthExternal:
                            wording =  BundleI18n.MailSDK.Email_SpamWarningUnauthenticatedAddress_Banner(mail.message.from.address).htmlEncoded
                        case .maliciousURL:
                            wording = ""
                        case .maliciousAttachment:
                            wording = ""
                        case .phishing1:
                            wording = ""
                        case .impersonatePartner:
                            wording = ""
                        case .externalEncryptionAttachment:
                            wording = ""
                        case .default:
                            break
                        @unknown default:
                            break
                        }
                    }
                    MailLogger.info("replaceForSafetyTipsBanner \(mail.message.id) \(mail.message.security.riskBannerReason)")
                    if let wording = wording {
                        return wording
                    } else {
                        // fallback 到默认值
                        MailLogger.info("replaceForSafetyTipsBanner fallback \(mail.message.id)")
                        return BundleI18n.MailSDK.Mail_ReportTrash_RiskNoteMobile.htmlEncoded
                    }
                case "safety-buttons-display-none":
                    // 是否隐藏风险 Bannner 下面两个按钮
                    if accountContext.featureManager.open(.newSpamPolicy) && atLabelID == MailLabelId.Spam.rawValue {
                        return "display-none"
                    } else if mail.message.security.reportType == .spam || fromChat || atLabelID == Mail_LabelId_SEARCH_TRASH_AND_SPAM {
                        return "display-none"
                    } else {
                        return ""
                    }
                case "normal-button-display-none":
                    // 是否隐藏标为正常按钮，Spam 和 Trash 下才展示标为正常按钮
                    return (atLabelID == MailLabelId.Trash.rawValue || atLabelID == MailLabelId.Spam.rawValue) ? "" : "display-none"
                case "report_wording":
                    // 举报按钮文案
                    return accountContext.featureManager.open(.newSpamPolicy)
                    ? BundleI18n.MailSDK.Mail_MarkSpam_Button
                    : BundleI18n.MailSDK.Mail_ReportTrash_ReportMobile
                case "normal_wording":
                    // 标为正常按钮文案
                    return accountContext.featureManager.open(.newSpamPolicy)
                    ? BundleI18n.MailSDK.Mail_NotSpam_Button
                    : BundleI18n.MailSDK.Mail_ReportTrash_NormalEmailMobile
                case "close-display-none":
                    return fromChat ? "display-none" : ""
                default:
                    return nil
                }
            })
        }
    }

    private func replaceForInterceptTipsBanner(statFrom: MessageListStatInfo.FromType, hasSafetyBanner: Bool) -> String {
        return replaceFor(template: template.setionInterceptTipsMessageBanner, patternHandler: { (keyword) -> String? in
            switch keyword {
            case "intercept_tips_wording":
                return BundleI18n.MailSDK.Mail_ExternalImagesNotShown_Banner
            case "show_images_wording":
                return BundleI18n.MailSDK.Mail_ExternalImagesNotShown_ShowOnce_Button
            case "intercept_more_wording":
                return BundleI18n.MailSDK.Mail_ExternalImagesNotShown_More_Button
            case "intercept-buttons-display-none":
                if (!statFrom.shouldShowTrustSender && hasSafetyBanner) || !Store.settingData.hasEmailService {
                    return "display-none"
                } else {
                    return ""
                }
            default:
                return nil
            }
        })
    }

    private func replaceForReadReceiptTipsBanner(messageId: String) -> String {
        return replaceFor(template: template.sectionReadReceiptTipsBanner, patternHandler: { (keyword) -> String? in
            switch keyword {
            case "request_title":
                return BundleI18n.MailSDK.Mail_ReadReceipt_RequestFromSender_Banner
            case "dont_send_button_detail":
                return BundleI18n.MailSDK.Mail_ReadReceipt_RequestFromSender_DontSend
            case "send_button_detail":
                return BundleI18n.MailSDK.Mail_ReadReceipt_RequestFromSender_SendReceipt
            case "loading":
                return accountContext.readReceiptManager.sendingMessages.contains(messageId) ? "loading" : ""
            default:
                return nil
            }
        })
    }

    private func replaceForScheduleMessageBanner(scheduleSendTimestamp: Int64) -> String {
        return replaceFor(template: template.setionScheduleMessageBanner, patternHandler: { (keyword) -> String? in
            switch keyword {
            case "schedule_time":
                let timeStr = ProviderManager.default.timeFormatProvider?.mailScheduleSendTimeFormat(scheduleSendTimestamp)
                return BundleI18n.MailSDK.Mail_SendLater_ScheduledForDate(timeStr ?? "")
            case "schedule-view-original-button-text":
                return Store.settingData.mailClient ? "" : BundleI18n.MailSDK.Mail_SendLater_CancelSend
            default:
                return nil
            }
        })
    }

    private func replaceForRecallMessageBanner(state: MailRecallState, displayBanner: Bool) -> String {
        return replaceFor(template: template.setionRecallMessageBanner, patternHandler: { (keyword) -> String? in
            switch keyword {
            case "recalling_text":
                return BundleI18n.MailSDK.Mail_Recall_BannerRecalling
            case "completed_text":
                return state.completedText
            case "button_detail":
                return BundleI18n.MailSDK.Mail_Recall_Details
            case "recall_state":
                return String(state.rawValue)
            case "showRecallBanner":
                return displayBanner ? "showRecallBanner" : ""
            case "showRecallMenuItem":
                return state == .none ? "showRecallMenuItem" : ""
            case "showRecalling":
                return (state == .request || state == .processing) ? "showRecalling" : ""
            case "showRecalled":
                return state == .done ? "showRecalled" : ""
            case "showRecallDetail":
                return (state == .processing || state == .done) ? "showRecallDetail" : ""
            default:
                return nil
            }
        })
    }

    private func replaceForRecallTag(display: Bool) -> String {
        return replaceFor(template: template.sectionRecallTag) { (keyword) -> String? in
            switch keyword {
            case "showRecallTag":
                return display ? "showRecallTag" : ""
            default:
                return nil
            }
        }
    }

    /// 提取所有的收件人姓名，显示到 TO 中 (包括 to cc bcc中的)
    func replaceForToNames(mail: MailMessageItem,
                                   shouldForceDisplayBcc: Bool,
                                   needReplaceName: Bool = false) -> String {
        func addressListToString(_ addressList: [MailClientAddress]) -> String {
            var allToNames = ""
            addressList.forEach { (address) in
                if !allToNames.isEmpty {
                    allToNames = allToNames + ", "
                }
                var name = address.mailToDisplayName
                if name.isEmpty {
                    name = address.address
                }
                if address.larkEntityType.isGroupOrEnterpriseMailGroup {
                    if address.larkEntityType == .group {
                        if needReplaceName {
                            allToNames = allToNames + template.sectionGroupIcon.escapeString + " "
                        } else {
                            allToNames = allToNames + template.sectionGroupIcon
                        }

                    } else {
                        if needReplaceName {
                            allToNames = allToNames + template.sectionMailListIcon.escapeString + " "
                        } else {
                            allToNames = allToNames + template.sectionMailListIcon
                        }
                    }
                }
                // address 替换逻辑
                if needReplaceName {
                    if let newName = MailAddressChangeManager.shared.uidNameMap[String(address.larkEntityID)] {
                        name = newName
                    } else if let newName = MailAddressChangeManager.shared.addressNameMap[address.address] {
                        name = newName
                    }
                }
                allToNames = allToNames + name.htmlEncoded
            }
            return allToNames
        }

        let allTosList = mail.message.to + mail.message.cc
        var allToNames = addressListToString(allTosList)
        /// 在to后面加上bcc的显示
        if mail.isFromMe || shouldForceDisplayBcc {
            var bccList = [MailClientAddress]()
            bccList.append(contentsOf: mail.message.bcc)
            let bccNames = addressListToString(bccList)
            if !bccNames.isEmpty {
                if allToNames.isEmpty {
                    allToNames.append(bccNames)
                } else {
                    allToNames.append(", ")
                    allToNames.append(bccNames)
                }
            }
        }
        return allToNames
    }

    private func replaceForFromAddressListItem(mail: MailMessageItem, by renderModel: MailMessageListRenderModel, isSeparateSend: Bool) -> String {
        return replaceFor(template: template.sectionRecipientsItem) { (keyword) -> String? in
            switch keyword {
            case "address_type":
                return BundleI18n.MailSDK.Mail_Normal_From.htmlEncoded
            case "address_item":
                var delegationAddress = ""
                if renderModel.shouldShowDelegationInfo(for: mail, accountContext: self.accountContext)  {
                    delegationAddress = replaceForDelegation(address: mail.message.senderDelegation)
                }
                return replaceForAddressList(address: mail.message.from, ignoreMe: true) + delegationAddress
            case "lan":
                return I18n.currentLanguageShortIdentifier()
            case "send-separately":
                return isSeparateSend ? "send-separately" : ""
            default:
                return nil
            }
        }
    }

    private func replaceForToAddressListItem(mail: MailMessageItem) -> String {
        var to = ""
        let tos = mail.message.to
        for address in tos {
            to = to + replaceForAddressList(address: address, isTo: true)
        }
        if to.isEmpty {
            /// 如果地址全都是空的，则to留空（适用于只bcc了我的情况）
            let allAddressList = mail.message.to + mail.message.cc + mail.message.bcc
            if allAddressList.isEmpty {
                to = " "
            } else {
                /// 如果有其他收件人，则不用显示空的to了
                return ""
            }
        }

        return replaceFor(template: template.sectionRecipientsItem) { (keyword) -> String? in
            switch keyword {
            case "address_type":
                return BundleI18n.MailSDK.Mail_Normal_To_Title.htmlEncoded
            case "address_item":
                return to
            case "lan":
                return I18n.currentLanguageShortIdentifier()
            case "send-separately":
                return ""
            default:
                return nil
            }
        }
    }

    private func replaceForCCAddressListItem(mail: MailMessageItem) -> String {
        let ccs = mail.message.cc
        var cc = ""
        for address in ccs {
            let name = address.mailDisplayName
            if name.isEmpty && address.address.isEmpty {
                continue
            }
            cc = cc + replaceForAddressList(address: address, isTo: true)
        }
        if cc.isEmpty {
            return ""
        }
        return replaceFor(template: template.sectionRecipientsItem) { (keyword) -> String? in
            switch keyword {
            case "address_type":
                return BundleI18n.MailSDK.Mail_Normal_Cc.htmlEncoded
            case "address_item":
                return cc
            case "lan":
                return I18n.currentLanguageShortIdentifier()
            case "send-separately":
                return ""
            default:
                return nil
            }
        }
    }

    private func replaceForBCCAddressListItem(
        mail: MailMessageItem,
        isSeparateSend: Bool,
        shouldForceDisplayBcc: Bool
    ) -> String {
        let bccs = mail.message.bcc
        var bcc = ""
        if !bccs.isEmpty && (mail.isFromMe || shouldForceDisplayBcc) {
            for address in bccs {
                let name = address.mailDisplayName
                if name.isEmpty && address.address.isEmpty {
                    continue
                }

                bcc = bcc + replaceForAddressList(address: address, isTo: true)
            }
            if bcc.isEmpty {
                return ""
            }
        } else {
            return ""
        }
        return replaceFor(template: template.sectionRecipientsItem) { (keyword) -> String? in
            switch keyword {
            case "address_type":
                return isSeparateSend ? BundleI18n.MailSDK.Mail_Normal_Sp : BundleI18n.MailSDK.Mail_Normal_Bcc.htmlEncoded
            case "address_item":
                return bcc
            case "lan":
                return I18n.currentLanguageShortIdentifier()
            case "send-separately":
                return isSeparateSend ? "send-separately" : ""
            default:
                return nil
            }
        }
    }

    func replaceForDelegation(address: MailClientAddress) -> String {
        return replaceFor(template: template.sectionDelegationItem, patternHandler: { (keyword) -> String? in
            switch keyword {
            case "delegation_name":
                var delegateName = address.displayName
                if delegateName.isEmpty {
                    delegateName = address.name
                }
                return delegateName.htmlEncoded
            case "delegation_address":
                return address.address.htmlEncoded
            case "user_type":
                return String(address.larkEntityType.rawValue)
            case "tenant_id":
                return address.tenantID
            case "user_id":
                return address.larkEntityType != .group ? address.larkEntityIDString.htmlEncoded : ""
            case "delegation_info_left":
                return BundleI18n.MailSDK.Mail_SentByNameAddress_Part1_Text
            case "delegation_info_right":
                return BundleI18n.MailSDK.Mail_SentByNameAddress_Part2_Text
            case "enable_click":
                // 搬家显示的委托中， 代发人默认不支持点击展示profile
                return ""
            default:
                return nil
            }

        })
    }

    private func replaceForAddressList(address: MailClientAddress,
                                       ignoreMe: Bool = false,
                                       isTo: Bool = false) -> String {
        let isGroup = address.isGroupOrEnterpriseMailGroup
        var displayName = (ignoreMe ? address.mailDisplayNameNoMe : address.mailDisplayName).htmlEncoded
        if isTo {
            displayName = address.mailToDisplayName.htmlEncoded
        }
        return replaceFor(template: template.sectionAddressItem) { (keyword) -> String? in
            switch keyword {
            case "address_name":
                return displayName
            case "address_address":
                return address.address.htmlEncoded
            case "user_type":
                return String(address.larkEntityType.rawValue)
            case "tenant_id":
                return address.tenantID
            case "address-item-group-icon":
                return isGroup ? "" : "hide"
            case "address_item_group_type_icon":
                if address.larkEntityType == .enterpriseMailGroup {
                    return template.sectionMailListIcon
                } else {
                    return template.sectionGroupIcon
                }
            case "user_id":
                return address.larkEntityType != .group ? address.larkEntityIDString.htmlEncoded : ""
            case "no-name-content":
                return displayName.isEmpty && !isGroup ? "no-name-content" : ""
            default:
                return nil
            }
        }
    }

    private func replaceFormessageLoadMore(messageLoadMoreId: String) -> String {
        return replaceFor(template: template.sectionMessageLoadMore) { (keyword) -> String? in
            switch keyword {
                case "message_loadmore_id":
                    return messageLoadMoreId
                default:
                    return nil
            }
        }
    }

    private func replaceForMessageActionBar() -> String {
        return replaceFor(template: template.sectionMessageActionBar) { (keyword) -> String? in
            switch keyword {
            case "action-reply-text":
                return BundleI18n.MailSDK.Mail_Normal_Reply
            case "action-replyall-text":
                return BundleI18n.MailSDK.Mail_Compose_Template_ReplyAll
            case "action-forward-text":
                return BundleI18n.MailSDK.Mail_Normal_Forward
            case "action-sendtochat-text":
                return BundleI18n.MailSDK.Mail_SharetoChat_MenuItem
            default:
                return nil
            }
        }
    }

    private func replaceForMessageDraftContainer(messageItem: MailMessageItem, mailAccount: MailAccount) -> String {
        // TODO: @chenyangfan 获取第一封草稿填充 done
        return replaceFor(template: template.sectionMessageDraftContainer) { (keyword) -> String? in
            switch keyword {
            case "from_name":
                return messageItem.message.from.mailDisplayNameNoMe
            case "address_address":
                return messageItem.message.from.address.htmlEncoded
            case "user_type":
                return String(messageItem.message.from.larkEntityType.rawValue)
            case "tenant_id":
                return messageItem.message.from.tenantID
            case "user_id":
                return messageItem.message.from.larkEntityIDString
            case "empty-draft":
                MailLogger.info("drafts isEmpty:\(messageItem.drafts.isEmpty)")
                return messageItem.drafts.isEmpty ? "empty-draft" : ""
            case "message-draft-avatar":
                if MailMessageListTemplateRender.enableNativeRender {
                    return self.replaceForFromNativeAvatar(userid: mailAccount.larkUserID,
                                                           name: mailAccount.accountName,
                                                           address: mailAccount.accountAddress,
                                                           userType: .user,
                                                           tenantId: self.accountContext.user.tenantID,
                                                           avatar: self.accountContext.user.avatarKey,
                                                           isFeedCard: true,
                                                           isMe: true)
                } else {
                    return self.replaceForFromAvatar(userid: mailAccount.larkUserID, userType: .user)
                }
            case "message-draft-text":
                return BundleI18n.MailSDK.Mail_Drafts_DraftsItem
            case "message-draft-summary":
                if let lastDraft = messageItem.drafts.max(by: { $0.createdTimestamp < $1.createdTimestamp }) {
                    let lastDraftBodySummary = lastDraft.bodySummary
                    return lastDraftBodySummary
                } else {
                    return ""
                }
            default:
                return nil
            }
        }
    }

    private func replaceForImportantContactBanner(importantContactName: String) -> String {
        // TODO: @chenyangfan 判断重要联系人填充
        // new event
        let newEvent = NewCoreEvent(event: .email_focus_contact_recommend_banner_view)
        newEvent.post()
        return replaceFor(template: template.sectionImportantContactBanner) { (keyword) -> String? in
            let description = """
            <span class="important-contact-name"> \(importantContactName.htmlEncoded) </span>
            """
            switch keyword {
            case "contact-banner-display-none":
                return "banner-expand-start"
            case "important-contact-description":
                return BundleI18n.MailSDK.Mail_FollowEmailContact_FollowAndCheckEmailsInChats_Mobile_Text(description)
            case "follow-contact":
                return BundleI18n.MailSDK.Mail_FollowEmailContact_Follow_Button
            case "do-not-recommend":
                return BundleI18n.MailSDK.Mail_FollowEmailContact_DontShowAgain_Button
            default:
                return nil
            }
        }
    }

    private func replaceForAttachments(attachments: [MailClientAttachement], msgId: String, isFromChat: Bool, isAtTop: Bool) -> String {
        var shouldReplaceTop: Bool = false
        if accountContext.featureManager.open(.attachmentLocation, openInMailClient: true),
           let setting = Store.settingData.getCachedPrimaryAccount()?.mailSetting,
           setting.attachmentLocation == .top {
            shouldReplaceTop = true
        }
        if shouldReplaceTop != isAtTop || attachments.count < 1 {
            return ""
        }

        return replaceFor(template: isAtTop ? template.sectionTopAttachment : template.sectionAttachment) { (keyword) -> String? in
            switch keyword {
            case "attachment_list":
                var attachlist = ""
                for attach in attachments {
                    attachlist = attachlist + replaceForAttachmentItem(attachment: attach, count: attachments.count, msgId: msgId, isFromChat: isFromChat, isAtTop: isAtTop)
                }
                return attachlist
            case "showattachment":
                return attachments.count < 1 ? "hide" : ""
            case "attachment_summary":
                return replaceForAttachmentSummary(attachments: attachments)
            case "attachment_show_more":
                return BundleI18n.MailSDK.Mail_Attachment_ShowMore
            default:
                return nil

            }
        }
    }

    private func replaceForAttachmentItem(attachment: MailClientAttachement, count: Int, msgId: String, isFromChat: Bool, isAtTop: Bool) -> String {
        var attachmentcount = count
        if count >= 3 && !isAtTop {
            attachmentcount = 3
        }

        let fileNameSubstrings = attachment.fileName.split(separator: ".")
        let attachmentType = fileNameSubstrings.count > 1 ? String(fileNameSubstrings.last ?? "") : nil
        let expireInfo = attachment.expireDisplayInfo
        var progress = ""
        var state: MailClientTemplateDownloadState = .needDownload
        if Store.settingData.mailClient && !isFromChat {
            if attachment.fileURL.isEmpty {
                progress = ""
                state = .needDownload
            } else {
                progress = "100%"
                state = .ready
            }
        } else {
            progress = "100%"
            state = .ready
        }

        return replaceFor(template: template.sectionAttachmentListItem) { (keyword) -> String? in
            switch keyword {
            case "attachment_count":
                var attachmentCount = "_"
                attachmentCount.append(String(attachmentcount))
                return attachmentCount.htmlEncoded
            case "file_token":
                return attachment.fileToken.htmlEncoded
            case "file_url":
                let localFileUrl = attachment.fileURL.htmlEncoded
                if !localFileUrl.isEmpty {
                  // eml场景，有本地URL，直接使用 design by @xiongbin
                  return localFileUrl
                } else {
                    return (Store.settingData.mailClient && !isFromChat) ? "cid:\(attachment.fileToken)_msgId\(msgId)".htmlEncoded : localFileUrl
                }
            case "attachment_name":
                return attachment.fileName.htmlEncoded
            case "attachment-state":
                return state.rawValue.htmlEncoded
            case "initial-progress":
                return progress.htmlEncoded
            case "attachment_icon":
                var mailAttachmentIcon = String(MailCustomScheme.mailAttachmentIcon.rawValue)
                mailAttachmentIcon.append(":")
                mailAttachmentIcon.append(attachment.fileName)
                return mailAttachmentIcon.htmlEncoded
            case "attachment_sizetype":
                return String(attachment.type.rawValue)
            case "attachment_type":
                return (attachmentType?.uppercased() ?? BundleI18n.MailSDK.Mail_Attachment_UnknownType).htmlEncoded
            case "attachment_background_color":
                return accountContext.featureManager.open(.attachmentLocation, openInMailClient: true) ? UIImage.fileBgColorType(with: attachment.fileName).rawValue : ""
            case "attachment_size":
                return FileSizeHelper.memoryFormat(UInt64(attachment.fileSize)).htmlEncoded
            case "attachment_warning_type":
                let attachmentType = String(attachment.fileName.split(separator: ".").last ?? "")
                let type = DriveFileType(rawValue: attachmentType)
                // 附件已失效优先级更高，此时不显示 warning
                return (type?.isHarmful == true && expireInfo.expireDateType != .expired) ? "warning" : "none"
            case "attachment_warning_tip":
                return BundleI18n.MailSDK.Mail_Attachment_HarmfulDetected.htmlEncoded
            case "attachment_status_text":
                return expireInfo.expireText
            case "attachment_status_type":
                return expireInfo.expireDateType.rawValue
            default:
                return nil
            }
        }
    }

    private func replaceForAttachmentSummary(attachments: [MailClientAttachement]) -> String {
        var size: UInt64 = 0
        for attachment in attachments {
            size = size + UInt64(attachment.fileSize)
        }
        return replaceFor(template: template.sectionAttachmentSummary) { (keyword) -> String? in
            switch keyword {
            case "attachment_count":
                return BundleI18n.MailSDK.Mail_Attachment_Count(attachments.count).htmlEncoded
            case "attachment_summary_value":
                return String(FileSizeHelper.memoryFormat(size)).htmlEncoded
            default:
                return nil
            }
        }
    }
}
