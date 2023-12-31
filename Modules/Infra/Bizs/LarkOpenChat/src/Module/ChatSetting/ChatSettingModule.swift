//
//  ChatSettingModule.swift
//  LarkOpenChat
//
//  Created by JackZhao on 2021/8/24.
//

import UIKit
import Swinject
import Foundation
import LKLoadable
import LarkOpenIM

/// ChatSetting区域抽象Module
public final class ChatSettingModule: Module<ChatSettingContext, ChatSettingMetaModel> {
    override public class var loadableKey: String {
        return "OpenChat"
    }
    /// 各业务方注册的SubModule
    private static var subModuleTypes: [ChatSettingSubModule.Type] = []
    /// 所有实例化的直接SubModule
    private var subModules: [ChatSettingSubModule] = []
    /// 所有能处理当前context的SubModule
    private var canHandleSubModules: [ChatSettingSubModule] = []

    public static func register(_ type: ChatSettingSubModule.Type) {
        #if DEBUG
        if subModuleTypes.contains(where: { $0 == type }) {
            assertionFailure("ChatSettingSubModule \(type) has already been registered")
        }
        #endif
        Self.subModuleTypes.append(type)
    }

    public override static func onLoad(context: ChatSettingContext) {
        launchLoad()
        // 对subModules依次调用onLoad
        Self.subModuleTypes.forEach({ $0.onLoad(context: context) })
    }

    /// 实例化subModules
    public override func onInitialize() {
        self.subModules = Self.subModuleTypes.filter({ $0.canInitialize(context: self.context) })
            .map({ $0.init(context: self.context) })
        self.subModules.forEach({ $0.registServices(container: self.context.container) })
    }

    /// subModules -> canHandleSubModules
    @discardableResult
    public override func handler(model: ChatSettingMetaModel) -> [Module<ChatSettingContext, ChatSettingMetaModel>] {
        let oldModules = self.canHandleSubModules

        self.canHandleSubModules = []
        self.subModules.forEach { (module) in
            // 如果能处理
            if module.canHandle(model: model) {
                // 遍历hander结果
                (module.handler(model: model) as? [ChatSettingSubModule] ?? []).forEach { (subModule) in
                    // 如果之前为true，则直接添加
                    if oldModules.contains(where: { $0.name == subModule.name }) {
                        self.canHandleSubModules.append(module)
                    } else {
                        // 如果之前为false，则判断现在是否能为true
                        if subModule.shouldActivatyChanged(to: true) {
                            subModule.beginActivaty()
                            self.canHandleSubModules.append(module)
                        }
                    }
                }
            } else { // 如果不能处理
                // 如果之前为true，则判断现在是否能为false
                if oldModules.contains(where: { $0.name == module.name }) {
                    if module.shouldActivatyChanged(to: false) {
                        module.endActivaty()
                    } else {
                        self.canHandleSubModules.append(module)
                    }
                }
            }
        }
        return [self]
    }

    public override func modelDidChange(model: ChatSettingMetaModel) {
        self.canHandleSubModules.forEach({ $0.modelDidChange(model: model) })
    }

    public override func onRefresh() {
        self.canHandleSubModules.forEach({ $0.onRefresh() })
    }

    public func items() -> [ChatSettingCellVMProtocol] {
        return self.canHandleSubModules.flatMap({ $0.items })
    }

    public func cellIdToTypeDic() -> [String: UITableViewCell.Type] {
        var dic = [String: UITableViewCell.Type]()
        self.canHandleSubModules.compactMap({ $0.cellIdToTypeDic }).forEach { idToTypes in
            idToTypes.forEach { item in
                dic[item.key] = item.value
            }
        }
        return dic
    }

    // 搜索工厂类型集合
    public func searchFactoryTypes() -> [ChatSettingSerachDetailItemsFactory.Type] {
        return self.canHandleSubModules.compactMap({ $0.searchItemFactoryTypes }).flatMap({ $0 })
    }

    // 应用工厂类型集合
    public func functionFactoryTypes() -> [ChatSettingFunctionItemsFactory.Type] {
        return self.canHandleSubModules.compactMap({ $0.fuctionItemFactoryTypes }).flatMap({ $0 })
    }

    /// 构造items
    public func createItems(model: ChatSettingMetaModel) {
        self.canHandleSubModules.forEach { (module) in
            module.createItems(model: model)
        }
    }
}
