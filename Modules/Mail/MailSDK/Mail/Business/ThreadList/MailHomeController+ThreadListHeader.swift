//
//  MailHomeController+ThreadListHeader.swift
//  MailSDK
//
//  Created by tefeng liu on 2022/3/15.
//

import Foundation
import LarkUIKit
import EENavigator
import LKCommonsLogging
import RxSwift
import Homeric
import LarkAlertController
import RustPB
import LarkKeyCommandKit
import LarkFoundation
import RxRelay
import UniverseDesignIcon
import UniverseDesignToast
import LarkSplitViewController

extension MailHomeController: ThreadListHeaderManagerDelegate {
    func headerCurrentLabelId(headerManager: ThreadListHeaderManager) -> String {
        return viewModel.currentLabelId
    }

    func headerCurrentAccount(headerManager: ThreadListHeaderManager) -> MailAccount? {
        return viewModel.currentAccount
    }

    func headerCurrentAccountContext(headerManager: ThreadListHeaderManager) -> MailAccountContext {
        return userContext.getCurrentAccountContext()
    }

    func mailClientReVerfiy() {
        guard let account = Store.settingData.getCachedCurrentAccount() else {
            MailLogger.error("[mail_client_token] getCachedCurrentAccount nil")
            return
        }
        if account.provider.isTokenLogin() {
            mailClientReLink()
        } else {
            if userContext.featureManager.realTimeOpen(.newFreeBindMail, openInMailClient: false) {
                let loginVC = MailClientLoginViewController(type: .other, accountContext: userContext.getAccountContextOrCurrent(accountID: account.mailAccountID), scene: .freeBindInvaild)
                let loginNav = LkNavigationController(rootViewController: loginVC)
                var imapAccount = MailImapAccount(mailAddress: "", password: "", bindType: .reBind)
                if let config = account.mailSetting.emailClientConfigs.first {
                    imapAccount.mailAddress = config.emailAddress
                }
                loginVC.imapAccount = imapAccount
                loginNav.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen
                self.navigator?.present(loginNav, from: self)
            } else {
                let adSettingVC = MailClientAdvanceSettingViewController(scene: .reVerfiy, accountID: account.mailAccountID, accountContext: userContext.getCurrentAccountContext(), isFreeBind: userContext.featureManager.realTimeOpen(.newFreeBindMail, openInMailClient: false))
                let adSettingNav = LkNavigationController(rootViewController: adSettingVC)
                adSettingNav.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen
                navigator?.present(adSettingNav, from: self)
            }
        }
    }
    
    func mailClientReLink() {
        guard let account = Store.settingData.getCachedCurrentAccount() else {
            MailLogger.error("[mail_client_token] getCachedCurrentAccount nil")
            return
        }
        Store.settingData.tokenRelink(provider: account.provider, navigator: userContext.navigator, from: self, accountID: account.mailAccountID, address: account.mailSetting.emailAlias.defaultAddress.address)
    }


    func headerNeddExitMultiSelect() {
        exitMultiSelect()
    }

    func resetTableViewHeader() {
        guard !shouldAdjustPullRefresh else { return }
        if let tempHeaderView = headerViewManager.tempHeaderView {
            updateTableViewHeader(with: tempHeaderView)
        }
        headerViewManager.tempHeaderView = nil
    }

    func updateTableViewHeader(with headerView: MailThreadListHeaderView) {
        if isMultiSelecting || !viewModel.hasFirstLoaded {
            self.headerViewManager.tempHeaderView = headerView
            return
        }
        asyncRunInMainThread {
            self.tableView.viewWidth = self.view.bounds.width
            self.tableView.tableHeaderView = headerView
            if self.viewModel.datasource.isEmpty {
                self.srcollToTop()
            }
        }
    }

    func navigatorFromHome(_ viewController: UIViewController, present: Bool) {
        if present {
            navigator?.present(viewController, from: self)
        } else {
            navigator?.push(viewController, from: self)
        }
    }

    func naviToServiceConsultant() {
        MailStorageLimitHelper.contactServiceConsultant(from: self, navigator: userContext.navigator)
    }

