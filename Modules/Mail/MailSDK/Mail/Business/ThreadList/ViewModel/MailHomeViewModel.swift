//
//  MailHomeViewModel.swift
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
import LarkAlertController

// MARK: state enum
extension MailHomeViewModel {
    enum ErrorRouter {
        case labelListFgDataError(isError: Bool)
    }

    // TODO: 后续需要拆解去除
    enum UIElement {
        case title(String)
        case mailLoading(Bool)
        case labelListSmartInboxFlag(Bool)
        // -- onboard -- ↓
        case showNewFilterOnboardingIfNeeded
        case showSmartInboxTips(SmartInboxTipsView.TipType)
        case showAIOnboardingIfNeeded
        // -- onboard -- ↑
        case smartInboxPreviewCardResponse(labelID: String, Email_Client_V1_MailGetNewMessagePreviewCardResponse)
        case refreshHeaderBizInfo
        // -- multi account -- ↓
        case showMultiAccount(MailAccount, showBadge: (count: Int64, isRed: Bool))
        case dismissMultiAccount
        case updateMultiAccountViewIfNeeded(_ account: MailAccount, accountList: [MailAccount])
        // -- header -- ↓
        case expiredTips(Bool)
        case passLoginExpiredTips(Bool)
        case refreshAuthPage(setting: Email_Client_V1_Setting)
        case refreshPreloadProgressStage(preloadProgress: MailPreloadProgressPushChange, fromLabel: String)
        // -- 自动切换label涉及UI及数据拉取变化 -- ↓
        case autoChangeLabel(labelId: String, labelName: String, isSystem: Bool, updateTimeStamp: Bool)
        case updateArrowView(isHidden: Bool, isRed: Bool)
        /// Stranger场景
        case showFeedBackToast(_ toast: String, isSuccess: Bool, selecteAll: Bool, sessionID: String)
        case handleLongTaskLoading(_ sessionInfo: MailBatchChangeInfo?, show: Bool)
        case dismissStrangerCardList
        // imap migration
        case showSharedAccountMigrationOboarding(migrationsIDs: Set<String>)
    }
}

class MailHomeViewModel {
    // MARK: common utils
    private static let logger = Logger.log(MailHomeViewModel.self, category: "Module.MailHomeViewModel")

    // MARK: property
    var fetcher: DataService? {
        return Store.fetcher
    }

    private(set) lazy var listViewModel = MailThreadListViewModel(labelID: Mail_LabelId_Inbox, userID: userContext.user.userID)
    private(set) lazy var strangerViewModel = MailThreadListViewModel(labelID: Mail_LabelId_Stranger, userID: userContext.user.userID)

    let filterViewModel = MailHomeFilterViewModel()

    lazy var authStatusHelper: MailAuthStatusHelper = {
        let helper = MailAuthStatusHelper()
        return helper
    }()

    var labels = [MailFilterLabelCellModel]()

    // MARK: temp
    let disposeBag = DisposeBag()
    var settingDisposeBag: DisposeBag? = DisposeBag()
    var getLabelDisposeBag = DisposeBag()
    var loadingDisposeBag = DisposeBag()
    private(set) var whiteScreenDetectDisposeBag: DisposeBag = DisposeBag()

    var lastSharedAccountChange: MailSharedAccountChange? = nil
    // TODO: REFACTOR 语意不清
    var lastGetThreadListInfo = (false, false) // (是否已经发起GetThreadList标记, SmartInbox开关状态)

    var currentAccount: MailAccount? {
        return currentAccountObservable.value.0
    }
    let currentAccountObservable: BehaviorRelay<(MailAccount?, Bool)> // 标记是否需要首页重拉数据，保护首次account为defalt无效值的case

    var hasFirstLoaded: Bool = false

    var startedFetchSetting = false

    var startedFetchThreadList = false

    var _labelListFgDataError = false

    var ignoreSettingPush = false

    var isPreloadedData = false

    var firstFetchSmartInboxMode = false

    var canInitData = true

    var enableStranger: Bool?

