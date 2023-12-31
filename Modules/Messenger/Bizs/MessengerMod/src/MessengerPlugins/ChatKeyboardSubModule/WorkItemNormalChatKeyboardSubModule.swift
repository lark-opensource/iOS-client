//
//  WorkItemNormalChatKeyboardSubModule.swift
//  LarkChat
//
//  Created by zhaojiachen on 2022/1/13.
//

import UIKit
import Foundation
import LarkOpenChat
import LarkOpenIM
import LarkContainer
import LarkModel
import EENavigator
import LarkChat
import LarkMeegoInterface

public final class WorkItemNormalChatKeyboardSubModule: NormalChatKeyboardSubModule {
    @ScopedProvider var larkMeegoService: LarkMeegoService?

    /// 「+」号菜单
    public override var moreItems: [ChatKeyboardMoreItem] {
        return [meego].compactMap { $0 }
    }

    private var metaModel: ChatKeyboardMetaModel?

    public override class func canInitialize(context: ChatKeyboardContext) -> Bool {
        return true
    }

    public override func canHandle(model: ChatKeyboardMetaModel) -> Bool {
        if model.chat.isP2PAi { return false }
        return self.canDisplayCreateWorkItemEntrance(chat: model.chat, from: "keyboard_menu") ?? false
    }

    public override func handler(model: ChatKeyboardMetaModel) -> [Module<ChatKeyboardContext, ChatKeyboardMetaModel>] {
        return [self]
    }

    public override func modelDidChange(model: ChatKeyboardMetaModel) {
        self.metaModel = model
    }

    public override func createMoreItems(metaModel: ChatKeyboardMetaModel) {
        self.metaModel = metaModel
    }

    private lazy var meego: ChatKeyboardMoreItem? = {
        let item = ChatKeyboardMoreItemConfig(
            text: BundleI18n.LarkChat.Lark_Project_Projects,
            icon: Resources.meegoPlusItem,
            type: .meego,
            tapped: { [weak self] in
                self?.clickMeego()
            })
        return item
    }()

    private func clickMeego() {
        guard let chatModel = self.metaModel?.chat else { return }
        let from = self.context.baseViewController()
        self.createWorkItem(
            with: chatModel,
            messages: nil,
            sourceVc: from,
            from: "keyboard_menu"
        )
        self.context.foldKeyboard()
    }

    public func canDisplayCreateWorkItemEntrance(chat: Chat, from: String) -> Bool {
        if chat.isPrivateMode { return false }
        if let fromEnum = EntranceSource(rawValue: from) {
            return larkMeegoService?.canDisplayCreateWorkItemEntrance(chat: chat, from: fromEnum) ?? false
        }
        return false
    }

    public func createWorkItem(with chat: Chat, messages: [Message]?, sourceVc: UIViewController, from: String) {
        EntranceSource(rawValue: from)
            .flatMap { larkMeegoService?.createWorkItem( with: chat, messages: messages, sourceVc: sourceVc, from: $0) }
    }
}
