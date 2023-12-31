import LarkWebViewContainer
import LarkOPInterface
import LKCommonsLogging
import ECOProbe
import ECOInfra

// MARK: - Bridge
extension WebBrowser {
    /// 初始化桥功能
    func setupBridge(webview: LarkWebView) {
        let bridge = webview.lkwBridge
        bridge.disableMonitor = true
        bridge.registerBridge()
        webview.lkwBridge.set(larkWebViewBridgeDelegate: self)
    }
}

extension WebBrowser: LarkWebViewBridgeDelegate {
    public func invoke(with message: APIMessage, webview: LarkWebView, callback: APICallbackProtocol) {
        extensionManager.singleItem?.callAPIDelegate?.recieveAPICall(webBrowser: self, message: message, callback: callback)
    }
}