    let currentLabelIdObservable: BehaviorRelay<String>
    var currentLabelId: String {
        return currentLabelIdObservable.value
    }

    var currentFilterType: MailThreadFilterType {
        return listViewModel.filterType
    }

    var currentLabelName: String {
        return listViewModel.labelName
    }

    var currentTagID: String {
        var tagID = self.currentLabelId
        if labels.first(where: { $0.labelId == self.currentLabelId && $0.tagType == .folder }) != nil {
            tagID = MailLabelId.Folder.rawValue
        }
        return tagID
    }

    var currentLabelModel: MailClientLabel? {
        return MailTagDataManager.shared.getTag(currentLabelId)
    }

    private(set) var datasource: [MailThreadListCellViewModel] = []

    static let THREAD_ID_KEY = "thread_id"

    static let MODELS_KEY = "models"
    
    var clearTrashAlert: UIViewController? = nil
    var updateLabelToTrash = false
    let trashAlertDays = 30

    /// 触发后端的selectall，都走push形式，不走callback
    lazy var sessionIDs = [String]()

    var strangerCardList: MailStrangerCardListController?
    var toastList = [(String, Bool)]()
    var shouldShowLongTask: Bool = false
    var cardListToastList = [(String, Bool)]()
    var didShowStrangerOnboard: Bool = false
    var shouldShowStrangerOnboard: Bool = false
    var batchConfirmAlert: LarkAlertController? = nil
    var conversationMode: Bool = true
    
    // MARK: IMAP Migration
    var migrationState: Email_Client_V1_IMAPMigrationState?
    
    // MARK: Banner 相关
    private(set) var outboxCount: Int = 0
    private lazy var outboxMessageInfos = Set<OutBoxMessageInfo>()

    // MARK: Observable
    @DataManagerValue<MailThreadListViewModel> var bindListVM

    @DataManagerValue<MailThreadListViewModel> var bindStrangerVM

    @DataManagerValue<UIElement> var uiElementChange

    @DataManagerValue<ErrorRouter> var errorRouter

    @DataManagerValue<Int> var outboxCountRefreshed

    @DataManagerValue<(messageId: String, deliveryState: MailClientMessageDeliveryState)> var outboxSendStateChange

    @DataManagerValue<String> var currentLabelDeleted

    @DataManagerValue<Bool> var initSyncFinish

    // --- invalid cache 三巨头 ↓ ---
    @DataManagerValue<()> var mailRefreshAll

    @DataManagerValue<()> var migrationDetailNeedRefresh
    
    @DataManagerValue<Email_Client_V1_IMAPMigrationState> var imapMigrationState
    // --- invalid cache 三巨头 ↑ ---

    // MARK: LifeCircle
    /// TODO:  先用着 userContext，后面看需不需要改成 accountContext
    let userContext: MailUserContext
    
    var longTaskLoadingVC: MailLongTaskLoadingViewController?

