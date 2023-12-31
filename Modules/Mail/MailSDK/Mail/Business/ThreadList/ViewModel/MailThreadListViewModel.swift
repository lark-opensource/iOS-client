//
//  MailThreadListViewModel.swift
//  MailSDK
//
//  Created by tefeng liu on 2022/2/20.
//

import RxSwift
import LarkUIKit
import LKCommonsLogging
import Homeric
import YYCache
import RustPB
import RxRelay
import LarkSwipeCellKit

enum MailThreadChanegDetail {
    case add     // 直接新增预加载任务
    case update  // 重置对应预加载任务
    case delete  // 删除对应已预加载缓存数据
    case refresh // 对于切换Label，账号，或者thread列表数据重置的case，包括refreshThreadLabel/invalidCache
}

class MailThreadListViewModel {
    enum DataState {
        case refreshed(data: [MailThreadListCellViewModel], resetLoadMore: Bool) // 后续值为是否loadmore
        case loadMore(data: [MailThreadListCellViewModel])
        case pageEmpty
        case failed(labelID: String, err: Error)
    }

    // MARK: common utils
    private static let logger = Logger.log(MailHomeViewModel.self, category: "Module.MailHomeViewModel")
    static let pageLength: Int64 = 20

    // MARK: property
    var fetcher: DataService? {
        return MailDataServiceFactory.commonDataService
    }

    /// 用于对加载后的数据进行初步的清洗附加请求
    lazy var dataFilters: [MailThreadListDataFilter] = {
        return [] // 曾经这里有表情需求，功能下了，但是机制保留。
    }()

    @MailAutoCleanData var mailThreads = ThreadSafeArray<MailThreadListCellViewModel>(array: [])

    // 用于加载更多的标记位
    @MailAutoCleanData var isLoading: Bool = false
    // 用于加载更多的标记位
    @MailAutoCleanData var isLastPage: Bool = false
    // 标记上一页请求数据的来源 值是fromDB
    @MailAutoCleanData var lastSource: Bool = false

    @MailAutoCleanData var autoLoadMore: Bool = true

    let userID: String
    let labelID: String

    var filterType: MailThreadFilterType = .allMail

    var labelName: String = BundleI18n.MailSDK.Mail_Folder_Inbox

    // MARK: temp
    private var getThreadDisposeBag: DisposeBag = DisposeBag()

    let disposeBag = DisposeBag()
    static let THREAD_ID_KEY = "thread_id"
    static let MODELS_KEY = "models"

    // leftOrientation、rightOrientation 用于缓存
    var leftOrientation: SwipeOptions?
    var rightOrientation: SwipeOptions?

    let mailFilter: MailPushFilter<PushDispatcher.MailChangePush>
    var filterDisposeBag = DisposeBag()

    // MARK: Observable
    @DataManagerValue<DataState> var dataState

    @DataManagerValue<(threadId: String, labelIds: [String])> var mailThreadChange

    @DataManagerValue<()> var refreshStranger

    // TODO: REFACTOR 实在弄不掉，先留着
    @DataManagerValue<(label2threads: Dictionary<String, (threadIds: [String], needReload: Bool)>, hasFilterThreads: Bool)> var multiThreadChange

    @DataManagerValue<(labelId: String, threadChangeDetail: [String : MailThreadChanegDetail])> var unreadPreloadChange

    // MARK: LifeCircle
    init(labelID: String, userID: String) {
        self.labelID = labelID
		self.userID = userID
        self.mailFilter = MailPushFilter<PushDispatcher.MailChangePush>()
//        self.mailFilter.setup(mapFunc: filterMapFunc)

        bindPush()
        bindEventBus()
    }

