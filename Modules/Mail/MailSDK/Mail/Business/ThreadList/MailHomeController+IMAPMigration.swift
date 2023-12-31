//
//  MailHomeController+IMAPMigration.swift
//  MailSDK
//
//  Created by ByteDance on 2023/9/26.
//

import Foundation
import RustPB
import UniverseDesignDialog
import EENavigator
import LarkAlertController
import LarkGuideUI

extension MailHomeController {
    func handleMigrationStateChange(state: Email_Client_V1_IMAPMigrationState) {
        guard userContext.featureManager.open(.imapMigration, openInMailClient: false) else {
            MailLogger.info("[mail_client] [imap_migration] featuregate disable")
            return
        }
        guard let account = viewModel.currentAccount else {
            MailLogger.error("[mail_client] [imap_migration] account not found")
            return
        }
        let isShareAccount = account.isShared
        let onboardStatus = account.mailSetting.mailOnboardStatus
        let provider = IMAPMigrationProvider(rawValue: state.imapProvider) ?? .other
        MailLogger.info("[mail_client] [imap_migration] migrate status \(state.status), onboardStatus \(onboardStatus), messageID: \(state.reportMessageID), isShared: \(isShareAccount)")
        switch state.status {
        case .init_:
            if onboardStatus == .forceInput || onboardStatus == .smtpActive {
                // 移除上一次搬家记录
                userContext.userKVStore.removeValue(forKey: MailHomeViewModel.IMAPMigrationStoreKey.bannerCloseKey(accountID: account.mailAccountID)) // 记录用户点击关闭banner
                userContext.userKVStore.removeValue(forKey: MailHomeViewModel.IMAPMigrationStoreKey.migrationInCompleteKey(accountID: account.mailAccountID)) // 记录弹窗邮件不全弹窗
                self.showIMAPMigrationAuthFlow(show: true, state: state, isCancelable: isShareAccount, provider: provider)
            } else {
                self.showIMAPMigrationAuthFlow(show: false, state: state, isCancelable: false, provider: provider)
            }
        case .migrating, .syncUid, .pause, .done, .none:
            self.showIMAPMigrationAuthFlow(show: false, state: state, isCancelable: false, provider: provider)
            self.updateMigrationProgress(state: state)
            self.updateDetailAlertIfNeed(state: state)
            if state.status == .pause {
                showPauseAlertIfNeed()
            } else {
                // 移除暂停搬家弹窗状态，重新暂停搬家能再次展示暂停弹窗提示
                userContext.userKVStore.removeValue(forKey: MailHomeViewModel.IMAPMigrationStoreKey.migrationPauseAlertKey(accountID: account.mailAccountID))
            }
            if state.status == .syncUid || state.status == .done {
                let provider = IMAPMigrationProvider(rawValue: state.imapProvider) ?? .other
                showMigrationInCompleteTipsIfNeed(provider: provider)
            }
        case .block:
            self.updateMigrationProgress(state: state)
        case .authOut:
            MailLogger.info("[mail_client] [imap_migration] do nothing authOut")
            
        @unknown default:
            MailLogger.error("[mail_client] [imap_migration] unknown status \(state.status)")
        }
    }
    
    private func updateMigrationProgress(state: Email_Client_V1_IMAPMigrationState) {
        guard let accountID = viewModel.currentAccount?.mailAccountID else {
            MailLogger.info("[mail_client] [imap_migration] migration no account")
            return
        }
        let isClosed = userContext.userKVStore.bool(forKey: MailHomeViewModel.IMAPMigrationStoreKey.bannerCloseKey(accountID: accountID))
        if !(state.status == .done && isClosed) {
            headerViewManager.refreshIMAPMigration(state: state)
        } else {
            MailLogger.info("[mail_client] [imap_migration] migration done and is closed, don't show again \(state.migrationIDString)")
        }
    }
    
