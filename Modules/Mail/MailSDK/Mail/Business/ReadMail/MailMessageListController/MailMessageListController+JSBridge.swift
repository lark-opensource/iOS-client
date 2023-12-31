//
//  MailMessageListController+JSBridge.swift
//  MailSDK
//
//  Created by majx on 2019/12/2.
//

import Foundation
import EENavigator
import LarkUIKit
import LarkActionSheet
import LarkAlertController
import Kingfisher
import Homeric
import RxSwift
import RustPB
import ServerPB
import LarkLocalizations
import LarkGuideUI
import WebKit
import ByteWebImage
import UniverseDesignActionPanel
import Reachability
import LarkReactionDetailController
import LarkEMM
import LarkSensitivityControl
import LarkAssetsBrowser
import LarkAlertController
import UniverseDesignToast
import UniverseDesignDialog
import UniverseDesignColor
import LarkStorage

// MARK: - JSBridge
enum MailMessageListJSMessageType: String {
    case openAttachment
    case deleteDraft
    case clickDraft
    case clickLabel
    case clickImage
    case clickFlag
    case checkUrls
    case log
    case tracker
    case showCalendarDetail
    case acceptCalendar
    case refuseCalendar
    case pendingCalendar
    case updateCalendarAction
    case messageClick
    case checkUserids
    case addressClick
    case receiverClick
    case avatarClick
    case readmore
    case domReady
    case recallDetail
    case translateClick
    case turnOffTranslationClick
    case selectTranslationLanguageClick
    case viewOriginalClick
    case viewTranslationClick
    case expandMessagesFirstVisible
    case track
    case contextMenuClick
    case cancelScheduleSendClick
    case scrollTo
    case fixScaleFinish
    case needContents
    case searchResults
    case exitSearch
    case reportMessage
    case trustMessage
    case closeSafetyBanner
    case popoverDidClose
    case sendStatusClick
    case imageStartLoad
    case imageOnLoad
    case imageOnError
    case imageLoadingOnScreen
    case jsSearchStart
    case downloadAttachment
    case cancelAttachmentDownload
    case calendarNeedUpdate
    case clickOnLink
    case copyContents
    case atUserInfos
    case clickShowInterceptedImages
    case interceptedMoreAction
    case showInterceptedBanner
    case clickDontSendReceipt
    case clickSendReceipt
    case clickDocPreview
    case followBtnClickMethod
    case triggerLoadMore
    case currentVisualMessage
    case replyAction
    case replyAllAction
    case forwardAction
    case sendToChatAction
    case callbackJsLifecycle
    case clickMessageDraft
    case stopRecommendContact
    case closeContactRecommendBanner
    case followRecommendContact
}

enum TemplateLogLevel: Int {
    case debug = 0
    case info
    case warn
    case error
}

// MARK: - WebView Invoke Methods
extension MailMessageListController {
    func invoke(webView: WKWebView, method: MailMessageListJSMessageType, args: [String: Any]) {

        var isComponentHandled = false
        // 分发到component内
        for comp in eventComponents {
            if comp.handleInvoke(webView: webView, method: method, args: args) {
                isComponentHandled = true
            }
        }

        if !isComponentHandled {
            switch method {
            case .followRecommendContact: followRecommendContact(args: args, in:webView)
            case .closeContactRecommendBanner: closeContactRecommendBanner(args: args, in:webView)
            case .stopRecommendContact: stopRecommendContact(args: args, in:webView)
            case .currentVisualMessage: currentVisualMessage(args: args, in: webView)
            case .triggerLoadMore: loadMoreHandler(args: args, in: webView)
            case .replyAllAction: replyAllAction(args: args, in: webView)
            case .forwardAction: forwardAction(args: args, in:webView)
            case .sendToChatAction: sendToChatAction(args: args, in:webView)
            case .replyAction: replyAction(args: args, in:webView)
            case .followBtnClickMethod: clickFollow(args: args, in: webView)
            case .openAttachment: openAttachment(args: args, in: webView)
            case .downloadAttachment: downloadAttachment(args: args, in: webView)
            case .cancelAttachmentDownload: cancelAttachmentDownload(args: args, in: webView)
            case .deleteDraft: deleteDraft(args: args, in: webView)
            case .clickDraft: clickDraft(args: args, in: webView)
            case .clickLabel: clickLabel(args: args, in: webView)
            case .clickImage: clickImage(args: args, in: webView)
            case .clickDocPreview: clickDocPreview(args: args, in: webView)
            case .clickFlag: clickFlag(args: args, in: webView)
            case .checkUserids: checkUserids(args: args, in: webView)
            case .checkUrls: checkUrls(args: args, in: webView)
            case .log: handleLog(args: args, in: webView)
            case .tracker: handleTracker(args: args, in: webView)
            case .messageClick: statReadMessageAction(args: args, in: webView)
            case .addressClick: handleAddressClick(args: args, in: webView)
            case .receiverClick: handleReceiverClick(args: args, in: webView)
            case .avatarClick: handleAvatarClick(args: args, in: webView)
            case .readmore: handleReadMore(args: args, in: webView)
            case .translateClick: translateClick(args: args, in: webView)
            case .turnOffTranslationClick: turnOffTranslationClick(args: args, in: webView)
            case .selectTranslationLanguageClick: selectTranslationLanguageClick(args: args, in: webView)
            case .viewOriginalClick: viewOriginalClick(args: args, in: webView)
            case .viewTranslationClick: viewTranslationClick(args: args, in: webView)
            case .recallDetail: handleRecallDetail(args: args, in: webView)
            case .expandMessagesFirstVisible: handleExpandMessagesFirstVisible(args: args, in: webView)
            case .track: handleTrack(args: args, in: webView)
            case .contextMenuClick: handleContextMenuClick(args: args, in: webView)
            case .scrollTo: handleScrollTo(args: args, in: webView)
            case .cancelScheduleSendClick: handleCancelScheduleSendClick(args: args, in: webView, source: "scheduled_banner")
            case .fixScaleFinish: handleFixScaleFinish(webView)
            case .needContents: handleNeedContent(args: args, in: webView)
            case .searchResults: handleSearchResults(args: args, in: webView)
            case .exitSearch: handleExitSearch()
            case .reportMessage: handleReportMessage(args: args)
            case .trustMessage: handleTrustMessage(args: args)
            case .closeSafetyBanner: handleCloseSafetyBanner(args: args)
            case .sendStatusClick: handleSendStatusButtonClick(args: args)
            case .jsSearchStart: handlejsSearchStart()
            case .calendarNeedUpdate: handleCalendarNeedUpdate(args: args, in: webView)
            case .clickOnLink: handleClickOnLink(args: args, in: webView)
            case .clickShowInterceptedImages: handleShowInterceptedImages(args: args, in: webView)
            case .interceptedMoreAction: handleInterceptedMoreAction(args: args, in: webView)
            case .showInterceptedBanner: handleShowInterceptedBanner(args: args, in: webView)
            case .clickDontSendReceipt: handleDontSendReceipt(args: args, in: webView)
            case .clickSendReceipt: handleSendReceipt(args: args, in: webView)
            case .clickMessageDraft: handleMessageDraftClick(args: args, in: webView)
            case .copyContents:
                guard let ids = args["messageIDs"] as? [String] else {
                    return
                }
                handleCopyContents(messageIDs: ids)
            case .showCalendarDetail, .acceptCalendar, .refuseCalendar, .pendingCalendar, .updateCalendarAction, .domReady, .popoverDidClose, .imageStartLoad, .imageOnLoad, .imageLoadingOnScreen, .imageOnError:
                assertionFailure("缺少处理逻辑")
            case .atUserInfos: // FIXME: use unknown default setting to fix warning
                 assertionFailure("unknown default")
            @unknown default:
                assertionFailure("unknown default")
            }
        }
    }
    
    func replyAction(args: [String: Any], in webView: WKWebView?) {
        let msgID = args["messageID"] as? String
        reply(replyMsgID: msgID ?? "", isFromFootBtn: false)
    }
    
    func replyAllAction(args: [String: Any], in webView: WKWebView?) {
        let msgID = args["messageID"] as? String
        replyAll(replyMsgID: msgID ?? "", isFromFootBtn: false)
    }
        
    func forwardAction(args: [String: Any], in webView: WKWebView?) {
        let msgID = args["messageID"] as? String
        forward(replyMsgID: msgID ?? "", isFromFootBtn: false)
    }
    
    func sendToChatAction(args: [String: Any], in webView: WKWebView?) {
        let msgID = args["messageID"] as? String
        Store.settingData.storageLimitCheck(from: self, navigator: accountContext.navigator) { [weak self] in
            self?.handleMenuClickShareToIm(messageId: msgID ?? "")
        }
    }
        
    func callJSFunction(_ funName: String, params: [String], isUserAction: Bool? = nil, withThreadId threadID: String?, completionHandler: ((Any?, Error?) -> Void)? = nil) {
        let threadID = threadID ?? mailItem.threadId
        let theWebView = getWebViewOf(threadId: threadID)
        callJSFunction(funName, params: params, isUserAction: isUserAction, in: theWebView, completionHandler)
    }

    func callJSFunction(_ funName: String, params: [String], completionHandler: ((Any?, Error?) -> Void)?) {
        callJSFunction(funName, params: params, in: nil, completionHandler)
    }

    func callJSFunction(_ funName: String, params: [String], isUserAction: Bool? = nil, in webView: WKWebView? = nil, _ completionHandler: ((Any?, Error?) -> Void)? = nil) {
        var javaScriptString = "window.\(funName)("
        for (index, param) in params.enumerated() {
            javaScriptString += "'\(param)'"
            if index != params.count - 1 {
                javaScriptString += ","
            }
        }
        if let isUserAction = isUserAction {
            javaScriptString += ", '\(isUserAction)'"
        }
        javaScriptString += ")"
        callJavaScript(javaScriptString, in: webView, completionHandler)
    }

    // 给listViewModel用的
    func callJavaScript(jsString: String) {
        callJavaScript(jsString)
    }

    func callJavaScript(_ javaScriptString: String, in webView: WKWebView? = nil, _ completionHandler: ((Any?, Error?) -> Void)? = nil) {
        asyncRunInMainThread { [weak self] in
            guard let theWebView = (webView ?? self?.webView) as? (WKWebView & MailBaseWebViewAble),
                  let threadID = theWebView.identifier else {
                return
            }
            let pageCell = self?.getPageCellOf(threadId: threadID)
            var jsMethod: String?
            if let index = javaScriptString.firstIndex(of: "(") {
                jsMethod = String(javaScriptString[javaScriptString.startIndex..<index])
            }
            if pageCell?.isDomReady == true {
                MailMessageListController.logger.info("callJS " + (jsMethod ?? "") + (" \(theWebView.identifier ?? "")"))
                theWebView.evaluateJavaScript(javaScriptString) { (res, error) in
                    if let error = error {
                        var errorMsg = "MailMessageListController JSError "
                        if let jsMethod = jsMethod {
                            errorMsg += jsMethod

                            var errorLocalizedString = "\(error)"
                            let methodRange = errorLocalizedString.range(of: "\(jsMethod)(")
                            if let methodRange = methodRange, methodRange.upperBound < errorLocalizedString.endIndex {
                                if let endRange = errorLocalizedString.range(of: ")", range: methodRange.upperBound..<errorLocalizedString.endIndex), methodRange.upperBound < endRange.lowerBound {
                                    errorLocalizedString = errorLocalizedString.replacingCharacters(in: methodRange.upperBound..<endRange.lowerBound, with: "")
                                    errorMsg += errorLocalizedString
                                }
                            }

                        }

                        MailMessageListController.logger.error(errorMsg)
                    }
                    completionHandler?(res, error)
                }
            } else {
                guard let threadID = theWebView.identifier else { return }
                var queues = self?.pendingJavaScriptQueue[threadID] ?? []
                queues.append(javaScriptString)
                self?.pendingJavaScriptQueue[threadID] = queues
                MailMessageListController.logger.info("appendJS " + (jsMethod ?? "") + (" \(threadID)"))
            }
        }
    }

    func handleCopyContents(messageIDs: [String]) {
        for id in messageIDs {
            if let messageItem = viewModel.mailItem?.messageItems.first(where: { $0.message.id == id }) {
                let mailInfo = messageItem.auditMailInfo(ownerID: realViewModel.forwardInfo?.ownerUserId, isEML: isEML)
                accountContext.securityAudit.audit(type: .copyMailContent(mailInfo: mailInfo, copyContentTypes: [.RichText]))
            }
        }
    }
    
    func stopRecommendContact(args: [String: Any], in webView: WKWebView?) {
        self.accountContext.accountKVStore.set(true, forKey: "MailFeedList.stopRecommend")
        let event = NewCoreEvent(event: .email_focus_contact_recommend_banner_click)
        event.params = ["click":"not_recommend",
                        "target": "none",
                        "label_item": self.statInfo.newCoreEventLabelItem,
                        "mail_show_type": self.statInfo.from == .bot ? "mail_bot_window" : "",
                        "mail_account_type":Store.settingData.getMailAccountType()]
        event.post()
    }
    
    func closeContactRecommendBanner(args: [String: Any], in webView: WKWebView?) {
        guard let mailAddress = args["mailAddress"] as? String else {
            return
        }
        if var closeRecommendAddress : [String] = self.accountContext.accountKVStore.value(forKey: "MailFeedList.closeRecommend") {
            closeRecommendAddress.append(mailAddress)
            self.accountContext.accountKVStore.set(closeRecommendAddress, forKey: "MailFeedList.closeRecommend")
        }
        let event = NewCoreEvent(event: .email_focus_contact_recommend_banner_click)
        event.params = ["click":"close_banner",
                        "target": "none",
                        "label_item": self.statInfo.newCoreEventLabelItem,
                        "mail_show_type": self.statInfo.from == .bot ? "mail_bot_window" : "",
                        "mail_account_type":Store.settingData.getMailAccountType()]
        event.post()
        Store.fetcher?.banMailImportantContacts(addresses: [mailAddress])
            .subscribe(onNext: {(_) in
            MailLogger.info("[Mail Feed banImportantContacts] mailAddress: \(mailAddress)")
        }, onError: { (error) in
            MailLogger.info("[Mail Feed banImportantContacts] error: \(error)")
        }).disposed(by: self.disposeBag)
    }
    
    func currentVisualMessage(args: [String: Any], in webView: WKWebView?) {
        guard let visibleList = args["visibleList"] as? [[String: Any]],
              let firstTimestamp = visibleList.first?["timestamp"] as? String,
              let lastTimestamp = visibleList.last?["timestamp"] as? String,
              let firstTimestampInt = Int64(firstTimestamp),
              let lastTimestampInt = Int64(lastTimestamp),
              let firstMessageId = visibleList.first?["messageId"] as? String,
              self.isFeedCard == true else {
            return
        }
        do {
            // 负责保存展开态
            let visibleListData = try JSONSerialization.data(withJSONObject: visibleList, options: [])
            let visibleListSet : [String : Data] = [self.feedCardId : visibleListData]
            self.accountContext.accountKVStore.set(visibleListSet, forKey: "MailFeedList.visualListData")
            
            // 负责保存找到起始请求时间戳 提前9封 避免loading态触发
            // true为新邮件在顶部
            let smallestTimestamp : Int64 = Store.settingData.getCachedCurrentSetting()?.mobileMessageDisplayRankMode ?? false ? lastTimestampInt : firstTimestampInt
            
            let lastFifthTimestamp = findFifthTimestamp(messages: self.mailItem.messageItems, firstTimestamp: smallestTimestamp)
            let lastFifthTimestampSet : [String : Int64] = [self.feedCardId : lastFifthTimestamp]
            self.accountContext.accountKVStore.set(lastFifthTimestampSet, forKey: "MailFeedList.lastFifthTimestamp")
            MailLogger.info("[mail_feed] lastFifthTimestamp \(firstTimestampInt) feedCardId:\(self.feedCardId)")
            
            // 负责找到当前位置
            let lastMessageIdSet : [String: String] = [self.feedCardId : firstMessageId]
            self.accountContext.accountKVStore.set(lastMessageIdSet, forKey: "MailFeedList.lastMessageId")
            MailLogger.info("[mail_feed] lastMessageId \(firstMessageId) feedCardId: \(self.feedCardId)")
            
            
            MailLogger.info("Stored visualList in keyValueStore.")
        } catch {
            MailLogger.info("Failed to store visualList in keyValueStore: \(error)")
        }
        
        for messageItem in self.mailItem.messageItems {
            if let lastTimestampInt = Int64(lastTimestamp), let firstTimestampInt = Int64(firstTimestamp) {
                if messageItem.message.createdTimestamp <= max(lastTimestampInt,firstTimestampInt) && messageItem.message.createdTimestamp >= min(firstTimestampInt,lastTimestampInt) {
                    if messageItem.message.isRead != true && !readMessageList.contains(messageItem.message.id) {
                        if let feedItems = self.mailItem.feedMessageItems.first(where: {$0.item.message.id == messageItem.message.id}),
                           let labelId = MailTagDataManager.shared.getTagModels(feedItems.labelIds).first?.id {
                            readMessageList.append(messageItem.message.id)
                            self.unReadMessageCount = self.unReadMessageCount - 1
                            self.setTipsBtnNum(count: self.unReadMessageCount)
                            if self.unReadMessageCount == 0 {
                                self.isShowTipsBtn(hidden: true)
                            }
                            Store.fetcher?.multiMutLabelForThread(threadIds: [feedItems.threadID],
                                                                  messageIds: [messageItem.message.id],
                                                                  addLabelIds: [],
                                                                  removeLabelIds: [Mail_LabelId_UNREAD],
                                                                  fromLabelID: labelId)
                            .subscribe(onNext: {(_) in
                                MailLogger.info("[Mail Feed unReadMessageCount] unReadMessageCount: \(self.unReadMessageCount)")
                            }, onError: { (error) in
                                MailLogger.info("[Mail Feed unReadMessageCount] multiMutLabelForThread: \(error)")
                            }).disposed(by: self.disposeBag)
                        }
                    }
                }
            }
        }
    }
    
    private func unReadMessageCount(messages: [MailMessageItem], lastTimestamp: Int64) -> Int {
        let filteredMessages = messages.filter { $0.message.createdTimestamp > lastTimestamp }
        let unReadMessages = filteredMessages.filter { $0.message.isRead != true }.count
        return unReadMessages
    }
    
