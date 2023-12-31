//
//  OpenAPIRequiredExtension.swift
//  LarkOpenPluginManager
//
//  Created by baojianjun on 2023/6/7.
//

import Foundation
import LarkContainer

/**
 从API派发框架获取基础服务
 
 -- Discussion:
 
 在`pluginManager`注册当前容器`SomeCommonExtension`的实现者，
 并在`OpenBaseExtension`子类处通过该propertyWrapper获取对应服务。
 
 -- Warning:
 
 只允许在`OpenBaseExtension`的子类中使用该propertyWrapper, 并且只允许获取基础服务实现
 
 
 -- 使用方式：
 ```
 public protocol SomeCommonExtension { ... }
 
 // API公共逻辑处
 final class OpenSomeAPIExtension: OpenBaseExtension {
    @OpenAPIRequiredExtension
    public var someExtension: SomeCommonExtension
 
     public override var autoCheckProperties: [OpenAPIInjectExtension] {
         [_someExtension]
     }
 }
 
 // PluginManager
 pluginManager.register(SomeCommonExtension.self) { _ in
    SomeCommonExtensionGadgetImpl()
 }
 
 // SomeAPIExtension某一实现者
 final class SomeCommonExtensionGadgetImpl: SomeCommonExtension { ... }
 
 final class SomeCommonExtensionWebImpl: SomeCommonExtension { ... }
 
 ```
 */
@propertyWrapper
public final class OpenAPIRequiredExtension<Extension>: OpenAPIInjectExtension {
    public func configAndCheck(with extensionResolver: ExtensionResolver, context: OpenAPIContext) throws {
        value = try extensionResolver.resolve(Extension.self, arguments: context)
    }
    
    private var value: Extension?
    
    public private(set) var wrappedValue: Extension {
        set { value = newValue }
        get {
            assert(value != nil, "value should not be nil")
            return value!
        }
    }
    
    public init() { }
}
