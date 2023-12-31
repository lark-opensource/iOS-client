import LarkWebViewContainer
import LKCommonsLogging
import WebKit
private let logger = Logger.webBrowserLog(FallbackExtensionItem.self, category: "FallbackExtensionItem")
final public class FallbackExtensionItem: WebBrowserExtensionItemProtocol {
    public var itemName: String? = "Fallback"
    //  不包括Browser加载的第一个URL
    private var fallbackUrls: [URL]
    public lazy var navigationDelegate: WebBrowserNavigationProtocol? = FallbackWebBrowserNavigation(item: self)
    var succeed = false
    public init(fallbackUrls: [URL]) {
        self.fallbackUrls = fallbackUrls
    }
    func handleError(browser: WebBrowser, error: Error) {
        if succeed {
            return
        }
        if fallbackUrls.isEmpty {
            return
        }
        let nextFallbackUrl = fallbackUrls.removeFirst()
        browser.loadURL(nextFallbackUrl)
    }
}
final public class FallbackWebBrowserNavigation: WebBrowserNavigationProtocol {
    private weak var item: FallbackExtensionItem?
    init(item: FallbackExtensionItem) {
        self.item = item
    }
    public func browser(_ browser: WebBrowser, didFail navigation: WKNavigation!, withError error: Error) {
        item?.handleError(browser: browser, error: error)
    }
    public func browser(_ browser: WebBrowser, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        item?.handleError(browser: browser, error: error)
    }
    public func browser(_ browser: WebBrowser, didFinish navigation: WKNavigation!) {
        item?.succeed = true
    }
}
