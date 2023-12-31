//
//  ThreadListHeaderManager.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2021/3/30.
//

import Foundation
import LarkAlertController
import EENavigator
import Homeric
import LarkUIKit
import RxSwift
import RustPB

protocol ThreadListHeaderManagerDelegate: MailMigrationStateTipsViewDelegate, AnyObject {
    func resetTableViewHeader()
    func closeTableViewHeader()
    func updateTableViewHeader(with headerView: MailThreadListHeaderView)
    func navigatorFromHome(_ viewController: UIViewController, present: Bool) // present or push
    func naviToServiceConsultant()
    func headerNeddExitMultiSelect()
    func changeLabel(auto: Bool, labelID: String, title: String, isSystemLabel: Bool)
    func mailClientReVerfiy()
    func mailClientReLink()
    func preloadCacheTipHandler(showDetail: Bool, dismiss: Bool, preloadProgress: MailPreloadProgressPushChange)
    func strangerCardListMoreActionHandler(sender: UIControl)
    func strangerCardListItemHandler(index: Int, threadID: String)
    func strangerCardListMoreCardItemHandler()
    func strangerCardCellDidClickReply(_ cell: MailStrangerThreadCell, cellModel: MailThreadListCellViewModel, status: Bool)
    func strangerCardCellDidClickAvatar(mailAddress: MailAddress, cellModel: MailThreadListCellViewModel)

    // MARK: DataSource
    func headerCurrentLabelId(headerManager: ThreadListHeaderManager) -> String
    func headerCurrentAccount(headerManager: ThreadListHeaderManager) -> MailAccount?
    func headerCurrentAccountContext(headerManager: ThreadListHeaderManager) -> MailAccountContext
    func trashClearAll()
}

class ThreadListHeaderManager {
    lazy var tableHeaderView: MailThreadListHeaderView = {
        let headerView = MailThreadListHeaderView(reuseIdentifier: "MailThreadListHeaderView")
        headerView.delegate = self
        return headerView
    }()
    var tempHeaderView: MailThreadListHeaderView?
    var migrationDoneAlertVC: LarkAlertController?
    weak var delegate: ThreadListHeaderManagerDelegate?

    var currentLabelId: String {
        guard let delegate = delegate else {
            mailAssertionFailure("no delegate of headerMananger found")
            return ""
        }
        return delegate.headerCurrentLabelId(headerManager: self)
    }
    var currentAccount: MailAccount? {
        return delegate?.headerCurrentAccount(headerManager: self)
    }
    private let disposeBag = DisposeBag()
    private let userContext: MailUserContext
    lazy var strangerViewModel = MailThreadListViewModel(labelID: Mail_LabelId_Stranger, userID: self.userContext.user.userID)

    init(userContext: MailUserContext) {
        self.userContext = userContext
    }

    func closeAccountDimensionHeader() {
        tableHeaderView = tableHeaderView.dismissSmartInboxPreviewCard()
        tableHeaderView = tableHeaderView.dismissPreloadCacheTask()
        tableHeaderView = tableHeaderView.dismissStrangerCardListView()
        tableHeaderView = tableHeaderView.dismissOOOTips()
        delegate?.updateTableViewHeader(with: tableHeaderView)
    }

    func refreshBussiessInfo() {
        /// 初始化的时候 refresh 一下 outbox
        /// 之后的 outbox 变化，通过 rust 端推送来更新
        self.refreshOutboxCount()
        /// refresh migration details
        self.refreshMailMigrationDetails()
        /// refresh ooo tips
        self.setupOutOfOfficeTipsAndSmartInboxIfNeeded()
        /// refresh storage limit
        self.refreshStorageLimit()
    }

    func refreshOutboxCount() {
        /// 如果用户选了dismiss，则暂时不用刷新
        let accountID = Store.settingData.getCachedCurrentAccount()?.mailAccountID ?? ""
        let kvStore = MailKVStore(space: .user(id: userContext.user.userID), mSpace: .account(id: accountID))
        let dismiss: Bool = kvStore.bool(forKey: UserDefaultKeys.dismissMillOutboxTip)
        if dismiss || self.currentLabelId == Mail_LabelId_Outbox {
            dismissOutboxTips()
        }

        EventBus.$threadListEvent.accept(.needUpdateOutbox)
    }