    // 找到当前看到的前五封邮件
    private func findFifthTimestamp(messages: [MailMessageItem], firstTimestamp: Int64) -> Int64 {
        let filteredMessages = messages.filter { $0.message.createdTimestamp <= firstTimestamp }
        let sortedMessages = filteredMessages.sorted { $0.message.createdTimestamp < $1.message.createdTimestamp }
        let timestamps = sortedMessages.map { $0.message.createdTimestamp }.sorted { $0 < $1 }
        let fifthTimestamp = timestamps.count >= 9 ? timestamps[timestamps.count - 9] : timestamps.first ?? 0
        // 时间戳往前一点点
        return fifthTimestamp - 5
    }
    // 找到当前所在邮件的messageId
    private func findCurrentMessageId(messages: [MailMessageItem], firstTimestamp: Int64) -> String {
        guard let messageId = messages.first(where: {$0.message.createdTimestamp == firstTimestamp})?.message.id else {
            return ""
        }
        return messageId
    }
    
    
    func loadMoreHandler(args: [String: Any], in webView: WKWebView?) {
        guard let isUp = args["isUp"] as? Bool,
              let isNewMessageAtTop = args["isNewMessageAtTop"] as? Bool,
              let messageID = args["messageID"] as? String,
              let timestamp = args["timestamp"] as? String else {
            return
        }
        // 调用loadFeedItem 请求更多数据
        let timestampOperator = (isUp && isNewMessageAtTop) || (!isUp && !isNewMessageAtTop) ? true : false
        if let timestampInt = Int64(timestamp) {
            self.loadFeedMailItem(feedCardId: self.viewModel.feedCardId, 
                                  timestampOperator: timestampOperator,
                                  timestamp: timestampInt,
                                  forceGetFromNet: false,
                                  isDraft: false) { (mailItem, hasMore) in
                // 追加loadMore数据
                let newMailMessageItems = Array(Set(self.mailItem.feedMessageItems + mailItem.feedMessageItems))
                    .sorted(by: { $0.item.message.createdTimestamp < $1.item.message.createdTimestamp })
                
                let newMailItem = MailItem(feedCardId: self.viewModel.feedCardId,
                                        feedMessageItems: newMailMessageItems,
                                        threadId: "",
                                        messageItems: [],
                                        composeDrafts: [],
                                        labels: [],
                                        code: .none,
                                        isExternal: true,
                                        isFlagged: false,
                                        isRead: false,
                                        isLastPage: false)
                self.refreshMessageList(with: newMailItem)
                // 停止动画
                self.callJSFunction("stopLoadMore", params: ["\(isUp)"])

                if(!hasMore){
                    // 隐藏loadMore组件
                    self.callJSFunction("loadMoreEnable", params: ["\(timestampOperator)", "\(false)"])
                }
            } errorCallBack: {
                self.callJSFunction("stopLoadMore", params: ["\(isUp)"])
            }
        }
    }
    