    init(userContext: MailUserContext) {
        self.userContext = userContext
        self.currentLabelIdObservable = BehaviorRelay<String>(value: Mail_LabelId_Inbox)
        self.currentAccountObservable = BehaviorRelay<(MailAccount?, Bool)>(value: (Store.settingData.getCachedCurrentAccount(), false))

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didReceiveMemoryWarning),
                                               name: UIApplication.didReceiveMemoryWarningNotification,
                                               object: nil)
        bindPush()
    }

    @objc
    private func didReceiveMemoryWarning () {
        MailHomeViewModel.logger.debug("didReceiveMemoryWarning")
    }

    private func bindPush() {
        PushDispatcher
            .shared
            .mailChange
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (push) in
                switch push {
                case .updateLabelsChange(let change):
                    self?.labelChange(change)
                default:
                    break
                }
        }).disposed(by: disposeBag)

        /// cacheInvalid 需要节流
        PushDispatcher.shared.mailChange.filter { push in
            if case .cacheInvalidChange(_) = push {
                return true
            }
            return false
        }.throttle(.seconds(1), scheduler: MainScheduler.instance)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (push) in
                if case .cacheInvalidChange(let change) = push {
                    self?.cacheInvalidChange(change)
                }
            }).disposed(by: disposeBag)

        EventBus.threadListEvent
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (event) in
                switch event {
                case .needUpdateOutbox:
                    self?.fetchAndUpdateOutboxState()
                case .needLoadMoreThreadIfNeeded(label: let label, timestamp: let tm, source: let source):
                    self?.handleLoadMoreIfNeeded(label: label, timestamp: tm, source: source)
                default:
                    break
                }
        }).disposed(by: disposeBag)

        PushDispatcher
            .shared
            .mailPreloadProgressChange
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (preloadProgress) in
                guard let `self` = self else { return }
                MailLogger.info("[mail_cache_preload] receive mailPreloadProgressPush, preloadProgress: \(preloadProgress)")
                self.$uiElementChange.accept(.refreshPreloadProgressStage(preloadProgress: preloadProgress, fromLabel: self.currentLabelId))
        }).disposed(by: disposeBag)
        
        Store.settingData
            .preloadRangeChanges
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] () in
                guard let `self` = self else { return }
                let dismissPreloadProgress = MailPreloadProgressPushChange(status: .preloadStatusUnspecified, progress: 0, errorCode: .unknownError, preloadTs: .preloadClosed, isBannerClosed: false, needPush: true)
                self.$uiElementChange.accept(.refreshPreloadProgressStage(preloadProgress: dismissPreloadProgress, fromLabel: self.currentLabelId))
        }).disposed(by: disposeBag)

        NotificationCenter.default.rx.notification(Notification.Name.Mail.MAIL_SDK_CLEAN_DATA)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                self.cleanAllCache()
            }).disposed(by: disposeBag)

        NotificationCenter.default.rx.notification(Notification.Name.Mail.MAIL_CACHED_CURRENT_SETTING_CHANGED)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                if let account = Store.settingData.getCachedCurrentAccount() {
                    self.refreshGetThreadListIfNeeded(account.mailSetting)
                    self.updateCurrentAccount(account)
                }
            }).disposed(by: disposeBag)
        
        MailCommonDataMananger
            .shared
            .batchEndChange
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (change) in
                self?.mailBatchChangesEnd(change)
            }).disposed(by: disposeBag)

        Store.settingData
            .batchSessionChanges
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (sessionInfos) in
                guard let `self` = self else { return }
                self.mailBatchResultChanges(sessionInfos)
        }).disposed(by: disposeBag)

        Store.settingData
            .easSyncRangeChanges
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] () in
                guard let `self` = self else { return }
                self.triggerMailClientRefreshIfNeeded(self.currentLabelId)
        }).disposed(by: disposeBag)
        
        // IMAP Migration Push
        EventBus.mailIMAPMigrationStatePush.subscribe(onNext: {[weak self] change in
            guard let self = self else { return }
            guard self.userContext.featureManager.open(.imapMigration, openInMailClient: false) else {
                MailLogger.info("[mail_client] [imap_migration] featuregate disable")
                return
            }

            MailLogger.info("[mail_client] [imap_migration] push state \(change.state.status), provider: \(change.state.imapProvider), id: \(change.state.migrationID), messageID: \(change.state.reportMessageID)")
            self.migrationState = change.state
            self.$imapMigrationState.accept(change.state)
        }).disposed(by: disposeBag)

    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: Data flow

    /// 初始化数据，创建完viewModel 绑定了必要的数据后在这里进行拉取
    func initData() {
        MailLogger.info("[mail_home_init] MailHomeViewModel initData")
        if isPreloadedData {
            // 走预加载情况的逻辑，少了请求，直接应用。
            initDataOfPreloaded()
        } else {
            MailLogger.info("[mail_preload] noNeed to preload")
            // 走正常的拉取流程  get account list, then refresh others
            refreshAllListData()
        }
    }
}

// MARK: interface
extension MailHomeViewModel {
    func switchLabelAndFilterType(_ labelId: String, labelName: String, filterType: MailThreadFilterType) {
        let oldLabelId = currentLabelId
        // 重新创建一个新的listViewModel，然后触发VC重新绑定
        if oldLabelId != labelId || currentFilterType != filterType {
            filterViewModel.didSelectFilter(type: filterType)
            createNewThreadList(labelId: labelId, labelName: labelName)
        }
    }