    @objc
    func refreshMailMigrationDetails() {
        Store.settingData.getCurrentSetting()
        .subscribe(onNext: {[weak self](resp) in
            guard let self = `self` else { return }
            /// if statusIsMigrationDonePromptRendered is true, no need to get migration status
            if !resp.statusIsMigrationDonePromptRendered && Store.settingData.getCachedCurrentAccount()?.mailSetting.userType != .tripartiteClient {
                MailDataServiceFactory.commonDataService?.getMailMigrationDetails().subscribe(onNext: {[weak self](details) in
                    guard let self = `self` else { return }
                    MailHomeController.logger.debug( "migration refresh stage:\(details.stage) progressPct:\(details.progressPct)")
                    self.updateMigrationState(stage: Int(details.stage),
                                              progressPct: Int(details.progressPct),
                                              showAlert: true)
                }).disposed(by: self.disposeBag)
            } else {
                self.delegate?.updateTableViewHeader(with: self.tableHeaderView.dismissMailSyncTips())
            }
        }).disposed(by: self.disposeBag)
    }

    private func refreshOOOTips(by setting: MailSetting) {
        if setting.vacationResponder.enable && Int64(Date().milliTimestamp) ?? 0 > setting.vacationResponder.startTimestamp {
            tableHeaderView = tableHeaderView.showOOOTips()
        } else {
            tableHeaderView = tableHeaderView.dismissOOOTips()
        }
        self.delegate?.updateTableViewHeader(with: tableHeaderView)
    }

    func setupOutOfOfficeTipsAndSmartInboxIfNeeded(_ setting: MailSetting? = nil) {
        if let setting = setting {
            self.refreshOOOTips(by: setting)
        } else {
            Store.settingData.getCurrentSetting().observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (setting) in
                guard let `self` = self else { return }
                self.refreshOOOTips(by: setting)
            }, onError: { (error) in
                MailHomeController.logger.error("getEmailSetting failed", error: error)
            }).disposed(by: disposeBag)
        }
    }

    func refreshStorageLimit(_ setting: MailSetting? = nil) {
        if let setting = setting {
            self.updateStorageLimit(setting)
        } else {
            Store.settingData.getCurrentSetting()
            .subscribe(onNext: { [weak self] (resp) in
                guard let self = `self` else { return }
                self.updateStorageLimit(resp)
            }).disposed(by: self.disposeBag)
        }
    }

    private func updateStorageLimit(_ setting: MailSetting) {
        MailLogger.info("updateStorageLimit enable: \(setting.storageLimitNotify.enable) limit: \(setting.storageLimitNotify.limit) isAdmin: \(setting.storageLimitNotify.isAdmin)")
        guard setting.storageLimitNotify.enable else {
            tableHeaderView = tableHeaderView.dismissBilingReminderNotice()
            tableHeaderView = tableHeaderView.dismissServiceSuspensionNotice()
            self.delegate?.updateTableViewHeader(with: tableHeaderView)
            return
        }
        if setting.storageLimitNotify.limit >= 100 {
            // 已满
            tableHeaderView = tableHeaderView.showServiceSuspensionNotice(setting.storageLimitNotify.isAdmin)
        } else if setting.storageLimitNotify.isAdmin {
            // 未满，只有管理员有提醒
            tableHeaderView = tableHeaderView.showBilingReminderNotice(Int(setting.storageLimitNotify.limit))
        }
        self.delegate?.updateTableViewHeader(with: tableHeaderView)
    }
}

// MARK: MailSyncStatusTipsView
extension ThreadListHeaderManager {
    func updateMigrationState(stage: Int, progressPct: Int, showAlert: Bool = false) {
        MailHomeController.logger.debug( "migration update state:\(stage) progressPct:\(progressPct)")
        /// if mail syny in progress
        showMailMigrationState(stage: MailMigrationStateTipsView.MigrationStage(rawValue: stage) ?? .invalid,
                               progressPct: progressPct,
                               showAlert: showAlert)
    }

    func showMailMigrationState(stage: MailMigrationStateTipsView.MigrationStage, progressPct: Int, showAlert: Bool = false) {
        /// if user click alert after migration done/error, don't show tips again before the state change to inProgress
        /// show sync status tips
        tableHeaderView = tableHeaderView.showMailSyncTips(state: stage, progressPct: progressPct)
        delegate?.updateTableViewHeader(with: tableHeaderView)
        MailHomeController.logger.debug( "migration show tips view at stage \(stage.rawValue)")
        if showAlert {
            checkAndShowMigrationAlert(stage)
        }
    }

