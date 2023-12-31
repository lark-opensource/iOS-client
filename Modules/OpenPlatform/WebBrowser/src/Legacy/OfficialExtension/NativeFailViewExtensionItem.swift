import Foundation
import LKCommonsLogging
import UniverseDesignEmpty
import WebKit
import LarkSetting
final public class NativeFailViewExtensionItem: WebBrowserExtensionItemProtocol {
    public var itemName: String? = "NativeFailView"
    static let logger = Logger.webBrowserLog(NativeFailViewExtensionItem.self, category: "NativeFailViewExtensionItem")
    public lazy var navigationDelegate: WebBrowserNavigationProtocol? = NativeFailViewWebBrowserNavigation(item: self)
    private weak var browser: WebBrowser?
    private var failView: UIView?
    public init(browser: WebBrowser) {
        self.browser = browser
    }
    func showFailView(browser: WebBrowser, error: Error) {
        if let error = error as? NSError, let url = error.userInfo[NSURLErrorFailingURLErrorKey] as? URL {
            // 包含明确的错误页面 URL，更新当前的 failingURL
            browser.failingURL = url
        } else {
            Self.logger.info("showFailView without failingURL")
            // 如果不包含明确的错误页面 URL，那么就不要添乱了，交给其他的默认逻辑
            browser.failingURL = nil
        }
        let fail = createFailView(error: error)
        failView = fail
        browser.view.addSubview(fail)
        fail.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        if browser.enableDarkModeOptimization {
            let canOptimizeCommit = FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.optimizecommit.enable"))// user:global
            if canOptimizeCommit {
                browser.webview.isHidden = WebBrowser.isDarkMode()
            }else{
                browser.webview.removeFromSuperview()
            }
        }
    }
    private func createFailView(error: Error) -> UIView {
        let error = error as NSError
        var des: UniverseDesignEmpty.UDEmptyConfig.Description? = .init(descriptionText: BundleI18n.WebBrowser.OpenPlatform_AppErrPage_PageLoadFailedErrDesc(errorDesc: error.localizedDescription, errorCode: error.code))
        let bgview = UIView()
        bgview.backgroundColor = UIColor.ud.bgBody
        let empty = UDEmpty(
            config: .init(
                title: .init(titleText: BundleI18n.WebBrowser.loading_failed),
                description: des,
                type: .loadingFailure,
                primaryButtonConfig: (BundleI18n.WebBrowser.Lark_Legacy_WebRefresh, { [weak self] (_) in
                    guard let self = self else { return }
                    Self.logger.info("tap failView to reload")
                    self.reload()
                })
            )
        )
        bgview.addSubview(empty)
        empty.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.right.equalToSuperview()
        }
        return bgview
    }
    private func reload() {
        guard let browser = browser else { return }
        browser.reload()
    }
    func removeFailView() {
        browser?.failingURL = nil
        failView?.removeFromSuperview()
        failView = nil
    }
    fileprivate func handleError(browser: WebBrowser, error: Error) {
        Self.logger.error("load page error", additionalData: ["url": browser.browserURL?.safeURLString ?? ""], error: error)
        guard WKNavigationDelegateFailFix.isFatalWebError(error: error) else {
            Self.logger.warn("not fatal web error.")
            return
        }
        showFailView(browser: browser, error: error)
    }
}
final public class NativeFailViewWebBrowserNavigation: WebBrowserNavigationProtocol {
    private weak var item: NativeFailViewExtensionItem?
    init(item: NativeFailViewExtensionItem) {
        self.item = item
    }
    public func browser(_ browser: WebBrowser, didStartProvisionalNavigation navigation: WKNavigation!) {
        item?.removeFailView()
    }
    public func browser(_ browser: WebBrowser, didFail navigation: WKNavigation!, withError error: Error) {
        item?.handleError(browser: browser, error: error)
    }
    public func browser(_ browser: WebBrowser, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        item?.handleError(browser: browser, error: error)
    }
}