    func filterMapFunc(push: PushDispatcher.MailChangePush) -> (Bool, String) {
        var type = "refresh"
        switch push {
        case .threadChange(let change):
            type = "threadChange"
            return (true, type)
        case .multiThreadsChange(let change):
            type = "multiThreadsChange"
            MailLogger.info("[mail_swipe_actions] multiThreadsChange")
            if change.hasFilterThreads && change.label2Threads.isEmpty {
                return (true, type)
            }
            for (labelId, value) in change.label2Threads where labelId == labelID {
                MailThreadListViewModel.logger.debug("MailChangePush -> multiThreadsChange label: \(labelId) threadId: \(value)")
                /// refresh current label threads list
                let threadsList = mailThreads.all
                let affectedThreads = value
                if affectedThreads.needReload {
                    return (true, type)
                } else {
                    var filterFunc: (Bool, String)?
                    var someThreadCannotHandle = change.hasFilterThreads
                    if someThreadCannotHandle {
                        isLastPage = false
                    }
                    let lastMessageTimeStamp = threadsList.last?.lastmessageTime ?? 0
                    mailMultiThreadItemsProvider(labelId: labelId, threadIds: affectedThreads.threadIds, sortTimeCursor: lastMessageTimeStamp)
                    .subscribe(onNext: { [weak self] (response, cells) in
                        guard let `self` = self else { return }
                        let threadItems = response.threadItems
                        let disappearedThreadIds = response.disappearedThreadIds
                        var shouldLoadMore: Bool = false
                        var result: Bool = false
                        /// update or add threads
                        threadItems.forEach { (item) in
                            if let lastTimestamp = self.mailThreads.all.last?.lastmessageTime,
                               item.thread.lastUpdatedTimestamp <= lastTimestamp {
                                shouldLoadMore = true
                            }
                            if shouldLoadMore {
                                result = shouldLoadMore
                            } else {
                                result = someThreadCannotHandle
                            }
                            if !disappearedThreadIds.isEmpty {
                                filterFunc = (true, type)
                            }
                            /// 如果thread存在，则增加或更新
                            if item.hasThread {
                                /// 更新对应label下的threadList
                                if let cell = cells.first(where: { $0.threadID == item.thread.id }) {
                                    let threadsList = self.mailThreads.all
                                    if let threadIndex = threadsList.firstIndex(where: { $0.threadID == cell.threadID }) {
                                        let oldThreadModel = threadsList[threadIndex]
                                        let newThreadModel = cell
                                        //MailLogger.info("[mail_swipe_actions] filterMapFunc threadsList[threadIndex]: isUnread - \(threadsList[threadIndex].isUnread) isFlagged - \(threadsList[threadIndex].isFlagged) \(threadsList[threadIndex].labelIDs) newThreadModel: isUnread - \(newThreadModel.isUnread) isFlagged - \(newThreadModel.isFlagged) \(newThreadModel.labelIDs)")
                                        if oldThreadModel.lastmessageTime == newThreadModel.lastmessageTime && threadsList[threadIndex] == newThreadModel {
                                            filterFunc = (false, type)
                                        } else {
                                            filterFunc = (true, type)
                                        }
                                    } else {
                                        filterFunc = (true, type)
                                    }
                                } else {
                                    // 按理说不可能发生
                                    mailAssertionFailure("no cell in results. @liutefeng")
                                }
                            } else {
                                filterFunc = (true, type)
                            }
                        }
                        MailLogger.info("[mail_swipe_actions] filterMapFunc filterFuncMap: \(filterFunc) ")
                        if let filterFuncMap = filterFunc, filterFuncMap.0 {
                            MailLogger.info("[mail_swipe_actions] filterMapFunc filterFuncMap.0: \(filterFuncMap.0) record count: \(self.mailFilter.getRecord().count)")
                            if self.mailFilter.getRecord().isEmpty {
                                self.mailFilter.updateRecord(filterFuncMap.1)
                            }
                        }
                    }, onError: { (error) in
                        MailThreadListViewModel.logger.error("getMailMultiThreadItems failed", error: error)
                    }).disposed(by: disposeBag)

                    return (false, type)
                }
            }
            return (false, type)
        case .labelPropertyChange(_):
            type = "labelPropertyChange"
            return (true, type)
        case .refreshThreadChange(_):
            type = "refreshThreadChange"
            return (true, type)
        case .mailMigrationChange(_):
            type = "mailMigrationChange"
            return (true, type)
        default:
            break
        }
        return (false, "")
    }

    /// 开始拦截
    func addChangeFilter() {
        mailFilter.startRecord()
        /// 触发此函数后，30s内销毁标记，防止不销毁
        Observable.just(())
        .delay(.seconds(timeIntvl.largeSecond), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                MailLogger.info("[MailPushFilter] [mail_swipe_actions] over 30s, remove filter, restart changelog sync")
                self?.refreshMailThreadListIfNeeded()
            }).disposed(by: filterDisposeBag)
    }

    /// 结束拦截
    func refreshMailThreadListIfNeeded() {
        filterDisposeBag = DisposeBag()
        /// 判断标记位，触发此函数后，10s内销毁标记
        if !mailFilter.getRecord().isEmpty {
            // 根据type相应事件. 目前type会是 refresh
            MailLogger.info("[mail_swipe_actions] refreshMailThreadList after swipe IfNeeded mailFilter: \(mailFilter.getRecord().map({ $0 }))")
            mailFilter.clearRecordAndStop()
            refreshMailThreadList()
        } else {
            mailFilter.clearRecordAndStop()
        }
    }
    
    func isFilteringChange() -> Bool {
        return mailFilter.enableBlock
    }

    private func bindPush() {
        PushDispatcher
            .shared
            .mailChange
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (push) in
                guard let self = self else { return }
                if self.mailFilter.enableBlock {
                    let filterFuncMap = self.filterMapFunc(push: push)
                    if filterFuncMap.0 && self.mailFilter.getRecord().isEmpty {
                        self.mailFilter.updateRecord(filterFuncMap.1)
                    }
                } else {
                    switch push {
                    case .threadChange(let change):
                        self.threadChange(change)
                    case .multiThreadsChange(let change):
                        self.multiThreadsChange(change)
                    case .labelPropertyChange(let change):
                        self.labelPropertyChange(change)
                    case .refreshThreadChange(let change):
                        self.refreshThreadsInLabel(change)
                    case .mailMigrationChange(let change):
                        self.mailMigrationChange(change)
                    default:
                        break
                    }
                }
        }).disposed(by: disposeBag)
    }

    private func bindEventBus() {
        let labelId = labelID
        // 用于广播首页列表刷新了
        dataState.subscribe(onNext: { state in
            if case let .refreshed(data: datas, resetLoadMore: loadMore) = state {
                EventBus.$threadListEvent.accept(.didReloadListData(labelId: labelId, datas: datas))
            }
        }).disposed(by: disposeBag)

        EventBus.threadListEvent
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (event) in
                if self?.mailFilter.enableBlock ?? false {
                    return
                }
                switch event {
                case .needUpdateThreadList(label: let labelId, removeThreadId: let thread):
                    self?.handleUpdateThreadList(labelId: labelId, remveThreadId: thread)
                default:
                    break
                }
        }).disposed(by: disposeBag)
    }
}

