//
//  NotificationSettingSpecificModule.swift
//  LarkMine
//
//  Created by panbinghua on 2022/6/28.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import UniverseDesignToast
import LarkMessengerInterface
import LarkSDKInterface
import LarkContainer
import RustPB
import LarkOpenSetting
import LarkSettingUI
import LarkStorage

struct SpecialFocusSettingOptions: OptionSet {
    let rawValue: Int
    static let muteChat = SpecialFocusSettingOptions(rawValue: 1 << 0)
    static let chatBox = SpecialFocusSettingOptions(rawValue: 1 << 1)
    static let muteMode = SpecialFocusSettingOptions(rawValue: 1 << 2)

    func toPB() -> Settings_V1_MessengerNotificationSetting.SpecialFocus {
        var setting = Settings_V1_MessengerNotificationSetting.SpecialFocus()
        setting.noticeInMuteChat = self.contains(.muteChat)
        setting.noticeInChatBox = self.contains(.chatBox)
        setting.noticeInMuteMode = self.contains(.muteMode)
        return setting
    }

    static func from(pb setting: Settings_V1_MessengerNotificationSetting.SpecialFocus) -> SpecialFocusSettingOptions {
        var ops: SpecialFocusSettingOptions = []
        if setting.noticeInMuteChat { ops.insert(.muteChat) }
        if setting.noticeInChatBox { ops.insert(.chatBox) }
        if setting.noticeInMuteMode { ops.insert(.muteMode) }
        return ops
    }
}

extension Settings_V1_MessengerNotificationSetting.SpecialFocus {
    static func from(rawValue: Int) -> Self {
        return SpecialFocusSettingOptions(rawValue: rawValue).toPB()
    }

    var rawValue: Int {
        return SpecialFocusSettingOptions.from(pb: self).rawValue
    }
}

final class NotificationSettingSpecificModule: BaseModule {
    private lazy var viewModel: INotificationSettingSpecificModuleModel = {
        NotificationSettingSpecificModuleModel(userResolver: self.userResolver)
    }()
    var ops = SpecificNotificationOptions()

    override init(userResolver: UserResolver) {
        super.init(userResolver: userResolver)
        self.viewModel.setting
            .subscribe(onNext: { [weak self] setting in
                self?.ops = setting
                self?.context?.reload()
            }).disposed(by: disposeBag)

        addStateListener(.viewWillAppear) { [weak self] in
            self?.viewModel.loadNotificationSetting()
        }
    }

    func toggle(_ ops: SpecificNotificationOptions) {
        viewModel.toggle(ops)
            .observeOn(MainScheduler.instance)
            .subscribe(onError: { [weak self] error in
                guard let self = self, let vc = self.context?.vc else { return }
                UDToast.showFailure(with: BundleI18n.LarkMine.Lark_Settings_BadgeStyleChangeFail,
                                    on: vc.view,
                                    error: error)
            }).disposed(by: disposeBag)
    }

    override func createSectionProp(_ key: String) -> SectionProp? {
        let ops = self.ops
        // 加急
        let buzzRow = CheckboxNormalCellProp(title: BundleI18n.LarkMine.Lark_NewSettings_NotifySelectedTypesOfMessagesBuzz,
                                             boxType: .multiple,
                                                  isOn: true,
                                                  isEnabled: false,
                                                  selectionStyle: .none)
        // at 我
        let atMeRow = CheckboxNormalCellProp(title: BundleI18n.LarkMine.Lark_NewSettings_NewMessageNotificationSoundMention,
                                             boxType: .multiple,
                                                  isOn: ops.contains(.atMe),
                                                  onClick: { [weak self] _ in
            self?.toggle(.atMe)
        })
        // at 所有人
        let atAllRow = CheckboxNormalCellProp(title: BundleI18n.LarkMine.Lark_NewSettings_MentionAllMessages,
                                                 boxType: .multiple,
                                                  isOn: ops.contains(.atAll),
                                                  onClick: { [weak self] _ in
            self?.toggle(.atAll)
        })
        // 单聊
        let singleRow = CheckboxNormalCellProp(title: BundleI18n.LarkMine.Lark_NewSettings_PrivateMessages,
                                                  boxType: .multiple,
                                                  isOn: ops.contains(.single),
                                                  onClick: { [weak self] _ in
            self?.toggle(.single)
        })
        var items = [buzzRow, atMeRow, atAllRow, singleRow]
        // 星标联系人
        let specialRow = CheckboxNormalCellProp(title: BundleI18n.LarkMine.Lark_Legacy_MuteSpecialRemindMessage,
                                                    boxType: .multiple,
                                                      isOn: ops.contains(.special),
                                                      onClick: { [weak self] _ in
            self?.toggle(.special)
        })
        items.append(specialRow)
        return SectionProp(items: items, header: .normal, footer: .normal)
    }
}