    func exitMultiSelect() {
        if !isMultiSelecting {
            return
        }
        multiAccountView.isHidden = false
        reloadListInMultiSelect(false)
        isMultiSelecting = false
        resetTableViewHeader()
        sendMailButton.isHidden = false
        if !selectedThreadIds.isEmpty {
            selectedThreadIds.removeAll()
        }
        threadActionBar.eraseThreadActions()
        if rootSizeClassIsRegular, let selectedThreadId = markSelectedThreadId,
           let opendedCellRow = viewModel.datasource.firstIndex(where: { $0.threadID == selectedThreadId }) {
            tableView.selectRow(at: IndexPath(row: opendedCellRow, section: 0), animated: true, scrollPosition: .none)
        }
        clearContentsBeforeAsynchronouslyDisplay = true
    }

    func changeLabel(auto: Bool, labelID: String, title: String, isSystemLabel: Bool) {
        autoChangeLabel(labelID, title: title, isSystemLabel: isSystemLabel, updateTimeStamp: auto)
        reloadNavbar()
    }
    
    func trashClearAll() {
        emptyAll()
    }
    
    func showClearTrashAlert() {
        if let setting = Store.settingData.getCachedCurrentSetting(), setting.showRegularCleanMessageOnboard == true {
            if self.viewModel.clearTrashAlert == nil && self.viewModel.updateLabelToTrash {
                self.viewModel.updateLabelToTrash = false
                let alert = LarkAlertController()
                alert.setTitle(text: BundleI18n.MailSDK.Mail_AutoDeletionInSpamTrash_Onboard_Title(self.viewModel.trashAlertDays))
                alert.setContent(text: BundleI18n.MailSDK.Mail_AutoDeletionInSpamTrash_Onboard_Desc(self.viewModel.trashAlertDays), alignment: .center)
                alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_AutoDeletionInSpamTrashGotIt_Onboard_Button, dismissCompletion: { [weak self] in
                    guard let `self` = self else { return }
                    self.viewModel.clearTrashAlert = nil
                    MailDataServiceFactory.commonDataService?.updateCleanMessageStatus().subscribe { [weak self] (resp) in
                        guard let `self` = self else { return }
                        MailLogger.info("updateCleanMessageStatus success")
                    } onError: { (error) in
                        MailLogger.error("updateCleanMessageStatus error=\(error)")
                    }.disposed(by: self.disposeBag)
                })
                self.viewModel.clearTrashAlert = alert
                self.navigator?.present(alert, from: self)
            }
        }
    }

    func preloadCacheTipHandler(showDetail: Bool, dismiss: Bool, preloadProgress: MailPreloadProgressPushChange) {
        if showDetail {
            let cacheSettingVC = MailCacheSettingViewController(viewModel: MailSettingViewModel(accountContext: userContext.getCurrentAccountContext()), accountContext: userContext.getCurrentAccountContext())
            cacheSettingVC.delegate = self
            cacheSettingVC.scene = .home
            let cacheSettingNav = LkNavigationController(rootViewController: cacheSettingVC)
            cacheSettingNav.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen
            navigator?.present(cacheSettingNav, from: self)
            MailTracker.log(event: "email_offline_cache_banner_click",
                            params: ["click": "offline_cache_setting", "label_item": viewModel.currentLabelId, "banner_type": preloadProgress.preloadStatus()])
        }
        if dismiss {
            updateTableViewHeader(with: self.headerViewManager.tableHeaderView.dismissPreloadCacheNotice())
            Store.fetcher?.mailClosePreloadFinishedBanner()
                .subscribe(onNext: { [weak self] _ in
                    guard let `self` = self else { return }
                    MailLogger.info("[mail_cache_preload] mailClosePreloadFinishedBanner success")
            }, onError: { (error) in
                MailLogger.error("[mail_cache_preload] mailClosePreloadFinishedBanner fail", error: error)
            }).disposed(by: self.disposeBag)
            MailTracker.log(event: "email_offline_cache_banner_click",
                            params: ["click": "close_banner", "label_item": viewModel.currentLabelId, "banner_type": preloadProgress.preloadStatus()])
        }
    }

    func strangerCardListMoreActionHandler(sender: UIControl) {
        var headerConfig = MoreActionHeaderConfig(iconType: .image(UDIcon.closeSmallOutlined.withRenderingMode(.alwaysTemplate)),
                                                  title: BundleI18n.MailSDK.Mail_StrangerMail_StrangerEmailsFeaturePopUp_Title,
                                                  subtitle: "")
        headerConfig.stranger = true

        var sections = [MoreActionSection]()
        let allowStrangerItem = MailActionItem(title: BundleI18n.MailSDK.Mail_StrangerInbox_AllowAll_Button,
                                               icon: UDIcon.yesOutlined,
                                               udGroupNumber: 1,
                                               tintColor: UIColor.ud.functionSuccess500,
                                       actionCallBack: { [weak self] _ in
            guard let `self` = self else { return }
            if let oldAlert = self.viewModel.batchConfirmAlert {
                oldAlert.dismiss(animated: false)
            }
            let alert = LarkAlertController()
            alert.setTitle(text: BundleI18n.MailSDK.Mail_StrangerMail_AllowAllConfirmation_Title)
            alert.setContent(text: BundleI18n.MailSDK.Mail_StrangerMail_AllowAllConfirmation_Desc, alignment: .center)
            alert.addCancelButton { [weak self] in
                self?.viewModel.batchConfirmAlert = nil
            }
            alert.addButton(text: BundleI18n.MailSDK.Mail_StrangerMail_AllowAllConfirmation_AllowAll, color: .ud.primaryPri500, dismissCompletion: { [weak self] in
                self?.viewModel.manageStrangerThread(threadIDs: nil, status: true, isSelectAll: true,
                                                     maxTimestamp: (self?.viewModel.strangerViewModel.mailThreads.first?.lastmessageTime ?? 0) + 1,
                                                     fromList: nil)
                self?.viewModel.batchConfirmAlert = nil
            })
            self.viewModel.batchConfirmAlert = alert
            self.userContext.navigator.present(alert, from: self)
        })
        let rejectStrangerItem = MailActionItem(title: BundleI18n.MailSDK.Mail_StrangerInbox_RejectAll_Button,
                                                icon: UDIcon.noOutlined,
                                                udGroupNumber: 1,
                                                tintColor: UIColor.ud.functionDanger500,
                                                actionCallBack: { [weak self] _ in
            guard let `self` = self else { return }
            if let oldAlert = self.viewModel.batchConfirmAlert {
                oldAlert.dismiss(animated: false)
            }
            let alert = LarkAlertController()
            alert.setTitle(text: BundleI18n.MailSDK.Mail_StrangerMail_RejectAllConfirmation_Title)
            alert.setContent(text: BundleI18n.MailSDK.Mail_StrangerMail_RejectAllConfirmation_Desc, alignment: .center)
            alert.addCancelButton { [weak self] in
                self?.viewModel.batchConfirmAlert = nil
            }
            alert.addButton(text: BundleI18n.MailSDK.Mail_StrangerMail_RejectAllConfirmation_RejectAll, color: .ud.primaryPri500, dismissCompletion: { [weak self] in
                self?.viewModel.manageStrangerThread(threadIDs: nil, status: false, isSelectAll: true,
                                                     maxTimestamp: (self?.viewModel.strangerViewModel.mailThreads.first?.lastmessageTime ?? 0) + 1,
                                                     fromList: nil)
                self?.viewModel.batchConfirmAlert = nil
            })
            self.viewModel.batchConfirmAlert = alert
            self.userContext.navigator.present(alert, from: self)
        })
        let showAllStrangerCardListItem = MailActionItem(title: BundleI18n.MailSDK.Mail_StrangerMail_IncompleteList_ViewAll_Button,
                                                         icon: UDIcon.allmailOutlined,
                                                         udGroupNumber: 1,
                                                         actionCallBack: { [weak self] _ in
            guard let `self` = self else { return }
            self.strangerCardListMoreCardItemHandler()
        })
        sections.append(MoreActionSection(layout: .vertical, items: [allowStrangerItem, rejectStrangerItem, showAllStrangerCardListItem]))


        let mailSettingItem = MailActionItem(title: BundleI18n.MailSDK.Mail_StrangerMail_Settings_Button,
                                             icon: UDIcon.settingOutlined,
                                             udGroupNumber: 2,
                                             actionCallBack: { [weak self] _ in
            guard let `self` = self else { return }
            self.showMailSettings()
            MailHomeController.logger.info("[mail_stranger] click mail setting")
        })
        sections.append(MoreActionSection(layout: .vertical, items: [mailSettingItem]))
        let popoverSourceView = rootSizeClassIsSystemRegular ? sender : nil
        presentMoreActionVC(headerConfig: headerConfig, sectionData: sections, popoverSourceView: popoverSourceView, popoverRect: popoverSourceView?.bounds)
    }

    func presentMoreActionVC(headerConfig: MoreActionHeaderConfig?, sectionData: [MoreActionSection], popoverSourceView: UIView?, popoverRect: CGRect?) {
        let moreVC = MoreActionViewController(headerConfig: headerConfig, sectionData: sectionData)
        if let popoverSourceView = popoverSourceView {
            moreVC.needAnimated = false
            moreVC.modalPresentationStyle = .popover
            moreVC.popoverPresentationController?.sourceView = popoverSourceView
            moreVC.popoverPresentationController?.sourceRect = popoverRect ?? CGRect.zero
            if let rect = popoverRect {
                if rect.origin.y > UIScreen.main.bounds.height / 3 * 2 {
                    moreVC.popoverPresentationController?.permittedArrowDirections = .down
                    moreVC.arrowUp = false
                } else {
                    moreVC.popoverPresentationController?.permittedArrowDirections = .up
                    moreVC.arrowUp = true
                }
            }
        }
        self.navigator?.present(moreVC, from: self, animated: false, completion: nil)
    }

    func strangerCardListItemHandler(index: Int, threadID: String) {
        markSelectedThreadId = nil
        MailMessageListViewsPool.reset()
        viewModel.syncDataSource()
        tableView.reloadData()
        enterMsgList(at: index, threadID: threadID, labelID: Mail_LabelId_Stranger, threadList: viewModel.strangerViewModel.mailThreads.all)
        MailTracker.log(event: "email_stranger_card_list_click", params: ["click": "stranger_card", "label_item": self.viewModel.currentLabelId])
    }

    func strangerCardListMoreCardItemHandler() {
        markSelectedThreadId = nil
        viewModel.syncDataSource()
        tableView.reloadData()
        let cardListVC = MailStrangerCardListController(accountContext: userContext.getCurrentAccountContext(),
                                                        pageSize: CGSize(width: view.frame.width,
                                                                         height: view.frame.height - naviHeight - statusHeight))
        cardListVC.delegate = self
        cardListVC.markSelectedThreadId = headerViewManager.tableHeaderView.strangerCardListView?.selectedThreadID
        cardListVC.currentLabelID = viewModel.currentLabelId
        cardListVC.backCallback = { [weak self] in
            guard let self = self else { return }
            let cardBannerDatasource = self.viewModel.strangerViewModel.mailThreads.all.prefix(StrangerCardConst.maxCardCount)
            MailLogger.info("[mail_stranger] collect cardBannerDatasource: \(cardBannerDatasource.map({ $0.threadID })) markSelectedThreadId: \(self.viewModel.strangerCardList?.markSelectedThreadId ?? "")")
            if let listSelectedID = self.viewModel.strangerCardList?.markSelectedThreadId {
                if let index = cardBannerDatasource.firstIndex(where: { $0.threadID == listSelectedID }) {
                    self.headerViewManager.tableHeaderView.strangerCardListView?
                        .updateSelectedStatus(index: IndexPath(row: index, section: 0), threadID: listSelectedID)
                } else {
                    self.headerViewManager.tableHeaderView.strangerCardListView?
                        .clearSelectedStatus()
                }
            }
            self.viewModel.strangerCardList = nil

        }
        cardListVC.didAppearHandler = { [weak self] in
            guard let self = self else { return }
            if let lastToast = self.viewModel.cardListToastList.last {
                if lastToast.1 {
                    UDToast.showSuccess(with: lastToast.0, on: cardListVC.view)
                } else {
                    UDToast.showFailure(with: lastToast.0, on: cardListVC.view)
                }
                self.viewModel.cardListToastList.removeAll()
            }
        }
        cardListVC.clearSelectedHandler = { [weak self] in
            guard let self = self else { return }
            if Display.pad && self.markSelectedThreadId == nil {
                self.navigator?.showDetail(SplitViewController.makeDefaultDetailVC(), wrap: LkNavigationController.self, from: self)
            }
        }
        viewModel.strangerCardList = cardListVC
        self.userContext.navigator.push(cardListVC, from: self)
        MailTracker.log(event: "email_stranger_card_list_click", params: ["click": "more_card", "label_item": self.viewModel.currentLabelId])
    }

    func strangerCardCellDidClickReply(_ cell: MailStrangerThreadCell, cellModel: MailThreadListCellViewModel, status: Bool) {
        MailLogger.info("[mail_stranger] strangerCardCellDidClickReply threadID: \(cellModel.threadID) status: \(status)")
        viewModel.didClickStrangerReply(cell, cellModel: cellModel, status: status)
        MailTracker.log(event: "email_stranger_card_list_click", params: ["click": status ? "allow_sender" : "reject_sender", "label_item": self.viewModel.currentLabelId])
    }

    func strangerCardCellDidClickAvatar(mailAddress: MailAddress, cellModel: MailThreadListCellViewModel) {
        let name = mailAddress.mailDisplayName
        let userid = mailAddress.larkID
        //let entityType = mailAddress.type ?? .unknown
        let entityType = Email_Client_V1_Address.LarkEntityType(rawValue: 0) ?? .user
        let tenantId = mailAddress.tenantId
        let address = mailAddress.address
        let accountId = userContext.getCurrentAccountContext().accountID
        MailContactLogic.default.checkContactDetailAction(userId: userid,
                                                          tenantId: tenantId,
                                                          currentTenantID: userContext.user.tenantID,
                                                          userType: entityType.toContactType()) { [weak self] result in
            guard let self = self else { return }
            if result == MailContactLogic.ContactDetailActionType.profile {
                // internal user, show Profile
                self.userContext.profileRouter.openUserProfile(userId: userid, fromVC: self)
            } else if result == MailContactLogic.ContactDetailActionType.nameCard {
                if MailAddressChangeManager.shared.addressNameOpen() {
                    var item = AddressRequestItem()
                    item.address =  address
                    MailDataServiceFactory.commonDataService?.getMailAddressNames(addressList: [item]).subscribe( onNext: { [weak self]  MailAddressNameResponse in
                        guard let `self` = self else { return }
                            if let item = MailAddressNameResponse.addressNameList.first, !item.larkEntityID.isEmpty &&
                                item.larkEntityID != "0" {
                                self.userContext.profileRouter.openUserProfile(userId: item.larkEntityID, fromVC: self)
                            } else {
                                self.userContext.profileRouter.openNameCard(accountId: accountId, address: address, name: name, fromVC: self) { [weak self] success in
                                    self?.handleSaveContactResult(success, cellModel: cellModel)
                                }
                            }
                        }, onError: { [weak self] (error) in
                            guard let `self` = self else { return }
                            MailLogger.error("handle peronal click resp error \(error)")
                            self.userContext.profileRouter.openNameCard(accountId: accountId, address: address, name: name, fromVC: self) { [weak self] success in
                                self?.handleSaveContactResult(success, cellModel: cellModel)
                            }
                        }).disposed(by: self.disposeBag)
                } else {
                    self.userContext.profileRouter.openNameCard(accountId: accountId, address: address, name: name, fromVC: self) { [weak self] success in
                        self?.handleSaveContactResult(success, cellModel: cellModel)
                    }
                }
            }
        }
    }

    func handleSaveContactResult(_ success: Bool, cellModel: MailThreadListCellViewModel) {
        MailLogger.info("[mail_stranger] openNameCard callback: \(success)")
        if success {
            self.viewModel.manageStrangerThread(threadIDs: [cellModel.threadID], status: true, isSelectAll: false, maxTimestamp: cellModel.lastmessageTime + 1, fromList: cellModel.fromList)
        }
    }
}

extension MailHomeController: MailCacheSettingDelegate {
    func updateCacheRangeSuccess(accountId: String, expandPreload: Bool, offline: Bool, allowMobileTraffic: Bool) {
        MailCacheSettingViewController.changeCacheRangeSuccess(accountId: accountId, showProgrssBtn: tableView.contentOffset.y > 0,
                                                               expandPreload: expandPreload, offline: offline, allowMobileTraffic: allowMobileTraffic, view: self.view) { [weak self] in
            self?.scrollToTopOfThreadList(accountId: accountId)
        }
    }
}