    func checkAndShowMigrationAlert(_ stage: MailMigrationStateTipsView.MigrationStage) {
        if let alert = tableHeaderView.alertOfMigrationTips(at: stage, onClickOK: { [weak self] in
            guard let `self` = self else { return }
            self.dismissMailMigrationStateTips(type: .api)
            self.setStatusIsMigrationDonePromptRendered()
        }) {
            MailHomeController.logger.debug( "migration show done alert at stage \(stage.rawValue)")
            asyncRunInMainThread { [weak self] in
                guard let `self` = self else { return }
                self.migrationDoneAlertVC = alert
                self.delegate?.navigatorFromHome(alert, present: true)
                // navigator?.present(alert, from: self)
                if stage == .done || stage == .doneWithError {
                    self.tableHeaderView = self.tableHeaderView.showMailSyncTips(state: stage, progressPct: 100)
                    self.delegate?.updateTableViewHeader(with: self.tableHeaderView)
                }
            }
        }
    }

    /// if click alert, set StatusIsMigrationDonePromptRendered to true
    private func setStatusIsMigrationDonePromptRendered() {
        Store.settingData.updateCurrentSettings(.statusIsMigrationDonePromptRendered(true))
    }
}

// MARK: IMAP Migration State
extension ThreadListHeaderManager {
    func dismissIMAPMigrationHeader() {
        delegate?.updateTableViewHeader(with: tableHeaderView.dismissIMAPMigrationTips())
    }
    func refreshIMAPMigration(state: Email_Client_V1_IMAPMigrationState) {
        typealias MigrationConfig = MailMigrationStateTipsView.MigrationTipsConfig
        let status = state.status
        let provider = IMAPMigrationProvider(rawValue: state.imapProvider) ?? .other
        MailLogger.info("[mail_client] [imap_migration] refresh state \(status), total: \(state.totalMessageCount), recieve: \(state.finishedMessageCount)")
        
        switch status {
        case .done:
            MailTracker.log(event: "email_mail_mig_banner_view",
                            params: ["mail_service": provider.rawValue,
                                     "mail_account_type": Store.settingData.getMailAccountType(),
                                     "banner_type": "finish"])
            let text = BundleI18n.MailSDK.Mail_EmailMigration_Mobile_MigrationCompleted_Notice_Text
            let detail = BundleI18n.MailSDK.Mail_EmailMigration_Mobile_MigrationCompleted_Notice_ViewReportButton
            let showDetail = !state.reportMessageID.isEmpty
            let config = MigrationConfig(type: .imap, tips: text, detailButton: detail, showDetail: showDetail, showClose: true)
            delegate?.updateTableViewHeader(with: tableHeaderView.showIMAPMigrationTips(stage: .done,
                                                                                        progressPct: 100,
                                                                                        config: config))
        case .migrating, .syncUid:
            MailTracker.log(event: "email_mail_mig_banner_view",
                            params: ["mail_service": provider.rawValue,
                                     "mail_account_type": Store.settingData.getMailAccountType(),
                                     "banner_type": "normal"])
            var progress: Int = 0
            if state.totalMessageCount > 0 {
                progress = Int(CGFloat(state.finishedMessageCount) / CGFloat(state.totalMessageCount) * 100)
            }
            let text = BundleI18n.MailSDK.Mail_EmailMigration_Mobile_MigrationInProgress_Notice_TextWithPercent("\(progress)%")
            let detail = BundleI18n.MailSDK.Mail_EmailMigration_Mobile_MigrationInProgress_Notice_DetailsTextButton
            let config = MigrationConfig(type: .imap, tips: text, detailButton: detail, showDetail: true, showClose: false)
            delegate?.updateTableViewHeader(with: tableHeaderView.showIMAPMigrationTips(stage: .inProgress,
                                                                                        progressPct: progress,
                                                                                        config: config))
        case .pause:
            MailTracker.log(event: "email_mail_mig_banner_view",
                            params: ["mail_service": provider.rawValue,
                                     "mail_account_type": Store.settingData.getMailAccountType(),
                                     "banner_type": "pause"])
            let text = BundleI18n.MailSDK.Mail_EmailMigration_Mobile_MigrationPausedUnableToSendOrReceive_Notice_Text()
            let config = MigrationConfig(type: .imap, tips: text, detailButton: "", showDetail: false, showClose: false)
            delegate?.updateTableViewHeader(with: tableHeaderView.showIMAPMigrationTips(stage: .terminated,
                                                                                        progressPct: 0,
                                                                                        config: config))
        case .none:
            delegate?.updateTableViewHeader(with: tableHeaderView.dismissIMAPMigrationTips())
        case .block:
            if state.blockReason == .authFail {
                MailTracker.log(event: "email_mail_mig_banner_view",
                                params: ["mail_service": provider.rawValue,
                                         "mail_account_type": Store.settingData.getMailAccountType(),
                                         "banner_type": "error"])
                let text = BundleI18n.MailSDK.Mail_EmailMigration_Mobile_MigrationPausedPasswordError_Notice_Text
                let detail = BundleI18n.MailSDK.Mail_EmailMigration_Mobile_MigrationPausedPasswordError_Notice_LogInButton
                let config = MigrationConfig(type: .imap, tips: text, detailButton: detail, showDetail: true, showClose: false)
                delegate?.updateTableViewHeader(with: tableHeaderView.showIMAPMigrationTips(stage: .terminated,
                                                                                            progressPct: 0,
                                                                                            config: config))
            }
        case .authOut, .init_:
            MailLogger.error("[mail_client] [imap_migration] unexpect status \(status)")
        @unknown default:
            MailLogger.error("[mail_client] [imap_migration] unknown status \(status)")
        }
    }
}
extension ThreadListHeaderManager: MailThreadListHeaderViewDelegate {
    func didClickAvatar(mailAddress: MailAddress, cellModel: MailThreadListCellViewModel) {
        delegate?.strangerCardCellDidClickAvatar(mailAddress: mailAddress, cellModel: cellModel)
    }

