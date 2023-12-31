//
//  PinMessageMenuManagerImpl.swift
//  LarkChat
//
//  Created by zc09v on 2019/9/24.
//

import UIKit
import Foundation
import EENavigator
import LarkMessageBase
import LarkModel
import LarkActionSheet
import LarkUIKit
import LarkMessageCore
import LarkOpenChat

protocol PinMenuService {
    func show(vc: UIViewController, message: Message, chat: Chat, info: MessageMenuInfo)
}
final class DefaultPinMenuService: PinMenuService {
    func show(vc: UIViewController, message: Message, chat: Chat, info: MessageMenuInfo) {}
}
final class PinMenuServiceImp: PinMenuService {
    private let actionModule: PinListMessageActionModule
    init(_ actionModule: PinListMessageActionModule) {
        self.actionModule = actionModule
    }

    func show(vc: UIViewController,
              message: Message,
              chat: Chat,
              info: MessageMenuInfo) {
        let model = MessageActionMetaModel(chat: chat,
                                           message: message,
                                           myAIChatMode: false,
                                           isOpen: true,
                                           copyType: .message,
                                           selected: { .all })
        actionModule.handler(model: model)
        let items = actionModule.getActionItems(model: model)
        if items.isEmpty {
            return
        }
        let adapter = ActionSheetAdapter()
        let adapterSource = ActionSheetAdapterSource(
            sourceView: info.trigerView,
            sourceRect: CGRect(x: info.trigerLocation?.x ?? 0, y: info.trigerLocation?.y ?? 0, width: 0, height: 0),
            arrowDirection: .unknown
        )
        let actionSheet = adapter.create(level: .normal(source: adapterSource))
        items.forEach { (item) in
            adapter.addItem(title: item.text) {
                ChatTracker.imChatPinMoreClickWithType(item.trackExtraParams, chat: chat)
                item.tapAction()
            }
        }
        adapter.addCancelItem(title: BundleI18n.LarkChat.Lark_Legacy_Cancel)

        actionModule.navigator.present(actionSheet, from: vc)
    }

}