    private func showMigrationSetting(state: Email_Client_V1_IMAPMigrationState, isCancelable: Bool, provider: IMAPMigrationProvider) {
        MailLogger.info("[mail_client] [imap_migration] show setting")
        guard let account = viewModel.currentAccount else {
            MailLogger.error("[mail_client] [imap_migration] account is nil")
            return
        }
        if let vc = self.migrationSettingPage {
            if vc.parent == nil {
                MailTracker.log(event: "email_mail_mig_setting_view",
                                params: ["mail_service": provider.rawValue,
                                         "mail_account_type": Store.settingData.getMailAccountType()])
                self.displayContentController(vc)
            }
        } else {
            MailTracker.log(event: "email_mail_mig_setting_view",
                            params: ["mail_service": provider.rawValue,
                                     "mail_account_type": Store.settingData.getMailAccountType()])
            let accountContext = self.userContext.getCurrentAccountContext()
            let vc = MailIMAPMigrationSettingController(state: state, accountContext: accountContext, account: account, cancelAble: isCancelable)
            vc.gotoNext = { [weak self] info in
                self?.setupNextStepMigrationAuth(migrationInfo: info)
            }
            vc.cancelBlock = { [weak self] _ in
                self?.cancelAuth()
            }
            self.displayContentController(vc)
            self.migrationSettingPage = vc
        }
    }
    
    func showIMAPMigrationAuth(state: Email_Client_V1_IMAPMigrationState, isCancelable: Bool, provider: IMAPMigrationProvider) {
        if let vc = self.migrationAuthPage {
            if vc.parent == nil {
                MailTracker.log(event: "email_mail_mig_account_view",
                                params: ["mail_service": provider.rawValue,
                                         "mail_account_type": Store.settingData.getMailAccountType()])
                self.displayContentController(vc)
            }
        } else {
            MailTracker.log(event: "email_mail_mig_account_view",
                            params: ["mail_service": provider.rawValue,
                                     "mail_account_type": Store.settingData.getMailAccountType()])
            let provider = IMAPMigrationProvider(rawValue: state.imapProvider) ?? .other
            let accountContext = self.userContext.getCurrentAccountContext()
            let migrationInfo = MailIMAPMigrationInfo(provider: provider, authType: state.authType, migrationID: state.migrationID)
            let vc = MailIMAPMigrationAuthController(migrationInfo: migrationInfo, accountContext: accountContext, cancelAble: isCancelable)
            vc.cancelBlock = { [weak self] curVC in
                guard let self = self else { return }
                self.cancelAuth()
            }
            displayContentController(vc)
            self.migrationAuthPage = vc
        }
    }
    
    func showIMAPMigrationAuthFlow(show: Bool, state: Email_Client_V1_IMAPMigrationState, isCancelable: Bool, provider: IMAPMigrationProvider) {
        MailLogger.info("[mail_client] [imap_migration] show auth flow \(show)")
        if show {
            let provider = IMAPMigrationProvider(rawValue: state.imapProvider) ?? .other
            switch provider {
            case .exmail, .qiye163:
                if userContext.featureManager.open(.imapMigrationShowSettingView, openInMailClient: false) {
                    showMigrationSetting(state: state, isCancelable: isCancelable, provider: provider)
                } else {
                    showIMAPMigrationAuth(state: state, isCancelable: isCancelable, provider: provider)
                }
            case .alimail, .office365, .internationO365, .chineseO365, .exchange, .gmail, .zoho, .other:
                showIMAPMigrationAuth(state: state, isCancelable: isCancelable, provider: provider)
            }
        } else {
            removeIMAPAuthFlow()
        }
        showLarkNavbar = !show
        multiAccountView.isHidden = show
        sendMailButton.isHidden = show
    }
    
