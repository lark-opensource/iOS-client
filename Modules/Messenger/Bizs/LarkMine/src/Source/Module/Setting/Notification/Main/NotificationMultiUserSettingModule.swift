//
//  NotificationMultiUserSettingModule.swift
//  LarkMine
//
//  Created by aslan on 2023/10/30.
//

import Foundation
import UIKit
import LarkContainer
import LarkFoundation
import LarkOpenSetting
import LarkSettingUI
import RxSwift
import RxRelay
import LarkAccountInterface
import LarkRustClient
import LarkPushTokenUploader
import LarkMessengerInterface
import UniverseDesignToast
import LarkStorage

typealias I18N = BundleI18n.LarkMine

// 接收其他账号消息通知设置入口
extension NotificationSettingMainModule {
    func createMultiUserNotificationSection() -> SectionProp? {
        guard MultiUserActivitySwitch.enableMultipleUserRealtime else {
            SettingLoggerService.logger(.module(self.key)).info("enableMultipleUserRealtime false")
            return nil
        }
        guard let multiUserService = try? self.userResolver.resolve(type: MultiUserActivityCoordinatable.self)
        else {
            SettingLoggerService.logger(.module(self.key)).info("resolve MultiUserActivityCoordinatable failed.")
            return nil
        }
        let multiUserNotificationSetting = multiUserService.settingsEnableMultiUserActivity
        let text = multiUserNotificationSetting
        ? I18N.Lark_NewSettings_MessageNotifications_FromOtherAccounts_On_Text
        : I18N.Lark_NewSettings_MessageNotifications_FromOtherAccounts_Off_Text
        let item = NormalCellProp(title: I18N.Lark_NewSettings_MessageNotifications_FromOtherAccounts_Title,
                                  accessories: [.text(text), .arrow()],
                                  onClick: { [weak self] _ in
            guard let vc = self?.context?.vc else { return }
            self?.userResolver.navigator.push(body: MultiUserNotificationBody(), from: vc)
        })
        return SectionProp(items: [item])
    }
}

final class NotificationMultiUserSettingModule: BaseModule {

    private enum Cons {
        static let maxDiffSwitchTime: Double = 10 // second
    }

    private let bag = DisposeBag()
    private let switchChange = PublishRelay<Bool>()
    private var multiUserNotificationSetting: Bool = false
    private var multiUserService: MultiUserActivityCoordinatable?

    static let userStore = \NotificationMultiUserSettingModule._userStore

    @KVBinding(to: userStore, key: KVKeys.Setting.MultiUserNotification.lastOperationTime)
    private var lastOperateTime: Double?

    override init(userResolver: UserResolver) {
        super.init(userResolver: userResolver)
        self.multiUserService = try? self.userResolver.resolve(type: MultiUserActivityCoordinatable.self)
        self.multiUserNotificationSetting = multiUserService?.settingsEnableMultiUserActivity ?? false
        SettingLoggerService.logger(.module(self.key)).info("init switch: \(self.multiUserNotificationSetting)")
        // 防止快速连续点击时开关需要频繁更新，改为最后一次点击后0.3s后生效
        switchChange
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isOn in
                guard let self = self else { return }
                self.handleSwitchChange(isOn)
            })
            .disposed(by: bag)
    }

    private func handleSwitchChange(_ isOn: Bool) {
        guard let context = self.context, let vc = context.vc else { return }
        let now: Double = Date().timeIntervalSince1970
        if let lastOperateTime = self.lastOperateTime,
           now - lastOperateTime < Cons.maxDiffSwitchTime {
            self.multiUserNotificationSetting = !isOn
            context.reload()
            SettingLoggerService.logger(.module(self.key)).info("switch too frequent")
            UDToast.showFailure(with: I18N.Lark_NewSettings_MessageNotifications_TooFrequentTryAgain_Toast, on: vc.view)
            return
        }
        self.multiUserNotificationSetting = isOn
        self.multiUserService?.settingsWillUpdate(isOn) { [weak self] _ in
            guard let `self` = self else { return }
            context.reload()

            /// 开关变化，触发上报
            guard let uploadService = try? self.userResolver.resolve(type: LarkPushTokenUploaderService.self) else {
                return
            }
            uploadService.multiUserNotificationSwitchChange(isOn)
        }
        self.lastOperateTime = Date().timeIntervalSince1970
        SettingLoggerService.logger(.module(self.key)).info("switch at time: \(String(describing: self.lastOperateTime)), result: \(isOn)")
    }

    private func getActivityUserList() -> [String] {
        let userList = self.multiUserService?.activityUserIDList.filter({ $0 != self.userResolver.userID })
        return userList ?? []
    }

    func getItem() -> CellProp {
        let item = SwitchNormalCellProp(title: I18N.Lark_NewSettings_MessageNotifications_FromOtherAccounts_Title,
                                        isOn: multiUserNotificationSetting,
                                        onSwitch: { [weak self] _, isOn in
            self?.switchChange.accept(isOn)
        })
        return item
    }

    func getTenantItems() -> [ImageTitleCellProp] {
        let passportService = try? self.userResolver.resolve(type: PassportService.self)
        let userList = getActivityUserList()
        SettingLoggerService.logger(.module(self.key)).info("get activity list: \(userList)")
        var items: [ImageTitleCellProp] = []
        userList.forEach { userId in
            // 过滤掉当前登录租户
            if userId != self.userResolver.userID,
               let tenant = passportService?.getUser(userId)?.tenant {
                let item = ImageTitleCellProp(imageUrl: tenant.iconURL, title: tenant.localizedTenantName)
                items.append(item)
            }
        }
        return items
    }

    override func createSectionProp(_ key: String) -> SectionProp? {
        if key == ModulePair.MultiUserNotification.multiUserSwitch.createKey {
            return createSwitchSection()
        } else if key == ModulePair.MultiUserNotification.multiUserList.createKey {
            return createListSection()
        }
        return nil
    }

    func createSwitchSection() -> SectionProp? {
        let items: [CellProp] = [getItem()]
        let text = I18N.Lark_NewSettings_MessageNotifications_FromOtherAccounts_Desc
        var footer: HeaderFooterType = .normal
        if multiUserNotificationSetting {
            let userList = getActivityUserList()
            if userList.isEmpty {
                footer = .title(I18N.Lark_NewSettings_MessageNotifications_FromOtherAccounts_NoOtherAccountsLoggedIn_Hint)
            }
        }
        let section = SectionProp(items: items, header: .title(text), footer: footer)
        return section
    }

    func createListSection() -> SectionProp? {
        var items: [CellProp] = []
        if multiUserNotificationSetting {
            let tenantItems = getTenantItems()
            items.append(contentsOf: tenantItems)
        }
        guard !items.isEmpty else {
            return nil
        }
        let text = I18N.Lark_NewSettings_MessageNotifications_FromOtherAccounts_ReceiveBelowAccounts
        let section = SectionProp(items: items, header: .title(text))
        return section
    }

    override func createCellProps(_ key: String) -> [CellProp]? {
        let item = getItem()
        return [item]
    }
}
