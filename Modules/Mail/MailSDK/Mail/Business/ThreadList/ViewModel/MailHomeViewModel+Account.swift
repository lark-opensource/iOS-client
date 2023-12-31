//
//  MailHomeViewModel+account.swift
//  MailSDK
//
//  Created by tefeng liu on 2022/3/16.
//

import Foundation
import RxSwift

extension MailHomeViewModel {
    /// 行为统计埋点
    func auditSwitchToSharedAccount() {
        guard Store.settingData.currentAccount.value?.isShared == true && Store.settingData.currentAccount.value?.mailSetting.userType != .tripartiteClient else {
            MailLogger.info("audit switch-mail not shared or is MailClient")
            return
        }
        guard let accountName = Store.settingData.currentAccount.value?.accountName, let accountAddress = Store.settingData.currentAccount.value?.accountAddress else {
            MailLogger.error("auditSwitchToSharedAccount Name or Address not found")
            return
        }
        userContext.securityAudit.audit(type: .switchToSharedMail(name: accountName, sender: accountAddress))
    }

    func refreshAllListData() {
        MailLogger.debug("[mail_home_init] [mail_home] [mail_init] refreshAccountList start")
        labels = []
        lastGetThreadListInfo = (false, false)
        listViewModel.cancelGetThreadList()
        getLabelDisposeBag = DisposeBag()
        startedFetchSetting = true
        refreshAccountList(onCompleted: { [weak self] in
            self?.startedFetchSetting = false
            MailLogger.debug("[mail_init] refreshAccountList end, group leave and set startedFetchSetting false")
            self?.firstFetchListData()
            self?.$uiElementChange.accept(.refreshHeaderBizInfo)
        })
    }

    func refreshAccountList(onCompleted: (() -> Void)?) {
        guard let settingDisposeBag = settingDisposeBag else {
            return
        }
        MailLogger.info("[mail_home_init] [mail_home] refreshAccountList accountList: \(Store.settingData.getCachedAccountList()?.count) currentAccountId: \(Store.settingData.getCachedCurrentAccount()?.mailAccountID)")
        if let accountList = Store.settingData.getCachedAccountList(), Store.settingData.ifTabVCSettingLoaded() {
            self.refreshCurrentAccCache(currentAccountId: Store.settingData.getCachedCurrentAccount()?.mailAccountID ?? "",
                                        accountList: accountList)
            onCompleted?()
            Store.settingData.resetTabVCSettingLoadedFlag()
        } else {
            Store.settingData.getAccountList(fetchDb: true)
            .subscribe(onNext: { [weak self](resp) in
                guard let `self` = self else { return }
                let currentAccountId = resp.currentAccountId
                self.refreshCurrentAccCache(currentAccountId: currentAccountId, accountList: resp.accountList)
                onCompleted?()
            }).disposed(by: settingDisposeBag)
        }
    }

    func updateCurrentAccount(_ account: MailAccount) {
        let needRefetch = !(currentAccount?.isValid() ?? true) && account.isValid()
        MailLogger.info("[mail_home] homeVM - updateCurrentAccount needRefetch: \(needRefetch) currentAccount: \(currentAccount?.mailAccountID) account: \(account.mailAccountID)")
        self.currentAccountObservable.accept((account, needRefetch))
        if enableStranger == nil {
            self.enableStranger = account.mailSetting.enableStranger
        }
    }

    func refreshCurrentAccCache(currentAccountId: String, accountList: [MailAccount]) {
        MailLogger.info("[mail_client] coexist refreshCurrentAccCache currentAccountId: \(currentAccountId) accountList: \(accountList.map({ $0.mailAccountID }))")
        var accList = accountList
        if Store.settingData.clientStatus == .mailClient {
            accList = accountList.filter({ $0.mailSetting.userType != .noPrimaryAddressUser && !Store.settingData.isInIMAPFlow($0) })
        } else if Store.settingData.clientStatus == .saas {
            accList = accountList.filter({ $0.mailSetting.userType != .tripartiteClient })
        }
        if let account = accList.first(where: { $0.mailAccountID == currentAccountId }), account.isValid() {
            MailLogger.info("mail home current account id: " + currentAccountId + " account count: \(accList.count) smartInbox \(account.mailSetting.smartInboxMode)")
            self.updateCurrentAccount(account)
            self.$uiElementChange.accept(.refreshAuthPage(setting: account.mailSetting))
            if accList.count > 1 {
                let badge = Store.settingData.getOtherAccountUnreadBadge()
                self.$uiElementChange.accept(.showMultiAccount(account, showBadge: badge))
            } else {
                self.$uiElementChange.accept(.dismissMultiAccount)
            }
            if let status = account.mailSetting.emailClientConfigs.first?.configStatus,
               status == .expired {
                self.$uiElementChange.accept(.expiredTips(true))
            } else {
                self.$uiElementChange.accept(.expiredTips(false))
                guard let shouldShowGuide = userContext.provider.guideServiceProvider?.guideService?.checkShouldShowGuide(key: "all_mail_Client_OAuth_login") else {
                    return
                }
                let needShowPassLoginExpiredTips = account.mailSetting.userType == .tripartiteClient &&
                account.provider.needShowPassLoginExpried() && account.loginPassType == .password
                self.$uiElementChange.accept(.passLoginExpiredTips(needShowPassLoginExpiredTips && !shouldShowGuide))
            }
        }
    }