    func removeIMAPAuthFlow() {
        MailLogger.info("[mail_client] [imap_migration] remove imap auth flow")
        if let vc = self.migrationSettingPage {
            self.hideContentController(vc)
            self.migrationSettingPage = nil
        }
        if let vc = self.migrationAuthPage {
            if let currentGuideVC = vc.currentGuideVC {
                currentGuideVC.dismiss(animated: false)
            }
            self.hideContentController(vc)
            self.migrationAuthPage = nil
        }
    }
    
    private func cancelAuth() {
        self.removeIMAPAuthFlow()
        showLarkNavbar = true
        multiAccountView.isHidden = false
        sendMailButton.isHidden = false
        if let nextAccount = Store.settingData.getCachedPrimaryAccount() {
            // 取消公共账号搬家，切回主账号
            self.viewModel.switchAccount(nextAccount.mailAccountID)
        }
        Store.settingData.acceptCurrentAccountChange()
    }

    private func updateDetailAlertIfNeed(state: Email_Client_V1_IMAPMigrationState) {
        guard let alert = migrationDetailAlert else { return }
        if state.status  == .migrating || state.status == .syncUid {
            let content = BundleI18n.MailSDK.Mail_EmailMigration_Mobile_MigrationInProgress_DetailsPopUp_Desc("\(state.finishedMessageCount)/\(state.totalMessageCount)")
            alert.setContent(text: content)
        }
    }
    // show pause alert
    private func showPauseAlertIfNeed() {
        guard self.isShowing else {
            MailLogger.info("[mail_client] [imap_migration] homevc is not showing")
            return
        }
        guard let address = viewModel.currentAccount?.accountAddress,
                let accountID = viewModel.currentAccount?.mailAccountID else {
            MailLogger.error("[mail_client] [imap_migration] no account")
            return
        }
        guard !userContext.userKVStore.bool(forKey: MailHomeViewModel.IMAPMigrationStoreKey.migrationPauseAlertKey(accountID: accountID)) else {
            MailLogger.info("[mail_client] [imap_migration] pause alert has showed")
            return
        }
        userContext.userKVStore.set(true, forKey: MailHomeViewModel.IMAPMigrationStoreKey.migrationPauseAlertKey(accountID: accountID))
        MailTracker.log(event: "email_mail_mig_error_window_view",
                        params: ["mail_service": viewModel.migrationState?.imapProvider ?? "other",
                                 "mail_account_type": Store.settingData.getMailAccountType(),
                                 "window_type": "admin_pause"])
        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.MailSDK.Mail_EmailMigration_Mobile_MigrationPausedPopUp_Title)
        dialog.setContent(text: BundleI18n.MailSDK.Mail_EmailMigration_Mobile_MigrationPausedPopUp_Desc(address))
        dialog.addPrimaryButton(text: BundleI18n.MailSDK.Mail_EmailMigration_Mobile_MigrationPausedPopUp_GotIt_Button, dismissCompletion:  {[weak self] in
            MailTracker.log(event: "email_mail_mig_error_window_click",
                            params: ["mail_service": self?.viewModel.migrationState?.imapProvider ?? "other",
                                     "mail_account_type": Store.settingData.getMailAccountType(),
                                     "window_type": "data_limit",
                                     "click": "i_know"])
        })
        self.userContext.navigator.present(dialog, from: self)
    }
    // show migration detail alert
    private func showDetailAlert() {
        let total = viewModel.migrationState?.totalMessageCount ?? 0
        let finished = viewModel.migrationState?.finishedMessageCount ?? 0
        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.MailSDK.Mail_EmailMigration_Mobile_MigrationInProgress_DetailsPopUp_Title)
        dialog.setContent(text: BundleI18n.MailSDK.Mail_EmailMigration_Mobile_MigrationInProgress_DetailsPopUp_Desc("\(finished)/\(total)"))
        dialog.addPrimaryButton(text: BundleI18n.MailSDK.Mail_EmailMigration_Mobile_MigrationInProgress_DetailsPopUp_DGotItButton, dismissCompletion: {[weak self] in
            self?.migrationDetailAlert = nil
        })
        self.migrationDetailAlert = dialog
        self.userContext.navigator.present(dialog, from: self)

    }
    
    // 下一步，鉴权
    private func setupNextStepMigrationAuth(migrationInfo: MailIMAPMigrationInfo) {
        MailTracker.log(event: "email_mail_mig_account_view",
                        params: ["mail_service": migrationInfo.provider.rawValue,
                                 "mail_account_type": Store.settingData.getMailAccountType()])
        let accountContext = self.userContext.getCurrentAccountContext()
        let vc = MailIMAPMigrationAuthController(migrationInfo: migrationInfo, accountContext: accountContext, cancelAble: false)
        vc.preStepBlock = { [weak self] curVC in
            guard let self = self else { return }
            guard let preVC = self.migrationSettingPage else {
                MailLogger.error("[mail_client] [imap_migration] preStep not found")
                return
            }
            MailLogger.info("[mail_client] [imap_migration] settup preVC")
            self.hideContentController(vc)
            self.displayContentController(preVC)
            self.migrationAuthPage = nil
        }

        if let migrationAuthPage = self.migrationAuthPage {
            self.hideContentController(migrationAuthPage)
            self.migrationAuthPage = nil
        }
        self.displayContentController(vc)
        self.migrationAuthPage = vc
    }
    
    private func showMigrationInCompleteTipsIfNeed(provider: IMAPMigrationProvider) {
        guard let accountID = viewModel.currentAccount?.mailAccountID else {
            MailLogger.info("[mail_client] [imap_migration] migration no account")
            return
        }
        let thirtyDays = 30
        let showMigrationPartialKey = MailHomeViewModel.IMAPMigrationStoreKey.migrationInCompleteKey(accountID: accountID)
        guard provider == .exmail || provider == .qiye163 else {
            MailLogger.info("[mail_client] [imap_migration] provider \(provider) not need to check in complete migration")
            return
        }
        guard !userContext.userKVStore.bool(forKey: showMigrationPartialKey) else {
            MailLogger.info("[mail_client] [imap_migration] did check migration partial")
            return
        }
        userContext.sharedServices.dataService.getOldestMessage().subscribe(onNext: {[weak self] resp in
            guard let self = self, resp.status == .ready else { return }
            guard self.daysFromNow(timestamp: resp.sendTimestamp) <= thirtyDays else {
                MailLogger.info("[mail_client] [imap_migration] oldest message is more than 30 days ago")
                self.userContext.userKVStore.set(true, forKey: showMigrationPartialKey)
                return
            }
            self.showImapMigrationAlert(from: self, service: provider.info.0, pageType: provider.rawValue)
            self.userContext.userKVStore.set(true, forKey: showMigrationPartialKey)
        }, onError: { error in
            MailLogger.error("[mail_client] [imap_migration] get oldest message error", error: error)
        }).disposed(by: disposeBag)
    }
    
    private func daysFromNow(timestamp: Int64) -> Int {
        let now = Date()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        let anotherDate = calendar.startOfDay(for: Date(timeIntervalSince1970: TimeInterval(timestamp / 1000)))
        let components = calendar.dateComponents([.day], from: today, to: anotherDate)
        return components.day ?? 0
    }
    
    func showImapMigrationAlert(from: NavigatorFrom, service: String, pageType: String) {
        MailTracker.log(event: "email_mail_mig_error_window_view",
                        params: ["mail_service": pageType,
                                 "mail_account_type": Store.settingData.getMailAccountType(),
                                 "window_type": "data_limit"])

        let alert = LarkAlertController()
        alert.setTitle(text: BundleI18n.MailSDK.Mail_EmailMigration_Mobile_PartlyMigratedPopUp_Title)
        let contentView = MailStepAlertContentView(dataSource: imapMigrationTipsDataSource(service: service, pageType: pageType))
        contentView.pagetType = pageType
        alert.setContent(view: contentView)
        alert.addSecondaryButton(text: BundleI18n.MailSDK.Mail_EmailMigration_Mobile_PartlyMigratedPopUp_GotIt_Button, dismissCompletion:  {
            MailTracker.log(event: "email_mail_mig_error_window_click",
                            params: ["mail_service": pageType,
                                     "mail_account_type": Store.settingData.getMailAccountType(),
                                     "window_type": "data_limit",
                                     "click": "i_know"])
        })
        alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_EmailMigration_Mobile_PartlyMigratedPopUp_LearnHow_Button, dismissCheck: {
            [weak self] in
               MailTracker.log(event: "email_mail_mig_error_window_click",
                               params: ["mail_service": pageType,
                                        "mail_account_type": Store.settingData.getMailAccountType(),
                                        "window_type": "data_limit",
                                        "click": "more_info"])
               guard let localLink = self?.serviceProvider?.provider.settingConfig?.linkConfig?.migrationInComplete.localLink else {
                   MailLogger.info("no link config")
                   return false
               }
               guard let url = URL(string: localLink) else {
                   MailLogger.info("initialize url failed")
                   return false
               }
               UIApplication.shared.open(url)
            return false
        })
        self.userContext.navigator.present(alert, from: from)
    }
    
    private func imapMigrationTipsDataSource(service: String, pageType: String) -> MailStepAlertContent {
        let steps: [MailStepAlertContent.AlertStep] = [(content: BundleI18n.MailSDK.Mail_EmailMigration_Mobile_PartlyMigratedPopUp_CheckSettings1(service),
                                                        actionText: nil,
                                                        action: nil),
                                                       (content: BundleI18n.MailSDK.Mail_EmailMigration_Mobile_PartlyMigratedPopUp_CheckSettings2(),
                                                        actionText: nil,
                                                        action: nil)]
        return MailStepAlertContent(title: BundleI18n.MailSDK.Mail_EmailMigration_Mobile_PartlyMigratedPopUp_Desc, steps: steps)
    }
}