    // 重要联系人banner关注
    func followRecommendContact(args: [String: Any], in webView: WKWebView?) {
        guard let address = args["mailAddress"] as? String,
              let fromName = args["followName"] as? String else {
            return
        }
        var followeeInfo = Email_Client_V1_FolloweeInfo()
        var followeeID = Email_Client_V1_FolloweeID()
        followeeID.externalMailAddress.mailAddress = address
        followeeInfo.followeeID = followeeID
        followeeInfo.name = fromName
        let action : Email_Client_V1_FollowAction = .follow
        var showLoadingWorkItem: DispatchWorkItem?
        let event = NewCoreEvent(event: .email_focus_contact_recommend_banner_click)
        showLoadingWorkItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            UDToast.showLoading(with: BundleI18n.MailSDK.Mail_KeyContact_Following_Toast, on: self.view)
        }
        if var showLoadingWorkItem = showLoadingWorkItem {
            DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.normal, execute: showLoadingWorkItem)
        }
        event.params = ["click":"focus_now",
                        "target": "none",
                        "label_item": self.statInfo.newCoreEventLabelItem,
                        "mail_show_type": self.statInfo.from == .bot ? "mail_bot_window" : "",
                        "mail_account_type":Store.settingData.getMailAccountType()]
        event.post()
        self.requestUpdateFollowStatus(action: action, followeeList: [followeeInfo], showLoadingWorkItem: showLoadingWorkItem)
    }
    
    // 点击关注或者取关
    func clickFollow(args: [String: Any], in webView: WKWebView?) {
        guard let address = args["mailAddress"] as? String,
              let fromName = args["followName"] as? String,
              let followType = args["followAction"] as? String else {
            return
        }
        var followeeInfo = Email_Client_V1_FolloweeInfo()
        var followeeID = Email_Client_V1_FolloweeID()
        followeeID.externalMailAddress.mailAddress = address
        followeeInfo.followeeID = followeeID
        followeeInfo.name = fromName
        var action : Email_Client_V1_FollowAction = .unfollow
        var showLoadingWorkItem: DispatchWorkItem?
        let event = NewCoreEvent(event: .email_message_list_click)
        if followType == "follow" {
            action = .follow
            showLoadingWorkItem = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                UDToast.showLoading(with: BundleI18n.MailSDK.Mail_KeyContact_Following_Toast, on: self.view)
            }
            if var showLoadingWorkItem = showLoadingWorkItem {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: showLoadingWorkItem)
            }
            event.params = ["click":"focus_contact",
                            "target": "none",
                            "label_item": self.statInfo.newCoreEventLabelItem,
                            "mail_show_type": self.statInfo.from == .bot ? "mail_bot_window" : "",
                            "mail_account_type":Store.settingData.getMailAccountType()]
            event.post()
            self.requestUpdateFollowStatus(action: action, followeeList: [followeeInfo], showLoadingWorkItem: showLoadingWorkItem)
        } else if followType == "unfollow" {
            action = .unfollow
            showLoadingWorkItem = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                UDToast.showLoading(with: BundleI18n.MailSDK.Mail_FollowExternalEmailContacts_Unfollowing_Toast, on: self.view)
            }
            let alert = LarkAlertController()
            alert.setTitle(text: BundleI18n.MailSDK.Mail_KeyContact_UnfollowPopover_Title)
            alert.setContent(text: BundleI18n.MailSDK.Mail_KeyContact_UnfollowPopover_Desc(username: fromName, emailAddress: address))
            alert.addSecondaryButton(text: BundleI18n.MailSDK.Mail_KeyContact_UnfollowPopover_NotNow_Button)
            alert.addDestructiveButton(text: BundleI18n.MailSDK.Mail_KeyContact_UnfollowPopover_Unfollow_Button, dismissCompletion:  {
                if var showLoadingWorkItem = showLoadingWorkItem {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: showLoadingWorkItem)
                }
                event.params = ["click":"cancel_focus_contact",
                                "target": "none",
                                "label_item": self.statInfo.newCoreEventLabelItem,
                                "mail_show_type": self.statInfo.from == .bot ? "mail_bot_window" : "",
                                "mail_account_type":Store.settingData.getMailAccountType()]
                event.post()
                self.requestUpdateFollowStatus(action: action, followeeList: [followeeInfo], showLoadingWorkItem: showLoadingWorkItem)
            })
            self.navigator?.present(alert, from: self)
        }
    }
    
    func requestUpdateFollowStatus(action: Email_Client_V1_FollowAction, followeeList: [Email_Client_V1_FolloweeInfo], showLoadingWorkItem: DispatchWorkItem?) {
        MailDataSource.shared.fetcher?.updateFollowStatus(action: action, followeeList: followeeList)
        .observeOn(MainScheduler.instance)
        .subscribe { [weak self] resp in
            guard let self = self else { return }
            // 取消之前的 showLoadingWorkItem
            showLoadingWorkItem?.cancel()
            for followeeInfo in resp {
                let address = followeeInfo.followeeID.externalMailAddress.mailAddress
                let actionString = action == .follow ? "follow" : "unfollow"
                self.callJSFunction("updateFollowType", params: [address, actionString])
            }
            
            if action == .follow {
                UDToast.showSuccess(with: BundleI18n.MailSDK.Mail_KeyContact_Followed_Toast, on: self.view)
            } else if action == .unfollow {
                UDToast.showSuccess(with: BundleI18n.MailSDK.Mail_KeyContact_Unfollowed_Toast, on: self.view)
            }
            
        } onError: { [weak self] e in
            guard let self = self else { return }
            MailLogger.info("Failed to updateFollowType, error: \(e)")
            // 取消之前的 showLoadingWorkItem
            showLoadingWorkItem?.cancel()
            UDToast.showFailure(with: BundleI18n.MailSDK.Mail_KeyContact_FollowFailed_Toast, on: self.view)
        }.disposed(by: self.disposeBag)
    }

    func handleClickOnLink(args: [String: Any], in webView: WKWebView) {
        guard let messageID = args["messageID"] as? String,
              let href = args["href"] as? String,
              let messageItem = viewModel.mailItem?.messageItems.first(where: { $0.message.id == messageID }) else {
            return
        }
        let auditMailInfo = messageItem.auditMailInfo(ownerID: realViewModel.forwardInfo?.ownerUserId, isEML: isEML)
        accountContext.securityAudit.audit(type: .readMailClickURL(mailInfo: auditMailInfo, urlString: href))
    }

    func handleCalendarNeedUpdate(args: [String: Any], in webView: WKWebView) {
        guard let threadId = args["threadId"] as? String, let messageId = args["messageId"] as? String else {
            return
        }
        guard let vm = realViewModel[threadId: threadId] else {
            return
        }
        MailDataSource.shared.getCalendarEventDetail([messageId])
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] resp in
                guard let self = self else { return }
                if !self.isFeedCard {
                    self.threadRefresh(threadId: threadId, success: { [weak self] mailItem in
                        guard let self = self else { return }
                        self.updateCalendarCardFor(mailItem: mailItem, targetMessageId: messageId)
                    })
                } else {
                    var feedMessageItems = self.mailItem.feedMessageItems
                    if let calendarEventCard: MailCalendarEventInfo = resp[messageId],
                       var feedMessageItem = feedMessageItems.first(where: { $0.item.message.id == messageId }),
                       let index = feedMessageItems.firstIndex(where: { $0.item.message.id == messageId}) {
                        feedMessageItem.item.message.calendarEventCard = calendarEventCard
                        feedMessageItem.item.state.calendarState = .fill
                        feedMessageItems[index] = feedMessageItem
                        let newMailItem = MailItem(feedCardId: self.viewModel.feedCardId,
                                                   feedMessageItems: feedMessageItems,
                                                   threadId: "",
                                                   messageItems: [],
                                                   composeDrafts: [],
                                                   labels: [],
                                                   code: .none,
                                                   isExternal: true,
                                                   isFlagged: false,
                                                   isRead: false,
                                                   isLastPage: false)
                        self.updateCalendarCardFor(mailItem: newMailItem, targetMessageId: messageId)
                        self.refreshMessageList(with: newMailItem)
                    }
                    self.handleFeedMessageItemStatus(messageIDs: [messageId])
                }
            } onError: { [weak self] e in
                self?.updateCalendarCardFor(mailItem: vm.mailItem, targetMessageId: messageId)
            }.disposed(by: self.disposeBag)
    }

    func updateCalendarCardFor(mailItem: MailItem?, targetMessageId: String) {
        guard let mailItem = mailItem else {
            return
        }
        // 此时已经有日程状态了，进行更新
        let cardHTML: String
        if let messageItem = mailItem.messageItems.first(where: { $0.message.id == targetMessageId }), messageItem.state.calendarState == .fill {
            cardHTML = realViewModel.templateRender.getCalendarCardTemplate(mail: messageItem).cleanEscapeCharacter()
        } else {
            cardHTML = ""
        }

        callJSFunction("updateCalendarCard", params: [targetMessageId, cardHTML], withThreadId: mailItem.threadId)
    }

    func handleExitSearch() {
        exitContentSearch()
    }

    func replaceAtName(messageId: String, dic: [String: Any]) {
        var copyDic: [String: Any] = [:]
        for (key, value) in dic {
            if let name = value as? String {
                copyDic[key] = name
            } else {
                copyDic[key] = value
            }
        }
        guard let data = try? JSONSerialization.data(withJSONObject: copyDic, options: []),
                    let JSONString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else {
            MailLogger.error("replaceAtName parse err, id=\(messageId)")
                        return
                }
        let javaScriptString = "window.replaceAtName(`\(messageId)`, `\((JSONString as String).escapeString)`)"
        callJavaScript(javaScriptString)
    }

    func replaceHeaderFrom(messageId: String, fromName: String) {
        callJSFunction("replaceHeaderFrom", params: [messageId, fromName.escapeString])
    }

    func replaceHeaderTo(messageId: String, toList: String) {
        callJSFunction("replaceHeaderTo", params: [messageId, toList])
    }

    func replaceAddressName(messageId: String, dic: [String: String], type: String) {
        guard let data = try? JSONSerialization.data(withJSONObject: dic, options: []),
                    let JSONString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else {
            MailLogger.error("replaceAddressName parse err,id=\(messageId)")
                        return
                }
        callJSFunction("replaceAddressName", params: [messageId, (JSONString as String).escapeString, type])
    }

    func handleReportMessage(args: [String: Any]) {
        guard let messageID = args["messageID"] as? String else { return }
        let feedThreadId = self.mailItem.feedMessageItems.first(where: {$0.item.message.id == messageID})?.threadID ?? ""
        let feedLabels = self.mailItem.feedMessageItems.first(where: {$0.item.message.id == messageID})?.labelIds ?? []
        let feedLabelIds = MailTagDataManager.shared.getTagModels(feedLabels)
        let feedLabel = feedLabelIds.first?.id ?? self.fromLabel
        let threadId = self.isFeedCard ? feedThreadId : self.viewModel.threadId
        let labelId = self.isFeedCard ? feedLabel : self.fromLabel
        
        let messageItem = mailItem.messageItems.first(where: { $0.message.id == messageID })
        let isFromAuthorized = messageItem?.message.security.isFromAuthorized ?? true
        let address = messageItem?.message.from.address ?? ""
        let riskBannerReason = messageItem?.message.security.riskBannerReason ?? .default
        let riskBannerLevel = messageItem?.message.security.riskBannerLevel ?? .info
        let riskReason = riskReasonToString(riskReason: riskBannerReason)
        let riskLevel = riskLevelToString(riskLevel: riskBannerLevel)
        let hasExtern = messageItem?.message.security.isFromExternal ?? true
        let content = SpamAlertContent(
            threadIDs: [threadId],
            fromLabelID: fromLabel,
            mailAddresses: isFromAuthorized ? [address] : [],
            unauthorizedAddresses: !isFromAuthorized ? [address] : [],
            isAllAuthorized: isFromAuthorized,
            shouldFetchUnauthorized: false,
            scene: .message,
            allInnerDomain: !hasExtern
        )
        LarkAlertController.showSpamAlert(type: .markSpam, content: content, from: self, navigator: accountContext.navigator, userStore: accountContext.userKVStore) { [weak self] ignore in
            guard let self = self else { return }
            // callRust
            self.realViewModel.report.reportMessage(threadID: threadId, messageID: messageID, fromLabelID: labelId, messageCount: self.mailItem.messageItems.count, logLabelID: self.getLogLabelID(), ignoreUnauthorized: ignore, riskReason: riskReason, riskLevel: riskLevel, feedCardId: self.isFeedCard ? self.feedCardId : nil)
            if !self.isFeedCard {
                self.backItemTapped {
                    if let view = self.fromViewController?.view {
                        MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_MarkedAsSpam_Toast, on: view)
                    }
                }
            } else {
                MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_MarkedAsSpam_Toast, on: self.view)
            }
        }
    }

    func handleSendStatusButtonClick(args: [String: Any]) {
        if let id = args["messageId"],
           let messageId = id as? String,
           let messageItem = mailItem.messageItems.first(where: { $0.message.id == messageId }) {
            var mailShowType = ""
            if self.isFeedCard {
                mailShowType = "im_feed"
            } else if statInfo.from == .bot {
                mailShowType = "mail_bot_window"
            }
            let event = NewCoreEvent(event: .email_message_list_click)
            event.params = ["click": "send_status",
                            "target": "none",
                            "status": messageItem.message.sendState.rawValue,
                            "label_item": statInfo.newCoreEventLabelItem,
                            "is_trash_or_spam_list": statInfo.isTrashOrSpamList,
                            "mail_show_type": mailShowType]
            event.post()
            if messageItem.message.deliveryState == .pending ||
                messageItem.message.sendState == .unknownSendState {
                let text = BundleI18n.MailSDK.Mail_Send_NoDetailsFound
                MailRoundedHUD.showTips(with: text, on: self.view)
            } else if MailMessageListController.checkSendStatusDurationValid(timestamp: TimeInterval(messageItem.message.createdTimestamp / 1000)) {
                let feedThreadId = self.mailItem.feedMessageItems.first(where: {$0.item.message.id == messageId})?.threadID ?? ""
                let feedLabels = self.mailItem.feedMessageItems.first(where: {$0.item.message.id == messageId})?.labelIds ?? []
                let feedLabelIds = MailTagDataManager.shared.getTagModels(feedLabels)
                let feedLabel = feedLabelIds.first?.id ?? self.fromLabel
                let threadId = self.isFeedCard ? feedThreadId : self.viewModel.threadId
                let labelId = self.isFeedCard ? feedLabel : viewModel.labelId
                self.enterSendStatusVC(messageId: messageId,
                                           threadId: threadId,
                                           labelId: labelId)
            } else {
                let text = BundleI18n.MailSDK.Mail_Send_OverDaysCantViewDetails
                MailRoundedHUD.showTips(with: text, on: self.view)
            }
        }
    }

    static func checkSendStatusDurationValid(timestamp: TimeInterval) -> Bool {
        let duration = Date().timeIntervalSince1970 - timestamp
        let daysLimit: Double = 30
        if duration <= 60 * 60 * 24 * daysLimit {// 小于30天
            return true
        }
        return false
    }

    private func riskLevelToString(riskLevel:RustPB.Email_Client_V1_RiskLevel) -> String {
        switch riskLevel {
        case .danger:
            return "danger"
        case .info:
            return "info"
        case .warning1:
            return "warning1"
        @unknown default:
            return ""
        }
    }

    private func riskReasonToString(riskReason: RustPB.Email_Client_V1_RiskReason) -> String {
        switch riskReason {
            /// 相似域名仿冒
        case .impersonateDomain:
            return "impersonateDomain"
            /// KP姓名仿冒
        case .impersonateKpName:
            return "impersonateKpName"
            /// 未认证的内部域名
        case .unauthInternal:
            return "unauthInternal"
            /// 未认证的外部域名
        case .unauthExternal:
            return "unauthExternal"
            /// 恶意链接
        case .maliciousURL:
            return "maliciousURL"
            /// 高危附件
        case .maliciousAttachment:
            return "maliciousAttachment"
            /// 钓鱼
        case .phishing1:
            return "phishing1"
            /// 仿冒合作伙伴
        case .impersonatePartner:
            return "impersonatePartner"
            /// 外部邮件，携带加密附件
        case .externalEncryptionAttachment:
            return "externalEncryptionAttachment"
        case .default:
            return "default"
        @unknown default:
            return "default"
        }
    }

    func handleTrustMessage(args: [String: Any]) {
        guard let messageID = args["messageID"] as? String else { return }
        let messageItem = mailItem.messageItems.first(where: { $0.message.id == messageID })
        let isFromAuthorized = messageItem?.message.security.isFromAuthorized ?? true
        let address = messageItem?.message.from.address ?? ""
        let riskBannerReason = messageItem?.message.security.riskBannerReason ?? .default
        let riskBannerLevel = messageItem?.message.security.riskBannerLevel ?? .info
        let riskReason = riskReasonToString(riskReason: riskBannerReason)
        let riskLevel = riskLevelToString(riskLevel: riskBannerLevel)
        let hasExtern = messageItem?.message.security.isFromExternal ?? true
        let content = SpamAlertContent(
            threadIDs: [viewModel.threadId],
            fromLabelID: fromLabel,
            mailAddresses: isFromAuthorized ? [address] : [],
            unauthorizedAddresses: !isFromAuthorized ? [address] : [],
            isAllAuthorized: isFromAuthorized,
            shouldFetchUnauthorized: false,
            scene: .message,
            allInnerDomain: !hasExtern
        )
        LarkAlertController.showSpamAlert(type: .markNormal, content: content, from: self, navigator: accountContext.navigator, userStore: accountContext.userKVStore) { [weak self] ignore in
            guard let self = self else { return }
            // callRust
            self.realViewModel.report.trustMessage(threadID: self.viewModel.threadId, messageID: messageID, fromLabelID: self.fromLabel, messageCount: self.mailItem.messageItems.count, logLabelID: self.getLogLabelID(), ignoreUnauthorized: ignore, riskReason: riskReason, riskLevel: riskLevel, feedCardId: self.feedCardId)
        }
    }

    func handleCloseSafetyBanner(args: [String: Any]) {
        guard let messageID = args["messageID"] as? String else { return }
        let messageItem = mailItem.messageItems.first(where: { $0.message.id == messageID })
        let riskBannerReason = messageItem?.message.security.riskBannerReason ?? .default
        let riskBannerLevel = messageItem?.message.security.riskBannerLevel ?? .info
        let riskReason = riskReasonToString(riskReason: riskBannerReason)
        let riskLevel = riskLevelToString(riskLevel: riskBannerLevel)
        
        let feedThreadId = self.mailItem.feedMessageItems.first(where: {$0.item.message.id == messageID})?.threadID ?? ""
        let feedLabels = self.mailItem.feedMessageItems.first(where: {$0.item.message.id == messageID})?.labelIds ?? []
        let feedLabelIds = MailTagDataManager.shared.getTagModels(feedLabels)
        let feedLabel = feedLabelIds.first?.id ?? self.fromLabel
        let threadId = self.isFeedCard ? feedThreadId : self.viewModel.threadId
        let labelId = self.isFeedCard ? feedLabel : self.fromLabel
        // callRust
        realViewModel.report.closeSafetyBanner(threadID: threadId, messageID: messageID, fromLabelID: labelId, logLabelID: getLogLabelID(), riskReason: riskReason, riskLevel: riskLevel, feedCardId: self.isFeedCard ? self.feedCardId : nil)
    }

    func handleSearchResults(args: [String: Any], in webView: WKWebView) {
        guard let key = args["key"] as? String, let searchType = args["searchType"] as? Int, let resultInfo = args["resultInfo"] as? [[String: Any]] else {
            return
        }
        let idx = (args["idx"] as? Int) ?? 0
        realViewModel.search.onJSSearchDone(searchKey: key, searchType: searchType, idx: idx, resultInfo: resultInfo)
    }

    func handlejsSearchStart() {
        realViewModel.search.handleJSSearchStart()
    }

    func handleNeedContent(args: [String: Any], in webView: WKWebView) {

        guard let msgIDs = args["msgIDs"] as? [String], msgIDs.count > 0 else { return }
        enum NeedContentType: Int {
            case normal
            case search
        }
        if let type = NeedContentType(rawValue: args["type"] as? Int ?? 0) {
            switch type {
            case .normal:
                callJs_addItemContent(msgIDs: msgIDs)
            case .search:
                realViewModel.search.preSearch(notLoadedMsgIDs: msgIDs)
            }
        }
    }

    func handleFixScaleFinish(_ webView: WKWebView) {
        guard let theWebView = webView as? (WKWebView & MailBaseWebViewAble),
              let pageCell = theWebView.weakRef.superContainer as? MailMessageListPageCell else {
            return
        }
        /// delay, 避免操作时webview native scrollView没渲染成功
        DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.short) { [weak pageCell] in
            guard let pageCell = pageCell else { return }
            pageCell.mailMessageListView?.handleWebScrollViews()
        }
    }

    func handleScrollTo(args: [String: Any], in webView: WKWebView) {
        guard let offsetY = args["offsetY"] as? CGFloat else { return }
        webView.scrollView.setContentOffset(CGPoint(x: 0, y: offsetY), animated: true)
    }

    func handleCancelScheduleSendClick(args: [String: Any], in webView: WKWebView?, source: String?) {
        guard !cancellingScheduleSend else { return }
        MailRoundedHUD.showLoading(with: BundleI18n.MailSDK.Mail_Toast_Loading, on: self.view, disableUserInteraction: false)
        cancellingScheduleSend = true
        MailLogger.info("mail cancel schedule send handle")
        MailTracker.log(event: "email_thread_scheduledSend_cancel", params: ["source": source ?? ""])
        guard let messageId = args["messageID"] as? String else { return }
        let feedCardId = self.feedCardId.isEmpty ? nil : self.feedCardId
        MailDataServiceFactory.commonDataService?.cancelScheduleSend(by: messageId, threadIds: [], feedCardID: feedCardId)
        .subscribe(onNext: { [weak self] (response) in
            guard let self = self else { return }
            self.cancellingScheduleSend = false
            MailLogger.info("mail cancel schedule send success")
            MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_SendLater_Cancelsucceed, on: self.view)
        }, onError: { [weak self] (err) in
            guard let self = self else { return }
            self.cancellingScheduleSend = false
            MailLogger.error("mail cancel schedule send error messageId \(messageId)")
            MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_SendLater_CancelFailure,
                                       on: self.view, event: ToastErrorEvent(event: .schedule_send_cancel_fail))
        }).disposed(by: disposeBag)
    }

    func handleTrack(args: [String: Any], in webView: WKWebView) {
        guard let event = args["event"] as? String else { return }
        var params = args["params"] as? [String: Any] ?? [:]
        let handledEvents = ["template_image_download_time_dev", "template_check_content_layout_dev", "email_read_fix_scale_dev"]
        if handledEvents.contains(event), let threadID = (webView as? MailBaseWebViewAble)?.identifier, threadID == viewModel.threadId {
            // 图片下载，添加当前页面判断。判断是否当前页面
            params["isCurrentThread"] = 1
        }
        MailTracker.log(event: event, params: params)
    }

    func handleSendToChatDraft(msgID: String, action: Email_Client_V1_MailCreateDraftRequest.CreateDraftAction) {
        guard let forwardInfo = realViewModel.forwardInfo else { mailAssertionFailure("must have forwardinfo in chat"); return }
        MailRoundedHUD.showLoading(on: self.view)
        let messageItem = mailItem.getMessageItem(by: msgID)
        guard let msgTimestamp = messageItem?.message.createdTimestamp else {
            mailAssertionFailure("must have lastUpdatedTimestamp")
            return
        }
        MailDataServiceFactory.commonDataService?.getForwardMsgDraft(msgID: msgID,
                                                   ownerId: forwardInfo.ownerUserId,
                                                   timestamp: msgTimestamp / 1000,
                                                   cardID: forwardInfo.cardId,
                                                   action: action, languageId: messageItem?.message.localeLanguage).subscribe(onNext: { [weak self] (response) in
                                                    guard let self = self else { return }
                                                    MailRoundedHUD.remove(on: self.view)

            // Must use this permCode to overwrite, because the code may change when user stay in this view controller but no change log will be received.
            self.mailItem.code = response.permissionCode
            let draft = MailDraft(with: response.draft)

            if response.canReply {
                self.showInterceptSendAlertIfNeeded(messageID: msgID, action: action.getSendAction()) { [weak self] (needBlockImage, isCancel) in
                    guard let self = self else { return }
                    guard !isCancel else { return }
                    if let vc = MailSendController.checkMailTab_makeSendNavController(accountContext: self.accountContext,
                                                                                      threadID: self.viewModel.threadId,
                                                                                      messageID: msgID,
                                                                                      action: action == .forward ? .sendToChat_Forward : .sendToChat_Reply,
                                                                                      labelId: self.viewModel.labelId,
                                                                                      draft: draft,
                                                                                      statInfo: MailSendStatInfo(from: .messageReply, newCoreEventLabelItem: self.statInfo.newCoreEventLabelItem),
                                                                                      trackerSourceType: MailTracker.SourcesType.messageActionReply,
                                                                                      ondiscard: self.makeDiscardDraftCallback(),
                                                                                      mailItem: self.mailItem,
                                                                                      msgStatInfo: self.statInfo,
                                                                                      isNewDraft: response.isNew,
                                                                                      needBlockWebImages: needBlockImage,
                                                                                      fileBannedInfos: self.viewModel.fileBannedInfos,
                                                                                      feedCardId: self.feedCardId) {
                        MailTracker.log(event: "email_share_card_reply_result_view", params: ["result": "success_to_edit", "target": "none", "mail_account_type": Store.settingData.getMailAccountType()])
                        self.navigator?.present(vc, from: self, completion: { [weak self] in
                            self?.popSelf(animated: false, dismissPresented: false, completion: nil)
                        })
                    } else {
                        MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_Share_Notrcptoast,
                                                   on: self.view, event: ToastErrorEvent(event: .read_forward_not_recipient_fail))
                        MailTracker.log(event: "email_share_card_reply_result_view", params: ["result": "not_receiver", "target": "none", "mail_account_type": Store.settingData.getMailAccountType()])
                    }
                }
            } else {
                MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_Share_Notrcptoast,
                                           on: self.view, event: ToastErrorEvent(event: .read_forward_not_recipient_fail))
                MailTracker.log(event: "email_share_card_reply_result_view", params: ["result": "not_receiver", "target": "none", "mail_account_type": Store.settingData.getMailAccountType()])
            }
        }, onError: { [weak self] (err) in
            guard let self = self else { return }
            MailLogger.error("getForwardMsgDraft error \(err)")
            MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_Share_Notrcptoast,
                                       on: self.view, event: ToastErrorEvent(event: .read_forward_not_recipient_fail))
        }).disposed(by: disposeBag)
    }
    
    func showInterceptSendAlertIfNeeded(messageID: String, action: MailSendAction, completion: @escaping (_ needBlockImage: Bool, _ isCancel: Bool) -> Void) {
        if accountContext.featureManager.open(.interceptWebImage, openInMailClient: true),
           viewModel.mailItem?.messageItems.first(where: { $0.message.id == messageID }) != nil
        {
            if fromLabel == Mail_LabelId_Spam {
                completion(true, false)
            } else {
                MailDataServiceFactory.commonDataService?.checkMessageHasDraft(messageID: messageID)
                    .subscribe { [weak self] (hasDraft) in
                        MailLogger.info("check has draft: \(hasDraft)")
                        if hasDraft {
                            completion(false, false)
                        } else {
                            self?._showInterceptSendAlert(messageID: messageID, action: action) { (needBlockImage, isCancel) in
                                completion(needBlockImage, isCancel)
                            }
                        }

                    } onError: { [weak self] (_) in
                        self?._showInterceptSendAlert(messageID: messageID, action: action) { (needBlockImage, isCancel) in
                            completion(needBlockImage, isCancel)
                        }
                    }.disposed(by: self.disposeBag)
            }
        } else {
            completion(false, false)
        }
    }

    func showStrangerReplyAlertIfNeeded(messageID: String, action: MailSendAction,
                                        completion: @escaping (_ needHandleStrangerCard: Bool, _ needReply: Bool) -> Void) {
        guard fromLabel == Mail_LabelId_Stranger && accountContext.featureManager.open(.stranger, openInMailClient: false) else {
            completion(false, true)
            return
        }
        if accountContext.userKVStore.bool(forKey: "MailStrangerReplyAlert.dontShowAlert") {
            completion(true, true)
        } else {
            LarkAlertController.showReplyAlert(from: self, navigator: accountContext.navigator, userStore: accountContext.userKVStore) { reply in
                completion(true, reply)
            }
        }
    }
    
    func presentSendVC(msgID: String, draft: MailDraft?, source: MailTracker.SourcesType, action: MailSendAction, sendStatInfo: MailSendStatInfo, needBlockImage: Bool, closeHandler: (() -> Void)?, completion: @escaping (() -> Void)) {
        let languageIdentifier = viewModel.mailItem?.messageItems.first(where: { $0.message.id == msgID })?.message.localeLanguage// languageIdentifier
        // 区分feed情况 回传threadId
        let feedMessageItemThreadID = self.mailItem.feedMessageItems.first(where: { $0.item.message.id == msgID})?.threadID
        let isFeedCard = viewModel.mailItem?.feedCardId != "" && viewModel.threadId.isEmpty && self.accountContext.featureManager.open(FeatureKey(fgKey: .mailToFeed, openInMailClient: false))
        let threadId = isFeedCard ? feedMessageItemThreadID : viewModel.threadId
        let vc = MailSendController.makeSendNavController(
            accountContext: accountContext,
            threadID: threadId,
            messageID: msgID,
            action: action,
            labelId: viewModel.labelId,
            draft: draft,
            statInfo: sendStatInfo,
            trackerSourceType: source,
            ondiscard: makeDiscardDraftCallback(),
            mailItem: mailItem,
            msgStatInfo: statInfo,
            languageId: languageIdentifier,
            needBlockWebImages: needBlockImage,
            fileBannedInfos: viewModel.fileBannedInfos,
            closeHandler: closeHandler,
            feedCardId: self.feedCardId)
        navigator?.present(vc, from: self, completion: completion)
    }

    func makeDiscardDraftCallback() -> DiscardCallback {
        let discardCallback: DiscardCallback = { [weak self] (draftID: String) in
            self?.deleteLocalDraft(draftID: draftID)
        }
        return discardCallback
    }

    func updateMessageItems(with newMailItem: MailItem) {
        var updateItem = newMailItem
        /// if current mailItem not fetched, don't update mail Item
        if mailItem.messageItems.isEmpty && self.feedCardId.isEmpty {
            return
        }
        /// if is full read message, don't update mail Item
        if viewModel.isFullReadMessage, viewModel.fullReadMessageId != nil {
            return
        }

        /// if user click undo send,  previous message should delete
        let messageIds = updateItem.messageItems.map { $0.message.id }
        let needDeleteMessageIds = self.mailItem.messageItems.filter { !messageIds.contains($0.message.id) }.map { $0.message.id }
        if !needDeleteMessageIds.isEmpty {
            needDeleteMessageIds.forEach { (messageId) in
                let deletejsstring = "window.deleteMessage('\(messageId)')"
                callJavaScript(deletejsstring)
            }
            MailLogger.info("message list delete message count: \(needDeleteMessageIds.count)")
        }

        /// filter new message
        let filteredItems = newMailItem.messageItems.filter({ [weak self] (item) -> Bool in
            guard let self = self else { return false }
            return !self.mailItem.messageItems.contains(where: { (localItem) -> Bool in
                localItem.message.id == item.message.id
            })
        })
        var isPushNewMessage = false
        if let lastNewMsgItem = filteredItems.max(by: { $0.message.createdTimestamp < $1.message.createdTimestamp }),
           let lastLacalMsgItem = self.mailItem.messageItems.max(by: { $0.message.createdTimestamp < $1.message.createdTimestamp }) {
            if lastNewMsgItem.message.createdTimestamp > lastLacalMsgItem.message.createdTimestamp {
                isPushNewMessage = true
            }
        } else if self.mailItem.messageItems.isEmpty && !filteredItems.isEmpty {
            isPushNewMessage = true
        }
        let filteredFeedItems = newMailItem.feedMessageItems.filter({ [weak self] (item) -> Bool in
            guard let self = self else { return false }
            return !self.mailItem.feedMessageItems.contains(where: { (localItem) -> Bool in
                localItem.item.message.id == item.item.message.id
            })
        })
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            if self.isFeedCard {
                updateItem.feedMessageItems = filteredFeedItems
            }
            updateItem.messageItems = filteredItems.map({ (origin) -> MailMessageItem in
                var newItem = origin
                newItem.message.bodyHtml = MailMessageListTemplateRender.preprocessHtml(newItem.message.bodyHtml,
                                                                                        messageID: newItem.message.id,
                                                                                        messageItem: newItem,
                                                                                        isFromChat: self.isForwardCard(),
                                                                                        sharedService: self.accountContext.sharedServices)
                return newItem
            })
            if updateItem.messageItems.count > 0 {
                MailLogger.info("updateMessageItems for \(updateItem.threadId)")
                for messageItem in updateItem.messageItems {
                    // 先删除对应的草稿
                    let messageid = messageItem.message.id
                    MailLogger.info("updateMessageItems deleteDraft, msg: \(messageid)")
                    self.callJSFunction("deleteDraft", params: [messageid], withThreadId: updateItem.threadId)
                }
                self.realViewModel.templateRender.replaceForMessageList(by: self.getRenderModel(by: self.viewModel, mailItem: updateItem, lazyLoadMessage: false, isPushNewMessage: isPushNewMessage),isUpdate: true) { [weak self] (messageListHtml) in
                    let template = messageListHtml.cleanEscapeCharacter()
                    if updateItem.feedCardId.isEmpty {
                        self?.callJSFunction("updateMessageItems", params: [template], withThreadId: updateItem.threadId)
                    } else {
                        self?.callJSFunction("updateMessageItems", params: [template, "\(true)"])
                    }
                }
            }
            MailLogger.info("message list update message count: \(updateItem.messageItems.count)")
        }
    }

    func updateDrafts(with newMailItem: MailItem, oldMailItem: MailItem) {
        let newDrafts = newMailItem.messageItems.filter { !$0.drafts.isEmpty }.flatMap { $0.drafts }
        let oldDraftsIds = oldMailItem.messageItems.filter { !$0.drafts.isEmpty }.flatMap { $0.drafts.map { $0.id } }
        if newDrafts.isEmpty && oldDraftsIds.isEmpty { return }

        if newDrafts.isEmpty {
            oldDraftsIds.forEach { callJSFunction("deleteDraft", params: [$0]) }
        } else {
            let newDraftIds = newDrafts.map { $0.id }
            oldDraftsIds.forEach { (draftId) in
                if !newDraftIds.contains(draftId) {
                    callJSFunction("deleteDraft", params: [draftId])
                }
            }
            newDrafts.forEach { mailMessageDraftUpdate(MailDraft(with: $0)) }
        }
    }

    func mailMessageDraftUpdate(_ draft: MailDraft) {
        guard statInfo.from != .chat, !self.isFeedCard else {
            return
        }
        if let setting = Store.settingData.getCachedCurrentSetting(), setting.enableConversationMode,
           !Store.settingData.mailClient {
            updateDraft(draft)
        }
    }

    private func updateDraft(_ draft: MailDraft) {
        let draftItem = realViewModel.templateRender.createDraftItem(draft, mailItem: mailItem, myUserId: accountContext.user.userID ?? "0")
        let msgID: String
        msgID = draft.replyToMailID
        let jsstring = "window.updateDraft('\(msgID)', '\(draftItem)')"
        callJavaScript(jsstring)
        // 添加draft到messageItem
        for (index, item) in self.mailItem.messageItems.enumerated() where item.message.id == msgID {
            self.mailItem.messageItems[index].drafts.removeAll()
            let clientDraft = draft.toPBModel()
            self.mailItem.messageItems[index].drafts.append(clientDraft)
        }
    }

    func downloadAttachment(args: [String: Any], in webView: WKWebView?) {
        if let msgId = args["messageID"] as? String,
           let fileToken = args["file_token"] as? String {
            if Store.settingData.mailClient, statInfo.from != .chat {
                let attachment = mailItem.messageItems.first(where: { $0.message.id == msgId})?.message.attachments.first(where: {$0.fileToken == fileToken})
                let name = attachment?.fileName ?? ""
                rustDownloadAttachment(token: fileToken, msgId: msgId, name: name)
            } else {
                MailLogger.error("[mail_client_att] downloadAttachment error logic")
            }
        }
    }

    func cancelAttachmentDownload(args: [String: Any], in webView: WKWebView?) {
        if let msgId = args["messageID"] as? String,
           let fileToken = args["file_token"] as? String, Store.settingData.mailClient, statInfo.from != .chat {
            let existTable = accountContext.imageService._rustTaskTable
            if let respKey = existTable.keys.first(where: { existTable[$0]?.fileToken == fileToken }) {
                MailDataSource.shared.fetcher?.mailCancelDownload(respKey: respKey)
                    .subscribe(onNext: { _ in
                        MailLogger.info("[mail_client_att] mailCancelDownload attachment success: \(respKey)")
                    }, onError: { (error) in
                        MailLogger.error("[mail_client_att] mailCancelDownload error: \(error)")
                    }).disposed(by: self.disposeBag)
                cancelDownload(msgId: msgId, fileToken: fileToken, in: webView)
                accountContext.imageService.removeRespKey(respKey)
            } else {
                MailLogger.error("[mail_client_att] cancelAttachmentDownload respKey is nil")
            }
        } else {
            MailLogger.error("[mail_client_att] cancelAttachmentDownload msgID: \(args["messageID"] ?? "") token: \(args["file_token"] ?? "")")
        }
    }

    private func cancelDownload(msgId: String, fileToken: String, in webView: WKWebView?) {
        MailLogger.info("[mail_client_att] msglist cancelDownload msgId: \(msgId) fileToken: \(fileToken)")
        webView?.evaluateJavaScript("window.updateAttachmentState('\(msgId)', '\(fileToken)', '1', '0', '0')")
    }

    func openAttachment(args: [String: Any], in webView: WKWebView?) {
        guard let messageID = args["messageID"] as? String, let targetMail = mailItem.messageItems.first(where: { $0.message.id == messageID }) else {
            let id = args["messageID"] as? String ?? ""
            MailLogger.error("openAttachment without message: \(id)")
            return
        }
        MailTracker.log(event: Homeric.EMAIL_MESSAGE_ATTACHMENT_PREVIEW, params: [:])

        /// @zhaoxiongbin同学说很合理 优先级需要先这样调整
        if let localAttachmentPath = args["file_url"] as? String, FileOperator.isExist(at: localAttachmentPath), localAttachmentPath != "" {
            // eml 预览打开本地附件.
            let targetAttachment = targetMail.message.attachments.first(where: { $0.fileURL == localAttachmentPath })
            if let attachment = targetAttachment {
                let url = URL(fileURLWithPath: localAttachmentPath)
                attachmentPreviewRouter.startLocalPreviewViaDrive(
                    typeStr: attachment.fileType,
                    fileURL: url,
                    fileName: attachment.fileName,
                    mailInfo: targetMail.auditMailInfo(ownerID: realViewModel.forwardInfo?.ownerUserId, isEML: isEML),
                    from: self,
                    origin: "mailDetail"
                )
            }
            if statInfo.from == .emailReview {
                // 审核附件预览打点
                MailTracker.log(event: "email_mail_audit_process_detail_click", params: ["click": "attachment_preview"])
            }
        } else if let filePath = args["file_url"] as? String,
                  let fileToken = args["file_token"] as? String, Store.settingData.mailClient, statInfo.from != .chat {
            let targetAttachment = targetMail.message.attachments.first(where: { $0.fileToken == fileToken })
            let name = targetAttachment?.fileName ?? ""
            openAttachmentInThirdParty(filePath: filePath, cid: fileToken, name: name)
        } else if let fileToken = args["file_token"] as? String {
            // Saas读信点击了附件
            if let attachment = targetMail.message.attachments.first(where: { $0.fileToken == fileToken }) {
                var mailShowType = ""
                if self.isFeedCard {
                    mailShowType = "im_feed"
                } else if statInfo.from == .bot {
                    mailShowType = "mail_bot_window"
                }
                let event = NewCoreEvent(event: .email_message_list_click)
                event.params = ["target": "none",
                                "click": "attachment_preview",
                                "is_large": attachment.type == .large ? "true" : "false",
                                "label_item": statInfo.newCoreEventLabelItem,
                                "is_trash_or_spam_list": statInfo.isTrashOrSpamList,
                                "attachment_position": Store.settingData.getCachedPrimaryAccount()?.mailSetting.attachmentLocation == .top ? "message_top": "message_bottom",
                                "mail_show_type": mailShowType]
                event.post()
                let expireTime = attachment.expireTime / 1000
                if attachment.type == .large, expireTime != 0, expireTime < Int64(Date().timeIntervalSince1970) {
                    let timeStr = ProviderManager.default.timeFormatProvider?.mailAttachmentTimeFormat(expireTime) ?? ""
                    MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_Attachment_CantViewDesc(timeStr), on: view)
                    return
                }
                // 如果 fileName 有英文以外的字符, 这个方法会对 fileName 进行百分号编码, 所以 url.pathExtension 是安全的.
                let url = URL(fileURLWithPath: attachment.fileName)
                // 风险附件，超大附件管理2期将检测接口合并了，存储数据的位置不同
                var isRisk = false
                if accountContext.featureManager.open(.largeAttachmentManagePhase2, openInMailClient: false) {
                    isRisk = viewModel.fileBannedInfos[attachment.fileToken]?.status == .highRisk
                } else {
                    isRisk = viewModel.fileRiskTags[attachment.fileToken]?.isRiskFile == true
                }
                attachmentPreviewRouter.startOnlinePreview(fileToken: attachment.fileToken,
                                                           name: attachment.fileName,
                                                           fileSize: Int64(attachment.fileSize),
                                                           typeStr: url.pathExtension,
                                                           isLarge: attachment.type == .large,
                                                           isRisk: isRisk,
                                                           isOwner: viewModel.fileBannedInfos[attachment.fileToken]?.isOwner == true,
                                                           isBanned: viewModel.fileBannedInfos[attachment.fileToken]?.isBanned == true,
                                                           isDeleted:viewModel.fileBannedInfos[attachment.fileToken]?.status == .deleted,
                                                           mailInfo: targetMail.auditMailInfo(ownerID: realViewModel.forwardInfo?.ownerUserId, isEML: isEML),
                                                           fromVC: self,
                                                           origin: "mailDetail")
            } else {
                MailLogger.error("openAttachment attachment not found: \(targetMail.message.id)")
            }
        }
    }

    private func rustDownloadAttachment(token: String, msgId: String, name: String) {
        // 第三方客户端读信点击附件的处理
        if let reachablility = Reachability(), reachablility.connection == .none {
            MailLogger.info("[mail_client_att] network none at msgList")
            MailRoundedHUD.showTips(with: BundleI18n.MailSDK.Mail_ThirdClient_AttachmentFailedRetry, on: self.view)
            return
        }
        downloadDisposeBag = DisposeBag()
        MailDataSource.shared.mailDownloadRequest(token: token, messageID: msgId, isInlineImage: false)
            .subscribe(onNext: { [weak self] (resp) in
                guard let self = self else { return }
                MailLogger.info("[mail_client_att] webview mail download attachment for preview resp key: \(resp.key) has filePath: \(!resp.filePath.isEmpty)")
                if !resp.filePath.isEmpty {
                    let localPath: String
                    if !AbsPath(resp.filePath).exists {
                        localPath = resp.filePath.correctPath
                    } else {
                        localPath = resp.filePath
                    }
                    MailRoundedHUD.remove(on: self.view)
                    self.attachmentPreviewRouter.startLocalPreviewViaDrive(typeStr: localPath.extension, fileURL: URL(fileURLWithPath: localPath),
                                                                           fileName: name, mailInfo: nil, from: self, origin: "mailDetail")
                    if let theWK = self.getPageCellOf(msgId: msgId)?.mailMessageListView?.webview {
                        theWK.evaluateJavaScript("window.updateAttachmentState('\(msgId)', '\(token)', '0', '\(100)', '\(100)')")
                    }
                } else {
                    let taskWrapper = RustSchemeTaskWrapper(task: nil, webURL: nil)
                    taskWrapper.key = resp.key
                    taskWrapper.msgID = msgId
                    taskWrapper.fileToken = token
                    taskWrapper.inlineImage = false
                    taskWrapper.downloadChange = MailDownloadPushChange(status: .pending, key: resp.key)
                    self.accountContext.imageService.startDownTask((resp.key, taskWrapper))
                }
            }, onError: { [weak self] (error) in
                MailLogger.error("[mail_client_att] webview mail download attachment error: \(error)")
                guard let self = self else { return }
                MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_ThirdClient_AttachmentFailedRetry, on: self.view)
            }).disposed(by: self.downloadDisposeBag)
    }

    private func openAttachmentInThirdParty(filePath: String, cid: String, name: String) {
        let msgId = accountContext.imageService.imageAdapter.getMsgIdFromSrc(filePath)
        MailLogger.info("[mail_client_att] webview mail download attachment for preview cid: \(cid.md5()) msgid: \(msgId) filePath: \(filePath)")
        rustDownloadAttachment(token: cid, msgId: msgId, name: name)
    }

    /// context : 二期 将risk接口与banned接口基于banned接口合并，并新增被删除态
    /// bannedInfo:
    /// required bool is_owner = 1;
    /// required bool is_banned = 2;
    /// optional bool is_high_risk = 3;
    /// optional bool is_deleted = 4;
    func handleCheckAttachmentNewBannedInfo(messageIDs: [String]) {
        let attachments = mailItem.messageItems.filter({ messageIDs.contains($0.message.id) })
            .flatMap { $0.message.attachments }
            .filterDuplicates({$0})
        if !attachments.isEmpty {
            // 先判断需不需要拉数据，当找不到某个 fileToken 对应的封禁信息时，一次性拉取整个 thread 的附件封禁信息
            getAttachmentBannedInfoIfNeeded(attachments.map{ $0.fileToken }) { [weak self] in
                // 等待数据拉取完再进行后续操作
                var warningItemsInfo: [[String: Any]] = [] // 用于文件Owner展示“发现违规内容”
                var statusItemsInfo: [[String: Any]] = [] // 用于文件收件人展示“已失效”
                var bannedFileOwnerCount = 0 // 计数用于上报
                var bannedFileCustomerCount = 0 // 计数用于上报
                var riskFileCount = 0 // 计数用于上报
                for attachment in attachments {
                    // 跳过没有 fileToken 的附件（本地附件）
                    if attachment.fileToken.isEmpty {
                        continue
                    }
                    if let bannedInfo = self?.viewModel.fileBannedInfos[attachment.fileToken] {
                        if bannedInfo.status == .deleted { // 待删除
                            let warningInfo = ["fileToken": attachment.fileToken,
                                               "warningType": "warning",
                                               "warningTip": BundleI18n.MailSDK.Mail_Shared_LargeAttachmentAlreadyDeleted_Text]
                            warningItemsInfo.append(warningInfo)
                        } else if bannedInfo.status == .banned { // 封禁
                            if bannedInfo.isOwner {
                                let warningInfo = ["fileToken":attachment.fileToken,
                                                   "warningType": "warning",
                                                   "warningTip": BundleI18n.MailSDK.Mail_UserAgreementViolated_Text]
                                warningItemsInfo.append(warningInfo)
                                bannedFileOwnerCount += 1
                            } else {
                                // 如果原本状态是 warning，需要刷回 none
                                let warningInfo = ["fileToken": attachment.fileToken,
                                                   "warningType": "none",
                                                   "warningTip": ""]
                                warningItemsInfo.append(warningInfo)
                                let statusInfo = ["fileToken": attachment.fileToken,
                                                  "statusType": "normal",
                                                  "statusText": BundleI18n.MailSDK.Mail_Expired_Text]
                                statusItemsInfo.append(statusInfo)
                                bannedFileCustomerCount += 1
                            }
                        } else if bannedInfo.status == .highRisk { // 高危
                            // 附件高危时，需要显示 warning
                            var warningType = "warning"
                            var warningTip = BundleI18n.MailSDK.Mail_HighRiskContentDetected_Text.htmlEncoded
                            let warningInfo = ["fileToken": attachment.fileToken,
                                                  "warningType": warningType,
                                                  "warningTip": warningTip] as [String: Any]
                            warningItemsInfo.append(warningInfo)

                            riskFileCount += 1
                        } else {
                            // 附件有害时，需要显示 warning
                            let attachmentType = String(attachment.fileName.split(separator: ".").last ?? "")
                            let type = DriveFileType(rawValue: attachmentType)
                            var warningType = type?.isHarmful == true ? "warning" : "none"
                            var warningTip = BundleI18n.MailSDK.Mail_Attachment_HarmfulDetected.htmlEncoded
                            let warningInfo = ["fileToken": attachment.fileToken,
                                                  "warningType": warningType,
                                                  "warningTip": warningTip] as [String: Any]
                            warningItemsInfo.append(warningInfo)
                            riskFileCount += 1
                        }
                    }
                }
                if let stringData = try? JSONSerialization.data(withJSONObject: warningItemsInfo, options: []),
                   let JSONString = NSString(data: stringData, encoding: String.Encoding.utf8.rawValue)?.replacingOccurrences(of: "'", with: "\\'") {
                    self?.callJSFunction("updateAttachmentWarning", params: [JSONString as String])
                }
                if let stringData = try? JSONSerialization.data(withJSONObject: statusItemsInfo, options: []),
                   let JSONString = NSString(data: stringData, encoding: String.Encoding.utf8.rawValue)?.replacingOccurrences(of: "'", with: "\\'") {
                    self?.callJSFunction("updateAttachmentStatus", params: [JSONString as String])
                }
                if bannedFileOwnerCount > 0 || bannedFileCustomerCount > 0 {
                    MailTracker.log(event: "email_attachment_list_view",
                                    params: ["risk_file_cnt": bannedFileOwnerCount,
                                             "expired_file_cnt": bannedFileCustomerCount,
                                             "mail_account_type": Store.settingData.getMailAccountType()])
                }
                if riskFileCount > 0 {
                    MailTracker.log(event: "email_attachment_file_alert_view",
                                    params: ["attachment_num": riskFileCount,
                                             "mail_account_type": Store.settingData.getMailAccountType()])
                }
            }
        }
    }

    func handleCheckAttachmentRiskTag(messageIDs: [String]) {
        guard accountContext.featureManager.open(.securityFile, openInMailClient: true) else { return }
        let attachments = mailItem.messageItems.filter({ messageIDs.contains($0.message.id) }).flatMap { $0.message.attachments }.filterDuplicates({$0})
        if !attachments.isEmpty {
            // 先判断需不需要拉数据，当找不到某个 fileToken 对应的风险标识时，一次性拉取整个 thread 的标识
            getAllAttachmentsRiskTagIfNeeded(attachments.map{ $0.fileToken }) { [weak self] in
                // 等待数据拉取完再进行后续操作
                var warningTagInfos: [[String: Any]] = []
                var riskFileCount = 0 // 计数用于上报
                for attachment in attachments {
                    // 跳过没有 fileToken 的附件（本地附件）
                    if attachment.fileToken.isEmpty {
                        continue
                    }
                    // 被封禁的附件优先级更高，跳过
                    if self?.viewModel.fileBannedInfos[attachment.fileToken]?.isBanned == true {
                        continue
                    }
                    // 附件有害时，需要显示 warning
                    let attachmentType = String(attachment.fileName.split(separator: ".").last ?? "")
                    let type = DriveFileType(rawValue: attachmentType)
                    var warningType = type?.isHarmful == true ? "warning" : "none"
                    var warningTip = BundleI18n.MailSDK.Mail_Attachment_HarmfulDetected.htmlEncoded
                    // 附件高危时，需要显示 warning
                    if let fileRiskTag = self?.viewModel.fileRiskTags[attachment.fileToken],
                       fileRiskTag.isRiskFile {
                        warningType = "warning"
                        warningTip = BundleI18n.MailSDK.Mail_HighRiskContentDetected_Text.htmlEncoded
                        riskFileCount += 1
                    }
                    // 读信页优先级：已失效 > 高危附件（风险）> 有害附件（文件后缀命中）
                    if attachment.expireDisplayInfo.expireDateType == .expired {
                        warningType = "none"
                    }
                    let warningTagInfo = ["fileToken": attachment.fileToken,
                                          "warningType": warningType,
                                          "warningTip": warningTip] as [String: Any]
                    warningTagInfos.append(warningTagInfo)
                }
                if let stringData = try? JSONSerialization.data(withJSONObject: warningTagInfos, options: []),
                   let JSONString = NSString(data: stringData, encoding: String.Encoding.utf8.rawValue)?.replacingOccurrences(of: "'", with: "\\'") {
                    self?.callJSFunction("updateAttachmentWarning", params: [JSONString as String])
                }
                if riskFileCount > 0 {
                    MailTracker.log(event: "email_attachment_file_alert_view",
                                    params: ["attachment_num": riskFileCount,
                                             "mail_account_type": Store.settingData.getMailAccountType()])
                }
            }
        }
    }

    private func getAllAttachmentsRiskTagIfNeeded(_ fileTokens: [String], completion: @escaping () -> Void) {
        if fileTokens.contains(where: {!$0.isEmpty && viewModel.fileRiskTags[$0] == nil}) {
            let event = MailAPMEvent.LoadFileRiskInfos()
            event.customScene = .MailRead
            event.endParams.append(MailAPMEvent.LoadFileRiskInfos.EndParam.requestSourceTerminal)
            event.markPostStart()

            MailLogger.info("getAttachmentsRiskTag threadId: \(mailItem.threadId)")
            let allAttachments = mailItem.messageItems.flatMap { $0.message.attachments }
            let allFileTokens = allAttachments.map({ $0.fileToken }).filter({ !$0.isEmpty }).filterDuplicates({$0})

            event.endParams.append(MailAPMEvent.LoadFileRiskInfos.EndParam.requestFileTokensLength(allFileTokens.count))

            // 接口一次最多接收100个Token，因此需要拆分
            let allFileTokensSplit = allFileTokens.splitArray(withSubsize: 100)
            let observables: [Observable<ServerPB_Compliance_MGetRiskTagByTokenResponse>] = allFileTokensSplit.map { fileTokensGroup in
                guard let dataService = MailDataServiceFactory.commonDataService else {
                    return Observable.error(MailUserLifeTimeError.serviceDisposed)
                }
                return dataService.getAttachmentsRiskTag(fileTokensGroup)
            }
            Observable.zip(observables).subscribe(onNext: { [weak self] allResult in
                MailLogger.info("getAllAttachmentsRiskTag Success.")
                var allResultCount = 0 // 用于品质埋点上报
                for result in allResult {
                    for tag in result.result {
                        self?.viewModel.fileRiskTags[tag.fileToken] = tag
                    }
                    allResultCount += result.result.count
                }
                event.endParams.append(MailAPMEvent.LoadFileRiskInfos.EndParam.responseRiskInfosLength(allResultCount))
                event.endParams.append(MailAPMEventConstant.CommonParam.status_success)
                event.postEnd()
                completion()
            }, onError: { (error) in
                MailLogger.info("getAllAttachmentsRiskTag Error: \(error)")
                event.endParams.appendError(error: error)
                if error.isRequestTimeout {
                    event.endParams.append(MailAPMEventConstant.CommonParam.status_timeout)
                } else {
                    event.endParams.append(MailAPMEventConstant.CommonParam.status_rust_fail)
                }
                event.postEnd()
                completion()
            }).disposed(by: disposeBag)
        } else {
            completion()
        }
    }

    func handleCheckAttachmentBannedInfo(messageIDs: [String]) {
        guard accountContext.featureManager.open(.largeAttachmentManage, openInMailClient: false) else { return }
        // ⚠️注意：未合并接口前封禁接口只处理超大附件
        let largeAttachments = mailItem.messageItems.filter({ messageIDs.contains($0.message.id) })
            .flatMap { $0.message.attachments }
            .filter({ $0.type == .large })
            .filterDuplicates({$0})
        if !largeAttachments.isEmpty {
            // 先判断需不需要拉数据，当找不到某个 fileToken 对应的封禁信息时，一次性拉取整个 thread 的附件封禁信息
            getAttachmentBannedInfoIfNeeded(largeAttachments.map{ $0.fileToken }) { [weak self] in
                // 等待数据拉取完再进行后续操作
                var warningItemsInfo: [[String: Any]] = [] // 用于文件Owner展示“发现违规内容”
                var statusItemsInfo: [[String: Any]] = [] // 用于文件收件人展示“已失效”
                var bannedFileOwnerCount = 0 // 计数用于上报
                var bannedFileCustomerCount = 0 // 计数用于上报
                for largeAttachment in largeAttachments {
                    // 跳过没有 fileToken 的附件（本地附件）
                    if largeAttachment.fileToken.isEmpty {
                        continue
                    }
                    if let bannedInfo = self?.viewModel.fileBannedInfos[largeAttachment.fileToken],
                       bannedInfo.isBanned {
                        if bannedInfo.isOwner {
                            let warningInfo = ["fileToken": largeAttachment.fileToken,
                                               "warningType": "warning",
                                               "warningTip": BundleI18n.MailSDK.Mail_UserAgreementViolated_Text]
                            warningItemsInfo.append(warningInfo)
                            bannedFileOwnerCount += 1
                        } else {
                            // 如果原本状态是 warning，需要刷回 none
                            let warningInfo = ["fileToken": largeAttachment.fileToken,
                                               "warningType": "none",
                                               "warningTip": ""]
                            warningItemsInfo.append(warningInfo)
                            let statusInfo = ["fileToken": largeAttachment.fileToken,
                                              "statusType": "normal",
                                              "statusText": BundleI18n.MailSDK.Mail_Expired_Text]
                            statusItemsInfo.append(statusInfo)
                            bannedFileCustomerCount += 1
                        }
                    }
                }
                if let stringData = try? JSONSerialization.data(withJSONObject: warningItemsInfo, options: []),
                   let JSONString = NSString(data: stringData, encoding: String.Encoding.utf8.rawValue)?.replacingOccurrences(of: "'", with: "\\'") {
                    self?.callJSFunction("updateAttachmentWarning", params: [JSONString as String])
                }
                if let stringData = try? JSONSerialization.data(withJSONObject: statusItemsInfo, options: []),
                   let JSONString = NSString(data: stringData, encoding: String.Encoding.utf8.rawValue)?.replacingOccurrences(of: "'", with: "\\'") {
                    self?.callJSFunction("updateAttachmentStatus", params: [JSONString as String])
                }
                if bannedFileOwnerCount > 0 || bannedFileCustomerCount > 0 {
                    MailTracker.log(event: "email_attachment_list_view",
                                    params: ["risk_file_cnt": bannedFileOwnerCount,
                                             "expired_file_cnt": bannedFileCustomerCount,
                                             "mail_account_type": Store.settingData.getMailAccountType()])
                }
            }
        }
    }

    private func getAttachmentBannedInfoIfNeeded(_ fileTokens: [String], completion: @escaping () -> Void) {
        if fileTokens.contains(where: {!$0.isEmpty && viewModel.fileBannedInfos[$0] == nil}) {
            let event = MailAPMEvent.LoadFileBannedInfos()
            event.customScene = .MailRead
            event.endParams.append(MailAPMEvent.LoadFileBannedInfos.EndParam.requestSourceTerminal)
            event.markPostStart()

            MailLogger.info("getLargeAttachmentBannedInfo threadId: \(mailItem.threadId)")
            let allLargeAttachments = mailItem.messageItems.flatMap { $0.message.attachments }
            let allFileTokens = allLargeAttachments.map({ $0.fileToken }).filter({ !$0.isEmpty }).filterDuplicates({$0})

            event.endParams.append(MailAPMEvent.LoadFileBannedInfos.EndParam.requestFileTokensLength(allFileTokens.count))

            // 接口一次最多接收100个Token，因此需要拆分
            let allFileTokensSplit = allFileTokens.splitArray(withSubsize: 100)
            let observables: [Observable<ServerPB_Mails_GetLargeAttachmentBannedInfoResponse>] = allFileTokensSplit.map { fileTokensGroup in
                guard let dataService = MailDataServiceFactory.commonDataService else {
                    return Observable.error(MailUserLifeTimeError.serviceDisposed)
                }
                return dataService.getLargeAttachmentBannedInfo(fileTokensGroup)
            }
            Observable.zip(observables).subscribe(onNext: { [weak self] allResult in
                MailLogger.info("getLargeAttachmentBannedInfo Success.")
                var allResultCount = 0 // 用于品质埋点上报
                for result in allResult {
                    for info in result.tokenBannedInfoMap {
                        self?.viewModel.fileBannedInfos[info.key] = info.value
                    }
                    allResultCount += result.tokenBannedInfoMap.count
                }
                event.endParams.append(MailAPMEvent.LoadFileBannedInfos.EndParam.responseBannedInfosLength(allResultCount))
                event.endParams.append(MailAPMEventConstant.CommonParam.status_success)
                event.postEnd()
                completion()
            }, onError: { (error) in
                MailLogger.info("getLargeAttachmentBannedInfo Error: \(error)")
                if error.isRequestTimeout {
                    event.endParams.append(MailAPMEventConstant.CommonParam.status_timeout)
                } else {
                    event.endParams.append(MailAPMEventConstant.CommonParam.status_rust_fail)
                }
                event.postEnd()
                completion()
            }).disposed(by: disposeBag)
        } else {
            completion()
        }
    }

    func handleReadMore(args: [String: Any], in webView: WKWebView?) {
        if let messageId = args["messageId"] as? String {
            MailLogger.info("read more message id:\(messageId)")
            let feedThreadId = self.mailItem.feedMessageItems.first(where: {$0.item.message.id == messageId})?.threadID ?? ""
            let feedLabels = self.mailItem.feedMessageItems.first(where: {$0.item.message.id == messageId})?.labelIds ?? []
            let feedLabelIds = MailTagDataManager.shared.getTagModels(feedLabels)
            let feedLabel = feedLabelIds.first?.id ?? self.fromLabel
            let threadId = self.isFeedCard ? feedThreadId : self.viewModel.threadId
            let labelId = self.isFeedCard ? feedLabel : self.viewModel.labelId
            
            var feedMailItem = mailItem
            feedMailItem.threadId = threadId
            feedMailItem.feedCardId = ""
            let newMailItem = self.isFeedCard ? feedMailItem : mailItem
            let viewController = MailMessageListController.makeForReadMore(accountContext: accountContext,
                                                                           threadId: threadId,
                                                                           labelId: labelId,
                                                                           mailItem: newMailItem,
                                                                           fullReadMessageId: messageId,
                                                                           statInfo: statInfo,
                                                                           keyword: keyword,
                                                                           forwardInfo: realViewModel.forwardInfo,
                                                                           externalDelegate: externalDelegate)
            navigator?.push(viewController, from: self)
        } else {
            MailLogger.info("read more message error")
        }
    }

    func deleteDraft(args: [String: Any], in webView: WKWebView?) {
        if let itemId = args["draftId"] as? String, let threadID = args["threadID"] as? String {
            /// before delete, show alert
            let alert = LarkAlertController()
            alert.setContent(text: BundleI18n.MailSDK.Mail_Alert_DiscardThisMessage, alignment: .center)
            alert.addSecondaryButton(text: BundleI18n.MailSDK.Mail_Alert_Cancel)
            alert.addDestructiveButton(text: BundleI18n.MailSDK.Mail_Alert_Discard, dismissCompletion: { [weak self] in
                guard let self = self else { return }
                MailTracker.log(event: Homeric.EMAIL_DRAFT_DISCARD,
                                params:
                                    [MailTracker.sourceParamKey():
                                        MailTracker.source(type: .threadAction),
                                     MailTracker.isMultiselectParamKey(): false])
                self.threadActionDataManager
                    .deleteDraft(draftID: itemId, threadID: threadID, onSuccess: { [weak self] in
                        guard let self = self else { return }
                        self.deleteLocalDraft(draftID: itemId, forceUpdateFooter: true)
                        MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_Toast_DraftDiscarded, on: self.view)
                    }, onError: { [weak self] in
                        guard let self = self else { return }
                        MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_Toast_OperationFailed,
                                                   on: self.view, event: ToastErrorEvent(event: .read_delete_draft_fail))
                    })
            })
            navigator?.present(alert, from: self)
        }
    }

    func deleteLocalDraft(draftID: String, forceUpdateFooter: Bool = false) {
        guard !draftID.isEmpty else {
            return
        }
        // 删除draft
        for (index, item) in mailItem.messageItems.enumerated() where item.drafts.first?.id == draftID {
            mailItem.messageItems[index].drafts.removeAll()
        }
        /// delete draft in webview
        callJSFunction("deleteDraft", params: [draftID])
    }

    func findDraft(replyMsgId: String) -> MailDraft? {
        var targetDraft: MailDraft?
        for msg in mailItem.messageItems {
            if let draft = msg.drafts.first(where: { $0.replyMessageID == replyMsgId }) {
                targetDraft = MailDraft(with: draft)
                break
            }
        }
        return targetDraft
    }

    func findDraft(draftId: String) -> MailDraft? {
        var targetDraft: MailDraft?
        for msg in mailItem.messageItems {
            if let draft = msg.drafts.first(where: { $0.id == draftId }) {
                targetDraft = MailDraft(with: draft)
                break
            }
        }
        return targetDraft
    }

    func clickDraft(args: [String: Any], in webView: WKWebView?) {
        guard let draftId = args["draftId"] as? String, let replyMessageId = args["replyMessageId"] as? String else {
            mailAssertionFailure("missing essential params")
            return
        }
        var sendStatInfo = MailSendStatInfo(from: .messageDraftClick, newCoreEventLabelItem: statInfo.newCoreEventLabelItem)
        if statInfo.from == .chatSideBar {
            sendStatInfo = MailSendStatInfo(from: .chatSideBar, newCoreEventLabelItem: statInfo.newCoreEventLabelItem)
        }
        if let vc = MailSendController.checkMailTab_makeSendNavController(accountContext: accountContext,
                                                                          threadID: viewModel.threadId,
                                                                          messageID: replyMessageId,
                                                                          action: .messagedraft,
                                                                          labelId: viewModel.labelId,
                                                                          draft: findDraft(draftId: draftId),
                                                                          statInfo: sendStatInfo,
                                                                          trackerSourceType: .messageItem,
                                                                          ondiscard: makeDiscardDraftCallback(),
                                                                          mailItem: mailItem,
                                                                          msgStatInfo: statInfo,
                                                                          fileBannedInfos: viewModel.fileBannedInfos) {
            navigator?.present(vc, from: self)
        }
    }

    func clickLabel(args: [String: Any], in webView: WKWebView?) {
        changeLabels(isThreadAction: false)
    }

    func clickFlag(args: [String: Any], in webView: WKWebView?) {
        handleFlag()
    }

    func handleFlag() {
        self.mailItem.isFlagged = !self.mailItem.isFlagged
        NewCoreEvent.messageListFlagAction(self.mailItem.isFlagged).post()
        if self.mailItem.isFlagged {
            threadActionDataManager.flag(threadID: viewModel.threadId,
                                         fromLabel: viewModel.labelId,
                                         msgIds: self.allMessageIds,
                                         sourceType: logThreadActionSource)
        } else {
            threadActionDataManager.unFlag(threadID: viewModel.threadId,
                                           fromLabel: viewModel.labelId,
                                           msgIds: self.allMessageIds,
                                           sourceType: logThreadActionSource)
        }
    }

    func clickDocPreview(args: [String: Any], in webView: WKWebView?) {
        let event = NewCoreEvent(event: .email_message_list_click)
        event.params = ["click": "click_doc_link_card",
                        "target": "none",
                        "label_item": statInfo.newCoreEventLabelItem,
                        "mail_account_type": NewCoreEvent.accountType()]
        event.post()
    }

    func clickImage(args: [String: Any], in webView: WKWebView?) {
        guard let currentImage = args["currentImage"] as? [String: String] else {
            mailAssertionFailure("must have currentImage")
            return
        }
        postClickImageEvent()
        // 用于行为打点
        var auditMailInfo: AuditMailInfo?
        var auditHandler: ImageAuditHandler?
        if let messageID = args["messageID"] as? String, let messageItem = viewModel.mailItem?.messageItems.first(where: { $0.message.id == messageID }) {
            var info = messageItem.auditMailInfo(ownerID: realViewModel.forwardInfo?.ownerUserId, isEML: isEML)
            auditMailInfo = info
            auditHandler = ImageAuditHandler(mailInfo: info, securityAudit: accountContext.securityAudit, origin: "mailDetail")
        }

        let eventTracker = ImageEventTracker(labelItem: statInfo.newCoreEventLabelItem)
        if let images = args["images"] as? [[String: String]] {
            guard let currentSrc = currentImage["src"] else {
                MailLogger.debug("messagelist currentimage no src")
                return
            }
            var currentToken = accountContext.imageService.htmlAdapter.getTokenFromSrc(currentSrc)
            if currentToken.isEmpty {
                if Store.settingData.mailClient && statInfo.from != .chat {
                    var currentPath = ""
                    let infosAndFilePaths = images.compactMap({
                        if let src = $0["src"] {
                            let user = accountContext.user
                            let token = accountContext.imageService.imageAdapter.getCidFromSrc(src)
                            if let filePath = accountContext.cacheService.cachedFilePath(forKey: MailImageInfo.getImageUrlCacheKey(urlString: "cid:\(token)", userToken: user.token, tenantID: user.tenantID)) {
                                let url = URL(fileURLWithPath: filePath)
                                let fileName = url.mail.fileName ?? "image"
                                if src == currentSrc {
                                    currentPath = filePath
                                }
                                return (DriveAttachmentInfo(token: token, name: fileName, type: "", size: url.asAbsPath().fileSize ?? 0), filePath)
                            }

                        }
                        return nil
                    })
                    let filePaths = infosAndFilePaths.map({$0.1})
                    auditHandler?.fileInfos = infosAndFilePaths.map({$0.0})
                    imageViewerService.openLocalImageViewer(
                        filePaths: filePaths,
                        pageIndex: filePaths.firstIndex(of: currentPath) ?? 0,
                        from: self,
                        auditHandler: auditHandler,
                        eventTracker: eventTracker)
                } else {
                    // token为空，走EML
                    DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                        guard let self = self else { return }
                        let currentCid = self.accountContext.imageService.htmlAdapter.getReplacedCidFromSrc(currentSrc)
                        if let image = self.viewModel.cidImageMap[currentCid] {
                            let url = URL(fileURLWithPath: image.filePath)
                            let fileData = try? url.asAbsPath().fileReadingHandle().readData(ofLength: 1)
                            let fileType = fileData?.mail.imagePreviewType ?? "png"
                            if fileType != "svg" {
                                var currentPath = ""
                                let infosAndFilePaths = self.viewModel.cidImageMap.map({
                                    if $0.key == currentCid {
                                        currentPath = $0.value.filePath
                                    }
                                    let url = URL(fileURLWithPath: $0.value.filePath)
                                    let fileName = url.mail.fileName ?? "image"
                                    return (DriveAttachmentInfo(token: $0.value.filePath, name: fileName, type: fileType, size: UInt64(fileData?.count ?? 0)), $0.value.filePath)
                                })
                                let filePaths = infosAndFilePaths.map({$0.1})
                                auditHandler?.fileInfos = infosAndFilePaths.map({$0.0})
                                DispatchQueue.main.async { [weak self] in
                                    guard let self = self else { return }
                                    self.imageViewerService.openLocalImageViewer(
                                        filePaths: filePaths,
                                        pageIndex: filePaths.firstIndex(of: currentPath) ?? 0,
                                        from: self,
                                        auditHandler: auditHandler,
                                        eventTracker: eventTracker)
                                }

                            } else {
                                let fileName = url.mail.fileName ?? "image"
                                self.attachmentPreviewRouter.startLocalImagesReview(fileURL: url,
                                                                               fileType: fileType,
                                                                               fileName: fileName,
                                                                               /// 这里需要拿 mailInfo
                                                                               mailInfo: auditMailInfo,
                                                                                    from: self, origin: "mailDetail")
                            }
                        }
                    }
                }
            } else {
                // 有token，走drive token preview
                let tokens = images.compactMap { (item) -> String? in
                    guard let imageSrc = item["src"] else {
                        return nil
                    }
                    let token = self.accountContext.imageService.htmlAdapter.getTokenFromSrc(imageSrc)
                    guard token.count > 0 else {
                        return nil
                    }
                    if currentToken.isEmpty, imageSrc == currentSrc {
                        currentToken = token
                    }
                    return token
                }
                auditHandler?.fileInfos = tokens.map({ DriveAttachmentInfo(token: $0, name: "image", type: "", size: 0) })
                imageViewerService.openDriveImageViewer(
                    tokens: tokens,
                    pageIndex: tokens.firstIndex(of: currentToken) ?? 0,
                    from: self,
                    auditHandler: auditHandler,
                    eventTracker: eventTracker
                )
            }
        } else if let httpSrc = currentImage["httpSrc"] {
            /// http 图片
            DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                guard let self = self else { return }
                guard let httpUrl = URL(string: httpSrc) else { mailAssertionFailure("must have a url object"); return }

                self.httpDownloader.startDownload(with: httpUrl, isCrypto: false, checkOtherCache: true) { [weak self] data, cachedPath, _  in
                    guard let self = self else { return }
                    if let cachedPath = cachedPath {
                        let localUrl = URL(fileURLWithPath: cachedPath)
	                    let fileName = httpUrl.mail.fileName ?? "image"
                        let fileType = data.mail.imagePreviewType
                        if fileType != "svg" {
                            auditHandler?.fileInfos = [DriveAttachmentInfo(token: cachedPath, name: fileName, type: fileType, size: UInt64(data.count)) ]
                            DispatchQueue.main.async { [weak self] in
                                guard let self = self else { return }
                                self.imageViewerService.openLocalImageViewer(
                                    filePaths: [cachedPath],
                                    from: self,
                                    auditHandler: auditHandler,
                                    eventTracker: eventTracker
                                )
                            }
                        } else {
                            self.attachmentPreviewRouter.startLocalImagesReview(fileURL: localUrl,
                                                                                fileType: fileType,
                                                                                fileName: fileName,
                                                                                mailInfo: auditMailInfo,
                                                                                from: self,
                                                                                origin: "mailDetail")
                        }
                    } else {
                        mailAssertionFailure("MailMessageList local image preview failed, cachedPath not found")
                    }
                } errorHandler: { statusCode, error in
                    MailLogger.error("MailMessageList local image preview failed with code: \(statusCode), error \(error?.desensitizedMessage)")
                }
            }
        }
    }

    func postClickImageEvent() {
        let event = NewCoreEvent(event: .email_message_list_click)
        event.params = ["click": "open_image",
                        "target": "none",
                        "label_item": statInfo.newCoreEventLabelItem,
                        "is_trash_or_spam_list": statInfo.isTrashOrSpamList]
        event.post()
    }

    func oldHandleAddressClick(args: [String: Any], in webView: WKWebView?) {
        guard let address = args["address"] as? String else {
            MailMessageListController.logger.error("参数不符合预期")
            return
        }
        MailMessageListController.logger.info(address)
        var popoverFrame: CGRect?
        if let frame = args["popoverFrame"] as? [String: CGFloat], let x = frame["x"], let y = frame["y"], let width = frame["width"], let height = frame["height"] {
            popoverFrame = CGRect(x: x, y: y, width: width, height: height)
        }

        if let userid = args["userid"] as? String, !userid.isEmpty {
            // internal user, show Profile
            MailLogger.info("AddressClick tenantId")
            MailModelManager.shared.getUserTenantId(userId: userid).observeOn(MainScheduler.instance).subscribe { [weak self] (tenantId) in
                guard let self = self else { return }
                MailLogger.info("AddressClick tenantId success")
                if tenantId == self.accountContext.user.tenantID && Store.settingData.mailClient {
                    // same tenant, show profile
                    self.accountContext.profileRouter.openUserProfile(userId: userid, fromVC: self)
                } else {
                    // external tenant, show actionSheet
                    self.showAddressActions(address: self.convertArgsToAddress(args: args).address, popoverFrame: popoverFrame)
                }
            } onError: { [weak self] (_) in
                guard let self = self else { return }
                MailLogger.info("AddressClick tenantId error")
                self.showAddressActions(address: self.convertArgsToAddress(args: args).address, popoverFrame: popoverFrame)
            }.disposed(by: disposeBag)
        } else {
            showAddressActions(address: convertArgsToAddress(args: args).address, popoverFrame: popoverFrame)
        }
    }

    func convertArgsToAddress(args: [String: Any]) -> MailAddress {
        let name = args["name"] as? String ?? ""
        let userid = args["userid"] as? String ?? ""
        let userType = Int(args["userType"] as? String ?? "0") ?? 0
        let tenantId = args["tenantId"] as? String ?? ""
        let address = args["address"] as? String ?? ""
        let entityType = Email_Client_V1_Address.LarkEntityType(rawValue: userType)
        let addressModel = MailAddress(name: name,
                                       address: address,
                                       larkID: userid,
                                       tenantId: tenantId,
                                       displayName: "",
                                       type: entityType?.toContactType())
        return addressModel
    }

    private func showAddressPopover(address: String, addressFrame: CGRect) {
        let copyAddress = PopupMenuActionItem(title: BundleI18n.MailSDK.Mail_Message_CopyAddress, icon: UIImage()) { [weak self] (vc, item) in
            guard let self = self else { return }
            do {
                let config = PasteboardConfig(token: Token(MailSensitivityApiToken.readMailCopyAddress, type: .pasteboard))
                try SCPasteboard.generalUnsafe(config).string = address
                DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.normal) {
                    MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_Message_CopyAddressSuccess, on: self.view)
                }
            } catch {
                DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.normal) {
                    MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_CopyEmailAddress_UnableCopy_Toast, on: self.view)
                }
            }
            MailTracker.log(event: Homeric.EMAIL_MESSAGE_COPY_ADDRESS, params: [MailTracker.sourceParamKey(): MailTracker.source(type: .mailAddressMenu)])
        }
        var items = [copyAddress]
        if Store.settingData.hasEmailService {
            let sendMail = PopupMenuActionItem(title: BundleI18n.MailSDK.Mail_Message_SendMail, icon: UIImage()) { [weak self] (vc, item) in
                guard let self = self,
                      let sendVc = MailSendController.checkMailTab_makeSendNavController(accountContext: self.accountContext,
                                                                                         action: .fromAddress,
                                                                                         labelId: self.viewModel.labelId,
                                                                                         statInfo: MailSendStatInfo(from: .messageAddress,
                                                                                                                    newCoreEventLabelItem: self.statInfo.newCoreEventLabelItem),
                                                                                         trackerSourceType: .mailAddressRightMenu,
                                                                                         mailItem: self.mailItem,
                                                                                         sendToAddress: address,
                                                                                         msgStatInfo: self.statInfo,
                                                                                         fileBannedInfos: self.viewModel.fileBannedInfos) else { return }
                self.navigator?.present(sendVc, from: self)
            }
            items.append(sendMail)
        }

        let vc = PopupMenuPoverViewController(items: items)
        vc.hideIconImage = true
        vc.modalPresentationStyle = .popover
        vc.popoverPresentationController?.backgroundColor = UIColor.ud.bgBody
        vc.popoverPresentationController?.sourceView = self.webView
        vc.popoverPresentationController?.sourceRect = addressFrame
        // 超过view高度2/3位置时，显示到上方，防止下方空间不足
        if let webView = self.webView,
           addressFrame.maxY > webView.frame.height * Const.popoverShowFactor {
            vc.popoverPresentationController?.permittedArrowDirections = .down
        } else {
            vc.popoverPresentationController?.permittedArrowDirections = .up
        }
        self.navigator?.present(vc, from: self)
    }

    func handleAddressClick(args: [String: Any], in webView: WKWebView?) {
        guard accountContext.featureManager.open(.contactCards) else {
            oldHandleAddressClick(args: args, in: webView)
            return
        }

        onAddressClicked(args: args, in: webView)
    }

    func callJs_addItemContent(msgIDs: [String]) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            self._callJs_addItemContent(msgIDs: msgIDs)
        }
    }

    private func _callJs_addItemContent(msgIDs: [String]) {
        var params = [String: String]()
        for msgID in msgIDs {
            if let messageItem = self.viewModel.mailItem?.messageItems.first(where: { $0.message.id == msgID }) {
                let replaceRecall = self.realViewModel.templateRender.shouldReplaceRecallBanner(for: messageItem, myUserId: self.myUserId ?? "")
                let mailRecallState = MailRecallManager.shared.recallState(for: messageItem)
                var itemContent = self.realViewModel.templateRender.replaceForItemContent(
                    messageItem: messageItem,
                    myUserId: self.myUserId ?? "",
                    replaceRecall: replaceRecall,
                    mailRecallState: mailRecallState,
                    atLabelID: self.fromLabel,
                    fromChat: self.isForwardCard(),
                    isFeedCard: self.realViewModel.isFeed)
                itemContent = MailMessageListTemplateRender.preprocessHtml(
                    itemContent,
                    messageID: msgID,
                    messageItem: messageItem,
                    isFromChat: self.isForwardCard(),
                    sharedService: self.accountContext.sharedServices)

                itemContent = itemContent.doubleEscapeForJson()
                params[msgID] = itemContent
            }
        }
        if params.count > 0 {
            if let data = try?
                JSONSerialization.data(withJSONObject: params,
                                        options: []),
                let JSONString = NSString(data: data,
                                            encoding: String.Encoding.utf8.rawValue)?.replacingOccurrences(of: "'", with: "\\'") {
                let jsString = "window.addItemContent('\(JSONString)')"
                self.callJavaScript(jsString)
            } else {
                mailAssertionFailure("callJs_addItemContent fail to serialize json")
            }
        }
    }

    func callJS_startContentSearch() {
        callJavaScript("window.startSearch()")
    }

    func callJS_search(_ keyword: String?) {
        let keyword = (keyword ?? "").cleanEscapeCharacter()
        callJavaScript("window.search('\(keyword)')")
    }

    func handlePersonalInfoClick(args: [String: Any], in webView: WKWebView?) {
        guard let address = args["address"] as? String else {
            MailMessageListController.logger.error("handlePersonalInfoClick 参数不符合预期")
            return
        }
        MailMessageListController.logger.info(address)
        let name = args["name"] as? String ?? ""
        let userid = args["userid"] as? String ?? ""
        let userType = Int(args["userType"] as? String ?? "0") ?? 0
        let tenantId = args["tenantId"] as? String ?? ""
        let entityType = Email_Client_V1_Address.LarkEntityType(rawValue: userType) ?? .user
        let accountId = Store.settingData.currentAccount.value?.mailAccountID ?? ""
        let mailAddress = MailAddress(name: name,
                                      address: address,
                                      larkID: userid,
                                      tenantId: tenantId,
                                      displayName: "",
                                      type: entityType.toContactType())
        var popoverFrame: CGRect?
        if let frame = args["popoverFrame"] as? [String: CGFloat], let x = frame["x"], let y = frame["y"], let width = frame["width"], let height = frame["height"] {
            popoverFrame = CGRect(x: x, y: y, width: width, height: height)
        }
        if mailItem.shouldForcePopActionSheet {
            self.showAddressActions(address: mailAddress.address, popoverFrame: popoverFrame)
        } else {
            MailContactLogic.default.checkContactDetailAction(userId: userid,
                                                              tenantId: tenantId,
                                                              currentTenantID: accountContext.user.tenantID,
                                                              userType: entityType) { [weak self] result in
                guard let self = self else { return }
                if result == MailContactLogic.ContactDetailActionType.actionSheet {
                    self.showAddressActions(address: mailAddress.address, popoverFrame: popoverFrame)
                } else if result == MailContactLogic.ContactDetailActionType.profile {
                    // internal user, show Profile
                    self.accountContext.profileRouter.openUserProfile(userId: userid, fromVC: self)
                } else if result == MailContactLogic.ContactDetailActionType.nameCard {
                    if self.addressNameFg {
                        var item = AddressRequestItem()
                        item.address =  address
                        MailDataServiceFactory.commonDataService?.getMailAddressNames(addressList: [item]).subscribe( onNext: { [weak self]  MailAddressNameResponse in
                            guard let `self` = self else { return }
                                if let item = MailAddressNameResponse.addressNameList.first, !item.larkEntityID.isEmpty &&
                                    item.larkEntityID != "0" {
                                    self.accountContext.profileRouter.openUserProfile(userId: item.larkEntityID, fromVC: self)
                                } else {
                                    self.accountContext.profileRouter.openNameCard(accountId: accountId, address: address, name: name, fromVC: self, callBack: { [weak self] success in
                                        self?.handleSaveContactResult(success)
                                    })
                                }
                            }, onError: { [weak self] (error) in
                                guard let `self` = self else { return }
                                MailLogger.error("handle peronal click resp error \(error)")
                                self.accountContext.profileRouter.openNameCard(accountId: accountId, address: address, name: name, fromVC: self, callBack: { [weak self] success in
                                    self?.handleSaveContactResult(success)
                                })
                            }).disposed(by: self.disposeBag)
                    } else {
                        self.accountContext.profileRouter.openNameCard(accountId: accountId, address: address, name: name, fromVC: self, callBack: { [weak self] success in
                            self?.handleSaveContactResult(success)
                        })
                    }
                }
            }
        }
    }

    func handleSaveContactResult(_ success: Bool) {
        MailLogger.info("[mail_stranger] msgList handleSaveContactResult success: \(success)")
        if success {
            self.manageStrangerThread(threadIDs: [self.viewModel.threadId], status: true,
                                      isSelectAll: false, dismissMsgListSecretly: true)
            self.closeScene(completionHandler: nil)
        }
    }

    /// 点击邮件地址时，弹出相关操作选项, regular sizeClass会以popover形式，compact sizeClass会以actionSheet形式弹出
    func showAddressActions(address: String, popoverFrame: CGRect?) {
        // 以actionSheet形式弹出的方法
        func showAddressActionSheet(address: String) {
            let pop = UDActionSheet(config: UDActionSheetUIConfig(isShowTitle: true))
            pop.setTitle(address)
            pop.addDefaultItem(text: BundleI18n.MailSDK.Mail_Message_CopyAddress) { [weak self] in
                guard let `self` = self else { return }
                do {
                    let config = PasteboardConfig(token: Token(MailSensitivityApiToken.readMailCopyAddress, type: .pasteboard))
                    try SCPasteboard.generalUnsafe(config).string = address
                    DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.normal) {
                        MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_Message_CopyAddressSuccess, on: self.view)
                    }
                } catch {
                    DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.normal) {
                        MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_CopyEmailAddress_UnableCopy_Toast, on: self.view)
                    }
                }
                MailTracker.log(event: Homeric.EMAIL_MESSAGE_COPY_ADDRESS, params: [MailTracker.sourceParamKey(): MailTracker.source(type: .mailAddressMenu)])
            }
            if Store.settingData.hasEmailService {
                pop.addDefaultItem(text: BundleI18n.MailSDK.Mail_Message_SendMail) { [weak self] in
                    guard let self = self,
                          let sendVc = MailSendController.checkMailTab_makeSendNavController(accountContext: self.accountContext,
                                                                                             action: .fromAddress,
                                                                                             labelId: self.viewModel.labelId,
                                                                                             statInfo: MailSendStatInfo(from: .messageAddress,
                                                                                                                        newCoreEventLabelItem: self.statInfo.newCoreEventLabelItem),
                                                                                             trackerSourceType: .mailAddressRightMenu,
                                                                                             mailItem: self.mailItem,
                                                                                             sendToAddress: address,
                                                                                             msgStatInfo: self.statInfo,
                                                                                             fileBannedInfos: self.viewModel.fileBannedInfos) else { return }
                    self.navigator?.present(sendVc, from: self)
                }
            }
            pop.setCancelItem(text: BundleI18n.MailSDK.Mail_Alert_Cancel) {
                MailLogger.info("AddressClick Cancle")
            }
            navigator?.present(pop, from: self)
        }

        if rootSizeClassIsSystemRegular, let popoverFrame = popoverFrame {
            // regular & 有popover frame，展示popover
            showAddressPopover(address: address, addressFrame: popoverFrame)
        } else {
            // 展示actionSheet
            showAddressActionSheet(address: address)
        }
    }

    func handleMenuClickShareToIm(messageId: String) {
        let subject = mailItem.messageItems.first(where: { $0.message.id == messageId })?.message.subject ?? ""
        accountContext.provider.routerProvider?.forwardMailMessageShareBody(threadId: viewModel.threadId, messageIds: [messageId], summary: subject, fromVC: self)
    }

    func handleRecallDetail(args: [String: Any], in webView: WKWebView?) {
        guard let messageId = args["messageId"] as? String else { return }
        let recallDetailVC = MailRecallDetailViewController(messageId: messageId, accountContext: accountContext)
        navigator?.push(recallDetailVC, from: self)
    }

    func handleExpandMessagesFirstVisible(args: [String: Any], in webView: WKWebView) {
        guard let ids = args["messageIds"] as? [String] else { return }
        handleFirstVisibleMessage(ids: ids)
    }

    func handleFirstVisibleMessage(ids: [String]) {
        MailMessageListController.logger.info("handleFirstVisibleMessage")
        guard ids.count > 0 else {
            MailMessageListController.logger.info("handleFirstVisibleMessage count <= 0")
            return
        }
        pendingFirstVisibleIDs.formUnion(ids)
        let targetMessages = mailItem.messageItems.filter({ ids.contains($0.message.id) })
        let currentIds = targetMessages.map { $0.message.id }

        if translateManager.isAutoTranslateOn {
            MailMessageListController.logger.info("auto translate is on")
            autoTranslateFor(messageIds: Set(currentIds))
        } else if accountContext.featureManager.open(.translateRecommend) {
            MailMessageListController.logger.info("auto recommend is on")
            handleTranslateRecommendFor(ids: currentIds)
        } else {
            MailMessageListController.logger.info("auto recommend & translate is off")
        }
        if FeatureManager.open(.largeAttachmentManagePhase2, openInMailClient: false) {
            // 合并接口处理
            handleCheckAttachmentNewBannedInfo(messageIDs: currentIds)
        } else {
            handleCheckAttachmentRiskTag(messageIDs: currentIds)
            handleCheckAttachmentBannedInfo(messageIDs: currentIds)
        }

        showTopAttachmentGuideIfNeeded(messageIDs: currentIds)

        pendingFirstVisibleIDs.subtract(currentIds)
        // Log SafetyBanner Display
        for message in targetMessages where message.showSafeTipsBanner {
            let riskBannerReason = message.message.security.riskBannerReason
            let riskBannerLevel = message.message.security.riskBannerLevel
            let riskReason = riskReasonToString(riskReason: riskBannerReason)
            let riskLevel = riskLevelToString(riskLevel: riskBannerLevel)
            MailTracker.log(event: "email_risk_banner_view", params: ["label_item": getLogLabelID(), "risk_reason": riskReason, "risk_level": riskLevel])
        }
        self.expandMessage(ids: ids)
    }
    private func handleTranslateRecommendFor(ids: [String]) {
        let idsAndI18N = ids.compactMap { (id) -> [String: Any]? in
            guard let messageItem = viewModel.mailItem?.messageItems.first(where: { $0.message.id == id }) else {
                return nil
            }
            guard let data = messageItem.message.languageIdentifier.data(using: .utf8),
                  let lan = (try? JSONSerialization.jsonObject(with: data, options: []) as? [String])?.first else {
                MailMessageListController.logger.info("TranslateRecommend-languageIdentifier not found")
                return nil
            }
            guard lan != MailTranslateLanguage.unknown &&
                    lan.lowercased() != I18n.currentLanguageShortIdentifier().lowercased() &&
                    lan != translateManager.targetLanFromSetting.lanCode &&
                    accountContext.user.getUserSetting()?.translationRecommendationSkipLanguage.contains(lan) != true else {
                MailMessageListController.logger.info("TranslateRecommend-not support for \(lan)")
                return nil
            }

            guard let srcConfigValue =
                    accountContext.provider.translateLanguageProvider?.srcLanguagesConfig[lan],
                  let srcI18N = srcConfigValue.i18NLanguage[LanguageManager.currentLanguage.localeIdentifier.lowercased()] ??
                    srcConfigValue.i18NLanguage[Lang.en_US.rawValue.lowercased()] else {
                MailMessageListController.logger.info("TranslateRecommend-no i18N for \(lan)")
                return nil
            }

            return ["messageID": id, "show": true, "displayText": BundleI18n.MailSDK.Mail_Translations_LanguageDetectedMobile(srcI18N)]
        }

        guard idsAndI18N.count > 0,
              let data = try? JSONSerialization.data(withJSONObject: idsAndI18N, options: []),
              let JSONString = NSString(data: data, encoding: String.Encoding.utf8.rawValue)?.replacingOccurrences(of: "'", with: "\\'") else { return }
        callJavaScript("window.showTranslateRecommend('\(JSONString)')", in: webView)
    }

    func shareManageButtonPosition(args: [String: Any], in webView: WKWebView) {
        guard !Display.pad else {
            return
        }
        let guideKey = "all_email_managesharing"
        let width = args["width"] as? CGFloat ?? 0
        let height = args["height"] as? CGFloat ?? 0
        let left = args["left"] as? CGFloat ?? 0
        let top = args["top"] as? CGFloat ?? 0
        let y: CGFloat = webView.screenFrame.minY + top - 5
        let frame = CGRect(x: left, y: y, width: width, height: height)

        let targetAnchor = TargetAnchor(targetSourceType: .targetRect(frame))
        let textConfig = TextInfoConfig(title: BundleI18n.MailSDK.Mail_Share_ShareManageButton, detail: BundleI18n.MailSDK.Mail_Share_ShareManageOnboarding)
        let bubbleConfig = SingleBubbleConfig(delegate: nil, bubbleConfig: BubbleItemConfig(guideAnchor: targetAnchor, textConfig: textConfig), maskConfig: nil)

        accountContext.provider.guideServiceProvider?.guideService?.showBubbleGuideIfNeeded(
            guideKey: guideKey,
            bubbleType: .single(bubbleConfig),
            dismissHandler: nil,
            didAppearHandler: nil,
            willAppearHandler: nil)
    }

    func handleContextMenuClick(args: [String: Any], in webView: WKWebView) {
        guard let threadID = args["threadId"] as? String, let messageID = args["messageId"] as? String, let isTranslated = args["isTranslated"] as? Bool else {
            return
        }
        let rgbMaxVal: CGFloat = 255.0
        var avatarInfo: (String, UIColor)?
        if let avatar = args["avatar"] as? [String: Any],
           let initial = avatar["initial"] as? String,
           let rgb = (avatar["rgb"] as? [CGFloat])?.map({ $0 / rgbMaxVal }), rgb.count >= 3 {
            let color = UIColor(red: rgb[0], green: rgb[1], blue: rgb[2], alpha: 1)
            avatarInfo = (initial, color)
        }
        var menuFrame: CGRect? = nil
        if let frame = args["menuFrame"] as? [String: CGFloat], let x = frame["x"], let y = frame["y"], let width = frame["width"], let height = frame["height"] {
            menuFrame = CGRect(x: x + width / 2, y: y + webView.scrollView.contentInset.top, width: width, height: height)
        }
        // 异步获取单msg的labelID
        if viewModel.labelId == Mail_LabelId_SEARCH_TRASH_AND_SPAM && !Store.settingData.mailClient {
            Store.fetcher?.getMessageSuitableInfo(messageId: messageID, threadId: threadID, scene: .readMessage)
                .subscribe(onNext: { [weak self] (resp) in
                    MailLogger.info("[mail_search] getMessageSuitableLabel label: \(resp.label)")
                    self?.showContextMenuPanel(threadID: threadID, messageID: messageID, isTranslated: isTranslated, avatarInfo: avatarInfo, menuFrame: menuFrame, labelID: resp.label, needBlockTrash: true)
                }, onError: { (error) in
                    MailLogger.info("[mail_search] getMessageSuitableLabel error: \(error)")
                }).disposed(by: disposeBag)
        } else {
            let labelID = {
                if Store.settingData.mailClient {
                    return searchFolderTag
                } else {
                    return nil
                }
            }()
            showContextMenuPanel(threadID: threadID, messageID: messageID, isTranslated: isTranslated, avatarInfo: avatarInfo, menuFrame: menuFrame, labelID: labelID, needBlockTrash: Store.settingData.mailClient && viewModel.labelId == Mail_LabelId_SEARCH_TRASH_AND_SPAM)
        }
    }

    /// Start translate for messageIds for current MailItem
    /// - Parameter messageIds: MessageIds
    /// - Returns: MessageIds that don't need to translate
    func autoTranslateFor(messageIds: Set<String>) {
        guard messageIds.count > 0 else {
            MailMessageListController.logger.info("autoTranslateFor messageIds empty")
            return
        }
        let idsForCurrentMail = messageIds.filter { (id) -> Bool in
            guard let targetMessage = viewModel.mailItem?.messageItems.first(where: { $0.message.id == id }) else {
                MailMessageListController.logger.info("autoTranslateFor message not match")
                return false
            }

            if targetMessage.message.from.isMyAddress(myAccount: currentAccount) {
                // 1. Dont translate for emails sent from my own
                MailMessageListController.logger.info("autoTranslateFor message from own")
                return false
            }

            let languages: [String]
            if let data = targetMessage.message.languageIdentifier.data(using: .utf8),
                let lans = try? JSONSerialization.jsonObject(with: data, options: []) as? [String] {
                languages = lans
            } else {
                languages = []
            }
            let src = languages.first ?? MailTranslateLanguage.unknown

            if src == MailTranslateLanguage.not_support || src == MailTranslateLanguage.not_lang {
                // 2. Dont translate for not_support/not_lang
                MailMessageListController.logger.log(level: .info, "MailAutoTranslate - not_support/not_lang \(id)")
                return false
            }

            if src == accountContext.provider.translateLanguageProvider?.targetLanguage {
                // 3. Dont translate when src is the same with target
                MailMessageListController.logger.log(level: .info, "MailAutoTranslate - same with target \(id)")
                return false
            }

            if !src.isEmpty && src != "unknown" && !translateManager.shouldAutoTranslate(src: src) {
                // 4. Dont translate when src is disabled
                MailMessageListController.logger.log(level: .info, "MailAutoTranslate - auto translate off for \(src) lang, \(id)")
                return false
            }
            MailMessageListController.logger.log(level: .info, "MailAutoTranslate - start auto translate \(id)")
            return true
        }

        if idsForCurrentMail.count > 0 {
            for id in idsForCurrentMail {
                MailMessageListController.logger.info("autoTranslateFor translate \(id)")
                startTranslate(messageId: id, targetLan: nil, isAuto: true)
            }
            MailTracker.log(event: "mail_auto_translation_message_count", params: ["thread_biz_id": viewModel.threadId])
        } else {
            MailMessageListController.logger.info("autoTranslateFor translate ids empty")
        }
    }

    func updateRecallStateFor(messageId: String, in threadId: String, mailItem: MailItem? = nil) {
        var tmpMail: MailMessageItem?
        if let mailItem = mailItem {
            tmpMail = mailItem.messageItems.first(where: { $0.message.id == messageId })
        } else {
            let vm = realViewModel[threadId: threadId]
            tmpMail = vm?.mailItem?.messageItems.first(where: { $0.message.id == messageId })
        }
        guard let mail = tmpMail else { return }
        let state = MailRecallManager.shared.recallState(for: mail)
        MailMessageListController.logger.debug("MailRecall: update state for '\(messageId)', to: '\(state)')")
        mailHideSendStatus(mail: mail)
        callJavaScript("window.updateRecallState('\(messageId)', '\(state.rawValue)', '\(state.bannerText)')", in: getWebViewOf(threadId: threadId))
    }

    func deleteMessageItem(id: String) {
        callJavaScript("window.deleteMessage('\(id)')")
    }

    func checkUserids(args: [String: Any], in webView: WKWebView?) {
        if NativeRenderService.shared.enable && viewModel.labelId != Mail_LabelId_Stranger {
            // 如果使用头像同层渲染，将不响应这个回调
            return
        }

        guard let userids = args["userids"] as? [String] else { return }
        var users: [String] = []
        // 排重
        for userid in userids {
            if !users.contains(userid) {
                users.append(userid)
            }
        }

        for userid in users {
            MailModelManager.shared.getUserAvatarKey(userId: userid).subscribe(onNext: { [weak self] (avatarKey) in
                guard let self = self else { return }
                guard !avatarKey.isEmpty else {
                    MailLogger.info("avatarKey is empty for \(userid)")
                    self.updateAvatar(userId: userid, avatarUrl: "", in: webView)
                    return
                }
                let fixedKey = avatarKey.replacingOccurrences(of: "lark.avatar/", with: "")
                MailModelManager.shared.getAvatarUrl(entityID: userid, avatarkey: fixedKey).subscribe(onNext: { [weak self] (urlpath) in
                    guard let self = self else { return }
                    if AbsPath(urlpath).exists {
                        self.updateAvatar(userId: userid, avatarUrl: urlpath, in: webView)
                        MailModelManager.shared.setAvatar(userid: userid, path: urlpath)
                    } else {
                        self.updateAvatar(userId: userid, avatarUrl: "", in: webView)
                        MailLogger.error("messagelist getAvatarPath not esists:\(fixedKey)")
                    }
                }, onError: { [weak self](error) in
                    guard let self = self else { return }
                    MailLogger.error("messagelist getAvatarUrl error:\(error)")
                    self.updateAvatar(userId: userid, avatarUrl: "", in: webView)
                }).disposed(by: self.disposeBag)
            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                MailLogger.error("messagelist getAvatarKey error")
                self.updateAvatar(userId: userid, avatarUrl: "", in: webView)
            }).disposed(by: disposeBag)
        }
    }

    func updateAvatar(userId: String, avatarUrl: String, in webView: WKWebView?) {
        let resultDic = ["userid": userId, "avatarurl": avatarUrl]
        guard let data = try? JSONSerialization.data(withJSONObject: resultDic, options: []),
            let JSONString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else {
                mailAssertionFailure("fail to serialize json")
                return
        }
        self.callJavaScript("window.updateUserid('\(JSONString)')", in: webView)
    }

    func checkUrls(args: [String: Any], in webView: WKWebView?) {
        guard !Store.settingData.mailClient else { return }
        guard let jsMsgUrlsDic = args["urls"] as? [String: [String]] else { return }
        var urls = [String]()

        for (_, docsUrls) in jsMsgUrlsDic {
            urls.append(contentsOf: docsUrls)
        }

        MailDataSource.shared.mailGetDocsPermModel(docsUrlStrings: urls, requestPermissions: false).subscribe(onNext: { [weak self] (resp) in
            guard let `self` = self else { return }
            let Docs = resp.docs
            var pbModleDic = [String: [String: Any]]()
            for (url, pbModel) in Docs {
                let docDic: [String: Any] = ["key": pbModel.key,
                                             "url": pbModel.url,
                                             "type": pbModel.type.rawValue,
                                             "name": pbModel.name,
                                             "iconKey": pbModel.iconKey,
                                             "abstract": pbModel.abstract,
                                             "createTime": pbModel.createTime,
                                             "updateTime": pbModel.updateTime,
                                             "ownerName": pbModel.ownerName,
                                             "ownerID": pbModel.ownerID]
                pbModleDic[url] = docDic
            }
            var resultDic = [String: [[String: Any]]]()
            for (msgId, docsUrls) in jsMsgUrlsDic {
                var models = [[String: Any]]()
                for docsUrl in docsUrls {
                    guard let dic = pbModleDic[docsUrl] else { continue }
                    models.append(dic)
                }
                resultDic[msgId] = models
            }
            var weakUrls: [String] = []
            weakUrls.append(contentsOf: resp.noPermUrls)
            weakUrls.append(contentsOf: resp.deletedUrls)
            let weakUrlsStr = weakUrls.joined(separator: ",")
            if weakUrls.count > 0 {
                self.callJavaScript("window.updateDocsColor('\(weakUrlsStr)')", in: webView)
            }
            guard let data = try? JSONSerialization.data(withJSONObject: resultDic, options: []),
                let JSONString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else { mailAssertionFailure("fail to serialize json"); return }

            self.callJavaScript("window.updateDocsItem('\(JSONString)')", in: webView)
            }).disposed(by: disposeBag)
    }

    func handleLog(args: [String: Any], in webView: WKWebView?) {
        guard let content = args["content"] as? String,
            let level = args["level"] as? Int,
            let logLevel = TemplateLogLevel(rawValue: level) else {
                mailAssertionFailure("unexpected param")
                return
        }
        #if DEBUG
        // 调试用打点
        if content.contains("timestamp"), let timeStampStr = content.split(separator: " ").last, let time = Int(timeStampStr), let first = content.split(separator: " ").first {
            MailMessageListController.logStartTime(name: "\(first)", timeStamp: time)
        }
        #endif
        switch logLevel {
        case .debug:
            MailMessageListController.logger.debug(content)
        case .info:
            MailMessageListController.logger.info(content)
        case .warn:
            MailMessageListController.logger.warn(content)
        case .error:
            MailMessageListController.logger.error(content)
        }
    }

    func handleTracker(args: [String: Any], in webView: WKWebView?) {
        guard let mailEvent = args["event"] as? String,
            let isStart = args["isStart"] as? Bool,
            let timestamp = args["timestamp"] as? Int else {
                mailAssertionFailure("unexpected param")
                return
        }
        let params = args["params"] as? [String: Any]
        if isStart {
            MailTracker.startRecordTimeConsuming(event: mailEvent, params: params, currentTime: timestamp)
        } else {
            MailTracker.endRecordTimeConsuming(event: mailEvent, params: params, currentTime: timestamp)
        }
    }

    func handleReceiverClick(args: [String: Any], in webView: WKWebView?) {
        guard let isExpand = args["expand"] as? Bool else {
            mailAssertionFailure("unexpected param")
            return
        }
        if !isExpand {
            return
        }
        MailTracker.log(event: Homeric.EMAIL_MESSAGE_DETAILRECEIVER, params: [:])
    }

    func handleAvatarClick(args: [String: Any], in webView: WKWebView?) {
        guard accountContext.featureManager.open(.contactCards) else {
            if let userid = args["userid"] as? String {
                if Store.settingData.mailClient {
                    MailLogger.info("[debug_profile] handleAvatarClick - mailClient - onAvatarClicked")
                    onAvatarClicked(args: args, in: webView)
                } else {
                    MailLogger.info("[debug_profile] contactCards fg close, openUserProfile")
                    accountContext.profileRouter.openUserProfile(userId: userid, fromVC: self)
                }
            }
            return
        }
        MailLogger.info("[debug_profile] handleAvatarClick - normal - onAvatarClicked")
        onAvatarClicked(args: args, in: webView)
    }

    // MARK: - Translation
    func translateClick(args: [String: Any], in webView: WKWebView?) {
        guard let messageId = args["messageID"] as? String else {
                MailMessageListController.logger.debug("Translate click error, messageId not found")
                return
        }
        MailTracker.log(event: Homeric.MAIL_TRANSLATION_SINGLE_MESSAGE_BTN, params: ["thread_biz_id": viewModel.threadId, "message_id": messageId])
        startTranslate(messageId: messageId, targetLan: nil, isAuto: false)
    }

    private func startTranslate(messageId: String, targetLan: MailTranslateLanguage?, isAuto: Bool, loading: Bool = true, isLanSwitch: Bool = false) {
        guard !translatingIdAndInterval.keys.contains(messageId),
            let mail = viewModel.mailItem?.messageItems.first(where: { $0.message.id == messageId }) else { return }

        if loading {
            toggleTranslationLoading(show: true, messageId: messageId)
        }
        translatingIdAndInterval[messageId] = Date().timeIntervalSince1970

        let target = targetLan ?? translateManager.targetLanFromSetting
        let translateThreadID: String?
        if let forwardInfo = realViewModel.forwardInfo {
            translateThreadID = forwardInfo.cardId
        } else {
            translateThreadID = viewModel.labelId == Mail_LabelId_Stranger ? nil : viewModel.threadId
        }
        let pageThreadID = viewModel.threadId
        translateManager.translate(threadId: translateThreadID, ownerUserID: realViewModel.forwardInfo?.ownerUserId,
                                   mail: mail, targetLan: target, isAuto: isAuto) { [weak self] (message, error) in
            func updateTranslation(_ jsResult: MailTranslateManager.TranslatedJSResult?, toastText: String?) {
                guard let self = self else { return }
                if let jsResult = jsResult, let jsString = jsResult.jsCallString {
                    if let messageListView = self.getPageCellOf(threadId: pageThreadID)?.mailMessageListView {
                        self.callJavaScript(jsString, in: messageListView.webview, { (_, error) in
                            if let error = error {
                                MailMessageListController.logger.error("Update Translation Error: \(error)")
                            }
                        })
                        if let toast = toastText {
                            MailRoundedHUD.showTips(with: toast, on: self.view)
                        }
                        if let translatedSubject = jsResult.translatedSubject {
                            self.updateMailTitleView(threadID: pageThreadID, translatedInfo: (translatedSubject, !jsResult.showOriginalText))
                        } else {
                            MailMessageListController.logger.log(level: .info, "Skip translation result without subject threadID: \(pageThreadID), messageID: \(messageId)")
                        }
                    } else {
                        MailMessageListController.logger.log(level: .info, "Cannot find page for translation result threadID: \(pageThreadID), messageID: \(messageId)")
                    }
                }
            }

            guard let self = self else { return }

            let startingInterval = self.translatingIdAndInterval[messageId] ?? 0
            self.translatingIdAndInterval.removeValue(forKey: messageId)

            if isAuto {
                guard let src = message?.sourceLans.first, self.translateManager.shouldAutoTranslate(src: src), src != target.lanCode else {
                    MailMessageListController.logger.log(level: .info, "MailAutoTranslate - from backend @{\(message?.sourceLans ?? [])} not translated \(mail.message.id)")
                    self.toggleTranslationLoading(show: false, messageId: messageId)
                    return
                }
            }

            guard error == nil, let result = message?.result else {
                // handle network error
                if isLanSwitch {
                    updateTranslation(self.translateManager.getPreTranslateResultJSCall(msgId: messageId, isTranslation: true), toastText: nil)
                }
                MailRoundedHUD.showTips(with: BundleI18n.MailSDK.Mail_Translations_Networkerror,
                                        on: self.view, event: ToastErrorEvent(event: .read_mail_translations_network_error))
                return
            }

            var jsonString: MailTranslateManager.TranslatedJSResult?
            var toastText: String?
            var closeTranslate = false

            switch result {
            case .succeed, .sameLanguage:
                jsonString = self.translateManager.getPreTranslateResultJSCall(msgId: messageId, isTranslation: true)
            case .notSupport:
                if isLanSwitch {
                    jsonString = self.translateManager.getPreTranslateResultJSCall(msgId: messageId, isTranslation: true)
                } else {
                    toastText = BundleI18n.MailSDK.Mail_Translations_NotSupported
                    closeTranslate = true
                    InteractiveErrorRecorder.recordError(event: .mail_translations_notsupported, tipsType: .toast)
                }
            case .blobDetected:
                toastText = BundleI18n.MailSDK.Mail_Translations_ContentTooLarge
                self.dismissTranslation(messageId: messageId)
                closeTranslate = true
                InteractiveErrorRecorder.recordError(event: .translations_contenttoolarge, tipsType: .toast)
            case .backendError:
                if isLanSwitch {
                    jsonString = self.translateManager.getPreTranslateResultJSCall(msgId: messageId, isTranslation: true)
                } else {
                    toastText = BundleI18n.MailSDK.Mail_Translations_Networkerror
                    InteractiveErrorRecorder.recordError(event: .read_mail_translations_network_error, tipsType: .toast)
                    closeTranslate = true
                }
            case .partialSupport:
                if !isLanSwitch {
                    toastText = BundleI18n.MailSDK.Mail_Translations_Detectedunsupported
                }
                jsonString = self.translateManager.getPreTranslateResultJSCall(msgId: messageId, isTranslation: true)
            case .ignored:
                MailMessageListController.logger.log(level: .info, "MailAutoTranslate - from backend src ignored \(mail.message.id)")
                closeTranslate = true
            }

            if let jsonString = jsonString {
                let animationInterval = Date().timeIntervalSince1970 - startingInterval
                if animationInterval < timeIntvl.normal {
                    DispatchQueue.main.asyncAfter(deadline: .now() + (timeIntvl.normal - animationInterval)) {
                        updateTranslation(jsonString, toastText: toastText)
                    }
                } else {
                    updateTranslation(jsonString, toastText: toastText)
                }
            } else if let toast = toastText {
                MailRoundedHUD.showTips(with: toast, on: self.view)
            }

            if loading && closeTranslate {
                self.toggleTranslationLoading(show: false, messageId: messageId)
            }
        }
    }

    private func toggleTranslationLoading(show: Bool, messageId: String) {
        callJavaScript("window.toggleTranslationLoading('\(messageId)', '\(show)')")
    }

    func dismissTranslation(messageId: String) {
        callJavaScript("window.dismissTranslation('\(messageId)')")
        updateCurrentMailTitleView(translatedInfo: nil)
    }

    func turnOffTranslationClick(args: [String: Any], in webView: WKWebView?) {
        guard let messageId = args["messageID"] as? String else {
            MailMessageListController.logger.debug("Translate click error, messageId not found")
            return
        }
        translatingIdAndInterval.removeValue(forKey: messageId)
        dismissTranslation(messageId: messageId)
    }

    func selectTranslationLanguageClick(args: [String: Any], in webView: WKWebView?) {
        guard let messageId = args["messageID"] as? String else { return }

        let aliasList = AliasListController(translateManager.targetLanguages, messageId: messageId)
        aliasList.transDelegate = self
        navigator?.present(aliasList, from: self, animated: false, completion: nil)
    }

    func selectedTargetLan(targetLan: MailTranslateLanguage, messageId: String) {
        MailTracker.log(event: Homeric.MAIL_TRANSLATION_SINGLE_MESSAGE_TARGET_LANGUAGE,
                        params: ["thread_biz_id": self.viewModel.threadId, "message_id": messageId, "target_language": targetLan.lanCode])
        if let resultItem = self.translateManager.resultItem(for: messageId), targetLan.lanCode != resultItem.targetLan.lanCode {
            self.startTranslate(messageId: messageId, targetLan: targetLan, isAuto: false, isLanSwitch: true)
        }
    }

    func viewOriginalClick(args: [String: Any], in webView: WKWebView?) {
        guard let messageId = args["messageID"] as? String else { return }
        toggleTranslation(for: messageId, isTranslation: false)
    }

    func viewTranslationClick(args: [String: Any], in webView: WKWebView?) {
        guard let messageId = args["messageID"] as? String else { return }
        toggleTranslation(for: messageId, isTranslation: true)
    }

    private func toggleTranslation(for msgId: String, isTranslation: Bool) {
        if isTranslation {
            // View Translation
            let jsResult = translateManager.getPreTranslateResultJSCall(msgId: msgId, isTranslation: isTranslation)
            if let jsString = jsResult.jsCallString {
                callJavaScript(jsString)
                if let translatedSubject = jsResult.translatedSubject {
                    updateCurrentMailTitleView(translatedInfo: (translatedSubject, !jsResult.showOriginalText))
                }
            } else {
                startTranslate(messageId: msgId, targetLan: nil, isAuto: false) // 考虑pad分屏重建vc和traslateManager的情况
            }
        } else if let mail = viewModel.mailItem?.messageItems.first(where: { $0.message.id == msgId }),
                  let jsString = translateManager.getUpdateTranslationJSCall(msgId: msgId, isTranslation: isTranslation,
                                                                             subject: viewModel.subject ?? "",
                                                                             messageSubject: viewModel.subject ?? "",
                                                                             summary: mail.message.bodySummary,
                                                                             translatedBody: mail.message.bodyHtml, isBodyClipped: mail.message.isBodyClipped, showOriginalText: false) {
            updateCurrentMailTitleView(translatedInfo: nil)
            // View Original
            callJavaScript(jsString)
        }
    }

}

