//
//  WebMetaOrientationComponet.swift
//  WebBrowser
//
//  Created by luogantong on 2022/5/6.
//

import Foundation
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

private let logger = Logger.webBrowserLog(WebMetaOrientationExtensionItem.self, category: "WebMetaOrientationExtensionItem")

public enum MetaOritation: String {
    case landscape  // 强制横屏
    case portrait   // 强制竖屏
    case `default`  // 默认逻辑
}

// https://www.figma.com/file/UeanoynvLvYFrgADkMMM8H/H5%E5%AE%B9%E5%99%A8%E6%8E%A7%E5%88%B6%E6%A8%AA%E5%B1%8F%E5%88%87%E6%8D%A2%E8%A7%84%E8%8C%83?node-id=0%3A1
class WebMetaOrientationRotationButton : UIView {
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        self.addSubview(self.shadowView)
        shadowView.snp.remakeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        self.addSubview(self.rotateButtton)
        rotateButtton.snp.remakeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var shadowView : UIView = {
        let view = UIView(frame: .zero)
        view.layer.shadowRadius = 16.0
        view.layer.shadowOffset = CGSize(width:0, height:6)
        view.layer.shadowOpacity = 1.0
        view.layer.shadowColor = UDColor.shadowDefaultMd.cgColor
        return view
    }()

    lazy var rotateButtton : UIButton = {
        let button = UIButton()
        button.setImage(BundleResources.WebBrowser.icon_web_browser_rotation, for: UIControl.State.normal)
        button.backgroundColor = UDColor.bgBody
        button.layer.cornerRadius = 24
        button.layer.borderWidth = 0.5
        button.layer.borderColor = UDColor.lineBorderCard.cgColor
        button.clipsToBounds = true
        
        return button
    }()
}

public final class WebMetaOrientationExtensionItem: WebBrowserExtensionItemProtocol, ScreenOrientationManagerProtocol {
    public var itemName: String? = "WebMetaOrientation"
    private weak var browser: WebBrowser?
    
    public lazy var lifecycleDelegate: WebBrowserLifeCycleProtocol? = WebMetaOrientationExtensionItemBrowserLifeCycle(item: self)
    
    public lazy var browserDelegate: WebBrowserProtocol? = WebMetaOrientationExtensionItemBrowserDelegate(item: self)
    
    public lazy var navigationDelegate: WebBrowserNavigationProtocol? = WebMetaOrientationExtensionItemBrowserNavigationDelegate(item: self)
    
    var metaContent: MetaOritation = MetaOritation.default
    
    var isForceDeviceOrientation: Bool = false

    lazy var screenOrientationManager: ScreenOrientationManager = ScreenOrientationManager(delegate: self)
    
    var rotationButtonHasCreated: Bool = false
    lazy var rotationButton: WebMetaOrientationRotationButton = {
        rotationButtonHasCreated = true
        let rotationButton = WebMetaOrientationRotationButton(frame: CGRect.zero)
        rotationButton.rotateButtton.addTarget(self, action: #selector(didRotationButtonClicked), for: .touchUpInside)
        return rotationButton
    }()
    
    var isBrowserRotationOptimizeEnable: Bool = {
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.browser.rotation.optimize.ios"))
    }()
    
    var isRotationButtonDisable: Bool = OPUserScope.userResolver().fg.dynamicFeatureGatingValue(with: "openplatform.web.meta.orientation.button.disable")
    
    var isBrowserRotationOptimizeDisable: Bool = {
        return OPUserScope.userResolver().fg.staticFeatureGatingValue(with: "openplatform.web.browser.rotation.optimize.ios.disable")
    }()
    
    public init(browser: WebBrowser) {
        self.browser = browser
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(orientationDidChange),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: nil)
    }
    
    deinit{
        NotificationCenter.default.removeObserver(self)
    }
    
    func applyMetaContent(metaContent: String?) {
        if let browser = browser {
            guard browser.configuration.acceptWebMeta else {
                isForceDeviceOrientation = false
                return
            }
            if let orientationStr = metaContent {
                logger.info("apply orientation to:\(orientationStr)")
                self.metaContent = MetaOritation(rawValue: orientationStr) ?? MetaOritation.default
                if self.metaContent == MetaOritation.default {
                    isForceDeviceOrientation = false
                } else {
                    isForceDeviceOrientation = true
                }
            } else {
                logger.info("apply orientation to default when nil")
                isForceDeviceOrientation = false
                self.metaContent = MetaOritation.default
            }
            applyMeta()
        } else {
            logger.info("remove rotation view when browser nil")
            self.metaContent = MetaOritation.default
            isForceDeviceOrientation = false
            rotationButton.removeFromSuperview()
        }
    }
    
    func applyMeta(){
        switch self.metaContent {
        case .landscape:
            browser?.setScreenOrientation(.landscapeRight)
        case .portrait:
            browser?.setScreenOrientation(.portrait)
        case .default:
            if !isBrowserRotationOptimizeDisable {
                browser?.setScreenOrientation(.portrait)
            } else {
                browser?.setScreenOrientation(.unknown)
            }
        }
    }
    
    func startDeviceMotionObserver(){
        if !Display.pad, !isRotationButtonDisable {
            self.screenOrientationManager.startDeviceMotionObserver()
        }
    }

    func stopDeviceMotionObserver(){
        if !Display.pad,!isRotationButtonDisable {
            self.screenOrientationManager.stopDeviceMotionObserver()
        }
    }

