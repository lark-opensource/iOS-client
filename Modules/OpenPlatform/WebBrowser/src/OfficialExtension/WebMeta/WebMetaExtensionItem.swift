//
//  WebMetaExtensionItem.swift
//  WebBrowser
//
//  Created by yinyuan on 2022/1/15.
//

import WebKit
import UIKit
import SnapKit
import ECOInfra
import ECOProbe
import LarkUIKit
import LarkSetting
import LKCommonsLogging
import UniverseDesignToast
import UniverseDesignColor

private let logger = Logger.webBrowserLog(WebMetaExtensionItem.self, category: "WebMetaExtensionItem")

final public class WebMetaExtensionItem: WebBrowserExtensionItemProtocol, ScreenOrientationManagerProtocol {
    public var itemName: String? = "WebMeta"
    public lazy var lifecycleDelegate: WebBrowserLifeCycleProtocol? = WebMetaWebBrowserLifeCycle(item: self)
    
    public lazy var browserDelegate: WebBrowserProtocol? = WebMetaWebBrowserDelegate(item: self)
    
    public lazy var navigationDelegate: WebBrowserNavigationProtocol? = WebMetaWebBrowserNavigationDelegate(item: self)
    
    private weak var browser: WebBrowser?
    
    // orientation legacy imp start
    var isForceDeviceOrientation: Bool = false
    
    lazy var screenOrientationManager: ScreenOrientationManager = ScreenOrientationManager(delegate: self)
    
    private lazy var shadowView : UIView = {
        let view = UIView(frame: .zero)
        view.layer.shadowRadius = 16.0
        view.layer.shadowOffset = CGSize(width:0, height:6)
        view.layer.shadowOpacity = 1.0
        view.layer.shadowColor = UDColor.shadowDefaultMd.cgColor
        return view
    }()
    
