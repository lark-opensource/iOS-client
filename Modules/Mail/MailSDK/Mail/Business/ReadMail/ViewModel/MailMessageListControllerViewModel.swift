//
//  MailMessageListControllerViewModel.swift
//  MailSDK
//
//  Created by zhaoxiongbin on 2021/5/11.
//

import Foundation
import RxSwift
import RxRelay
import ThreadSafeDataStructure
import RustPB

public enum emptyError: Error {
    case empty(isEmpty: Bool)
}

protocol MailMessageListControllerViewModelDelegate: AnyObject {
    var shouldLoadRemoteData: Bool { get }

    func getRenderModel(by viewModel: MailMessageListPageViewModel, mailItem: MailItem, lazyLoadMessage: Bool, isPushNewMessage: Bool) -> MailMessageListRenderModel
    func messageListViewModelDidUpdate(threadId: String)
    func feedMessageListViewModelDidUpdate(feedCardId: String)
    func onLoadBodyHtmlError(viewModel: MailMessageListPageViewModel, error: Error)
    func callJSFunction(_ funName: String, params: [String], isUserAction: Bool?, withThreadId threadID: String?, completionHandler: ((Any?, Error?) -> Void)?)
    func showSuccessToast(_ toast: String)
    func showFailToast(_ toast: String)
    func updateFromLabel(_ newLabel: String)
}

protocol MailMessageListControllerViewModeling: AnyObject {
    func callJSFunction(_ funName: String, params: [String], withThreadId threadID: String?, completionHandler: ((Any?, Error?) -> Void)?)
    func showSuccessToast(_ toast: String)
}

/// 管理多个 mailItem 数据， MailMessageListController 的 ViewModel
class MailMessageListControllerViewModel {
    private var loadingThreads = ThreadSafeSet<String>()
    private let loadHTMLOperationQueue: OperationQueue

    private let dataService = MailMessageListDataService()
    private let disposeBag = DisposeBag()

    // feature VM
    private(set) lazy var report: MailMessageListReportViewModel = {
        let reportVM = MailMessageListReportViewModel(delegate: self)
        return reportVM
    }()

    let imageService: MailImageService
    let search = MailMessageSearchViewModel()
    let templateRender: MailMessageListTemplateRender

    let forwardInfo: DataServiceForwardInfo?
    let isBot: Bool
    let isFeed: Bool
    var messageLabels: [String: String] = [:]
    /// 用于标记是否来自永删邮件的applink
    var isForDeletePreview: Bool = false
    var fromNotice: Bool

    init(templateRender: MailMessageListTemplateRender, imageService: MailImageService, forwardInfo: DataServiceForwardInfo?, isBot: Bool, isFeed: Bool, fromNotice: Bool) {
        self.isBot = isBot
        self.imageService = imageService
        self.templateRender = templateRender
        self.forwardInfo = forwardInfo
        self.loadHTMLOperationQueue = OperationQueue()
        self.isFeed = isFeed
        self.fromNotice = fromNotice
        let loadQueue = DispatchQueue(label: "mailmessagelist.loadhtml", qos: .userInteractive)
        loadHTMLOperationQueue.underlyingQueue = loadQueue
        loadHTMLOperationQueue.maxConcurrentOperationCount = 1
        loadHTMLOperationQueue.isSuspended = false
    }

    func isForDeleteSingleMessage() -> Bool {
        let fgOpen = FeatureManager.open(FeatureKey(fgKey: .applinkDelete, openInMailClient: false))
        return self.isForDeletePreview && fgOpen
    }

