//
//  ChatBannerModule.swift
//  LarkOpenChat
//
//  Created by 李勇 on 2020/12/6.
//

import UIKit
import Foundation
import Swinject
import LarkOpenIM

// 所有业务如果需要接入banner，需要声明业务对应枚举，枚举值大小会影响展示优先级(优先级递增)
public enum ChatBannerType: Int {
    case unknown
    case edu // 家校群
    case meeting // 会议
    case chatTopNotice // 置顶消息
    case externalContact // 外部联系人
    case chatApprove // 入群申请
}

/// Chat中Banner区域抽象Module，VC持有该Module完成Banner创建/显示/更新。
public class BaseChatBannerModule: Module<ChatBannerContext, ChatBannerMetaModel> {
    override open class var loadableKey: String {
        return "OpenChat"
    }

    var subModuleTypes: [BaseChatBannerSubModule.Type] {
        return []
    }

    // 白名单
    var whiteList: [ChatBannerType]? {
        return nil
    }

    /// 所有实例化的直接SubModule
    private var subModules: [BaseChatBannerSubModule] = []
    /// 所有能处理当前context的SubModule
    private var canHandleSubModules: [BaseChatBannerSubModule] = []

    /// 实例化subModules
    public override func onInitialize() {
        self.subModules = self.subModuleTypes.filter({ $0.canInitialize(context: self.context) })
            .map({ $0.init(context: self.context) })
        self.subModules.forEach({ $0.registServices(container: self.context.container) })
    }

    /// subModules -> canHandleSubModules
    @discardableResult
    public override func handler(model: ChatBannerMetaModel) -> [Module<ChatBannerContext, ChatBannerMetaModel>] {
        self.canHandleSubModules = []
        self.subModules.forEach { (module) in
            // 如果能处理
            if module.canHandle(model: model), self.whiteListCheck(type: module.type) {
                // 遍历hander结果
                (module.handler(model: model) as? [BaseChatBannerSubModule] ?? []).forEach { (_) in
                    self.canHandleSubModules.append(module)
                }
            }
        }
        return [self]
    }

    public override func modelDidChange(model: ChatBannerMetaModel) {
        self.canHandleSubModules.forEach({ $0.modelDidChange(model: model) })
    }

    /// 构造视图
    public func createViews(model: ChatBannerMetaModel) {
        self.canHandleSubModules.forEach { (module) in
            if module.didCreate {
                module.updateViews(model: model)
            } else {
                module.createViews(model: model)
            }
        }
    }

    /// 获取视图，按需求设计，banner同一时刻只会展示一个，按优先级从高到低展示。
    /// 之前实现有问题，保持兼容性，只调整内部逻辑，但数组中至多只会返回一个view
    public func contentViews() -> [UIView] {
        let modules = self.canHandleSubModules.filter({ $0.display }).sorted { m1, m2 in
            return m1.type.rawValue > m2.type.rawValue
        }
        if let contentView = modules.first?.contentView() {
            if !contentView.isHidden {
                return [contentView]
            } else {
                assertionFailure("display为true是，isHidden应该为false")
            }
        }
        return []
    }

    private func whiteListCheck(type: ChatBannerType) -> Bool {
        guard let whiteList = self.whiteList else {
            // 不需要校验
            return true
        }
        return whiteList.contains(type)
    }
}

public final class ChatBannerModule: BaseChatBannerModule {
    private static var normalSubModuleTypes: [ChatBannerSubModule.Type] = []

    override var subModuleTypes: [BaseChatBannerSubModule.Type] {
        return Self.normalSubModuleTypes
    }

    public static func register(_ type: ChatBannerSubModule.Type) {
        #if DEBUG
        if normalSubModuleTypes.contains(where: { $0 == type }) {
            assertionFailure("ChatBannerSubModule \(type) has already been registered")
        }
        #endif
        normalSubModuleTypes.append(type)
    }

    public override static func onLoad(context: ChatBannerContext) {
        launchLoad()
        // 对subModules依次调用onLoad
        normalSubModuleTypes.forEach({ $0.onLoad(context: context) })
    }

    /// 对subModules依次调用registGlobalServices
    public override class func registGlobalServices(container: Container) {
        normalSubModuleTypes.forEach({ $0.registGlobalServices(container: container) })
    }
}

public final class CryptoChatBannerModule: BaseChatBannerModule {
    private static var cryptoSubModuleTypes: [CryptoChatBannerSubModule.Type] = []

    override var subModuleTypes: [BaseChatBannerSubModule.Type] {
        return Self.cryptoSubModuleTypes
    }

    override var whiteList: [ChatBannerType]? {
        return [.externalContact]
    }

    public static func register(_ type: CryptoChatBannerSubModule.Type) {
        #if DEBUG
        if cryptoSubModuleTypes.contains(where: { $0 == type }) {
            assertionFailure("CryptoChatBannerSubModule \(type) has already been registered")
        }
        #endif
        cryptoSubModuleTypes.append(type)
    }

    public override static func onLoad(context: ChatBannerContext) {
        launchLoad()
        // 对subModules依次调用onLoad
        cryptoSubModuleTypes.forEach({ $0.onLoad(context: context) })
    }

    /// 对subModules依次调用registGlobalServices
    public override class func registGlobalServices(container: Container) {
        cryptoSubModuleTypes.forEach({ $0.registGlobalServices(container: container) })
    }
}
