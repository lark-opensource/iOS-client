//
//  BrowserViewBaseContext.swift
//  SKBrowser
//
//  Created by lijuyou on 2020/7/1.
//  

import Foundation
import SKCommon


public protocol BrowserToolConfig: AnyObject {
    /// 当前工具条编辑模式
    var currentMode: DocsToolbarManager.Mode { get }
    /// 上一次工具条编辑模式
    var lastestMode: DocsToolbarManager.Mode { get }
    /// 键盘跟手监控组件，如果设置自定义编辑器，请设置此模块为对应编辑器的inputAccessoryView
    var keyboardObservingView: DocsKeyboardObservingView { get }
    /// 工具栏(特指用于Docs/Sheet/Mindnote等工具的全局工具栏)
    var toolBar: DocsToolBar { get }
    var toolKeyboardDidShowHeight: CGFloat? { get }
    func embed(_ config: DocsToolbarManager.ToolConfig)
    func unembed(_ config: DocsToolbarManager.ToolConfig)
    func set(_ config: DocsToolbarManager.ToolConfig, mode: DocsToolbarManager.Mode)
    func restore(mode: DocsToolbarManager.Mode)
    func remove(mode: DocsToolbarManager.Mode)
    /// 当前工具frame自行更新时主动调用
    func invalidateToolLayout()
    ///DocsContainer拦截webview上的点击事件 ⚠️使用后一定需要在确定的时机重新将enable设为false
    func setShouldInterceptEvents(to enable: Bool)
    
    
}