    // MARK: - MailThreadListHeaderViewDelegate
    func storageLimitContactHelp() {
        // applink 跳转到人工客服
        delegate?.naviToServiceConsultant()
    }

    func showExpiredTips() {
        if Store.settingData.mailClient { // saas的状态下不该出现过期提示
            tableHeaderView = tableHeaderView.showMailClientExpiredTips()
            delegate?.updateTableViewHeader(with: tableHeaderView)
        }
    }

    func dismissExpiredTips() {
        tableHeaderView = tableHeaderView.dismisssMailClientExpiredTips()
        delegate?.updateTableViewHeader(with: tableHeaderView)
    }
    
    func showPassLoginExpiredTips() {
        if Store.settingData.mailClient { // saas的状态下不该出现过期提示
            tableHeaderView = tableHeaderView.showMailClientPassLoginExpiredTips()
            delegate?.updateTableViewHeader(with: tableHeaderView)
        }
    }

    func dismissPassLoginExpiredTips() {
        tableHeaderView = tableHeaderView.dismisssMailClientPassLoginExpiredTips()
        delegate?.updateTableViewHeader(with: tableHeaderView)
    }

    func refreshPreloadProgressStage(_ preloadProgress: MailPreloadProgressPushChange, fromLabel: String) {

        MailLogger.info("[mail_cache_preload] status:\(preloadProgress.status), isbannerClosed: \(preloadProgress.isBannerClosed), progress: \(preloadProgress.progress),errorCode: \(preloadProgress.errorCode), needPush: \(preloadProgress.needPush)")
        let status = preloadProgress.status
        let hideBanner = preloadProgress.preloadTs == .preloadClosed || preloadProgress.preloadTs == .preloadStUnspecified || preloadProgress.isBannerClosed

        if status == .preloadStatusUnspecified || status == .noTask || preloadProgress.errorCode == .userAbort || hideBanner ||
        (status == .stopped && preloadProgress.progress == 100 && preloadProgress.errorCode == .pushErrorUnspecified && preloadProgress.isBannerClosed) { // 用户主动关闭后不展示成功的绿色banner
            delegate?.updateTableViewHeader(with: tableHeaderView.dismissPreloadCacheTask())
        } else {
            delegate?.updateTableViewHeader(with: tableHeaderView.showPreloadCacheNotice(preloadProgress))
            MailTracker.log(event: "email_offline_cache_banner_view", params: ["label_item": fromLabel, "banner_type": preloadProgress.preloadStatus()])
        }
    }

