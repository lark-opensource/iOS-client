//
//  WebAPICallback.swift
//  LarkWebViewContainer
//
//  Created by 新竹路车神 on 2020/9/23.
//

import WebKit
import ECOProbe
import ECOInfra

/// 网页API回调对象
class WebAPICallback: APICallbackProtocol {
    /// 网页对象
    private weak var webView: LarkWebView?
    
    /// 回调ID
    private var callbackID: String?
    
    /// api invoke result monitor
    private let monitor: OPMonitor?
    
    /// 回调对象初始化方法
    /// - Parameters:
    ///   - webView: 网页对象
    ///   - callbackID: 回调ID
    init(webView: LarkWebView, callbackID: String?, monitor: OPMonitor?) {
        self.webView = webView
        self.callbackID = callbackID
        self.monitor = monitor
    }
    /// 成功回调
    func callbackSuccess(param: [String: Any], extra: [AnyHashable: Any]?) {
        do {
            try evalCallBack(event: callbackID, params: param, extra: extra, type: .success, error: nil)
        } catch {
            let opError = error as? OPError ?? error.newOPError(monitorCode: BridgeMonitorCode.buildJsStringFailed, message: "callback success failed")
            OPMonitor(.bridgeErrorEvent, webview: webView)
                .setResultTypeFail()
                .setError(opError)
                .timing()
                .flush()
            return
        }
    }
    
    /// 失败回调
    func callbackFailure(param: [String : Any], extra: [AnyHashable: Any]?, error: OPError?) {
        monitor?.setError(error)
        do {
            try evalCallBack(event: callbackID, params: param, extra: extra, type: .failure, error: error)
        } catch {
            let opError = error as? OPError ?? error.newOPError(monitorCode: BridgeMonitorCode.buildJsStringFailed, message: "callback failure failed")
            OPMonitor(.bridgeErrorEvent, webview: webView)
                .setResultTypeFail()
                .setError(opError)
                .timing()
                .flush()
            return
        }
    }
    
    /// 取消回调
    func callbackCancel(param: [String : Any], extra: [AnyHashable: Any]?, error: OPError?) {
        monitor?.setError(error)
        do {
            try evalCallBack(event: callbackID, params: param, extra: extra, type: .cancel, error: error)
        } catch {
            let opError = error as? OPError ?? error.newOPError(monitorCode: BridgeMonitorCode.buildJsStringFailed, message: "callback cancel failed")
            OPMonitor(.bridgeErrorEvent, webview: webView)
                .setResultTypeFail()
                .setError(opError)
                .timing()
                .flush()
            return
        }
    }
    
    /// 发送消息
    func callbackContinued(param: [String: Any], extra: [AnyHashable: Any]?) {
        do {
            try evalCallBack(event: callbackID, params: param, extra: extra, type: .continued, error: nil)
        } catch {
            let opError = error as? OPError ?? error.newOPError(monitorCode: BridgeMonitorCode.buildJsStringFailed, message: "callback continued failed")
            OPMonitor(.bridgeErrorEvent, webview: webView)
                .setResultTypeFail()
                .setError(opError)
                .timing()
                .flush()
            return
        }
    }
    
    /// 发送消息（支持）
    func callbackContinued(
        event: String,
        param: [String: Any],
        extra: [AnyHashable: Any]?
    ) {
        do {
            try evalCallBack(event: event, params: param, extra: extra, type: .continued, error: nil)
        } catch {
            let opError = error as? OPError ?? error.newOPError(monitorCode: BridgeMonitorCode.buildJsStringFailed, message: "callback continued failed")
            OPMonitor(.bridgeErrorEvent, webview: webView)
                .setResultTypeFail()
                .setError(opError)
                .timing()
                .flush()
            return
        }
    }

    /// 执行回调函数
    /// - Parameters:
    ///   - event: 消息名称
    ///   - params: API 参数
    ///   - extra: 业务额外字段
    ///   - type: 回调类型
    ///   - error: 用于埋点的错误对象
    /// - Throws: 组装错误
    private func evalCallBack(event: String?, params: [String: Any], extra: [AnyHashable: Any]?, type: CallBackType, error: OPError?) throws {
        let jsStr = try LarkWebViewBridge.buildCallBackJavaScriptString(
            callbackID: event,
            params: params,
            extra: extra,
            type: type
        )
        webView?.evaluateJavaScript(jsStr, completionHandler: { [weak webView] _, err in
            //  回调
            if let opError = err?.newOPError(monitorCode: BridgeMonitorCode.evaluateJsError, message: "callback cancel js error") {
                OPMonitor(.bridgeErrorEvent, webview: webView)
                    .setError(opError)
                    .setResultTypeFail()
                    .flush()
            }
        })
        //  埋点补充回调类型和可能存在的error对象
        switch type {
        case .success:
            monitor?
                .setResultTypeSuccess()
        case .failure:
            monitor?
                .setResultTypeFail()
                .setError(error)
                .addMap(params)
        case .cancel:
            monitor?
                .setResultTypeCancel()
                .setError(error)
        case .continued:
            monitor?
                .setResultType(type.rawValue)
        }
        monitor?
            .timing()
            .flush()
    }
}