    func motionSensorUpdatesOrientation(to: UIInterfaceOrientation) {
        if isForceDeviceOrientation {
            rotationButton.removeFromSuperview()
            logger.info("device motion, fixed orientation")
            return
        }
        
        guard let browser = self.browser else {
            rotationButton.removeFromSuperview()
            logger.info("browser nil, return")
            return
        }
        if browser.webview.isLoading {
            logger.info("loading document")
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
                if (rotationButton.superview == nil) {
                    browser.view.addSubview(rotationButton)
                    OPMonitor("openplatform_mobile_webpage_orientation_button_show")
                        .addCategoryValue("application_id", webBrowserDependency.appInfoForCurrentWebpage(browser: browser)?.id ?? "none")
                        .addCategoryValue("url", browser.browserURL?.safeURLString)
                        .tracing(browser.webview.trace)
                        .setPlatform([.tea, .slardar])
                        .flush()
                }
                browser.view.bringSubviewToFront(rotationButton)
                rotationButton.snp.remakeConstraints { (make) in
                    make.left.equalToSuperview().offset(16)
                    make.bottom.equalToSuperview().offset(-bottomOffest)
                    make.width.height.equalTo(48)
                }
            case .unknown:
                rotationButton.removeFromSuperview()
            case .portrait:
                if (rotationButton.superview == nil) {
                    browser.view.addSubview(rotationButton)
                    OPMonitor("openplatform_mobile_webpage_orientation_button_show")
                    // 下边这一行需要抽离
                        .addCategoryValue("application_id", webBrowserDependency.appInfoForCurrentWebpage(browser: browser)?.id ?? "none")
                        .addCategoryValue("url", browser.browserURL?.safeURLString)
                        .tracing(browser.webview.trace)
                        .setPlatform([.tea, .slardar])
                        .flush()
                }
                browser.view.bringSubviewToFront(rotationButton)
                rotationButton.snp.remakeConstraints { (make) in
                    make.right.equalToSuperview().offset(-bottomOffest)
                    make.top.equalToSuperview().offset(16)
                    make.width.height.equalTo(48)
                }
            case .portraitUpsideDown:
                rotationButton.removeFromSuperview()
            case .landscapeLeft:
                rotationButton.removeFromSuperview()
            }
        } else {
            if(self.rotationButtonHasCreated){
                rotationButton.removeFromSuperview()
            }
        }
    }
    
    @objc func didRotationButtonClicked(){
        guard let browser = self.browser else { return  }
        var deviceOrientation = UIDeviceOrientation.portrait
        switch screenOrientationManager.deviceOrientation {
        case .portrait:
            deviceOrientation = UIDeviceOrientation.portrait
        case .unknown:
            deviceOrientation = UIDeviceOrientation.portrait
        case .portraitUpsideDown:
            deviceOrientation = UIDeviceOrientation.portrait
        case .landscapeLeft:
            deviceOrientation = UIDeviceOrientation.landscapeLeft
        case .landscapeRight:
            deviceOrientation = UIDeviceOrientation.landscapeRight
        }
        
        OPMonitor("openplatform_mobile_webpage_orientation_button_show_click")
            .addCategoryValue("application_id", webBrowserDependency.appInfoForCurrentWebpage(browser: browser)?.id ?? "none")
            .addCategoryValue("url", browser.browserURL?.safeURLString)
            .addCategoryValue("click", "screen_rotate")
            .addCategoryValue("target", "none")
            .tracing(browser.webview.trace)
            .setPlatform([.tea, .slardar])
            .flush()
        logger.info("device motion, cm orientation: \(screenOrientationManager.deviceOrientation.rawValue) change to: \(deviceOrientation.rawValue)")
        browser.setScreenOrientation(deviceOrientation)
        rotationButton.removeFromSuperview()
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

final public class WebMetaOrientationExtensionItemBrowserLifeCycle: WebBrowserLifeCycleProtocol {
    private weak var item: WebMetaOrientationExtensionItem?
    init(item: WebMetaOrientationExtensionItem) {
        self.item = item
    }
    
    public func viewDidAppear(browser: WebBrowser, animated: Bool) {
        guard browser.configuration.acceptWebMeta else {
            self.item?.isForceDeviceOrientation = false
            return
        }
        logger.info("viewDidAppear")
        self.item?.startDeviceMotionObserver()
        logger.info("device motion, start motion observer")
        self.item?.applyMeta()
    }
    
    public func viewDidDisappear(browser: WebBrowser, animated: Bool) {
        self.item?.stopDeviceMotionObserver()
        logger.info("device motion, stop motion observer")
    }
}

final public class WebMetaOrientationExtensionItemBrowserDelegate :WebBrowserProtocol {
    private weak var item: WebMetaOrientationExtensionItem?
    init(item: WebMetaOrientationExtensionItem) {
        self.item = item
    }
    public func browser(_ browser: WebBrowser, didURLChanged url: URL?) {
        guard browser.configuration.acceptWebMeta else {
            self.item?.isForceDeviceOrientation = false
            return
        }
        self.item?.applyMeta()
    }
}

final public class WebMetaOrientationExtensionItemBrowserNavigationDelegate:WebBrowserNavigationProtocol {
    private weak var item: WebMetaOrientationExtensionItem?
    init(item: WebMetaOrientationExtensionItem) {
        self.item = item
    }
    
    public func browser(_ browser: WebBrowser, didCommit navigation: WKNavigation!) {
        logger.info("didCommit")
        if (self.item?.rotationButtonHasCreated == true){
            self.item?.rotationButton.removeFromSuperview()
        }
    }
}
