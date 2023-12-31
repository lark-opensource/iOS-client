//
//  NotificationSettingEntryModule.swift
//  LarkMine
//
//  Created by panbinghua on 2022/6/17.
//

import UserNotifications
import Foundation
import UIKit
import LarkContainer
import EENavigator
import LarkFoundation
import LarkMessengerInterface
import LarkSDKInterface
import LarkOpenSetting
import LarkSettingUI

final class NotificationSettingEntryModule: BaseModule {
    var enableNotification = true

    override init(userResolver: UserResolver) {
        super.init(userResolver: userResolver)
        checkNotificationSettings()
        NotificationCenter.default.rx.notification(UIApplication.willEnterForegroundNotification)
            .subscribe(onNext: { [weak self] _ in
                self?.checkNotificationSettings()
            }).disposed(by: disposeBag)
    }

    func checkNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] (setting) in
            guard let self = self else { return }
            let enable = setting.authorizationStatus == .authorized
            if enable != self.enableNotification {
                self.enableNotification = enable
                self.context?.reload()
            }
        }
    }

    lazy var warningIconView: UIView = {
        let size = CGSize(width: 16, height: 16)
        let icon = Resources.notice_alert.ud.resized(to: size)
        let view = ViewHelper.createSizedImageView(size: size, image: icon)
        return view
    }()

    func getItem() -> CellProp {
        let str = BundleI18n.LarkMine.Lark_NewSettings_NewMessageNotificationGoToEnableMobile
        let viewProvider = { () -> UIView in self.warningIconView }
        let accessories: [NormalCellAccessory] = self.enableNotification ? [.arrow()]
        : [.custom(viewProvider, spacing: 5.5),
           .text(str, spacing: 4),
           .arrow()]
        let item = NormalCellProp(title: BundleI18n.LarkMine.Lark_NewSettings_NewMessageNotifications,
                                         accessories: accessories,
                                         onClick: { [weak self] _ in
            guard let self = self, let vc = self.context?.vc else { return }
            if self.enableNotification {
                let body = MineNotificationSettingBody()
                self.userResolver.navigator.push(body: body, from: vc)
            } else {
                self.goToSetting()
            }
        })
        return item
    }

    override func createSectionProp(_ key: String) -> SectionProp? {
        guard !enableNotification else { return nil }
        let item = getItem()
        let text: String
        if Utils.isiOSAppOnMacSystem {
            text = BundleI18n.LarkMine.Lark_Core_EnableNotification
        } else {
            text = BundleI18n.LarkMine.Lark_NewSettings_NewMessageNotificationNotEnabledDescriptionMobile
        }
        let section = SectionProp(items: [item], footer: .title(text))
        return section
    }

    override func createCellProps(_ key: String) -> [CellProp]? {
        guard enableNotification else { return nil }
        let item = getItem()
        return [item]
    }
}
