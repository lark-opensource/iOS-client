import LKCommonsLogging

final class GetBodyRecoverRequestID: WebAPIHandler {
    static let logger = Logger.lkwlog(GetBodyRecoverRequestID.self, category: "GetBodyRecoverRequestID")
    
    public override var shouldInvokeInMainThread: Bool { true }
    
    public override func invoke(
        with message: APIMessage,
        webview: LarkWebView,
        callback: APICallbackProtocol
    ) {
        let id = UUID().uuidString
        Self.logger.info("request_id is \(id)")
        callback.callbackSuccess(param: [
            "id": id
        ])
    }
}