    func cancelSettingFetch() {
        MailLogger.info("[mail_home_init] cancelSettingFetch")
        settingDisposeBag = nil
        settingDisposeBag = DisposeBag()
    }

    /// 为了充分适配当前代码，这个做的事情是 listViewModel内的threads -> datasource
    func syncDataSource() {
        datasource = listViewModel.mailThreads.all
    }

    func syncDataSource(datas: [MailThreadListCellViewModel]) {
        datasource = datas
    }
    
    // 确保labelname逻辑
    @discardableResult
    func startupInfo(_ setting: MailSetting? = nil) -> (String, Bool) {
        var initLabelId = self.currentLabelId
        var labelName = self.currentLabelName
        /// 判断是否开启了 smartInbox
        var smartInboxEnable = false
        if let setting = setting ?? self.currentAccount?.mailSetting, setting.smartInboxMode,
           !_labelListFgDataError {
            smartInboxEnable = true
            MailLogger.info("[mail_init] smartInboxModeEnable")
        }
        if smartInboxEnable, userContext.featureManager.open(.aiBlock, openInMailClient: false) {
            MailLogger.info("[mail_init] aiBlock smartInboxModeEnable set false")
            smartInboxEnable = false
        }
        self.firstFetchSmartInboxMode = smartInboxEnable

        if smartInboxEnable {
            initLabelId = Mail_LabelId_Important
            labelName = BundleI18n.MailSDK.Mail_SmartInbox_Important
        } else {
            initLabelId = Mail_LabelId_Inbox
            labelName = BundleI18n.MailSDK.Mail_Folder_Inbox
        }

        if Store.settingData.mailClient {
            if labels.map({ $0.labelId }).contains(Mail_LabelId_Inbox) {
                initLabelId = Mail_LabelId_Inbox
                labelName = BundleI18n.MailSDK.Mail_Folder_Inbox
            } else {
                initLabelId =  labels.first?.labelId ?? Mail_LabelId_Inbox
                labelName = labels.first?.text ?? BundleI18n.MailSDK.Mail_Folder_Inbox
            }
            self.$uiElementChange.accept(.title(BundleI18n.MailSDK.Mail_Folder_Inbox))
        }

        // 根据之前的判断，最后统一赋值
        createNewThreadList(labelId: initLabelId, labelName: labelName)
        self.$uiElementChange.accept(.title(labelName))

        MailLogger.info("[mail_home_init] [mail_init] currentLabelId:\(currentLabelId) smartInboxEnable:\(smartInboxEnable)")
        return (currentLabelId, smartInboxEnable)
    }

    func getThreadList(_ setting: MailSetting? = nil) {
        let startupInfo = self.startupInfo(setting)
        MailLogger.info("[mail_home_init] [mail_init] getThreadList \(setting?.smartInboxMode ?? startupInfo.1)")
        lastGetThreadListInfo = (true, setting?.smartInboxMode ?? startupInfo.1)

        self.showLoadingIfNeededFirstScreen(labelId: self.currentLabelId, type: self.currentFilterType)
        if startupInfo.0 == Mail_LabelId_Important {
            self.showPreviewCardIfNeeded(Mail_LabelId_Other)
        }
        if let setting = setting {
            self.$uiElementChange.accept(.labelListSmartInboxFlag(setting.smartInboxMode))
        } else {
            self.$uiElementChange.accept(.labelListSmartInboxFlag(startupInfo.1))
        }
        if userContext.featureManager.open(.aiBlock) {
            lastGetThreadListInfo = (true, setting?.smartInboxMode ?? startupInfo.1)
            self.$uiElementChange.accept(.labelListSmartInboxFlag(false))
        }
        self.$errorRouter.accept(.labelListFgDataError(isError: self._labelListFgDataError))
        EventBus.$threadListEvent.accept(.updateLabelsCellVM(labels: labels))
        listViewModel.getMailListFromLocal()
        if hasFirstLoaded {
            showSmartInboxOnboardingIfNeeded()
            self.$uiElementChange.accept(.showNewFilterOnboardingIfNeeded)
            self.$uiElementChange.accept(.showAIOnboardingIfNeeded)
        }
    }