// MARK: interface
extension MailThreadListViewModel {
    func cleanUnreadFilterIfNeeded() {
        guard filterType == .unread else {
            return
        }
        MailLogger.info("cleanUnreadFilterIfNeeded called")
        self.mailThreads.removeAll()
        self.$dataState.accept(.refreshed(data: [], resetLoadMore: false))
    }

    func cleanMailThreadCache() {
        MailLogger.info("cleanMailThreadCache called")
        self.mailThreads.removeAll()
        self.$dataState.accept(.pageEmpty)
    }

    func getMailListFromLocal(filterType: MailThreadFilterType? = nil, length: Int64 = MailThreadListViewModel.pageLength, fromMessageList: Bool = false) {
        if let newFilterType = filterType {
            self.filterType = newFilterType
        }

        // 从Rust层拉取数据 From DB/Serve
        let lastMessageTime = self.mailThreads.all.last?.lastmessageTime ?? 0
        let timeStamp = lastMessageTime > 0 ? lastMessageTime : 0
        MailLogger.info("[mail_init] [mail_preload] call getMailListFromLocal labelId: \(labelID) timeStamp: \(timeStamp)")
        let label = labelID
        isLoading = true
        // 现在有额外的数据加载拼装逻辑
        var dataProvider = mailListFromLocalProvider(labelID: label,
                                                     filterType: self.filterType,
                                                     timeStamp: timeStamp)
        dataProvider
        .subscribe(onNext: { [weak self] (result, newThreadItems) in
            guard let `self` = self else { return }
            self.isLoading = false
            let isLastPage = result.isLastPage
            var newThreadsList: [MailThreadListCellViewModel] = []
            MailThreadListViewModel.logger.info("[mail_home_init] getMailListFromLocal resp items count: \(newThreadItems.count) isLastPage: \(isLastPage)")
            self.lastSource = result.isFromDb
            ///  if should clear thread list, replace with new thread list
            if self.shouldClearMailThread() {
                newThreadsList = newThreadItems
                MailThreadListViewModel.logger.info("[mail_home_init] getMailListFromLocal has renew label: \(label) timeStamp: \(timeStamp) items count: \(newThreadItems.count) isLastPage: \(isLastPage)")
            } else {
                let theadsList = self.mailThreads.all
                /// append new items and duplicate removal
                let filterNewThreadItems = newThreadItems.filter { self.shouldAppendModel(array: theadsList, model: $0) }
                if filterNewThreadItems.count > 0 {
                    newThreadsList = theadsList + filterNewThreadItems
                    MailThreadListViewModel.logger.info("[mail_home_init] getMailListFromLocal has append label: \(label) timeStamp: \(timeStamp) items count: \(newThreadItems.count) isLastPage: \(isLastPage)")
                } else {
                    /// if no need append, cancle update
                    self.isLastPage = isLastPage
                    MailThreadListViewModel.logger.info("[mail_home_init] getMailListFromLocal has append empty label: \(label) timeStamp: \(timeStamp) isLastPage: \(isLastPage)")
                    self.$dataState.accept(.loadMore(data: []))
                    return // ⚠️ 注意！！这里有个该死的return
                }
            }
            /// update new threads list
            self.setThreadsListOfLabel(label, mailList: newThreadsList)
            MailThreadListViewModel.logger.info("[mail_home_init] getMailListFromLocal success label: \(label) timeStamp: \(timeStamp) items count: \(newThreadsList.count) isLastPage: \(isLastPage)")
            self.isLastPage = isLastPage

            /// in case of error infinite loop
            if newThreadsList.isEmpty {
                self.isLastPage = true
                MailThreadListViewModel.logger.info("[mail_home_init] getMailListFromLocal Label: \(label) Empty timeStamp: \(timeStamp)")
                self.$dataState.accept(.refreshed(data: [], resetLoadMore: false)) // 触发下，告诉上层页面空了。
                return // ⚠️ 注意！！这里又有个狡猾的return！！
            }

            // 原本在Complete内，决定调整到这里
            self.$dataState.accept(.refreshed(data: newThreadsList, resetLoadMore: false))
            if fromMessageList {
                EventBus.$threadListEvent.accept(.didReloadListDataOnlyFromMessageList(labelId: label, datas: newThreadsList))
            }
        }, onError: { [weak self] (error) in
            guard let self = self else { return }
            self.isLoading = false
            // 弱网或者服务端出错，返回错误的时候，拉不到数据，需要展示错误页并给予重试按钮
            let threadList = self.mailThreads.all
            if error.mailErrorCode == MailErrorCode.getMailListEmpty {
                if threadList.isEmpty {
                    self.setThreadsListOfLabel(self.labelID, mailList: [])
                }
            } else if threadList.isEmpty {
                self.$dataState.accept(.failed(labelID: self.labelID, err: error))
            }
            self.$dataState.accept(.loadMore(data: []))
            MailThreadListViewModel.logger.error("[mail_home_init] getMailListFromLocal failed label: \(label) timeStamp: \(timeStamp) ", error: error)
        }).disposed(by: getThreadDisposeBag)
    }

