//
//  MailHomeController+SharedAccount.swift
//  MailSDK
//
//  Created by majx on 2020/6/17.
//

import Foundation
import EENavigator
import LarkSceneManager
import RxSwift

extension MailHomeController {
    func mailAccountInfosChange() {
        let showBadge = Store.settingData.getOtherAccountUnreadBadge()
        MailLogger.debug("mail show other account unread badge \(showBadge.count) isRed: \(showBadge.isRed)")
        multiAccountView.update(showBadge: showBadge.count > 0, isRed: showBadge.isRed)
        guard let curAcc = Store.settingData.getCachedCurrentAccount() else { return }
        let status = Store.settingData.getAccountInfos().first(where: { $0.accountId == curAcc.mailAccountID } )?.status
        if status == .expired {
            MailLogger.debug("[mail_client] mail setting manager curr status: \(status)")
            headerViewManager.showExpiredTips()
        } else {
            headerViewManager.dismissExpiredTips()
        }
        if curAcc.provider.isTokenLogin() && curAcc.loginPassType == .token {
            headerViewManager.dismissPassLoginExpiredTips()
        }
    }

    func mailAccountListChange() {
        self.accountListMenu?.dismissMenu()
        self.dismissMultiAccount()
        Store.settingData.getAccountList(fetchDb: true)
        .subscribe(onNext: { [weak self](resp) in
            guard let `self` = self else { return }
            let currentAccountId = resp.currentAccountId
            self.viewModel.refreshCurrentAccCache(currentAccountId: currentAccountId, accountList: resp.accountList)
        }).disposed(by: disposeBag)
    }

    func mailAccountChange(_ change: MailAccountChange) {
        MailLogger.debug("[free_bind] mail AccountChange")
        asyncRunInMainThread {
            self.accountListMenu?.dismissMenu()
            self.labelsMenuController?.dismissMenu()
            self.status = .none
            let userType = change.account.mailSetting.userType
            if self.userContext.featureManager.realTimeOpen(.newFreeBindMail, openInMailClient: false) {
                if userType == .newUser {
                    self.displayDelegate?.switchContent(inHome: false, insert: false, initData: true)
                } else {
                    self.refreshAuthPageIfNeeded(change.account.mailSetting)
                }
            }
        }
    }

    func mailCurrentAccountChange() {
        MailLogger.debug("[mail_client] mail shared mailCurrentAccountChange")
        asyncRunInMainThread {
            self.accountListMenu?.dismissMenu()
            self.status = .none
            self.viewModel.refreshAccountList(onCompleted: { [weak self] in
                self?.reloadThreadData(resetLabel: true)
            })
        }
    }

    // mail shared account change
    func mailSharedAccountChange(_ change: MailSharedAccountChange) {
        dealSharedAccountChange(change: change)
        exitMultiSelect()
    }

    func mailDidShowSharedAccountAlert(_ notification: Notification) {
        self.viewModel.lastSharedAccountChange = nil
    }

