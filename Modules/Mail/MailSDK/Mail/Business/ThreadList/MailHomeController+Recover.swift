//
//  MailHomeController+recover.swift
//  MailSDK
//
//  Created by tefeng liu on 2020/8/5.
//

import Foundation

extension MailHomeController {
    func handleRecoverActions(_ noti: Notification) {
        if let info = noti.userInfo,
            let action = info[MailRecoverAction.NotificationKey] as? MailRecoverAction {
            if action.actionType.contains(.reloadThreadData) {
                status = .none
                viewModel.refreshAccountList { [weak self] in
                    self?.reloadThreadData()
                }
            }
            if action.actionType.contains(.refreshMigration) {
                refreshMigrationData()
            }
            if action.actionType.contains(.refreshOutBox) {
                refreshOutBoxData()
            }
        }
    }

    func reloadThreadData(resetLabel: Bool = false) {
        guard let currentAccount = self.viewModel.currentAccount, currentAccount.isValid() else {
            MailLogger.error("[mail_home_init] [mail_init] [mail_home] [mail_client] coexist account reloadThreadData account is not valid! no need to fetch data")
            return
        }
        MailLogger.info("[mail_home_init] [mail_home] [mail_client] coexist account reloadThreadData")
 //       print("--------- reloadThreadData")
//        self.labelsMenuController.viewModel.apmMarkRefresh()
        let getLabelStart = MailTracker.getCurrentTime()
        MailDataSource.shared.getLabelsFromDB().subscribe(onNext: { [weak self] (labels) in
            guard let self = `self` else {
                return
            }
            var refreshLabel = self.viewModel.currentLabelId
            var title = self.viewModel.currentLabelName
            let find = labels.filter { (item) -> Bool in
                return item.labelId == refreshLabel
            }
            if find.isEmpty {
                refreshLabel = Mail_LabelId_Inbox
                title = BundleI18n.MailSDK.Mail_Folder_Inbox
            } else {
                // 如果是修改了这个label。为了更新title
                title = find.first!.text
            }
            if resetLabel {
                refreshLabel = Mail_LabelId_Inbox
                title = BundleI18n.MailSDK.Mail_Folder_Inbox
            }

            let labelIds = labels.map({ $0.labelId })
            self.labelListFgDataError = !(labelIds.contains(Mail_LabelId_Important) && labelIds.contains(Mail_LabelId_Other))

            if let setting = Store.settingData.getCachedCurrentSetting(),
                !self.labelListFgDataError,
                setting.smartInboxMode,
                (resetLabel || refreshLabel == Mail_LabelId_Inbox) {
                refreshLabel = Mail_LabelId_Important
                title = BundleI18n.MailSDK.Mail_SmartInbox_Important
                self.labelsMenuController?.smartInboxModeEnable = true
            }
            if let setting = Store.settingData.getCachedCurrentSetting() {
                self.labelsMenuController?.strangerModeEnable = setting.enableStranger
            }
            if refreshLabel == Mail_LabelId_Important {
                self.viewModel.showPreviewCardIfNeeded(Mail_LabelId_Other)
            }
            if Store.settingData.mailClient {
                if labels.map({ $0.labelId }).contains(Mail_LabelId_Inbox) {
                    refreshLabel = Mail_LabelId_Inbox
                    title = BundleI18n.MailSDK.Mail_Folder_Inbox
                } else {
                    refreshLabel =  labels.first?.labelId ?? Mail_LabelId_Inbox
                    title = labels.first?.text ?? BundleI18n.MailSDK.Mail_Folder_Inbox
                }
            }
            let refreshType = self.viewModel.currentFilterType
            self.switchLabelAndFilterType(refreshLabel, labelName: title, filterType: refreshType)
            self.updateTitle(title)
            self.viewModel.filterViewModel.selectedFilter.accept((refreshType, false))
            self.navbarShowLoading.accept(false)
            self.labelsMenuController?.fgDataError = self.labelListFgDataError
            self.labelsMenuController?.updateLabels(labels)
            self.viewModel.loadThreadListCostTimeStart()
            self.viewModel.listViewModel.refreshMailThreadList(forceRefresh: resetLabel)
            self.viewModel.showSmartInboxOnboardingIfNeeded()
            self.viewModel.labels = labels
            self.viewModel.updateUnreadDotAfterFirstScreenLoaded()
        }, onError: { [weak self] (_) in
            guard let self = `self` else {
                return
            }
            self.viewModel.listViewModel.refreshMailThreadList(forceRefresh: resetLabel)
        }).disposed(by: viewModel.getLabelDisposeBag)
    }

}

extension MailHomeController {

    func refreshMigrationData() {
        headerViewManager.refreshMailMigrationDetails()
    }

    func refreshOutBoxData() {
        headerViewManager.refreshOutboxCount()
    }
}
