//
//  ChatWidgetModule.swift
//  LarkOpenChat
//
//  Created by zhaojiachen on 2023/1/9.
//

import Foundation
import RustPB
import LarkModel
import LarkOpenIM
import Swinject

public final class ChatWidgetModule: Module<ChatWidgetContext, ChatWidgetMetaModel> {
    override public class var loadableKey: String {
        return "OpenChat"
    }

    /// 所有实例化的直接SubModule
    private var subModules: [ChatWidgetSubModule] = []
    /// 所有能处理当前context的SubModule
    private var canHandleSubModules: [ChatWidgetSubModule] = []

    private static var subModuleTypes: [ChatWidgetSubModule.Type] = []
    public static func register(_ type: ChatWidgetSubModule.Type) {
        #if DEBUG
        if ChatWidgetModule.subModuleTypes.contains(where: { $0 == type }) {
            assertionFailure("ChatWidgetSubModule \(type) has already been registered")
        }
        #endif
        ChatWidgetModule.subModuleTypes.append(type)
    }

    public override static func onLoad(context: ChatWidgetContext) {
        launchLoad()
        // 对subModules依次调用onLoad
        ChatWidgetModule.subModuleTypes.forEach({ $0.onLoad(context: context) })
    }

    /// 实例化subModules
    public override func onInitialize() {
        self.subModules = ChatWidgetModule.subModuleTypes
            .filter({ $0.canInitialize(context: self.context) })
            .map({ $0.init(context: self.context) })
        self.subModules.forEach({ $0.registServices(container: self.context.container) })
    }

    /// 对subModules依次调用registGlobalServices
    public override class func registGlobalServices(container: Container) {
        ChatWidgetModule.subModuleTypes.forEach({ $0.registGlobalServices(container: container) })
    }

    /// subModules -> canHandleSubModules
    @discardableResult
    public override func handler(model: ChatWidgetMetaModel) -> [Module<ChatWidgetContext, ChatWidgetMetaModel>] {
        self.canHandleSubModules = []
        self.subModules.forEach { (module) in
            // 如果能处理
            if module.canHandle(model: model) {
                // 遍历hander结果
                (module.handler(model: model) as? [ChatWidgetSubModule] ?? []).forEach { (_) in
                    self.canHandleSubModules.append(module)
                }
            }
        }
        return [self]
    }

    public override func modelDidChange(model: ChatWidgetMetaModel) {
        self.canHandleSubModules.forEach({ $0.modelDidChange(model: model) })
    }

    public func parseWidgetsResponse(response: RustPB.Im_V1_GetChatWidgetsResponse) -> [ChatWidget] {
        var chatWidgets: [ChatWidget] = []
        var sortDic: [Int64: Int] = [:]
        for (index, value) in response.widgets.enumerated() {
            sortDic[value.id] = index
        }
        self.canHandleSubModules.forEach { subModule in
            let widgetPBs = response.widgets.filter { $0.widgetType == subModule.type }
            chatWidgets += subModule.parseWidgetsResponse(widgetPBs: widgetPBs, response: response)

        }
        return chatWidgets.sorted(by: { widget1, widget2 in
            let index1 = sortDic[widget1.id] ?? 0
            let index2 = sortDic[widget2.id] ?? 0
            return index1 < index2
        })
    }

    public func parseWidgetsPush(push: RustPB.Im_V1_PushChatWidgets) -> [ChatWidget] {
        var chatWidgets: [ChatWidget] = []
        var sortDic: [Int64: Int] = [:]
        for (index, value) in push.widgets.enumerated() {
            sortDic[value.id] = index
        }
        self.canHandleSubModules.forEach { subModule in
            let widgetPBs = push.widgets.filter { $0.widgetType == subModule.type }
            chatWidgets += subModule.parseWidgetsPush(widgetPBs: widgetPBs, push: push)

        }
        return chatWidgets.sorted(by: { widget1, widget2 in
            let index1 = sortDic[widget1.id] ?? 0
            let index2 = sortDic[widget2.id] ?? 0
            return index1 < index2
        })
    }

    public func setup() {
        self.canHandleSubModules.forEach { $0.setup() }
    }

    public func canShow(_ metaModel: ChatWidgetCellMetaModel) -> Bool {
        guard let module = self.canHandleSubModules.first(where: { $0.type == metaModel.widget.type }) else { return false }
        return module.canShow(metaModel)
    }

    public func createViewModel(_ metaModel: ChatWidgetCellMetaModel) -> ChatWidgetContentViewModel? {
        guard let module = self.canHandleSubModules.first(where: { $0.type == metaModel.widget.type }) else { return nil }
        return module.createViewModel(metaModel)
    }
}
