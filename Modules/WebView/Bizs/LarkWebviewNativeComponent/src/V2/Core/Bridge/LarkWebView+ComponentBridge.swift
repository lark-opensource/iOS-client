//
//  LarkWebView+ComponentBridge.swift
//  LarkWebviewNativeComponent
//
//  Created by yi on 2021/9/1.
//
// 组件能力bridge相关

import Foundation
import LarkWebViewContainer
import LKCommonsLogging
import ECOInfra
import WebKit

enum OpenNativeAPIName: String, CaseIterable {
    case insertNativeComponent
    case updateNativeComponentAttribute
    case deleteNativeComponent
    case nativeComponentDispatchAction
}

extension LarkWebView {
    static private let componentLogger = Logger.oplog(OpenNativeComponentBridgeAPIHandler.self, category: "NativeComponent")

    private struct OPWebViewBridgeAssociatedKeys {
        static var nativeComponentBridgeKey = "NativeComponentBridgeKey" // bridge对象key
    }
    // bridge对象
    var op_nativeComponentBridge: OpenNativeComponentBridge? {
        get {
            return objc_getAssociatedObject(self, &OPWebViewBridgeAssociatedKeys.nativeComponentBridgeKey) as? OpenNativeComponentBridge
        }

        set {
            objc_setAssociatedObject(self,
                &OPWebViewBridgeAssociatedKeys.nativeComponentBridgeKey, newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    // 开启组件bridge功能
    func openc_enableBridge() {
        // 组件bridge
        if op_nativeComponentBridge == nil {
            op_nativeComponentBridge = OpenNativeComponentBridge()
        }
        op_nativeComponentBridge?.webView = self

        // 来自LarkBridge的消息处理
        let handler = OpenNativeComponentMessageHandler(bridge: op_nativeComponentBridge)
        OpenNativeAPIName.allCases.forEach { name in
            lkwBridge.registerAPIHandler(handler, name: name.rawValue)
        }

        // 为bridge注册api
        let apiHandler = OpenNativeComponentBridgeAPIHandler()
        if let bridge = op_nativeComponentBridge {
            apiHandler.registerHandlers(bridge: bridge, view: self)
        }
        Self.componentLogger.info("\(self) \(#function) called")
    }
    
    @objc open func nativeComponentConfigJS(appId: String, windowConfig: [String: AnyHashable]?) -> NativeComponentConfigManager {
        // 小程序场景注入appID
        op_nativeComponentBridge?.appID = appId
        // 注入nativeComponentConfig
        return NativeComponentConfigManager(with: appId, windowConfig: windowConfig)
    }
}

extension WKWebViewConfiguration {
    // doc 那边的逻辑单独保留
    @objc open func lnc_injectJSNativeComponentConfig() {
        /// 新同层渲染（sync && className）设置hook
        NativeComponentInsertSyncHook.tryHookUIScrollView()
        // 是否支持同层，提供给前端用于降级到纯web标签
        var jsUserScriptString = ";window.LarkNativeComponentConfig = window.LarkNativeComponentConfig || {}; window.LarkNativeComponentConfig['supportNativeComponent'] = () => { return true; };"
        if let enableSyncSetting = LarkWebView.op_enableSyncSetting, enableSyncSetting {
            jsUserScriptString.append("window.LarkNativeComponentConfig['nativeComponentSyncEnable'] = () => { return true; };")
        }
        let userScript = WKUserScript(source: jsUserScriptString, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        userContentController.addUserScript(userScript)
    }
}