// MARK: banner tips delegate
extension MailHomeController: MailMigrationStateTipsViewDelegate {
    func dismissMailMigrationStateTips(type: MailMigrationStateTipsView.MigrationType) { }
    
    func didClickMailMigrationStateDetails(type: MailMigrationStateTipsView.MigrationType) {
        guard type == .imap, let state = viewModel.migrationState else { return }
        let provider = IMAPMigrationProvider(rawValue: state.imapProvider) ?? .other
        switch state.status {
        case .migrating, .syncUid:
            showDetailAlert()
        case .done:
            if !state.reportMessageID.isEmpty {
                openMigrationReport(messageID: state.reportMessageID)
            } else {
                MailLogger.error("[mail_client] [imap_migration] invalid messageID")
            }
        case .block:
            if state.blockReason == .authFail {
                MailLogger.info("[mail_client] [imap_migration] show auth failed")
                showIMAPMigrationAuthFlow(show: true, state: state, isCancelable: true, provider: provider)
            } else {
                MailLogger.info("[mail_client] [imap_migration] do nothing")
            }
        case .authOut, .pause, .init_, .none:
            MailLogger.info("[mail_client] [imap_migration] do nothing")
        @unknown default:
            MailLogger.error("[mail_client] [imap_migration] unknown status \(state.status)")
        }
    }
    func didClickDismissMailMigrationStateTips(type: MailMigrationStateTipsView.MigrationType) {
        guard let accountID = viewModel.currentAccount?.mailAccountID else {
            MailLogger.info("[mail_client] [imap_migration] migration no account")
            return
        }
        guard type == .imap, let state = viewModel.migrationState else { return }
        let provider = IMAPMigrationProvider(rawValue: state.imapProvider) ?? .other
        MailTracker.log(event: "email_mail_mig_banner_click",
                        params: ["mail_service": provider.rawValue,
                                 "mail_account_type": Store.settingData.getMailAccountType(),
                                 "banner_type": "finish",
                                 "click": "close"])
        headerViewManager.dismissIMAPMigrationHeader()
        userContext.userKVStore.set(true, forKey: MailHomeViewModel.IMAPMigrationStoreKey.bannerCloseKey(accountID: accountID))
    }
    
