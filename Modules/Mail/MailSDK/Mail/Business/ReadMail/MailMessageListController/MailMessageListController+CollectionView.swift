//
//  MailMessageListController+CollectionView.swift
//  MailSDK
//
//  Created by majx on 2020/3/18.
//

import Foundation
import Homeric
import RxSwift
import WebKit
import EENavigator
import LarkAlertController
import LarkLocalizations
import LarkRustClient
import Reachability
import Heimdallr

// MARK: MailMessageListDataServiceRenderDelegate
extension MailMessageListController {
    func getRenderModel(by viewModel: MailMessageListPageViewModel, mailItem: MailItem, lazyLoadMessage: Bool, isPushNewMessage: Bool = false) -> MailMessageListRenderModel {
        let titleHeight: CGFloat
        if pageWidth == 0 {
            // pageWidth没初始化，需要初始化
            if Thread.current == Thread.main {
                pageWidth = view.bounds.width
            } else {
                DispatchQueue.main.sync {
                    self.pageWidth = self.view.bounds.width
                }
            }
        }
        MailMessageListController.logger.info("messagelist rendermodel pageWidth \(pageWidth)")
        if MailMessageListTemplateRender.enableNativeRender {
            var cover: MailReadTitleViewConfig.CoverImageInfo? = nil
            if let info = viewModel.mailSubjectCover() {
                cover = MailReadTitleViewConfig.CoverImageInfo(subjectCover: info)
            }
            let fromLabelID = MsgListLabelHelper.resetFromLabelIfNeeded(viewModel.labelId, msgLabels: viewModel.messageLabels)
            let config = MailReadTitleViewConfig(title: mailItem.displaySubject,
                                                 fromLabel: fromLabelID,
                                                 labels: mailItem.labels,
                                                 isExternal: mailItem.isExternal,
                                                 translatedInfo: nil,
                                                 coverImageInfo: cover,
                                                 spamMailTip: mailItem.spamMailTip,
                                                 needBanner: viewModel.needBanner,
                                                 subjects: subjects)
            titleHeight = MailReadTitleView.calcViewSizeAndLabelsFrame(config: config,
                                                                       attributedString: nil,
                                                                       containerWidth: pageWidth).viewSize.height
        } else {
            titleHeight = 0
        }
        var renderModel = MailMessageListRenderModel(mailItem: mailItem,
                                                     subject: viewModel.subject ?? "",
                                                     pageWidth: pageWidth,
                                                     userID: accountContext.user.userID,
                                                     threadId: mailItem.threadId,
                                                     atLabelId: viewModel.labelId,
                                                     locateMessageId: viewModel.messageId,
                                                     isFromChat: isForwardCard(),
                                                     keyword: keyword,
                                                     paddingTop: webViewContentInsetTop,
                                                     isFullReadMessage: viewModel.isFullReadMessage,
                                                     lazyLoadMessage: lazyLoadMessage,
                                                     titleHeight: titleHeight,
                                                     openProtectedMode: viewModel.openProtectedMode,
                                                     featureManager: accountContext.featureManager,
                                                     statFromType: statInfo.from,
                                                     avatar: self.messageListFeedInfo?.avatar ?? "",
                                                     fromNotice: self.fromNotice,
                                                     importantContactsAddresses: viewModel.importantContactsAddresses,
                                                     isPushNewMessage: isPushNewMessage)
        renderModel.messageLabels = realViewModel.messageLabels
        var newDataSource = realViewModel.getDataSouece()
        if let index = newDataSource.firstIndex(where: { $0.threadId == mailItem.threadId && $0.labelId ==  viewModel.labelId }) {
            let pageVM = newDataSource[index]
            pageVM.messageLabels = realViewModel.messageLabels
            newDataSource[index] = pageVM
        }
        realViewModel.updateDataSource(newDataSource)
        return renderModel
    }

    func getIndexOf(threadId: String) -> Int? {
        return realViewModel.indexOf(threadId: threadId)
    }
    
    func feedGetIndexPathOf() -> IndexPath {
        return IndexPath(row: 0, section: 0)
    }

