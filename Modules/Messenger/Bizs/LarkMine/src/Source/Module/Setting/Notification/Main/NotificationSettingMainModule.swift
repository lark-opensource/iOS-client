//
//  NotificationSettingMainModule.swift
//  LarkMine
//
//  Created by panbinghua on 2022/6/27.
//

import Foundation
import EENavigator
import LarkContainer
import LarkSetting
import LarkMessengerInterface
import Swinject
import LarkSDKInterface
import RustPB
import RxSwift
import RxCocoa
import UniverseDesignToast
import LarkOpenSetting
import LarkStorage
import LarkSettingUI
import LarkAccountInterface

struct SpecificNotificationOptions: OptionSet {
    let rawValue: Int
    static let buzz = SpecificNotificationOptions(rawValue: 1 << 0)
    static let atMe = SpecificNotificationOptions(rawValue: 1 << 1)
    static let atAll = SpecificNotificationOptions(rawValue: 1 << 2)
    static let single = SpecificNotificationOptions(rawValue: 1 << 3)
    static let special = SpecificNotificationOptions(rawValue: 1 << 4)

    func toPB() -> Settings_V1_MessengerNotificationSetting {
        var setting = Settings_V1_MessengerNotificationSetting()
        setting.buzzOpen = true
        setting.mentionOpen = self.contains(.atMe)
        setting.mentionAllOpen = self.contains(.atAll)
        setting.userP2PChatOpen = self.contains(.single)
        setting.specialFocusOpen = self.contains(.special)
        return setting
    }

    static func from(pb setting: Settings_V1_MessengerNotificationSetting) -> SpecificNotificationOptions {
        var ops: SpecificNotificationOptions = []
        ops.insert(.buzz)
        if setting.mentionOpen { ops.insert(.atMe) }
        if setting.mentionAllOpen { ops.insert(.atAll) }
        if setting.userP2PChatOpen { ops.insert(.single) }
        if setting.specialFocusOpen { ops.insert(.special) }
        return ops
    }
}

extension Settings_V1_MessengerNotificationSetting {
    // 只有mentionOpen等open结尾的bool值，不包含switchStatus和specialFocusSetting
    static func from(rawValue: Int) -> Self {
        return SpecificNotificationOptions(rawValue: rawValue).toPB()
    }

    var rawValue: Int {
        return SpecificNotificationOptions.from(pb: self).rawValue
    }

    func getOptionStrings() -> [String] {
        var ops = [String]()
        ops.append(BundleI18n.LarkMine.Lark_IM_NotificationsSettings_EnabledOptions_Buzz)
        if self.mentionOpen { ops.append(BundleI18n.LarkMine.Lark_IM_NotificationsSettings_EnabledOptions_MentionMe) }
        if self.mentionAllOpen { ops.append(BundleI18n.LarkMine.Lark_IM_NotificationsSettings_EnabledOptions_MentionAll) }
        if self.userP2PChatOpen { ops.append(BundleI18n.LarkMine.Lark_IM_NotificationsSettings_EnabledOptions_PrivateChats) }
        if self.specialFocusOpen {
            ops.append(BundleI18n.LarkMine.Lark_IM_NotificationsSettings_EnabledOptions_StarredContacts)
        }
        return ops
    }

    func getTrack() -> String {
        var ops = [String]()
        ops.append("buzz")
        if self.mentionOpen { ops.append("mention") }
        if self.userP2PChatOpen { ops.append("single") }
        return ops.joined(separator: "&")
    }
}

final class NotificationSettingContext: ModuleContext {
    let offDuringCallsSubject = PublishRelay<Bool>()
    let notificationSettingSubject = PublishRelay<Settings_V1_MessengerNotificationSetting>()
    override init() {
        super.init()
    }
}

final class NotificationSettingViewController: SettingViewController {
    private var configurationAPI: ConfigurationAPI?
    private var pushCenter: PushNotificationCenter?
    private let userResolver: UserResolver

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        let context = NotificationSettingContext()
        super.init(name: Page.notification.rawValue, context: context)
        self.navTitle = BundleI18n.LarkMine.Lark_NewSettings_NewMessageNotifications
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let logger = SettingLoggerService.logger(.page(page))

        self.configurationAPI = try? self.userResolver.resolve(assert: ConfigurationAPI.self)
        self.pushCenter = try? self.userResolver.userPushCenter