    func switchAccount(_ mailAccountID: String) {
        guard !mailAccountID.isEmpty else { return }
        MailLogger.info("[mail_client] switch account id \(mailAccountID)")
        Store.settingData
            .switchMailAccount(to: mailAccountID)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (resp) in
                guard let `self` = self else { return }
                self.refreshAccountList { [weak self] in
                    if self?.hasFirstLoaded ?? false {
                        EventBus.$threadListEvent.accept(.reloadLabelMenu)
                        self?.updateUnreadDotAfterFirstScreenLoaded()
                    }
                }
                MailLogger.info("[mail_client] switch success account id \(mailAccountID)")
            },
            onError: { (error) in
                MailLogger.error("[mail_client] switch error account id \(mailAccountID)")
            }).disposed(by: self.disposeBag)
    }

    func updateUnreadDotAfterFirstScreenLoaded() {
        guard let setting = Store.settingData.getCachedCurrentSetting() else { return }
        let labelID = Store.settingData.mailClient ? Mail_LabelId_Inbox : (setting.smartInboxMode ? Mail_LabelId_Important : Mail_LabelId_Inbox)
        let count = labels.filter({ ($0.labelId == labelID || ($0.tagType == .folder && $0.labelId != Mail_LabelId_Stranger)) && $0.labelId != currentLabelId })
            .map({ $0.badge ?? 0 }).reduce(0, +)
        let canNotificate = setting.allNewMailNotificationSwitch && setting.newMailNotification
        self.$uiElementChange.accept(.updateArrowView(isHidden: count <= 0, isRed: canNotificate))
    }


    /// 刷完account数据后需要拉取列表数据
    func firstFetchListData() {
        guard let currentAccount = self.currentAccount, currentAccount.isValid(), canInitData else {
            MailLogger.error("[mail_home_init] [mail_init] [mail_home] refreshAccountList account is not valid!  or curAccID is empty! no need to fetch data, canInitData: \(canInitData)")
            return
        }
        userContext.bootManager.homePreloader.preloadStatus.accept(.noNeed)
        startedFetchThreadList = true
        let event = MailAPMEvent.LabelListLoaded()
        event.commonParams.append(MailAPMEvent.LabelListLoaded.CommonParam.sence_cold_start)
        event.markPostStart()
        loadLabelListCostTimeStart() // TODO: REFACTOR 埋点
        MailLogger.info("[mail_init] [mail_home] firstFetchListData initListData start getLabels")
        // 先获取label列表 拉取第一个
        MailDataSource.shared.getLabelsFromDB().subscribe(onNext: { [weak self] (labels) in
            guard let `self` = self else { return }
            MailLogger.info("[mail_home_init] [loadLabels] initData label order from rust \(labels.map({ $0.labelId }).joined(separator: ", "))")
            let labelIds = labels.map({ $0.labelId })
            self.labels = labels
            MailTagDataManager.shared.updateTags(labels.map({ $0.toPBModel() }))
            self._labelListFgDataError = !(labelIds.contains(Mail_LabelId_Important) && labelIds.contains(Mail_LabelId_Other))
            self.$errorRouter.accept(.labelListFgDataError(isError: self._labelListFgDataError))
            let labelCount = MailAPMEvent.LabelListLoaded.EndParam.list_length(self.labels.count)
            event.endParams.append(labelCount)
            event.endParams.append(MailAPMEventConstant.CommonParam.status_success)
            event.postEnd()
            self.loadLabelListCostTimeEnd() // TODO: REFACTOR 埋点
            MailLogger.info("[mail_home_init] [mail_init] getLabelsFromDB end, group leave")
        }, onError: { [weak self] (error) in
            guard let self = `self` else { return }
            MailLogger.info("[mail_home_init][mail_init] getLabelsFromDB error: \(error )")
            event.endParams.appendError(errorCode: error.mailErrorCode, errorMessage: error.getMessage())
            event.endParams.append(MailAPMEventConstant.CommonParam.status_rust_fail)
            event.postEnd()
            self.listViewModel.$dataState.accept(.failed(labelID: self.currentLabelId, err: error))
        }).disposed(by: getLabelDisposeBag)
        self.loadThreadListCostTimeStart()
        self.getThreadList()
    }

    func refreshGetThreadListIfNeeded(_ setting: MailSetting) {
        guard !Store.settingData.mailClient else {
            return
        }
        // 相关技术文档 https://bytedance.feishu.cn/docs/doccn4UU3EEgVG1jSksqHplhd7c
        if let currentAccount = currentAccount, !labels.isEmpty { // Step 1 阶段
            // Setting 已经拉回来 Labels也已经返回
            if !hasFirstLoaded,
                lastGetThreadListInfo.0 == true, lastGetThreadListInfo.1 == setting.smartInboxMode {
                MailLogger.info("[mail_home_init] [mail_init] GetThreadList no need to cancel, smartInboxMode not change")
                return
            }
            MailLogger.info("[mail_home_init] [mail_init] current: \(currentAccount.mailSetting.smartInboxMode) smartInboxMode changed to \(setting.smartInboxMode)")
            guard currentAccount.mailSetting.smartInboxMode != setting.smartInboxMode else {
                return
            }
            if let account = Store.settingData.getCachedCurrentAccount() {
                if !self.hasFirstLoaded { // 若smart inbox开关变化了，取消GetThreadList 重新请求 // && account.mailSetting.smartInboxMode != setting.smartInboxMode
                    MailLogger.info("[mail_home_init] [mail_home] [mail_init] Step 2 processing, cancelGetThreadList and Re Fetch")
                    self.listViewModel.cancelGetThreadList()
                    self.lastGetThreadListInfo = (false, false)
                    self.getThreadList(setting)
                } else {
                    if !setting.smartInboxMode &&
                        (self.currentLabelId == Mail_LabelId_Important || self.currentLabelId == Mail_LabelId_Other) {
                        let labelId = Mail_LabelId_Inbox
                        let labelName = BundleI18n.MailSDK.Mail_Folder_Inbox
                        self.createNewThreadList(labelId: labelId,
                                                 labelName: labelName)
                        self.$uiElementChange.accept(.autoChangeLabel(labelId: labelId,
                                                                      labelName: labelName,
                                                                      isSystem: true,
                                                                      updateTimeStamp: true))
                    } else if !self._labelListFgDataError && setting.smartInboxMode && self.currentLabelId == Mail_LabelId_Inbox {
                        let labelId = Mail_LabelId_Important
                        let labelName = BundleI18n.MailSDK.Mail_SmartInbox_Important
                        self.createNewThreadList(labelId: labelId,
                                                 labelName: labelName)
                        self.$uiElementChange.accept(.autoChangeLabel(labelId: labelId,
                                                                      labelName: labelName,
                                                                      isSystem: true,
                                                                      updateTimeStamp: false))
                    }
                }
                if var tempCurrentAccount = self.currentAccount {
                    tempCurrentAccount.mailSetting = setting
                    self.updateCurrentAccount(tempCurrentAccount)
                }
            }
        } else { // Step 1 阶段未完成
            // gcd group 进行中, 确保能更新currentAccount即可
            guard !ignoreSettingPush else { return }
            if let account = Store.settingData.getCachedCurrentAccount() {
                MailLogger.info("[mail_home_init] Step 1 processing, cancelSettingFetch currentAccountID: \(currentAccount?.mailAccountID) labels count: \(labels.count) startedFetchSetting: \(startedFetchSetting) startedFetchThreadList: \(startedFetchThreadList)")
                self.updateCurrentAccount(account)
                if startedFetchSetting {
                    MailLogger.info("[mail_home_init] Step 1 startedFetchSetting, apply setting mode: \(account.mailSetting.smartInboxMode) from push and group leave again")
                    cancelSettingFetch()
                    startedFetchSetting = false
                }
                if !self.startedFetchThreadList {
                    self.firstFetchListData()
                }
                self.$uiElementChange.accept(.refreshHeaderBizInfo)
                self.refreshAccountList(onCompleted: nil)
                ignoreSettingPush = true
            }
        }
    }
}
