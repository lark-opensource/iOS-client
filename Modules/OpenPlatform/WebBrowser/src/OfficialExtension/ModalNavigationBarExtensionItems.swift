//
//  ModalNavigationBarExtensionItems.swift
//  WebBrowser
//
//  Created by jiangzhongping on 2023/3/10.
//

import LarkUIKit
import LKCommonsLogging

//对应模态的导航栏(容器popup)
// MARK: - 左侧按钮
final public class ModalNavigationBarLeftExtensionItem: WebBrowserExtensionItemProtocol {
    public var itemName: String? = "ModalNavigationBarLeft"
    static let logger = Logger.webBrowserLog(ModalNavigationBarLeftExtensionItem.self, category: "ModalNavigationBarLeftExtensionItem")
    
    public lazy var lifecycleDelegate: WebBrowserLifeCycleProtocol? = ModalNavigationBarLeftWebBrowserLifeCycle(item: self)
    
    weak private var browser: WebBrowser?
    
    /// 关闭按钮
    public lazy var closeItem: LKBarButtonItem = {
        let closeItem = FeatureGatingKey.webBrowserProfileCloseBtnGap.fgValue() ? WebBrowserBarItem.makeIconButton(.closeOutlined) : LKBarButtonItem(image: LarkUIKit.Resources.navigation_close_outlined)
        closeItem.webButtonID = "1004"
        closeItem.addTarget(self, action: #selector(close), for: .touchUpInside)
        return closeItem
    }()
    
    @objc private func close() {
        Self.logger.info("closeItem clicked")
        // 直接退出
        browser?.closeBrowser()
        closeItem.webReportClick(applicationID: browser?.currrentWebpageAppID())
    }

    public init(browser: WebBrowser) {
        self.browser = browser
    }
    
    func setupLeftNavigationBarButtonItemsObservable(browser: WebBrowser) {
        var items: [UIBarButtonItem] = []
        items.append(closeItem)
        browser.navigationItem.setLeftBarButtonItems(insertSpaceForWebNavBar(items), animated: false)
    }
}

final public class ModalNavigationBarLeftWebBrowserLifeCycle: WebBrowserLifeCycleProtocol {
    private weak var item: ModalNavigationBarLeftExtensionItem?
    init(item: ModalNavigationBarLeftExtensionItem) {
        self.item = item
    }
    
    public func viewDidLoad(browser: WebBrowser) {
        item?.setupLeftNavigationBarButtonItemsObservable(browser: browser)
    }
}