        self.configurationAPI?.getMostUserSetting()
            .map { ($0.notificationSettingV2.messengerNotificationSetting, $0.messageNotificationsOffDuringCalls) }
            .subscribe(onNext: { [weak self] (notificationSetting, offDuringCalls) in
                guard let context = self?.context as? NotificationSettingContext else { return }
                context.notificationSettingSubject.accept(notificationSetting)
                context.offDuringCallsSubject.accept(offDuringCalls)
                logger.info("api/mostUserSetting/get/res: ok  offDuringCalls: \(offDuringCalls), setting :\(notificationSetting)")
            }, onError: { error in
                logger.error("api/mostUserSetting/get/error: \(error)")
            }).disposed(by: self.disposeBag)
        self.pushCenter?.observable(for: Settings_V1_PushUserSetting.self)
            .subscribe(onNext: { [weak self] allSettings in
                guard let context = self?.context as? NotificationSettingContext else { return }
                context.notificationSettingSubject.accept(allSettings.notificationSettingV2.messengerNotificationSetting)
                context.offDuringCallsSubject.accept(allSettings.messageNotificationsOffDuringCalls)
                logger.info("api/mostUserSetting/push/offDuringCalls: \(allSettings.messageNotificationsOffDuringCalls) setting :\(allSettings.notificationSettingV2.messengerNotificationSetting)")
            }).disposed(by: self.disposeBag)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension Settings_V1_MessengerNotificationSetting.SpecialFocus: Codable, CustomStringConvertible {
    enum CodingKeys: CodingKey {
        case noticeInMuteChat
        case noticeInMuteMode
        case noticeInChatBox
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.init()
        self.noticeInMuteChat = try values.decode(Bool.self, forKey: .noticeInMuteChat)
        self.noticeInMuteMode = try values.decode(Bool.self, forKey: .noticeInMuteMode)
        self.noticeInChatBox = try values.decode(Bool.self, forKey: .noticeInChatBox)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(noticeInMuteChat, forKey: .noticeInMuteChat)
        try container.encode(noticeInMuteMode, forKey: .noticeInMuteMode)
        try container.encode(noticeInChatBox, forKey: .noticeInChatBox)
    }

    public var description: String {
        return "muteChat: \(noticeInMuteChat), muteMode: \(noticeInMuteMode), chatBox: \(noticeInChatBox)"
    }
}

extension Settings_V1_MessengerNotificationSetting: Codable, CustomStringConvertible {

    enum CodingKeys: CodingKey {
        case switchState
        case buzzOpen
        case mentionOpen
        case mentionAllOpen
        case userP2PChatOpen
        case specialFocusOpen
        case specialSetting
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let stateValue = try values.decode(Int.self, forKey: .switchState)
        self.init()
        self.switchState = .init(rawValue: stateValue) ?? .open
        self.buzzOpen = true
        self.mentionOpen = try values.decode(Bool.self, forKey: .mentionOpen)
        self.mentionAllOpen = try values.decode(Bool.self, forKey: .mentionAllOpen)
        self.userP2PChatOpen = try values.decode(Bool.self, forKey: .userP2PChatOpen)
        self.specialFocusOpen = try values.decode(Bool.self, forKey: .specialFocusOpen)
        self.specialFocusSetting = try values.decode(Settings_V1_MessengerNotificationSetting.SpecialFocus.self,
                                                     forKey: .specialSetting)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(switchState.rawValue, forKey: .switchState)
        try container.encode(buzzOpen, forKey: .buzzOpen)
        try container.encode(mentionOpen, forKey: .mentionOpen)
        try container.encode(mentionAllOpen, forKey: .mentionAllOpen)
        try container.encode(userP2PChatOpen, forKey: .userP2PChatOpen)
        try container.encode(specialFocusOpen, forKey: .specialFocusOpen)
        try container.encode(specialFocusSetting, forKey: .specialSetting)
    }

    public var description: String {
        return "switchState: \(switchState.rawValue), buzzOpen: \(buzzOpen), mentionOpen: \(mentionOpen),"
            + " mentionAllOpen: \(mentionAllOpen), userP2PChatOpen: \(userP2PChatOpen), specialFocusOpen: \(specialFocusOpen),"
            + " specialFocusSetting: \(specialFocusSetting)"
    }
}

final class NotificationSettingMainModule: BaseModule {

    private var configurationAPI: ConfigurationAPI?

    static let userStore = \NotificationSettingMainModule._userStore

    @KVBinding(to: userStore, key: KVKeys.SettingStore.Notification.offDuringCalls)
    private var offDuringCalls: Bool

