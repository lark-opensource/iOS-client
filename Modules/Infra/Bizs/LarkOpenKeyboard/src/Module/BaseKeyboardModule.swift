//
//  BaseKeyboardModule.swift
//  LarkOpenChat
//
//  Created by liluobin on 2023/3/17.
//

import UIKit
import LarkOpenIM
import LarkContainer
import LarkKeyboardView

open class BaseKeyboardModule<C: KeyboardContext, M: KeyboardMetaModel>: Module<C, M> {

    override open class var loadableKey: String {
        return "openKeyboard"
    }

    open var subModuleTypes: [BaseKeyboardPlugInModule<C, M>.Type] {
        return Self.getRegisterSubModuleTypes()
    }

    /// 所有实例化的直接SubModule
    private var subModules: [BaseKeyboardPlugInModule<C, M>] = []

    /// 所有能处理当前context的SubModule
    private var canHandleSubModules: [BaseKeyboardPlugInModule<C, M>] = []

    open override func onInitialize() {
        self.subModules = subModuleTypes.filter({ $0.canInitialize(context: self.context) }).map({ value in
            value.init(context: self.context)
        })

        self.subModules.forEach({ $0.registServices(container: self.context.container) })
    }

    public override func modelDidChange(model: M) {
        self.canHandleSubModules.forEach({ $0.modelDidChange(model: model) })
    }

    /// subModules -> canHandleSubModules
    @discardableResult
    public override func handler(model: M) -> [Module<C, M>] {
        self.canHandleSubModules = []
        self.subModules.forEach { (module) in
            // 如果能处理
            if module.canHandle(model: model) {
                // 遍历hander结果
                (module.handler(model: model) as? [BaseKeyboardPlugInModule] ?? []).forEach { (_) in
                    self.canHandleSubModules.append(module)
                }
            }
        }
        return [self]
    }

    /// 所在的VC 生命周期 viewWillAppear
    public func viewWillAppear() {
        for module in self.canHandleSubModules {
            module.viewWillAppear()
        }
    }

    /// 所在的VC 生命周期 viewDidAppear
    public func viewDidAppear() {
        for module in self.canHandleSubModules {
            module.viewDidAppear()
        }
    }

    /// 所在的VC 生命周期 viewWillTransition
    public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        for module in self.canHandleSubModules {
            module.viewWillTransition(to: size, with: coordinator)
        }
    }

    /// 所在的VC 生命周期 splitDisplayModeChange
    public func splitDisplayModeChange() {
        for module in self.canHandleSubModules {
            module.splitDisplayModeChange()
        }
    }

    /// 所在的VC 生命周期 splitSplitModeChange
    public func splitSplitModeChange() {
        for module in self.canHandleSubModules {
            module.splitSplitModeChange()
        }
    }

    public func keyboardPanelInit() {
        for module in self.canHandleSubModules {
            module.keyboardPanelInit()
        }
    }

    public func keyboardPanelDidLayoutIcon() {
        for module in self.canHandleSubModules {
            module.keyboardPanelDidLayoutIcon()
        }
    }

    /// 注册subModule
    public static func register(_ type: BaseKeyboardPlugInModule<C, M>.Type) {
        #if DEBUG
        if getRegisterSubModuleTypes().contains(where: { $0 == type }) {
            assertionFailure("ChatNavigationBarSubModule \(type) has already been registered")
        }
        #endif
        addRegisterSubModuleType(type)
    }

    open class func addRegisterSubModuleType(_ type: BaseKeyboardPlugInModule<C, M>.Type) {
        assertionFailure("need override")
    }

    open class func getRegisterSubModuleTypes() -> [BaseKeyboardPlugInModule<C, M>.Type] {
        return []
    }

    public static func registerPanelSubModule(_ subType: BaseKeyboardPanelSubItemModule<C, M>.Type) {
        self.getRegisterSubModuleTypes().forEach { type in
            if type.markID == BaseKeyboardPanelModule<C, M>.markID {
                type.register(subType)
            }
        }
    }

    /// 根据panelItem的key获取具体的subModule
    public func getPanelSubModuleForItemKey(_ key: KeyboardItemKey) -> BaseKeyboardPanelSubItemModule<C, M>? {
        let item = self.subModules.first { ($0 as? BaseKeyboardPanelModule<C,M>) != nil }
        let value = item?.subModules.first(where: { subModule in
            if let panelSubItemModule = subModule as? BaseKeyboardPanelSubItemModule<C,M> {
                return panelSubItemModule.panelItemKey == key
            }
            return false
        })
        if value == nil {
            assertionFailure("may be you name is error")
        }
        return value as? BaseKeyboardPanelSubItemModule
    }

    /// 获取某个类型的Module, 精确获取
    public func getPanelSubModuleInstanceForModuleClass(_ moduleClass: BaseKeyboardPanelSubItemModule<C, M>.Type) ->
    BaseKeyboardPanelSubItemModule<C, M>? {
        let item = self.subModules.first { ($0 as? BaseKeyboardPanelModule<C,M>) != nil }
        let value = (item?.subModules.first(where: { a in
            return type(of: a) == moduleClass
        }))
        if value == nil {
            assertionFailure("may be you moduleClass is error")
        }
        return value as? BaseKeyboardPanelSubItemModule
    }
}


extension BaseKeyboardModule {
    /// 获取可用的右侧按钮
    public func getPanelItems() -> [InputKeyboardItem] {
        let module = self.canHandleSubModules.first { ($0 as? BaseKeyboardPanelModule) != nil }
        return (module as? BaseKeyboardPanelModule)?.getPanelItems() ?? []
    }
    /// 创建右侧按钮
    public func reloadPanelItems() {
        let module = self.canHandleSubModules.first { ($0 as? BaseKeyboardPanelModule) != nil }
        (module as? BaseKeyboardPanelModule)?.reloadPanelItems()
    }

    /// 获取PanelModule
    public func getKeyboardPanelModule() -> BaseKeyboardPanelModule<C, M>? {
        return self.subModules.first { $0 as? BaseKeyboardPanelModule != nil } as? BaseKeyboardPanelModule<C, M>
    }

}
