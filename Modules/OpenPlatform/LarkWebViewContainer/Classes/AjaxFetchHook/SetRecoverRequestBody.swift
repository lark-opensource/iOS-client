import Foundation

final class SetRecoverRequestBody: WebAPIHandler {
    public override var shouldInvokeInMainThread: Bool { true }
    
    public override func invoke(
        with message: APIMessage,
        webview: LarkWebView,
        callback: APICallbackProtocol
    ) {
        let data = message.data
        guard let requestID = data["id"] as? String else { return }
        RecoverRequestBodyManager.shared.setBody(with: requestID, body: data)
        callback.callbackSuccess(param: [
            "id": requestID
        ])
    }
}
