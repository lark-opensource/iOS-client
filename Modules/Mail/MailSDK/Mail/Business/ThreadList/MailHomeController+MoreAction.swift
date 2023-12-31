//
//  MailHomeController+MoreAction.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2020/10/29.
//

import Foundation
import Homeric
import LarkAlertController
import EENavigator
import LarkUIKit
import UniverseDesignMenu
import UniverseDesignIcon
import RxSwift

// MARK: - Nav Bar Actions
extension MailHomeController {
    func markAllAsRead() {
        let alert = LarkAlertController()
        alert.setContent(text: BundleI18n.MailSDK.Mail_ThreadList_MarkAllAsReadAlert, alignment: .center)
        alert.addSecondaryButton(text: BundleI18n.MailSDK.Mail_Alert_Cancel)
        alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_Alert_OK, dismissCompletion: { [weak self] in
            MailTracker.log(event: Homeric.EMAIL_THREAD_MARKALLASREAD, params: [MailTracker.sourceParamKey(): MailTracker.source(type: .threadList)])
            guard let `self` = self else { return }
            let labelID = self.viewModel.currentLabelId
            self.viewModel.apmMarkThreadMarkAllReadStart()
            self.threadActionDataManager.markAllAsRead(labelID: labelID).subscribe(onNext: { () in
                self.viewModel.apmMarkThreadMarkAllReadEnd(status: .status_success)
                DispatchQueue.main.async {
                    MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_ThreadList_MarkAllAsReadSucceed, on: self.tabBarController?.view ?? self.view)
                }
                /// 全标已读下，rust的乐观请求会先推送，再callback，但为了确保端上已接收push并更新完毕cache，需要做延迟推送
                Observable.just(())
                    .delay(.milliseconds(timeIntvl.normalMili), scheduler: MainScheduler.instance)
                    .subscribe(onNext: { [weak self] _ in
                        self?.refreshListDataReady.accept((.markAllRead, true))
                    }).disposed(by: self.disposeBag)
            }, onError: { [weak self](error) in
                guard let `self` = self else { return }
                self.viewModel.apmMarkThreadMarkAllReadEnd(status: .status_rust_fail, error: error)
                DispatchQueue.main.async {
                    if error.mailErrorCode == MailErrorCode.migrationReject {
                        let alert = LarkAlertController()
                        alert.setTitle(text: BundleI18n.MailSDK.Mail_Inbox_ActionFailed)
                        alert.setContent(text: BundleI18n.MailSDK.Mail_Inbox_MigrationCannotExecuteAction, alignment: .center)
                        alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_Alert_CloseAnyway)
                        self.navigator?.present(alert, from: self)
                    } else {
                        MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_ThreadList_MarkAllAsReadFailed,
                                                   on: self.tabBarController?.view ?? self.view, event: ToastErrorEvent(event: .thread_mark_all_read_fail))
                    }
                }
            }).disposed(by: self.disposeBag)
            if self.viewModel.currentFilterType == .unread {
                self.viewModel.listViewModel.cancelGetThreadList()
                self.viewModel.listViewModel.cleanUnreadFilterIfNeeded()
                self.viewModel.syncDataSource(datas: [])
                self.tableView.reloadData()
                self.refreshListDataReady.accept((.markAllRead, true))
            }
            MailHomeController.logger.info("didClick MarkAllAsRead")
        })
        navigator?.present(alert, from: self)
    }

    func didClickFilterButton() {
        if viewModel.filterViewModel.selectedFilter.value.filterType == .allMail {
            viewModel.filterViewModel.showMenu()
        } else if viewModel.filterViewModel.selectedFilter.value.filterType == .unread {
            // 直接设置为all
            viewModel.filterViewModel.didSelectFilter(type: .allMail)
        }
    }

    func emptyAll() {
        let alert = LarkAlertController()
        let dialog = viewModel.currentLabelId == Mail_LabelId_Spam ? BundleI18n.MailSDK.Mail_ThreadList_EmptySpamDialog : BundleI18n.MailSDK.Mail_ThreadList_EmptyTrashDialog
        alert.setContent(text: dialog, alignment: .center)
        alert.addSecondaryButton(text: BundleI18n.MailSDK.Mail_ThreadList_EmptyCancel)
        alert.addDestructiveButton(text: BundleI18n.MailSDK.Mail_ThreadList_EmptyConfirm, dismissCompletion: { [weak self] in
            guard let `self` = self else { return }
            let event = self.viewModel.currentLabelId == Mail_LabelId_Spam ? "email_thread_emptySpam" : "email_thread_emptyTrash"
            MailTracker.log(event: event, params: [MailTracker.sourceParamKey(): MailTracker.source(type: .threadList)])
            guard let lastmessageTime = self.viewModel.datasource.first?.lastmessageTime else {
                return
            }
            MailRoundedHUD.showLoading(with: BundleI18n.MailSDK.Mail_ThreadList_Emptying,
                                   on: self.tabBarController?.view ?? self.view, disableUserInteraction: false)
            let labelID = self.viewModel.currentLabelId
            MailDataServiceFactory
                .commonDataService?
                .selectAll(labelID: labelID, maxTimestamp: lastmessageTime + 1, addLabelIds: ["PERMANENT_DELETE"])
                .subscribe(onNext: { [weak self] (response)  in
                    self?.viewModel.sessionIDs.append(response.sessionID)
                }, onError: { [weak self] (error) in
                    guard let `self` = self else { return }
                    MailLogger.error("Send selectAll request failed error: \(error).")
                    DispatchQueue.main.async {
                        MailRoundedHUD.remove(on: self.tabBarController?.view ?? self.view)
                        if error.mailErrorCode == MailErrorCode.migrationReject {
                            let alert = LarkAlertController()
                            alert.setTitle(text: BundleI18n.MailSDK.Mail_Inbox_ActionFailed)
                            alert.setContent(text: BundleI18n.MailSDK.Mail_Inbox_MigrationCannotExecuteAction, alignment: .center)
                            alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_Alert_CloseAnyway)
                            self.navigator?.present(alert, from: self)
                        } else {
                            MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_ThreadList_ActionFailed,
                                                       on: self.tabBarController?.view ?? self.view, event: ToastErrorEvent(event: .thread_empty_all_fail))
                        }
                    }
                }).disposed(by: self.disposeBag)
            MailHomeController.logger.info("didClick EmptyAll")
        })
        navigator?.present(alert, from: self)
    }

    func emptyAllEnable() -> Bool {
        if viewModel.currentLabelId == Mail_LabelId_Trash
        || viewModel.currentLabelId == Mail_LabelId_Spam {
            return true
        }
        return false
    }

    private func menuNewCoreEvent(targetAction: String) {
        let labelsMenuController = self.getTagMenu()
        let event = NewCoreEvent(event: .email_label_item_right_menu_click)
        let value = NewCoreEvent.labelTransfor(labelId: labelsMenuController.viewModel.selectedID,
                                               allLabels: labelsMenuController.viewModel.labels)
        event.params = ["click": targetAction,
                        "target": "none",
                        "label_item": value,
                        "mail_service_type": Store.settingData.getMailAccountListType()]
        event.post()
    }

    func showMoreAction() {
        showMoreActionCustom()
    }

    private func showMoreActionCustom() {
        if isMultiSelecting { return }
        let markAsReadItem = PopupMenuActionItem(title: BundleI18n.MailSDK.Mail_ThreadList_MarkAllAsRead,
                                                 icon: UDIcon.markReadOutlined,
                                                 callback: { [weak self] (menu, action) in
                guard let `self` = self else { return }
                self.markAllAsRead()

                self.menuNewCoreEvent(targetAction: "marksread")
        })
        let multipleSelectItem = PopupMenuActionItem(title: BundleI18n.MailSDK.Mail_MultipleSelect_Button,
                                                     icon: UDIcon.selectUpOutlined,
                                                     callback: { [weak self] (menu, action) in
                guard let `self` = self else { return }
                self.enterMultiSelect()
                self.updateThreadActionBar()
                MailTracker.log(event: Homeric.EMAIL_MULTISELECT_THREADLIST, params: ["source": "more"])
                MailHomeController.logger.info("didClick multipleSelect")
        })
        let mailSettingItem = PopupMenuActionItem(title: BundleI18n.MailSDK.Mail_ThreadList_MailSettings,
                                                  icon: UDIcon.settingOutlined,
                                                  callback: { [weak self] (menu, action) in
                guard let `self` = self else { return }
                self.showMailSettings()
                MailHomeController.logger.info("didClick mail setting")
        })
        let emptyAllTitle = viewModel.currentLabelId == Mail_LabelId_Spam ? BundleI18n.MailSDK.Mail_ThreadList_EmptySpam : BundleI18n.MailSDK.Mail_ThreadList_EmptyTrash
        let emptyAllItem = PopupMenuActionItem(title: emptyAllTitle,
                                               icon: UDIcon.deleteTrashOutlined,
                                               callback: { [weak self] (menu, action) in
            guard let `self` = self else { return }
            self.emptyAll()
        })
        var items: [PopupMenuActionItem] = [mailSettingItem]
        if multipleSelectEnable() {
            items.insert(multipleSelectItem, at: 0)
        }
        if markAllAsReadEnable() {
            items.insert(markAsReadItem, at: 0)
        }
        if emptyAllEnable() {
            items.insert(emptyAllItem, at: 0)
        }
        /// if no datasource, disabled multiple select
        multipleSelectItem.isEnabled = !viewModel.datasource.isEmpty
        markAsReadItem.isEnabled = !viewModel.datasource.isEmpty
        emptyAllItem.isEnabled = !viewModel.datasource.isEmpty
        var vc: UIViewController
        if rootSizeClassIsSystemRegular {
            vc = PopupMenuPoverViewController(items: items)
            vc.modalPresentationStyle = .popover
            vc.popoverPresentationController?.backgroundColor = UIColor.ud.bgBody
            vc.popoverPresentationController?.sourceView = navMoreButton
            vc.popoverPresentationController?.sourceRect = navMoreButton.bounds
        } else {
            vc = PopupMenuViewController(items: items)
            vc.modalPresentationStyle = .overFullScreen
        }
        navigator?.present(vc, from: self, animated: false)
        MailTracker.log(event: Homeric.EMAIL_HOME_MORE, params: [:])

        let labelsMenuController = self.getTagMenu()
        let event = NewCoreEvent(event: .email_label_item_right_menu_view)
        let value = NewCoreEvent.labelTransfor(labelId: labelsMenuController.viewModel.selectedID,
                                               allLabels: labelsMenuController.viewModel.labels)
        event.params = ["label_item": value,
                        "mail_service_type": Store.settingData.getMailAccountListType()]
        event.post()
    }

    @discardableResult
    func showMailSettings() -> UIViewController? {
        MailTracker.log(event: Homeric.EMAIL_SETTINGS_CLICK, params: [:])
        let settingController = MailSettingWrapper.getSettingController(userContext: userContext)
        settingController.clientDelegate = self
        let nav = LkNavigationController(rootViewController: settingController)
        nav.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen
        navigator?.present(nav, from: self)
        return settingController
    }

    /// need show mark all as read
    func markAllAsReadEnable() -> Bool {
        if viewModel.currentLabelId == Mail_LabelId_Stranger &&
            !userContext.featureManager.open(.stranger, openInMailClient: false) {
            return true
        }
        if viewModel.currentLabelId == Mail_LabelId_Inbox
            || viewModel.currentLabelId == Mail_LabelId_Important
            || viewModel.currentLabelId == Mail_LabelId_Other
            || viewModel.currentLabelId == Mail_LabelId_SHARED
            || !viewModel.currentLabelId.isSystemLabel() {
            return true
        }
        return false
    }

    /// need show multiple select
    func multipleSelectEnable() -> Bool {
        if viewModel.currentLabelId == Mail_LabelId_Stranger &&
            !userContext.featureManager.open(.stranger, openInMailClient: false) {
            return true
        }
        if isMultiSelecting ||
            viewModel.currentLabelId == Mail_LabelId_Outbox ||
            viewModel.currentLabelId == Mail_LabelId_SHARED ||
            viewModel.currentLabelId == Mail_LabelId_Stranger {
            return false
        }
        return true
    }
}