    func dealSharedAccountChange(change: MailSharedAccountChange) {
        if change.fetchAccountList { // 为ture时无需弹框，所以无需缓存
            viewModel.lastSharedAccountChange = change
        }
        let currentAccountId = viewModel.currentAccount?.mailAccountID
        let accountId = change.account.mailAccountID
        let name = change.account.accountName
        let address = change.account.accountAddress
        let isBind = change.isBind
        let needReloadAccountList = change.fetchAccountList

        MailLogger.info("[mail_home_init] shared account change accountId:\(accountId) currentAccountId:\(currentAccountId) isBind:\(isBind) needReloadAccountList:\(needReloadAccountList)")
        if isShowing, !accountId.isEmpty, change.account.isShared, change.account.mailSetting.userType != .tripartiteClient {
            viewModel.lastSharedAccountChange = nil
            self.alertHelper?.showSharedAccountAlert(changes: [change], in: self) { [weak self] in
                /// onboarding
                if isBind && needReloadAccountList &&
                    change.account.isShared && change.account.mailSetting.userType != .tripartiteClient {
                    self?.showMultiAccountOnboardingIfNeeded()
                }
            }
        }

        if needReloadAccountList {
            if let curAcc = Store.settingData.getCachedCurrentAccount(), curAcc.isValid() {
                // 未成功赋值account id的情况，需要重新出发拉列表数据
                viewModel.refreshAccountList(onCompleted: { [weak self] in
                    self?.viewModel.startedFetchSetting = false
                    self?.viewModel.$uiElementChange.accept(.refreshHeaderBizInfo)
                })
            } else {
                viewModel.refreshAccountList(onCompleted: { [weak self] in
                    self?.viewModel.startedFetchSetting = false
                    self?.viewModel.firstFetchListData()
                    self?.viewModel.$uiElementChange.accept(.refreshHeaderBizInfo)
                })
            }
        }

        guard !accountId.isEmpty else { return }

        /// if revoke current account, need switch to main account (rust switch)
        let unbindCurrentAccount = (accountId == currentAccountId && !isBind)
        if unbindCurrentAccount {
            if Store.settingData.clientStatus == .mailClient {
                if let nextAccount = Store.settingData.getCachedAccountList()?.first(where: { $0.mailAccountID != currentAccountId && $0.isShared }) {
                    /// refresh account list
                    //  切一下账号吧
                    viewModel.switchAccount(nextAccount.mailAccountID)
                } else {
                    displayDelegate?.switchContent(inHome: false, insert: false, initData: false)
                    let kvStore = userContext.userKVStore
                    kvStore.set(true, forKey: "MailClient_ShowLoginPage_\(userContext.user.tenantID)")
                }
                enterThread(with: nil)
            } else {
                if let nextAccount = Store.settingData.getCachedPrimaryAccount() {
                    //  当前公共账号被删除，切换回主账号
                    viewModel.switchAccount(nextAccount.mailAccountID)
                }
                Store.settingData.acceptCurrentAccountChange()
            }
        } else {
            /// refresh account list
            status = .none
            viewModel.refreshAccountList { [weak self] in
                if self?.viewModel.hasFirstLoaded ?? false {
                    self?.labelsMenuController?.reloadTableView()
                }
            }
        }
    }

    func switchToLMSAccountInNextLoginIfNeeded() {
        if Store.settingData.clientStatus == .saas && viewModel.currentAccount?.mailSetting.userType == .tripartiteClient {
            guard let primaryAccount = Store.settingData.getCachedPrimaryAccount() else {
                MailLogger.error("[mail_client] saas homevc didAppear primaryAccount is nil")
                return
            }
            Store.settingData.switchMailAccount(to: primaryAccount.mailAccountID).subscribe(onNext: { (_) in
                NotificationCenter.default.post(Notification(name: Notification.Name.Mail.MAIL_SWITCH_ACCOUNT))
                Store.settingData.$permissionChanges.accept((.mailClientRevoke, true))
                Store.settingData.acceptCurrentAccountChange()
             }, onError: { (err) in
                 mailAssertionFailure("[mail_client] coexist MailClientSaasDataCenter [mail_account] err in switch account \(err)")
             }).disposed(by: Store.settingData.disposeBag)
        }

        // 检查标记位 当前主账号为lms/搬家状态，且用户未进入过该页面的需要弹出
        if shouldChecklmsStatus {
            guard let primaryAccount = Store.settingData.getCachedPrimaryAccount() else {
                MailLogger.error("[mail_client] coexist homevc didAppear primaryAccount is nil")
                return
            }
            guard let currentAccount = Store.settingData.getCachedCurrentAccount() else {
                MailLogger.error("[mail_client] coexist homevc didAppear currentAccount is nil")
                Store.settingData.switchToAvailableAccountIfNeeded()
                return
            }
            let primaryAccountID = primaryAccount.mailAccountID
            let currentAccountID = currentAccount.mailAccountID
            guard primaryAccount.mailSetting.userType == .newUser ||
                    (primaryAccount.mailSetting.userType == .larkServer &&
                    primaryAccount.mailSetting.mailOnboardStatus != .forceInput) else {
                return
            }
            let kvStore = userContext.userKVStore
            if kvStore.value(forKey: "mail_client_have_displayed_lms_\(primaryAccountID)") ?? false {
                /// 已经自动跳转过lms账号，无需再次处理
                return
            }
            if currentAccountID == primaryAccountID {
                if !kvStore.bool(forKey: "mail_client_have_displayed_lms_\(currentAccountID)") {
                    kvStore.set(true, forKey: "mail_client_have_displayed_lms_\(currentAccountID)")
                }
            } else {
                MailLogger.info("[mail_client] homevc should switch account to lms")
                Store.settingData
                    .switchMailAccount(to: primaryAccountID)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { (_) in
                        NotificationCenter.default.post(Notification(name: Notification.Name.Mail.MAIL_SWITCH_ACCOUNT))
                        MailLogger.info("[mail_client] homevc switch account id \(primaryAccountID)")
                        kvStore.set(true, forKey: "mail_client_have_displayed_lms_\(primaryAccountID)")
                    },onError: { (error) in
                        MailLogger.error("[mail_client] homevc switch error account id \(primaryAccountID)")
                    }).disposed(by: disposeBag)
            }
        } else {
            shouldChecklmsStatus = true
        }
    }

    func showAccountDropMenu() {
        // 刷新公共邮箱搬家状态，显示待搬家
        viewModel.getImapMigrationState()
        // if showing refresh animation, can't show acccount dropMenu
        if header.showingRefreshAnimation {
            return
        }
        guard let titleView = self.getLarkNavbar()?.getTitleTappedSourceView() else {
            return
        }
        if self.accountListMenu == nil {
            self.accountListMenu = MailAccountListController(userContext: userContext)
            self.accountListMenu?.delegate = self
        }
        guard accountListMenu?.isBeingPresented == false else { return }
        guard self.presentedViewController == nil else { return }
        if rootSizeClassIsSystemRegular {
            self.accountListMenu?.modalPresentationStyle = .popover
            self.accountListMenu?.popoverPresentationController?.backgroundColor = UIColor.ud.bgBase
            self.accountListMenu?.popoverPresentationController?.sourceView = multiAccountView
            self.accountListMenu?.popoverPresentationController?.sourceRect = multiAccountView.bounds.insetBy(dx: 0, dy: 8)
            self.accountListMenu?.popoverPresentationController?.permittedArrowDirections = .up
            self.accountListMenu?.topMargin = naviHeight + statusHeight
            self.accountListMenu?.preferredContentSize = CGSize(width: self.view.bounds.size.width, height: 0)

        } else {
            self.accountListMenu?.topMargin = naviHeight + statusHeight
            self.accountListMenu?.modalPresentationStyle = .overFullScreen
        }
        if let menu = self.accountListMenu {
            navigator?.present(menu, from: self)
        }
    }

    func dismissAccountDropMenu() {
        self.accountListMenu?.dismissMenu()
    }
}

