//
//  DocMenuPluginAPIHandler.swift
//  SKCommon
//
//  Created by huayufan on 2022/6/27.
//  


import WebBrowser
import SKFoundation
import Foundation
import SKResource
import LarkWebViewContainer
import UIKit
import UniverseDesignToast
import SKInfra

protocol DocMenuPluginService {
    var handleServices: [DocsJSService] { get }
    func handle(params: [String: Any], serviceName: DocsJSService, callback: APICallbackProtocol?, api: DocMenuPluginWebAPI)
}

protocol DocMenuPluginWebAPI {
    var currentWindow: UIView { get }
    var webBrowser: WebBrowser? { get }
}

protocol DocMenuPluginConfig {
    
    var blackList: [String] { get }
    
    var clipSpecifyEnable: Bool { get }
}

class DefaultDocMenuPluginConfig: DocMenuPluginConfig {

    var blackList: [String] {
        return SettingConfig.clipBlackList?.blackList ?? []
    }
    
    var clipSpecifyEnable: Bool {
        return LKFeatureGating.clipSpecifyEnable
    }
}

class DocMenuPluginAPIHandler: WebAPIHandler {
    
    var methods: [String] {
        services.flatMap {
            return $0.handleServices.map { jsService in
                jsService.rawValue
            }
        }
    }

    /// webview控制器
    weak var webBrowser: WebBrowser?
    
    /// 弱引用LarkWebview Bridge对象
    weak var lkwBridge: LarkWebViewBridge?
    
    var services: [DocMenuPluginService] = []
    
    /// 验证前端接口是否合法（fetch接口）
    let secretKey: String
    
    /// 和webview绑定的唯一标识
    let identifier: String
    
    /// 标记是否注册过bridge
    var registered = false
    
    /// 只记录是否注入过，并不代表webview有注入的代码，比如刷新
    var injected = false
    
    /// 解压资源工具类
    var resourceTool: ClippingResourceTool?
    
    let tracker: ClippingDocReport
    
    let pluginConfig: DocMenuPluginConfig
    
    let checkJsReadyFunc = "checkJsReady()"
    
    init(webBrowser: WebBrowser?, pluginConfig: DocMenuPluginConfig = DefaultDocMenuPluginConfig()) {
        if let wb = webBrowser {
            self.identifier = "\(ObjectIdentifier(wb))"
        } else {
            self.identifier = "-"
            DocsLogger.error("init webBrowser is nil", component: LogComponents.clippingDoc)
        }
        self.secretKey = UUID().uuidString
        let articleUrl = webBrowser?.webview.url?.absoluteString ?? ""
        self.tracker = ClippingDocReport(articleUrl: articleUrl)
        self.pluginConfig = pluginConfig
        super.init()
        self.webBrowser = webBrowser
        self.lkwBridge = webBrowser?.webview.lkwBridge
        setupService()
        resourceTool = try? ClippingResourceTool(traceId: identifier)
    }

    /// 注入剪存代码
    func injectScript() {
        if injected == false {
            beginInjectScript()
        } else {
            checkJsReady { [weak self] isReady in
                guard let self = self, isReady == false else {
                    DocsLogger.info("js has ready, injectScript return", component: LogComponents.clippingDoc, traceId: self?.identifier)
                    return
                }
                self.beginInjectScript()
            }
        }
    }
    
    private func beginInjectScript() {
        loadJSString { [weak self] jsString in
            guard let self = self else { return }
            guard !jsString.isEmpty else {
                DocsLogger.error("loadJSString error", component: LogComponents.clippingDoc, traceId: self.identifier)
                self.tracker.fail(reason: .unknow)
                return
            }
            DocsLogger.info("begin inject", component: LogComponents.clippingDoc, traceId: self.identifier)
            self.evaluateJavaScript(jsString) { [weak self] _, error in
                if error != nil {
                    self?.tracker.fail(reason: .injectFail)
                }
            }
            self.injected = true
        }
    }

    func loadJSString(callback: @escaping ((String) -> Void)) {
#if DEBUG
        // 提供本地文件代理方式加载js文件
        if let url = ClippingDocDebug.url, let data = try? Data.read(from: SKFilePath(absUrl: url)){
            DocsLogger.info("using localhost file", component: LogComponents.clippingDoc, traceId: identifier)
            let jsString = String(data: data, encoding: .utf8) ?? ""
            let str = resolveTemplate(jsString: jsString)
            callback(str)
            UDToast.showSuccess(with: "代理到本地文件", on: currentWindow)
            return
        }
#endif
        let measure = ClipTimeMeasure()
        let extracted = resourceTool?.jsExtractedFile != nil
        resourceTool?.fetchJSResource({ [weak self] (jsString, error) in
            guard let self = self else { return }
            if let jsStr = jsString {
                let t = measure.end()
                DocsLogger.info("cost extract:\(t) ms", component: LogComponents.clippingDoc, traceId: self.identifier)
                let str = self.resolveTemplate(jsString: jsStr)
                callback(str)
                if !extracted {
                    self.tracker.record(stage: .extract, cost: t)
                }
            } else {
                self.tracker.fail(reason: .extractFail)
                DocsLogger.info("fetch js string error:\(error)", component: LogComponents.clippingDoc, traceId: self.identifier)
            }
        })
    }
    