protocol INotificationSettingSpecificModuleModel {
    var setting: BehaviorRelay<SpecificNotificationOptions> { get }
    func toggle(_ ops: SpecificNotificationOptions) -> Observable<Void>
    func loadNotificationSetting()
}

final class NotificationSettingSpecificModuleModel: INotificationSettingSpecificModuleModel {
    private let userResolver: UserResolver
    private var configurationAPI: ConfigurationAPI?
    private var pushCenter: PushNotificationCenter?
    let disposeBag = DisposeBag()

    public lazy var _userStore: KVStore = {
        SettingKVStore(realStore: KVStores.udkv(space: .user(id: self.userResolver.userID), domain: Domain.biz.setting))
    }()
    static let userStore = \NotificationSettingSpecificModuleModel._userStore

    @KVBinding(to: userStore, key: KVKeys.Setting.Notification.notificationSettings)
    private var specificNotificationSetting: Settings_V1_MessengerNotificationSetting

    lazy var setting: BehaviorRelay<SpecificNotificationOptions> = {
        let options = SpecificNotificationOptions.from(pb: self.specificNotificationSetting)
        return BehaviorRelay<SpecificNotificationOptions>(value: options)
    }()

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        self.configurationAPI = try? self.userResolver.resolve(assert: ConfigurationAPI.self)
    }

    func toggle(_ op: SpecificNotificationOptions) -> Observable<Void> {
        let originSetting = self.specificNotificationSetting
        let originOps = SpecificNotificationOptions.from(pb: originSetting)
        var newOpenOps = originOps
        if newOpenOps.contains(op) {
            newOpenOps.remove(op)
        } else {
            newOpenOps.insert(op)
        }
        setting.accept(newOpenOps) // 触发界面刷新
        trackMention(newOpenOps.contains(.atMe))

        var newSetting = Settings_V1_NotificationSettingV2()
        let newSpecificSetting: Settings_V1_MessengerNotificationSetting = {
            var res = newOpenOps.toPB()
            res.switchState = originSetting.switchState
            res.specialFocusSetting = originSetting.specialFocusSetting
            return res
        }()
        newSetting.messengerNotificationSetting = newSpecificSetting
        let logger = SettingLoggerService.logger(.module("notificationSettingSpecific"))
        logger.info("api/setReq: \(newSpecificSetting)")
        return configurationAPI?
            .setNotificationSettingV2(setting: newSetting)
            .do(onNext: { [weak self] _ in
                logger.info("api/setRes: ok")
                self?.specificNotificationSetting = newSpecificSetting // 写入缓存
            }, onError: { [weak self] error in
                logger.error("api/setRes: error: \(error)")
                self?.setting.accept(originOps) // 失败回滚
            }) ?? .empty()
    }

    func loadNotificationSetting() {
        configurationAPI?.getNotificationSettingV2()
            .map { $0.messengerNotificationSetting }
            .do(onNext: { [weak self] setting in
                self?.specificNotificationSetting = setting
            })
            .map { SpecificNotificationOptions.from(pb: $0) }
            .bind(to: setting)
            .disposed(by: disposeBag)
    }

    func trackMention(_ hasMention: Bool) {
        if hasMention {
            MineTracker.trackSettingNotificationSpecificMessageMentionChoose()
        } else {
            MineTracker.trackSettingNotificationSpecificMessageMentionCancel()
        }
    }
}
