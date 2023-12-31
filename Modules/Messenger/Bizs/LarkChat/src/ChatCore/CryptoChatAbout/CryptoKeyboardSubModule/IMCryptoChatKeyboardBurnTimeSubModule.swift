//
//  IMCryptoChatKeyboardBurnTimeSubModule.swift
//  LarkChat
//
//  Created by liluobin on 2023/4/10.
//

import UIKit
import LarkContainer
import LarkBaseKeyboard
import LarkOpenKeyboard
import LarkChatOpenKeyboard
import LarkKeyboardView
import LarkMessengerInterface
import LarkActionSheet
import LarkSDKInterface
import RxSwift
import EENavigator
import LKCommonsLogging

// MARK: - Secret chat burn time
struct CryptoBurnTimeProps {
    var time: Int32
    var title: String
    var icon: (normal: UIImage, highlight: UIImage)
    var isSelected: Bool

    static let minutes_1: Int32 = 60
    static let hours_1: Int32 = 60 * CryptoBurnTimeProps.minutes_1
    static let day_1: Int32 = 24 * CryptoBurnTimeProps.hours_1
    static let week_1: Int32 = 7 * CryptoBurnTimeProps.day_1

    static func createBurnTimeSource(_ burnLife: Int32) -> [CryptoBurnTimeProps] {
        let sources: [CryptoBurnTimeProps] = [
            /// 1m
            CryptoBurnTimeProps(
                time: CryptoBurnTimeProps.minutes_1,
                title: String(format: BundleI18n.LarkChat.Lark_Legacy_SecretChatBurnAfterTimeMinutes, 1),
                icon: (normal: Resources.secret_1m, highlight: Resources.secret_1m_select),
                isSelected: (CryptoBurnTimeProps.minutes_1 == burnLife)
            ),
            /// 1h
            CryptoBurnTimeProps(
                time: CryptoBurnTimeProps.hours_1,
                title: String(format: BundleI18n.LarkChat.Lark_Legacy_SecretChatBurnAfterTimeHours, 1),
                icon: (normal: Resources.secret_1h, highlight: Resources.secret_1h_select),
                isSelected: (CryptoBurnTimeProps.hours_1 == burnLife)
            ),
            /// 1d
            CryptoBurnTimeProps(
                time: CryptoBurnTimeProps.day_1,
                title: String(format: BundleI18n.LarkChat.Lark_Legacy_SecretChatBurnAfterTimeDay, 1),
                icon: (normal: Resources.secret_1d, highlight: Resources.secret_1d_select),
                isSelected: (CryptoBurnTimeProps.day_1 == burnLife)
            ),
            /// 1w
            CryptoBurnTimeProps(
                time: CryptoBurnTimeProps.week_1,
                title: String(format: BundleI18n.LarkChat.Lark_Legacy_SecretChatBurnAfterTimeWeek, 1),
                icon: (normal: Resources.secret_1w, highlight: Resources.secret_1w_select),
                isSelected: (CryptoBurnTimeProps.week_1 == burnLife)
            )
        ]
        return sources
    }

    static func getBurnTimeIcon(_ burnLife: Int32, tintColor: UIColor) -> (UIImage?, UIImage?) {
        var normal: UIImage?
        var select: UIImage?
        if burnLife == CryptoBurnTimeProps.minutes_1 {
            normal = Resources.secret_1m
            select = Resources.secret_1m_select
        } else if burnLife == CryptoBurnTimeProps.hours_1 {
            normal = Resources.secret_1h
            select = Resources.secret_1h_select
        } else if burnLife == CryptoBurnTimeProps.day_1 {
            normal = Resources.secret_1d
            select = Resources.secret_1d_select
        } else if burnLife == CryptoBurnTimeProps.week_1 {
            normal = Resources.secret_1w
            select = Resources.secret_1w_select
        } else {
            return (nil, nil)
        }
        return (normal?.ud.withTintColor(tintColor), select?.ud.withTintColor(tintColor))
    }
}