    func preloadCacheTipShowDetail(preloadProgress: MailPreloadProgressPushChange) {
        delegate?.preloadCacheTipHandler(showDetail: true, dismiss: false, preloadProgress: preloadProgress)
    }

    func dismissPreloadCacheTip(preloadProgress: MailPreloadProgressPushChange) {
        delegate?.preloadCacheTipHandler(showDetail: false, dismiss: true, preloadProgress: preloadProgress)
    }

    func dismissPreloadCacheNotice() {
        delegate?.updateTableViewHeader(with: tableHeaderView.dismissPreloadCacheNotice())
    }

    func clientReVerify() {
        delegate?.mailClientReVerfiy()
    }
    
    func clientReLink() {
        delegate?.mailClientReLink()
    }
    
    func clickTrashClearAll() {
        delegate?.trashClearAll()
    }

    func storageLimitCancelWarning() {
        delegate?.updateTableViewHeader(with: tableHeaderView.dismissBilingReminderNotice())
        guard var storageLimit = currentAccount?.mailSetting.storageLimitNotify else {
            MailLogger.debug("get storageLimit fail because currentAccount is nil")
            Store.settingData.getCurrentSetting()
            .subscribe(onNext: { (resp) in
                var storageLimit = resp.storageLimitNotify
                storageLimit.enable = false
                MailLogger.debug("updateStorageLimit modify enable: \(storageLimit.enable) limit: \(storageLimit.limit) isAdmin: \(storageLimit.isAdmin)")
                Store.settingData.updateCurrentSettings(.storageLimitNotify(storageLimit))
            }).disposed(by: disposeBag)
            return
        }
        storageLimit.enable = false
        MailLogger.debug("updateStorageLimit modify enable: \(storageLimit.enable) limit: \(storageLimit.limit) isAdmin: \(storageLimit.isAdmin)")
        Store.settingData.updateCurrentSettings(.storageLimitNotify(storageLimit))
    }

    func didClickPreviewCard() {
//        exitMultiSelect()
        delegate?.headerNeddExitMultiSelect()
        if currentLabelId == Mail_LabelId_Important {
            delegate?.changeLabel(auto: true, labelID: Mail_LabelId_Other, title: BundleI18n.MailSDK.Mail_SmartInbox_Others, isSystemLabel: true)
//            autoChangeLabel(Mail_LabelId_Other, title: BundleI18n.MailSDK.Mail_SmartInbox_Others, isSystemLabel: true)
            MailTracker.log(event: Homeric.EMAIL_SMARTINBOX_PREVIEW_CLICK, params: ["current": "important"])
        } else if currentLabelId == Mail_LabelId_Other {
            delegate?.changeLabel(auto: true, labelID: Mail_LabelId_Important, title: BundleI18n.MailSDK.Mail_SmartInbox_Important, isSystemLabel: true)
//            autoChangeLabel(Mail_LabelId_Important, title: BundleI18n.MailSDK.Mail_SmartInbox_Important, isSystemLabel: true)
            MailTracker.log(event: Homeric.EMAIL_SMARTINBOX_PREVIEW_CLICK, params: ["current": "other"])
        } else {
            // RoundedHUD.showTips(with: "didClickPreviewCard")
        }
    }

    func closePreviewCard() {
        delegate?.updateTableViewHeader(with: tableHeaderView.dismissSmartInboxPreviewCard())
        if currentLabelId == Mail_LabelId_Important {
            updateLastVisitOtherLabelTimestamp()
        } else if currentLabelId == Mail_LabelId_Other {
            updateLastVisitImportantLabelTimestamp()
        } else {

        }
    }

    func updateLastVisitImportantLabelTimestamp() {
        let nowTimestamp = Int64(Date().milliTimestamp) ?? 0
        Store.settingData.updateCurrentSettings(.lastVisitImportantLabelTimestamp(nowTimestamp))
    }

    func updateLastVisitOtherLabelTimestamp() {
        let nowTimestamp = Int64(Date().milliTimestamp) ?? 0
        Store.settingData.updateCurrentSettings(.lastVisitOtherLabelTimestamp(nowTimestamp))
    }