    func resolveTemplate(jsString: String) -> String {
        var jsStr = jsString
        let measure = ClipTimeMeasure()
        let fg = pluginConfig.clipSpecifyEnable
        jsStr = jsStr.replacingOccurrences(of: "{{ secret_key }}", with: self.secretKey)
                 .replacingOccurrences(of: "{{ specify_enable }}", with: "\(fg)")
        let t = measure.end()
        self.tracker.record(stage: .replace, cost: t)
        DocsLogger.info("cost replace:\(t) ms", component: LogComponents.clippingDoc, traceId: identifier)
        return jsStr
    }
    
    override var shouldInvokeInMainThread: Bool {
        return true
    }
    
    typealias OverTimeCallback = (Bool) -> Void
    
    var readyCallback: OverTimeCallback?
    
    override func invoke(with message: APIMessage, webview: LarkWebView, callback: APICallbackProtocol) {
        DocsLogger.info("invoke: \(message.apiName)", component: LogComponents.clippingDoc, traceId: identifier)
        if message.apiName == DocsJSService.notifyJsReady.rawValue {
            readyCallback?(true)
            readyCallback = nil
        }
        let cmd = DocsJSService(rawValue: message.apiName)
        self.services.forEach { service in
            if service.handleServices.contains(cmd) {
                service.handle(params: message.data, serviceName: cmd, callback: callback, api: self)
            }
        }
    }
    
    func checkJsReady(_ callback: @escaping OverTimeCallback) {
        if readyCallback != nil {
            DocsLogger.info("waiting checkJsReady", component: LogComponents.clippingDoc, traceId: identifier)
            return
        }
        readyCallback = callback
        evaluateJavaScript(checkJsReadyFunc) { [weak self] obj, error in
            guard error == nil else {
                return
            }
            func setReady() {
                self?.readyCallback?(true)
                self?.readyCallback = nil
            }
            if let res = obj as? Bool, res {
                setReady()
            } else if let res = obj as? String,
                      res.lowercased() == "true" {
                setReady()
            } else {
                DocsLogger.error("checkJsReady result:\(obj) not supoorted", component: LogComponents.clippingDoc, traceId: self?.identifier)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_2500) { [weak self] in
            guard let self = self else { return }
            if self.readyCallback != nil {
                DocsLogger.error("checkJsReady overtime", component: LogComponents.clippingDoc, traceId: self.identifier)
                self.tracker.fail(reason: .injectTimeout)
                self.readyCallback?(false)
                self.readyCallback = nil
            }
        }
    }
    
    deinit {
        DocsLogger.info("deinit:\(identifier)", component: LogComponents.clippingDoc, traceId: identifier)
    }
}


// MARK: - services
extension DocMenuPluginAPIHandler {
    
    private func setupService() {
        services = [ClippingDocService(secretKey: secretKey,
                                       traceId: identifier,
                                       tracker: tracker)]
    }
    
    /// 往lkwBridge注册bridge，同时强引用DocMenuPluginAPIHandler，
    /// 让其生命周期和webview保持一致
    func register() {
        guard registered == false else {
            return
        }
        DocsLogger.info("begin register", component: LogComponents.clippingDoc, traceId: identifier)
        methods.forEach {
            DocsLogger.info("register \($0)", component: LogComponents.clippingDoc, traceId: identifier)
            self.lkwBridge?.registerAPIHandler(self, name: $0)
        }
        registered = true
    }
}


// MARK: - native-js通信
extension DocMenuPluginAPIHandler: DocMenuPluginWebAPI {

    var currentWindow: UIView {
        return webBrowser?.view.window ?? UIView()
    }

    /// 通过LarkWebViewJavaScriptBridge.nativeCallBack(\(str))方式调用前端方法
    func callFunction(_ function: String, params: [String: Any], completionHandler: ((Any?, Error?) -> Void)?) {
        guard let jsStr = try? LarkWebViewBridge.buildCallBackJavaScriptString(
            callbackID: function,
            params: params,
            extra: nil,
            type: .success) else {
                DocsLogger.error("construct params error", component: LogComponents.clippingDoc, traceId: identifier)
                return
        }
        evaluateJavaScript(jsStr, completionHandler: nil)
    }
    
    /// 通过裸调方式调用前端方法
    func evaluateJavaScript(_ javaScriptString: String, completionHandler: ((Any?, Error?) -> Void)?) {
        webBrowser?.webView.evaluateJavaScript(javaScriptString, completionHandler: { [weak self] (obj, error) in
            guard let self = self else { return }
            completionHandler?(obj, error)
            if let err = error {
                let base64Error = err.localizedDescription.data(using: .utf8)?.base64EncodedString() ?? ""
                DocsLogger.error("evaluateJavaScript error:\(base64Error)", component: LogComponents.clippingDoc, traceId: self.identifier)
            }
        })
    }
}
