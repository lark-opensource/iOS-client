//
//  NotificationSettingAddUrgentNumModule.swift
//  LarkUrgent
//
//  Created by ByteDance on 2023/5/15.
//

import Foundation
import LarkOpenSetting
import LarkStorage
import LarkContainer
import LarkMessengerInterface
import LarkSettingUI
import LarkAlertController
import EENavigator
import Contacts
import LarkSDKInterface
import LarkFoundation
import LKCommonsLogging

final public class NotificationSettingAddUrgentNumModule: BaseModule {

    private let appConfigService: UserAppConfig?

    static private var logger = Logger.log(NotificationSettingAddUrgentNumModule.self, category: "AddUrgentNum")

    override public init(userResolver: UserResolver) {
        self.appConfigService = try? userResolver.resolve(assert: UserAppConfig.self)
        super.init(userResolver: userResolver)
    }

    override public func createSectionProp(_ key: String) -> SectionProp? {
        let isOn = KVPublic.Setting.enableAddUrgentNum.value()
        let cellProp = SwitchNormalCellProp(title: BundleI18n.LarkUrgent.Lark_Settings_AddBuzzNumberToContacts_Toggle(),
                                            detail: BundleI18n.LarkUrgent.Lark_Settings_AddBuzzNumberToContacts_Desc(),
                                            isOn: isOn,
                                            id: MineNotificationSettingBody.ItemKey.AddUrgentNum.rawValue) { [weak self] _, isOn in
            self?.updateStatus(status: isOn)
        }
        return SectionProp(items: [cellProp])
    }

    private func updateStatus(status: Bool) {
        if !status {
            // 关闭
            self.showCloseConfirmAlert()
        } else {
            // 打开，需要校验通讯录权限
            self.requestSystemContactAuthorization()
        }
    }

    func requestSystemContactAuthorization() {
        let authorizationStatus = CNContactStore.authorizationStatus(for: CNEntityType.contacts)
        switch authorizationStatus {
        case CNAuthorizationStatus.denied, CNAuthorizationStatus.restricted:
            DispatchQueue.main.async {
                self.context?.reload()
                self.showRequestAuthorizationAlert()
            }
        case CNAuthorizationStatus.notDetermined:
            CNContactStore().requestAccess(for: CNEntityType.contacts, completionHandler: { (granted, _) -> Void in
                DispatchQueue.main.async {
                    if granted {
                        // 写入通讯录并更新本地缓存状态
                        KVPublic.Setting.enableAddUrgentNum.setValue(true)
                        self.updateUrgentNum()
                        UrgentTracker.trackSettingDingAddToAddressClick(isOpen: true)
                    } else {
                        self.context?.reload()
                    }
                }
            })
        case  CNAuthorizationStatus.authorized:
            // 写入通讯录并更新本地缓存状态
            KVPublic.Setting.enableAddUrgentNum.setValue(true)
            self.updateUrgentNum()
            UrgentTracker.trackSettingDingAddToAddressClick(isOpen: true)
        @unknown default:
            fatalError("unknown")
        }
    }

    private func showRequestAuthorizationAlert() {
        guard let vc = self.userResolver.navigator.mainSceneTopMost else {
            return
        }
        let alertController = LarkAlertController()
        alertController.setTitle(text: BundleI18n.LarkUrgent.Lark_Settings_AddBuzzNumberToContacts_AccessContactsFirst_Title())
        alertController.setContent(text: BundleI18n.LarkUrgent.Lark_Settings_AddBuzzNumberToContacts_AccessContactsFirst_Desc())
        alertController.addSecondaryButton(text: BundleI18n.LarkUrgent.Lark_Settings_AddBuzzNumberToContacts_AccessContactsFirst_Cancel_Button)
        alertController.addPrimaryButton(text: BundleI18n.LarkUrgent.Lark_Settings_AddBuzzNumberToContacts_AccessContactsFirst_GotoSettings_Button,
                                  dismissCompletion: {
            if let appSettings = try? URL.forceCreateURL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
            }
        })
        self.userResolver.navigator.present(alertController, from: vc)
    }

    // 更新加急电话
    func updateUrgentNum() {
        guard let appConfig = self.appConfigService?.appConfig, !appConfig.urgentNum.nums.isEmpty else {
            return
        }
        let urgentNum = appConfig.urgentNum.nums
        let updateTime = appConfig.urgentNum.updateTime
        Self.updateUrgentNumWith(urgentNum, updateTime: updateTime)
    }

    // 关闭功能提示弹窗
    func showCloseConfirmAlert() {
        guard let vc = self.userResolver.navigator.mainSceneTopMost else {
            return
        }
        let alertController = LarkAlertController()
        alertController.setTitle(text: BundleI18n.LarkUrgent.Lark_Settings_TurnOffAddBuzzNumberToContacts_Title)
        alertController.setContent(text: BundleI18n.LarkUrgent.Lark_Settings_TurnOffAddBuzzNumberToContacts_Desc)
        alertController.addSecondaryButton(text: BundleI18n.LarkUrgent.Lark_Settings_TurnOffAddBuzzNumberToContacts_Cancel_Button, dismissCompletion: {
            self.context?.reload()
        })
        alertController.addPrimaryButton(text: BundleI18n.LarkUrgent.Lark_Settings_TurnOffAddBuzzNumberToContacts_StopAdding_Button,
                                  dismissCompletion: {
            KVPublic.Setting.enableAddUrgentNum.setValue(false)
            UrgentTracker.trackSettingDingAddToAddressClick(isOpen: false)
        })
        self.userResolver.navigator.present(alertController, from: vc)
    }

    static func updateUrgentNumWith(_ urgentNum: [String], updateTime: Int64) {
        let store = CNContactStore()
        let name = BundleI18n.LarkUrgent.Lark_Core_BuzzCall_Text()
        let emailAddress = "feishu-IMgroup@bytedance.com"
        do {
            let keysToFetch = [CNContactEmailAddressesKey, CNContactPhoneNumbersKey] as [CNKeyDescriptor]
            let predicate = CNContact.predicateForContacts(matchingEmailAddress: emailAddress)
            let contacts = try store.unifiedContacts(matching: predicate, keysToFetch: keysToFetch)
            // 电话号码
            var phoneNumbers: [CNLabeledValue<CNPhoneNumber>] = []
            for call in urgentNum {
                phoneNumbers.append(CNLabeledValue(label: CNLabelPhoneNumberWorkFax, value: CNPhoneNumber(stringValue: call)))
            }
            if contacts.isEmpty {
                // 新增联系人
                let saveRequest = CNSaveRequest()
                let contact = CNMutableContact()
                contact.givenName = name
                contact.phoneNumbers = phoneNumbers
                contact.emailAddresses = [CNLabeledValue(label: CNLabelEmailiCloud, value: emailAddress as NSString)]
                saveRequest.add(contact, toContainerWithIdentifier: nil)
                try store.execute(saveRequest)
            } else {
                // 修改联系人
                for contact in contacts {
                    if let mutableContact = contact.mutableCopy() as? CNMutableContact {
                        let saveRequest = CNSaveRequest()
                        mutableContact.phoneNumbers = phoneNumbers
                        saveRequest.update(mutableContact)
                        try store.execute(saveRequest)
                    }
                }
            }
            KVPublic.Setting.urgentNumUpdateTime.setValue(updateTime)
        } catch let error {
            Self.logger.error("System api error: \(error), update urgent num failed!!, updateTime: \(updateTime)")
        }
    }
}