    func loadMore() {
        let lastMessageTimeStamp = datasource.last?.lastmessageTime ?? 0
        apmMarkThreadListStart(sence: .sence_load_more)
        if !listViewModel.isLoading {
            listViewModel.getMailListFromLocal()
            MailLogger.debug( "Mail Thread List Load More - LabelID: \(currentLabelId) timeStamp: \(lastMessageTimeStamp)")
        }
    }

    func isLastPage() -> Bool {
        return listViewModel.isLastPage
    }

    func needAutoLoadMore() -> Bool {
        var needAutoLoadMore = listViewModel.autoLoadMore &&
        listViewModel.mailThreads.all.count < MailThreadListViewModel.pageLength &&
        !listViewModel.isLastPage
        if needAutoLoadMore {
            listViewModel.autoLoadMore = false // 只执行一次
        }
        return needAutoLoadMore
    }
    
    func resetWhiteScreenDetect() {
        MailLogger.info("[mail_loading] resetWhiteScreenDetect")
        whiteScreenDetectDisposeBag = DisposeBag()
    }

    func preloadVisableIndexsIfNeed(indexPaths: [IndexPath]) {
        let images: [MailClientDraftImage] = indexPaths.flatMap { index -> [MailClientDraftImage] in
            guard self.datasource.count > index.row, index.row >= 0 else { return [] }
            // 每封邮件最多加载N张图片
            let firstN = userContext.sharedServices.provider.settingConfig?.preloadConfig?.preloadImageCountPerThread ?? 0
            return Array(self.datasource[index.row].images.prefix(firstN))
        }
        let preloader = userContext.sharedServices.preloadServices
        preloader.preloadImages(images: images, source: .list)
    }

    func preloadImagesWhenClick(index: Int) {
        guard true == userContext.provider.settingConfig?.preloadConfig?.enablePreDownloadImg else {
            MailLogger.info("disable predownload img")
            return
        }
        guard self.datasource.count > index, index >= 0 else {
            mailAssertionFailure("invalid click index")
            return
        }
        let images: [MailClientDraftImage] = self.datasource[index].images
        MailLogger.info("images count: \(images.count)")
        let preloader = userContext.sharedServices.preloadServices
        preloader.preloadImagesImmediately(images)
    }

    func setupConversationModeValue() {
        conversationMode = Store.settingData.getCachedCurrentSetting()?.enableConversationMode ?? true
    }
}

// MARK: internal interface
extension MailHomeViewModel {
    func showSmartInboxOnboardingIfNeeded() {
        guard !Store.settingData.mailClient else { return }
        guard let setting = userContext.user.getUserSetting() else {
            return
        }
        if setting.smartInboxMode || currentLabelId == Mail_LabelId_Important {
            self.$uiElementChange.accept(.showSmartInboxTips(.labelPop))
            return
        }
    }

    func showPreviewCardIfNeeded(_ labelID: String) {
        guard !Store.settingData.mailClient else { return }
        guard smartInboxLabels.contains(currentLabelId) else {
            return
        }
        guard currentLabelId != labelID else {
            MailLogger.error("Send getPreviewCard label ID equal, no need to fetch \(labelID)")
            return
        }
        MailLogger.info("Send getPreviewCard request: \(labelID)")
        MailDataServiceFactory
            .commonDataService?
            .getPreviewCard(label_id: labelID).subscribe(onNext: { [weak self] (response) in
                guard let `self` = self else { return }
                self.$uiElementChange.accept(.smartInboxPreviewCardResponse(labelID: labelID, response))
            }, onError: { (error) in
                MailLogger.error("Send getPreviewCard request failed error: \(error).")
            }).disposed(by: disposeBag)
    }

