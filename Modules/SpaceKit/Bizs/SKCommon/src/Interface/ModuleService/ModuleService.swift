//
//  ModuleService.swift
//  SKCommon
//
//  Created by lijuyou on 2020/6/7.
//  


import Foundation
import LarkContainer

public protocol ModuleService {

    /// 初始化时调用
    func setup()

    /// 注册路由
    func registerURLRouter()

    /// 注册JSService
    func registerJSServices(type: DocsJSServiceType, ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?, register: (JSServiceHandler) -> Void)

    func userDidLogin()

    func userDidLogout()
}

extension ModuleService {

    public func registerURLRouter() {}

    public func userDidLogin() {}

    public func userDidLogout() {}

    public func registerJSServices(type: DocsJSServiceType, ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?, register: (JSServiceHandler) -> Void) {}
}
