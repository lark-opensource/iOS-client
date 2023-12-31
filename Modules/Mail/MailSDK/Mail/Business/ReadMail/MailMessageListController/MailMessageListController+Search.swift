//
//  MailMessageListController+Search.swift
//  MailSDK
//
//  Created by zhaoxiongbin on 2021/5/11.
//

import Foundation
import UniverseDesignToast
import Reachability
import UniverseDesignIcon

extension MailMessageListController {
    func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            var containerViewInsets = view.safeAreaInsets
            containerViewInsets.bottom = keyboardHeight
            containerViewEdgesConstraint?.update(inset: containerViewInsets)
        }
    }

    func keyboardWillHide(_ notification: Notification) {
        var containerViewInsets = view.safeAreaInsets
        containerViewInsets.bottom = 0
        containerViewEdgesConstraint?.update(inset: containerViewInsets)
    }

    /// 获取打点的label字符串
    /// custom label 返回 "LABEL", folder 返回 "FOLDER"，分享到卡片 返回 "FORWARD_CARD"
    /// 其他 case 返回 labelID
    func getLogLabelID() -> String {
        let labelID: String
        if isForwardCard() {
            labelID = "FORWARD_CARD"
        } else if let labelModel = mailItem.labels.first(where: { $0.id == fromLabel }) {
            switch labelModel.tagType {
            case .label:
                if labelModel.isSystem {
                    labelID = labelModel.id
                } else {
                    // CUSTOM LABEL
                    labelID = "LABEL"
                }
            case .folder:
                labelID = "FOLDER"
            }
        } else {
            labelID = fromLabel
        }
        return labelID
    }

    func startContentSearch() {
        // 开始监听键盘尺寸
        observeForKeyboard()
        let params = ["show_type": "thread_action", "thread_item": getLogLabelID()]
        MailTracker.log(event: "email_message_list_search_click", params: params)
        messageNavBar.showSearchBar()
        callJS_startContentSearch()
        if let index = getIndexOf(threadId: mailItem.threadId), let pageCell = self.collectionView?.cellForItem(at: IndexPath(row: index, section: 0)) as? MailMessageListPageCell {
            pageCell.mailMessageListView?.toggleSearchMode(true)
            currentMailMessageListView?.searchLeftButton?.isEnabled = false
            currentMailMessageListView?.searchLeftButton?.tintColor = UIColor.ud.iconDisabled
            currentMailMessageListView?.searchRightButton?.isEnabled = false
            currentMailMessageListView?.searchRightButton?.tintColor = UIColor.ud.iconDisabled
        }
    }
    func emlAsAttachmentForSingleMessage(msgID: String, subject: String) {
        if isForwardCard() {
            guard let forwardInfo = realViewModel.forwardInfo else {
                UDToast.showFailure(with: BundleI18n.MailSDK.Mail_Share_Notrcptoast,
                                    on: self.view)
                MailLogger.info("[eml_as_attachment] get forwardInfo fail")
                return
            }
            MailDataServiceFactory
                .commonDataService?.getCardMessageBizId(bizId: msgID,
                                                        cardId: forwardInfo.cardId,
                                                        userId: forwardInfo.ownerUserId).subscribe(onNext: { [weak self] (resp) in
                    guard let `self` = self else { return }
                    if !resp.bizID.isEmpty {
                        self.emlAsAttachment(bizId: resp.bizID,
                                             subject: subject,
                                             click: "message_action")
                    } else {
                        UDToast.showFailure(with: BundleI18n.MailSDK.Mail_Share_Notrcptoast,
                                            on: self.view)
                        MailLogger.info("[eml_as_attachment] get card bizId fail")
                        return
                    }
                }, onError: { [weak self] (error) in
                    guard let `self` = self else { return }
                    UDToast.showFailure(with: BundleI18n.MailSDK.Mail_Share_Notrcptoast,
                                        on: self.view)
                    MailLogger.error("[eml_as_attachment] getCardMessageBizId error: \(error).")
                }).disposed(by: self.disposeBag)
        } else {
            self.emlAsAttachment(bizId: msgID,
                                 subject: subject,
                                 click: "message_action")
        }
    }
    func emlAsAttachment() {
        guard let reach = Reachability(), reach.connection != .none else {
                UDToast.showFailure(with: BundleI18n.MailSDK.Mail_MailAttachment_UnableToForwardAsAttachment_Toast,
                                    on: self.view)
                return
        }
        MailDataServiceFactory
            .commonDataService?.getThreadLastMessageInfoRequest(labelId: self.fromLabel, threadIds: [self.mailItem.threadId]).subscribe(onNext: { [weak self] (resp) in
                guard let `self` = self else { return }
                if let info = resp.messageInfoList.first {
                    self.emlAsAttachment(bizId: info.bizID, subject: info.subject, click: "thread_action")
                } else {
                    UDToast.showFailure(with: BundleI18n.MailSDK.Mail_MailAttachment_UnableToForwardAsAttachment_Toast,
                                        on: self.view)
                    MailLogger.error("[eml_as_attachment] message more action no info return")
                }
            }, onError: { [weak self] (error) in
                guard let `self` = self else { return }
                UDToast.showFailure(with: BundleI18n.MailSDK.Mail_MailAttachment_UnableToForwardAsAttachment_Toast,
                                    on: self.view)
                MailLogger.error("[eml_as_attachment] message more action error: \(error).")
            }).disposed(by: self.disposeBag)
    }
    private func emlAsAttachmentEvent(click: String) {
        let event = NewCoreEvent(event: .email_message_list_click)
        var params = ["click": click,
                      "target": "none",
                      "label_item": statInfo.newCoreEventLabelItem,
                      "is_trash_or_spam_list": statInfo.isTrashOrSpamList,
                      "action_type": "foward_as_attachment"]
        if click == "thread_action" {
            params["action_position"] = "thread_bar"
        }
        event.post()
    }
    func emlAsAttachment(bizId: String, subject: String, click: String) {
        guard let reach = Reachability(), reach.connection != .none else {
                UDToast.showFailure(with: BundleI18n.MailSDK.Mail_MailAttachment_UnableToForwardAsAttachment_Toast,
                                    on: self.view)
                return
        }
        guard !bizId.isEmpty else { return }
        self.emlAsAttachmentEvent(click: click)
        var statInfo = MailSendStatInfo(from: .emlAsAttachment,
                                        newCoreEventLabelItem: "none")
        statInfo.emlAsAttachmentInfos = [EmlAsAttachmentInfo(subject: subject,
                                                           bizId: bizId)]
        let vc = MailSendController.makeSendNavController(accountContext: self.accountContext,
                                                          action: .new,
                                                          labelId: self.viewModel.labelId,
                                                          statInfo: statInfo,
                                                          trackerSourceType: .emlAsAttachment)
        self.accountContext.navigator.present(vc, from: self)
    }

    func searchContent(_ keyword: String?) {
        realViewModel.search.startSearch(keyword: keyword)
    }
}