    func getIndexPathOf(threadId: String) -> IndexPath? {
        if let index = getIndexOf(threadId: threadId) {
            return IndexPath(row: index, section: 0)
        }
        return nil
    }

    func getIndexOf(msgId: String) -> Int? {
        if let index = realViewModel.indexOf(msgId: msgId) {
            return index
        }
        return nil
    }

    func getIndexPathOf(msgId: String) -> IndexPath? {
        if let index = getIndexOf(msgId: msgId) {
            return IndexPath(row: index, section: 0)
        }
        return nil
    }

    func getPageCellOf(msgId: String) -> MailMessageListPageCell? {
        func getCell() -> MailMessageListPageCell? {
            var pageCell: MailMessageListPageCell?
            if let indexPath = getIndexPathOf(msgId: msgId) {
                if let cell = collectionView?.cellForItem(at: indexPath) as? MailMessageListPageCell {
                    pageCell = cell
                } else if let cell = collectionView?.subviews.compactMap({ (cell) -> MailMessageListPageCell? in
                    guard let cell = cell as? MailMessageListPageCell, ((cell.viewModel?.mailItem?.messageItems.map({ $0.message.id }).contains(msgId)) != nil) else { return nil }
                    return cell
                }).first {
                    // collectionView.cellForItem(at: ) will return nil when the cell is not visible
                    // have to iterate the subviews to correctly find the cell
                    pageCell = cell
                }
            }
            return pageCell
        }
        if !Thread.isMainThread {
            var cell: MailMessageListPageCell?
            // collectionView.cellForItem 需要保证在主线程调用
            DispatchQueue.main.sync {
                cell = getCell()
            }
            return cell
        } else {
            return getCell()
        }
    }
    
    func feedgetPageCellOf() -> MailMessageListPageCell? {
        func getCell() -> MailMessageListPageCell? {
            var pageCell: MailMessageListPageCell?
            let indexPath = feedGetIndexPathOf()
            if let cell = collectionView?.cellForItem(at: indexPath) as? MailMessageListPageCell {
                pageCell = cell
            } else if let cell = collectionView?.subviews.compactMap({ (cell) -> MailMessageListPageCell? in
                guard let cell = cell as? MailMessageListPageCell else { return nil }
                return cell
            }).first {
                // collectionView.cellForItem(at: ) will return nil when the cell is not visible
                // have to iterate the subviews to correctly find the cell
                pageCell = cell
            }
            return pageCell
        }
        if !Thread.isMainThread {
            var cell: MailMessageListPageCell?
            // collectionView.cellForItem 需要保证在主线程调用
            DispatchQueue.main.sync {
                cell = getCell()
            }
            return cell
        } else {
            return getCell()
        }
    }

    func getPageCellOf(threadId: String) -> MailMessageListPageCell? {
        func getCell() -> MailMessageListPageCell? {
            var pageCell: MailMessageListPageCell?
            if let indexPath = getIndexPathOf(threadId: threadId) {
                if let cell = collectionView?.cellForItem(at: indexPath) as? MailMessageListPageCell {
                    pageCell = cell
                } else if let cell = collectionView?.subviews.compactMap({ (cell) -> MailMessageListPageCell? in
                    guard let cell = cell as? MailMessageListPageCell, cell.viewModel?.threadId == threadId else { return nil }
                    return cell
                }).first {
                    // collectionView.cellForItem(at: ) will return nil when the cell is not visible
                    // have to iterate the subviews to correctly find the cell
                    pageCell = cell
                }
            }
            return pageCell
        }
        if !Thread.isMainThread {
            var cell: MailMessageListPageCell?
            // collectionView.cellForItem 需要保证在主线程调用
            DispatchQueue.main.sync {
                cell = getCell()
            }
            return cell
        } else {
            return getCell()
        }
    }

    var currentMailMessageListView: MailMessageListView? {
        return currentPageCell?.mailMessageListView
    }

    var currentPageCell: MailMessageListPageCell? {
        if currentPageIndex < dataSource.count,
            let cell = collectionView?.cellForItem(at: IndexPath(row: currentPageIndex, section: 0)) as? MailMessageListPageCell {
            return cell
        }
        return nil
    }

