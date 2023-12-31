//
//  SKBrowserTrace.swift
//  SKCommon
//
//  Created by zengsenyuan on 2021/11/26.
//  


import Foundation


public struct SKBrowserTrace {
    
    /// trace start
    /// 有两种情况会启动 browser，一个是预加载的地方，一个是打开一篇文档的地方。
    public static let openBrowser = create("openBrowser")
    /// trace finish
    public static let closeBrowser = create("closeBrowser")
    /// browser 开始已加载
    public static let browserViewDidLoad = create("browserViewDidLoad")
    /// browser 开始已展示
    public static let browserViewDidAppear = create("browserViewDidAppear")
    /// browser 消失
    public static let browserViewDidDisappear = create("browserViewDidDisappear")
    
    
    // MARK: 这里是对照原来统计秒开率的事件 OpenFileRecord 的 stage 来对应，有适当的增删。 大部分都有 WebLoader 来实现的。
    /// 加载 BrowserView 等 UI 处理，在开始加载 url 之前
    public static let createEditorUI = create("createEditorUI")
    /// 重置 docsInfo 数据
    public static let resetDocsInfo = create("resetDocsInfo")
    /// 如果需要预加载模版的话就调用服务预加载接口
    public static let callPreloadTemplete = create("callPreloadTemplete")
    /// 开始加载合渲染
    public static let loadUrl = create("loadUrl")
    /// 如果需要预加载模版的话就需要等待预加载模版完成
    public static let waitPreloadTemplete = create("waitPreloadTemplete")
    /// 开始拉取货读取本地数据
    public static let pullJS = create("pullJS")
    /// 远端拉去 ClientVar 数据
    public static let getNativeData = create("getNativeData")
    /// 读取本地 Html 缓存
    public static let readLocalHtmlCache = create("readLocalHtmlCache")
    /// 读取本地客户端变量
    public static let readLocalClientVar = create("readLocalClientVar")
    /// 开始渲染本地缓存
    public static let renderLocalCacheHtml = create("renderLocalCacheHtml")
    /// 调用前端的 windowRenader 接口
    public static let callRenderFuc = create("callRenderFuc")
    /// 前端加载 data
    public static let pullData = create("pullData")
    /// 前端渲染内容
    public static let renderDoc = create("renderDoc")
    /// 完成文档打开流程
    public static let openDocFinish = create("openDocFinish")
    
    static func create(_ spanName: String) -> String {
        return "CCM_SKBrowserTrace_" + spanName
    }
}
