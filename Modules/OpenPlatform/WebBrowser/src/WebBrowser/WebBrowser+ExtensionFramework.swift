//
//  WebBrowser+ExtensionFramework.swift
//  WebBrowser
//
//  Created by 新竹路车神 on 2021/7/29.
//

import Foundation

extension WebBrowser {
    /// 获取Extension实例 请在主线程调用
    /// - Parameter extensionType: 需要获取的Extension类型
    /// - Returns: Extension实例
    public func resolve<Extension: WebBrowserExtensionItemProtocol>(_ extensionType: Extension.Type) -> Extension? {
        extensionManager.resolve(extensionType)
    }
    
    /// 注册 Extension Item 请在主线程调用
    /// - Parameters:
    ///   - item: 功能 item
    ///   - extensionType: item 类型
    /// - Throws: 错误原因
    public func register<Extension: WebBrowserExtensionItemProtocol>(item: Extension) throws {
        try extensionManager.register(item: item)
    }
    
    /// 获取唯一功能 Extension item 实例 请在主线程调用
    /// - Parameter extensionType: 需要获取的Extension类型
    /// - Returns: Extension实例
    func singleResolve<Extension: WebBrowserExtensionSingleItemProtocol>(_ extensionType: Extension.Type) -> Extension? {
        extensionManager.singleResolve(extensionType)
    }
    
    /// 设置唯一功能 Extension item 实例 请在主线程调用
    /// - Parameter singleItem: 唯一功能 Extension item 实例
    /// - Throws: 错误原因
    public func register<Extension: WebBrowserExtensionSingleItemProtocol>(singleItem: Extension) throws {
        Self.logger.info("register single item:\(singleItem)")
        try extensionManager.register(singleItem: singleItem)
    }
}