    func getWebViewOf(threadId: String) -> (WKWebView & MailBaseWebViewAble)? {
        if let cell = getPageCellOf(threadId: threadId) {
            return cell.mailMessageListView?.webview
        } else if let preloadWebView = MailMessageListViewsPool.getWebViewFromPool(threadId: threadId) {
            return preloadWebView
        }
        return nil
    }

    func currentWebViewDidLoadFinish() {
        MailLogger.info("mail message list \(viewModel.threadId) page load complete")
    }

    func currentWebViewDidDomReady() {
        self.updateAtInfos()
        MailLogger.info("mail message list \(viewModel.threadId) page dom ready")
        handleFirstVisibleMessage(ids: Array(pendingFirstVisibleIDs))
        
        // execute pending js
        if let callCount = pendingJavaScriptQueue[viewModel.threadId]?.count, callCount > 0 {
            MailMessageListController.logger.info("Executing pending javaScript call")
            for _ in 0..<callCount where pendingJavaScriptQueue[viewModel.threadId]?.isEmpty == false {
                if let javaScriptString = pendingJavaScriptQueue[viewModel.threadId]?.removeFirst() {
                    callJavaScript(javaScriptString)
                }
            }
        }
        markAsRead(vm: viewModel)
        if MailMessageListViewsPool.fpsOpt {
            preRenderRelay.accept(())
        } else {
            preloadMailMessageView()
        }
        if accountContext.featureManager.open(.interceptWebImage, openInMailClient: true) && !accountContext.featureManager.open(.interceptWebImagePhase2, openInMailClient: true) {
            fetchAndUpdateCurrentInterceptedState()
        }
    }