    private func openMigrationReport(messageID: String) {
        userContext.sharedServices.dataService.getMessageSuitableInfo(messageId: messageID, threadId: messageID, scene: .readMessage)
            .subscribe(onNext: {[weak self] (resp) in
                guard let self = self else { return }
                let labelID = resp.label
                self.gotoMessageList(threadID: messageID, messageID: messageID, labelID: labelID)
            }, onError: {[weak self] error in
                guard let self = self else { return }
                MailLogger.error("[mail_client] [imap_migration] open migration report error", error: error)
                self.gotoMessageList(threadID: messageID, messageID: messageID, labelID: Mail_LabelId_Inbox)
            }).disposed(by: disposeBag)
    }
    
    private func gotoMessageList(threadID: String, messageID: String, labelID: String) {
        Store.sharedContext.value.markEnterThreadId = threadID
        markSelectedThreadId = threadID
        let vc = MailMessageListController.makeForRouter(accountContext: self.userContext.getCurrentAccountContext(),
                                                         threadId: messageID,
                                                         labelId: labelID,
                                                         messageId: messageID,
                                                         statInfo: MessageListStatInfo(from: .other, newCoreEventLabelItem: labelID),
                                                         forwardInfo: nil)
        vc.backCallback = { [weak self] in
            guard let self = self, Display.pad else { return }
            self.markSelectedThreadId = nil
            MailMessageListViewsPool.reset()
        }
        if Display.pad {
            self.userContext.navigator.showDetail(vc, wrap: MailMessageListNavigationController.self, from: self)
        } else {
            self.userContext.navigator.push(vc, from: self)
        }
    }
}