    func didClickedSettingButton() {
        guard let accountContext = delegate?.headerCurrentAccountContext(headerManager: self) else { return }
        let oooSettingVC = MailOOOSettingViewController(
            accountContext: accountContext,
            viewModel: MailSettingViewModel(accountContext: accountContext),
            source: .banner,
            accountId: currentAccount?.mailAccountID ?? ""
        )
        let nav = LkNavigationController(rootViewController: oooSettingVC)
        nav.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen
        delegate?.navigatorFromHome(nav, present: true)
    }

    // --------
    func didClickMailMigrationStateDetails(type: MailMigrationStateTipsView.MigrationType) {
        switch type {
        case .api:
            /// show migration inprogress detail alert
            let alert = LarkAlertController()
            let text = BundleI18n.MailSDK.Mail_Migration_ProgressToolTip
            alert.setContent(text: text, alignment: .center)
            alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_Alert_OK, dismissCompletion: { })
            delegate?.navigatorFromHome(alert, present: true)
        case .imap:
            delegate?.didClickMailMigrationStateDetails(type: type)
        }
       
    }

    func dismissMailMigrationStateTips(type: MailMigrationStateTipsView.MigrationType) {
        switch type {
        case .api:
            tableHeaderView = tableHeaderView.dismissMailSyncTips()
            delegate?.updateTableViewHeader(with: tableHeaderView)
            MailHomeController.logger.debug( "migration dismiss tips view")
        case .imap:
            delegate?.dismissMailMigrationStateTips(type: type)
        }
    }
    
    func didClickDismissMailMigrationStateTips(type: MailMigrationStateTipsView.MigrationType) {
        switch type {
        case .api:
            dismissMailMigrationStateTips(type: type)
            setStatusIsMigrationDonePromptRendered()
        case .imap:
            delegate?.didClickDismissMailMigrationStateTips(type: type)
        }
        
    }

    // --------
    func didClickDismissOutboxTips() {
        /// 点击dismiss后，记录到UserDefaults中
        dismissOutboxTips()
        let accountID = Store.settingData.getCachedCurrentAccount()?.mailAccountID ?? ""
        let kvStore = MailKVStore(space: .user(id: userContext.user.userID), mSpace: .account(id: accountID))
        kvStore.set(true, forKey: UserDefaultKeys.dismissMillOutboxTip)
        NewCoreEvent.outboxBannerClick(isClosed: true)
    }

    /// 切换到outbox
    func didClickOutboxTips() {
        dismissOutboxTips()
        delegate?.headerNeddExitMultiSelect()
        delegate?.changeLabel(auto: false, labelID: Mail_LabelId_Outbox, title: BundleI18n.MailSDK.Mail_Outbox_OutboxMobile, isSystemLabel: true)
        NewCoreEvent.outboxBannerClick(isClosed: false)
//        didSelectedLabel(Mail_LabelId_Outbox, title: BundleI18n.MailSDK.Mail_Outbox_Outbox, isSystemLabel: true)
    }

    func dismissOutboxTips() {
        tableHeaderView = tableHeaderView.dismissOutboxTips()
        delegate?.updateTableViewHeader(with: tableHeaderView)
        MailHomeController.logger.debug( "dismiss outbox tips view")
    }

    // Stranger
    func showStrangerCardListView(_ viewModel: MailThreadListViewModel) {
        guard !viewModel.mailThreads.isEmpty else { return }
        tableHeaderView = tableHeaderView.showStrangerCardListView(viewModel)
        delegate?.updateTableViewHeader(with: tableHeaderView)
    }

    func dismissStrangerCardListView() {
        tableHeaderView = tableHeaderView.dismissStrangerCardListView()
        delegate?.updateTableViewHeader(with: tableHeaderView)
    }

    func moreActionHandler(sender: UIControl) {
        delegate?.strangerCardListMoreActionHandler(sender: sender)
    }

    func cardItemHandler(index: Int, threadID: String) {
        guard !(tableHeaderView.strangerCardListView?.selectedThreadID == nil ||
                tableHeaderView.strangerCardListView?.selectedThreadID != threadID) else { return }
        delegate?.strangerCardListItemHandler(index: index, threadID: threadID)
    }

    func moreCardItemHandler() {
        delegate?.strangerCardListMoreCardItemHandler()
    }

    func didClickStrangerReply(_ cell: MailStrangerThreadCell, cellModel: MailThreadListCellViewModel, status: Bool) {
        delegate?.strangerCardCellDidClickReply(cell, cellModel: cellModel, status: status)
    }

    func loadMoreIfNeeded() {}
}
