//
//  MultiAccountMailClientDataCenter.swift
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

class MultiAccountMailClientDataCenter: MultiAccountDataCenter {

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

    func handleAccountChange(change: MailAccountChange) {
        NotificationCenter.default.post(name: Notification.Name.Mail.MAIL_SETTING_CHANGED_BYPUSH,
                                        object: Store.settingData.findCurrentSetting(account: change.account))
        // end
        MailLogger.info("[mail_client_token] handleAccountChange \(change.account.sharedAccounts.map({ $0.loginPassType }))")
        MailLogger.info("[mail_client] coexist MailClientDataCenter [mail_account] mail client mail setting manager mail account changed from local: \(change.fromLocal) \(change.account.mailAccountID) isShared:\(change.account.isShared) \(change.account.mailSetting.userType)  \(change.account.sharedAccounts.count) \(change.account.mailSetting.mailOnboardStatus) isThirdServiceEnable: \(change.account.mailSetting.isThirdServiceEnable)")

        if change.account.mailSetting.userType == .noPrimaryAddressUser && change.account.accountSelected.isSelected,
           let clientAccount = change.account.sharedAccounts.first(where: { $0.mailSetting.userType == .tripartiteClient }) {
            Store.settingData.switchMailAccount(to: clientAccount.mailAccountID).subscribe(onNext: { [weak self] (_) in
                self?.userKVStore.set(true, forKey: "mail_client_account_onboard_\(clientAccount.mailAccountID)")
                NotificationCenter.default.post(Notification(name: Notification.Name.Mail.MAIL_SWITCH_ACCOUNT))
            }, onError: { (err) in
                mailAssertionFailure("[mail_client] coexist MailClientDataCenter [mail_account] err in switch account \(err)")
            }).disposed(by: Store.settingData.disposeBag)
        }
        handlePermissionChange(change: change)
        if change.account.accountSelected.isSelected {
            Store.settingData.updateCachedCurrentAccount(change.account)
        } else if let selectedAccount = change.account.sharedAccounts.first(where: { $0.accountSelected.isSelected }) {
            Store.settingData.updateCachedCurrentAccount(selectedAccount)
        }
        Store.settingData.updateAccountInfos(of: change.account)
        Store.settingData.$accountInfoChanges.accept(())
    }

    func handlePermissionChange(change: MailAccountChange) {
        if !change.account.mailSetting.isThirdServiceEnable {
            mailClientRevokeHandler(setting: change.account.mailSetting)
            return
        }
        var primaryAccShouldBlockTripartiteClient = false
        if change.account.mailSetting.userType == .larkServer || change.account.mailSetting.userType == .exchangeClient {
            if Store.settingData.isInIMAPFlow(change.account) {
                /// IMAP搬家未完成 - 屏蔽主账号
                primaryAccShouldBlockTripartiteClient = true
                MailLogger.info("[mail_client] coexist MailClientDataCenter handlePermissionChange IMAP not finish primaryAccShouldBlockTripartiteClient")
            } else {
                /// IMAP搬家完成 - 走正常新增权限逻辑
                MailLogger.info("[mail_client] coexist MailClientDataCenter handlePermissionChange IMAP finish")
                Store.settingData.$permissionChanges.accept((.lmsAdd(change.account.accountAddress), false))
                userKVStore.set(false, forKey: "mail_client_have_displayed_lms_\(change.account.mailAccountID)")
                rebootIfNeeded(change.account)
                updateAccListIfNeeded(change.account)
            }
        } else if change.account.mailSetting.userType == .oauthClient {
            MailLogger.info("[mail_client] coexist MailClientDataCenter handlePermissionChange change account userType is oauthClient")
            Store.settingData.$permissionChanges.accept((.gcAdd, false))
            rebootIfNeeded(change.account)
            updateAccListIfNeeded(change.account)
        } else if change.account.mailSetting.showApiOnboardingPage {
            /// API搬家
            MailLogger.info("[mail_client] coexist MailClientDataCenter handlePermissionChange showApiOnboardingPage userType: \(change.account.mailSetting.userType)")
            if change.account.mailSetting.userType == .gmailApiClient || change.account.mailSetting.userType == .exchangeApiClient {
                Store.settingData.$permissionChanges.accept((.apiMigration(change.account.accountAddress), false))
                rebootIfNeeded(change.account)
                updateAccListIfNeeded(change.account)
                let accountID = Store.settingData.getCachedCurrentAccount()?.mailAccountID ?? ""
                let store: MailKVStore = {
                    if let userID = userKVStore.userID {
                        return MailKVStore(space: .user(id: userID), mSpace: .account(id: accountID))
                    } else {
                        return MailKVStore(space: .global, mSpace: .account(id: accountID))
                    }
                }()
                store.set(false, forKey: "mail_client_have_displayed_lms_\(change.account.mailAccountID)")
            } else if change.account.mailSetting.userType == .newUser {
                Store.settingData.$permissionChanges.accept((.gcAdd, false))
                rebootIfNeeded(change.account)
                updateAccListIfNeeded(change.account)
                userKVStore.set(false, forKey: "mail_client_have_displayed_lms_\(change.account.mailAccountID)")
            }
        } else {
            updateAccListIfNeeded(change.account)
            MailLogger.info("[mail_client] coexist MailClientDataCenter handlePermissionChange no need to change clientStatus")
        }
        MailLogger.info("[mail_client] coexist MailClientDataCenter handlePermissionChange primaryAccShouldBlockTripartiteClient: \(primaryAccShouldBlockTripartiteClient)")
        if primaryAccShouldBlockTripartiteClient {
            if !change.account.isShared {
                Store.settingData.deleteAccountFromList(change.account.mailAccountID)
            }
        }
    }

