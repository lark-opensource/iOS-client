//
//  MultiAccountCoExistDataCenter.swift
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

class MultiAccountCoExistDataCenter: MultiAccountDataCenter {

    var fgValue = FeatureManager.realTimeOpen(.mailClient)
    private let disposeBag = DisposeBag()
    private let userKVStore: MailKVStore
    init(userKVStore: MailKVStore) {
        self.userKVStore = userKVStore
        if FeatureManager.open(.fgNotifyUseApi) {
            FeatureManager.getFeatureNotify().subscribe(onNext: {[weak self] in
                guard let `self` = self else { return }
                if self.fgValue != FeatureManager.realTimeOpen(.mailClient), !FeatureManager.realTimeOpen(.mailClient) {
                    MailLogger.info("[mail_client] coexist fg change, mailClientRevoke")
                    self.fgValue = FeatureManager.realTimeOpen(.mailClient)
                    self.mailClientRevokeHandler()
                }
            }).disposed(by: disposeBag)
        }
    }

    func mailClientRevokeHandler(setting: MailSetting? = nil) {
        var needPopToHome = false
        if Store.settingData.currentAccount.value?.mailSetting.userType == .tripartiteClient {
            // 切换到主账号
            var needPopToHome = true
            guard let primaryAccount = Store.settingData.primaryAccount.value else { return }
            Store.settingData.switchMailAccount(to: primaryAccount.mailAccountID).subscribe(onNext: { (_) in
                NotificationCenter.default.post(Notification(name: Notification.Name.Mail.MAIL_SWITCH_ACCOUNT))
                Store.settingData.$permissionChanges.accept((.mailClientRevoke, needPopToHome))
                Store.settingData.acceptCurrentAccountChange()
             }, onError: { (err) in
                 mailAssertionFailure("[mail_client] coexist MailClientDataCenter [mail_account] err in switch account \(err)")
             }).disposed(by: Store.settingData.disposeBag)
        } else {
            Store.settingData.$permissionChanges.accept((.mailClientRevoke, needPopToHome))
            Store.settingData.acceptCurrentAccountChange()
        }
    }

    func handleAccountChange(change: MailAccountChange) {
        NotificationCenter.default.post(name: Notification.Name.Mail.MAIL_SETTING_CHANGED_BYPUSH,
                                        object: Store.settingData.findCurrentSetting(account: change.account))
        // end
        MailLogger.info("[mail_client] coexist CoExistDataCenter [mail_account] mail client mail setting manager mail account changed from local: \(change.fromLocal) \(change.account.mailAccountID) isShared: \(change.account.isShared) \(change.account.mailSetting.userType) \(change.account.sharedAccounts.count) \(change.account.mailSetting.mailOnboardStatus) isThirdServiceEnable: \(change.account.mailSetting.isThirdServiceEnable) isSelected: \(change.account.accountSelected.isSelected)")
        if change.account.mailSetting.userType == .noPrimaryAddressUser && change.account.accountSelected.isSelected,
           let clientAccount = change.account.sharedAccounts.first(where: { $0.mailSetting.userType == .tripartiteClient }) {
            MailLogger.info("[mail_client] coexist CoExistDataCenter create triClient first time, need to switch account")
            Store.settingData.switchMailAccount(to: clientAccount.mailAccountID).subscribe(onNext: { [weak self] (_) in
                self?.userKVStore.set(true, forKey: "mail_client_account_onboard_\(clientAccount.mailAccountID)")
                NotificationCenter.default.post(Notification(name: Notification.Name.Mail.MAIL_SWITCH_ACCOUNT))
                self?.handlePermissionChange(change: change)
                Store.settingData.updateAccountInfos(of: change.account)
                Store.settingData.$accountInfoChanges.accept(())
            }, onError: { (err) in
                mailAssertionFailure("[mail_client] coexist CoExistDataCenter [mail_account] err in switch account \(err)")
            }).disposed(by: Store.settingData.disposeBag)
        } else {
            Store.settingData.updateAccountInfos(of: change.account)
            handlePermissionChange(change: change)
            if change.account.accountSelected.isSelected {
                Store.settingData.updateCachedCurrentAccount(change.account)
            } else if let selectedAccount = change.account.sharedAccounts.first(where: { $0.accountSelected.isSelected }) {
                Store.settingData.updateCachedCurrentAccount(selectedAccount)
            }
            Store.settingData.$accountInfoChanges.accept(())
        }
    }

