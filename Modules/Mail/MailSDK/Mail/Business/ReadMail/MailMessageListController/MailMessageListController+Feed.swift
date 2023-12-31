//
//  MailMessageListController+Feed.swift
//  MailSDK
//
//  Created by ByteDance on 2023/9/5.
//

import Foundation
import UniverseDesignIcon
import UniverseDesignFont
import UniverseDesignColor
import UniverseDesignToast
import LarkAlertController
import RustPB
import RxSwift
import UniverseDesignTheme
import LarkSplitViewController
import LarkUIKit

extension MailMessageListController: MailFeedNavBarDelegate {
    func feedMoreAction(address: String, name: String, sender: UIControl) {
        let unfollowItem = PopupMenuActionItem(title: BundleI18n.MailSDK.Mail_KeyContact_UnfollowPopover_Unfollow_Button,
                                                     icon: UDIcon.laterCancelOutlined,
                                                     callback: { [weak self] (_, action) in
            guard let `self` = self else { return }
            let alert = LarkAlertController()
            alert.setTitle(text:BundleI18n.MailSDK.Mail_KeyContact_UnfollowPopover_Title)
            alert.setContent(text:BundleI18n.MailSDK.Mail_KeyContact_UnfollowPopover_Desc(name, address))
            alert.addSecondaryButton(text:BundleI18n.MailSDK.Mail_KeyContact_UnfollowPopover_NotNow_Button)
            alert.addDestructiveButton(text: BundleI18n.MailSDK.Mail_KeyContact_UnfollowPopover_Unfollow_Button, dismissCompletion: { [weak self] in
                guard let self = self else { return }
                var followeeInfo = Email_Client_V1_FolloweeInfo()
                var followeeID = Email_Client_V1_FolloweeID()
                followeeID.externalMailAddress.mailAddress = address
                followeeInfo.followeeID = followeeID
                followeeInfo.name = name
                self.requestUnFollowStatus(action: .unfollow, followeeList: [followeeInfo])
            })
            self.navigator?.present(alert, from: self)
        })
        let checkoutDarkModeStr = !self.isContentLight ? BundleI18n.MailSDK.Mail_SwitchToLightMode_Button : BundleI18n.MailSDK.Mail_SwitchToDarkMode_Button
        let icon = !self.isContentLight ? UDIcon.dayOutlined : UDIcon.nightOutlined
        let checkoutDarkModeItem = PopupMenuActionItem(title: checkoutDarkModeStr,
                                                  icon: icon,
                                                  callback: { [weak self] (_, _) in
            guard let `self` = self else { return }
            self.isContentLight = !self.isContentLight
            let modelsCount = self.realViewModel.allMailViewModels.count
            for i in 0...modelsCount-1 {
                guard let viewModel = self.realViewModel[i] else { continue }
                if let webView = self.getWebViewOf(threadId: viewModel.threadId) {
                    // 当前及前后页面
                    if i >= self.currentPageIndex - 1 && i <= self.currentPageIndex + 1 {
                        self.callJavaScript("window.updateContentStyle(\(self.isContentLight))", in: webView)
                    }
                }
                // html文本会被缓存在bodyHtml里，更改了内容区DM后需要清空使下一次浏览时重新走组装template的流程
                viewModel.bodyHtml = nil
            }
            self.accountContext.messageListPreloader.clear()
            let kvStore = MailKVStore(space: .global, mSpace: .global)
            if self.isContentLight != kvStore.value(forKey: "mail_contentSwitch_isLight") {
                kvStore.set(self.isContentLight, forKey: "mail_contentSwitch_isLight")
            }
            self.actionsFactory.resetActionConfigMap(isContentLM: self.isContentLight)
        })

        var items: [PopupMenuActionItem] = []
        var isDarkModeTheme: Bool = false
        if #available(iOS 13.0, *) {
            isDarkModeTheme = UDThemeManager.getRealUserInterfaceStyle() == .dark
        }
        
        items.append(unfollowItem)
        if (isDarkModeTheme) {
            items.append(checkoutDarkModeItem)
        }

        var vc: UIViewController
        