    @KVBinding(to: userStore, key: KVKeys.Setting.Notification.notificationSettings)
    private var specificNotificationSetting: Settings_V1_MessengerNotificationSetting

    private var rxOffDuringCalls: Binder<Bool> {
        return Binder(self) { module, offDuringCalls in
            module.offDuringCalls = offDuringCalls
        }
    }

    private var rxNotificationSetting: Binder<Settings_V1_MessengerNotificationSetting> {
        return Binder(self) { module, notificationSetting in
            module.specificNotificationSetting = notificationSetting
        }
    }

    private var rxReload: Binder<Void> {
        return Binder(self) { module, _  in
            module.context?.reload()
        }
    }

    override init(userResolver: UserResolver) {
        super.init(userResolver: userResolver)

        self.configurationAPI = try? self.userResolver.resolve(assert: ConfigurationAPI.self)

        self.onRegisterDequeueViews = { tableView in
            tableView.register(RadioButtonCell.self, forCellReuseIdentifier: "RadioButtonCell")
        }
        self.addStateListener(.viewDidLoad) { [weak self] in
            guard let self = self,
                  let context = self.context as? NotificationSettingContext else {
                return
            }
            context.offDuringCallsSubject
                .bind(to: self.rxOffDuringCalls)
                .disposed(by: self.disposeBag)
            context.notificationSettingSubject
                .bind(to: self.rxNotificationSetting)
                .disposed(by: self.disposeBag)
            Observable.merge(context.offDuringCallsSubject.map { _ in Void() },
                             context.notificationSettingSubject.map { _ in Void() })
                .bind(to: self.rxReload)
                .disposed(by: self.disposeBag)
        }

        NotificationCenter.default.rx.notification(MultiUserActivitySwitch.enableMultipleUserRealtimeChanged)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                guard let self = self else { return }
                self.context?.reload()
            }).disposed(by: disposeBag)
    }

    override func createSectionProp(_ key: String) -> SectionProp? {
        if key == ModulePair.Notification.main.createKey {
            return createMainSection()
        } else if key == ModulePair.Notification.specialFocus.createKey {
            return createSpecialFocusSection()
        } else if key == ModulePair.Notification.multiUserNotification.createKey {
            return createMultiUserNotificationSection()
        } else if key == ModulePair.Notification.offDuringCalls.createKey {
            return createOffDuringCallsSection()
        }
        return nil
    }
}

// 入口
extension NotificationSettingMainModule {
    func createSpecialFocusSection() -> SectionProp? {
        let item = NormalCellProp(title: BundleI18n.LarkMine.Lark_IM_ProfileSettings_VIPContactsNotificationsSettings,
                                         accessories: [.arrow()],
                                         onClick: { [weak self] _ in
            guard let vc = self?.context?.vc else { return }
            self?.userResolver.navigator.push(body: SpecialFocusSettingBody(from: .setting), from: vc)
        })
        return SectionProp(items: [item])
    }
}

// 以下情况通知我
extension NotificationSettingMainModule {

    func createMainSection() -> SectionProp? {
        let isEditButtonEnabled = specificNotificationSetting.switchState == .halfOpen
        let commaStr = BundleI18n.LarkMine.Lark_IM_NotificationsSettings_EnabledOptions_Comma
        let optionStrs = specificNotificationSetting.getOptionStrings()
        let detail = optionStrs.isEmpty ? " " : optionStrs.joined(separator: commaStr)
        let all = CheckboxNormalCellProp(title: BundleI18n.LarkMine.Lark_NewSettings_MessageNotificationScopeAllMobile,
                                             isOn: specificNotificationSetting.switchState == .open,
                                             id: MineNotificationSettingBody.ItemKey.NotifyScopeAll.rawValue,
                                         onClick: { [weak self] _ in
            self?.setNotificationSetting(to: .open)
        })
        let partial = RadioButtonCellProp(title: BundleI18n.LarkMine.Lark_NewSettings_MessageNotificationScopePartialMobile,
                                               detail: detail,
                                               isOn: specificNotificationSetting.switchState == .halfOpen,
                                               isEditButtonEnabled: isEditButtonEnabled,
                                               id: MineNotificationSettingBody.ItemKey.NotifyScopePartial.rawValue,
                                         onClick: { [weak self] _ in
            self?.setNotificationSetting(to: .halfOpen)
        }, onClickButton: { [weak self] _ in
            guard let `self` = self else { return }
            guard let from = self.context?.vc else { return }
            MineTracker.trackSettingNotificationSpecificMessageEdit()
            let vc = PageFactory.shared.generate(userResolver: self.userResolver, page: .notificationSpecific)
            vc.navTitle = BundleI18n.LarkMine.Lark_NewSettings_MessageNotificationScopePartialMobile
            self.userResolver.navigator.push(vc, from: from)
        })
        let none = CheckboxNormalCellProp(title: BundleI18n.LarkMine.Lark_NewSettings_MessageNotificationNoneMobile,
                                              isOn: specificNotificationSetting.switchState == .closed,
                                              id: MineNotificationSettingBody.ItemKey.NotifyScopeNone.rawValue,
                                         onClick: { [weak self] _ in
            self?.setNotificationSetting(to: .closed)
        })
        let footer: HeaderFooterType = specificNotificationSetting.switchState == .open ? .normal : .title(BundleI18n.LarkMine.Lark_NewSettings_StillShowNumberOfAllUnreadMessages)
        let header: HeaderFooterType = .title(BundleI18n.LarkMine.Lark_NewSettings_MessageNotificationScopeMobile)
        return SectionProp(items: [all, partial, none], header: header, footer: footer)
    }