    func cancelGetThreadList() {
        MailLogger.info("[mail_home_init] [mail_init] cancelGetThreadList getMailListFromLocal")
        getThreadDisposeBag = DisposeBag()
    }
}

// MARK: internal interface
extension MailThreadListViewModel {
    private func getMailThreadItemThenUpdateList(labelId: String, threadId: String) {
        mailItemProvider(labelID: labelId, threadID: threadId)
        .subscribe(onNext: { [weak self] (threadItem, cell) in
            guard let `self` = self else { return }
            /// 如果thread存在，则增加或更新
            if threadItem.hasThread && threadItem.thread.id == threadId {
                /// 更新对应label下的threadList
                self.updateThread(cell)
            } else {
                /// 如果thread不存在，删除此thread
                self.deleteThreads(threadIds: [threadId])
            }
        }, onError: { (error) in
            MailThreadListViewModel.logger.error("getMailThread failed", error: error)
        }).disposed(by: disposeBag)
    }

    private func deleteThreads(threadIds: [String], someThreadCannotHandle: Bool = false) {
        if threadIds.isEmpty && !someThreadCannotHandle {
            return
        }
        var refreshNow = true // 因为只处理自己的 所以肯定是true
        var threadsList = mailThreads.all
        threadsList.removeAll {
            if threadIds.contains($0.threadID) {
                return true
            }
            return false
        }
        setThreadsListOfLabel(labelID, mailList: threadsList)
        MailThreadListViewModel.logger.debug("MailChangePush -> deleteThread labelId: \(labelID) threadIds: \(threadIds)")
        MailTracker.log(event: Homeric.EMAIL_CHANGE_LOG, params: ["change": "deleteThread"])
        if refreshNow || someThreadCannotHandle {
            self.$dataState.accept(.refreshed(data: threadsList, resetLoadMore: someThreadCannotHandle))
            self.$unreadPreloadChange.accept(( labelID, Dictionary(uniqueKeysWithValues: threadIds.map({ ($0, .delete) })) ))
        }
    }

