//
//  LarkWebviewNativeComponent.swift
//  LarkWebviewNativeComponent
//
//  Created by tefeng liu on 2020/10/30.
//

import Foundation
import LarkWebViewContainer

public enum LarkWebviewNativeComponent {

    /// 让实例开启同层渲染组件能力，并注入组件
    /// - Parameters:
    ///   - webview: webview实例
    ///   - compenents: 组件s
    ///   - componentManager: 不传的话使用默认 componentManager 实现
    public static func enableNativeRender(webview: LarkWebView,
                                          compenents: [NativeComponentAble.Type],
                                          componentManager: NativeComponentManageable?) {
        if let componentManager = componentManager {
            webview.componentManager = componentManager
        }
        // webview注册组件
        webview.componentManager.registerComponentType(compenents)
        // webview注册内部接口
        ComponentJSRegister.baseRegister(bridgeManager: webview.componetBridge)
        // webview注册handler
        let bridge = webview.lkwBridge
        bridge.registerBridge()
        bridge.registerAPIHandler(ComponentMessageHandler(webview: webview), name: "nativeTagAction")
    }

    /// 让实例开启同层渲染组件能力，并注入组件
    /// - Parameters:
    ///   - webview: webview实例
    ///   - compenents: 组件s
    public static func enableNativeRender(webview: LarkWebView,
                                          compenents: [NativeComponentAble.Type]) {
        enableNativeRender(webview: webview, compenents: compenents, componentManager: nil)
    }
}