        if rootSizeClassIsSystemRegular {
            vc = PopupMenuPoverViewController(items: items)
            vc.modalPresentationStyle = .popover
            vc.popoverPresentationController?.backgroundColor = UIColor.ud.bgBody
            vc.popoverPresentationController?.sourceView = sender
        } else {
            vc = PopupMenuViewController(items: items)
            vc.modalPresentationStyle = .overFullScreen
        }
        self.navigator?.present(vc, from: self, animated: false, completion: nil)
    }
    func requestUnFollowStatus(action: Email_Client_V1_FollowAction, followeeList: [Email_Client_V1_FolloweeInfo]) {
        MailDataSource.shared.fetcher?.updateFollowStatus(action: .unfollow, followeeList: followeeList)
        .observeOn(MainScheduler.instance)
        .subscribe { [weak self] _ in
            guard let self = self else { return }
            UDToast.showFailure(with: BundleI18n.MailSDK.Mail_KeyContact_Unfollowed_Toast, on: self.view)
            self.backItemTappedOrCloseScene()
        } onError: { [weak self] e in
            guard let self = self else { return }
            MailLogger.info("Failed to updateFollowType, error: \(e)")
            UDToast.showFailure(with: BundleI18n.MailSDK.Mail_KeyContact_FollowFailed_Toast, on: self.view)
        }.disposed(by: self.disposeBag)
    }
    
    // MARK: - MailFeedNavBarDelegate
    func jumpToProfile(emailAddress: String, name: String) {
        var item = AddressRequestItem()
        item.address = emailAddress
        MailDataServiceFactory.commonDataService?.getMailAddressNames(addressList: [item]).subscribe( onNext: { [weak self]  MailAddressNameResponse in
            guard let `self` = self else { return }
            if let respItem = MailAddressNameResponse.addressNameList.first,
               !respItem.larkEntityID.isEmpty,
                respItem.larkEntityID != "0",
                !respItem.tenantID.isEmpty,
                respItem.tenantID != "0" {
                self.accountContext.provider.routerProvider?.openUserProfile(userId: respItem.larkEntityID, fromVC: self)
            } else {
                let accountId = Store.settingData.currentAccount.value?.mailAccountID ?? ""
                self.accountContext.provider.routerProvider?.openNameCard(accountId: accountId, address: emailAddress, name: name, fromVC: self, callBack: { _ in })
            }
            }, onError: { (error) in
                MailLogger.error("token getAddressNames resp error \(error)")
            }).disposed(by: disposeBag)
    }
    
    func loadMoreFeedMailItems(completion: @escaping (_ hasMore: Bool, _ newMailItem: MailItem) -> Void) {
        if let timestamp = self.viewModel.mailItem?.messageItems.last?.message.createdTimestamp {
            self.loadFeedMailItem(feedCardId: self.viewModel.feedCardId, 
                                  timestampOperator: true,
                                  timestamp: Int64(timestamp),
                                  forceGetFromNet: false,
                                  isDraft: false) { (mailItem, hasMore) in
                // 追加loadMore数据
                var newMailFeedMessageItems: [FromViewMailMessageItem]
                newMailFeedMessageItems = self.mailItem.feedMessageItems + mailItem.feedMessageItems
                newMailFeedMessageItems = newMailFeedMessageItems.sorted { $0.item.message.createdTimestamp < $1.item.message.createdTimestamp }
                let newMailItem = MailItem(feedCardId: self.viewModel.feedCardId,
                                           feedMessageItems: newMailFeedMessageItems,
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
                self.mailItem = newMailItem
                MailLogger.info("message sendState feedMessageItems.count:(loadMore) \(newMailItem.feedMessageItems.count)")
                completion(hasMore, newMailItem)
            } errorCallBack: {
                UDToast.showFailure(with: BundleI18n.MailSDK.Mail_KeyContact_FollowFailed_Toast, on: self.view ?? UIView())
                self.callJSFunction("stopLoadMore", params: ["\(false)"])
            }
        }
    }
    
    func tipsLoadMoreHandler() {
        self.loadMoreFeedMailItems { hasMore, newMailItem in
            self.readTag(newMailItem: newMailItem)
            if hasMore {
                self.tipsLoadMoreHandler()
                self.callJSFunction("scrollToBottomMessage", params: [])
            } else {
                self.tipsBtn.hideLoading()
                self.tipsBtn.isHidden = true
                self.unReadMessageCount = 0
                self.callJSFunction("loadMoreEnable", params: ["\(true)", "\(false)"])
                DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.normal) { [weak self] in
                    self?.callJSFunction("scrollToBottomMessage", params: [])
                }
            }
        }
    }
    
    // 点击电梯标记已读
    func readTag(newMailItem: MailItem) {
        let feedMessageItems = newMailItem.feedMessageItems.filter({$0.item.message.isRead != true})
        for feedMessageItem in feedMessageItems {
            if let labelId = MailTagDataManager.shared.getTagModels(feedMessageItem.labelIds).first?.id {
                Store.fetcher?.multiMutLabelForThread(threadIds: [feedMessageItem.threadID],
                                                      messageIds: [feedMessageItem.item.message.id],
                                                      addLabelIds: [],
                                                      removeLabelIds: [Mail_LabelId_UNREAD],
                                                      fromLabelID: labelId)
                            .subscribe(onNext: {(_) in
                                MailLogger.info("[MailFeed] readTag threadID: \(feedMessageItem.threadID) messageId: \(feedMessageItem.item.message.id) labelId:\(labelId) ")
                            }, onError: { (error) in
                                MailLogger.error("[MailFeed] readTag threadID: \(feedMessageItem.threadID) messageId: \(feedMessageItem.item.message.id) labelId:\(labelId) ", error: error)
                            }).disposed(by: self.disposeBag)
            }
        }
    }
    
    func updateMessagesDraftSummary(messageIds: [String]) {
        MailDataSource.shared.getFromItem(feedCardId: self.feedCardId, messageOrDraftIds: messageIds)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] result in
                guard let self = self else { return }
                let draftItems = result.draftItems
                self.updateMessagesDraftSummary(draftItems: draftItems)
            }).disposed(by: disposeBag)
    }

    func deleteMessagesDraft(draftIds: [String], draftItems: [Email_Client_V1_FromViewDraftItem]) {
        let deletedDraftIds = draftIds.filter { item in
            !draftItems.contains { $0.item.id == item}
        }
        var deletedDraftMessageIds : [String] = []
        let messageItems = self.mailItem.messageItems
        for messageItem in messageItems {
            MailLogger.info("[mail_feed_list] removeMessagesDraftSummary messageItem.drafts.isEmpty:\(messageItem.drafts.isEmpty), messageItem.subject:\(messageItem.message.subject)")
            for deletedDraftId in deletedDraftIds {
                for draft in messageItem.drafts {
                    if draft.id == deletedDraftId {
                        deletedDraftMessageIds.append(messageItem.message.id)
                        MailLogger.info("[mail_feed_list] removeMessagesDraftSummary  draftId:\(draft.id), messageId: \(messageItem.message.id), deletedDraftMessageIds:\(deletedDraftMessageIds)")
                    }
                }
                if messageItem.drafts.isEmpty {
                    deletedDraftMessageIds.append(messageItem.message.id)
                }
            }
        }
        if !deletedDraftMessageIds.isEmpty {
            guard let data = try? JSONSerialization.data(withJSONObject: deletedDraftMessageIds, options: []),
                  let JSONString = NSString(data: data, encoding: String.Encoding.utf8.rawValue)?.replacingOccurrences(of: "\\", with: "\\\\") else { mailAssertionFailure("fail to serialize json"); return }
            self.callJSFunction("removeMessagesDraftSummary", params: [JSONString])
        }
    }
    
    func handleOutboxStateChange(){
        if let address = self.messageListFeedInfo?.address {
            headerViewManager.fetchOutboxStateForChange(feedCardID: self.feedCardId, address: address, messageIDs: []) {
                self.view.addSubview(self.messagelistHeader)
                self.messagelistHeader.snp.makeConstraints { make in
                    make.top.equalTo(self.messageNavBar.snp.bottom)
                    make.width.equalToSuperview()
                }
                self.containerView.snp.remakeConstraints { make in
                    make.top.equalToSuperview().offset(self.messagelistHeader.previewCardCurrentTopMargin() + self.view.safeAreaInsets.top)
                    make.left.right.bottom.equalToSuperview()
                }
            }
        }
    }
    
    func updateMessagesDraftSummary(draftItems: [Email_Client_V1_FromViewDraftItem]) {
        var resultDic: [String: String] = [:]
        var needUpdateMessageIds :[String] = []
        for draftItem in draftItems {
            let messageId = draftItem.item.replyMessageID
            let summary = draftItem.item.bodySummary
            needUpdateMessageIds.append(messageId)
            MailLogger.info("[Mail handleFeedDraftItem] window.updateMessagesDraftSummary \(draftItem.item.replyMessageID), summary:\(draftItem.item.bodySummary)")
            resultDic[messageId] = summary
        }
        guard let data = try? JSONSerialization.data(withJSONObject: resultDic, options: []),
              let JSONString = NSString(data: data, encoding: String.Encoding.utf8.rawValue)?.replacingOccurrences(of: "\\", with: "\\\\") else { mailAssertionFailure("fail to serialize json"); return }
        self.callJSFunction("updateMessagesDraftSummary", params: [JSONString])
    }
    
    func handleFeedMessageItemStatus(messageIDs: [String]) {
        guard !messageIDs.isEmpty else { return }
        MailDataSource.shared.getFromItem(feedCardId: self.feedCardId, messageOrDraftIds: messageIDs)
            .observeOn(MainScheduler.instance)
            .subscribe (onNext: { [weak self] result in
                guard let self = self else { return }
                let msgItems = result.msgItems
                var newFromViewMessageItems : [Email_Client_V1_FromViewMessageItem] = []
                for msgItem in msgItems {
                    newFromViewMessageItems.append(msgItem)
                }
                var feedMessageItems : [Email_Client_V1_FromViewMessageItem] = self.mailItem.feedMessageItems
                guard !newFromViewMessageItems.isEmpty else { return }
                for newFromViewMessageItem in newFromViewMessageItems {
                    if let index = feedMessageItems.firstIndex(where: { $0.item.message.id == newFromViewMessageItem.item.message.id }) {
                        MailLogger.info("message sendState old: \(feedMessageItems[index].item.message.sendState) new:  \(newFromViewMessageItem.item.message.sendState) subject:\(feedMessageItems[index].item.message.subject) ")
                        if let address = self.messageListFeedInfo?.address {
                            headerViewManager.fetchOutboxStateForChange(feedCardID: self.feedCardId, address: address, messageIDs: []) {
                                self.view.addSubview(self.messagelistHeader)
                                self.messagelistHeader.snp.makeConstraints { make in
                                    make.top.equalTo(self.messageNavBar.snp.bottom)
                                    make.width.equalToSuperview()
                                }
                                self.containerView.snp.remakeConstraints { make in
                                    make.top.equalToSuperview().offset(self.messagelistHeader.previewCardCurrentTopMargin() + self.view.safeAreaInsets.top)
                                    make.left.right.bottom.equalToSuperview()
                                }
                            }
                        }
                        feedMessageItems[index] = newFromViewMessageItem
                    }
                }
                let newMailItem = MailItem(feedCardId: self.feedCardId,
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
                self.refreshMessageList(with: newMailItem)
                for messageId in messageIDs {
                    self.reloadFeedLabel(with: newMailItem, messageId: messageId, hideFlag: self.hideFlagButton())
                }
                self.mailItem = newMailItem
            }).disposed(by: disposeBag)
    }
    
    func handleFrom(_ fromChange: Email_Client_V1_MailFromChangeResponse ) {
        // 推送处理三种场景，新增邮件（电梯出现），原来为空新增邮件，被删除邮件，
        MailLogger.info("[mail_feed_list] feed handle from start")
        guard !fromChange.messageMetas.isEmpty && !self.feedCardId.isEmpty && fromChange.feedCardID == self.feedCardId else { return }
        let hasNewMessagesMetaList = fromChange.messageMetas.filter({$0.isNewMessage == true})
        self.unReadMessageCount = hasNewMessagesMetaList.count + self.unReadMessageCount
        let messageIds = fromChange.messageMetas.map { $0.messageID }
        if self.accountContext.featureManager.open(FeatureKey(fgKey: .mailToFeed, openInMailClient: false)) {
            self.checkShowDraftBtn()
        }
        for message in fromChange.messageMetas {
            if message.isNewMessage {
                MailLogger.info("[mail_feed_list] push a new message messageId: \(message.messageID)")

                if (!(Store.settingData.getCachedCurrentSetting()?.mobileMessageDisplayRankMode ?? false) ) {
                    let show = self.mailItem.messageItems.count > 1 && !hasNewMessagesMetaList.isEmpty
                    self.isShowTipsBtn(hidden: !show)
                    self.setTipsBtnNum(count: self.unReadMessageCount)
                    self.callJSFunction("loadMoreEnable", params: ["\(true)", "\(true)"])
                }
                self.loadMoreFeedMailItems {[weak self] hasMore, _ in
                    guard let self = self else { return }
                    if !hasMore {
                        self.callJSFunction("loadMoreEnable", params: ["\(true)", "\(false)"])
                    }
                }
            } else if message.isDraft {
                self.updateMessagesDraftSummary(messageIds: [message.messageID])
            }
        }
        MailDataSource.shared.getFromItem(feedCardId: self.feedCardId, messageOrDraftIds: messageIds)
            .observeOn(MainScheduler.instance)
            .subscribe (onNext: { [weak self] result in
                guard let self = self else { return }
                // 处理DraftItem 删除草稿
                let draftItems = result.draftItems
                self.deleteMessagesDraft(draftIds: messageIds, draftItems: draftItems)
                // 处理messageItem
                // Find the min and max timestamps in existing message items
                let msgItems = result.msgItems
                var minTimestamp: Int64 = .max
                var maxTimestamp: Int64 = .min
                for messageItem in self.mailItem.feedMessageItems {
                    let timestamp = messageItem.item.message.createdTimestamp
                    minTimestamp = min(minTimestamp, timestamp)
                    maxTimestamp = max(maxTimestamp, timestamp)
                }
                
                // Filter and update the message items
                var updatedMessageItems = self.mailItem.feedMessageItems
                if updatedMessageItems.isEmpty && self.viewModel.loadErrorType == .feedEmpty {
                    // emptyView to load new msg
                    if let isDomReady = self.currentPageCell?.isDomReady, isDomReady == true {
                        self.loadFeedMailItem(feedCardId: self.feedCardId, timestampOperator: false, timestamp: 0, forceGetFromNet: false, isDraft: false) { mailItem, _ in
                            if !mailItem.feedMessageItems.isEmpty {
                                self.refreshMessageList(with: mailItem)
                                self.currentPageCell?.showLoadFail(false)
                            }
                            MailLogger.info("[mail_feed] refreshNewMessageMailItem feedMessageItems.count: \(mailItem.feedMessageItems.count)")
                        } errorCallBack: {
                            self.callJSFunction("stopLoadMore", params: ["\(false)"])
                        }
                    } else {
                        self.viewModel.loadErrorType = nil
                        self.realViewModel.startLoadFeedBodyHtml(feedCardId: self.feedCardId, timestampOperator: false, timestamp: 0, forceGetFromNet: false, isDraft: false)
                    }
                } else {
                    MailLogger.info("[mail_feed_list] get a push  messageIds:\(messageIds), msgItems count: \(msgItems.count)")
                        // delect push handler
                    let deletedMessageIds = messageIds.filter { item in
                        !msgItems.contains { $0.item.message.id == item }
                    }
                    updatedMessageItems = updatedMessageItems.filter{ item in
                        !deletedMessageIds.contains { $0 == item.item.message.id }
                    }
                    
                    for msgItem in msgItems {
                        let pushTimestamp = msgItem.item.message.createdTimestamp
                        if updatedMessageItems.isEmpty {
                            updatedMessageItems.append(msgItem)
                        } else if pushTimestamp >= minTimestamp && pushTimestamp <= maxTimestamp {
                            // Check if there is an existing message item with the same timestamp and message ID
                            if let existingIndex = self.mailItem.feedMessageItems.firstIndex(where: { $0.item.message.createdTimestamp == pushTimestamp && $0.item.message.id == msgItem.item.message.id }) {
                                // Replace the existing message item
                                updatedMessageItems[existingIndex] = msgItem
                                MailLogger.info("[mail_feed_list] updateMessageItem draft count  \(msgItem.item.drafts.count)")
                                MailLogger.info("message sendState feedMessageItemsSendStatus(handleFrom replace) \(msgItem.item.message.sendState), subject:\(msgItem.item.message.subject), messageId: \(msgItem.item.message.id)")
                            } else {
                                // Insert the new message item in chronological order
                                if let insertIndex = updatedMessageItems.firstIndex(where: { $0.item.message.createdTimestamp > pushTimestamp }) {
                                    updatedMessageItems.insert(msgItem, at: insertIndex)
                                } else {
                                    updatedMessageItems.append(msgItem)
                                }
                            }
                        } else if pushTimestamp < minTimestamp {
                            self.callJSFunction("loadMoreEnable", params: ["\(false)", "\(true)"])
                        } else {
                            self.callJSFunction("loadMoreEnable", params: ["\(true)", "\(true)"])
                        }
                    }
                    updatedMessageItems = Array(Set(updatedMessageItems))
                    updatedMessageItems = updatedMessageItems.sorted { $0.item.message.createdTimestamp < $1.item.message.createdTimestamp }
                    let updatedMailItem = MailItem(feedCardId: self.feedCardId,
                                            feedMessageItems: updatedMessageItems,
                                            threadId: "",
                                            messageItems: [],
                                            composeDrafts: [],
                                            labels: [],
                                            code: .none,
                                            isExternal: true,
                                            isFlagged: false,
                                            isRead: false,
                                            isLastPage: false)
                    self.refreshMessageList(with: updatedMailItem)
                    self.mailItem = updatedMailItem
                    MailLogger.info("message sendState feedMessageItems.count:(handleFrom) \(mailItem.feedMessageItems.count)")
                    if updatedMailItem.feedMessageItems.isEmpty {
                        self.viewModel.loadErrorType = .feedEmpty
                        self.currentPageCell?.showLoadFail(true)
                    } else {
                        self.currentPageCell?.showLoadFail(false)
                    }
                }
            }).disposed(by: disposeBag)
    }
    
    func handleFollowStatusChange(_ infoList: [Email_Client_V1_FolloweeInfo]) {
        let strangerStyle = self.accountContext.featureManager.open(.stranger) && self.viewModel.labelId == Mail_LabelId_Stranger
        guard self.accountContext.featureManager.open(FeatureKey(fgKey: .mailToFeed, openInMailClient: false)) && !strangerStyle else { return }
        for info in infoList {
            MailLogger.info("mail message follow status refreshed [handleFollowStatusChange] for status \(info.followeeID.externalMailAddress.mailAddress)")
            let address = info.followeeID.externalMailAddress.mailAddress
            let action = info.status == .followed ? "follow" : "unfollow"
            if self.isFeedCard {
                if action == "unfollow" {
                    if Display.pad {
                        self.accountContext.navigator.showDetail(SplitViewController.makeDefaultDetailVC(),
                                                                 wrap: LkNavigationController.self, from: self)
                    }
                    if let nav = navigationController, nav.viewControllers.count > 1 {
                        for i in stride(from: nav.viewControllers.count - 1, through: 0, by: -1) {
                            let vc = nav.viewControllers[i]
                            if vc != self {
                                navigator?.pop(from: vc, completion: nil)
                            }
                        }
                        navigator?.pop(from: self, completion: nil)
                    } else {
                        MailLogger.info("MailMessageList dismiss")
                        self.dismiss(animated: true, completion: nil)
                    }
                }
            } else {
                self.callJSFunction("updateFollowType", params: [address, action])
            }
        }
    }
    
    func checkShowDraftBtn() {
        MailDataSource.shared.getDraftsBtn(feedCardId: self.feedCardId)
        .observeOn(MainScheduler.instance)
        .subscribe { [weak self] (draftItems, _) in
            guard let self = self else { return }
            if !draftItems.isEmpty && self.accountContext.mailAccount?.isUnuse() == false {
                self.draftListBtn.isHidden = false
            } else {
                self.draftListBtn.isHidden = true
            }
        } onError: { e in
            MailLogger.info("[mail_load_feedDraft] checkShowDraftBtn feedCardId \(self.feedCardId), error \(e)")
        }.disposed(by: self.disposeBag)
    }
}