    func mailClientRevokeHandler(setting: MailSetting? = nil) {
        var needPopToHome = false
        if Store.settingData.currentAccount.value?.mailSetting.userType == .tripartiteClient {
            // 切换到主账号
            needPopToHome = true
            guard let primaryAccount = Store.settingData.primaryAccount.value else { return }
            Store.settingData.switchMailAccount(to: primaryAccount.mailAccountID).subscribe(onNext: { (_) in
                 NotificationCenter.default.post(Notification(name: Notification.Name.Mail.MAIL_SWITCH_ACCOUNT))
             }, onError: { (err) in
                 mailAssertionFailure("[mail_client] coexist MailClientDataCenter [mail_account] err in switch account \(err)")
             }).disposed(by: Store.settingData.disposeBag)
        } else if let accList = Store.settingData.getCachedAccountList(), accList.count <= 1 {
            // 只有主账号，即未添加三方账号
            needPopToHome = true
            Store.settingData.$rebootChanges.accept(())
            if let setting = setting {
                NotificationCenter.default.post(name: Notification.Name.Mail.MAIL_SETTING_AUTH_STATUS_CHANGED,
                                                object: nil,
                                                userInfo: [Notification.Name.Mail.MAIL_SETTING_DATA_KEY: setting])
            } else if let curSetting = Store.settingData.getCachedCurrentSetting() {
                NotificationCenter.default.post(name: Notification.Name.Mail.MAIL_SETTING_AUTH_STATUS_CHANGED,
                                                object: nil,
                                                userInfo: [Notification.Name.Mail.MAIL_SETTING_DATA_KEY: curSetting])
            }

        }
        Store.settingData.$permissionChanges.accept((.mailClientRevoke, needPopToHome))
        Store.settingData.acceptCurrentAccountChange()
    }