    func renderPreloadMessageView(viewModel: MailMessageListPageViewModel?) {
        guard let viewModel = viewModel, let idx = getIndexOf(threadId: viewModel.threadId), idx != currentPageIndex else {
            return
        }
        MailMessageListController.logger.info("MailMessageList onRenderPreload \(viewModel.threadId)")
        let preloadView = MailMessageListViewsPool.getViewFor(threadId: viewModel.threadId, isFullReadMessage: viewModel.isFullReadMessage, controller: self, provider: accountContext, isFeed: self.isFeedCard)
        if preloadView.superview == nil {
            /// 添加到view，避免 webView 被释放
            view.insertSubview(preloadView, at: 0)
            /// 设置约束，避免webView加载JS逻辑依赖于尺寸
            preloadView.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        if preloadView.superview == view {
            preloadView.isHidden = true
        }
        preloadView.render(by: viewModel,
                           webDelegate: self,
                           controller: self,
                           superContainer: nil,
                           mailActionItemsBlock: { [weak self] in
                            self?.bottomActionItemsFor(idx) ?? []
                           },
                           baseURL: self.realViewModel.templateRender.template.baseURL,
                           delegate: nil)
    }

    func preloadMailMessageView(_ render: Bool = true) {
        // preload next & previous view
        guard !pageIsScrolling else { return }
        MailMessageListController.logStartTime(name: "preloadMailMessageView")

        for i in [currentPageIndex - 1, currentPageIndex + 1] {
            if let viewModel = realViewModel[i] {
                MailMessageListController.logger.info("MailMessageList onPreload \(viewModel.threadId)")
                if viewModel.newMessageTimeEvent == nil {
                    let timeEvent = MailAPMEvent.NewMessageListLoaded()
                    timeEvent.actualStartTime = Date().timeIntervalSince1970
                    timeEvent.markPostStart()
                    viewModel.newMessageTimeEvent = timeEvent
                }
                if viewModel.bodyHtml == nil {
                    MailMessageListController.logger.info("preloadMailMessageView loadHtml \(viewModel.threadId)")
                    realViewModel.startLoadBodyHtml(threadID: viewModel.threadId)
                } else {
                    MailMessageListController.logger.info("preloadMailMessageView render \(viewModel.threadId)")
                    renderPreloadMessageView(viewModel: viewModel)
                }
            }
        }
    }
}

extension MailMessageListController {
    func onLoadBodyHtmlError(viewModel: MailMessageListPageViewModel, error: Error) {
        asyncRunInMainThread { [weak viewModel] in
            guard let viewModel = viewModel else { return }
            viewModel.messageEvent?.endParams.append(MailAPMEventConstant.CommonParam.status_rust_fail)
            viewModel.messageEvent?.endParams.appendError(error: error)
            viewModel.messageEvent?.postEnd()

            let isInBackground = UIApplication.shared.applicationState == .background
            viewModel.newMessageTimeEvent?.endParams.append(MailAPMEvent.NewMessageListLoaded.CommonParam.isInBackground(isInBackground))
            viewModel.newMessageTimeEvent?.endParams.append(MailAPMEventConstant.CommonParam.status_rust_fail)
            viewModel.newMessageTimeEvent?.endParams.append(MailAPMEvent.NewMessageListLoaded.CommonParam.mailStatus("error"))
            viewModel.newMessageTimeEvent?.endParams.appendError(error: error)
            viewModel.newMessageTimeEvent?.postEnd()
        }

        MailMessageListController.logger.error("onLoadBodyHtmlError", error: error)
        if viewModel.labelId == Mail_LabelId_SEARCH {
            MailTracker.log(event: "email_message_list_load_error_view", params: ["search_type": statInfo.fromString])
        }
        if error.localizedDescription.contains("[&message_ids] is empty") {
            // 已删除、已撤回的异常场景，提示邮件不存在
            // dismissSelf and show alert
            asyncRunInMainThread { [weak self] in
                guard let self = self else { return }
                let viewController = WindowTopMostFrom(vc: self)
                self.dismissSelf() {
                    let alert = LarkAlertController()
                    alert.setTitle(text: BundleI18n.MailSDK.Mail_Common_EmailNotExisted)
                    alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_Alert_OK)
                    self.navigator?.present(alert, from: viewController)
                }
            }
        } else {
            // 其他case，显示错误页面
            if statInfo.from == .bot, accountContext.featureManager.open(.openBotDirectly, openInMailClient: false), error.mailErrorCode == 483 {
                // Bot 读信场景，查到不到 LabelId
                viewModel.loadErrorType = .botLabelError
            } else if statInfo.from == .bot,
                      accountContext.featureManager.open(.openBotDirectly, openInMailClient: false),
                      error.mailErrorCode == 100052 || error.mailErrorCode == 100053 || error.mailErrorCode == 100054 {
                // Bot 读信场景，查找 LabelId 超时
                viewModel.loadErrorType = .botLabelNetworkError
            } else if statInfo.from == .emailReview, let rcError = error as? RCError, case let .businessFailure(errorInfo: errorInfo) = rcError, errorInfo.errorCode == 403 {
                // 邮件审核场景，添加无权限错误处理
                viewModel.loadErrorType = .noPermission
            } else if let connection = Reachability()?.connection, connection == .none {
                viewModel.loadErrorType = .offline
            } else if let rcError = error as? RCError, case let .businessFailure(errorInfo: errorInfo) = rcError, errorInfo.errorCode == 250601 {
                viewModel.loadErrorType = .strangerError
            } else if error.mailErrorCode == 100000, realViewModel.isForDeleteSingleMessage() {
                // applink删除邮件场景 若邮件已被删除 会走到这里
                viewModel.loadErrorType = .botLabelError
            } else if let emptyError = error as? emptyError, case let .empty(isEmpty: isEmpty) = emptyError, isEmpty == true, !viewModel.feedCardId.isEmpty {
                viewModel.loadErrorType = .feedEmpty
            } else {
                viewModel.loadErrorType = .normal
            }
            messageListViewModelDidUpdate(threadId: viewModel.threadId)
        }
    }
    
    func feedMessageListViewModelDidUpdate(feedCardId: String) {
        asyncRunInMainThread { [weak self] in
            guard let self = self else { return }
            
            if let viewModel = self.realViewModel[0] {
                var finalPageCell: MailMessageListPageCell?
                if let pageCell = self.feedgetPageCellOf() {
                    finalPageCell = pageCell
                    MailMessageListController.logStartTime(name: "messageListViewModelDidUpdate pageCell")
                    pageCell.render(
                        by: self.dataSource[0],
                        baseURL: self.realViewModel.templateRender.template.baseURL,
                        provider: self.accountContext,
                        mailActionItemsBlock: {
                            return []
                    })
                }
            }
        }
    }

