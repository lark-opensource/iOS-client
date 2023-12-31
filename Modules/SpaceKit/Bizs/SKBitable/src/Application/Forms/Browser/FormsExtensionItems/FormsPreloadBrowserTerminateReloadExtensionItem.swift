import Foundation
import LKCommonsLogging
import WebBrowser
import WebKit

/// Forms 业务预加载容器渲染进程崩溃自动重试
final public class FormsPreloadBrowserTerminateReloadExtensionItem: WebBrowserExtensionItemProtocol {
    
    public var itemName: String? = "FormsPreloadBrowserTerminateReload"
    
    static let logger = Logger.formsWebLog(FormsPreloadBrowserTerminateReloadExtensionItem.self, category: "FormsPreloadBrowserTerminateReloadExtensionItem")
    
    public lazy var navigationDelegate: WebBrowserNavigationProtocol? = FormsPreloadBrowserTerminateReloadWebBrowserNavigation()
    
    public init() {
        Self.logger.info("FormsPreloadBrowserTerminateReloadExtensionItem init")
    }
    
    deinit {
        Self.logger.info("FormsPreloadBrowserTerminateReloadExtensionItem deinit")
    }

}

final public class FormsPreloadBrowserTerminateReloadWebBrowserNavigation: WebBrowserNavigationProtocol {
    
    static let logger = Logger.formsWebLog(FormsPreloadBrowserTerminateReloadWebBrowserNavigation.self, category: "FormsPreloadBrowserTerminateReloadWebBrowserNavigation")
    
    private var webContentProcessTerminateCount = 0
    
    public init() {
        Self.logger.info("FormsPreloadBrowserTerminateReloadWebBrowserNavigation init")
    }
    
    deinit {
        Self.logger.info("FormsPreloadBrowserTerminateReloadWebBrowserNavigation deinit")
    }
    
    public func browserWebContentProcessDidTerminate(_ browser: WebBrowser) {
        if browser.webview.isVisible() {
            Self.logger.info("browserWebContentProcessDidTerminate and isVisible, call browser.reload()")
            browser.reload()
        } else {
            if webContentProcessTerminateCount > FormsConfiguration.preloadFormsBrowserMaxTerminateCount() {
                Self.logger.info("browserWebContentProcessDidTerminate and not visible and terminate count over max, destory preload browser")
                try? browser
                    .resolver?
                    .resolve(
                        assert: FormsBrowserManager.self
                    )
                    .formsPreloadBrowser = nil
            } else {
                Self.logger.info("browserWebContentProcessDidTerminate and not visible bot terminate count not over max, call browser.reload()")
                browser.reload()
            }
            
            webContentProcessTerminateCount = webContentProcessTerminateCount + 1
        }
    }
}
