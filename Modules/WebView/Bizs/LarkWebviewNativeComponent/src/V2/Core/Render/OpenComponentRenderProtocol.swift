//
//  OpenComponentRenderProtocol.swift
//  OPPlugin
//
//  Created by yi on 2021/8/11.
//
// 组件渲染能力协议
// 文档：https://bytedance.feishu.cn/docs/doccnbAOwBbFcmMs6t1TyBUpbSc

import Foundation
import WebKit
import LarkWebViewContainer

public protocol OpenComponentRenderProtocol {
    // 插入组件视图
    static func insertComponent(webView: LarkWebView, view: UIView, componentID: String, style: [String : Any]?, completion: @escaping (Bool)->Void)

    // 移除组件视图
    static func removeComponent(webView: LarkWebView, componentID: String) -> Bool

    // 获取组件视图
    static func component(webView: LarkWebView, componentID: String) -> UIView?
    // 更新组件视图
    static func updateComponent(webView: LarkWebView, componentID: String, style: [String : Any]?)
}