    private func showLoadingIfNeededFirstScreen(labelId: String, type: MailThreadFilterType) {
        guard !labelId.isEmpty else { return }
        guard self.datasource.isEmpty else { return }
        fetcher?.getLabelThreadsEnough(labelId: labelId, filterType: type)
            .subscribe(onNext: { [weak self] (result) in
            guard let `self` = self else { return }
            MailLogger.info("[mail_init] [mail_loading] mail show load enough \(result.enough)")
                if !result.enough {
                    self.$uiElementChange.accept(.mailLoading(true))
                } else {
                    self.whiteScreenDetectDisposeBag = DisposeBag()
                }
            }, onError: { (error) in
                MailLogger.error("[mail_init] showLoadingIfNeededFirstScreen failed", error: error)
            }).disposed(by: self.disposeBag)
    }

    func createNewThreadList(labelId: String, labelName: String? = nil) {
        guard labelId != listViewModel.labelID else {
            return
        }
        MailLogger.info("[mail_init] createNewThreadList old label \(listViewModel.labelID) new label \(labelId) currentFilterType: \(currentFilterType)")
        let needResetFilterType = filterViewModel.selectedFilter.value.0 != .allMail
        self.listViewModel = MailThreadListViewModel(labelID: labelId, userID: userContext.user.userID)
        if needResetFilterType {
            self.listViewModel.filterType = filterViewModel.selectedFilter.value.0
            MailLogger.info("[mail_init] createNewThreadList reset filtertype")
        }

        if let name = labelName {
            self.listViewModel.labelName = name
        }
        self.$bindListVM.accept(listViewModel)
        self.currentLabelIdObservable.accept(labelId)
        filterViewModel.didSelectFilter(type: currentFilterType)
    }

    private func handleLoadMoreIfNeeded(label: String, timestamp: Int64?, source: PushDispatcher.ActionSource) {
        guard label == currentLabelId else {
            return
        }
        // 这里不能传allmail 因为有filtertype的存在
        listViewModel.getMailListFromLocal(fromMessageList: source == .messageList)
    }
}

// MARK: changelog dispatch
extension MailHomeViewModel {
    func labelChange(_ change: MailLabelChange) {
//        $mailLabelChange.accept(change.labels) // TODO: REFACTOR 让业务VM直接监听changelog
        MailHomeViewModel.logger.debug("MailChangePush -> labelChange")
        MailTracker.log(event: Homeric.EMAIL_CHANGE_LOG, params: ["change": "labelChange"])
        // 如果当前 label 不存在，则通知当前 label 已被删除, outbox 和 scheduled 除外
        if self.listViewModel.labelID == Mail_LabelId_Outbox || self.listViewModel.labelID == Mail_LabelId_Scheduled {
            return
        }
        if change.labels.isEmpty {
            MailHomeViewModel.logger.error("MailChangePush -> labelChange label is null")
            return
        }
        if !(change.labels.contains(where: { $0.id == self.listViewModel.labelID })) {
            self.$currentLabelDeleted.accept(self.listViewModel.labelID)
        }
        self.labels = change.labels.map({ MailFilterLabelCellModel(pbModel: $0) })
        self.updateUnreadDotAfterFirstScreenLoaded()
    }

    func cacheInvalidChange(_ change: MailCacheInvalidChange) {
        MailTracker.log(event: Homeric.EMAIL_CHANGE_LOG, params: ["change": "cacheInvalid"])
        MailHomeViewModel.logger.debug("MailCacheInvalid --> clean cache")
        cleanAllCache()
        MailHomeViewModel.logger.debug("MailChangePush -> cacheInvalid -> refresh")
    }

    // clean memory cache
    func cleanAllCache() {
        $mailRefreshAll.accept(())
        $migrationDetailNeedRefresh.accept(())
    }
}

// MARK: - Outbox