// MARK: - Intercept

extension MailMessageListController {
    func handleShowInterceptedImages(args: [String: Any], in webView: WKWebView) {
        guard let messageID = args["messageID"] as? String else { return }
        MailInterceptWebImageHelper.updateInterceptWhiteList(
            messageID: messageID,
            store: accountContext.accountKVStore
        )
        trackInterceptedBannerClick(action: "display_image")
    }

    func handleInterceptedMoreAction(args: [String: Any], in webView: WKWebView) {
        guard let messageID = args["messageID"] as? String,
              let messageItem = viewModel.mailItem?.messageItems.first(where: { $0.message.id == messageID }) else {
            return
        }

        var hasTrustItem = false
        var hasShowItem = false
        var pop: UDActionSheet?
        var popArray: [PopupMenuActionItem] = []

        if !Display.pad {
            pop = UDActionSheet(config: UDActionSheetUIConfig())
        }

        if Store.settingData.getCachedCurrentAccount()?.mailSetting.userType != .tripartiteClient
            && Store.settingData.hasEnterpriseMail
            && statInfo.from.shouldShowTrustSender
            && fromLabel != Mail_LabelId_Stranger
        {
            hasTrustItem = true
            let title = BundleI18n.MailSDK.Mail_ExternalImagesNotShown_TrustThisSender_Button
            if Display.pad {
                let trustItem = PopupMenuActionItem(title: title, icon: UIImage()) { [weak self] (_, _) in
                    self?.showTrustSenderAlert(messageID: messageID, messageItem: messageItem)
                }
                popArray.append(trustItem)
            } else {
                pop?.addDefaultItem(text: title) { [weak self] in
                    self?.showTrustSenderAlert(messageID: messageID, messageItem: messageItem)
                }
            }
        }

        if !messageItem.showSafeTipsBanner && Store.settingData.hasEmailService {
            hasShowItem = true
            let title = BundleI18n.MailSDK.Mail_ExternalImagesNotShown_ShowAll_Button
            if Display.pad {
                let showAllItem = PopupMenuActionItem(title: title, icon: UIImage()) { [weak self] (_, _) in
                    self?.showDisplayAllAlert()
                }
                popArray.append(showAllItem)
            } else {
                pop?.addDefaultItem(text: title) { [weak self] in
                    self?.showDisplayAllAlert()
                }
            }
        }

        if !hasTrustItem && !hasShowItem {
            MailLogger.info("No item is appended, skip show panel")
            return
        }

        if Display.pad,
           let buttonX = args["buttonX"] as? CGFloat,
           let buttonY = args["buttonY"] as? CGFloat,
           let buttonWidth = args["buttonWidth"] as? CGFloat,
           let buttonHeight = args["buttonHeight"] as? CGFloat {
            let placeholderView = MailPassthroughView(frame: CGRect(
                x: buttonX,
                y: buttonY,
                width: buttonWidth,
                height: buttonHeight
            ))
            placeholderView.backgroundColor = .clear
            webView.addSubview(placeholderView)
            let popVC = PopupMenuPoverViewController(items: popArray)
            popVC.hideIconImage = true
            popVC.modalPresentationStyle = .popover
            popVC.popoverPresentationController?.backgroundColor = UIColor.ud.bgBody
            popVC.popoverPresentationController?.sourceView = placeholderView
            popVC.popoverPresentationController?.permittedArrowDirections = .up
            popVC.popoverPresentationController?.delegate = popVC
            navigator?.present(popVC, from: self)
            popVC.dismissCallback = { [weak placeholderView] in
                placeholderView?.removeFromSuperview()
            }
        } else if let pop = pop {
            pop.setCancelItem(text: BundleI18n.MailSDK.Mail_Common_Cancel)
            navigator?.present(pop, from: self)
        } else {
            mailAssertionFailure("Missing args in handleInterceptedMoreAction")
        }

        trackInterceptedBannerClick(action: "more")
    }

