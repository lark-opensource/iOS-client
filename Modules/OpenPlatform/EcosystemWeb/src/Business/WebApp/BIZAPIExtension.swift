// 这个文件的接口是暴露给BIZ API的，请API组删除BIZ API的时候把这个文件删了

import EENavigator
import Foundation
import LarkWebViewContainer
import WebKit
import LarkSplitViewController
import LarkSceneManager
import LarkUIKit
import WebBrowser

/// 该文件存放一些历史遗留对外API
extension WebBrowser {
    
    // MARK: Base UI
    public func showAlert(title: String, message: String, handler: ((UIAlertAction) -> Void)? = nil) {
        Self.logger.info("showAlert: title{\(title)}, message: {\(message)}")
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: BundleI18n.EcosystemWeb.Lark_Legacy_Sure, style: .default, handler: handler)
        alertController.addAction(okAction)
        present(alertController, animated: true)
    }
    
    /// 返回上级浏览页面，如果已经是根页面则会关闭当前浏览窗口
    public func goBack() -> Bool {
        Self.logger.info("goBack with webView.canGoBack(\(webView.canGoBack))")
        goBackOrClose()
        return true
    }

    public func update(title: String?) {
        resolve(NavigationBarMiddleExtensionItem.self)?.setNavigationTitle(browser: self, title: title ?? "")
    }

    public func checkAndUpdateLeftItems() {
        resolve(NavigationBarStyleExtensionItem.self)?.checkAndUpdateSwipeBack(browser: self)
    }

    public func open(url: URL) {
        let req = URLRequest(url: url)
        webview.lwvc_loadRequest(req, prevUrl: nil)
    }

    public func getLeftCloseItem() -> UIBarButtonItem? {
        resolve(NavigationBarLeftExtensionItem.self)?.closeItem
    }

    public func getLeftBackItem() -> UIBarButtonItem? {
        resolve(NavigationBarLeftExtensionItem.self)?.backItem
    }

    @discardableResult
    public func closeVC() -> Bool {
        closeBrowser()
    }

    public func setRightBarButton(_ item: UIBarButtonItem?, animated: Bool) {
        navigationItem.setRightBarButton(item, animated: animated)
    }

    public func setRightBarButtonItems(_ items: [UIBarButtonItem]?, animated: Bool) {
        if isNavigationRightBarExtensionDisable {
            navigationItem.setRightBarButtonItems(items, animated: animated)
        } else {
            if let navigationExtension = resolve(NavigationBarRightExtensionItem.self) {
                if items == nil {
                    navigationExtension.customItems = nil
                    navigationExtension.isHideRightItems = true
                } else {
                    navigationExtension.customItems = items
                    navigationExtension.isHideRightItems = false
                }
                navigationExtension.resetAndUpdateRightItems(browser: self)
            }
        }
    }

    public func setLeftBarButtonItems(_ items: [UIBarButtonItem]?, animated: Bool) {
        navigationItem.setLeftBarButtonItems(insertSpaceForWebNavBar(items), animated: animated) // code from lilun 多scene适配
    }
}
