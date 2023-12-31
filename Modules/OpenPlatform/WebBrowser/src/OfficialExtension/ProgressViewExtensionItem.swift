import Foundation
import LKCommonsLogging
import SnapKit
import UniverseDesignProgressView
import WebKit
import LarkSetting

final public class ProgressViewExtensionItem: WebBrowserExtensionItemProtocol, WebBrowserProtocol {
    public var itemName: String? = "ProgressView"
    static let logger = Logger.webBrowserLog(ProgressViewExtensionItem.self, category: "ProgressViewExtensionItem")
    public lazy var lifecycleDelegate: WebBrowserLifeCycleProtocol? = ProgressViewWebBrowserLifeCycle(item: self)
    public lazy var browserDelegate: WebBrowserProtocol? = ProgressViewBrowserDelegate(item: self)
    public let progressView = UDProgressView()
    private var currentProgress = 0.0
    public init() {}
    fileprivate func setupProgress(browser: WebBrowser) {
        browser.view.addSubview(progressView)
        progressView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
        }
        if self.enableStrategyUpdate() {
            Self.logger.info("webview has init, fake progress changed to 0.4")
            self.progressView.layoutIfNeeded()
            self.changeProgressView(with: 0.4)
        }
        observeEstimatedProgress(browser: browser)
    }
    private var estimatedProgressObservation: NSKeyValueObservation?
    private func observeEstimatedProgress(browser: WebBrowser) {
        estimatedProgressObservation = browser
            .webview
            .observe(
                \.estimatedProgress,
                options: [.old, .new]
            ) { [weak self] (webView, change) in
                guard let self = self, let progress = change.newValue else { return }
                Self.logger.info("estimated progress changed from \(change.oldValue) to \(progress)")
                self.changeProgressView(with: CGFloat(progress))
            }
    }
    func changeProgressView(with value: CGFloat) {
        var newValue = value
        if self.enableStrategyUpdate() {
            if (newValue < self.currentProgress) {
                newValue = self.currentProgress //新值小于currentProgress，继续使用currentProgress
            } else {
                self.currentProgress = newValue //新值大于等于currentProgress，更新currentProgress
            }
        }
        
        progressView.setProgress(newValue, animated: false)
        if newValue > 0 && newValue < 1 {
            if progressView.isHidden {
                progressView.isHidden = false
            }
            return
        }
        //  如果是0（刚开始加载）则需要展示出来 1（加载完毕）则需要隐藏
        let hidden = newValue >= 1
        progressView.isHidden = hidden
    }
    
    private func enableStrategyUpdate() -> Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.webbrowser.process.strategyupdate.enable"))// user:global
    }
}
final public class ProgressViewWebBrowserLifeCycle: WebBrowserLifeCycleProtocol {
    private weak var item: ProgressViewExtensionItem?
    init(item: ProgressViewExtensionItem) {
        self.item = item
    }
    public func viewDidLoad(browser: WebBrowser) {
        item?.setupProgress(browser: browser)
    }
}

final public class ProgressViewBrowserDelegate: WebBrowserProtocol {
    
    static let logger = Logger.webBrowserLog(ProgressViewExtensionItem.self, category: "ProgressViewBrowserDelegate")
    private weak var item: ProgressViewExtensionItem?
    
    init(item: ProgressViewExtensionItem) {
        self.item = item
    }
    
    public func browser(_ browser: WebBrowser, willLoadURL url: URL) {
        guard let item = item else {
            return
        }
        
        if FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.webbrowser.process.strategyupdate.enable")) {// user:global
            Self.logger.info("webview ready to load URL, fake progress changed to 0.5")
            item.changeProgressView(with: 0.5)
        }
    }
}