    private func showTrustSenderAlert(messageID: String, messageItem: MailMessageItem) {
        let pageIndex = currentPageIndex
        let senderAddress = messageItem.message.from.address
        let isUnauthorized = viewModel.mailItem?.isAllFromAuthorized == false
        let v2FG = accountContext.featureManager.open(.blockSender, openInMailClient: false)
        let content = (isUnauthorized && !v2FG)
        ? BundleI18n.MailSDK.Mail_ExternalImagesNotShown_SenderMayBePretended_TrustThisSender_Desc(senderAddress, BundleI18n.MailSDK.Mail_ExternalImagesPrivacyConcernsLearnMore_Button)
        : BundleI18n.MailSDK.Mail_ExternalImagesNotShown_TrustThisSender_Desc(senderAddress, BundleI18n.MailSDK.Mail_ExternalImagesPrivacyConcernsLearnMore_Button)
        showInterceptOptionAlert(
            title: BundleI18n.MailSDK.Mail_ExternalImagesNotShown_TrustThisSender_Title,
            content: content,
            actionTitle: BundleI18n.MailSDK.Mail_ExternalImagesNotShown_TrustThisSenderTrust_Button,
            isTrust: true
        ) { [weak self] in
            guard let self = self else { return }
            MailDataSource.shared.addSenderToWebImageWhiteList(sender: [messageItem.message.from])
                .observeOn(MainScheduler.instance)
                .subscribe { [weak self] _ in
                    guard let self = self else { return }
                    // 手动点击触发
                    if pageIndex != self.currentPageIndex {
                        MailLogger.info("Current page changed, skip updating intercepted images")
                        return
                    } else if let messageIDs = self.viewModel.mailItem?.messageItems.filter({ $0.message.from.address == senderAddress }).map({ $0.message.id }).joined(separator: ",") {
                        self.callJSFunction("showInterceptedImages", params: [messageIDs], isUserAction: true,  withThreadId: nil)
                    } else {
                        self.callJSFunction("showInterceptedImages", params: [messageID], isUserAction: true, withThreadId: nil)
                    }
                    UDToast.showSuccess(with: BundleI18n.MailSDK.Mail_ExternalImagesNotShown_TrustThisSenderTrusted_Toast, on: self.view)
                } onError: { [weak self] e in
                    guard let self = self else { return }
                    MailLogger.info("Failed to add sender to white list, error: \(e)")
                    UDToast.showFailure(with: BundleI18n.MailSDK.Mail_Toast_OperationFailed, on: self.view)
                }.disposed(by: self.disposeBag)
        }
        trackInterceptedBannerClick(action: "trust_from")
    }