    private func updateThread(_ threadItem: MailThreadListCellViewModel, someThreadCannotHandle: Bool = false) {
        var threadsList = mailThreads.all
        var needReloadList = false
        var updateThreadDetail = [String: MailThreadChanegDetail]()
        if let threadIndex = threadsList.firstIndex(where: { $0.threadID == threadItem.threadID }) {
            let oldThreadModel = threadsList[threadIndex]
            var newThreadModel = threadItem
            /// 如果比列表最后一条的时间更早，则放弃更新
            /// if can found this thread in the threadList , should update this thread
            /// if let lastThreadModel = threadsList.last,
            ///    lastThreadModel.lastmessageTime > newThreadModel.lastmessageTime {
            ///    return
            /// }
            /// 如果此thread的更新时间发生了变化，需要删除原有位置的数据，并将新的thread插入到合适的位置
            if oldThreadModel.lastmessageTime != newThreadModel.lastmessageTime {
                needReloadList = true
                threadsList.remove(at: threadIndex)
                /// 插入到列表中合适的位置
                if let index = threadsList.firstIndex(where: { newThreadModel.lastmessageTime > $0.lastmessageTime }) { // 等于的话不知道会不会影响之前的逻辑
                    threadsList.insert(newThreadModel, at: index)
                } else {
                    /// 添加到末尾
                    threadsList.append(newThreadModel)
                }
                if threadsList.isEmpty {
                    threadsList.insert(newThreadModel, at: 0)
                }
                updateThreadDetail.updateValue(.update, forKey: newThreadModel.threadID)
            } else {
                /// 与左右滑体验优化冲突，暂时屏蔽此检测和乐观处理
                /// 如果没有发生时间上的变化，不需要重新排序位置，只替换掉原有的数据即可
//                if MailAPMErrorDetector.shared.threadIDs.all.contains(newThreadModel.threadID) {
//                    if newThreadModel.isUnread {
//                        /// 收到标记未读的changelog
//                        MailAPMErrorDetector.shared.abandonDetect(newThreadModel.threadID)
//                    } else if MailAPMErrorDetector.shared.endDetect(newThreadModel.threadID), newThreadModel.isUnread {
//                        /// 强制UI还原
//                        newThreadModel.isUnread = false
//                    }
//                }
                // 增加对比，发现没有变更则无需更新reloadData
                if threadsList[threadIndex] == newThreadModel {
                    // 无须更新
                    needReloadList = false
                } else {
                    threadsList[threadIndex] = newThreadModel
                    needReloadList = true
                    updateThreadDetail.updateValue(newThreadModel.isUnread ? .update : .delete, forKey: newThreadModel.threadID)
                }
            }
            setThreadsListOfLabel(labelID, mailList: threadsList)
        } else {
            /// 如果thread list中找不到，则尝试添加到合适的位置
            addThread(threadItem, isFromUpdate: true)
        }
        MailThreadListViewModel.logger.debug("MailChangePush -> updateThread labelId: \(labelID) threadId: \(threadItem.threadID)")
        MailTracker.log(event: Homeric.EMAIL_CHANGE_LOG, params: ["change": "updateThread"])
        if needReloadList {
            self.$dataState.accept(.refreshed(data: mailThreads.all, resetLoadMore: someThreadCannotHandle))
            if !updateThreadDetail.keys.isEmpty {
                self.$unreadPreloadChange.accept((labelID, updateThreadDetail))
            }
        }
    }

    private func addThread(_ threadItem: MailThreadListCellViewModel, isFromUpdate: Bool = false) {
        if filterType == .unread && !threadItem.isUnread {
            return // 未读filter对已读新增加的邮件做拦截
        }
        let labelId = labelID
        var threadsList = mailThreads.all
        // 如果有旧的，先移除
        threadsList.removeAll { $0.threadID == threadItem.threadID }
        // 创建一个ViewModel
        let newModel = threadItem
        if threadsList.last?.lastmessageTime ?? 0 == newModel.lastmessageTime
            && threadsList.last?.threadID != threadItem.threadID {
            threadsList.append(newModel)
            setThreadsListOfLabel(labelId, mailList: threadsList)
            if !isFromUpdate {
                MailThreadListViewModel.logger.debug("MailChangePush -> addThread labelId: \(labelId) threadId: \(threadItem.threadID)")
                MailTracker.log(event: Homeric.EMAIL_CHANGE_LOG, params: ["change": "addThread"])
            }
            // 通知当前页面刷新
            self.$dataState.accept(.refreshed(data: threadsList, resetLoadMore: false))

            if newModel.isUnread {
                self.$unreadPreloadChange.accept((labelID, [newModel.threadID: .add]))
            }
        }
        // 如果比列表最后一条的时间更早，则放弃更新
        if threadsList.last?.lastmessageTime ?? 0 >= newModel.lastmessageTime {
            return
        }
        // 通过时间戳，插入到列表中合适的位置
        if let index = threadsList.firstIndex(where: { newModel.lastmessageTime > $0.lastmessageTime }) {
            threadsList.insert(newModel, at: index)
            setThreadsListOfLabel(labelId, mailList: threadsList)
            if !isFromUpdate {
                MailThreadListViewModel.logger.debug("MailChangePush -> addThread labelId: \(labelId) threadId: \(threadItem.threadID)")
                MailTracker.log(event: Homeric.EMAIL_CHANGE_LOG, params: ["change": "addThread"])
            }
            // 通知当前页面刷新
            self.$dataState.accept(.refreshed(data: threadsList, resetLoadMore: false))
            if newModel.isUnread {
                self.$unreadPreloadChange.accept((labelID, [newModel.threadID: .add]))
            }
        }
        // 如果当前列表是空的，则直接读db
        if threadsList.isEmpty {
            getMailListFromLocal(filterType: filterType)
        }
    }

