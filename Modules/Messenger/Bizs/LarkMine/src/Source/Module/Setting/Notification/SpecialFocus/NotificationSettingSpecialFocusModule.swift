//
//  NotificationSettingSpecialFocusModule.swift
//  LarkMine
//
//  Created by panbinghua on 2022/6/9.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import EENavigator
import LarkSDKInterface
import LarkContainer
import RustPB
import LarkMessengerInterface
import UniverseDesignToast
import LKCommonsTracker
import Homeric
import LarkSetting
import LarkOpenSetting
import LarkSettingUI
import LarkStorage

final class SpecialFocusSettingConfigModule: BaseModule, UITextViewDelegate {

    private var configurationAPI: ConfigurationAPI?
    private var pushCenter: PushNotificationCenter?

    override func createSectionProp(_ key: String) -> SectionProp? {
        return createSectionNotificationConfig(setting: self.setting)
    }

    override init(userResolver: UserResolver) {
        super.init(userResolver: userResolver)

        self.configurationAPI = try? self.userResolver.resolve(assert: ConfigurationAPI.self)
        self.pushCenter = try? self.userResolver.userPushCenter

        self.onRegisterDequeueViews = { tableView in
            tableView.register(HyphenSwitchNormalCell.self, forCellReuseIdentifier: "HyphenSwitchNormalCell")
        }
        self.addStateListener(.viewDidLoad) { [weak self] in
            self?.trackSpecialFocusSettigScene()
        }
        self.addStateListener(.viewWillAppear) { [weak self] in
            guard let self = self else { return }
            self.loadDatas()
        }
        allSetting
            .subscribe(onNext: { [weak self] _ in
                self?.context?.reload()
            })
            .disposed(by: disposeBag)
        self.pushCenter?.observable(for: Settings_V1_PushUserSetting.self)
            .map { $0.notificationSettingV2 }
            .do(onNext: { [weak self] setting in
                guard let self = self else { return }
                self.specificNotificationSetting = setting.messengerNotificationSetting
            })
            .bind(to: allSetting)
            .disposed(by: disposeBag)
    }

    var from: SpecialFocusSettingBody.Scene? {
        guard let scene = context?.info["scene"] as? SpecialFocusSettingBody.Scene else { return nil }
        return scene
    }

    static let userStore = \SpecialFocusSettingConfigModule._userStore

    @KVBinding(to: userStore, key: KVKeys.Setting.Notification.notificationSettings)
    private var specificNotificationSetting: Settings_V1_MessengerNotificationSetting

    // 因为修改配置，是整个通知配置一起修改的，所有需要这个
    private lazy var allSetting: BehaviorRelay<Settings_V1_NotificationSettingV2> = {
        var setting = Settings_V1_NotificationSettingV2()
        setting.messengerNotificationSetting = self.specificNotificationSetting
        return BehaviorRelay<Settings_V1_NotificationSettingV2>(value: setting)
    }()

    var setting: Settings_V1_MessengerNotificationSetting {
        return allSetting.value.messengerNotificationSetting
    }