    func handlePermissionChange(change: MailAccountChange) {
        if var accList = Store.settingData.getCachedAccountList() {
            for (index, acc) in accList.enumerated() where acc.mailAccountID == change.account.mailAccountID {
                accList[index] = change.account
            }
            accList = accList.filter({ ($0.mailSetting.userType == .tripartiteClient && change.account.mailSetting.isThirdServiceEnable) || ($0.mailSetting.userType != .tripartiteClient && $0.mailSetting.emailClientConfigs.first?.configStatus != .deleted) })
            MailLogger.info("[mail_client] coexist CoExistDataCenter handlePermissionChange accList: \(accList.count)")
            Store.settingData.updateAccountList(accList)
            if !change.account.isShared {
                var account = change.account
                account.sharedAccounts = accList
            }
        }
        /// 共存 -> 主账号被删,切换到三方账号
        if (Store.settingData.isInIMAPFlow(change.account) || change.account.mailSetting.emailClientConfigs.first?.configStatus == .deleted), change.account.mailSetting.isThirdServiceEnable {
            MailLogger.info("[mail_client] coexist CoExistDataCenter primary deleted, switch to thirdService")
            var needPopToMailHome = false
            guard let currentAccount = Store.settingData.getCachedCurrentAccount() else { return }
            if currentAccount.mailAccountID == change.account.mailAccountID {
                needPopToMailHome = true
                guard let mailClientAcc = Store.settingData.getAvailableMailClientAccount() else {
                    MailLogger.error("[mail_client] coexist CoExistDataCenter mailClientAcc is nil, should jump to clientvc")
                    dispatchPermisschange(userType: currentAccount.mailSetting.userType, needPopToMailHome: needPopToMailHome)
                    Store.settingData.$rebootChanges.accept(())
                    Store.settingData.updateClientStatusIfNeeded()
                    return
                }
                Store.settingData.switchMailAccount(to: mailClientAcc.mailAccountID).subscribe(onNext: { [weak self] (_) in
                    guard let `self` = self else { return }
                    NotificationCenter.default.post(Notification(name: Notification.Name.Mail.MAIL_SWITCH_ACCOUNT))
                    self.dispatchPermisschange(userType: currentAccount.mailSetting.userType, needPopToMailHome: needPopToMailHome)
                }, onError: { [weak self] (err) in
                    guard let `self` = self else { return }
                    mailAssertionFailure("[mail_client] coexist CoExistDataCenter [mail_account] err in switch account \(err)")
                    self.dispatchPermisschange(userType: currentAccount.mailSetting.userType, needPopToMailHome: needPopToMailHome)
                    Store.settingData.acceptCurrentAccountChange()
                    Store.settingData.updateClientStatusIfNeeded()
                }).disposed(by: Store.settingData.disposeBag)
            } else {
                dispatchPermisschange(userType: currentAccount.mailSetting.userType, needPopToMailHome: needPopToMailHome)
                Store.settingData.acceptCurrentAccountChange()
            }
        /// 共存 -> 单账号
        } else if !change.account.mailSetting.isThirdServiceEnable {
            MailLogger.info("[mail_client] coexist CoExistDataCenter coexist to saas")
            var needPopToMailHome = false
            if let currentAccount = Store.settingData.getCachedCurrentAccount(),
               currentAccount.mailSetting.userType == .tripartiteClient {
                needPopToMailHome = true
                guard let primaryAcc = Store.settingData.getCachedPrimaryAccount() else {
                    MailLogger.error("[mail_client] coexist CoExistDataCenter primaryAcc is nil")
                    Store.settingData.$permissionChanges.accept((.mailClientRevoke, needPopToMailHome))
                    Store.settingData.updateClientStatusIfNeeded()
                    return
                }
                Store.settingData.$permissionChanges.accept((.mailClientRevoke, needPopToMailHome))
                Store.settingData.switchMailAccount(to: primaryAcc.mailAccountID).subscribe(onNext: { [weak self] (_) in
                    guard let `self` = self else { return }
                    NotificationCenter.default.post(Notification(name: Notification.Name.Mail.MAIL_SWITCH_ACCOUNT))
                    Store.settingData.acceptCurrentAccountChange()
                    Store.settingData.updateAccountInfos(of: change.account)
                    Store.settingData.$accountInfoChanges.accept(())
                    Store.settingData.updateClientStatusIfNeeded()
                }, onError: { [weak self] (err) in
                    guard let `self` = self else { return }
                    mailAssertionFailure("[mail_client] coexist CoExistDataCenter err in switch account \(err)")
                }).disposed(by: Store.settingData.disposeBag)
            } else {
                Store.settingData.$permissionChanges.accept((.mailClientRevoke, false))
                Store.settingData.updateClientStatusIfNeeded()
            }
        }
    }

