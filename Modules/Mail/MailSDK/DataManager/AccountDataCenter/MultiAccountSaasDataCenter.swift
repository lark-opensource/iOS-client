//
//  MultiAccountSaasDataCenter.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2022/5/9.
//

import Foundation
import RxSwift
import Logger
import RustPB
import ThreadSafeDataStructure
import EENavigator
import LarkAlertController

class MultiAccountSaasDataCenter: MultiAccountDataCenter {

    var fgValue = FeatureManager.realTimeOpen(.mailClient)
    private let disposeBag = DisposeBag()
    init() {
        if FeatureManager.open(.fgNotifyUseApi) {
            FeatureManager.getFeatureNotify().subscribe(onNext: {[weak self] in
                guard let `self` = self else { return }
                if self.fgValue != FeatureManager.realTimeOpen(.mailClient), FeatureManager.realTimeOpen(.mailClient) {
                    MailLogger.info("[mail_client] coexist fg change, mailClientAdd")
                    self.fgValue = FeatureManager.realTimeOpen(.mailClient)
                    self.mailClientAddHandler()
                }
            }).disposed(by: disposeBag)
        }
    }

    func mailClientAddHandler() {
        if let accList = Store.settingData.getCachedAccountList(), accList.count <= 1 {
            // 只有主账号，即未添加三方账号
            Store.settingData.$rebootChanges.accept(())
            if let curSetting = Store.settingData.getCachedCurrentSetting() {
                NotificationCenter.default.post(name: Notification.Name.Mail.MAIL_SETTING_AUTH_STATUS_CHANGED,
                                                object: nil,
                                                userInfo: [Notification.Name.Mail.MAIL_SETTING_DATA_KEY: curSetting])
            }

        }
        Store.settingData.$permissionChanges.accept((.mailClientAdd, false))
        Store.settingData.acceptCurrentAccountChange()
    }

    func handleAccountChange(change: MailAccountChange) {
        NotificationCenter.default.post(name: Notification.Name.Mail.MAIL_SETTING_CHANGED_BYPUSH,
                                        object: Store.settingData.findCurrentSetting(account: change.account))
        // end
        MailLogger.info("[mail_account] coexist saas mail setting manager mail account changed from local: \(change.fromLocal) \(change.account.mailAccountID) isShared: \(change.account.isShared) \(change.account.mailSetting.userType)  \(change.account.sharedAccounts.count) \(change.account.mailSetting.mailOnboardStatus) isThirdServiceEnable: \(change.account.mailSetting.isThirdServiceEnable)")

        Store.settingData.updateAccountInfos(of: change.account)
        if change.account.accountSelected.isSelected {
            Store.settingData.updateCachedCurrentAccount(change.account)
        } else if let selectedAccount = change.account.sharedAccounts.first(where: { $0.accountSelected.isSelected }) {
            Store.settingData.updateCachedCurrentAccount(selectedAccount)
        }
        handlePermissionChange(change: change)
        Store.settingData.$accountInfoChanges.accept(())
    }

    func handlePermissionChange(change: MailAccountChange) {
        // 增加了三方 -> 变共存 本期不做Onboard，设置页实时刷新即可
        let userType = change.account.mailSetting.userType
        guard let status = change.account.mailSetting.emailClientConfigs.first?.configStatus else { return }
        if userType == .larkServer, status == .deleted {
            Store.settingData.$permissionChanges.accept((.lmsRevoke, true))
        } else if userType == .oauthClient, status == .deleted {
            Store.settingData.$permissionChanges.accept((.gcRevoke, true))
        }
    }

    func handleShareAccountChange(change: MailSharedAccountChange) {
        MailLogger.info("[mail_account] coexist mail setting manager shared account changed: \(change.account.mailAccountID) \(change.account.mailSetting.emailClientConfigs.map({ $0.configStatus })) bind: \(change.isBind)")
        guard change.account.isValid() else { return }
        if change.isBind {
            var accountInfos = Store.settingData.getAccountInfos()
            accountInfos.append(MailSettingManager.getInfo(of: change.account, isMigrating: false, primaryAccount: change.account))
            Store.settingData.setAccountInfos(of: accountInfos)
        } else {
            Store.settingData.setAccountInfos(of: Store.settingData.getAccountInfos().filter({ $0.accountId != change.account.mailAccountID }))
        }
        MailLogger.info("[mail_account] coexist mail setting manager get account shared account changed")
        Store.settingData.$accountInfoChanges.accept(())
    }

    // 获取全量的 account list
    func getAccountList(fetchDb: Bool) -> Observable<(currentAccountId: String, accountList: [MailAccount])> {
        guard let fetcher = Store.fetcher else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        let originAccountId = Store.settingData.getCachedCurrentAccount()?.mailAccountID ?? ""
        MailLogger.info("[mail_client] coexist account getAccountList fetchDb: \(fetchDb) originAccountId: \(originAccountId)")
        return fetcher.getPrimaryAccount(fetchDb: fetchDb).map { [weak self] (response) -> (currentAccountId: String, accountList: [MailAccount]) in
            guard let `self` = self else { return (currentAccountId: "", accountList: []) }
            /// TODO 首次请求的数据不能做屏蔽，因为初始化的clientStatus不准确
            let sharedAccounts = response.account.sharedAccounts //.filter({ $0.mailSetting.userType != .tripartiteClient })
            Store.settingData.updateAccountList([response.account] + sharedAccounts)
            let selectedAccountId = ([response.account] + sharedAccounts).first(where: { $0.accountSelected.isSelected })?.mailAccountID
            MailLogger.info("[mail_client] coexist accountId: \(response.account.mailAccountID) selectedAccountId: \(selectedAccountId) ")
            guard let accountId = selectedAccountId else {
                // assertionFailure("get account list error - no current account id")
                MailLogger.error("[mail_client] coexist account list error - no current account id, originAccountId: \(originAccountId)")
                return (currentAccountId: originAccountId,
                        accountList: [response.account] + sharedAccounts)
            }
            MailLogger.info("[mail_client] coexist get account list shared accounts count \(sharedAccounts.count)")
            return (currentAccountId: accountId,
                    accountList: [response.account] + sharedAccounts)
        }
    }

    func getCachedAccountList() -> [MailAccount]? {
        let list = Store.settingData.accountList.value?.filter({ $0.mailSetting.userType != .tripartiteClient && $0.isValid() })
        MailLogger.info("[mail_client] coexist SaasDataCenter getCachedAccountList count: \(list?.count)")
        return (list?.count ?? 0) > 0 ? list : nil
    }
}