    private lazy var rotationButtton : UIButton = {
        let button = UIButton()
        button.setImage(BundleResources.WebBrowser.icon_web_browser_rotation, for: UIControl.State.normal)
        button.backgroundColor = UDColor.bgBody
        button.layer.cornerRadius = 24
        button.layer.borderWidth = 0.5
        button.layer.borderColor = UDColor.lineBorderCard.cgColor
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(didRotationButtonClicked), for: .touchUpInside)
        return button
    }()
    
    // orientation legacy imp end
    
    private var viewMeta: WebMeta
    
    private var urlPageMeta: WebMeta
    
    private var documentPageMeta: WebMeta
    
    private var usingMeta: WebMeta
    
    private var usingMetaTrackModel : WebMetaTrackModel = WebMetaTrackModel()
    
    public init(browser: WebBrowser) {
        self.browser = browser
        let lkMeta: LKMeta? = LKMeta.resolveMeta(url: browser.browserURL)
        documentPageMeta = WebMeta()
        usingMeta = WebMeta()
        viewMeta = lkMeta?.viewMeta ?? WebMeta()
        urlPageMeta = lkMeta?.pageMeta ?? WebMeta()
        
        self.combineAllMeta()
    }
    
    // newfeature
    
    public func updateMetas(metas: [Dictionary<String, Any>]){
        logger.info("updateMetas: \(metas)")
    
        var pageMetaFromDoc = WebMeta()
        for meta in metas {
            guard let name = meta["name"] as? String else {
                continue
            }
            let content = meta["content"] as? String
            switch name {
            case "orientation":
                pageMetaFromDoc.orientation = content
                usingMetaTrackModel.orientationSource = "meta_page_meta"
            case "hideMenuItems":
                pageMetaFromDoc.hideMenuItems = content
            case "slideToClose":
                pageMetaFromDoc.slideToClose = content
            case "showNavBar":
                pageMetaFromDoc.showNavBar = content
            case "showNavLBarBtn":
                pageMetaFromDoc.showNavLBarBtn = content
            case "showNavRBarBtn":
                pageMetaFromDoc.showNavRBarBtn = content
            case "navBgColor":
                pageMetaFromDoc.navBgColor = content
            case "navFgColor":
                pageMetaFromDoc.navFgColor = content
            case "shareLink":
                pageMetaFromDoc.shareLink = content
                logger.info("meta set shareLink")
            case "hideNavBarItems":
                logger.error("hideNavBarItems dose not support <meta>")
            case "showBottomNavBar":
                pageMetaFromDoc.showBottomNavBar = content
                logger.info("meta set showBottomNavBar")
            case "allowBackForwardGestures":
                pageMetaFromDoc.allowBackForwardGestures = content
            default:
                break
            }
        }
        documentPageMeta = pageMetaFromDoc
        if Thread.isMainThread {
            self.combineAndApplyUsingMeta()
        } else {
            DispatchQueue.main.async {
                self.combineAndApplyUsingMeta()
            }
        }
    }
    
    func combineAndApplyUsingMeta(){
        self.combineAllMeta()
        self.applyUsingMeta()
    }
    
    
    fileprivate func applyUsingMeta() {
        logger.info("apply applyUsingMeta")
        guard let browser = browser else {
            logger.info("browser is nil")
            return
        }
        if let metaComponent = browser.resolve(WebMetaOrientationExtensionItem.self) {
            metaComponent.applyMetaContent(metaContent: usingMeta.orientation)
        }
        browser.resolve(WebMetaSafeAreaExtensionItem.self)?.applyMetaContent(metaContent: usingMeta.fixsafearea)
        if FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.meta.meta_hidemenuitems")) {// user:global
            if let menuConfigExtensionItem = browser.resolve(WebMetaMoreMenuConfigExtensionItem.self) {
                menuConfigExtensionItem.applyMetaContent(metaContent: usingMeta.hideMenuItems)
            }
        }
        // slideToClose
        if WebMetaSlideToCloseExtensionItem.isSlideToCloseEnabled() {
            if let slideToCloseItem = browser.resolve(WebMetaSlideToCloseExtensionItem.self) {
                slideToCloseItem.applyMetaContent(metaContent: usingMeta.slideToClose)
            }
        }
        
        // showNavBar/showNavLBarBtn/showNavRBarBtn
        // navBgColor/navFgColor
        // hideNavBarItems
        if WebMetaNavigationBarExtensionItem.isShowNavigationBarEnabled() ||
            WebMetaNavigationBarExtensionItem.isNavBgAndFgColorEnabled() ||
            WebMetaNavigationBarExtensionItem.isHideNavBarItemsEnabled() {
            if let navBarItem = browser.resolve(WebMetaNavigationBarExtensionItem.self) {
                navBarItem.applyWebMeta(usingMeta)
            }
        }
        //shareLink
        if WebMetaMoreMenuConfigExtensionItem.isWebShareLinkEnabled() {
            if let moreItem = browser.resolve(WebMetaMoreMenuConfigExtensionItem.self) {
                moreItem.applyMenuItemContent(metaContent: usingMeta.shareLink)
            }
        }
        // showBottomNavBar
        if WebMetaLaunchBarExtensionItem.isShowLaunchBarEnabled() {
            if let launchBarItem = browser.resolve(WebMetaLaunchBarExtensionItem.self) {
                launchBarItem.applyWebMeta(usingMeta)
            }
        }
        
        //allowBackForwardGestures
        if WebMetaBackForwardGesturesExtensionItem.allowBackForwardGesEnable() {
            if let item = browser.resolve(WebMetaBackForwardGesturesExtensionItem.self) {
                item.applyMetaContent(metaContent: usingMeta.allowBackForwardGestures)
            }
        }
    }
    
    fileprivate func resetAndResolveURLMeta(){
        logger.info("resetAndResolveURLMeta")
        guard let browser = browser else {
            logger.info("browser is nil")
            return
        }
        let lkMeta: LKMeta? = LKMeta.resolveMeta(url: browser.browserURL)
        // 先清空之前的pagemeta和urlmeta
        urlPageMeta = WebMeta()
        documentPageMeta = WebMeta()
        usingMeta = WebMeta()
        if let lkMeta = lkMeta {
            urlPageMeta = lkMeta.pageMeta ?? WebMeta()
        }
        self.combineAllMeta()
        self.applyUsingMeta()
    }
    
    // legacy
    fileprivate func applyMeta() {
        guard let browser = browser else {
            logger.info("browser is nil")
            return
        }
        guard browser.configuration.acceptWebMeta else {
            isForceDeviceOrientation = false
            return
        }
        applyMeta(from: browser.browserURL)
    }
    
    
    fileprivate func applyMeta(from url: URL?) {
        guard let browser = browser else {
            logger.info("browser is nil")
            return
        }
        let lkMeta: LKMeta? = LKMeta.resolveMeta(url: url)
        applyMeta(browser: browser, meta: lkMeta)
    }
    
    fileprivate func applyMeta(browser: WebBrowser, meta: LKMeta?) {
        guard browser.configuration.acceptWebMeta else {
            isForceDeviceOrientation = false
            return
        }
        logger.info("apply meta: \(meta)")
        applyOrientationIfNeeded(browser: browser, meta: meta)
    }
    
    
    func startDeviceMotionObserver(){
        if !Display.pad {
            self.screenOrientationManager.startDeviceMotionObserver()
        }
    }
    
    func stopDeviceMotionObserver(){
        if !Display.pad {
            self.screenOrientationManager.stopDeviceMotionObserver()
        }
    }
    
    func motionSensorUpdatesOrientation(to: UIInterfaceOrientation) {
        if isForceDeviceOrientation {
            shadowView.removeFromSuperview()
            rotationButtton.removeFromSuperview()
            logger.info("device motion, fixed orientation")
            return
        }
        let statusBarOrientation = UIApplication.shared.statusBarOrientation
        if statusBarOrientation != to {
            var bottomOffest = 16.0
            if let keyWindow = self.browser?.view.window {
                bottomOffest += keyWindow.safeAreaInsets.bottom
            }
            logger.info("device motion, statusBarOrientation: \(statusBarOrientation.rawValue), device status orientation:\(to.rawValue)")
            switch to {
            case .landscapeRight:
                if (shadowView.superview == nil) {
                    self.browser?.view.addSubview(shadowView)
                    shadowView.addSubview(rotationButtton)
                }
                self.browser?.view.bringSubviewToFront(shadowView)
                shadowView.bringSubviewToFront(rotationButtton)
                shadowView.snp.remakeConstraints { (make) in
                    make.left.equalToSuperview().offset(16)
                    make.bottom.equalToSuperview().offset(-bottomOffest)
                    make.width.height.equalTo(48)
                }
                rotationButtton.snp.remakeConstraints { (make) in
                    make.center.equalTo(shadowView)
                    make.size.equalTo(shadowView)
                }
                break
            case .unknown:
                shadowView.removeFromSuperview()
                rotationButtton.removeFromSuperview()
                break;
            case .portrait:
                if (shadowView.superview == nil) {
                    self.browser?.view.addSubview(shadowView)
                    shadowView.addSubview(rotationButtton)
                }
                self.browser?.view.bringSubviewToFront(shadowView)
                shadowView.bringSubviewToFront(rotationButtton)
                shadowView.snp.remakeConstraints { (make) in
                    make.right.equalToSuperview().offset(-bottomOffest)
                    make.top.equalToSuperview().offset(16)
                    make.width.height.equalTo(48)
                }
                rotationButtton.snp.remakeConstraints { (make) in
                    make.center.equalTo(shadowView)
                    make.size.equalTo(shadowView)
                }
                break;
            case .portraitUpsideDown:
                shadowView.removeFromSuperview()
                rotationButtton.removeFromSuperview()
                break;
            case .landscapeLeft:
                shadowView.removeFromSuperview()
                rotationButtton.removeFromSuperview()
                break;
            }
        }
    }
    
    @objc func didRotationButtonClicked(){
        var deviceOrientation = UIDeviceOrientation.portrait
        switch screenOrientationManager.deviceOrientation {
        case .portrait:
            deviceOrientation = UIDeviceOrientation.portrait
            break;
        case .unknown:
            deviceOrientation = UIDeviceOrientation.portrait
            break;
        case .portraitUpsideDown:
            deviceOrientation = UIDeviceOrientation.portrait
            break;
        case .landscapeLeft:
            deviceOrientation = UIDeviceOrientation.landscapeLeft
            break;
        case .landscapeRight:
            deviceOrientation = UIDeviceOrientation.landscapeRight
            break;
        @unknown default:
            break;
        }
        logger.info("device motion, cm orientation: \(screenOrientationManager.deviceOrientation.rawValue) change to: \(deviceOrientation.rawValue)")
        browser?.setScreenOrientation(deviceOrientation)
        shadowView.removeFromSuperview()
        rotationButtton.removeFromSuperview()
    }
    
    func combineAllMeta() {
        // orientation
        if documentPageMeta.orientation != nil  {
            usingMeta.orientation = documentPageMeta.orientation
            usingMetaTrackModel.orientationSource = "meta_page_meta"
        }else if urlPageMeta.orientation != nil {
            usingMeta.orientation = urlPageMeta.orientation
            usingMetaTrackModel.orientationSource = "url_page_meta"
        } else if viewMeta.orientation != nil {
            usingMeta.orientation = viewMeta.orientation
            usingMetaTrackModel.orientationSource = "url_view_meta"
        }
        // safearea
        if documentPageMeta.fixsafearea != nil  {
            usingMeta.fixsafearea = documentPageMeta.fixsafearea
        } else if urlPageMeta.fixsafearea != nil {
            usingMeta.fixsafearea = urlPageMeta.fixsafearea
        } else if viewMeta.fixsafearea != nil {
            usingMeta.fixsafearea = viewMeta.fixsafearea
        }
        
        
        // hidemenuitems , 目前不解析view-meta,产品层面的考虑；page-meta(url)根据fg判断是否使用
        if FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.meta.meta_hidemenuitems")), let browser = browser {// user:global
            if documentPageMeta.hideMenuItems != nil  {
                usingMeta.hideMenuItems = documentPageMeta.hideMenuItems
            } else if urlPageMeta.hideMenuItems != nil, FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.meta.meta_hidemenuitems.urlpagemeta")) {// user:global
                usingMeta.hideMenuItems = urlPageMeta.hideMenuItems
            } else if viewMeta.hideMenuItems != nil, FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.meta.meta_hidemenuitems.urlviewmeta")) {
                usingMeta.hideMenuItems = viewMeta.hideMenuItems
            }
        }
        // slideToClose
        if WebMetaSlideToCloseExtensionItem.isSlideToCloseEnabled() {
            if documentPageMeta.slideToClose != nil {
                usingMeta.slideToClose = documentPageMeta.slideToClose
            } else if urlPageMeta.slideToClose != nil {
                usingMeta.slideToClose = urlPageMeta.slideToClose
            } else if viewMeta.slideToClose != nil {
                usingMeta.slideToClose = viewMeta.slideToClose
            }
        }
        // showNavBar/showNavLBarBtn/showNavRBarBtn
        if WebMetaNavigationBarExtensionItem.isShowNavigationBarEnabled() {
            if let docPageMeta = documentPageMeta.showNavBar {
                usingMeta.showNavBar = docPageMeta
            } else if let urlPageMeta = urlPageMeta.showNavBar {
                usingMeta.showNavBar = urlPageMeta
            } else if let viewMeta = viewMeta.showNavBar {
                usingMeta.showNavBar = viewMeta
            }
            
            if let docPageMeta = documentPageMeta.showNavLBarBtn {
                usingMeta.showNavLBarBtn = docPageMeta
            } else if let urlPageMeta = urlPageMeta.showNavLBarBtn {
                usingMeta.showNavLBarBtn = urlPageMeta
            } else if let viewMeta = viewMeta.showNavLBarBtn {
                usingMeta.showNavLBarBtn = viewMeta
            }
            
            if let docPageMeta = documentPageMeta.showNavRBarBtn {
                usingMeta.showNavRBarBtn = docPageMeta
            } else if let urlPageMeta = urlPageMeta.showNavRBarBtn {
                usingMeta.showNavRBarBtn = urlPageMeta
            } else if let viewMeta = viewMeta.showNavRBarBtn {
                usingMeta.showNavRBarBtn = viewMeta
            }
        }
        // navBgColor/navFgColor
        if WebMetaNavigationBarExtensionItem.isNavBgAndFgColorEnabled() {
            if let docPageMeta = documentPageMeta.navBgColor {
                usingMeta.navBgColor = docPageMeta
            } else if let urlPageMeta = urlPageMeta.navBgColor {
                usingMeta.navBgColor = urlPageMeta
            } else if let viewMeta = viewMeta.navBgColor {
                usingMeta.navBgColor = viewMeta
            }
            
            if let docPageMeta = documentPageMeta.navFgColor {
                usingMeta.navFgColor = docPageMeta
            } else if let urlPageMeta = urlPageMeta.navFgColor {
                usingMeta.navFgColor = urlPageMeta
            } else if let viewMeta = viewMeta.navFgColor {
                usingMeta.navFgColor = viewMeta
            }
        }
        // hideNavBarItems
        if WebMetaNavigationBarExtensionItem.isHideNavBarItemsEnabled() {
            if let viewMeta = viewMeta.hideNavBarItems {
                usingMeta.hideNavBarItems = viewMeta
            }
        }
        // shareLink
        if WebMetaMoreMenuConfigExtensionItem.isWebShareLinkEnabled() {
            if let shareLink = documentPageMeta.shareLink {
                logger.info("documentPageMeta set shareLink")
                usingMeta.shareLink = shareLink
            } else if let urlPageMeta = urlPageMeta.shareLink {
                logger.info("urlPageMeta set shareLink")
                usingMeta.shareLink = urlPageMeta
            }
        }
        // showBottomNavBar
        if WebMetaLaunchBarExtensionItem.isShowLaunchBarEnabled() {
            if let docPageMeta = documentPageMeta.showBottomNavBar {
                logger.info("documentPageMeta set showBottomNavBar")
                usingMeta.showBottomNavBar = docPageMeta
            } else if let urlPageMeta = urlPageMeta.showBottomNavBar {
                logger.info("urlPageMeta set showBottomNavBar")
                usingMeta.showBottomNavBar = urlPageMeta
            } else if let viewMeta = viewMeta.showBottomNavBar {
                usingMeta.showBottomNavBar = viewMeta
                logger.info("viewMeta set showBottomNavBar")
            }
        }
        
        //allowBackForwardGestures
        if WebMetaBackForwardGesturesExtensionItem.allowBackForwardGesEnable() {
            if documentPageMeta.allowBackForwardGestures != nil {
                usingMeta.allowBackForwardGestures = documentPageMeta.allowBackForwardGestures
            } else if urlPageMeta.allowBackForwardGestures != nil {
                usingMeta.allowBackForwardGestures = urlPageMeta.allowBackForwardGestures
            } else if viewMeta.allowBackForwardGestures != nil {
                usingMeta.allowBackForwardGestures = viewMeta.allowBackForwardGestures
            }
        }
    }
    
    func trackWebMeta(){
        guard let browser = self.browser else { return  }
        let screen_orientation = usingMeta.orientation != nil ? usingMeta.orientation : "none"
        let showBottomNavBar = usingMeta.showBottomNavBar != nil ? usingMeta.showBottomNavBar : "none"
        OPMonitor("openplatform_web_page_view")
            .addCategoryValue("application_id", webBrowserDependency.appInfoForCurrentWebpage(browser: browser)?.id ?? "none")
            .addCategoryValue("url", browser.browserURL?.safeURLString)
            .addCategoryValue("screen_orientation", screen_orientation)
            .addCategoryValue("screen_orientation_set_source", usingMetaTrackModel.orientationSource != nil ? usingMetaTrackModel.orientationSource : "")
            .addCategoryValue("show_bottomnavbar", showBottomNavBar)
            .tracing(browser.webview.trace)
            .setPlatform([.tea, .slardar])
            .flush()
    }
}