    func addAttachmentObserver() {
        guard Store.settingData.mailClient else { return }
        imageService.downloadTask.asObservable()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (key, task) in
                guard let `self` = self else { return }
                guard let task = task else { return }
                guard let msgID = task.msgID else {
                    MailLogger.error("[mail_client_att] ❌ task msgID is nil")
                    return
                }
                let threadID = self.dataService.getViewModelOf(msgID: msgID)?.threadId ?? msgID
//                guard let threadID = self.dataService.getViewModelOf(msgID: msgID)?.threadId else {
//                    MailLogger.error("[mail_client_att] ❌ task threadID is nil")
//                    return
//                } // TODO 需要debug这个方法为什么取不到thread id
                var status: MailClientTemplateDownloadState = .needDownload
                guard let change = task.downloadChange else {
                    MailLogger.error("[mail_client_att] ❌ 有对应key的push，但缓存没有task")
                    return
                }
                switch change.status {
                case .success:
                    status = .ready
                case .inflight, .pending:
                    status = .downloading
                case .failed:
                    status = .needDownload
                    if !task.inlineImage { // 内联图片不应该弹框
                        self.delegate?.showFailToast(BundleI18n.MailSDK.Mail_ThirdClient_AttachmentFailedRetry)
                    }
                case .cancel: // FIXME: use unknown default setting to fix warning
                    status = .needDownload
                @unknown default:
                    status = .needDownload
                }
                MailLogger.info("[mail_client_att] msglist updateAttachmentState cancel: \(task.cancel) msgID:\(msgID) fileToken: \(String(describing: task.fileToken)) status:\(status) transSize:\(change.transferSize ?? 0) total:\(change.totalSize ?? 0) threadID:\(threadID)")
                guard let transferSize = change.transferSize, let totalSize = change.totalSize, let token = task.fileToken else {
                    if let token = task.fileToken {
                        let receivedPercentage = 0.01
                        self.delegate?.callJSFunction("updateAttachmentState",
                                                      params: [msgID, token, MailClientTemplateDownloadState.downloading.rawValue, "\(receivedPercentage)", "\(1)"],
                                                      withThreadId: threadID, completionHandler: nil)
                    }
                    MailLogger.error("[mail_client_att] ❌ transferSize: \(change.transferSize ?? 0) totalSize: \(change.totalSize ?? 0) token: \(task.fileToken ?? "")")
                    return
                }
                guard !task.cancel else {
                    MailLogger.error("[mail_client_att] ❌ task has been cancel")
                    self.delegate?.callJSFunction("updateAttachmentState",
                                                  params: [msgID, token, MailClientTemplateDownloadState.needDownload.rawValue, "\(1)", "\(1)"],
                                                  withThreadId: threadID, completionHandler: nil)
                    return
                }
                MailLogger.info("[mail_client_att] msglist updateAttachmentState msgID:\(msgID) fileToken: \(token) status:\(status) transSize:\(transferSize) total:\(totalSize) threadID:\(threadID)")
                if totalSize != 0 {
                    self.delegate?.callJSFunction("updateAttachmentState",
                                                  params: [msgID, token, status.rawValue, "\(transferSize)", "\(totalSize)"],
                                                  withThreadId: threadID, completionHandler: nil)
                }
        }).disposed(by: disposeBag)
    }

    subscript(index: Int) -> MailMessageListPageViewModel? {
        dataService.getViewModelAt(index: index)
    }

    subscript(threadId threadId: String) -> MailMessageListPageViewModel? {
        getViewModelOf(threadId: threadId)
    }

    var allMailViewModels: [MailMessageListPageViewModel] {
        dataService.dataSource.all
    }

    var delegate: (MailMessageSearchDelegate & MailMessageListControllerViewModelDelegate & MailMessageListRenderProcess)? {
        get {
            if let d = _delegate {
                return d
            } else {
                mailAssertionFailure("MailMessageListControllerViewModel delegate not set", ignoreLog: true)
                // error, 不应该走到这里！
                // 如果vc提前被释放了，可能会跑到这个error，需要确认会不会影响用户体验
                return nil
            }
        }
        set {
            _delegate = newValue
        }
    }

    private weak var _delegate: (MailMessageSearchDelegate & MailMessageListControllerViewModelDelegate & MailMessageListRenderProcess)? {
        didSet {
            search.delegate = delegate
        }
    }

    func updateDataSource(_ newDataSource: [MailMessageListPageViewModel]) {
        dataService.dataSource = ThreadSafeArray<MailMessageListPageViewModel>(array: newDataSource)
    }
    
    func getDataSouece() -> [MailMessageListPageViewModel] {
        return dataService.dataSource.all
    }

    func indexOf(threadId: String) -> Int? {
        return dataService.dataSource.all.firstIndex(where: { $0.threadId == threadId })
    }

    func indexOf(msgId: String) -> Int? {
        for (tIndex, vm) in dataService.dataSource.all.enumerated() {
            if (vm.mailItem?.messageItems.first(where: { $0.message.id == msgId }) != nil) {
                return tIndex
            }
        }
        return nil
    }

    private func getViewModelOf(threadId: String) -> MailMessageListPageViewModel? {
        return dataService.dataSource.all.first(where: { $0.threadId == threadId })
    }
    
    private func getViewModelOf(feedCardId: String) -> MailMessageListPageViewModel? {
        return dataService.dataSource.all.first(where: { $0.feedCardId == feedCardId })
    }

    func getViewModelContainsMessage(id: String) -> MailMessageListPageViewModel? {
        return allMailViewModels.first(where: { $0.mailItem?.messageItems.contains(where: { $0.message.id == id }) == true })
    }
    
    /// bot 场景，尝试获取正确的 labelId，再次获取mailItem
    private func getSuitableLabelAndReload(threadId: String,
                                           labelId: String,
                                           messageId: String,
                                           loadRemote: Bool? = nil,
                                           forwardInfo: DataServiceForwardInfo?,
                                           successCallback: ((MailItem, _ isFromNet: Bool) -> Void)?,
                                           errorCallback: ((Error) -> Void)?) {
        // 获取正确的 labelID
        Store.fetcher?.getMessageSuitableInfo(messageId: messageId, threadId: threadId, scene: .readMessage).flatMap({ [weak self] resp -> Observable<(MailItem, Bool)> in
            guard let self = self else { return Observable.empty() }
            let newLabelId = resp.label
            let vm = self.dataService.getViewModelOf(threadId: threadId)
            vm?.labelId = newLabelId
            self.delegate?.updateFromLabel(newLabelId)
            /// 基于新 labelID 再次读信
            return self.dataService.loadMailItem(threadId: threadId, labelId: newLabelId, messageId: messageId, forwardInfo: forwardInfo)
        }).subscribe(onNext: { (mailItem, isFromNet) in
            MailMessageListController.logStartTime(name: "loadMailItem end \(isFromNet)")
            successCallback?(mailItem, isFromNet)
        }, onError: errorCallback)
        .disposed(by: disposeBag)
    }
    
    func loadFeedMailItem(feedCardId: String,
                          timestampOperator: Bool,
                          timestamp: Int64,
                          forceGetFromNet: Bool,
                          isDraft: Bool,
                          successCallback: ((MailItem, Bool) -> Void)?,
                          errorCallback: ((Error) -> Void)?) {
        
        dataService.loadFeedMailItem(feedCardId: feedCardId,
                                     timestampOperator: timestampOperator,
                                     timestamp: timestamp,
                                     forceGetFromNet: forceGetFromNet,
                                     isDraft: isDraft)
        .subscribe(onNext: {[weak self] (mailItem, hasMore) in
            guard let self = self else { return }
            successCallback?(mailItem, hasMore)
        }, onError: errorCallback)
        .disposed(by: disposeBag)
    }

    func loadMailItem(threadId: String,
                      labelId: String,
                      messageId: String?,
                      loadRemote: Bool? = nil,
                      forwardInfo: DataServiceForwardInfo?,
                      successCallback: ((MailItem, _ isFromNet: Bool) -> Void)?,
                      errorCallback: ((Error) -> Void)?) {
        delegate?.onGetRustDataStart(threadId)

        guard !isForDeleteSingleMessage() else {
            loadMailItemWithSingleMsg(threadId: threadId,
                                      messageId: messageId,
                                      successCallback: successCallback,
                                      errorCallback: errorCallback)
            return
        }

        dataService.loadMailItem(threadId: threadId,
                                 labelId: labelId,
                                 messageId: messageId,
                                 forwardInfo: forwardInfo)
        .subscribe(onNext: { [weak self] (mailItem, isFromNet) in
            guard let self = self else { return }
            MailMessageListController.logStartTime(name: "loadMailItem end \(isFromNet)")
            // 需要端上合并请求每个msg所在的label，会影响读信渲染(SpamLabel)
            if labelId == Mail_LabelId_SEARCH_TRASH_AND_SPAM, !mailItem.messageItems.isEmpty {
                let messageLabel = BehaviorRelay<(String, String)?>(value: nil)
                let messageLabels: SafeAtomic<[String: String]> = [:] + .readWriteLock
                _ = mailItem.messageItems.map({
                    let messageItem = $0
                    if Store.settingData.mailClient {
                        messageLabel.accept((messageItem.message.id, labelId))
                    } else {
                        Store.fetcher?.getMessageSuitableInfo(messageId: messageItem.message.id, threadId: threadId, scene: .readMessage)
                            .subscribe(onNext: { (resp) in
                                MailLogger.info("[mail_search] getMessageSuitableLabel msgID: \(messageItem.message.id) label: \(resp.label)")
                                messageLabel.accept((messageItem.message.id, resp.label))
                                //messageLabels.updateValue(resp.label, forKey: messageItem.message.id)
                            }, onError: { (error) in
                                MailLogger.info("[mail_search] getMessageSuitableLabel error: \(error)")
                            }).disposed(by: self.disposeBag)
                    }
                })
                messageLabel.asObservable().subscribe(onNext: { messageLabelInfo in
                    guard let messageLabelInfo = messageLabelInfo else { return }
                    messageLabels.value.updateValue(messageLabelInfo.1, forKey: messageLabelInfo.0)
                    if messageLabels.value.keys.count == mailItem.messageItems.count {
                        MailLogger.info("[mail_search] getMessageSuitableLabel messageLabels: \(messageLabels.value)")
                        self.messageLabels = messageLabels.value
                        successCallback?(mailItem, isFromNet)
                    }
                }).disposed(by: self.disposeBag)
            } else {
                successCallback?(mailItem, isFromNet)
            }
        }, onError: errorCallback)
        .disposed(by: disposeBag)
    }
    
    /// 数据加载完成
    private func feedUpdateVMAndParseHTML(mailItem: MailItem,
                                          completion: @escaping ((MailMessageListPageViewModel) -> Void)) {
        guard let mailViewModel = getViewModelOf(feedCardId: mailItem.feedCardId) else {
            mailAssertionFailure("MessageListVM not found")
            return
        }
        mailViewModel.mailItem = mailItem
        parseMailBodyHtml(for: mailViewModel, onComplete: completion)
    }

    // 拉单封message组装mailItem
    func loadMailItemWithSingleMsg(threadId: String,
                                   messageId: String?,
                                   successCallback: ((MailItem, _ isFromNet: Bool) -> Void)?,
                                   errorCallback: ((Error) -> Void)?) {
        guard let viewModel = self.dataService.getViewModelOf(threadId: threadId),
              let messageId = messageId
        else { return }
        self.dataService.loadMessageItemWithNoMailItem(threadId: threadId,
                                         messageId: messageId)
        .subscribe(onNext: { [weak self] (mailItem) in
            guard let `self` = self else { return }
            Store.fetcher?.getMessageSuitableInfo(messageId: messageId, threadId: threadId, scene: .readMessage)
                .subscribe(onNext: { (resp) in
                    MailLogger.info("[mail_applink_delete] getMessageSuitableLabel msgID: \(messageId) label: \(resp.label)")
                    self.messageLabels.updateValue(resp.label, forKey: messageId)
                    viewModel.labelId = resp.label
                    var newMailItem = mailItem
                    newMailItem.labels = MailTagDataManager.shared.getTagModels([resp.label])
                    if newMailItem.labels.isEmpty {
                        MailLogger.info("[mail_applink_delete] getMessageSuitableLabel getTagModels Empty!")
                    }
                    successCallback?(newMailItem, false)
                }, onError: { (error) in
                    MailLogger.info("[mail_applink_delete] getMessageSuitableLabel error: \(error)")
                }).disposed(by: self.disposeBag)
        }, onError: errorCallback)
        .disposed(by: self.disposeBag)
    }

    /// 数据加载完成.
    private func updateVMAndParseHTML(
        threadId: String,
        mailItem: MailItem,
        isFromNet: Bool,
        completion: @escaping ((MailMessageListPageViewModel) -> Void)
    ) {
        let hasBigMessage = mailItem.messageItems.contains(where: { $0.message.isBodyClipped == true })

        delegate?.onGetRustDataEnd(threadId,
                                   messageCount: mailItem.messageItems.count,
                                   hasBigMessage: hasBigMessage,
                                   isFromNet: isFromNet,
                                   isRead: mailItem.isRead)

        guard let mailViewModel = getViewModelOf(threadId: mailItem.threadId) else {
            mailAssertionFailure("MessageListVM not found")
            return
        }
        mailViewModel.mailItem = mailItem
        parseMailBodyHtml(for: mailViewModel, onComplete: completion)
        let addresses = mailItem.messageItems.map({$0.message.from.address})
        if FeatureManager.open(FeatureKey(fgKey: .mailToFeed, openInMailClient: false)) {
            self.statsImportantContacts(addresses: addresses)
        }
        self.getImportantContacts(addresses: addresses, mailViewModel: mailViewModel)

    }
    
    private func statsImportantContacts(addresses: [String]) {
//        let addresses = self.mailItem.messageItems.map({$0.message.from.address})
        MailDataSource.shared.fetcher?.statsMailImportantContacts(addresses: addresses)
            .observeOn(MainScheduler.instance)
            .subscribe { _ in
                MailLogger.info("succs to StatsMailImportantContacts")
            } onError: { e in
                MailLogger.info("Failed to StatsMailImportantContacts, error: \(e)")
            }.disposed(by: self.disposeBag)
    }
    
    // 更新重要联系人
    private func getImportantContacts(addresses: [String], mailViewModel: MailMessageListPageViewModel) {
        MailDataSource.shared.fetcher?.getMailImportantContacts(addresses: addresses)
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] result in
                guard let self = self else { return }
                let newImportant = Set(result)
                if !newImportant.isEmpty {
                    mailViewModel.importantContactsAddresses = result
                    let importantMessageItems: [MailMessageItem] = mailViewModel.mailItem?.messageItems.filter({ result.contains($0.message.from.address) }) ?? []
                    var justFisrtMessageItems: [MailMessageItem] = []
                    // 过滤出创建时间最晚的第一封重要推荐人邮件messageId
                    for importantMessageItem in importantMessageItems {
                        if let messageItem: MailMessageItem = justFisrtMessageItems.first(where: { $0.message.from.address == importantMessageItem.message.from.address }),
                           let indexNow = justFisrtMessageItems.firstIndex(where: { $0.message.from.address == importantMessageItem.message.from.address }) {
                            if messageItem.message.createdTimestamp < importantMessageItem.message.createdTimestamp {
                                justFisrtMessageItems.remove(at: indexNow)
                                justFisrtMessageItems.append(importantMessageItem)
                            }
                        } else {
                            justFisrtMessageItems.append(importantMessageItem)
                        }
                    }
                    let justFisrtImportantMessageIds = justFisrtMessageItems.map({$0.message.id})
                    self.updateImportantContact(importantMessageIds: justFisrtImportantMessageIds)
                    MailLogger.info("[mail_feed] getMailImportantContacts, result: \(result)")
                }
            } onError: { e in
                MailLogger.info("Failed to getMailImportantContacts, error: \(e)")
            }.disposed(by: self.disposeBag)
    }
    
    func updateImportantContact(importantMessageIds: [String]) {
        MailLogger.info("[Mail handleFeedDraftItem] window.updateImportantContact \(importantMessageIds)")
        guard let data = try? JSONSerialization.data(withJSONObject: importantMessageIds, options: []),
              let JSONString = NSString(data: data, encoding: String.Encoding.utf8.rawValue)?.replacingOccurrences(of: "'", with: "\\'") else { mailAssertionFailure("fail to serialize json"); return }
        self.callJSFunction("updateImportantContact", params: [JSONString], withThreadId: nil, completionHandler: nil)
    }

    private func parseMailBodyHtml(for viewModel: MailMessageListPageViewModel, onComplete: ((MailMessageListPageViewModel) -> Void)?) {
        guard let mailItem = viewModel.mailItem else { return }
        let startTime = Date().timeIntervalSince1970
        viewModel.newMessageTimeEvent?.stage = .generate_html
        delegate?.onParseHtmlStart(viewModel.threadId)
        let lazyLoadMessage = mailItem.shouldLazyLoadMessage
        if let renderModel = delegate?.getRenderModel(by: viewModel, mailItem: mailItem, lazyLoadMessage: lazyLoadMessage, isPushNewMessage: false) {
            templateRender.renderMessageListHtml(by: renderModel).subscribe(onNext: { [weak self] (result) in
                guard let self = self else { return }
                self.delegate?.onParseHtmlEnd(mailItem, parseResult: result, lazyLoadMessage: lazyLoadMessage)
                if let vm = self.getViewModelOf(threadId: viewModel.threadId) {
                    let time = Date().timeIntervalSince1970 - startTime
                    vm.messageEvent?.commonParams.appendOrUpdate(MailAPMEvent.MessageListLoaded.CommonParam.parseHTMLTime(time))
                    vm.newMessageTimeEvent?.commonParams.appendOrUpdate(MailAPMEvent.NewMessageListLoaded.CommonParam.generateHTMLCost(Int(time) * 1000))
                    onComplete?(vm)
                }
            }).disposed(by: self.disposeBag)
        }
    }
    
    func onMailItemUpdate(newMailItem: MailItem, oldMailItem: MailItem) {
        report.onMailItemUpdate(newMailItem: newMailItem, oldMailItem: oldMailItem)
    }

    func startLoadFeedBodyHtml(feedCardId: String, 
                               timestampOperator: Bool,
                               timestamp: Int64,
                               forceGetFromNet: Bool,
                               isDraft: Bool) {
        loadHTMLOperationQueue.addOperation { [weak self] in
            guard let self = self else { return }
            guard let viewModel = self.dataService.feedGetViewModelOf() else { return }

            if viewModel.loadErrorType != nil {
                return
            }
            if (Store.settingData.getCachedPrimaryAccount()?.isUnuse() ?? false) {
                viewModel.loadErrorType = .noPermission
                return
            }
            /// 成功回调，通知 VC 更新页面
            let completion: ((MailMessageListPageViewModel) -> Void) = { [weak self] vm in
                self?.delegate?.messageListViewModelDidUpdate(threadId: vm.threadId)
            }

            let onError = { [weak self] (error: Error)  in
                asyncRunInMainThread {
                    self?.delegate?.onLoadBodyHtmlError(viewModel: viewModel, error: error)
                }
            }

            let onMailItemSuccess: (MailItem) -> (Void) = { [weak self] mailItem in
                self?.feedUpdateVMAndParseHTML(mailItem: mailItem, completion: completion)
            }

            if viewModel.mailItem == nil || viewModel.bodyHtml == nil {
                loadNewleastMailItem(feedCardId: feedCardId,
                                     timestampOperator: timestampOperator,
                                     timestamp: timestamp,
                                     forceGetFromNet: forceGetFromNet,
                                     isDraft: isDraft)
            } else {
                completion(viewModel)
            }
            
            func loadNewleastMailItem(feedCardId: String, 
                                      timestampOperator: Bool,
                                      timestamp: Int64,
                                      forceGetFromNet: Bool,
                                      isDraft: Bool) {
                self.loadFeedMailItem(feedCardId: feedCardId,
                                      timestampOperator: timestampOperator,
                                      timestamp: timestamp,
                                      forceGetFromNet: forceGetFromNet,
                                      isDraft: isDraft) {[weak self] (mailItem, hasMore) in
                    // 追加loadMore数据
                    var newMailFeedMessageItems: [FromViewMailMessageItem] = []
                    newMailFeedMessageItems = mailItem.feedMessageItems.sorted { $0.item.message.createdTimestamp < $1.item.message.createdTimestamp }
                    
                    let newMailItem = MailItem(feedCardId: feedCardId,
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
                    
                    let error = emptyError.empty(isEmpty: true)
                    // 倒序 如果有
                    self?.delegate?.callJSFunction("loadMoreEnable", params: ["\(timestampOperator)", "\(hasMore)"],  withThreadId: nil, completionHandler: nil)
                    if timestampOperator == false {
                        self?.delegate?.callJSFunction("loadMoreEnable", params: ["\(true)", "\(false)"],  withThreadId: nil, completionHandler: nil)
                    }
                    if newMailItem.messageItems.count == 0 {
                        if timestamp == 0 && timestampOperator == false {
                            onError(error)
                        } else {
                            loadNewleastMailItem(feedCardId: feedCardId,
                                                 timestampOperator: false,
                                                 timestamp: 0,
                                                 forceGetFromNet: false,
                                                 isDraft: false)
                        }
                    } else {
                        viewModel.loadErrorType = nil
                        onMailItemSuccess(newMailItem)
                    }
                } errorCallback: { error in
                    onError(error)
                }
            }
        }
    }
    func startLoadBodyHtml(threadID: String) {
        loadHTMLOperationQueue.addOperation { [weak self] in
            guard let self = self else { return }
            guard !self.loadingThreads.contains(threadID) else {
                return
            }
            guard let viewModel = self.dataService.getViewModelOf(threadId: threadID) else { return }

            if viewModel.loadErrorType != nil {
                return
            }
            self.loadingThreads.insert(threadID)
            /// 成功回调，通知 VC 更新页面
            let completion: ((MailMessageListPageViewModel) -> Void) = { [weak self] vm in
                self?.loadingThreads.remove(threadID)
                self?.delegate?.messageListViewModelDidUpdate(threadId: vm.threadId)
            }

            let onError = { [weak self] (error: Error)  in
                self?.loadingThreads.remove(threadID)
                self?.delegate?.onLoadBodyHtmlError(viewModel: viewModel, error: error)
            }
            
            let onMailItemSuccess: (MailItem, Bool) -> (Void) = { [weak self] mailItem, isFromNet in
                self?.updateVMAndParseHTML(threadId: threadID, mailItem: mailItem, isFromNet: isFromNet, completion: completion)
            }
            var needReload = false
            if self.isBot,
               Store.settingData.getCachedCurrentSetting()?.smartInboxMode == true,
               viewModel.labelId == Mail_LabelId_Inbox {
                // Bot 读信，开了智能收件箱，但 labelId 是 INBOX
                // 这种情况下虽然能读到信，但 labelId 是错的，需要重新 getLabel
                needReload = true
            }
            if viewModel.mailItem == nil || needReload {
                self.loadMailItem(threadId: viewModel.threadId,
                                  labelId: viewModel.labelId,
                                  messageId: viewModel.messageId,
                                  forwardInfo: self.forwardInfo) { [weak self] (mailItem, isFromNet) in
                    guard let self = self else { return }
                    if self.isBot, let messageId = viewModel.messageId,
                       mailItem.messageItems.first(where: { $0.message.id == messageId }) == nil || needReload,
                       FeatureManager.open(.openBotDirectly, openInMailClient: false) {
                        // 获取的 messageItems 不包含当前messageID，bot读信下尝试刷新 labelID
                        self.getSuitableLabelAndReload(threadId: viewModel.threadId,
                                                       labelId: viewModel.labelId,
                                                       messageId: messageId,
                                                       forwardInfo: self.forwardInfo,
                                                       successCallback: onMailItemSuccess,
                                                       errorCallback: onError)
                    } else {
                        onMailItemSuccess(mailItem, isFromNet)
                    }
                } errorCallback: { [weak self] error in
                    guard let self = self else { return }
                    // 部分场景，如永久删除后，rust纪录ID，会返回error，bot错误时也尝试刷新 labelID
                    if self.isBot, let messageId = viewModel.messageId,
                       FeatureManager.open(.openBotDirectly, openInMailClient: false) {
                        // 获取的 messageItems 为空，bot读信下尝试刷新 labelID
                        self.getSuitableLabelAndReload(threadId: viewModel.threadId,
                                                       labelId: viewModel.labelId,
                                                       messageId: messageId,
                                                       forwardInfo: self.forwardInfo,
                                                       successCallback: onMailItemSuccess,
                                                       errorCallback: onError)
                    } else {
                        onError(error)
                    }
                }
            } else if viewModel.isFullReadMessage, let fullReadMessageId = viewModel.fullReadMessageId, viewModel.bodyHtml == nil {
                let isForward = self.forwardInfo != nil
                self.delegate?.onGetRustDataStart(viewModel.threadId)
                self.dataService.loadMessageItem(threadId: viewModel.threadId, messageId: fullReadMessageId, isForward: isForward)
                    .subscribe(onNext: { [weak self] (vm) in
                        guard let vm = vm else {
                            mailAssertionFailure("loadMessageItem vm not found")
                            return
                        }
                        self?.delegate?.onGetRustDataEnd(vm.threadId,
                                                         messageCount: vm.mailItem?.messageItems.count ?? 0,
                                                         hasBigMessage: vm.hasBigMessage,
                                                         isFromNet: true,
                                                         isRead: vm.mailItem?.isRead == true)
                        self?.parseMailBodyHtml(for: vm, onComplete: completion)
                    }, onError: onError)
                    .disposed(by: self.disposeBag)
            } else if viewModel.bodyHtml == nil {
                self.loadMailItem(threadId: viewModel.threadId,
                                  labelId: viewModel.labelId,
                                  messageId: viewModel.messageId,
                                  forwardInfo: self.forwardInfo,
                                  successCallback: onMailItemSuccess,
                                  errorCallback: onError)
            } else {
                completion(viewModel)
            }
        }
    }
}

extension MailMessageListControllerViewModel: MailMessageListControllerViewModeling {
    func callJSFunction(_ funName: String, params: [String], withThreadId threadID: String?, completionHandler: ((Any?, Error?) -> Void)?) {
        delegate?.callJSFunction(funName, params: params, isUserAction: nil, withThreadId: threadID, completionHandler: completionHandler)
    }

    func showSuccessToast(_ toast: String) {
        delegate?.showSuccessToast(toast)
    }
}
