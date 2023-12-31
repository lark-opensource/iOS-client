//
//  SaveToMessageActionSubModule.swift
//  LarkMessageCore
//
//  Created by liluobin on 2023/5/31.
//

import UIKit
import LarkOpenChat
import LKCommonsLogging
import LarkFeatureGating

// 会话场景
public final class ChatSaveToMessageActionModule: SaveToMessageActionSubModule {

    private static var chatSubModuleTypes: [BaseMessageActionSubModule<MessageActionContext>.Type] = []

    public override var subModuleTypes: [BaseMessageActionSubModule<MessageActionContext>.Type] {
        return Self.chatSubModuleTypes
    }

    public static func register(_ type: BaseMessageActionSubModule<MessageActionContext>.Type) {
        #if DEBUG
        if chatSubModuleTypes.contains(where: { $0 == type }) {
            assertionFailure("MessageActionSubModule \(type) has already been registered")
        }
        #endif
        chatSubModuleTypes.append(type)
    }
}

// 回复详情场景
public final class MessageDetailSaveToMessageActionModule: SaveToMessageActionSubModule {
    private static var chatReplySubModuleTypes: [BaseMessageActionSubModule<MessageActionContext>.Type] = []

    public override var subModuleTypes: [BaseMessageActionSubModule<MessageActionContext>.Type] {
        return Self.chatReplySubModuleTypes
    }

    public static func register(_ type: BaseMessageActionSubModule<MessageActionContext>.Type) {
        #if DEBUG
        if chatReplySubModuleTypes.contains(where: { $0 == type }) {
            assertionFailure("MessageActionSubModule \(type) has already been registered")
        }
        #endif
        chatReplySubModuleTypes.append(type)
    }
}

// 话题群场景
public final class ThreadSaveToMessageActionModule: SaveToMessageActionSubModule {
    private static var threadSubModuleTypes: [BaseMessageActionSubModule<MessageActionContext>.Type] = []

    public override var subModuleTypes: [BaseMessageActionSubModule<MessageActionContext>.Type] {
        return Self.threadSubModuleTypes
    }

    public static func register(_ type: BaseMessageActionSubModule<MessageActionContext>.Type) {
        #if DEBUG
        if threadSubModuleTypes.contains(where: { $0 == type }) {
            assertionFailure("MessageActionSubModule \(type) has already been registered")
        }
        #endif
        threadSubModuleTypes.append(type)
    }
}

// 话题群详情页场景
public final class ThreadDetailSaveToMessageActionModule: SaveToMessageActionSubModule {
    private static var threadDetailSubModuleTypes: [BaseMessageActionSubModule<MessageActionContext>.Type] = []

    public override var subModuleTypes: [BaseMessageActionSubModule<MessageActionContext>.Type] {
        return Self.threadDetailSubModuleTypes
    }

    public static func register(_ type: BaseMessageActionSubModule<MessageActionContext>.Type) {
        #if DEBUG
        if threadDetailSubModuleTypes.contains(where: { $0 == type }) {
            assertionFailure("MessageActionSubModule \(type) has already been registered")
        }
        #endif
        threadDetailSubModuleTypes.append(type)
    }
}

// 话题回复场景
public final class ReplyThreadSaveToMessageActionModule: SaveToMessageActionSubModule {
    private static var replyThreadSubModuleTypes: [BaseMessageActionSubModule<MessageActionContext>.Type] = []

    public override var subModuleTypes: [BaseMessageActionSubModule<MessageActionContext>.Type] {
        return Self.replyThreadSubModuleTypes
    }

    public static func register(_ type: BaseMessageActionSubModule<MessageActionContext>.Type) {
        #if DEBUG
        if replyThreadSubModuleTypes.contains(where: { $0 == type }) {
            assertionFailure("MessageActionSubModule \(type) has already been registered")
        }
        #endif
        replyThreadSubModuleTypes.append(type)
    }
}

// 私有话题场景
public final class PrivateThreadSaveToMessageActionModule: SaveToMessageActionSubModule {
    private static var threadSubModuleTypes: [BaseMessageActionSubModule<MessageActionContext>.Type] = []

    public override var subModuleTypes: [BaseMessageActionSubModule<MessageActionContext>.Type] {
        return Self.threadSubModuleTypes
    }

    public static func register(_ type: BaseMessageActionSubModule<MessageActionContext>.Type) {
        #if DEBUG
        if threadSubModuleTypes.contains(where: { $0 == type }) {
            assertionFailure("MessageActionSubModule \(type) has already been registered")
        }
        #endif
        threadSubModuleTypes.append(type)
    }
}

public class SaveToMessageActionSubModule: MessageActionFoldSubModule {

    static let logger = Logger.log(SaveToMessageActionSubModule.self, category: "MessageCore")

    public override var subItemOrder: [MessageActionType] {
        return [.flag, .favorite, .todo]
    }

    private lazy var savetoFg: Bool = {
        return self.context.userResolver.fg.dynamicFeatureGatingValue(with: "messenger.message.simplify_message_menu")
    }()

    public override var type: MessageActionType {
        return .saveTo
    }

    public override static func canInitialize(context: MessageActionContext) -> Bool {
        return true
    }

    public override func canHandle(model: MessageActionMetaModel) -> Bool {
        return self.savetoFg
    }

    public override func createActionItem(model: MessageActionMetaModel) -> MessageActionItem? {
        let chatId = model.chat.id
        return MessageActionItem(text: BundleI18n.LarkMessageCore.Lark_IM_MessageMenu_AddTo_Button,
                                 icon: BundleResources.Menu.menu_save_to,
                                 trackExtraParams: ["click": "add_to", "target": "none"]) {
            Self.logger.info("user click save to \(chatId)")
        }
    }

    /// 判断是否需要展示自己
    public override func beforeApplyMenuActionItem(_ items: [MessageActionItem]) -> [MessageActionItem] {
        guard let item = items.first else {
            return []
        }
        let targetItems = items.map { value in
            var newValue = value
            newValue.subText = self.subTextFor(item: value)
            return newValue
        }
        return item.subItems.isEmpty ? [] : targetItems
    }

    public func subTextFor(item: MessageActionItem) -> String {
        var text = ""
        for (idx, subItem) in item.subItems.enumerated() {
            text.append(subItem.text)
            if idx != item.subItems.count - 1 {
                text.append(BundleI18n.LarkMessageCore.Lark_Common_Comma_Text)
            }
        }
        return BundleI18n.LarkMessageCore.Lark_IM_MessageMenu_AddToFilters_Button(filter: text)
    }
}