    func rebootIfNeeded(_ account: MailAccount) {
        if let accList = Store.settingData.getCachedAccountList() {
            if accList.map({ $0.isShared }).isEmpty {
                MailLogger.info("[mail_client] coexist MailClientDataCenter have no mailclient account, jump to lms")
                Store.settingData.$rebootChanges.accept(())
                let tenantID = Store.settingData.currentUserContext?.user.tenantID ?? ""
                Store.settingData.switchMailAccount(to: account.mailAccountID).subscribe(onNext: { [weak self] (_) in
                    NotificationCenter.default.post(Notification(name: Notification.Name.Mail.MAIL_SWITCH_ACCOUNT))
                    self?.userKVStore.set(true, forKey: "MailClient_ShowLoginPage_\(tenantID)")
                    self?.updateAccListIfNeeded(account)
                }, onError: { (err) in
                    mailAssertionFailure("[mail_client] coexist MailClientDataCenter [mail_account] err in switch account \(err)")
                }).disposed(by: Store.settingData.disposeBag)
            } else {
                updateAccListIfNeeded(account)
            }
        }
    }

    func updateAccListIfNeeded(_ account: MailAccount) {
        if var accList = Store.settingData.getCachedAccountList() {
            if accList.map({ $0.mailAccountID }).contains(account.mailAccountID) {
                MailLogger.info("[mail_client] coexist MailClientDataCenter insert")
                accList.insert(account, at: 0)
                Store.settingData.updateAccountList(accList)
            } else {
                MailLogger.info("[mail_client] coexist MailClientDataCenter update")
                Store.settingData.updateAccountInList(account)
            }
            Store.settingData.$accountListChanges.accept(())
        }
    }

    func handleShareAccountChange(change: MailSharedAccountChange) {
        MailLogger.info("[mail_client] coexist MailClientDataCenter [mail_account] mail setting manager shared account changed: \(change.account.mailAccountID) \(change.account.mailSetting.emailClientConfigs.map({ $0.configStatus })) bind: \(change.isBind)")
        Store.settingData.shareAccountChangeDefaultHandler(change)
    }

    // 获取全量的 account list
    func getAccountList(fetchDb: Bool) -> Observable<(currentAccountId: String, accountList: [MailAccount])> {
        guard let fetcher = Store.fetcher else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        let originAccountId = Store.settingData.getCachedCurrentAccount()?.mailAccountID ?? ""
        MailLogger.info("[mail_client] coexist MailClientDataCenter getAccountList fetchDb: \(fetchDb) originAccountId: \(originAccountId)")
        return fetcher.getPrimaryAccount(fetchDb: fetchDb).map { [weak self] (response) -> (currentAccountId: String, accountList: [MailAccount]) in
            guard let `self` = self else { return (currentAccountId: "", accountList: []) }
            var accList = [response.account] + response.account.sharedAccounts
            let isThirdServiceEnable = response.account.mailSetting.isThirdServiceEnable
            accList = accList
                .filter({
                    ($0.mailSetting.userType == .tripartiteClient && isThirdServiceEnable) ||
                    ($0.mailSetting.userType != .tripartiteClient &&
                     $0.mailSetting.emailClientConfigs.first?.configStatus != .deleted &&
                     Store.settingData.isInIMAPFlow($0)) })
            Store.settingData.updateAccountList(accList)
            let selectedAccountId = (accList).first(where: { $0.accountSelected.isSelected })?.mailAccountID
            MailLogger.info("[mail_client] coexist MailClientDataCenter accountId: \(response.account.mailAccountID) selectedAccountId: \(selectedAccountId) accList: \(accList.count)")
            guard let accountId = selectedAccountId else {
                // assertionFailure("get account list error - no current account id")
                MailLogger.error("[mail_client] coexist MailClientDataCenter get account list error - no current account id, originAccountId: \(originAccountId)")
                return (currentAccountId: originAccountId,
                        accountList: accList)
            }
            MailLogger.info("[mail_client] coexist MailClientDataCenter get account list shared accounts count \(response.account.sharedAccounts.count)")
            return (currentAccountId: accountId,
                    accountList: accList)
        }
    }

    func getCachedAccountList() -> [MailAccount]? {
        var list = Store.settingData.accountList.value?.filter({ $0.mailSetting.userType != .noPrimaryAddressUser && !Store.settingData.isInIMAPFlow($0) && $0.isValid() })
        MailLogger.info("[mail_client] coexist MailClientDataCenter getCachedAccountList count: \(list?.count)")
        return (list?.count ?? 0) > 0 ? list : nil
    }
}
