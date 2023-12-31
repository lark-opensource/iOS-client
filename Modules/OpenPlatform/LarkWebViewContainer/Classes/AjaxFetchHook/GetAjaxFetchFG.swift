import LKCommonsLogging

final class GetAjaxFetchFG: WebAPIHandler {
    static let logger = Logger.lkwlog(GetAjaxFetchFG.self, category: "GetAjaxFetchFG")
    
    public override var shouldInvokeInMainThread: Bool { true }
    
    public override func invoke(
        with message: APIMessage,
        webview: LarkWebView,
        callback: APICallbackProtocol
    ) {
        Self.logger.info("ajaxFetchHookFG is \(ajaxFetchHookFG)")
        callback.callbackSuccess(param: [
            "result": ajaxFetchHookFG
        ])
    }
}
