//
//  ChatFooterModule.swift
//  LarkOpenChat
//
//  Created by Zigeng on 2022/7/7.
//

import UIKit
import Foundation
import Swinject
import LarkOpenIM

public class BaseChatFooterModule: Module<ChatFooterContext, ChatFooterMetaModel> {
    override open class var loadableKey: String {
        return "OpenChat"
    }

    var subModuleTypes: [BaseChatFooterSubModule.Type] {
        assertionFailure("BaseChatFooterModule.subModuleTypes Must Been Overrided!!!")
        return []
    }

    var whiteList: [ChatFooterType]? {
        return nil
    }

    private var subModules: [BaseChatFooterSubModule] = []
    private var canHandleSubModules: [BaseChatFooterSubModule] = []
    
    public override func onInitialize() {
        self.subModules = self.subModuleTypes
                              .filter { $0.canInitialize(context: self.context) }
                              .map { $0.init(context: self.context) }
        self.subModules.forEach {
            $0.registServices(container: self.context.container)
        }
    }

    @discardableResult
    public override func handler(model: ChatFooterMetaModel) -> [Module<ChatFooterContext, ChatFooterMetaModel>] {
        self.canHandleSubModules = []
        self.subModules.forEach { module in
            if self.whiteListCheck(type: module.type), module.canHandle(model: model) {
                (module.handler(model: model) as? [BaseChatFooterSubModule] ?? []).forEach { subModule in
                    self.canHandleSubModules.append(module)
                }
            }
        }
        return [self]
    }

    public func contentView() -> UIView? {
        let modules = self.canHandleSubModules.filter { $0.display }.sorted { m1, m2 in
            return m1.type.rawValue > m2.type.rawValue
        }
        if let contentView = modules.first?.contentView() {
            if !contentView.isHidden {
                return contentView
            } else {
                assertionFailure("isHidden should be true while display is true")
            }
        }
        return nil
    }

    public override func modelDidChange(model: ChatFooterMetaModel) {
        self.canHandleSubModules.forEach { $0.modelDidChange(model: model) }
    }

    public func createViews(model: ChatFooterMetaModel) {
        self.canHandleSubModules.forEach { module in
            if module.didCreate {
                module.updateViews(model: model)
            } else {
                module.createViews(model: model)
            }
        }
    }

    private func whiteListCheck(type: ChatFooterType) -> Bool {
        // 若whiteList为nil,说明没有override,不需要校验
        guard let whiteList = whiteList else {
            return true
        }
        return whiteList.contains(type)
    }
}

public final class ChatFooterModule: BaseChatFooterModule {
    private static var subModuleTypes: [ChatFooterSubModule.Type] = []

    override var subModuleTypes: [BaseChatFooterSubModule.Type] {
        return Self.subModuleTypes
    }

    public static func register(_ type: ChatFooterSubModule.Type) {
        #if DEBUG
        if subModuleTypes.contains(where: { $0 == type }) {
            assertionFailure("ChatFooterSubModule \(type) has already beeen registered!!")
        }
        #endif
        subModuleTypes.append(type)
    }

    public override static func onLoad(context: ChatFooterContext) {
        launchLoad()
        subModuleTypes.forEach{ $0.onLoad(context: context) }
    }

    public override class func registGlobalServices(container: Container) {
        subModuleTypes.forEach { $0.registGlobalServices(container: container)}
    }
}

public final class CryptoChatFooterModule: BaseChatFooterModule {
    private static var subModuleTypes: [CryptoChatFooterSubModule.Type] = []

    override var subModuleTypes: [BaseChatFooterSubModule.Type] {
        return Self.subModuleTypes
    }

    override var whiteList: [ChatFooterType]? {
        return [.resignChatMask]
    }

    public static func register(_ type: CryptoChatFooterSubModule.Type) {
        #if DEBUG
        if subModuleTypes.contains(where: { $0 == type }) {
            assertionFailure("CryptoChatFooterSubModule \(type) has already beeen registered!!")
        }
        #endif
        subModuleTypes.append(type)
    }

    public override static func onLoad(context: ChatFooterContext) {
        launchLoad()
        subModuleTypes.forEach{ $0.onLoad(context: context) }
    }

    public override class func registGlobalServices(container: Container) {
        subModuleTypes.forEach { $0.registGlobalServices(container: container)}
    }
}
