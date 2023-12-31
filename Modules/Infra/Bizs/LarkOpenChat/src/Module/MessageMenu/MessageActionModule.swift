//
//  MessageActionModule.swift
//  LarkOpenChat
//
//  Created by Zigeng on 2023/1/18.
//

import Foundation
import Swinject
import LarkOpenIM
import LarkMessageBase
import LarkContainer
import LarkSetting
import LKCommonsLogging

public class BaseMessageActionModule<C: MessageActionContext>: Module<C, MessageActionMetaModel>, MenuTypeToActionItemsProtocol {
    let logger = Logger.log(BaseMessageActionModule.self, category: "LarkOpenChat.BaseMessageActionModule")

    override open class var loadableKey: String {
        return "OpenChat"
    }

    @ScopedInjectedLazy private var abTestService: MenuInteractionABTestService?

    var subModuleTypes: [BaseMessageActionSubModule<MessageActionContext>.Type] {
        return []
    }

    // 如果为true，选中文字时根据游标来返回位置。否则返回lark的位置
    // 如果为false，在第一次展示的时候，不遮挡view
    public var useNewLayout: Bool { return false }

    /// 所有实例化的直接SubModule
    private var subModules: [BaseMessageActionSubModule<MessageActionContext>] = []

    private var canHandleActionItems: [MessageActionType: [MessageActionItem]] = [:]

    /// 能处理当前context的SubModule
    private var canHandleSubModule: [MessageActionType: BaseMessageActionSubModule<MessageActionContext>] = [:]

    public override static func onLoad(context: C) {
        launchLoad()
    }

    /// 实例化subModules
    public override func onInitialize() {
        self.subModules = self.subModuleTypes.compactMap {
            if $0.canInitialize(context: context) {
                return $0.init(context: context)
            }
            return nil
        }
        self.subModules.forEach({ $0.registServices(container: self.context.container) })
    }

    /// 执行操作, 重新构造当前上下文可展示按钮
    @discardableResult
    public override func handler(model: MessageActionMetaModel) -> [Module<C, MessageActionMetaModel>] {
        self.canHandleActionItems = [:]
        self.canHandleSubModule = [:]
        self.subModules.forEach { (module) in
            // 如果能处理
            if module.canHandle(model: model) {
                // 遍历hander结果
                (module.handler(model: model) as? [BaseMessageActionSubModule<MessageActionContext>] ?? []).forEach { (_) in
                    if let items = module.createActionItems(model: model) {
                        self.canHandleActionItems.updateValue(items, forKey: module.type)
                        self.canHandleSubModule.updateValue(module, forKey: module.type)
                    } else if let item = module.createActionItem(model: model) {
                        self.canHandleActionItems.updateValue([item], forKey: module.type)
                        self.canHandleSubModule.updateValue(module, forKey: module.type)
                    }
                }
            }
        }
        return []
    }

    /// 是否可以展示表情面板
    public var showEmojiHeader: Bool = true

    /// hover面板顺序
    public func hoverOrder(model: MessageActionMetaModel) -> [MessageActionType] {
        return (!model.chat.isCrypto && (abTestService?.abTestResult ?? .none) == .radical) ? MessageActionOrder.abTestHover : MessageActionOrder.hover
    }

    /// 获取essageActionItem
    public func getActionItems(model: MessageActionMetaModel) -> [MessageActionItem] {
        /// 被拦截器拦截的MessageActionType
        let interceptedActionTypes = context.interceptor
            .intercept(context: .init(message: model.message,
                                      chat: model.chat,
                                      myAIChatMode: model.myAIChatMode,
                                      isInPartialSelect: model.isInPartialSelect,
                                      userResolver: self.context.userResolver))
        showEmojiHeader = !interceptedActionTypes.keys.contains(.reaction)
        let hover = model.isInPartialSelect ? MessageActionOrder.partialHover : hoverOrder(model: model)
        return hover.flatMap { type -> [MessageActionItem] in
            return self.mapMenuTypeToActionItems(type: type,
                                                 interceptedActionTypes: interceptedActionTypes)
        }
    }

    private func mapMenuTypeToActionItems(type: MessageActionType,
                                          interceptedActionTypes: [MessageActionType: MessageActionInterceptedType]) -> [MessageActionItem] {
        var targetItems: [MessageActionItem] = self.mapMenuTypeToActionItems(type: type,
                                                                             actionItems: canHandleActionItems,
                                                                             interceptedActionTypes: interceptedActionTypes)
        if !targetItems.isEmpty, let module = self.canHandleSubModule[type] as? BaseMessageFoldActionSubModule {
            targetItems = module.getActionItems(targetItems, interceptedActionTypes: interceptedActionTypes)
        }
        return targetItems
    }

