//
//  LarkMailService+LauchMoniter.swift
//  MailSDK
//
//  Created by tefeng liu on 2019/6/28.
//

import Foundation
import LarkAccountInterface
import LarkContainer
import RxSwift
import MailSDK
import LarkPerf

/// launchDelegte
extension LarkMailService {
    static func larkUserDidLogout(_ error: Error?) {
        if error == nil {
            NotificationCenter.default.post(name: Notification.Name.Mail.MAIL_SDK_CLEAN_DATA, object: nil)
        }
    }

    func mailTabLoaded(_ error: Error?) {
        MailLaunchStatService.default.markActionStart(type: .larkMailAccountLoaded)
        logger.debug("[mailTab] launchMoniter mailTabLoaded")
        //更新apidependency
        updateAPIDependency()
        //详细加载流程看Launcher的State
        mail.refreshUserProfile()
        //更新mail通知中心
        updateMailPushCenter()
        //垃圾袋
        appConfigDisposeBage = DisposeBag()

        dependency.globalWaterMarkOn
            .subscribe(onNext: { [weak self] (isOn) in
                self?.globalWaterMarkIsShow = isOn
            }).disposed(by: appConfigDisposeBage)
        // 首页创建完成后preload数据
        clearAndReloadUnreadCount()
        MailLaunchStatService.default.markActionEnd(type: .larkMailAccountLoaded)
    }

    func didFinishSwitchAccount(_ error: Error?) {
        logger.debug("launchMoniter didFinishSwitchAccount")
        if error == nil {
            mailSDKAPIImp.clean()
        }
        clearAndReloadUnreadCount()
    }

    func reLaunchMail() {
        /// call initsync to load mail
        logger.debug("launchMoniter reLaunchMail")
        clearAndReloadUnreadCount()
    }

    private func clearAndReloadUnreadCount() {
        logger.debug("launchMoniter clearAndReloadUnreadCount")
        mail.getMailUnreadCount().subscribe(onNext: { [weak self] (response) in
            self?.logger.debug("launchMoniter get unreadCount \(response.unreadCount)")
            self?.mailPushCenter?.updateMailTabBadge(count: 0, tabUnreadColor: nil)
            self?.mailPushCenter?.updateMailTabBadge(count: response.unreadCount, tabUnreadColor: response.tabUnreadColor)
            }, onError: { [weak self] (error) in
                self?.logger.debug("Email_Client_V1_MailGetUnreadCountRequest fail error: \(error)")
                self?.logger.debug("launchMoniter get unreadCount fail error: \(error)")
        }).disposed(by: disposeBag)
    }
}