    func changeSetting(_ setting: RustPB.Settings_V1_MessengerNotificationSetting) {
        let disableChange = setting.switchState == .closed
            || (setting.switchState == .halfOpen && !setting.specialFocusOpen)
        // 当不允许设置时，实现回弹效果
        guard !disableChange else {
            DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 0.1) {
                self.allSetting.accept(self.allSetting.value)
            }
            return
        }
        let originAllSetting = allSetting.value
        var newAllSetting = allSetting.value
        newAllSetting.messengerNotificationSetting = setting
        self.allSetting.accept(newAllSetting)
        let logger = SettingLoggerService.logger(.module(self.key))
        configurationAPI?
            .setNotificationSettingV2(setting: newAllSetting)
            .do(onNext: { [weak self] in
                guard let self = self else { return }
                self.specificNotificationSetting = newAllSetting.messengerNotificationSetting
                logger.info("api/set/req: \(newAllSetting); res: ok")
            }, onError: { [weak self] error in
                guard let self = self else { return }
                self.allSetting.accept(originAllSetting)
                logger.error("api/set/req: \(newAllSetting); res: error: \(error)")
            })
            .observeOn(MainScheduler.instance)
            .subscribe(onError: { [weak self] error in
                guard let self = self, let vc = self.context?.vc else { return }
                UDToast.showFailure(with: BundleI18n.LarkMine.Lark_Settings_BadgeStyleChangeFail,
                                    on: vc.view,
                                    error: error)
            }).disposed(by: disposeBag)
    }

    func loadDatas() {
        configurationAPI?.getNotificationSettingV2()
            .do(onNext: { [weak self] allSetting in
                guard let self = self else { return }
                self.specificNotificationSetting = allSetting.messengerNotificationSetting
                SettingLoggerService.logger(.module(self.key)).info("api/get/res: ok \(allSetting.messengerNotificationSetting)")
            })
            .bind(to: allSetting)
            .disposed(by: disposeBag)
    }

    func createSectionNotificationConfig(setting: RustPB.Settings_V1_MessengerNotificationSetting) -> SectionProp {
        var items = [CellProp]()
        // 通知为关 或者 部分新消息通知关闭星标联系人时 设置样式为关，且不能更改设置，并显示footer
        let showDisableHint = setting.switchState == .closed
            || (setting.switchState == .halfOpen && !setting.specialFocusOpen)
        let enableUI = !showDisableHint
        let showChatBoxItem = setting.specialFocusSetting.noticeInMuteChat && enableUI
        // 免打扰
        let undisturbText = BundleI18n.LarkMine.Lark_IM_ProfileSettings_VIPContactsNotificationsSettings_MutedChatsNotify
        let undisturbRow = SwitchNormalCellProp(title: undisturbText,
                                                       isOn: enableUI && setting.specialFocusSetting.noticeInMuteChat,
                                                       separatorLineStyle: showChatBoxItem ? .none : .normal,
                                                       onSwitch: { [weak self] _, isOn in
            guard let self = self else { return }
            var newSetting = setting
            newSetting.specialFocusSetting.noticeInMuteChat.toggle()
            self.changeSetting(newSetting)
            self.trackChange(isOn: isOn, click: "notice_in_mute_filter")
        })
        items.append(undisturbRow)
        // 会话盒子
        if showChatBoxItem {
            let chatBoxText = BundleI18n.LarkMine.Lark_Core_StarContactNotificationSettings_CollapsedChatsNotify
            let chatBoxRow = SwitchNormalCellProp(title: chatBoxText,
                                                         isOn: enableUI && setting.specialFocusSetting.noticeInChatBox,
                                                         cellIdentifier: "HyphenSwitchNormalCell",
                                                         onSwitch: { [weak self] _, isOn in
                guard let self = self else { return }
                var newSetting = setting
                newSetting.specialFocusSetting.noticeInChatBox.toggle()
                self.changeSetting(newSetting)
                self.trackChange(isOn: isOn, click: "notice_in_chatbox")
           })
            items.append(chatBoxRow)
        }
        // 禁音仍通知
        let notificationMuteText = BundleI18n.LarkMine.Lark_IM_ProfileSettings_VIPContactsNotificationsSettings_AllMuted
        let notificationMuteRow = SwitchNormalCellProp(title: notificationMuteText,
                                                              isOn: enableUI && setting.specialFocusSetting.noticeInMuteMode,
                                                              onSwitch: { [weak self] _, isOn in
            guard let self = self else { return }
            var newSetting = setting
            newSetting.specialFocusSetting.noticeInMuteMode.toggle()
            self.changeSetting(newSetting)
            self.trackChange(isOn: isOn, click: "notice_in_mute")
        })
        items.append(notificationMuteRow)
        let footer: HeaderFooterType = showDisableHint ? .custom({ self.goMessageSettingFooter }) : .normal
        return SectionProp(items: items, header: .normal, footer: footer)
    }

    private lazy var goMessageSettingView: UITextView = {
        let textview = UITextView()
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.maximumLineHeight = 20
        paragraphStyle.minimumLineHeight = 20
        paragraphStyle.lineSpacing = 0
        let attrStr = NSMutableAttributedString(string: BundleI18n.LarkMine.Lark_IM_ProfileSettings_VIPContactsNotificationsSettings_UMutedAllNotificationsFromVIPContactsRevise,
                                                attributes: [.font: UIFont.systemFont(ofSize: 14),
                                                             .paragraphStyle: paragraphStyle,
                                                             .foregroundColor: UIColor.ud.textPlaceholder])
        attrStr.append(NSAttributedString(string: "  "))
        attrStr.append(NSAttributedString(string: BundleI18n.LarkMine.Lark_IM_ProfileSettings_VIPContactsNotifications_GoToSettings,
                                          attributes: [.link: ""]))
        textview.linkTextAttributes = [.font: UIFont.systemFont(ofSize: 14),
                                       .paragraphStyle: paragraphStyle,
                                       .foregroundColor: UIColor.ud.textLinkNormal]
        textview.attributedText = attrStr
        textview.backgroundColor = .clear
        textview.isEditable = false
        textview.isSelectable = true
        textview.textDragInteraction?.isEnabled = false
        textview.isScrollEnabled = false
        textview.showsVerticalScrollIndicator = false
        textview.showsHorizontalScrollIndicator = false
        textview.delegate = self
        textview.textContainerInset = .zero
        textview.textContainer.lineFragmentPadding = 0
        return textview
    }()

    private lazy var goMessageSettingFooter: UITableViewHeaderFooterView = { [weak self] () -> UITableViewHeaderFooterView in
        let view = UITableViewHeaderFooterView()
        guard let self = self else { return view }
        view.contentView.addSubview(self.goMessageSettingView)
        self.goMessageSettingView.snp.makeConstraints {
            $0.top.equalTo(4)
            $0.bottom.equalToSuperview()
            $0.left.equalTo(16)
            $0.right.equalTo(-16)
        }
        return view
    }()
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if let vc = self.context?.vc, interaction == .invokeDefaultAction {
            // 去到通知设置页
            let body = MineNotificationSettingBody()
            self.userResolver.navigator.push(body: body, from: vc)
        }
        return false
    }
}

