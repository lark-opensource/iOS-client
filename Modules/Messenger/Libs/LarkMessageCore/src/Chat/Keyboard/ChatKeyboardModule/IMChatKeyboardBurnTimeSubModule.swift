//
//  IMChatKeyboardBurnTimeSubModule.swift
//  LarkChat
//
//  Created by liluobin on 2023/4/10.
//

import UIKit
import LarkBaseKeyboard
import LarkChatOpenKeyboard
import LarkOpenKeyboard
import LarkKeyboardView
import RxSwift
import LarkModel
import UniverseDesignToast
import LarkAccountInterface
import LarkSDKInterface
import LarkContainer
import LKCommonsLogging
import LarkChatKeyboardInterface

class KeyboardBurnTimePanelLogger {
    static let logger = Logger.log(KeyboardBurnTimePanelLogger.self, category: "Module.Inputs")
}

public class IMChatKeyboardBurnTimePanelSubModule: IMKeyboardBurnTimePanelSubModule<KeyboardContext> {}

public class IMComposeKeyboardBurnTimePanelSubModule: IMKeyboardBurnTimePanelSubModule<IMComposeKeyboardContext> {
    public override var itemTintColor: UIColor {
        return ComposeKeyboardPageItem.iconColor
    }
}

public class IMKeyboardBurnTimePanelSubModule<C: KeyboardContext>: KeyboardPanelBurnTimeSubModule<C, IMKeyboardMetaModel> {

    open var logPrefix: String { return " chat " }

    static var logger: Log { return KeyboardBurnTimePanelLogger.logger }

    let disposeBag = DisposeBag()

    @ScopedInjectedLazy var chatAPI: ChatAPI?

    private var itemConfig: ChatKeyboardBurnTimeItemConfig? {
        return try? context.userResolver.resolve(assert: ChatOpenKeyboardItemConfigService.self).getChatKeyboardItemFor(self.panelItemKey)
    }

    /// 子类可以重写 默认iconN2
    open var itemTintColor: UIColor {
        return UIColor.ud.iconN2
    }

    public override var metaModel: IMKeyboardMetaModel? {
        didSet {
            guard let chat = self.metaModel?.chat else { return }
            if chat.enableMessageBurn != oldValue?.chat.enableMessageBurn {
                Self.logger.info("chat restrictedModeSetting onTimeDelMsgSetting enableMessageBurn \(chat.id) \(chat.enableMessageBurn)")
                if !chat.enableMessageBurn {
                    if self.item != nil {
                        self.item = nil
                        self.context.reloadPaneItems()
                    }
                    return
                } else {
                    if self.item == nil {
                        self.context.reloadPaneItems()
                        return
                    }
                }
            }

            guard self.item != nil else { return }
            if chat.restrictedModeSetting.onTimeDelMsgSetting.aliveTime !=
                oldValue?.chat.restrictedModeSetting.onTimeDelMsgSetting.aliveTime {
                Self.logger.info("\(self.logPrefix) restrictedModeSetting onTimeDelMsgSetting aliveTime \(chat.id) \(chat.restrictedModeSetting.onTimeDelMsgSetting.aliveTime)")
                let icons = BurnTimeProps.getBurnTimeIcon(Int64(chat.restrictedModeSetting.onTimeDelMsgSetting.aliveTime),
                                                          tintColor: itemTintColor)
                self.item?.keyboardIcon = (icons.0, icons.1, nil)
                self.context.keyboardPanel.reloadPanelBtn(key: KeyboardItemKey.burnTime.rawValue)
            }
        }
    }

    public override func didCreatePanelItem() -> InputKeyboardItem? {
        guard let chat = self.metaModel?.chat, chat.enableMessageBurn else {
            self.item = nil
            return nil
        }
        return LarkKeyboard.buildBurnTime(tintColor: UIColor.ud.iconN2,
                                          targetViewController: context.displayVC,
                                          canChangeTime: { [weak self] in
            if let chat = self?.metaModel?.chat {
                return (chat.ownerId == self?.context.userID ?? "") || chat.isGroupAdmin || chat.type == .p2P
            }
            return false
        },
                                          currenBurnLife: { [weak self] in
            return Int64(self?.metaModel?.chat.restrictedModeSetting.onTimeDelMsgSetting.aliveTime ?? 0)
        },
                                          willShowBurnTimeSelectSheet: { [weak self] in
            self?.foldKeyboard()
            return self?.getBurnTimeView()
        },
                                          selectedNewBurnLife: { [weak self] time in
            self?.itemConfig?.uiConfig?.tappedBlock?()
            /// update burn life icon
            let newBurnLifeIcon = BurnTimeProps.getBurnTimeIcon(time, tintColor: UIColor.ud.iconN2)
            guard let item = self?.item else {
                return
            }
            let oldIcon = item.keyboardIcon
            self?.item?.keyboardIcon = (newBurnLifeIcon.0, newBurnLifeIcon.1, nil)
            self?.context.reloadPaneItems()

            var restrictedModeSetting = Chat.RestrictedModeSetting()
            var timeSetting = Chat.RestrictedModeSetting.OnTimeDelMsgSetting()
            timeSetting.aliveTime = time
            restrictedModeSetting.onTimeDelMsgSetting = timeSetting
            guard let self = self else { return }
            self.chatAPI?.updateChat(chatId: chat.id, restrictedModeSetting: restrictedModeSetting)
                .observeOn(MainScheduler.instance)
                .subscribe(onError: { [weak self] (error) in
                    UDToast.showFailure(with: BundleI18n.LarkMessageCore.Lark_Legacy_ErrorMessageTip,
                                        on: self?.context.displayVC.view ?? UIView(),
                                        error: error)
                    self?.item?.keyboardIcon = oldIcon
                    self?.context.reloadPaneItems()
                    Self.logger.error(
                        "\(self?.logPrefix) update chat burn life error",
                        additionalData: ["chatId": chat.id],
                        error: error
                    )
                }).disposed(by: self.disposeBag)
        })
    }
}
