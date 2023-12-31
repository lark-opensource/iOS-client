//
//  LarkNativeComponent.swift
//  LarkWebviewNativeComponent
//
//  Created by yi on 2021/9/5.
//
// 通用同层能力对外接口类
// 接入文档：https://bytedance.feishu.cn/docs/doccnU14JPuMnKlpA1x6MMM0z3f
// 方案文档：https://bytedance.feishu.cn/docs/doccnDMvl0QXgEvtqRdNqCHz7eb#

import Foundation
import WebKit
import LarkWebViewContainer
import LKCommonsLogging

public final class LarkNativeComponent {
    static private let logger = Logger.oplog(LarkNativeComponent.self, category: "NativeComponent")

    // 开启native功能，传入的组件只针对于webview实例
    public class func enableNativeComponent(webView: LarkWebView, components: [OpenNativeBaseComponent.Type]) {
        webView.openc_enableBridge() // 开启组件bridge
        webView.op_registerNativeComponents(components) // 注册组件
    }

    // 注册native组件，只对传入webview实例生效
    public class func registerNativeComponents(webView: LarkWebView, components: [OpenNativeBaseComponent.Type]) {
        webView.op_registerNativeComponents(components)
    }

    // 清理webview 实例
    public class func clearNativeComponents(webView: LarkWebView) {
        webView.op_nativeComponentManager().removeAllComponents(webView: webView)
    }
}