extension MailHomeController: MailMultiAccountViewDelegate {
    func didClickMultiAccount() {
        showAccountDropMenu()
//        let vc = MailAccountListController()
//        navigator?.push(vc)
    }

    func didReverifySuccess() {
        DispatchQueue.main.async {
            self.hideOauthPlaceholderPage()
        }
    }
}

extension MailHomeController: MailAccountListControllerDelegate {
    func accountListMenu(_ menu: MailAccountListController, touchesEndedAt location: CGPoint) {
        if let window = self.view.window, let point = navSearchButton.superview?.convert(location, from: window) {
            if navSearchButton.frame.contains(point) {
                DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.short) {
                    self.onSelectSearch()
                }
            }
            if navMoreButton.frame.contains(point) {
                DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.short) {
                    self.showMoreAction()
                }
            }
        }
    }

    func closeAllMailScenes() {
        if #available(iOS 13.0, *) {
            for uiScene in UIApplication.shared.windowApplicationScenes {
                let scene = uiScene.sceneInfo
                if !scene.isMainScene() && scene.key == "Mail" {
                    SceneManager.shared.deactive(scene: scene)
                    MailLogger.info("close Mail assistant scene")
                }
            }
        }
    }

    func didClickSwitchAccount() {
        viewModel.listViewModel.cancelGetThreadList()
        enterThread(with: nil)
    }

    func reloadAcountChangeUI() {
        MailLogger.info("[mail_home_init] [mail_home] reloadAcountChangeUI")
        viewModel.listViewModel.cleanMailThreadCache()
        showMailLoading()
        viewModel.cancelSettingFetch()
        viewModel.listViewModel.cancelGetThreadList()
        rebuildViewModel()
        viewModel.refreshAllListData()
        viewModel.updateUnreadDotAfterFirstScreenLoaded()
        refreshListDataReady.accept((.switchAccount, false))
        // label list
        labelsMenuController = self.makeTagMenu()
        labelsMenuController?.viewModel.selectedID = viewModel.currentLabelId
        // header
        headerViewManager.closeAccountDimensionHeader()
        viewModel.refreshAccountList { [weak self] in
            self?.labelsMenuController?.reloadTableView()
            self?.setInset()
            self?.resetAllRefresh()
            DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.short) {
                self?.srcollToTop(completion: {
                    self?.showMailClientPassLoginExpriedAlertIfNeeded()
                    self?.showClientMigrationTips()
                    self?.showPreloadTaskStatusIfNeeded()
                    self?.showStrangerCardListViewIfNeeded()
                })
            }
        }
    }
}
