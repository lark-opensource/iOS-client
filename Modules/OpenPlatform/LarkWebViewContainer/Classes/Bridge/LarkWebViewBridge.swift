//
//  LarkWebViewBridge.swift
//  WebView
//
//  Created by 新竹路车神 on 2020/8/26.
//

import LKCommonsLogging
import WebKit
import ECOProbe
import LarkSetting
import LarkFeatureGating
import ECOInfra

/// 套件统一Bridge代理 职责是把转换好的API Message等对象派发到代理 建议代理调用套件统一API框架 https://bytedance.feishu.cn/docs/doccnrBlLulgvaVvBJGPi81qUzg
public protocol LarkWebViewBridgeDelegate: AnyObject {
    /// 消息派发方法
    /// - Parameters:
    ///   - message: API 数据结构
    ///   - webview: webview对象
    ///   - callback: 回调
    func invoke(
        with message: APIMessage,
        webview: LarkWebView,
        callback: APICallbackProtocol
    )
}

/// 关联对象使用的key
private var bridgeKey: UInt = 0

/// Bridge 对象配置和获取
public extension LarkWebView {
    /// LarkWebView Bridge对象
    var lkwBridge: LarkWebViewBridge {
        guard let bridge = objc_getAssociatedObject(self, &bridgeKey) as? LarkWebViewBridge else {
            let bridge = LarkWebViewBridge(webView: self)
            objc_setAssociatedObject(
                self,
                &bridgeKey,
                bridge,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
            return bridge
        }
        return bridge
    }
}

private let bridgeLog = Logger.lkwlog(LarkWebViewBridge.self, category: "LarkWebViewBridge")

// MARK: - WebViewBridge
/// 套件统一WebViewBridge 职责是解析协议统一协议派发
@objcMembers
public final class LarkWebViewBridge: NSObject {
    /// 被注入的LarkWebView
    private weak var webView: LarkWebView?

    /// 已注册的 APIHandler（等待API组的套件统一API框架上线后废弃Bridge耦合的Handler管理器 https://bytedance.feishu.cn/docs/doccnrBlLulgvaVvBJGPi81qUzg ）
    private lazy var apiHandlers = [String: APIHandlerProtocol]()
    
    /// 信息派发对象
    private weak var delegate: LarkWebViewBridgeDelegate?
    
    /// 是否关闭 Bridge 调用埋点（如果业务方希望高度自定义 Bridge 全链路埋点，可以关闭内部的埋点节约性能，请谨慎使用）
    public var disableMonitor: Bool = false
    
    static let disableBuildCallBackFailLog = FeatureGatingManager.realTimeManager.featureGatingValue(with: "openplatform.web.buildcallback.log.disable")// user:global


    /// 初始化方法
    /// - Parameter webView: 初始化要求注入 LarkWebView
    fileprivate init(webView: LarkWebView) {
        self.webView = webView
        super.init()
    }

    deinit {
        bridgeLog.info("LarkWebViewBridge deinit")
    }
}

// MARK: - WebViewBridge 注册APIhandler
public extension LarkWebViewBridge {
    /// 注册通用 APIHandler （等待API组的套件统一API框架上线后废弃Bridge耦合的Handler管理器 https://bytedance.feishu.cn/docs/doccnrBlLulgvaVvBJGPi81qUzg ）
    /// - Parameters:
    ///   - handler: APIHandler对象
    ///   - name: handler name
    func registerAPIHandler(_ handler: APIHandlerProtocol, name: String) {
        apiHandlers[name] = handler
        bridgeLog.info("register handler:\(name)")
    }

    /// 反注册 APIHandler （等待API组的套件统一API框架上线后废弃Bridge耦合的Handler管理器 https://bytedance.feishu.cn/docs/doccnrBlLulgvaVvBJGPi81qUzg ）
    /// - Parameter handlerName: API Handler 名
    func unregisterAPIHandler(_ handlerName: String) {
        apiHandlers[handlerName] = nil
        bridgeLog.info("unregister handler:\(handlerName)")
    }

    /// 反注册所有API Handler （等待API组的套件统一API框架上线后废弃Bridge耦合的Handler管理器 https://bytedance.feishu.cn/docs/doccnrBlLulgvaVvBJGPi81qUzg ）
    func unregisterAllAPIHandlers() {
        apiHandlers.removeAll()
        bridgeLog.info("unregister all handler")
    }
}

// MARK: - WebViewBridge 注册反注册通用Bridge通道
public extension LarkWebViewBridge {
    /// 注册 Bridge 信道
    func registerBridge() {
        //  预防业务方重复注册导致Crash 系统方法无法判断是否已经注册invoke
        unregisterBridge()
        webView?.registerBridge(scriptMessageHandler: self)
        bridgeLog.info("registerBridgeChannel")
    }
    
