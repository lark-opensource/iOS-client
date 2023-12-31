//
//  TodoNormalChatKeyboardSubModule.swift
//  LarkChat
//
//  Created by zhaojiachen on 2022/1/13.
//

import Foundation
import LarkOpenChat
import LarkOpenIM
import LarkContainer
import LarkModel
import EENavigator
import LarkNavigation
import RustPB
import LarkCore
import LarkMessageCore
import LarkChat

public final class TodoNormalChatKeyboardSubModule: NormalChatKeyboardSubModule {
    /// 「+」号菜单
    public override var moreItems: [ChatKeyboardMoreItem] {
        return [todo].compactMap { $0 }
    }

    private var metaModel: ChatKeyboardMetaModel?
    @ScopedInjectedLazy private var navigationService: NavigationService?
    // TODO: 这个接口的依赖太多了，等一起隔离上浮了后，把相关的调用依赖从IM中隔离出去
    @ScopedInjectedLazy private var todoDependency: MessageCoreTodoDependency?

    public override class func canInitialize(context: ChatKeyboardContext) -> Bool {
        return true
    }

    public override func canHandle(model: ChatKeyboardMetaModel) -> Bool {
        return self.navigationService?.checkInTabs(for: .todo) ?? false
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

    private lazy var todo: ChatKeyboardMoreItem? = {
        guard let chatModel = self.metaModel?.chat else { return nil }
        if !chatModel.isCrossWithKa
            && ((chatModel.type == .p2P) || (chatModel.type == .group))
            && !self.context.hasRootMessage
            && !chatModel.isSuper
            && !chatModel.isP2PAi
            && !chatModel.isPrivateMode {
            let item = ChatKeyboardMoreItemConfig(
                text: BundleI18n.Todo.Todo_IM_TextFieldAddTask_Button,
                icon: Resources.todo_task,
                type: .todo,
                tapped: { [weak self] in
                    self?.clickTodo()
                })
            return item
        }
        return nil
    }()

    private func clickTodo() {
        guard let chatModel = self.metaModel?.chat else { return }
        IMTracker.Chat.InputPlus.Click.Todo(chatModel)

        var richContent: Basic_V1_RichContent?
        if let richText = self.context.getInputRichText() {
            richContent = .init()
            richContent?.richText = richText
        }
        let from = self.context.baseViewController()
        self.todoDependency?.createTodo(from: from, chat: chatModel, richContent: richContent)
        self.context.foldKeyboard()
    }
}