extension MailMessageListController: MailMessageNavBarDelegate {
    func searchKeywordDidChange(_ keyword: String?) {
        searchContent(keyword)
    }

    func exitContentSearch() {
        realViewModel.search.quitSearch()
        messageNavBar.hideSearchBar()
        if let index = getIndexOf(threadId: mailItem.threadId), let pageCell = self.collectionView?.cellForItem(at: IndexPath(row: index, section: 0)) as? MailMessageListPageCell {
            pageCell.mailMessageListView?.toggleSearchMode(false)
        }
        stopObserveForKeyboard()
    }
    
}

extension MailMessageListController: MailMessageSearchDelegate {
    func callJSFunction(_ funName: String, params: [String], withThreadId threadID: String?, completionHandler: ((Any?, Error?) -> Void)?) {
        callJSFunction(funName, params: params, isUserAction: nil, withThreadId: threadID, completionHandler: completionHandler)
    }

    func quitSearch() {
        showSearchLoading(false)
    }

    func showSearchLoading(_ show: Bool) {
        messageNavBar.showLoading(show)
        if show {
            currentMailMessageListView?.searchLeftButton?.isEnabled = false
            currentMailMessageListView?.searchRightButton?.isEnabled = false
        }
    }

    func updateNativeTitleUI(searchKey: String?, locateIdx: Int?) {
        currentPageCell?.mailMessageListView?.titleView?.updateNativeTitleUI(searchKey: searchKey, locateIdx: locateIdx)
    }

    func didStartInputSearch() {
        showSearchLoading(true)
    }

    func shouldNativeSearchTitle() -> Bool {
        return MailMessageListTemplateRender.enableNativeRender
    }

    func getSearchMailItem() -> MailItem? {
        return mailItem
    }

    func updateSearchView(currentIdx: Int, total: Int) {
        messageNavBar.updateSearchCount(currentIdx: currentIdx, total: total)
        currentMailMessageListView?.searchLeftButton?.isEnabled = total != 0 && currentIdx != 0
        currentMailMessageListView?.searchRightButton?.isEnabled = total != 0 && currentIdx + 1 < total
        showSearchLoading(false)
    }

    func getItemContentFor(msgId: String) -> String {
        if let messageItem = viewModel.mailItem?.messageItems.first(where: { $0.message.id == msgId }) {
            let replaceRecall = realViewModel.templateRender.shouldReplaceRecallBanner(for: messageItem, myUserId: myUserId ?? "")
            let mailRecallState = MailRecallManager.shared.recallState(for: messageItem)
            var itemContent = realViewModel.templateRender.replaceForItemContent(
                messageItem: messageItem,
                myUserId: myUserId ?? "",
                replaceRecall: replaceRecall,
                mailRecallState: mailRecallState,
                atLabelID: fromLabel,
                fromChat: isForwardCard(),
                isFeedCard: realViewModel.isFeed)

            itemContent = MailMessageListTemplateRender.preprocessHtml(
                itemContent,
                messageID: msgId,
                messageItem: messageItem,
                isFromChat: isForwardCard(),
                sharedService: accountContext.sharedServices)
            itemContent = itemContent.doubleEscapeForJson()
            return itemContent
        }
        return ""
    }
}

struct MsgListLabelHelper {
    static func resetFromLabelIfNeeded(_ fromLabel: String, msgLabels: [String: String]) -> String {
        if fromLabel == Mail_LabelId_SEARCH_TRASH_AND_SPAM {
            let spamMsg = msgLabels.values.filter({ $0 == Mail_LabelId_Spam })
            return spamMsg.isEmpty ? fromLabel : Mail_LabelId_Spam
        } else {
            return fromLabel
        }
    }
}