    /// 刷新当前列表
    /// - Parameters:
    ///   - filterType: 对应的filterType，默认当前
    ///   - length: 默认20
    ///   - cleanCache: 是否清理掉缓存，主要cover fail的情况
    func updateMailListFromLocal(filterType: MailThreadFilterType? = nil, length: Int64 = MailThreadListViewModel.pageLength, cleanCache: Bool = false) {
        let labelId = labelID
        let type = filterType ?? self.filterType
        MailLogger.info("[mail_init] [mail_preload] call updateMailListFromLocal labelId: \(labelId)")
        self.isLoading = true
        mailListFromLocalProvider(labelID: labelId, filterType: type, timeStamp: 0, length: length)
            .subscribe(onNext: { [weak self] (resp, threadItems) in
            guard let `self` = self else { return }
            self.isLoading = false
            if cleanCache {
                self.mailThreads.removeAll()
            }
            var threadsList: [MailThreadListCellViewModel] = self.mailThreads.all
            // TODO: REFACTOR 这里的逻辑有数据不一致的风险，确认下是否能直接去掉。
            let threadIDs = threadsList.map({ $0.threadID })
            for (index, threadItem) in threadItems.enumerated() {
                let model = threadItem
                let threadID = threadItem.threadID
                if threadIDs.firstIndex(of: threadID) != nil {
                    threadsList[index] = model
                } else {
                    threadsList.insert(model, at: index)
                }
            }
            self.isLastPage = resp.isLastPage
            self.setThreadsListOfLabel(labelId, mailList: threadsList)

            self.$dataState.accept(.refreshed(data: threadsList, resetLoadMore: false))
        }, onError: { [weak self] (error) in
            guard let self = self else {
                return
            }
            self.isLoading = false
            MailThreadListViewModel.logger.error("updateMailListFromLocal failed", error: error)// 跑这了
            if cleanCache {
                self.mailThreads.removeAll()
            }
            let threadList = self.mailThreads.all
            if error.mailErrorCode == MailErrorCode.getMailListEmpty {
                if threadList.isEmpty {
                    self.setThreadsListOfLabel(labelId, mailList: [])
                }
            } else if threadList.isEmpty {
                self.$dataState.accept(.failed(labelID: labelId, err: error))
            }
        }).disposed(by: self.disposeBag)
    }

    private func getMailMultiThreadItemsThenUpdateList(threadIds: [String], sortTimeCursor: Int64 = 0, someThreadCannotHandle: Bool = false) {
        let labelId = labelID
        MailThreadListViewModel.logger.info("getMailMultiThreadItemsThenUpdateList: \(someThreadCannotHandle)")
        mailMultiThreadItemsProvider(labelId: labelId, threadIds: threadIds, sortTimeCursor: sortTimeCursor)
        .subscribe(onNext: { [weak self] (response, cells) in
            guard let `self` = self else { return }
            let threadItems = response.threadItems
            let disappearedThreadIds = response.disappearedThreadIds
            var shouldLoadMore: Bool = false
            var result: Bool = false
            /// update or add threads
            threadItems.forEach { (item) in
                if let lastTimestamp = self.mailThreads.all.last?.lastmessageTime,
                   item.thread.lastUpdatedTimestamp <= lastTimestamp {
                    shouldLoadMore = true
                }
                if shouldLoadMore {
                    result = shouldLoadMore
                } else {
                    result = someThreadCannotHandle
                }
                MailThreadListViewModel.logger.debug("getMailMultiThreadItemsThenUpdateList  result: \(result)")
                if result {
                    self.isLastPage = false
                }
                /// 如果thread存在，则增加或更新
                if item.hasThread {
                    /// 更新对应label下的threadList
                    if let cell = cells.first(where: { $0.threadID == item.thread.id }) {
                        self.updateThread(cell, someThreadCannotHandle: result)
                    } else {
                        // 按理说不可能发生
                        mailAssertionFailure("no cell in results. @liutefeng")
                    }
                } else {
                    /// 如果thread不存在，删除此thread
                    self.deleteThreads(threadIds: [item.thread.id], someThreadCannotHandle: result)
                    /// MailListDataSource.logger.error("getMailMultiThreadItems delete \(item.thread.id)")
                }
            }
            /// delete threads
            self.deleteThreads(threadIds: disappearedThreadIds, someThreadCannotHandle: result)
        }, onError: { (error) in
            MailThreadListViewModel.logger.error("getMailMultiThreadItems failed", error: error)
        }).disposed(by: disposeBag)
    }

    func setThreadsListOfLabel(_ labelId: String, mailList: [MailThreadListCellViewModel]) {
        guard labelId == labelID else {
            return
        }
        if mailList.isEmpty {
            MailLogger.info("[MailHome] setThreadsListOfLabel empty of labelId: \(labelId)")
        }
        mailThreads.replaceAll(mailList)
    }

    func refreshMailThreadList(forceRefresh: Bool = false) {
        var threadsCount: Int64 = 0
        let threads = mailThreads.all
        if threads.count > 0 {
            threadsCount = Int64(max(Int(MailThreadListViewModel.pageLength), threads.count))
        } else {
            threadsCount = MailThreadListViewModel.pageLength
        }
        if forceRefresh {
            threadsCount = MailThreadListViewModel.pageLength
        }
        updateMailListFromLocal(length: threadsCount, cleanCache: true)
    }

