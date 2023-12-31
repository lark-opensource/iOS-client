//
//  Todo.swift
//  LarkMessageCore
//
//  Created by Zigeng on 2023/2/16.
//

import Foundation
import LarkMessageBase
import LarkModel
import LarkMessengerInterface
import LarkCore
import LarkContainer
import RustPB
import LarkSDKInterface
import LarkUIKit
import LarkOpenChat
import LarkFeatureGating
import LarkNavigation

public class TodoMessageActionSubModule: MessageActionSubModule {
    @ScopedInjectedLazy fileprivate var todoDependency: MessageCoreTodoDependency?
    @ScopedInjectedLazy fileprivate var modelService: ModelService?
    @ScopedInjectedLazy private var navigationService: NavigationService?

    lazy var lynxcardRenderFG: Bool = {
        return self.userResolver.fg.staticFeatureGatingValue(with: "lynxcard.client.render.enable")
    }()

    var itemText: String {
        return BundleI18n.LarkMessageCore.Todo_Task_CreateATask
    }
    public override var type: MessageActionType {
        return .todo
    }

    public override static func canInitialize(context: MessageActionContext) -> Bool {
        return true
    }

    fileprivate func handle(message: Message, chat: Chat) {
        guard let targetVC = self.context.targetVC else { return }
        // 只拦截 reply in thread 即可，话题群中的处理不会走到这里
        if message.threadMessageType == .threadRootMessage {
            todoDependency?.createTodo(
                from: targetVC,
                chat: chat,
                threadID: message.id,
                message: message,
                title: modelService?.messageSummerize(message) ?? "",
                extra: ["source": "topic", "sub_source": "topic_press"]
            )
        } else {
            todoDependency?.createTodo(from: targetVC, chat: chat, message: message, extra: [:], lynxcardRenderFG: lynxcardRenderFG)
        }
    }

    public override func canHandle(model: MessageActionMetaModel) -> Bool {
        guard self.navigationService?.checkInTabs(for: .todo) ?? false else { return false }
        // 「互通」群不支持 todo
        if model.chat.isCrossWithKa || model.chat.isSuper {
            return false
        }
        if model.message.type == .mergeForward {
            let isFromPrivateTopic = (model.message.content as? MergeForwardContent)?.isFromPrivateTopic ?? false
            return !isFromPrivateTopic
        }
        return true
    }

    public override func createActionItem(model: MessageActionMetaModel) -> MessageActionItem? {
        return MessageActionItem(text: itemText,
                                 icon: BundleResources.Menu.menu_todo,
                                 trackExtraParams: ["click": "todo",
                                                    "target": "todo_create_view"]) { [weak self] in
            self?.handle(message: model.message, chat: model.chat)
        }
    }
}

public class TodoMessageActionSubModuleInThread: TodoMessageActionSubModule {
    override func handle(message: Message, chat: Chat) {
        guard let targetVC = self.context.targetVC else { return }
        // rootId.isEmpty 可以判断普通 thread 的根消息
        if message.rootId.isEmpty {
            todoDependency?.createTodo(
                from: targetVC,
                chat: chat,
                threadID: message.id,
                message: message,
                title: modelService?.messageSummerize(message) ?? "",
                extra: ["source": "topic", "sub_source": "topic_press"]
            )
        } else {
            todoDependency?.createTodo(
                from: targetVC,
                chat: chat,
                message: message,
                extra: ["source": "topic", "sub_source": "topic_remmend"],
                lynxcardRenderFG: lynxcardRenderFG
            )
        }
    }
}

public class TodoMessageActionSubModuleInReplyThread: TodoMessageActionSubModule {
    override func handle(message: Message, chat: Chat) {
        guard let targetVC = self.context.targetVC else { return }
        // threadMessageType == .threadRootMessage 可以判断 reply in thread 的根消息
        if message.threadMessageType == .threadRootMessage {
            todoDependency?.createTodo(
                from: targetVC,
                chat: chat,
                threadID: message.id,
                message: message,
                title: modelService?.messageSummerize(message) ?? "",
                extra: ["source": "topic", "sub_source": "topic_press"]
            )
        } else {
            todoDependency?.createTodo(
                from: targetVC,
                chat: chat,
                message: message,
                extra: ["source": "topic", "sub_source": "topic_remmend"],
                lynxcardRenderFG: lynxcardRenderFG
            )
        }
    }
}

public final class TodoMessageActionSaveToSubModule: TodoMessageActionSubModule {
    override var itemText: String { BundleI18n.LarkMessageCore.Lark_IM_MessageMenu_AddTo_Tasks_Button }
}

public final class TodoMessageActionSaveToSubModuleInThread: TodoMessageActionSubModuleInThread {
    override var itemText: String { BundleI18n.LarkMessageCore.Lark_IM_MessageMenu_AddTo_Tasks_Button }
}

public final class TodoMessageActionSaveToSubModuleInReplyThread: TodoMessageActionSubModuleInReplyThread {
    override var itemText: String { BundleI18n.LarkMessageCore.Lark_IM_MessageMenu_AddTo_Tasks_Button }
}
