//
//  ComponentManager.swift
//  LarkWebviewNativeComponent
//
//  Created by tefeng liu on 2020/10/30.
//

import Foundation

public protocol NativeComponentManageable: AnyObject {
    /// 唯一标示id 和 组件实例的映射表，弱引用
    var components: [String: WeakComponentWrapper] { get set }
    /// 初始化时注册组件类型
    func registerComponentType(_ types: [NativeComponentAble.Type])
    /// 创建 tagName 对应的组件实例
    func createCompentWithTagName(tagName: String) -> NativeComponentAble?
    /// 添加组件，同层组件添加到webview后调用。提供默认实现，添加到 components
    func insertComponent(component: NativeComponentAble?)
    /// 组件从view移除。提供默认实现，从components移除
    func removeComponent(id: String)
    /// 通过id查找对应组件。提供默认实现，从components中进行查找
    func findComponent(id: String) -> NativeComponentAble?
}

public extension NativeComponentManageable {
    func insertComponent(component: NativeComponentAble?) {
        guard let id = component?.id else {
            return
        }
        components[id] = WeakComponentWrapper(component: component)
    }

    func removeComponent(id: String) {
        components.removeValue(forKey: id)
    }

    func findComponent(id: String) -> NativeComponentAble? {
        guard let wrapper = components[id] else {
            return nil
        }
        if let component = wrapper.component {
            return component
        } else {
            components.removeValue(forKey: id)
            return nil
        }
    }
}

public final class WeakComponentWrapper {
    weak var component: NativeComponentAble?

    init(component: NativeComponentAble?) {
        self.component = component
    }
}

final class ComponentManager {
    /// tagName 和 具体类型的映射表
    fileprivate var componentTypeMap: [String: NativeComponentAble.Type] = [:]

    /// 唯一标示id 和 组件实例的映射表，弱引用
    var components: [String: WeakComponentWrapper] = [:]


    init() {}
}

extension ComponentManager: NativeComponentManageable {
    func registerComponentType(_ types: [NativeComponentAble.Type]) {
        for type in types {
            componentTypeMap[type.tagName] = type
        }
    }

    func createCompentWithTagName(tagName: String) -> NativeComponentAble? {
        guard let type = componentTypeMap[tagName] else {
            return nil
        }
        return type.init()
    }
}