    /// 注册代理
    /// - Parameter larkWebViewBridgeDelegate: 套件统一Bridge代理 建议在代理中调用套件统一API框架，参考文档：https://bytedance.feishu.cn/docs/doccnrBlLulgvaVvBJGPi81qUzg
    func set(larkWebViewBridgeDelegate: LarkWebViewBridgeDelegate) {
        delegate = larkWebViewBridgeDelegate
    }

    /// 反注册 Bridge 信道
    func unregisterBridge() {
        webView?.unregisterBridge()
        bridgeLog.info("unregisterBridgeChannel")
    }
}

// MARK: - WebViewBridge 执行JS
public extension LarkWebViewBridge {
    /// 执行JS方法 仅执行JS方法，如果是执行document.title，请使用原生的evaluateJavaScript
    /// - Parameters:
    ///   - functionName: 方法名
    ///   - params: 参数
    ///   - completionHandler: 回调   对外暴露和原生执行JS方法一致的回调
    func evaluateJS(
        functionName: String,
        params: [String: Any]?,
        completionHandler: ((Any?, Error?) -> Void)? = nil
    ) {
        guard let webView = webView else {
            let opError = OPError.error(monitorCode: BridgeMonitorCode.buildJsStringFailed, message: "webview has deinit, please don't call this function")
            completionHandler?(nil, opError)
            return
        }
        let jsString: String
        do {
            jsString = try buildJavaScript(with: functionName, params: params).transformToExecutableScript()
        } catch {
            let operror = (error as? OPError) ?? error.newOPError(monitorCode: BridgeMonitorCode.buildJsStringFailed)
            completionHandler?(nil, operror)
            return
        }
        webView.evaluateJavaScript(jsString, completionHandler: completionHandler)
    }

    /// 组装JS字符串
    /// - Parameters:
    ///   - functionName: 方法名
    ///   - params: 参数字典
    /// - Throws: 错误
    /// - Returns: JS字符串
    private func buildJavaScript(with functionName: String, params: [String: Any]?) throws -> String {
        guard !functionName.isEmpty else {
            //  方法名为空，抛出异常
            throw OPError.error(monitorCode: BridgeMonitorCode.jsFunctionNameEmpty)
        }
        guard let params = params else {
            return functionName + "()"
        }
        guard JSONSerialization.isValidJSONObject(params) else {
            //  数据不合法，抛出异常
            throw OPError.error(monitorCode: BridgeMonitorCode.invalidJsParams, message: "param is not vaild json object")
        }
        let data = try JSONSerialization.data(withJSONObject: params)
        guard let paramsString = String(data: data, encoding: .utf8) else {
            //  数据不合法，抛出异常
            throw OPError.error(monitorCode: BridgeMonitorCode.invalidJsParams, message: "param data cannot transform to param string")
        }
        guard !paramsString.isEmpty else {
            //  数据不合法，抛出异常
            throw OPError.error(monitorCode: BridgeMonitorCode.invalidJsParams, message: "param data cannot transform to param string")
        }
        return "\(functionName)(\(paramsString))"
    }
}

/// 无权限回调信息
private let noAuthParam = [errMsgKey: "api has no auth"]
/// 未找到handler回调信息
private let noHandlerParam = [errMsgKey: "find no handler"]

// MARK: - WebViewBridge WKScriptMessageHandler
extension LarkWebViewBridge: WKScriptMessageHandler {
    /// JS Call Native, Native 端的统一入口
    /// - Parameters:
    ///   - userContentController: userContentController
    ///   - message: 从JS收到的信息
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let webView = webView else {
            //  这里不会调用到，webview释放的话这个方法就不会执行了
            assertionFailure("system will not call this function")
            return
        }
        var apiInvokeResultEvent: OPMonitor? = OPMonitor(.apiInvokeResult, webview: webView)
            .tracing(webView.trace)
            .timing()
        if disableMonitor {
            apiInvokeResultEvent = nil
        }
        //  组装message
        let apiMessage: APIMessage
        do {
            apiMessage = try getAPIMessage(with: message.body)
        } catch {
            apiInvokeResultEvent?
                .setResultTypeFail()
                .timing()
                .setError((error as? OPError) ?? error.newOPError(monitorCode: BridgeMonitorCode.buildApiMessageFailed))
                .flush()
            return
        }
        apiInvokeResultEvent?.addCategoryValue(.apiName, apiMessage.apiName)

        //  创建回调对象
        let callback = WebAPICallback(webView: webView, callbackID: apiMessage.callbackID, monitor: apiInvokeResultEvent)