    /// 构造分组后的MessageActionItem
    public func getActionItemSections(model: MessageActionMetaModel) -> [[MessageActionItem]] {
        var sheet: [[MessageActionType]] = model.isInPartialSelect ? [MessageActionOrder.defaultPartialSheet] : MessageActionOrder.defaultSheet
        // 能拉到setting，则使用远端排序数据
        if let mobileConfig = try? context.userResolver.settings.setting(with: MessageActionOrderSetting.self).mobileConfig {
            sheet = MessageActionOrder.formatSetting(config: mobileConfig)
            self.logger.info("[MenuInfo] get setting success")
        }

        // 需要调整顺序的需求-调整基本盘
        if !model.chat.isCrypto && (abTestService?.abTestResult ?? .none) == .radical {
            sheet = MessageActionOrder.abTestSheetOrderForShowSaveTo(sheet)
            self.logger.info("[MenuInfo] Need to justify menu order")
        }

        // 部分选择菜单-从setting拉取设置
        if model.isInPartialSelect,
           let mobileConfig = try? context.userResolver.settings.setting(with: MessageActionOrderSetting.self).mobilePartialConfig {
            sheet = mobileConfig.flatMap {
                MessageActionOrder.settingToActionType(settingName: $0)
            }
            self.logger.info("[MenuInfo] get partial setting success")
        }
        let interceptedActionTypes = context.interceptor
            .intercept(context: .init(message: model.message,
                                      chat: model.chat,
                                      myAIChatMode: model.myAIChatMode,
                                      isInPartialSelect: model.isInPartialSelect,
                                      userResolver: self.context.userResolver))
        showEmojiHeader = !interceptedActionTypes.keys.contains(.reaction)

        return sheet.compactMap {
            let section = $0.flatMap { type -> [MessageActionItem] in
                return self.mapMenuTypeToActionItems(type: type,
                                                     interceptedActionTypes: interceptedActionTypes)

            }
            return !section.isEmpty ? section : []
        }
    }
}

// 会话场景
public final class ChatMessageActionModule: BaseMessageActionModule<MessageActionContext> {
    private static var chatSubModuleTypes: [BaseMessageActionSubModule<MessageActionContext>.Type] = []