    private func showDisplayAllAlert() {
        let pageIndex = currentPageIndex
        showInterceptOptionAlert(
            title: BundleI18n.MailSDK.Mail_ExternalImagesNotShown_ShowAll_Title,
            content: BundleI18n.MailSDK.Mail_ExternalImagesNotShown_ShowAll_Desc(BundleI18n.MailSDK.Mail_ExternalImagesPrivacyConcernsLearnMore_Button),
            actionTitle: BundleI18n.MailSDK.Mail_ExternalImagesNotShown_ShowAllConfirm_Button,
            isTrust: false
        ) { [weak self] in
            guard let self = self else { return }
            if var account = Store.settingData.getCachedPrimaryAccount() {
                Store.settingData.updateSettings(.webImageDisplay(enable: true), of: &account) { [weak self] in
                    guard let self = self else { return }
                    if pageIndex != self.currentPageIndex {
                        MailLogger.info("Current page changed, skip updating intercepted images")
                    } else {
                        // 手动点击触发
                        self.callJSFunction("showInterceptedImages", params: [""], isUserAction: true, withThreadId: nil)
                        UDToast.showSuccess(with: BundleI18n.MailSDK.Mail_ExternalImagesNotShown_AllShown_Toast, on: self.view)
                    }
                } onError: { [weak self] error in
                    guard let self = self else { return }
                    MailLogger.info("Failed to changed web image disaplay setting, error: \(error)")
                    UDToast.showFailure(with: BundleI18n.MailSDK.Mail_Toast_OperationFailed, on: self.view)
                }
            }
        }
        trackInterceptedBannerClick(action: "always_display")
    }

