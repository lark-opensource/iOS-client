//
//  ChatKeyboardTopExtendModule.swift
//  LarkOpenChat
//
//  Created by zc09v on 2021/8/9.
//

import UIKit
import Foundation
import Swinject
import LKLoadable
import LarkOpenIM

// 所有业务如果需要接入新增键盘上方区域，需要声明业务对应枚举，枚举值大小会影响展示优先级
public enum ChatKeyboardTopExtendType: Int {
    case unknown
    case demo
    /// MyAI：https://bytedance.feishu.cn/docx/Rn9kdvsX6okJyTxoGtYcygJBn2A
    case myAI
    case helpdesk
    // 开放平台快捷小组件
    /// doc: https://bytedance.feishu.cn/docx/doxcn25TC3tE8jjsHEzrpZS5jIf
    case toolKit
    case todo
}

public class BaseChatKeyboardTopExtendModule: Module<ChatKeyboardTopExtendContext, ChatKeyboardTopExtendMetaModel> {
    override open class var loadableKey: String {
        return "OpenChat"
    }

    var subModuleTypes: [BaseChatKeyboardTopExtendSubModule.Type] {
        return []
    }
    /// 所有实例化的直接SubModule
    private var subModules: [BaseChatKeyboardTopExtendSubModule] = []
    /// 所有能处理当前context的SubModule
    private var canHandleSubModules: [BaseChatKeyboardTopExtendSubModule] = []

    // 白名单
    var whiteList: [ChatKeyboardTopExtendType]? {
        return nil
    }

    /// 实例化subModules
    public override func onInitialize() {
        self.subModules = self.subModuleTypes.filter({ $0.canInitialize(context: self.context) })
            .map({ $0.init(context: self.context) })
        self.subModules.forEach({ $0.registServices(container: self.context.container) })
    }

    /// subModules -> canHandleSubModules
    @discardableResult
    public override func handler(model: ChatKeyboardTopExtendMetaModel) -> [Module<ChatKeyboardTopExtendContext, ChatKeyboardTopExtendMetaModel>] {
        self.canHandleSubModules = []
        self.subModules.forEach { (module) in
            // 如果能处理
            if self.whiteListCheck(type: module.type), module.canHandle(model: model) {
                // 遍历hander结果
                (module.handler(model: model) as? [BaseChatKeyboardTopExtendSubModule] ?? []).forEach { (_) in
                    self.canHandleSubModules.append(module)
                }
            }
        }
        return [self]
    }

    public override func modelDidChange(model: ChatKeyboardTopExtendMetaModel) {
        self.canHandleSubModules.forEach({ $0.modelDidChange(model: model) })
    }

    public func refresh() -> (UIView, CGFloat)? {
        return self.currentDisplayContent()
    }

    /// 获取初始视图，视图相对于顶部的间距
    public func setUpContentView(model: ChatKeyboardTopExtendMetaModel) -> (UIView, CGFloat)? {
        self.canHandleSubModules.forEach { subModule in
            subModule.createContentView(model: model)
        }
        return self.currentDisplayContent()
    }

    private func currentDisplayContent() -> (UIView, CGFloat)? {
        let sortedModules = self.canHandleSubModules.sorted { sub1, sub2 in
            return sub1.type.rawValue > sub2.type.rawValue
        }
        for module in sortedModules {
            if let content = module.contentView() {
                return (content, module.contentTopMargin())
            }
        }
        return nil
    }

    private func whiteListCheck(type: ChatKeyboardTopExtendType) -> Bool {
        guard let whiteList = self.whiteList else {
            // 不需要校验
            return true
        }
        return whiteList.contains(type)
    }
}

public final class ChatKeyboardTopExtendModule: BaseChatKeyboardTopExtendModule {
    private static var normalSubModuleTypes: [ChatKeyboardTopExtendSubModule.Type] = []

    override var subModuleTypes: [BaseChatKeyboardTopExtendSubModule.Type] {
        return Self.normalSubModuleTypes
    }

    public static func register(_ type: ChatKeyboardTopExtendSubModule.Type) {
        #if DEBUG
        if normalSubModuleTypes.contains(where: { $0 == type }) {
            assertionFailure("ChatKeyboardTopExtendSubModule \(type) has already been registered")
        }
        #endif
        normalSubModuleTypes.append(type)
    }

    public override static func onLoad(context: ChatKeyboardTopExtendContext) {
        launchLoad()
        // 对subModules依次调用onLoad
        normalSubModuleTypes.forEach({ $0.onLoad(context: context) })
    }

    /// 对subModules依次调用registGlobalServices
    public override class func registGlobalServices(container: Container) {
        normalSubModuleTypes.forEach({ $0.registGlobalServices(container: container) })
    }
}

public final class CryptoChatKeyboardTopExtendModule: BaseChatKeyboardTopExtendModule {
    private static var cryptoSubModuleTypes: [CryptoChatKeyboardTopExtendSubModule.Type] = []

    override var whiteList: [ChatKeyboardTopExtendType]? {
        return []
    }

    override var subModuleTypes: [BaseChatKeyboardTopExtendSubModule.Type] {
        return Self.cryptoSubModuleTypes
    }

    public static func register(_ type: CryptoChatKeyboardTopExtendSubModule.Type) {
        #if DEBUG
        if cryptoSubModuleTypes.contains(where: { $0 == type }) {
            assertionFailure("ChatKeyboardTopExtendSubModule \(type) has already been registered")
        }
        #endif
        cryptoSubModuleTypes.append(type)
    }

    public override static func onLoad(context: ChatKeyboardTopExtendContext) {
        launchLoad()
        // 对subModules依次调用onLoad
        cryptoSubModuleTypes.forEach({ $0.onLoad(context: context) })
    }

    /// 对subModules依次调用registGlobalServices
    public override class func registGlobalServices(container: Container) {
        cryptoSubModuleTypes.forEach({ $0.registGlobalServices(container: container) })
    }
}
