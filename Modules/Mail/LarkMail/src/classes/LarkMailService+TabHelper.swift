//
//  LarkMailService+TabHelper.swift
//  LarkMail
//
//  Created by Quanze Gao on 2023/5/19.
//

import Foundation
import RustPB
import LarkRustClient
import RxSwift
import MailSDK

private let inboxTypeKey = "inboxType"
private let isConfigsExpiredKey = "isConfigsExpired" // 是否有账号过期
private let isConfigsDeletedKey = "isConfigsDeleted" // 是否有账号被删除
private let showOnboarding = "showOnboarding"

/// 用户态隔离改造， shared 单例的内容迁移到 LarkMailService 内
extension LarkMailService {
    func initMailForServerNavMode() {
        guard !MailSettingManagerInterface.ifNetSettingLoaded() else {
            logger.debug("[mailTab] NetSetting has been Loaded")
            return
        }
        logger.debug("[mailTab] initMailForServerNavMode")

        preloadSettingInServerNavMode()
    }

    func handleSetting(_ setting: Email_Client_V1_Setting) {
        // 获取了server setting，需要更新badge颜色，防止local setting颜色和server setting不一致，导致颜色不对的bug
        NotificationCenter.default.post(name: Notification.Name.Mail.MAIL_SETTING_CHANGED_BYSELF,
                                        object: setting)
        userContext.bootManager.handleSetting(setting)
    }

    func handleAccount(_ account: MailAccount) {
        // 获取了server account，提前初始化共存数据
        logger.info("[mail_client] handleAccount pri userType: \(account.mailSetting.userType) sharedAccCount: \(account.sharedAccounts.count)")
        MailSettingManagerInterface.updatePrimaryAcc(account)
        MailSettingManagerInterface.updateClientStatusIfNeeded()
        MailSettingManagerInterface.updateCachedCurrentAccount(account, accountList: account.sharedAccounts)
    }

    func preloadSettingInServerNavMode() {
        guard let rustService = try? resolver.resolve(assert: RustService.self) else {
            MailSDKManager.assertAndReportFailure("[UserContainer] Failed to get RustService")
            return
        }
        getNetworkAccountFromRust(rustService: rustService, settingHandler: handleSetting, accountHandler: handleAccount)
    }

    func getNetworkAccountFromRust(rustService: RustService, settingHandler: @escaping (Email_Client_V1_Setting) -> Void, accountHandler: @escaping (MailAccount) -> Void) {
        logger.debug("[mailTab] call getNetworkSettingFromRust")
        MailSettingManagerInterface.getAccount(fetchDb: false).subscribe(onNext: { [weak self] account in
            guard let `self` = self else { return }
            self.logger.debug("[mailTab] call getNetworkSettingFromRust success")
            accountHandler(account)
            settingHandler(account.mailSetting)
            MailSettingManagerInterface.netSettingLoadedNotify()
        }, onError: { [weak self] error in
            guard let `self` = self else { return }
            self.logger.debug("[mailTab] call getNetworkSettingFromRust failed \(error)")
        }).disposed(by: disposeBag)
    }
}