    func messageListViewModelDidUpdate(threadId: String) {
        asyncRunInMainThread { [weak self] in
            guard let self = self else { return }
            if let index = self.getIndexOf(threadId: threadId), let viewModel = self.realViewModel[index] {
                var finalPageCell: MailMessageListPageCell?
                if let pageCell = self.getPageCellOf(threadId: threadId) {
                    finalPageCell = pageCell
                    MailMessageListController.logStartTime(name: "messageListViewModelDidUpdate pageCell")
                    pageCell.render(
                        by: self.dataSource[index],
                        baseURL: self.realViewModel.templateRender.template.baseURL,
                        provider: self.accountContext,
                        mailActionItemsBlock: { [weak self] in
                            guard let `self` = self else { return [] }
                            if self.realViewModel.isForDeleteSingleMessage() {
                                return []
                            }
                            return self.bottomActionItemsFor(index)
                    })
                } else {
                    MailMessageListController.logStartTime(name: "messageListViewModelDidUpdate reload")
                    self.renderPreloadMessageView(viewModel: self.realViewModel[threadId: threadId])
                }
                MailMessageListController.logger.info("mail message list view model push refresh with index \(index)")
                /// if is current page index, update thread actions
                if index == self.currentPageIndex && !self.realViewModel.isFeed {
                    self.markAsRead(vm: viewModel)
                    if let mailItem = viewModel.mailItem {
                        _ = self.checkNeedDismissSelf(newMailItem: mailItem)
                        if finalPageCell?.isDomReady == true {
                            self.setupThreadActions(mailItem: mailItem)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - UICollectionViewDataSource & UICollectionViewDelegate
extension MailMessageListController {
    func _collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }

    func _collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        MailMessageListController.logStartTime(name: "cellForItemAt")
        let isFirstScreen = !didLoadFirstScreen && indexPath.row == initIndex
        if let pageCell = collectionView.dequeueReusableCell(withReuseIdentifier: MailMessageListController.PageCellIdentifier,
                                                             for: indexPath) as? MailMessageListPageCell {
            let pageIndex = indexPath.row
            let viewModel = dataSource[pageIndex]
            let isTerminatedRetry = terminatedRetryThreads.contains(viewModel.threadId)
            terminatedRetryThreads.remove(viewModel.threadId)

            if !didLoad {
                didLoad = true

                if initIndex > 0 {
                    collectionView.scrollToItem(at: IndexPath(row: initIndex, section: 0), at: .centeredHorizontally, animated: false)
                    pageCell.render(
                        by: nil,
                        baseURL: realViewModel.templateRender.template.baseURL,
                        provider: accountContext,
                        mailActionItemsBlock: { [weak self] in
                            return self?.bottomActionItemsFor(indexPath.row) ?? []
                    })
                    return pageCell
                }
            } else {
                didLoadFirstScreen = true
                if isFirstScreen {
                    // skip fisrtscreen
                } else {
                    MailMessageListController.logger.info("message list cell reload for row index: \(pageIndex) threadId: \(viewModel.threadId) isTerminated: \(isTerminatedRetry)")
                    // 非首屏需要创建一个绑定上去
                    let event = MailAPMEvent.MessageListLoaded()
                    var timeEventFrom: MailAPMEventConstant.CommonParam
                    if isTerminatedRetry {
                        // 被杀掉重试的case
                        event.commonParams.append(MailAPMEvent.MessageListLoaded.CommonParam.sence_other("terminated_retry"))
                        timeEventFrom = MailAPMEventConstant.CommonParam.customKeyValue(key: "from", value: "terminated_retry")
                    } else {
                        event.commonParams.append(MailAPMEvent.MessageListLoaded.CommonParam.sence_swipe_thread)
                        timeEventFrom = MailAPMEventConstant.CommonParam.customKeyValue(key: "from", value: "swipe_thread")
                    }
                    event.actualStartTime = Date().timeIntervalSince1970
                    event.commonParams.appendOrUpdate(MailAPMEvent.MessageListLoaded.CommonParam.clickToInitTime(0))
                    event.markPostStart()
                    viewModel.messageEvent = event
                    if viewModel.newMessageTimeEvent == nil {
                        let timeEvent = MailAPMEvent.NewMessageListLoaded()
                        timeEvent.actualStartTime = Date().timeIntervalSince1970
                        timeEvent.markPostStart()
                        viewModel.newMessageTimeEvent = timeEvent
                    }
                    viewModel.newMessageTimeEvent?.commonParams.append(timeEventFrom)
                    updateMessageLoadParam(viewModel: viewModel, event: event, timeEvent: viewModel.newMessageTimeEvent)

                    // new event
                    let newEvent = NewCoreEvent(event: .email_message_list_view)
                    newEvent.params = ["label_item": statInfo.newCoreEventLabelItem, "mail_display_type": Store.settingData.threadDisplayType(),
                                       "result_hint_from": statInfo.searchHintFrom,
                                       "is_trash_or_spam_list": statInfo.isTrashOrSpamList,
                                       "mail_service_type": Store.settingData.getMailAccountListType()]
                    newEvent.post()
                    if fromLabel == Mail_LabelId_Stranger {
                        MailTracker.log(event: "email_stranger_message_list_view", params: ["label_item": Mail_LabelId_Stranger])
                    }
                }
            }
            pageCell.controller = self
            pageCell.webDelegate = self
            pageCell.delegate = self

            if isTerminatedRetry,
               let terminatedCount = MailMessageListViewsPool.threadTerminatedCountDict[viewModel.threadId],
               terminatedCount > 0 {
                viewModel.bodyHtml = nil
                viewModel.openProtectedMode = true
                MailMessageListController.logger.info("message list collection cell for row enter protected mode, threadId: \(viewModel.threadId)")
            }

            MailMessageListController.logger.info("message list collection cell for row index: \(pageIndex) threadId: \(viewModel.threadId) isTerminated: \(isTerminatedRetry)")
            if viewModel.bodyHtml == nil {
                // Load rust & bodyHtml
                MailMessageListController.logStartTime(name: "html_nil")
                pageCell.showLoading(true)
                if viewModel.feedCardId.isEmpty {
                    realViewModel.startLoadBodyHtml(threadID: viewModel.threadId)
                } else {
                    MailLogger.info("[MailModelManager] getGloballyEnterChatPosition: \(MailModelManager.shared.getGloballyEnterChatPosition())")
                    // 1 -> 上次定位 2 -> 最新位置
                    var timestamp : Int64 = 0
                    var timestampOperater = false
                    MailLogger.info("[Mail Feed locate] fromNotice: \(self.fromNotice)")
                    if MailModelManager.shared.getGloballyEnterChatPosition() == 1 && self.fromNotice != true {
                        // 定位到上次位置
                        if let lastFifthTimestampSet: [String: Int64] = self.accountContext.accountKVStore.value(forKey: "MailFeedList.lastFifthTimestamp"),
                           let lastFifthTimestamp = lastFifthTimestampSet[self.feedCardId] {
                            timestamp = lastFifthTimestamp
                            timestampOperater = true
                        }
                    } else {
                        // 定位到全新邮件
                        timestamp = 0
                        timestampOperater = false
                    }
                    let forceGetFromNet = self.fromNotice
                    realViewModel.startLoadFeedBodyHtml(feedCardId: viewModel.feedCardId,
                                                        timestampOperator: timestampOperater,
                                                        timestamp: timestamp,
                                                        forceGetFromNet: forceGetFromNet,
                                                        isDraft: false)
                }
            } else {
                // Direct render
                MailMessageListController.logStartTime(name: "direct_render")
                viewModel.messageEvent?.commonParams.appendOrUpdate(MailAPMEvent.MessageListLoaded.CommonParam.from_db(1))
                viewModel.newMessageTimeEvent?.commonParams.appendOrUpdate(MailAPMEvent.NewMessageListLoaded.CommonParam.isThreadInfoReady(true))
            }
            pageCell.render(
                by: viewModel,
                baseURL: realViewModel.templateRender.template.baseURL,
                provider: accountContext,
                mailActionItemsBlock: { [weak self] in
                    guard let self = self else { return [] }
                    if self.isFeedCard {
                        return []
                    } else {
                        return self.bottomActionItemsFor(indexPath.row) ?? []
                    }
            })
            return pageCell
        }
        return MailMessageListPageCell()
    }

    func _collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        /// load more data if come from thread list
        if statInfo.from == .threadList && MailMessageListController.isShortcutEnabled {
            checkNeedLoadMore(indexPath: indexPath)
        }
        if let viewModel = realViewModel[indexPath.row] {
            viewModel.newMessageTimeEvent?.userVisibleTime = Date().timeIntervalSince1970
        }
    }

    func _collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let viewModel = realViewModel[indexPath.row] {
            if let event = viewModel.messageEvent {
                event.endParams.append(MailAPMEventConstant.CommonParam.status_user_leave)
                event.postEnd()
            }
        }
        (cell as? MailMessageListPageCell)?.mailMessageListView?.postMessageLoadEvent(isUserLeave: true)

    }

    private func checkNeedLoadMore(indexPath: IndexPath) {
        /// when scroll to middle, load more data
        let currentLabelId = fromLabel
        if let lastMessageTimeStamp = dataSource.last?.lastmessageTime,
           (indexPath.row == (dataSource.count - 10) ||
                indexPath.row == dataSource.count - 1) {
            MailMessageListController.logger.info("message list collection load more at label:\(currentLabelId) index\(indexPath.row)")
            EventBus.$threadListEvent.accept(.needLoadMoreThreadIfNeeded(label: currentLabelId,
                                                                         timestamp: lastMessageTimeStamp, source: .messageList))
        }
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDelegateFlowLayout
extension MailMessageListController {
    func _collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.bounds.size
    }

    func _collectionView(_ collectionView: UICollectionView, targetContentOffsetForProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        guard updateContentOffsetOnOrientationChanged else {
            return proposedContentOffset
        }
        // change to correct content offset on orientation changed
        let newOffset = CGPoint(x: CGFloat(currentPageIndex) * collectionView.bounds.width, y: 0)
        return newOffset
    }
}

// MARK: - MailMessageListCellDelegate
extension MailMessageListController: MailMessageListCellDelegate {
    func titleLabelsTapped() {
        changeLabels(isThreadAction: false)
    }

    func onClickMessageListRetry(threadId: String) {
        if let viewModel = realViewModel[threadId: threadId] {
            viewModel.loadErrorType = nil
            collectionView?.reloadData()
            messageListViewModelDidUpdate(threadId: viewModel.threadId)
        }
    }

    func startLoadHtml(threadId: String) {
        onRenderPageStart(threadId)
        let bodyHtmlLength = threadBodyHtmlLengthMap[threadId] ?? 0
        domReadyMonitor.start(threadID: threadId, datalen: UInt(bodyHtmlLength))
    }

    func flagTapped() {
        handleFlag()
    }

    func notSpamTapped() {
        notSpamMail()
        trackSpamBannerClick()
    }

    func bannerTermsAction() {
        let domain = accountContext.provider.configurationProvider?.getDomainSetting(key: .suiteMainDomain).first ?? ""
        let lang = LanguageManager.currentLanguage.languageIdentifier
        let urlString = "https://\(domain)/terms?lang=\(lang)"
        if let url = URL(string: urlString) {
            navigator?.push(url, from: self)
            MailTracker.log(event: "email_attachment_preview_risk_banner_click",
                            params: ["click": "open_user_agreement",
                                     "target": "none",
                                     "mail_account_type": Store.settingData.getMailAccountType()])
        }
    }

    func bannerSupportAction() {
        guard let urlString = ProviderManager.default.commonSettingProvider?.stringValue(key: "banned_customer_service_url") else { return }
        if let url = URL(string: urlString) {
            navigator?.push(url, from: self)
            MailTracker.log(event: "email_attachment_preview_risk_banner_click",
                            params: ["click": "customer_service",
                                     "target": "none",
                                     "mail_account_type": Store.settingData.getMailAccountType()])
        }
    }

    func didClickStrangerReply(status: Bool) {
        self.manageStrangerThread(threadIDs: [self.viewModel.threadId], status: status, isSelectAll: false)
        self.closeScene(completionHandler: nil)
    }

    func avatarClickHandler(mailAddress: MailAddress) {
        accountContext.profileRouter.openNameCard(accountId: accountContext.accountID, address: mailAddress.address,
                                                  name: mailAddress.mailDisplayName, fromVC: self) { [weak self] success in
            guard let self = self else { return }
            MailLogger.info("[mail_stranger] msgList avatarClickHandler: \(success)")
            if success {
                self.manageStrangerThread(threadIDs: [self.viewModel.threadId], status: true, isSelectAll: false, dismissMsgListSecretly: true)
                self.closeScene(completionHandler: nil)
            }
        }
    }
}

// MARK: - UIScrollViewDelegate
extension MailMessageListController {
    func _scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !updateContentOffsetOnOrientationChanged else { return }
        guard scrollView == collectionView else { return }
        setNavBarHidden(false, animated: true)
        let center = CGPoint(x: scrollView.contentOffset.x + (scrollView.frame.width / 2), y: (scrollView.frame.height / 2))
        if let indexPath = collectionView?.indexPathForItem(at: center), indexPath.row != currentPageIndex {
            /// skip first track
            if startTrackPageView {
                trackPageViewEvent()
            }
            // 左右切换退出搜索
            if isInSearchMode {
                exitContentSearch()
            }
            currentPageIndex = indexPath.row
            if self.didRenderDic[mailItem.threadId] ?? false {
                MailTracker.endRecordTimeConsuming(event: Homeric.EMAIL_THREAD_DISPLAY, params: nil, useNewKey: true)
                MailTracker.startRecordTimeConsuming(event: Homeric.EMAIL_THREAD_DISPLAY, params: ["threadid": mailItem.threadId]) // 结束上一个thread计时并开启下一个thread计时
            }
            /// when currentPageIndex changed, refresh page view (thread action in nav bar)
            if let viewModel = self.realViewModel[currentPageIndex] {
                self.markAsRead(vm: viewModel, abandonThreadIDs: preThreadIDs())
                if let mailItem = viewModel.mailItem {
                    self.setupViewsWithItem(mailItem: mailItem)
                }
            }
            startTrackPageView = true
            MailMessageListController.logger.info("message list collection current page index \(currentPageIndex)")
            self.updateAtInfos()
            if MailMessageListViewsPool.fpsOpt {
                fpsRelay.accept(true)
            }
        }
    }
    
    private func updateAtInfos() {
        guard self.addressNameFg else { return }
        // update at infos
        if let infos = self.currentPageCell?.mailMessageListView?.atInfos {
            self.handleAtInfos(infos: infos)
        }
        if let change = self.currentPageCell?.mailMessageListView?.addressChanged, change == true {
            self.currentPageCell?.mailMessageListView?.addressChanged = false
            self.handleAddressChange()
        }
    }

    private func preThreadIDs() -> [String] {
        var threadIDs = [String]()
        if let viewModel = self.realViewModel[currentPageIndex - 1] {
            threadIDs.append(viewModel.threadId)
        }
        if let viewModel = self.realViewModel[currentPageIndex + 1] {
            threadIDs.append(viewModel.threadId)
        }
        return threadIDs
    }

    func _scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard scrollView == collectionView else { return }
        pageIsScrolling = true
        if MailMessageListViewsPool.fpsOpt {
            if !self.fpsFlag {
                self.fpsFlag = true
                HMDFPSMonitor.shared().enterFluencyCustomScene(withUniq: "Lark.MailSDK.Message.Scroll")
            }
        }
    }

    func _scrollViewEndScroll(_ scrollView: UIScrollView) {
        guard scrollView == collectionView else { return }
        pageIsScrolling = false
    }

    func _scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard scrollView == collectionView else { return }
        self.scrollViewEndScroll(scrollView)
    }

    func _scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView == collectionView else { return }
        scrollViewEndScroll(scrollView)
    }
}
