//
//  WebTranslateExtension.swift
//  LarkAI
//
//  Created by liushuwei on 2020/11/17.
//

import UIKit
import Foundation
import WebBrowser
import Swinject
import LarkContainer
import LarkSDKInterface
import LarkFeatureGating
import LarkMessengerInterface
import EENavigator
import LarkActionSheet
import LKCommonsLogging
import Homeric
import LKCommonsTracker
import UniverseDesignToast
import RxSwift
import LarkModel
import LarkUIKit
import WebKit
import LarkSearchCore

// 迁移到新菜单新架构，功能逻辑未进行任何修改
final public class WebTranslateExtensionItem: NSObject, WebBrowserExtensionItemProtocol {
    public var itemName: String? = "WebTranslate"
    // swiftlint:disable all
    // Weak Delegate Violation: Delegates should be weak to avoid reference cycles.
    public lazy var lifecycleDelegate: WebBrowserLifeCycleProtocol? = WebTranslateWebBrowserLifeCycle(item: self)
    public lazy var navigationDelegate: WebBrowserNavigationProtocol? = WebTranslateWebBrowserNavigation(item: self)
    // swiftlint:enable all
    weak var webviewApi: WebBrowser?
    var jsCodeInjector: JSCodeInjector?
    var injectCallback: (() -> Void)?
    var translateView: WebTranslateView?
    var translateViewModel: WebTranslateViewModel?
    // js API的几个依赖
    var urlAPI: UrlAPI?
    var configurationAPI: ConfigurationAPI?
    var userGeneralSettings: UserGeneralSettings?
    var translateWebAPIRegister: WebTranslateWebAPIRegister?
    let userResolver: UserResolver = Container.shared.getCurrentUserResolver()
    public init(browser: WebBrowser) {
        self.webviewApi = browser
        self.jsCodeInjector = JSCodeInjector()
        self.urlAPI = try? userResolver.resolve(assert: UrlAPI.self)
        self.configurationAPI = try? userResolver.resolve(assert: ConfigurationAPI.self)
        self.userGeneralSettings = try? userResolver.resolve(assert: UserGeneralSettings.self)
        self.translateWebAPIRegister = try? userResolver.resolve(assert: WebTranslateWebAPIRegister.self)
        super.init()
        setup(webviewApi: browser)
    }
    private func setup(webviewApi: WebBrowser) {
        guard AIFeatureGating.webTranslate.isEnabled else { return }
        self.translateViewModel = WebTranslateViewModel(userResolver: userResolver, webviewApi: webviewApi)
        guard let translateViewModel else { return }
        self.translateView = WebTranslateView(userResolver: userResolver, viewModel: translateViewModel)
        translateViewModel.setup()
        if translateViewModel.webTranslateAppSetting.isUrlEnable(url: webviewApi.browserURL) {
            self.setupInjectCallback()
        }
    }
    public func getInjectJSApi() -> [String: () -> LarkWebJSAPIHandler] {
        guard let translateViewModel = self.translateViewModel else { return [String: () -> LarkWebJSAPIHandler]() }
        return WebTranslateProvider.getTranslateApiDict(urlAPI: urlAPI,
                                                        configurationAPI: configurationAPI,
                                                        userGeneralSettings: userGeneralSettings,
                                                        translateViewModel: translateViewModel)
    }
    public func onPageLoadFinish() {
        self.injectCallback?()
    }
    // 设置网页加载完成后的回调
    // 这里加载网页翻译相关两个的JS
    private func setupInjectCallback() {
        self.injectCallback = { [weak self] in
            guard let api = self?.webviewApi else { return }
            self?.jsCodeInjector?.injectCode(api: api)
        }
    }
}
public protocol WebTranslateWebAPIRegister {
    func registJSSDK(apiDict: [String: () -> LarkWebJSAPIHandler], jsSDK: LarkWebJSSDK)
    func canEnableWebTranslate(_ context: WebBrowserMenuContext) -> Bool
}
final public class WebTranslateWebBrowserLifeCycle: WebBrowserLifeCycleProtocol {
    weak var item: WebTranslateExtensionItem?
    init(item: WebTranslateExtensionItem) {
        self.item = item
    }
    public func viewDidLoad(browser: WebBrowser) {
        if let a = item?.getInjectJSApi(), let j = browser.jsSDK {
            item?.translateWebAPIRegister?.registJSSDK(apiDict: a, jsSDK: j)
        }
    }
}
final public class WebTranslateWebBrowserNavigation: WebBrowserNavigationProtocol {
    weak var item: WebTranslateExtensionItem?
    init(item: WebTranslateExtensionItem) {
        self.item = item
    }
    public func browser(_ browser: WebBrowser, didFinish navigation: WKNavigation!) {
        item?.onPageLoadFinish()
    }
}
final public class WebTranslateMenuPlugin: MenuPlugin {
    public static var pluginID: String { "WebTranslateMenuPlugin" }
    public static var enableMenuContexts: [MenuContext.Type] { [WebBrowserMenuContext.self] }
    private let menuContext: WebBrowserMenuContext
    var translateWebAPIRegister: WebTranslateWebAPIRegister?

    public let userResolver: UserResolver = Container.shared.getCurrentUserResolver()
    public init?(menuContext: MenuContext, pluginContext: MenuPluginContext) {
        guard AIFeatureGating.webTranslate.isEnabled else { return nil }
        guard let webMenuContext = menuContext as? WebBrowserMenuContext else { return nil }
        self.menuContext = webMenuContext
        translateWebAPIRegister = try? userResolver.resolve(assert: WebTranslateWebAPIRegister.self)
    }
    public func pluginDidLoad(handler: MenuPluginOperationHandler) {
        guard AIFeatureGating.webTranslate.isEnabled else { return }
        if translateWebAPIRegister?.canEnableWebTranslate(menuContext) != true {
            return
        }
        fetchMenuItemModel { item in
            handler.updateItemModels(for: [item])
        }
    }
    private func fetchMenuItemModel(updater: @escaping (MenuItemModelProtocol) -> Void) {
        ///Todo: 用户态容器改造
        guard let webTranslateExtensionItem = menuContext.webBrowser?.resolve(WebTranslateExtensionItem.self) else { return }
        let title = BundleI18n.LarkAI.Lark_Legacy_Translation
        let image: UIImage
        if webTranslateExtensionItem.translateViewModel?.currentTranslateInfo != nil {
            image = Resources.menu_icon_translate_new
        } else {
            image = Resources.menu_icon_translate_disable_new
        }
        let badgeNumber: UInt = 0
        let imageModle = MenuItemImageModel(normalForIPhonePanel: image, normalForIPadPopover: image)
        let translateMenuItem = MenuItemModel(title: title,
                                              imageModel: imageModle,
                                              itemIdentifier: "translate",
                                              badgeNumber: badgeNumber,
                                              itemPriority: 10,
                                              action: {[weak webTranslateExtensionItem] _ in
                                                webTranslateExtensionItem?.translateViewModel?.onBrowserTranslateMenuClick()
                                              })
        updater(translateMenuItem)
    }
}