    private func setNotificationSetting(to state: Settings_V1_MessengerNotificationSetting.SwithState) {
        // 如果当前值未发生改变，则不用处理
        guard specificNotificationSetting.switchState != state else { return }
        let originSetting = specificNotificationSetting

        var newSpecificSetting = specificNotificationSetting
        newSpecificSetting.switchState = state
        var newAllSetting = Settings_V1_NotificationSettingV2()
        newAllSetting.messengerNotificationSetting = newSpecificSetting
        specificNotificationSetting = newSpecificSetting
        self.context?.reload()

        let logger = SettingLoggerService.logger(.module(self.key))
        self.configurationAPI?.setNotificationSettingV2(setting: newAllSetting)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {
                logger.info("api/notificationSetting/set/req: \(newAllSetting); res: ok")
                switch state {
                case .open:
                    MineTracker.trackSettingNotificationAllNewMessage()
                case .halfOpen:
                    // 单聊埋点
                    let track = newAllSetting.messengerNotificationSetting.getTrack()
                    MineTracker.trackSettingNotificationSpecificMessage(setting: track)
                case .closed:
                    MineTracker.trackSettingNotificationNothing()
                case .unknownState: break
                @unknown default: break
                }
            }, onError: { [weak self] error in
                guard let self = self, let vc = self.context?.vc else { return }
                logger.error("api/notificationSetting/set/req: \(newAllSetting); res: error", error: error)
                UDToast.showFailure(with: BundleI18n.LarkMine.Lark_Settings_BadgeStyleChangeFail, on: vc.view, error: error)
                self.specificNotificationSetting = originSetting
                self.context?.reload()
            }).disposed(by: disposeBag)
    }
}

// 会议中是否提醒我
extension NotificationSettingMainModule {
    func createOffDuringCallsSection() -> SectionProp? {
        let item = SwitchNormalCellProp(title: BundleI18n.LarkMine.Lark_NewSettings_MessageNotificationsOffDuringCalls,
                                               isOn: offDuringCalls,
                                               id: MineNotificationSettingBody.ItemKey.OffDuringCalls.rawValue) { [weak self] _, isOn in
            self?.setNotificationSetting(offDuringCalls: isOn)
        }
        return SectionProp(items: [item])
    }

    func setNotificationSetting(offDuringCalls: Bool) {
        guard self.offDuringCalls != offDuringCalls else { return }
        let tempOldDuringCallsSetting = self.offDuringCalls
        let logger = SettingLoggerService.logger(.module(self.key))
        self.configurationAPI?.setNotificationSetting(setting: nil, messageNotificationsOffDuringCallsSetting: offDuringCalls)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {
                logger.info("api/offDuringCalls/set/req: \(offDuringCalls); res: ok")
            }, onError: { [weak self] error in
                guard let self = self, let vc = self.context?.vc else { return }
                UDToast.showFailure(with: BundleI18n.LarkMine.Lark_Settings_BadgeStyleChangeFail, on: vc.view, error: error)
                self.offDuringCalls = tempOldDuringCallsSetting
                self.context?.reload()
                logger.error("api/offDuringCalls/set/req: \(offDuringCalls); res: error: \(error)")
        }).disposed(by: self.disposeBag)
    }
}
