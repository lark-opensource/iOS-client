import LarkQuickLaunchInterface
import LarkTab
import LKCommonsLogging
import SKFoundation
import WebBrowser
import WebKit

// MARK: - Browser Extension Item
/// 收集表/表单分享页套件统一浏览器插件
final public class FormsExtensionItem: WebBrowserExtensionItemProtocol {
    
    static let logger = Logger.formsWebLog(FormsExtensionItem.self, category: "FormsExtensionItem")
    
    public lazy var lifecycleDelegate: WebBrowserLifeCycleProtocol? = FormsWebBrowserLifeCycle(isFormsBrowser: isFormsBrowser)
    
    public lazy var navigationDelegate: WebBrowserNavigationProtocol? = FormsWebBrowserNavigation(item: self)
    
    public var itemName: String? = "BitableForm"
    
    public let isFormsBrowser: Bool
    
    public init(isFormsBrowser: Bool = false) {
        Self.logger.info("new FormsExtensionItem, isFormsBrowser:\(isFormsBrowser)")
        self.isFormsBrowser = isFormsBrowser
    }
    
    deinit {
        Self.logger.info("FormsExtensionItem deinit")
    }
    
    /// 如果有正在上传或者上传完成但不需要消费的任务，则取消或者删除无用资源
    /// - Parameter browser: 挂载任务的套件统一浏览器对象
    fileprivate func cancelOrDeleteAllUploadTasksIfNeeded(_ browser: WebBrowser) {
        if let form = browser.formsAPIOptional {
            let infos = Array(
                FormsAttachment
                    .choosenAttachments
                    .values
            )
            
            form
                .formsAttachment
                .cancelOrDeleteUploadTasks(
                    attachmentInfos: infos,
                    needRemoveMemoryAndDeleteAttachment: false
                )
        }
    }
    
}

/// 收集表/表单分享页套件统一浏览器容器生命周期插件
final public class FormsWebBrowserLifeCycle: WebBrowserLifeCycleProtocol {
    
    static let logger = Logger.formsWebLog(FormsWebBrowserLifeCycle.self, category: "FormsWebBrowserLifeCycle")
    
    public let isFormsBrowser: Bool
    
    init(isFormsBrowser: Bool) {
        Self.logger.info("new FormsWebBrowserLifeCycle")
        self.isFormsBrowser = isFormsBrowser
    }
    
    deinit {
        Self.logger.info("FormsWebBrowserLifeCycle deinit")
    }
    
    public func viewDidAppear(browser: WebBrowser, animated: Bool) {
        if isFormsBrowser {
            setupTitleObservable(browser: browser)
        }
    }
    
    private var titleObservation: NSKeyValueObservation?
    /// 导航栏title跟着document.title走
    func setupTitleObservable(browser: WebBrowser) {
        guard titleObservation == nil else { return }
        titleObservation = browser
            .webview
            .observe(
                \.title,
                options: [.old, .new],
                changeHandler: { [weak browser] (_, _) in
                    guard let browser = browser else { return }
                    
                    if let resolver = browser.resolver,
                       let browser = browser as? TabContainable {
                        do {
                            try resolver
                                .resolve(
                                    assert: TemporaryTabService.self
                                )
                                .updateTab(browser)
                        } catch {
                            Self.logger.error("resolve TemporaryTabService error", error: error)
                        }
                        
                    }
                    
                }
            )
    }
    
}

/// 收集表/表单分享页套件统一浏览器网页生命周期插件
final public class FormsWebBrowserNavigation: WebBrowserNavigationProtocol {
    
    static let logger = Logger.formsWebLog(FormsWebBrowserNavigation.self, category: "FormsWebBrowserNavigation")
    
    private weak var item: FormsExtensionItem?
    
    init(item: FormsExtensionItem) {
        Self.logger.info("new FormsWebBrowserNavigation")
        self.item = item
    }
    
    deinit {
        Self.logger.info("FormsWebBrowserNavigation deinit")
    }
    
    public func browser(_ browser: WebBrowser, didCommit navigation: WKNavigation!) {
        Self.logger.info("didCommit navigation")
        item?.cancelOrDeleteAllUploadTasksIfNeeded(browser)
    }
    
    public func browserWebContentProcessDidTerminate(_ browser: WebBrowser) {
        Self.logger.info("browserWebContentProcessDidTerminate")
        item?.cancelOrDeleteAllUploadTasksIfNeeded(browser)
    }
}
