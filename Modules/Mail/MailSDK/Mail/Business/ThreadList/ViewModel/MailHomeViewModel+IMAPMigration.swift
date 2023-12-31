//
//  MailHomeViewModel+IMAPMigration.swift
//  MailSDK
//
//  Created by ByteDance on 2023/10/8.
//

import Foundation
import RustPB

extension MailHomeViewModel {
    struct IMAPMigrationStoreKey {
        static private  let bannerClosePrefix = "banner_closed_"
        static private  let migrationInCompletePrefix = "show_migration_partial_"
        static private  let shareAccountImgrationTipsPrefix = "show_share_account_migration_onboarding"
        static private  let pauseAlertPrefix = "show_migraion_pause_alert_"
        static func bannerCloseKey(accountID: String) -> String {
            return bannerClosePrefix + accountID
        }
        static func migrationInCompleteKey(accountID: String) -> String {
            return migrationInCompletePrefix + accountID
        }
        static func migrationPauseAlertKey(accountID: String) -> String {
            return pauseAlertPrefix + accountID
        }
        static func shareAccountImgrationTipsKey() -> String {
            return shareAccountImgrationTipsPrefix
        }
    }
    
    func getImapMigrationState() {
        guard userContext.featureManager.open(.imapMigration, openInMailClient: false) else {
            MailLogger.info("[mail_client] [imap_migration] featuregate disable")
            return
        }
        MailLogger.info("[mail_client] [imap_migration] get state start")
        userContext.sharedServices.dataService.getIMAPMigartionState().subscribe(onNext: {[weak self] response in
            let state = response.state
            MailLogger.info("[mail_client] [imap_migration] get state \(state.status), messageID: \(state.reportMessageID), migrationID: \(state.migrationIDString)")
            self?.migrationState = state
            self?.$imapMigrationState.accept(state)
        }, onError: { error in
            MailLogger.error("[mail_client] [imap_migration] get state failed", error: error)
        }).disposed(by: disposeBag)
        self.getAllAccountIMAPMigrationStates(fromServer: true)
    }
    
    func showMigrationOnboardIfNeed() {
        MailLogger.info("[mail_client] [imap_migration] check if show migration tips when appeared")
        getAllAccountIMAPMigrationStates(fromServer: false)
    }
    
    func didShowMigrationOnboard(migrationsIDs: Set<String>) {
        MailLogger.info("[mail_client] [imap_migration] did show share account migration tips \(migrationsIDs)")
        let storeKey = IMAPMigrationStoreKey.shareAccountImgrationTipsKey()
        userContext.userKVStore.set(migrationsIDs, forKey: storeKey)
    }
    
    private func getAllAccountIMAPMigrationStates(fromServer: Bool) {
        guard userContext.featureManager.open(.imapMigration, openInMailClient: false) else {
            MailLogger.info("[mail_client] [imap_migration] featuregate disable")
            return
        }
        MailLogger.info("[mail_client] [imap_migration] start get all imap migration states from server \(fromServer)")
        userContext.sharedServices.dataService.getAllAccountIMAPMigrationState(fromServer: fromServer).subscribe(onNext: {[weak self] response in
            if response.status == .success {
                MailLogger.info("[mail_client] [imap_migration] get states \(response.stateMap)")
                Store.settingData.updateImapMigrateStates(stateMap: response.stateMap)
                self?.checkIfShareAccountStartMigration(stateMap: response.stateMap)
            } else {
                MailLogger.info("[mail_client] [imap_migration] get states failed")
            }
        }, onError: { error in
            MailLogger.error("[mail_client] [imap_migration] get all imap migration states failed", error: error)
        }).disposed(by: disposeBag)

    }
    
    // 新增开启搬家的公共邮箱，并且新增的公共邮箱不是当前的邮箱
    private func checkIfShareAccountStartMigration(stateMap: [Int64: Email_Client_V1_IMAPMigrationState]) {
        guard let currentAccountID = currentAccount?.mailAccountID else { return }
        guard let primaryAccountID = Store.settingData.primaryAccount.value?.mailAccountID else { return }
        let storeKey = IMAPMigrationStoreKey.shareAccountImgrationTipsKey()
        let lastMigrateInitShareAccounts: Set<String> = userContext.userKVStore.value(forKey: storeKey) ?? Set<String>()
        var curMigrationInitShareAccounts = Set<String>()
        for (key, value) in stateMap {
            if value.status == .init_  && primaryAccountID != String(key) {
                curMigrationInitShareAccounts.insert(String(key))
            }
        }
        MailLogger.info("[mail_client] [imap_migration] shareAccounts init last \(lastMigrateInitShareAccounts)")
        MailLogger.info("[mail_client] [imap_migration] shareAccounts init current \(curMigrationInitShareAccounts)")
        var subtraction = curMigrationInitShareAccounts.subtracting(lastMigrateInitShareAccounts)
        subtraction.remove(currentAccountID)
        if !subtraction.isEmpty { // 有新增的公共邮箱开启搬家
            self.$uiElementChange.accept(.showSharedAccountMigrationOboarding(migrationsIDs: curMigrationInitShareAccounts))
        } else {
            // 更新缓存
            userContext.userKVStore.set(curMigrationInitShareAccounts, forKey: storeKey)
        }
    }
}