// MARK: 埋点
extension SpecialFocusSettingConfigModule {
    func trackChange(isOn: Bool, click: String) {
        var params: [AnyHashable: Any] = [:]
        params["click"] = click
        params["target"] = "setting_starred_contact_view"
        params["status"] = isOn ? "off_to_on" : "on_to_off"
        if let from = self.from {
            params["scene"] = from.rawValue
        }
        Tracker.post(TeaEvent(Homeric.SETTING_STARRED_CONTACT_CLICK, params: params))
    }

    func trackSpecialFocusSettigScene() {
        if let from = self.from {
            Tracker.post(TeaEvent(Homeric.SETTING_STARRED_CONTACT_VIEW, params: ["scene": from.rawValue]))
        }
    }
}

final class SpecialFocusSettingNumberModule: BaseModule {

    lazy var numberOfSpecialFocusRelay = BehaviorRelay<Int>(value: 0)

    override func createSectionProp(_ key: String) -> SectionProp? {
        return createSectionSpecialFocusContact(num: self.numberOfSpecialFocusRelay.value)
    }

    func createSectionSpecialFocusContact(num: Int) -> SectionProp {
        let row = NormalCellProp(title: BundleI18n.LarkMine.Lark_IM_ProfileSettings_VIPContactsNotificationsSettings_ViewAllContacts,
                                        accessories: [NormalCellAccessory(.text("\(num)"), spacing: 4),
                                                      NormalCellAccessory(.arrow)],
                                         onClick: { [weak self] _ in
            guard let self = self, let vc = self.context?.vc else { return }
            let body = SpecialFocusListBody()
            self.userResolver.navigator.push(body: body, from: vc)
            self.trackGoToSpecialFocusList()
        })
        return SectionProp(items: [row], header: .normal, footer: .normal)
    }

    func loadDatas() {
        let chatterAPI = try? self.userResolver.resolve(assert: ChatterAPI.self)
        chatterAPI?.getSpecialFocusChatterList()
            .map { $0.count }
            .catchErrorJustReturn(0)
            .bind(to: numberOfSpecialFocusRelay)
            .disposed(by: disposeBag)
    }

    override init(userResolver: UserResolver) {
        super.init(userResolver: userResolver)
        self.addStateListener(.viewWillAppear) { [weak self] in
            guard let self = self else { return }
            self.loadDatas()
        }
        numberOfSpecialFocusRelay
            .subscribe(onNext: { [weak self] _ in
                self?.context?.reload()
            })
            .disposed(by: disposeBag)
    }
}

// MARK: 埋点
extension SpecialFocusSettingNumberModule {
    func trackGoToSpecialFocusList() {
        var params: [AnyHashable: Any] = [:]
        params["click"] = "starred_contact_list"
        params["target"] = "contact_starred_contact_view"
        Tracker.post(TeaEvent(Homeric.SETTING_DETAIL_CLICK, params: params))
    }
}