final public class WebMetaWebBrowserLifeCycle: WebBrowserLifeCycleProtocol {
    
    private weak var item: WebMetaExtensionItem?
    
    init(item: WebMetaExtensionItem) {
        self.item = item
    }
    
    public func viewDidLoad(browser: WebBrowser) {
        logger.info("viewDidLoad")
        guard browser.configuration.acceptWebMeta else {
            return
        }
        if let item = self.item {
            item.applyUsingMeta()
        }
    }
    
    public func viewDidAppear(browser: WebBrowser, animated: Bool) {
        logger.info("viewDidAppear")
        guard browser.configuration.acceptWebMeta else {
            return
        }
        
//        if !FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.meta.meta_orientation")) {
//            if FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.orientaion.v2.enable")) {
//                self.item?.startDeviceMotionObserver()
//                logger.info("device motion, start motion observer")
//            }
//            guard browser.configuration.acceptWebMeta else {
//                self.item?.isForceDeviceOrientation = false
//                return
//            }
//            logger.info("viewDidAppear")
//            self.item?.applyMeta()
//        }
    }
    
    public func viewDidDisappear(browser: WebBrowser, animated: Bool) {
        guard browser.configuration.acceptWebMeta else {
            return
        }
        logger.info("viewDidDisappear")
//        if !FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.meta.meta_orientation")) {
//            if FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.orientaion.v2.enable")) {
//                self.item?.stopDeviceMotionObserver()
//                logger.info("device motion, stop motion observer")
//            }
//        }
    }
}

