import LKCommonsLogging
import LarkFeatureGating
import LarkSetting
import ECOInfra

private var ajaxFetchHookBridgeKey: UInt = 0

public extension LarkWebView {
    var ajaxFetchHookBridge: AjaxFetchHookScriptMessageHandler {
        guard let bridge = objc_getAssociatedObject(self, &ajaxFetchHookBridgeKey) as? AjaxFetchHookScriptMessageHandler else {
            let bridge = AjaxFetchHookScriptMessageHandler(webView: self)
            objc_setAssociatedObject(
                self,
                &ajaxFetchHookBridgeKey,
                bridge,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
            return bridge
        }
        return bridge
    }
}

public final class AjaxFetchHookScriptMessageHandler: NSObject, WKScriptMessageHandler {
    
    static let disableBuildCallBackFailLog = FeatureGatingManager.realTimeManager.featureGatingValue(with: "openplatform.web.buildcallback.log.disable")// user:global
    
    private weak var webView: LarkWebView?
    
    let apiHandlers: [String: APIHandlerProtocol] = [
        "setRecoverRequestBody": SetRecoverRequestBody(),
        "getBodyRecoverRequestID": GetBodyRecoverRequestID(),
        "getAjaxFetchFG": GetAjaxFetchFG()
    ]
    
    init(webView: LarkWebView) {
        self.webView = webView
        super.init()
    }
    
    public func setAjaxFetchHook() {
        webView?.registerAjaxFetchHookBridge(scriptMessageHandler: self)
    }
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let webView = webView else { return }
        let apiMessage: APIMessage
        do {
            apiMessage = try defaultBuildAPIMessage(with: message.body)
        } catch {
            logger.lkwlog(level: .error, "build api message error", traceId: webView.opTraceId(), error: error)
            return
        }
        guard let handler = apiHandlers[apiMessage.apiName] else {
            logger.lkwlog(level: .error, "has not register \(apiMessage.apiName)", traceId: webView.opTraceId())
            return
        }
        let callback = AjaxFetchHookAPICallback(webView: webView, callbackID: apiMessage.callbackID)
        executeOnMainQueueAsync {
            handler.invoke(with: apiMessage, context: webView, callback: callback)
        }
    }
    
    private func defaultBuildAPIMessage(with body: Any) throws -> APIMessage {
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
}

class AjaxFetchHookAPICallback: APICallbackProtocol {
    
    private weak var webView: LarkWebView?
    
    private var callbackID: String?
    
    init(webView: LarkWebView, callbackID: String?) {
        self.webView = webView
        self.callbackID = callbackID
    }
    func callbackSuccess(param: [String: Any], extra: [AnyHashable: Any]?) {
        do {
            try evalCallBack(event: callbackID, params: param, extra: nil)
        } catch {
            logger.error("eval callback js error", error: error)
        }
    }
    func callbackFailure(param: [String : Any], extra: [AnyHashable: Any]?, error: OPError?) {
    }
    func callbackCancel(param: [String : Any], extra: [AnyHashable: Any]?, error: OPError?) {
    }
    func callbackContinued(param: [String: Any], extra: [AnyHashable: Any]?) {
    }
    func callbackContinued(
        event: String,
        param: [String: Any],
        extra: [AnyHashable: Any]?
    ) {
    }

    private func evalCallBack(event: String?, params: [String: Any], extra: [AnyHashable: Any]?) throws {
        let jsStr = try AjaxFetchHookScriptMessageHandler.buildCallBackJavaScriptString(
            callbackID: event,
            params: params
        )
        webView?.evaluateJavaScript(jsStr)
    }
}


extension AjaxFetchHookScriptMessageHandler {
    static func buildCallBackJavaScriptString(
        callbackID: String?,
        params: [AnyHashable: Any]
    ) throws -> String {
        let finalMap: [String: Any] = [
            APIMessageKey.callbackID.rawValue: callbackID ?? "",
            APIMessageKey.data.rawValue: params,
            APIMessageKey.callbackType.rawValue: CallBackType.success.rawValue
        ]
        guard JSONSerialization.isValidJSONObject(finalMap) else {
            var e = OPError.error(monitorCode: BridgeMonitorCode.buildJsStringFailed)
            if !AjaxFetchHookScriptMessageHandler.disableBuildCallBackFailLog {
                e = OPError.error(monitorCode: BridgeMonitorCode.buildJsStringFailed, userInfo: finalMap)
                logger.error("build ajax callback string failed, callbackID: \(callbackID ?? "")", error: e)
            }
            assertionFailure(e.description)
            throw e
        }
        let data = try JSONSerialization.data(withJSONObject: finalMap)
        let str = String(data: data, encoding: .utf8) ?? ""
        let jsStr = "AjaxFetchHookBridge.callback(\(str))"
        return jsStr
    }
}