    func showInterceptOptionAlert(title: String, content: String, actionTitle: String, isTrust: Bool, action: @escaping () -> Void) {
        let alert = LarkAlertController()
        if !title.isEmpty {
            alert.setTitle(text: title)
        }

        let textView = ActionableTextView.alertWithLinkTextView(
            text: content,
            actionableText: BundleI18n.MailSDK.Mail_ExternalImagesPrivacyConcernsLearnMore_Button
        ) { [weak self] in
            if let urlString = ProviderManager.default.commonSettingProvider?.stringValue(key: "block-web-image"),
               let url = URL(string: urlString)
            {
                MailLogger.info("Click intercept help page")
                UIApplication.shared.open(url)
            } else {
                MailLogger.error("Failed to get intercept help page url")
            }
            if isTrust {
                self?.trackInterceptedTrustAlertClick(action: "more_detail")
            } else {
                self?.trackInterceptedDisplayAlertClick(action: "more_detail")
            }

        }
        alert.setContent(view: textView)
        alert.addCancelButton() { [weak self] in
            if isTrust {
                self?.trackInterceptedTrustAlertClick(action: "cancel")
            } else {
                self?.trackInterceptedDisplayAlertClick(action: "cancel")
            }
        }

        alert.addPrimaryButton(text: actionTitle, dismissCompletion: { [weak self] in
            action()
            if isTrust {
                self?.trackInterceptedTrustAlertClick(action: "trust")
            } else {
                self?.trackInterceptedDisplayAlertClick(action: "always_display")
            }
        })

        navigator?.present(alert, from: self)
    }

