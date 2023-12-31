//
//  BaseChatKeyboardModule.swift
//  LarkOpenChat
//
//  Created by zhaojiachen on 2021/12/24.
//

import Foundation
import Swinject
import LKLoadable
import LarkOpenIM

public class BaseChatKeyboardModule: Module<ChatKeyboardContext, ChatKeyboardMetaModel> {
    override open class var loadableKey: String {
        return "OpenChat"
    }

    var subModuleTypes: [BaseChatKeyboardSubModule.Type] {
        return []
    }

    /// 所有实例化的直接SubModule
    private var subModules: [BaseChatKeyboardSubModule] = []
    /// 所有能处理当前context的SubModule
    private var canHandleSubModules: [BaseChatKeyboardSubModule] = []

    /// 实例化subModules
    public override func onInitialize() {
        self.subModules = subModuleTypes.filter({ $0.canInitialize(context: self.context) })
            .map({ $0.init(context: self.context) })
        self.subModules.forEach({ $0.registServices(container: self.context.container) })
    }

    /// subModules -> canHandleSubModules
    @discardableResult
    public override func handler(model: ChatKeyboardMetaModel) -> [Module<ChatKeyboardContext, ChatKeyboardMetaModel>] {
        self.canHandleSubModules = []
        self.subModules.forEach { (module) in
            // 如果能处理
            if module.canHandle(model: model) {
                // 遍历hander结果
                (module.handler(model: model) as? [BaseChatKeyboardSubModule] ?? []).forEach { (_) in
                    self.canHandleSubModules.append(module)
                }
            }
        }
        return [self]
    }

    public override func modelDidChange(model: ChatKeyboardMetaModel) {
        self.canHandleSubModules.forEach({ $0.modelDidChange(model: model) })
    }

    // MARK: - 「+」号菜单
    /// 「+」菜单白名单
    var moreItemWhiteList: [ChatKeyboardMoreItemType]? {
        return nil
    }

    private var moreItemsAleadySetup: Bool = false
    public func createMoreItems(metaModel: ChatKeyboardMetaModel) {
        guard !moreItemsAleadySetup else {
            return
        }
        moreItemsAleadySetup = true
        self.canHandleSubModules.forEach { subModule in
            subModule.createMoreItems(metaModel: metaModel)
        }
    }

    public func moreItems() -> [ChatKeyboardMoreItem] {
        let modules = self.canHandleSubModules
        var moreItems: [ChatKeyboardMoreItem] = []
        for module in modules {
            moreItems.append(contentsOf: module.moreItems)
        }
        return moreItems.sorted(by: { item1, item2 in
            return item1.type.rawValue < item2.type.rawValue
        }).filter { item in
            return self.moreItemWhiteListCheck(type: item.type)
        }
    }

    private func moreItemWhiteListCheck(type: ChatKeyboardMoreItemType) -> Bool {
        guard let whiteList = self.moreItemWhiteList else {
            /// 不需要校验
            return true
        }
        return whiteList.contains(type)
    }

    // MARK: - Input Handler
    /// input handler 白名单
    var inputHandlerWhiteList: [ChatKeyboardInputOpenType]? {
        return nil
    }

    private var inputHandlersAleadySetup: Bool = false
    public func createInputHandlers(metaModel: ChatKeyboardMetaModel) {
        guard !inputHandlersAleadySetup else {
            return
        }
        inputHandlersAleadySetup = true
        self.canHandleSubModules.forEach { subModule in
            subModule.createInputHandlers(metaModel: metaModel)
        }
    }

    public func inputHandlers() -> [ChatKeyboardInputOpenProtocol] {
        let modules = self.canHandleSubModules
        var inputHandlers: [ChatKeyboardInputOpenProtocol] = []
        for module in modules {
            inputHandlers.append(contentsOf: module.inputHandlers)
        }
        return inputHandlers.sorted(by: { handler1, handler2 in
            return handler1.type.rawValue < handler2.type.rawValue
        }).filter { handler in
            return self.inputHandlerWhiteListCheck(type: handler.type)
        }
    }

    private func inputHandlerWhiteListCheck(type: ChatKeyboardInputOpenType) -> Bool {
        guard let whiteList = self.inputHandlerWhiteList else {
            /// 不需要校验
            return true
        }
        return whiteList.contains(type)
    }
}

public final class NormalChatKeyboardModule: BaseChatKeyboardModule {
    /// 普通聊天各业务方注册的SubModule
    private static var normalSubModuleTypes: [BaseChatKeyboardSubModule.Type] = []
    override var subModuleTypes: [BaseChatKeyboardSubModule.Type] {
        return NormalChatKeyboardModule.normalSubModuleTypes
    }

    public override static func onLoad(context: ChatKeyboardContext) {
        launchLoad()
        // 对subModules依次调用onLoad
        normalSubModuleTypes.forEach({ $0.onLoad(context: context) })
    }

    public static func register(_ type: NormalChatKeyboardSubModule.Type) {
        #if DEBUG
        if NormalChatKeyboardModule.normalSubModuleTypes.contains(where: { $0 == type }) {
            assertionFailure("NormalChatKeyboardSubModule \(type) has already been registered")
        }
        #endif
        NormalChatKeyboardModule.normalSubModuleTypes.append(type)
    }

    /// 对subModules依次调用registGlobalServices
    public override class func registGlobalServices(container: Container) {
        NormalChatKeyboardModule.normalSubModuleTypes.forEach({ $0.registGlobalServices(container: container) })
    }
}

public final class CryptoChatKeyboardModule: BaseChatKeyboardModule {
    /// 密聊各业务方注册的SubModule
    private static var cryptoSubModuleTypes: [BaseChatKeyboardSubModule.Type] = []

    /// 往 CryptoChatKeyboardModule 中注册的「+」号更多 Item，需要加入白名单，进行管控
    override var moreItemWhiteList: [ChatKeyboardMoreItemType] {
        return [.file, .doc, .location, .userCard]
    }

    /// 往 CryptoChatKeyboardModule 中注册的 input handler，需要加入白名单，进行管控
    override var inputHandlerWhiteList: [ChatKeyboardInputOpenType]? {
        return [.return, .atPicker, .atUser, .emoji]
    }

    override var subModuleTypes: [BaseChatKeyboardSubModule.Type] {
        return CryptoChatKeyboardModule.cryptoSubModuleTypes
    }

    public override static func onLoad(context: ChatKeyboardContext) {
        launchLoad()
        // 对subModules依次调用onLoad
        cryptoSubModuleTypes.forEach({ $0.onLoad(context: context) })
    }

    public static func register(_ type: CryptoChatKeyboardSubModule.Type) {
        #if DEBUG
        if CryptoChatKeyboardModule.cryptoSubModuleTypes.contains(where: { $0 == type }) {
            assertionFailure("CryptoChatKeyboardSubModule \(type) has already been registered")
        }
        #endif
        CryptoChatKeyboardModule.cryptoSubModuleTypes.append(type)
    }

    /// 对subModules依次调用registGlobalServices
    public override class func registGlobalServices(container: Container) {
        CryptoChatKeyboardModule.cryptoSubModuleTypes.forEach({ $0.registGlobalServices(container: container) })
    }
}