        //  派发到代理
        //  寻找handler示例（等待API组的套件统一API框架上线后废弃Bridge耦合的Handler管理器 https://bytedance.feishu.cn/docs/doccnrBlLulgvaVvBJGPi81qUzg ）
        //  套件统一API框架上线后 这里只需要留下 delegate.invoke(with: apiMessage, webview: webView, callback: callback)
        //  原则上Bridge框架只需要关注协议解析协议统一
        guard let handler = apiHandlers[apiMessage.apiName] else {
            guard let delegate = delegate else {
                // 未注册Bridge代理，没找到Handler，流程结束
                executeOnMainQueueAsync {
                    callback.callbackFailure(param: noHandlerParam, extra: nil, error: OPError.error(monitorCode: BridgeMonitorCode.noApiHandler))
                }
                return
            }
            //  最后API需要在什么线程执行，请在套件统一API框架决策，Bridge框架不予处理
            delegate.invoke(with: apiMessage, webview: webView, callback: callback)
            return
        }
        //  下边的代码需要被废弃，所有的消息都走 delegate 排发出去
        //  建议派发出去后使用套件统一API框架管理API
        //  套件统一API框架对应文档：https://bytedance.feishu.cn/docs/doccnrBlLulgvaVvBJGPi81qUzg
        if handler.shouldInvokeInMainThread {
            executeOnMainQueueAsync {
                handler.invoke(with: apiMessage, context: webView, callback: callback)
            }
        } else {
            handler.invoke(with: apiMessage, context: webView, callback: callback)
        }
    }
}

// MARK: - WebViewBridge Provider
extension LarkWebViewBridge {
    /// 获取APIMessage
    /// - Parameter messageBody: JS传入的结构
    /// - Throws: 组装发生的错误
    /// - Returns: APIMessage
    private func getAPIMessage(with messageBody: Any) throws -> APIMessage {
        if let msg = webView?.webviewDelegate?.buildAPIMessage?(with: messageBody) {
            return msg
        }
        /// 组装APIMessage
        /// - Parameter body: JS传入的结构
        /// - Throws: 组装发生的错误
        /// - Returns: APIMessage
        func defaultBuildAPIMessage(with body: Any) throws -> APIMessage {
            guard let messageBody = body as? [AnyHashable: Any] else {
                throw OPError.error(monitorCode: BridgeMonitorCode.buildApiMessageFailed, message: "invaild jsmessage body, is not [AnyHashable: Any]")
            }
            guard let apiName = messageBody[APIMessageKey.apiName.rawValue] as? String else {
                throw OPError.error(monitorCode: BridgeMonitorCode.buildApiMessageFailed, message: "invaild jsmessage body, apiName invaild")
            }
            return APIMessage(
                apiName: apiName,
                data: messageBody[APIMessageKey.data.rawValue] as? [String: Any] ?? [String: Any](),
                callbackID: messageBody[APIMessageKey.callbackID.rawValue] as? String,
                extra: messageBody[APIMessageKey.extra.rawValue] as? [AnyHashable: Any]
            )
        }
        return try defaultBuildAPIMessage(with: messageBody)
    }
}

// MARK: - WebViewBridge Tool Method
extension LarkWebViewBridge {
    public static func buildCallBackJavaScriptString(
        callbackID: String?,
        params: [AnyHashable: Any],
        extra: [AnyHashable: Any]?,
        type: CallBackType
    ) throws -> String {
        var finalMap: [String: Any] = [
            APIMessageKey.callbackID.rawValue: callbackID ?? "",
            APIMessageKey.data.rawValue: params,
            APIMessageKey.callbackType.rawValue: type.rawValue
        ]
        //  如果业务需要补充
        if let extra = extra {
            finalMap[APIMessageKey.extra.rawValue] = extra
        }
        //  避免 finalMap 不合法导致 try JSONSerialization.data(withJSONObject: finalMap) catch 不到
        guard JSONSerialization.isValidJSONObject(finalMap) else {
            var e = OPError.error(monitorCode: BridgeMonitorCode.buildJsStringFailed)
            if !LarkWebViewBridge.disableBuildCallBackFailLog {
                let e = OPError.error(monitorCode: BridgeMonitorCode.buildJsStringFailed, userInfo: finalMap)
                bridgeLog.info("build callback string failed, id:\(callbackID ?? "")  params:\(params), extra:\(String(describing: extra)), type:\(type.rawValue)")
            }
            assertionFailure(e.description)
            throw e
        }
        let data = try JSONSerialization.data(withJSONObject: finalMap)
        let str = String(data: data, encoding: .utf8) ?? ""
        let jsStr = "LarkWebViewJavaScriptBridge.nativeCallBack(\(str))"
        return jsStr
    }
}