    func handleShowInterceptedBanner(args: [String: Any], in webView: WKWebView) {
        guard let messageID = args["messageID"] as? String,
              let messageItem = viewModel.mailItem?.messageItems.first(where: { $0.message.id == messageID }) else {
            return
        }

        MailTracker.log(
            event: "email_network_image_banner_read_view",
            params: ["message_id": messageID,
                     "thread_id": viewModel.mailItem?.threadId ?? "",
                     "label_item": fromLabel]
        )
    }

    func trackInterceptedBannerClick(action: String) {
        MailTracker.log(
            event: "email_network_image_banner_read_click",
            params: ["click": action,
                     "label_item": fromLabel]
        )
    }

    func trackInterceptedTrustAlertClick(action: String) {
        MailTracker.log(
            event: "email_network_image_trust_window_click",
            params: ["click": action,
                     "label_item": fromLabel]
        )
    }

    func trackInterceptedDisplayAlertClick(action: String) {
        MailTracker.log(
            event: "email_network_image_always_display_window_click",
            params: ["click": action,
                     "label_item": fromLabel]
        )
    }
    
    private func _showInterceptSendAlert(messageID: String, action: MailSendAction,
                                         completion: @escaping (_ needBlockImage: Bool, _ isCancel: Bool) -> Void) {
        callJSFunction("checkMessageHasWebImageBanner", params: [messageID]) { [weak self] value, error in
            guard let self = self else { return }
            if let hasBanner = value as? String, hasBanner == "false" {
                if self.viewModel.mailItem?.messageItems.first(where: { $0.message.id == messageID })?.message.isBodyClipped == true {
                    self.callJSFunction("isMessageIntercepted", params: [messageID]) { [weak self] value, error in
                        if let hasBanner = value as? String, hasBanner == "false" {
                            completion(false, false)
                        } else {
                            completion(true, false)
                        }
                    }
                } else {
                    completion(false, false)
                }
            } else {
                let actionType: String = {
                    switch action {
                    case .reply, .sendToChat_Reply: return "reply"
                    case .replyAll: return "reply_all"
                    case .forward, .sendToChat_Forward: return "forward"
                    default: return ""
                    }
                }()

                let alert = LarkAlertController(config: UDDialogUIConfig(style: .vertical))
                alert.setTitle(text: action.isReply ? BundleI18n.MailSDK.Mail_ExternalImagesNotShown_LoadInReply_Title : BundleI18n.MailSDK.Mail_ExternalImagesNotShown_LoadForward_Title)
                alert.setContent(text: action.isReply ? BundleI18n.MailSDK.Mail_ExternalImagesNotShown_LoadInReply_Desc : BundleI18n.MailSDK.Mail_ExternalImagesNotShown_LoadForward_Desc)
                alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_ExternalImagesNotShown_Load_Button, dismissCompletion:  {
                    completion(false, false)
                    MailTracker.log(
                        event: "email_network_image_alert_click",
                        params: ["click": "display_image",
                                 "action": actionType,
                                 "label_item": self.fromLabel]
                    )
                })
                alert.addSecondaryButton(text: BundleI18n.MailSDK.Mail_ExternalImagesNotShown_DontLoad_Button, dismissCompletion:  {
                    completion(true, false)
                    MailTracker.log(
                        event: "email_network_image_alert_click",
                        params: ["click": "do_not_display_image",
                                 "action": actionType,
                                 "label_item": self.fromLabel]
                    )
                })
                alert.addCancelButton(dismissCompletion: {
                    completion(true, true)
                })
                self.navigator?.present(alert, from: self)

                MailTracker.log(
                    event: "email_network_image_alert_view",
                    params: ["action": actionType,
                             "label_item": self.fromLabel]
                )
            }
        }
    }

    func fetchAndUpdateCurrentInterceptedState() {
        guard let mailItem = viewModel.mailItem, fromLabel != Mail_LabelId_Spam else { return }

        let messageIDs = MailInterceptWebImageHelper.filterInterceptedMessageIDs(
            messageItems: mailItem.messageItems,
            userID: accountContext.user.userID,
            labelID: fromLabel,
            dataManager: Store.settingData,
            store: accountContext.accountKVStore,
            from: statInfo.from
        )

        guard !messageIDs.isEmpty else { return }

        Observable.zip(messageIDs.map({
            MailDataSource.shared.fetchIsMessageImageBlocked(messageID: $0)
        })).subscribe { result in
            let blockMessageIDs = result.filter({ $0.1 }).map({ $0.0 })
            let blockMessageIDsString = blockMessageIDs.joined(separator: ",")
            let unblockMessageIDs = result.filter({ !$0.1 }).map({ $0.0 })
            let unblockMessageIDsString = unblockMessageIDs.joined(separator: ",")
            if !blockMessageIDsString.isEmpty {
                self.callJSFunction("delayShowInterceptedBanner", params: [blockMessageIDsString], withThreadId: nil)
            }
            if !unblockMessageIDsString.isEmpty {
                // 非手动点击触发
                self.callJSFunction("showInterceptedImages", params: [unblockMessageIDsString], isUserAction: true, withThreadId: nil)
            }
            MailTracker.log(event: "email_web_image_white_list_dev",
                            params: ["total_msg_count": result.count,
                                     "white_list_msg_count": unblockMessageIDs.count,
                                     "black_list_msg_count": blockMessageIDs.count])
        } onError: { e in
            MailLogger.error("Failed to fetch message intercepted state, error: \(e)")
            self.callJSFunction("delayShowInterceptedBanner", params: [messageIDs.joined(separator: ",")], withThreadId: nil)
        }.disposed(by: disposeBag)
    }
}

// MARK: Read Receipt
extension MailMessageListController {
    func handleDontSendReceipt(args: [String: Any], in webView: WKWebView) {
        guard let messageID = args["messageID"] as? String else { return }
        let threadId = self.viewModel.threadId // 确保结果返回后关闭正确的 banner
        self.accountContext.readReceiptManager.dontSendReadReceipt(threadID: threadId,
                                                                   messageID: messageID,
                                                                   fromLabelID: fromLabel,
                                                                   on: self.view)
        MailTracker.log(event: "email_read_receipt_banner_click",
                        params: ["click": "not_send",
                                 "is_stranger": fromLabel == Mail_LabelId_Stranger ? "True" : "False",
                                 "label_item": fromLabel,
                                 "mail_account_type": Store.settingData.getMailAccountType()])
    }

    func handleSendReceipt(args: [String: Any], in webView: WKWebView) {
        guard let messageID = args["messageID"] as? String else { return }
        let threadID = self.viewModel.threadId // 确保结果返回后关闭正确的 banner
        if let mail = self.viewModel.mailItem?.getMessageItem(by: messageID) {
            // 陌生人需要弹窗
            showStrangerReadReceiptAlertIfNeeded() { [weak self] (needHandleStrangerCard, needSendReadReceipt) in
                guard let `self` = self else { return }
                if needHandleStrangerCard {
                    self.manageStrangerThread(threadIDs: [threadID], status: true,
                                              isSelectAll: false, dismissMsgListSecretly: true)
                    self.closeScene(completionHandler: nil)
                }
                if needSendReadReceipt {
                    self.callJSFunction("readReceiptBannerShowLoading", params: [messageID], withThreadId: threadID)
                    self.accountContext.readReceiptManager.sendReadReceipt(threadID: threadID,
                                                                           messageID: messageID,
                                                                           msgTimestamp: mail.message.createdTimestamp,
                                                                           languageId: mail.message.localeLanguage,
                                                                           on: self.view)
                }
            }
            MailTracker.log(event: "email_read_receipt_banner_click",
                            params: ["click": "send",
                                     "is_stranger": fromLabel == Mail_LabelId_Stranger ? "True" : "False",
                                     "label_item": fromLabel,
                                     "mail_account_type": Store.settingData.getMailAccountType()])
        }
    }

    func handleMessageDraftClick(args: [String: Any], in webView: WKWebView) {
        guard let messageID = args["messageID"] as? String else { return }
        if let mail = self.viewModel.mailItem?.getMessageItem(by: messageID) {
            if let draft : Email_Client_V1_Draft = mail.drafts.max(by: { $0.createdTimestamp < $1.createdTimestamp }) {
                let mailDraft = MailDraft(with: draft)
                if let vc = MailSendController.checkMailTab_makeSendNavController(accountContext: accountContext,
                                                                                     messageID: messageID,
                                                                                     action: .messagedraft,
                                                                                     draft: mailDraft,
                                                                                     statInfo: MailSendStatInfo(from: .messageDraftClick, newCoreEventLabelItem: "none"),
                                                                                     trackerSourceType: .feedDraftAction,
                                                                                  feedCardId: self.feedCardId) {
                       self.navigator?.present(vc, from: self)
                }
            }
        }
    }

    private func showStrangerReadReceiptAlertIfNeeded(completion: @escaping (_ needHandleStrangerCard: Bool, _ needSendReadReceipt: Bool) -> Void) {
        guard fromLabel == Mail_LabelId_Stranger && accountContext.featureManager.open(.stranger, openInMailClient: false) else {
            completion(false, true)
            return
        }
        if accountContext.userKVStore.bool(forKey: "MailReadReceipt.StrangerAlert.dontShowAlert") {
            completion(true, true)
        } else {
            LarkAlertController.showStrangerReadReceiptAlert(from: self,
                                                             labelItem: fromLabel,
                                                             navigator: accountContext.navigator,
                                                             userStore: accountContext.userKVStore) { needAction in
                completion(needAction, needAction)
            }
            MailTracker.log(event: "email_stranger_read_receipt_window_view",
                            params: ["label_item": fromLabel,
                                     "mail_account_type": Store.settingData.getMailAccountType()])
        }
    }
}

extension MailMessageListController: ReadReceiptDelegate {
    func hideReadReceiptBanner(threadID: String, messageID: String) {
        self.callJSFunction("hideReadReceiptBanner", params: [messageID], withThreadId: threadID)
    }

    func hideReadReceiptBannerLoading(threadID: String, messageID: String) {
        self.callJSFunction("readReceiptBannerHideLoading", params: [messageID], withThreadId: threadID)
    }
}