final public class WebMetaWebBrowserDelegate: WebBrowserProtocol {
    
    private weak var item: WebMetaExtensionItem?
    
    init(item: WebMetaExtensionItem) {
        self.item = item
    }

    public func browser(_ browser: WebBrowser, didURLChanged url: URL?) {
        guard browser.configuration.acceptWebMeta else {
            item?.isForceDeviceOrientation = false
            return
        }
//        if !FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.meta.meta_orientation")) {
//            self.item?.applyMeta(from: url)
//        }
    }
}


final public class WebMetaWebBrowserNavigationDelegate: WebBrowserNavigationProtocol {
    private weak var item: WebMetaExtensionItem?
    
    init(item: WebMetaExtensionItem) {
        self.item = item
    }
    public func browser(_ browser: WebBrowser, didCommit navigation: WKNavigation!) {
        logger.info("didCommit")
//        if FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.meta.meta_orientation")) {
//
//        }
        self.item?.resetAndResolveURLMeta()
    }
    
    public func browser(_ browser: WebBrowser, didFinish navigation: WKNavigation!) {
        logger.info("didFinish")
//        if FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.meta.meta_orientation")) {
//            
//        }
        self.item?.applyUsingMeta()
        self.item?.trackWebMeta()
    }
}


extension WebMetaExtensionItem {
    
