//
//  WebBrowserExtensionManager.swift
//  WebBrowser
//
//  Created by 新竹路车神 on 2021/7/29.
//

import Foundation

enum ExtensionFrameworkError: String, Error {
    case repeatRegistrationExtensionItem
    case repeatRegistrationSingleExtensionItem
}

/**
 套件统一浏览器Extension管理器
 所有方法请在主线程调用
 */
final class WebBrowserExtensionManager {
    
    /// 被管理的 Extension Item 集合
    var items = [WebBrowserExtensionItemProtocol]()
    
    /// 唯一功能 Extension item 实例
    var singleItem: WebBrowserExtensionSingleItemProtocol?
    
    var viewDidLoadedFlag: Bool = false
    
    /// 获取Extension实例
    /// - Parameter extensionType: 需要获取的Extension类型
    /// - Returns: Extension实例
    func resolve<Extension: WebBrowserExtensionItemProtocol>(_ extensionType: Extension.Type) -> Extension? {
        items.filter { $0 as? Extension != nil }.first as? Extension
    }
    
    /// 注册 Extension Item
    /// - Parameters:
    ///   - item: 功能 item
    /// - Throws: 错误原因
    func register<Extension: WebBrowserExtensionItemProtocol>(item: Extension) throws {
        if viewDidLoadedFlag {
            assertionFailure("cannot register extension item after viewDidLoad, name is: \(item.itemName)")
        }
        guard items.filter({ $0 as? Extension != nil }).isEmpty else {
            //  相同功能严禁重复注册
            throw ExtensionFrameworkError.repeatRegistrationExtensionItem
        }
        items.append(item)
    }
    
    /// 获取唯一功能 Extension item 实例
    /// - Parameter extensionType: 需要获取的Extension类型
    /// - Returns: Extension实例
    func singleResolve<Extension: WebBrowserExtensionSingleItemProtocol>(_ extensionType: Extension.Type) -> Extension? {
        singleItem as? Extension
    }
    
    /// 设置唯一功能 Extension item 实例
    /// - Parameter singleItem: 唯一功能 Extension item 实例
    /// - Throws: 错误原因
    func register<Extension: WebBrowserExtensionSingleItemProtocol>(singleItem: Extension) throws {
        if self.singleItem != nil {
            throw ExtensionFrameworkError.repeatRegistrationSingleExtensionItem
        }
        self.singleItem = singleItem
    }
}