// MARK: Migration Onboarding
extension MailHomeController {
    func showMigrationGuideIfNeed(migrationsIDs: Set<String>) {
        if !isShowing
            || multiAccountView.isHidden
            || multiAccountView.frame == .zero
            || isShowingMigrationOnboard
            || self.presentedViewController != nil {
            MailLogger.info("[mail_client] [imap_migration] homeView notshow or multiAccountView is hidden")
            return
        }
        self.isShowingMigrationOnboard = true
        MailLogger.info("[mail_client] [imap_migration] migraion guide show")
        let textConfig = TextInfoConfig(detail: BundleI18n.MailSDK.Mail_EmailMigration_Mobile_PublicMailboxMigrationEnabled_Onboarding_Desc)
        let anchor = TargetAnchor(targetSourceType: .targetView(multiAccountView.arrowImageView))
        let maskConfig = MaskConfig(shadowAlpha: 0, windowBackgroundColor: .clear, maskInteractionForceOpen: false)
        let bottomConfig = BottomConfig(rightBtnInfo: ButtonInfo(title: BundleI18n.MailSDK.Mail_EmailMigration_Mobile_PublicMailboxMigrationEnabled_Onboarding_GotItButton, buttonType: .finished))
        let bubbleConfig = BubbleItemConfig(guideAnchor: anchor,
                                            textConfig: textConfig,
                                            bottomConfig: bottomConfig)
        let singleConfig = SingleBubbleConfig(delegate: self,bubbleConfig: bubbleConfig, maskConfig: maskConfig)
        GuideUITool.displayBubble(hostProvider: self, bubbleType: BubbleType.single(singleConfig), dismissHandler: { [weak self] in
            MailLogger.info("[mail_client] [imap_migration] migrate status onboard dismiss")
            self?.isShowingMigrationOnboard = false
        })
        viewModel.didShowMigrationOnboard(migrationsIDs: migrationsIDs)
    }
}