    fileprivate func applyOrientationIfNeeded(browser: WebBrowser, meta: LKMeta?) {
        let orientation: MetaOritation
        
        if let orientationStr = meta?.pageMeta?.orientation, let orientationEnum = MetaOritation(rawValue: orientationStr) {
            isForceDeviceOrientation = true
            orientation = orientationEnum
            
            switch orientation {
            case .landscape:
                isForceDeviceOrientation = true
                browser.setScreenOrientation(.landscapeRight)
            case .portrait:
                isForceDeviceOrientation = true
                browser.setScreenOrientation(.portrait)
            case .default:
                browser.setScreenOrientation(.unknown)
                isForceDeviceOrientation = false
            }
        } else {
            isForceDeviceOrientation = false
        }
    }
    
    @objc
    private func orientationDidChange() {
        
        if let browser = browser {
            // 更新webview约束
            if browser.webview.superview != nil {
                // 横屏safearea适配开关，默认不开，开启后走5.14.0之前逻辑
                if !FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.landscape.safearea.inset.disable")) {// user:global
                    // 5.14.0之后逻辑
                    browser.updateWebViewConstraint()
                }
            }
            
            // 更新contentInsetAdjustmentBehavior
            // 专门为横屏需求做的降级逻辑
            browser.webview.scrollView.contentInsetAdjustmentBehavior = .never
            logger.info("update webview contentInsetAdjustmentBehavior to never when content_adjustment open")
        }
    }
}