    func dispatchPermisschange(userType: Email_Client_V1_Setting.UserType, needPopToMailHome: Bool) {
        if userType == .larkServer {
            Store.settingData.$permissionChanges.accept((.lmsRevoke, needPopToMailHome))
        } else if userType == .oauthClient {
            Store.settingData.$permissionChanges.accept((.gcRevoke, needPopToMailHome))
        }
        Store.settingData.updateClientStatusIfNeeded()
    }

    func handleShareAccountChange(change: MailSharedAccountChange) {
        MailLogger.info("[mail_client] coexist [mail_client_token] [mail_account] mail setting manager shared account changed: \(change.account.mailAccountID) \(change.account.mailSetting.emailClientConfigs.map({ $0.configStatus })) bind: \(change.isBind) sharedAcc count: \(change.account.sharedAccounts)")
        Store.settingData.shareAccountChangeDefaultHandler(change)
    }

    // 获取全量的 account list
    func getAccountList(fetchDb: Bool) -> Observable<(currentAccountId: String, accountList: [MailAccount])> {
        guard let fetcher = Store.fetcher else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        let originAccountId = Store.settingData.getCachedCurrentAccount()?.mailAccountID ?? ""
        MailLogger.info("[mail_client] coexist getAccountList fetchDb: \(fetchDb) originAccountId: \(originAccountId)")
        return fetcher.getPrimaryAccount(fetchDb: fetchDb).map { [weak self] (response) -> (currentAccountId: String, accountList: [MailAccount]) in
            guard let `self` = self else { return (currentAccountId: "", accountList: []) }
            Store.settingData.updateAccountList([response.account] + response.account.sharedAccounts)
            let selectedAccountId = ([response.account] + response.account.sharedAccounts).first(where: { $0.accountSelected.isSelected })?.mailAccountID
            MailLogger.info("[mail_client] coexist accountId: \(response.account.mailAccountID) selectedAccountId: \(selectedAccountId) ")
            guard let accountId = selectedAccountId else {
                // assertionFailure("get account list error - no current account id")
                MailLogger.error("[mail_client] coexist get account list error - no current account id, originAccountId: \(originAccountId)")
                return (currentAccountId: originAccountId,
                        accountList: [response.account] + response.account.sharedAccounts)
            }
            MailLogger.info("[mail_client] coexist get account list shared accounts count \(response.account.sharedAccounts.count)")
            return (currentAccountId: accountId,
                    accountList: [response.account] + response.account.sharedAccounts)
        }
    }

    func getCachedAccountList() -> [MailAccount]? {
        let list = Store.settingData.accountList.value?.filter({ $0.mailSetting.userType != .noPrimaryAddressUser && $0.isValid() })
        MailLogger.info("[mail_client] coexist CoExistDataCenter getCachedAccountList count: \(list?.count)")
        return (list?.count ?? 0) > 0 ? list : nil
    }
}