    func shouldClearMailThread() -> Bool {
        return mailThreads.all.isEmpty
    }

    // 对齐安卓的去重逻辑： 取出新数据的时候，拿出第一条数据，然后从后往前跟之前的数据比较，删除时间戳相同的数据
    private func shouldAppendModel(array: [MailThreadListCellViewModel]?, model: MailThreadListCellViewModel) -> Bool {
        guard let array = array else {
            MailThreadListViewModel.logger.info("self.mailThreads type:\(labelID) is nil")
            return false
        }
        for modelInArray in array.reversed()
            where modelInArray.lastmessageTime == model.lastmessageTime {
                return false
        }
        return true
    }
}

// MARK: Changelog dispatch
extension MailThreadListViewModel {
    private func threadChange(_ change: MailThreadChange) {
        /// 只更新缓存中的 threadsList
        for labelId in change.labelIds where labelID == labelId {
            let threadId = change.threadId
            MailThreadListViewModel.logger.debug("MailChangePush -> threadChange labelId: \(labelId) threadId: \(threadId)")
            MailTracker.log(event: Homeric.EMAIL_CHANGE_LOG, params: ["change": "threadChange"])
            /// 拿到 thread 实体，再更新 ViewModel
            getMailThreadItemThenUpdateList(labelId: labelId, threadId: threadId)
        }

        $mailThreadChange.accept((change.threadId, change.labelIds))
    }

    private func multiThreadsChange(_ change: MailMultiThreadsChange) {
        // 这段看不懂是啥玩意，先保留。
        if change.hasFilterThreads && change.label2Threads.isEmpty {
            isLastPage = false
            self.$dataState.accept(.refreshed(data: mailThreads.all, resetLoadMore: true))
            return
        }
        MailTracker.log(event: Homeric.EMAIL_CHANGE_LOG, params: ["change": "multiThreadsChange"])
        // 只处理自己labelId下的
        for (labelId, value) in change.label2Threads where labelId == labelID {
            MailThreadListViewModel.logger.debug("MailChangePush -> multiThreadsChange label: \(labelId) threadId: \(value)")
            /// refresh current label threads list
            let threadsList = mailThreads.all
            let affectedThreads = value
            /// if need reload refresh all threads
            if affectedThreads.needReload {
                let listLength = max(Int(MailThreadListViewModel.pageLength), threadsList.count)
                updateMailListFromLocal(filterType: filterType, length: Int64(listLength))
                MailThreadListViewModel.logger.debug("MailChangePush -> multiThreadsChange labelId: \(labelId) reload all")
            } else {
                var someThreadCannotHandle = change.hasFilterThreads
                if someThreadCannotHandle {
                    isLastPage = false
                }

                let lastMessageTimeStamp = threadsList.last?.lastmessageTime ?? 0
                /// reload changed multi threads
                getMailMultiThreadItemsThenUpdateList(threadIds: affectedThreads.threadIds,
                                                      sortTimeCursor: lastMessageTimeStamp,
                                                      someThreadCannotHandle: someThreadCannotHandle)
                MailThreadListViewModel.logger.debug("MailChangePush -> multiThreadsChange labelId: \(labelId) threadIds: \(affectedThreads.threadIds)")
            }
        }

        $multiThreadChange.accept((change.label2Threads, change.hasFilterThreads))
    }

    private func labelPropertyChange(_ change: MailLabelPropertyChange) {
        MailThreadListViewModel.logger.debug("MailChangePush -> labelPropertyChange -> label: \(change.label.id) listVM label: \(labelID)")
        /// label 的颜色或名称发生变化后，刷新当前所在的 thread list 及 message list 以响应最新的变化
        let threads = mailThreads.all
        guard threads.count > 0 else { return }
        updateMailListFromLocal(length: Int64(threads.count))
    }

    private func refreshThreadsInLabel(_ change: MailRefreshLabelThreadsChange) {
        MailLogger.info("refreshThreadsInLabel listVM: \(labelID) change.labelIDs: \(change.labelIDs)") // 可能推[STR] [INBOX,STR]
        if labelID != Mail_LabelId_Stranger && change.labelIDs.contains(Mail_LabelId_Stranger) {
            $refreshStranger.accept(())
        }
        if labelID != Mail_LabelId_Stranger {
            refreshMailThreadList()
        }
    }

    private func mailMigrationChange(_ change: MailMigrationChange) {
        self.updateMailListFromLocal()
    }

    private func handleUpdateThreadList(labelId: String, remveThreadId: String?) {
        guard labelId == labelID else { return }
        var threadsList = mailThreads.all
        threadsList.removeAll { $0.threadID == remveThreadId }
        mailThreads.replaceAll(threadsList)

        updateMailListFromLocal()
    }
}

// MARK: data request provider
extension MailThreadListViewModel {
    typealias ListDataResult = (MailGetThreadListResponse, [MailThreadListCellViewModel])

