//
//  Meego.swift
//  LarkMessageCore
//
//  Created by Zigeng on 2023/2/5.
//

import Foundation
import LarkOpenChat
import LarkModel
import LarkContainer

/// meego起的名字, 后面可以改一下 @冯梓耕
public protocol ChatMessageCellVMDependency {
    func canDisplayCreateWorkItemEntrance(chat: Chat, messages: [Message]?, from: String) -> Bool
}

public protocol MeegoMenuHandlereDependency {
    func createWorkItem(
        with chat: Chat,
        messages: [Message]?,
        sourceVc: UIViewController,
        from: String
    )
}

public final class MeegoMessageActionSubModule: MessageActionSubModule {
    public override var type: MessageActionType {
        return .meego
    }
    // Meego 服务
    @ScopedInjectedLazy private var dependency: MeegoMenuHandlereDependency?
    @ScopedInjectedLazy private var canMeegoDependency: ChatMessageCellVMDependency?

    public override static func canInitialize(context: MessageActionContext) -> Bool {
        return true
    }

    private func handle(message: Message, chat: Chat) {
        guard let targetVC = self.context.pageAPI else { return }
        dependency?.createWorkItem(
            with: chat,
            messages: [message],
            sourceVc: targetVC,
            from: "float_menu"
        )

    }

    public override func canHandle(model: MessageActionMetaModel) -> Bool {
        return canMeegoDependency?.canDisplayCreateWorkItemEntrance(chat: model.chat, messages: [model.message], from: "float_menu") ?? false
    }

    public override func createActionItem(model: MessageActionMetaModel) -> MessageActionItem? {
        return MessageActionItem(text: BundleI18n.LarkMessageCore.Lark_Project_Projects,
                                 icon: BundleResources.Menu.menu_meego,
                                 trackExtraParams: [:]) { [weak self] in
            self?.handle(message: model.message, chat: model.chat)
        }
    }
}
