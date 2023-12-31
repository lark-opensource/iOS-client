//
//  NotificationSettingModule.swift
//  ByteViewMod
//
//  Created by kiri on 2023/6/2.
//

import Foundation
import ByteViewCommon
import LarkOpenSetting
import LarkContainer
import ByteViewSetting
import LarkSDKInterface
import LarkSettingUI
import UniverseDesignToast
import RxSwift

final class NotificationSettingModule: BaseModule {
    private var setting: UserUniversalSettingService? { try? userResolver.resolve(assert: UserUniversalSettingService.self) }
    private var vcSetting: UserSettingManager? { try? userResolver.resolve(assert: UserSettingManager.self) }

    override init(userResolver: UserResolver) {
        super.init(userResolver: userResolver)

        self.settingObservable(for: .useSysCall)?.subscribe(onNext: { _ in
            self.context?.reload()
        }).disposed(by: disposeBag)
        self.settingObservable(for: .includeInRecent)?.subscribe(onNext: { _ in
            self.context?.reload()
        }).disposed(by: disposeBag)
        self.settingObservable(for: .useINStartCallIntent)?.subscribe(onNext: { _ in
            self.context?.reload()
        }).disposed(by: disposeBag)
    }

    override func createSectionProp(_ key: String) -> SectionProp? {
        guard #available(iOS 15.2, *), key == ModulePair.Notification.inStartCallIntent.createKey else { return nil }
        let item = SwitchNormalCellProp(title: I18n.View_MV_EnhanceNotification,
                                        detail: I18n.View_MV_EnhanceNotification_Note,
                                        isOn: self.useInStartCallIntent) { [weak self] _, isOn in
            self?.updateSetting(isOn, for: .useINStartCallIntent)
        }
        return SectionProp(items: [item])
    }

    override func createCellProps(_ key: String) -> [CellProp]? {
        switch key {
        case ModulePair.Notification.useSystemCall.createKey:
            guard let service = self.vcSetting, service.showsCallKitSetting else { return nil }
            let item = SwitchNormalCellProp(title: I18n.View_MV_ReceiveCallSystemPhone_Switch,
                                            detail: I18n.View_MV_ReceiveCallWithPhone_Note,
                                            isOn: self.useSystemCall) { [weak self] _, isOn in
                self?.updateSetting(isOn, for: .useSysCall)
            }
            return [item]
        case ModulePair.Notification.includesCallsInRecents.createKey:
            guard let service = self.vcSetting, service.isCallKitEnabled, self.useSystemCall else { return nil }
            let item = SwitchNormalCellProp(title: I18n.View_MV_SystemCallRecordIntegrateApp_Note(),
                                            isOn: self.includeCallsInRecents) { [weak self] _, isOn in
                self?.updateSetting(isOn, for: .includeInRecent)
            }
            return [item]
        default:
            return nil
        }
    }

    private var useSystemCall: Bool {
        currentSetting(for: .useSysCall, defaultValue: true)
    }

    private var includeCallsInRecents: Bool {
        currentSetting(for: .includeInRecent, defaultValue: false)
    }

    private var useInStartCallIntent: Bool {
        currentSetting(for: .useINStartCallIntent, defaultValue: true)
    }

    private func updateSetting(_ value: Bool, for key: UniversalSettingKey) {
        if self.setting?.getBoolUniversalUserSetting(key: key.rawValue) == value { return }
        self.setting?.setUniversalUserConfig(values: [key.rawValue: .boolValue(value)])
            .observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] in
                self?.context?.reload()
        }, onError: { [weak self] error in
            guard let self = self, let vc = self.context?.vc else { return }
            UDToast.showFailure(with: I18n.Lark_Settings_BadgeStyleChangeFail, on: vc.view, error: error)
            self.context?.reload()
            SettingLoggerService.logger(.module(self.key)).info("api/\(key.errorApiName)/set/req: \(value); res: error: \(error)")
        }).disposed(by: disposeBag)
    }

    private func currentSetting(for key: UniversalSettingKey, defaultValue: Bool) -> Bool {
        if let value = setting?.getBoolUniversalUserSetting(key: key.rawValue) {
            return value
        } else {
            return defaultValue
        }
    }

    private func settingObservable(for key: UniversalSettingKey) -> Observable<Bool?>? {
        setting?.getBoolUniversalUserObservableSetting(key: key.rawValue).observeOn(MainScheduler.instance)
    }
}

private enum UniversalSettingKey: String {
    // 设置通话用系统电话接听
    case useSysCall = "BYTEVIEW_USE_SYS_CALL"
    // 设置系统通话记录显示应用通话记录
    case includeInRecent = "BYTEVIEW_USE_SYS_RECENT"
    // 设置使用持续震动响铃通知
    case useINStartCallIntent = "BYTEVIEW_USE_START_CALL_INTENT"

    var errorApiName: String {
        switch self {
        case .useSysCall:
            return "useSystemCall"
        case .includeInRecent:
            return "includesInRecent"
        case .useINStartCallIntent:
            return "useINStartCallIntent"
        }
    }
}
