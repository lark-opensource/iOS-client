//
//  OpenComponentTypeManager.swift
//  LarkOpenPluginManager
//
//  Created by yi on 2021/8/10.
//
// 组件标签注册
import Foundation
public final class OpenComponentTypeManager {
    private var componentTypeMap: [AnyHashable: AnyClass] = [:] // 局部组件标签map

    static var globalTypeMap: [AnyHashable: AnyClass] = [:] // 全局标签map

    // 注册组件标签
    // component： 组件类，继承自OpenNativeBaseComponent
    public func register(component: OpenNativeBaseComponent.Type) {
        let type = component.nativeComponentName()
        componentTypeMap[type] = component
    }

    // 注册组件标签
    // components：组件类数组
    public func register(components: [OpenNativeBaseComponent.Type]) {
        for component in components {
            register(component: component)
        }
    }

    // 注册单个全局标签
    // component：组件类
    public class func registerGlobal(component: OpenNativeBaseComponent.Type) {
        let type = component.nativeComponentName()
        globalTypeMap[type] = component
    }

    // 根据标签获取组件类
    public func componentClass(type: String) -> AnyClass? {
        var component: AnyClass? = componentTypeMap[type]
        if component == nil {
            component = Self.globalTypeMap[type]
        }
        return component
    }
}
