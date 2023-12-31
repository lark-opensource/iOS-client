//
//  MessageActionSubModule.swift
//  LarkOpenChat
//
//  Created by Zigeng on 2023/1/18.
//

import Foundation
import LarkOpenIM
import UIKit
import LarkMessageBase

public protocol HasMessageActionType {
    var type: MessageActionType { get }
}

protocol MenuTypeToActionItemsProtocol {
    func mapMenuTypeToActionItems(type: MessageActionType,
                                  actionItems: [MessageActionType: [MessageActionItem]],
                                  interceptedActionTypes: [MessageActionType: MessageActionInterceptedType]) -> [MessageActionItem]

}
extension MenuTypeToActionItemsProtocol {
    func mapMenuTypeToActionItems(type: MessageActionType,
                                  actionItems: [MessageActionType: [MessageActionItem]],
                                  interceptedActionTypes: [MessageActionType: MessageActionInterceptedType]) -> [MessageActionItem] {

        var targetItems: [MessageActionItem] = []
        guard let items = actionItems[type] else { return targetItems }
        switch interceptedActionTypes[type] {
        case .hidden:
              break
        case .disable(let errorMessage):
            targetItems = items.map {
                MessageActionItem(text: $0.text,
                                  icon: $0.icon,
                                  enable: false,
                                  disableActionType: .showToast(errorMessage),
                                  trackExtraParams: $0.trackExtraParams,
                                  tapAction: $0.tapAction)
            }
        case .none:
            targetItems = items
        }
        return targetItems
    }
}

open class BaseMessageActionSubModule<C: MessageActionContext>: Module<C, MessageActionMetaModel>,
                                                                HasMessageActionType, MenuTypeToActionItemsProtocol {
    /// 消息菜单操作的类型
    open var type: MessageActionType {
        assertionFailure("must override")
        return .unknown
    }

    /// 一个SubModule可以构造一个消息按钮
    open func createActionItem(model: MessageActionMetaModel) -> MessageActionItem? {
        return nil
    }

    /// 一个SUbModule构造多个按钮
    open func createActionItems(model: MessageActionMetaModel) -> [MessageActionItem]? {
        return nil
    }
}

open class BaseMessageFoldActionSubModule<C: MessageActionContext>: BaseMessageActionSubModule<C> {

    open var subItemOrder: [MessageActionType] {
        assertionFailure("must override")
        return []
    }

    open var subModuleTypes: [BaseMessageActionSubModule<MessageActionContext>.Type] {
        return []
    }
    /// 所有实例化的直接SubModule
    private var subModules: [BaseMessageActionSubModule<MessageActionContext>] = []

    /// 能处理当前context的SubModule
    private var canHandleActionItems: [MessageActionType: [MessageActionItem]] = [:]

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
        self.subModules.forEach { (module) in
            // 如果能处理
            if module.canHandle(model: model) {
                // 遍历hander结果
                (module.handler(model: model) as? [BaseMessageActionSubModule<MessageActionContext>] ?? []).forEach { (_) in
                    if let items = module.createActionItems(model: model) {
                        self.canHandleActionItems.updateValue(items, forKey: module.type)
                    } else if let item = module.createActionItem(model: model) {
                        self.canHandleActionItems.updateValue([item], forKey: module.type)
                    }
                }
            }
        }
        return [self]
    }

    /// 获取essageActionItem
    public func getActionItems(_ foldItems: [MessageActionItem],
                               interceptedActionTypes: [MessageActionType: MessageActionInterceptedType]) -> [MessageActionItem] {
        let types = self.canHandleActionItems.keys
        var sortTypes: [MessageActionType] = []
        self.subItemOrder.forEach { type in
            if types.first(where: { $0 == type }) != nil {
                sortTypes.append(type)
            }
        }
        let subItems = sortTypes.flatMap { type -> [MessageActionItem] in
            return self.mapMenuTypeToActionItems(type: type,
                                                 actionItems: canHandleActionItems,
                                                 interceptedActionTypes: interceptedActionTypes)
        }
        var targetItems = foldItems.map { item in
            var newItem = item
            newItem._subItems = subItems
            return newItem
        }
        targetItems = beforeApplyMenuActionItem(targetItems)
        return targetItems
    }

    /// 如果是层级展示的 在最终应用前 会进行调用，业务可以根据情况条状实际展示
    open func beforeApplyMenuActionItem(_ items: [MessageActionItem]) -> [MessageActionItem] {
        return items
    }
}

open class MessageActionSubModule: BaseMessageActionSubModule<MessageActionContext> {}
open class MessageActionFoldSubModule: BaseMessageFoldActionSubModule<MessageActionContext> {}
