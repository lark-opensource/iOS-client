//
//  BaseKeyboardSubModule.swift
//  LarkOpenChat
//
//  Created by liluobin on 2023/3/17.
//

import UIKit
import LarkOpenIM
import LarkKeyboardView
import Swinject

open class BaseKeyboardPlugInModule<C: KeyboardContext, M: KeyboardMetaModel>: BaseKeyboardSubModule<C, M> {

    override class var markID: String { "BaseKeyboardPlugInModule" }

    var subModuleTypes: [BaseKeyboardSubModule<C, M>.Type] {
        return Self.getRegisterSubModuleTypes()
    }
    /// 所有实例化的直接SubModule
    var subModules: [BaseKeyboardSubModule<C, M>] = []
    /// 所有能处理当前context的SubModule
    var canHandleSubModules: [BaseKeyboardSubModule<C, M>] = []

    public override func onInitialize() {
        self.subModules = subModuleTypes.filter({ $0.canInitialize(context: self.context) })
            .map({ $0.init(context: self.context) })
        self.subModules.forEach({ $0.registServices(container: self.context.container) })
    }

    public override func modelDidChange(model: M) {
        self.canHandleSubModules.forEach({ $0.modelDidChange(model: model) })
    }

    open override func canHandle(model: M) -> Bool {
        return true
    }

    /// subModules -> canHandleSubModules
    @discardableResult
    public override func handler(model: M) -> [Module<C, M>] {
        self.canHandleSubModules = []
        self.subModules.forEach { (module) in
            // 如果能处理
            if module.canHandle(model: model) {
                // 遍历hander结果
                module.handler(model: model).forEach { (_) in
                    self.canHandleSubModules.append(module)
                }
            }
        }
        return [self]
    }

    /// 注册subModule
    public static func register(_ type: BaseKeyboardSubModule<C, M>.Type) {
        #if DEBUG
        if getRegisterSubModuleTypes().contains(where: { $0 == type }) {
            assertionFailure("BaseKeyboardPanelModule \(type) has already been registered")
        }
        #endif
        addRegisterSubModuleType(type)
    }

    open override func viewWillAppear() {
        for module in self.canHandleSubModules {
            module.viewWillAppear()
        }
    }

    open override func viewDidAppear() {
        for module in self.canHandleSubModules {
            module.viewDidAppear()
        }
    }

    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        for module in self.canHandleSubModules {
            module.viewWillTransition(to: size, with: coordinator)
        }
    }

    open override func splitDisplayModeChange() {
        for module in self.canHandleSubModules {
            module.splitDisplayModeChange()
        }

    }

    open override func splitSplitModeChange() {
        for module in self.canHandleSubModules {
            module.splitSplitModeChange()
        }
    }
    /// Keyboard相关的UI初始化
    open override func keyboardPanelInit() {
        self.canHandleSubModules.forEach { module in
            module.keyboardPanelInit()
        }
    }

    open override func keyboardPanelDidLayoutIcon() {
        self.canHandleSubModules.forEach { module in
            module.keyboardPanelDidLayoutIcon()
        }
    }

    open class func addRegisterSubModuleType(_ type: BaseKeyboardSubModule<C, M>.Type) {
        assertionFailure("need override")
    }

    open class func getRegisterSubModuleTypes() -> [BaseKeyboardSubModule<C, M>.Type] {
        return []
    }

}

open class BaseKeyboardPanelModule<C: KeyboardContext, M: KeyboardMetaModel>: BaseKeyboardPlugInModule<C, M> {

    override class var markID: String { "BaseKeyboardPanelModule" }

    /// 指定PanelItems的顺序
    open var itemsOrder: [KeyboardItemKey] {
        assertionFailure("must be override")
        return []
    }

    open var whiteList: [KeyboardItemKey]? {
        return nil
    }

    override open func keyboardPanelInit() {
        super.keyboardPanelInit()
        reloadPanelItems()
    }

    open func reloadPanelItems() {
        self.canHandleSubModules.forEach { module in
            (module as? BaseKeyboardPanelSubItemModule)?.createItem()
        }
    }

    open func getPanelItems() -> [InputKeyboardItem] {
        var newItems: [InputKeyboardItem] = []
        let items = self.canHandleSubModules.flatMap { module in
            return (module as? BaseKeyboardPanelSubItemModule)?.getItems() ?? []
        }
        itemsOrder.forEach { key in
            if let item = items.first(where: { $0.key == key.rawValue }) {
                newItems.append(item)
            }
        }
        if let whiteList = self.whiteList {
            newItems = newItems.compactMap({ item in
                return whiteList.contains(where: { $0.rawValue == item.key }) ? item : nil
            })
        }
        return newItems
    }
}


open class BaseKeyboardSubModule<C: KeyboardContext, M: KeyboardMetaModel>: Module<C, M> {

    class var markID: String { "BaseKeyboardSubModule" }

    open override class func canInitialize(context: C) -> Bool {
        return true
    }

    open override func canHandle(model: M) -> Bool {
        return true
    }

    open func keyboardPanelInit() {
    }

    open func keyboardPanelDidLayoutIcon() {
    }

    open func viewWillAppear() {
    }

    open func viewDidAppear() {
    }

    open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    }

    open func splitDisplayModeChange() {
    }

    open func splitSplitModeChange() {
    }
}

open class BaseKeyboardPanelSubItemModule<C: KeyboardContext, M: KeyboardMetaModel> : BaseKeyboardSubModule<C, M> {

    open var panelItemKey: KeyboardItemKey {
        return .unknown
    }

    override class var markID: String { "BaseKeyboardPanelSubItemModule" }

    open func createItem() {
        assertionFailure("must be override")
    }

    open func getItems() -> [InputKeyboardItem] {
        assertionFailure("must be override")
        return []
    }
}