public class IMCryptoChatKeyboardBurnTimeSubModule: BaseKeyboardPanelDefaultSubModule<KeyboardContext, IMKeyboardMetaModel> {

    static let logger = Logger.log(IMCryptoChatKeyboardBurnTimeSubModule.self, category: "Module.Inputs")

    let disposeBag = DisposeBag()

    @ScopedInjectedLazy private var secretChatService: SecretChatService?
    @ScopedInjectedLazy var chatAPI: ChatAPI?

    open override var panelItemKey: KeyboardItemKey {
        return .cryptoBurnTime
    }

    public override var metaModel: IMKeyboardMetaModel? {
        didSet {
            guard self.item != nil, let chat = self.metaModel?.chat, let secretChatService else { return }
            if chat.burnLife != oldValue?.chat.burnLife {
                let icons = CryptoBurnTimeProps.getBurnTimeIcon(chat.burnLife,
                                                                tintColor: secretChatService.keyboardItemsTintColor)
                self.item?.keyboardIcon = (icons.0, icons.1, nil)
                self.context.reloadPaneItems()
            }
        }
    }

    public override func didCreatePanelItem() -> InputKeyboardItem? {
        guard let chat = self.metaModel?.chat, let secretChatService else { return nil }
        let group = chat.type == .group
        let (burnNormal, burnHighlight) = CryptoBurnTimeProps.getBurnTimeIcon(chat.burnLife,
                                                                        tintColor: secretChatService.keyboardItemsTintColor)
        let item = InputKeyboardItem(key: KeyboardItemKey.cryptoBurnTime.rawValue, keyboardViewBlock: { () -> UIView in
            return UIView()
        }, keyboardHeightBlock: { 0 }, keyboardIcon: (burnNormal, burnHighlight, nil)) { [weak self, navigator] in
            self?.foldKeyboard()
            guard let itemView = self?.getBurnTimeView() else { return false }
            let adapter = ActionSheetAdapter()
            /// Tips
            let actionSheet = adapter.create(
                level: .normal(source: itemView.defaultSource),
                title: BundleI18n.LarkChat.Lark_Legacy_SecretChatBurnTime
            )
            /// Burn time
            let burnTimeItemAction: (Int32) -> Void = { [weak self] (time) in
                guard let self = self else { return }
                /// update burn life icon
                let newBurnLifeIcon = CryptoBurnTimeProps.getBurnTimeIcon(time, tintColor: self.secretChatService?.keyboardItemsTintColor ?? UIColor.ud.iconN3)
                self.item?.keyboardIcon = (newBurnLifeIcon.0, newBurnLifeIcon.1, nil)
                self.context.reloadPaneItems()
                /// update chat burn life
                self.chatAPI?.updateChat(chatId: chat.id, burnLife: Int32(time))
                    .observeOn(MainScheduler.instance)
                    .subscribe(onError: { (error) in
                        Self.logger.error(
                            "update chat burn life error",
                            additionalData: ["chatId": chat.id ?? ""],
                            error: error
                        )
                    }).disposed(by: self.disposeBag)
            }

            for props in CryptoBurnTimeProps.createBurnTimeSource(self?.metaModel?.chat.burnLife ?? 0) {
                adapter.addItem(title: props.title, textColor: props.isSelected ? UIColor.ud.textLinkHover : UIColor.ud.textTitle) {
                    burnTimeItemAction(props.time)
                }
            }
            /// cancel
            adapter.addCancelItem(title: BundleI18n.LarkChat.Lark_Legacy_Cancel)
            guard let vc = self?.context.displayVC else {
                assertionFailure()
                return false
            }
            navigator.present(actionSheet, from: vc)
            return false
        }
        return item

    }

    func getBurnTimeView() -> UIView? {
        return context.keyboardPanel.buttons.first { btn in
            return btn.key == KeyboardItemKey.cryptoBurnTime.rawValue
        }
    }
}