extension MailHomeViewModel {
    /// New outbox
    func fetchAndUpdateOutboxState() {
        fetcher?.getOutBoxMessageState().subscribe(onNext: { [weak self] infos in
            guard let self = self else { return }
            let messageInfos = Set(infos)
            let newMessageInfos = messageInfos.subtracting(self.outboxMessageInfos)
            let failedMessageInfos = messageInfos.filter({ $0.deliveryState == .sendError })
            if !newMessageInfos.filter({ $0.deliveryState == .sendError }).isEmpty {
                /// 有新的失败 Message，重置 banner 状态
                let kvStore = self.userContext.getCurrentAccountContext().accountKVStore
                kvStore.set(false, forKey: UserDefaultKeys.dismissMillOutboxTip)
            }

            MailLogger.info("Did Update outbox count from: \(self.outboxCount) to: \(failedMessageInfos.count), infos count: \(infos.count)")

            self.outboxCount = failedMessageInfos.count
            self.outboxMessageInfos = messageInfos
            self.$outboxCountRefreshed.accept(failedMessageInfos.count)
            EventBus.$threadListEvent.accept(.didFailedOutboxCountRefreshed(failedMessageInfos.count))

            // Update Datasource
            newMessageInfos.forEach {
                self.removeOutboxThread($0.messageID, deliveryState: $0.deliveryState)
                self.$outboxSendStateChange.accept(($0.messageID, $0.deliveryState))
            }
        }, onError: { error in
            MailLogger.error("Failed to get outbox message state, error: \(error)")
        }).disposed(by: disposeBag)
    }

    private func removeOutboxThread(_ threadID: String, deliveryState: MailClientMessageDeliveryState) {
        guard deliveryState == .delivered, currentLabelId == Mail_LabelId_Outbox else { return }
        var outboxList = listViewModel.mailThreads.all
        if let threadIndex = outboxList.firstIndex(where: { $0.threadID == threadID }) {
            outboxList.remove(at: threadIndex)
            listViewModel.mailThreads.replaceAll(outboxList)
        }
    }
}

// MARK: Smart Inbox相关
extension MailHomeViewModel {
    // 进入 或 离开 Important和Other都需要更新时间戳
    func updateVisitSmartInboxTimestampIfNeeded(_ labelId: String) {
        // 合并更新时间戳
        if (currentLabelId == Mail_LabelId_Important && labelId == Mail_LabelId_Other) ||
            (currentLabelId == Mail_LabelId_Other && labelId == Mail_LabelId_Important) {
            updateLastVisitSmartInboxTimestamp()
            return
        }
        if labelId == Mail_LabelId_Important {
            updateLastVisitImportantLabelTimestamp()
        }
        if labelId == Mail_LabelId_Other {
            updateLastVisitOtherLabelTimestamp()
        }
    }

    func updateLastVisitSmartInboxTimestamp() {
        let nowTimestamp = Int64(Date().milliTimestamp) ?? 0
        Store.settingData.updateCurrentSettings(.lastVisitImportantLabelTimestamp(nowTimestamp),
                                                        .lastVisitOtherLabelTimestamp(nowTimestamp))
    }

    func updateLastVisitImportantLabelTimestamp() {
        let nowTimestamp = Int64(Date().milliTimestamp) ?? 0
        Store.settingData.updateCurrentSettings(.lastVisitImportantLabelTimestamp(nowTimestamp))
    }

    func updateLastVisitOtherLabelTimestamp() {
        let nowTimestamp = Int64(Date().milliTimestamp) ?? 0
        Store.settingData.updateCurrentSettings(.lastVisitOtherLabelTimestamp(nowTimestamp))
    }
}

// 三方调用refresh接口
extension MailHomeViewModel {
    func triggerMailClientRefreshIfNeeded(_ labelId: String? = nil) {
        guard Store.settingData.mailClient else { return }
        Store.fetcher?
            .refreshThreadList(label_id: labelId ?? currentLabelId,
                               filterType: .allMail,
                               first_timestamp: datasource.first?.lastmessageTime ?? 0,
                               enableDebounce: true)
            .subscribe(onNext: { (_) in
                MailLogger.info("[mail_client_refresh] success")
            }, onError: { (error) in
                MailLogger.info("[mail_client_refresh] error:\(error)")
            }).disposed(by: disposeBag)
    }
}