    override var subModuleTypes: [BaseMessageActionSubModule<MessageActionContext>.Type] {
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
public final class MessageDetailMessageActionModule: BaseMessageActionModule<MessageActionContext> {

    private static var chatReplySubModuleTypes: [BaseMessageActionSubModule<MessageActionContext>.Type] = []
    public override var useNewLayout: Bool { return true }

    override var subModuleTypes: [BaseMessageActionSubModule<MessageActionContext>.Type] {
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

// 密聊场景
public final class CryptoMessageActionModule: BaseMessageActionModule<MessageActionContext> {
    private static var cryptoSubModuleTypes: [BaseMessageActionSubModule<MessageActionContext>.Type] = []

    override var subModuleTypes: [BaseMessageActionSubModule<MessageActionContext>.Type] {
        return Self.cryptoSubModuleTypes
    }

    public static func register(_ type: BaseMessageActionSubModule<MessageActionContext>.Type) {
        #if DEBUG
        if cryptoSubModuleTypes.contains(where: { $0 == type }) {
            assertionFailure("MessageActionSubModule \(type) has already been registered")
        }
        #endif
        cryptoSubModuleTypes.append(type)
    }
}

// 密聊回复详情场景
public final class CryptoMessageDetailMessageActionModule: BaseMessageActionModule<MessageActionContext> {

    private static var cryptoSubModuleTypes: [BaseMessageActionSubModule<MessageActionContext>.Type] = []
    public override var useNewLayout: Bool { return true }

    override var subModuleTypes: [BaseMessageActionSubModule<MessageActionContext>.Type] {
        return Self.cryptoSubModuleTypes
    }

    public static func register(_ type: BaseMessageActionSubModule<MessageActionContext>.Type) {
        #if DEBUG
        if cryptoSubModuleTypes.contains(where: { $0 == type }) {
            assertionFailure("MessageActionSubModule \(type) has already been registered")
        }
        #endif
        cryptoSubModuleTypes.append(type)
    }
}

// 话题群场景
public final class ThreadMessageActionModule: BaseMessageActionModule<MessageActionContext> {

    private static var threadSubModuleTypes: [BaseMessageActionSubModule<MessageActionContext>.Type] = []
    public override var useNewLayout: Bool { return true }

    override var subModuleTypes: [BaseMessageActionSubModule<MessageActionContext>.Type] {
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
public final class ThreadDetailMessageActionModule: BaseMessageActionModule<MessageActionContext> {
    private static var threadDetailSubModuleTypes: [BaseMessageActionSubModule<MessageActionContext>.Type] = []

    override var subModuleTypes: [BaseMessageActionSubModule<MessageActionContext>.Type] {
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
public final class ReplyThreadMessageActionModule: BaseMessageActionModule<MessageActionContext> {
    private static var replyThreadSubModuleTypes: [BaseMessageActionSubModule<MessageActionContext>.Type] = []

    override var subModuleTypes: [BaseMessageActionSubModule<MessageActionContext>.Type] {
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
public final class PrivateThreadMessageActionModule: BaseMessageActionModule<PrivateThreadMessageActionContext> {
    private static var threadSubModuleTypes: [BaseMessageActionSubModule<MessageActionContext>.Type] = []

    override var subModuleTypes: [BaseMessageActionSubModule<MessageActionContext>.Type] {
        return Self.threadSubModuleTypes
    }

    // 私有话题场景没有emoji
    public override var showEmojiHeader: Bool {
        get { return false }
        set { }
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

// 合并转发场景
public final class MergeForwardMessageActionModule: BaseMessageActionModule<MessageActionContext> {
    private static var mergeSubModuleTypes: [BaseMessageActionSubModule<MessageActionContext>.Type] = []

    override var subModuleTypes: [BaseMessageActionSubModule<MessageActionContext>.Type] {
        return Self.mergeSubModuleTypes
    }

    // 合并转发场景没有emoji
    public override var showEmojiHeader: Bool {
        get { return false }
        set { }
    }

    public static func register(_ type: BaseMessageActionSubModule<MessageActionContext>.Type) {
        #if DEBUG
        if mergeSubModuleTypes.contains(where: { $0 == type }) {
            assertionFailure("MessageActionSubModule \(type) has already been registered")
        }
        #endif
        mergeSubModuleTypes.append(type)
    }
}

// Pin列表场景
public final class PinListMessageActionModule: BaseMessageActionModule<MessageActionContext> {
    private static var pinSubModuleTypes: [MessageActionSubModule.Type] = []

    private static let pinMenuOrder: [MessageActionType] = [
        .pin,
        .jumpToChat,
        .forward,
        .copy,
    ]

    override var subModuleTypes: [BaseMessageActionSubModule<MessageActionContext>.Type] {
        return Self.pinSubModuleTypes
    }

    override public func hoverOrder(model: MessageActionMetaModel) -> [MessageActionType] {
        return super.hoverOrder(model: model).sorted { (type1, type2) -> Bool in
            guard let index1 = Self.pinMenuOrder.firstIndex(of: type1) else { return false }
            guard let index2 = Self.pinMenuOrder.firstIndex(of: type2) else { return true }
            return index1 < index2
        }
    }

    public static func register(_ type: MessageActionSubModule.Type) {
        #if DEBUG
        if pinSubModuleTypes.contains(where: { $0 == type }) {
            assertionFailure("MessageActionSubModule \(type) has already been registered")
        }
        #endif
        pinSubModuleTypes.append(type)
    }
}

// 消息链接化详情页，复用合并转发页面，但是翻译接口与合并转发的不同，因此需要单独写一个
public final class MessageLinkDetailActionModule: BaseMessageActionModule<MessageActionContext> {
    private static var mergeSubModuleTypes: [MessageActionSubModule.Type] = []

    override var subModuleTypes: [BaseMessageActionSubModule<MessageActionContext>.Type] {
        return Self.mergeSubModuleTypes
    }

    // 合并转发场景没有emoji
    public override var showEmojiHeader: Bool {
        get { return false }
        set { }
    }

    public static func register(_ type: MessageActionSubModule.Type) {
        #if DEBUG
        if mergeSubModuleTypes.contains(where: { $0 == type }) {
            assertionFailure("MessageActionSubModule \(type) has already been registered")
        }
        #endif
        mergeSubModuleTypes.append(type)
    }
}
