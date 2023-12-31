//
//  SKBitableRecommendController.swift
//  SKSpace
//
//  Created by ByteDance on 2023/7/16.
//

import UIKit
import WebBrowser
import SKFoundation
import SKCommon
import LarkWebViewContainer
import LarkUIKit
import LarkSetting
import SKInfra
import SKUIKit

//MARK: 推荐页面
public class SKBitableRecommendController: NSObject {
    public var viewController : WebBrowser?
    //MARK: Controller初始化
    public override init() {
        super.init()
        prepareWebBrowser()
    }
    func prepareWebBrowser() {
        if let mainpageUrl = self.fetchRecommendPageUrl() {
            var config = WebBrowserConfiguration(
                secLinkEnable: false,
                webBizType: .larkBase
            )
            config.fromScene = .mainTab
            config.scene = .mainTab
            config.acceptWebMeta = true
            let controller = WebBrowser(url: mainpageUrl, configuration: config)
            self.viewController = controller
            try? controller.register(item: SKBitableRecommendExtensionItem(fromViewController: self))
            controller.registerExtensionItemsForBitableHomePage()
            controller.webview.scrollView.bounces = false
            controller.webview.tryFixDarkModeWhitePage()
        }
    }
    
    func fetchRecommendPageUrl() -> URL? {
        let settings = try? SettingManager.shared.setting(with: UserSettingKey.make(userKeyLiteral: "ccm_base_homepage_recommend_url"))
        if let urlS = settings?["homePageUrl"] as? String {
            let recommendUrl = URL.init(string:urlS)
            DocsLogger.info("recommendPageUrl use setting url...")
            return recommendUrl
        }
        return nil
    }
    
    func reload() {
        self.viewController?.reload()
    }
}

//MARK: FG&setting 相关
extension SKBitableRecommendController {
    static public func shouldShowRecommend() -> Bool {
        /*
         *条件一：FG是否打开
         *条件二：首页推荐地址存在 并且不会被本地拦截
         */
        guard hasConfigedFG() else {
            DocsLogger.info("hasConfigedFG not pass")
            return false
        }
        
        if UserScopeNoChangeFG.WPB.homepageRecommendNativeEnable {
            return true
        }
        
        guard hasConfigedRecommenUrlAndNoIntercept() else {
            DocsLogger.info("hasConfigedRecommenUrlAndNoIntercept not pass")
            return false
        }
        
        return true
    }
    
    static private func hasConfigedFG() -> Bool {
        if DocsSDK.currentLanguage == .zh_CN {
            return UserScopeNoChangeFG.PXR.btHomepageSwitchTabEnable
        }else {
            return UserScopeNoChangeFG.PXR.btHomepageSwitchTabLanguageEnable
        }
    }
        
    static private func hasConfigedRecommenUrlAndNoIntercept() -> Bool {
        //没有首页地址返回false
        guard let settings = try? SettingManager.shared.setting(with: "ccm_base_homepage_recommend_url"), let urlS = settings["homePageUrl"] as? String, let url = URL.init(string: urlS) else {
            DocsLogger.info("baseTab recommed url has errors!")
            return false
        }
        //判断是否会被doc拦截
        let isDocsUrl = URLValidator.isDocsURL(url)
        return !isDocsUrl
    }
}

//MARK: 容器插件
final class SKBitableRecommendExtensionItem: NSObject, WebBrowserExtensionItemProtocol {
    public var itemName: String? = "SKBitableRecommendExtension"
    public weak var fromViewController : SKBitableRecommendController?
    var lastLoadingisFailed : Bool = false
    
    public lazy var  lifecycleDelegate: WebBrowserLifeCycleProtocol? = SKBitableRecommendWebBrowserLifeCycle(item: self)
    public lazy var  navigationDelegate: WebBrowserNavigationProtocol? = SKBitableRecommendWebBrowserNavigation(item: self)
    
    public init(fromViewController : SKBitableRecommendController) {
        self.fromViewController = fromViewController
        super.init()
    }
}

//MARK: 容器生命周期
final public class SKBitableRecommendWebBrowserLifeCycle: WebBrowserLifeCycleProtocol {
    weak var item: SKBitableRecommendExtensionItem?
    init(item: SKBitableRecommendExtensionItem) {
        self.item = item
    }
    
    public func viewWillAppear(browser: WebBrowser, animated: Bool) {
        guard let item = self.item else{
            return
        }
        if item.lastLoadingisFailed {
            item.lastLoadingisFailed = false
            self.item?.fromViewController?.reload()
        }
    }
}

//MARK: 网页生命周期
final public class SKBitableRecommendWebBrowserNavigation: WebBrowserNavigationProtocol {
    weak var item: SKBitableRecommendExtensionItem?
    init(item: SKBitableRecommendExtensionItem) {
        self.item = item
    }
   
    //MARK: fail
    public func browser(_ browser: WebBrowser, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        item?.lastLoadingisFailed = true
    }

    public func browser(_ browser: WebBrowser, didFail navigation: WKNavigation!, withError error: Error) {
        item?.lastLoadingisFailed = true
    }
    
    public func browserWebContentProcessDidTerminate(_ browser: WebBrowser) {
        item?.lastLoadingisFailed = true
    }
    
    //MARK: success
    public func browser(_ browser: WebBrowser, didFinish navigation: WKNavigation!) {
        item?.lastLoadingisFailed = false
        browser.webview.tryRecoveryOpaque()
    }
}