    func mailListFromLocalProvider(labelID: String,
                                   filterType: MailThreadFilterType,
                                   timeStamp: Int64 = 0,
                                   length: Int64 = MailThreadListViewModel.pageLength) -> Observable<ListDataResult> {
        guard let fetcher = fetcher else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        let label = labelID
        // 现在有额外的数据加载拼装逻辑
        var dataProvider: Observable<ListDataResult> = fetcher
            .getThreadListFromLocal(timeStamp: timeStamp,
                                    labelId: label,
                                    filterType: filterType,
                                    length: length).map({ [weak self] resp -> ListDataResult in
                let cells = resp.threadItems.map { MailThreadListCellViewModel(with: $0, labelId: label, userID: self?.userID ?? "") }
                return (resp, cells)
            })

        for filter in dataFilters {
            dataProvider = dataProvider.flatMap({ (resp, cells) -> Observable<ListDataResult> in
                return filter
                    .filterCellViewModelsIfNeeded(cellVMS: cells, labelId: label)
                    .map { cellResult -> ListDataResult in
                    return (resp, cellResult)
                }
            })
        }

        return dataProvider
    }

    typealias MailItemDataResult = (MailThreadItem, MailThreadListCellViewModel)
    func mailItemProvider(labelID: String, threadID: String) -> Observable<MailItemDataResult> {
        guard let fetcher = fetcher else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        let label = labelID
        // 现在有额外的数据加载拼装逻辑
        var dataProvider: Observable<MailItemDataResult> = fetcher
            .getMailThreadItemRequest(labelId: labelID, threadId: threadID)
            .map({ [weak self] threadItem -> MailItemDataResult in
                let cell = MailThreadListCellViewModel(with: threadItem, labelId: label, userID: self?.userID ?? "")
                return (threadItem, cell)
            })

        for filter in dataFilters {
            dataProvider = dataProvider.flatMap({ [weak self] (resp, cell) -> Observable<MailItemDataResult> in
                return filter
                    .filterCellViewModelsIfNeeded(cellVMS: [cell], labelId: label)
                    .map { cellResult -> MailItemDataResult in
                        // 理论不可能nil，不想用!所以??兜底代码
                        return (resp,
                                cellResult.first ?? MailThreadListCellViewModel(with: resp, labelId: label, userID: self?.userID ?? ""))
                }
            })
        }

        return dataProvider
    }

    typealias MutilItemDataResult = (resp: (threadItems: [MailThreadItem], disappearedThreadIds: [String]),
                                     cells: [MailThreadListCellViewModel])

    func mailMultiThreadItemsProvider(labelId: String,
                                      threadIds: [String],
                                      sortTimeCursor: Int64 = 0,
                                      someThreadCannotHandle: Bool = false) -> Observable<MutilItemDataResult> {
        guard let fetcher = fetcher else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        var dataProvider: Observable<MutilItemDataResult> = fetcher
            .getMailMultiThreadItemsRequest(fromLabel: labelID,
                                            threadIds: threadIds,
                                            sortTimeCursor: sortTimeCursor).map({ [weak self] resp -> MutilItemDataResult in
                let cells = resp.threadItems.map { MailThreadListCellViewModel(with: $0, labelId: labelId, userID: self?.userID ?? "") }
                return (resp, cells)
            })

        for filter in dataFilters {
            dataProvider = dataProvider.flatMap({ (resp, cells) -> Observable<MutilItemDataResult> in
                return filter
                    .filterCellViewModelsIfNeeded(cellVMS: cells, labelId: labelId)
                    .map { cellResult -> MutilItemDataResult in
                    return (resp, cellResult)
                }
            })
        }
        return dataProvider
    }

    typealias TopRefreshDataResult = (resp: Email_Client_V1_MailRefreshThreadListResponse,
                                      cells: [MailThreadListCellViewModel])
    func topLoadMoreRefreshProvider() -> Observable<TopRefreshDataResult> {
        guard let fetcher = fetcher else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        let label = labelID
        var dataProvider: Observable<TopRefreshDataResult> = fetcher
            .refreshThreadList(label_id: labelID,
                               filterType: filterType,
                               first_timestamp: mailThreads.first?.lastmessageTime ?? 0)
            .map({ [weak self] resp -> TopRefreshDataResult in
                let cells = resp.response.threadItems.map { MailThreadListCellViewModel(with: $0, labelId: label, userID: self?.userID ?? "") }
            return (resp, cells)
        })

        for filter in dataFilters {
            dataProvider = dataProvider.flatMap({ (resp, cells) -> Observable<TopRefreshDataResult> in
                return filter
                    .filterCellViewModelsIfNeeded(cellVMS: cells, labelId: label)
                    .map { cellResult -> TopRefreshDataResult in
                    return (resp, cellResult)
                }
            })
        }

        return dataProvider
    }
}
