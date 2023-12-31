//
//  LynxBaseViewController.swift
//  SKCommon
//
//  Created by 曾浩泓 on 2021/11/4.
//  


import Foundation
import SKFoundation
import SKUIKit
import BDXLynxKit
import BDXServiceCenter
import BDXBridgeKit
import UniverseDesignTheme
import LarkLocalizations
import LarkAppConfig
import LarkTraitCollection
import RxSwift
import SKInfra

open class LynxBaseViewController: BaseViewController, BDXKitViewLifecycleProtocol {
    private(set) public var lynxView: LynxEnvManager.LynxView?
    var id: String?
    var templateLoadParams: LynxTemplateLoader.Params = .default
    public var templateRelativePath: String = ""
    public var hotfixLoadStrategy: LynxGeckoLoadStrategy = .localFirstNotWaitRemote
    public var initialProperties: [String: Any] = [:]
    private(set) public var globalEventEmiter = GlobalEventEmiter()
    private var debugUrl: String?
    public var customHandlers: [BridgeHandler] = []

    open var shareContextID: String?

    var globalProps: [String: Any] {
        var props: [String: Any] = [:]
        #if DEBUG
        props["appIsDebug"] =  "true"
        #else
        props["appIsDebug"] =  "false"
        #endif
        props["containerId"] = "\(self.id ?? "")_\(unsafeBitCast(self, to: Int.self)))"
        props["brightness"] = isDarkMode() ? "dark" : "light"
        let langId = LanguageManager.currentLanguage.identifier
        props["language"] = langId.replacingOccurrences(of: "_", with: "-")
        props["isUSPackage"] = DomainConfig.envInfo.isFeishuPackage ? "false" : "true"
        props["shareContextID"] = shareContextID
        props["isFeishuBrand"] = DomainConfig.envInfo.isFeishuBrand ? "true" : "false"
        props["domain"] = DomainConfig.helpCenterDomain
        return props
    }
    private let bag = DisposeBag()
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationBar.isHidden = true
        LynxEnvManager.setupLynx()
        setupKitViewV2()
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        lynxView?.triggerLayout()
    }
    
    private func fetchTemplateData() {
        let bdxParams = BDXLynxKitParams()
        bdxParams.widthMode = .exact
        bdxParams.heightMode = .exact
        bdxParams.initialProperties = initialProperties
        if let shareContextID {
            bdxParams.groupContext = shareContextID
        }
        var isDebug = false
        if let debugUrl = debugUrl, !debugUrl.isEmpty {
            isDebug = true
            bdxParams.sourceUrl = debugUrl
        }
        if isDebug {
            self.setupKitView(params: bdxParams)
            DocsLogger.info("[lynx] fetchTemplateData debugURl: \(debugUrl ?? "")", component: LogComponents.lynx)
            
        } else {
            DocsLogger.info("[lynx] fetchTemplateData templateRelativePath: \(templateRelativePath)", component: LogComponents.lynx)
            LynxTemplateLoader.shared.register(with: self.templateLoadParams)
            LynxTemplateLoader.shared.fetchTemplate(
                at: templateRelativePath,
                bizId: templateLoadParams.bizId,
                channel: templateLoadParams.channel
            ) { [weak self] data in
                guard let self = self, let data = data else {
                    return
                }
                bdxParams.sourceUrl = ""
                bdxParams.templateData = data
                self.setupKitView(params: bdxParams)
            }
        }
    }
    
    private func setupKitView(params: BDXLynxKitParams) {
        let frame = calculateFrameForLynxView()
        if let kitView = LynxEnvManager.createLynxView(frame: frame, params: params) {
            // bdx会设置默认的GlobalProps，这里往里面更新一些我们的
            kitView.configGlobalProps(self.globalProps)
            if let preLynxView = self.lynxView {
                preLynxView.removeFromSuperview()
                let unsendEvents = self.globalEventEmiter.drain()
                self.globalEventEmiter = GlobalEventEmiter(unsendEvents)
            }
            self.globalEventEmiter.setup(lynxView: kitView)
            self.lynxView = kitView
            registerHandlers(for: kitView)
            kitView.lifecycleDelegate = self
            kitView.load()
            DocsLogger.info("[lynx] setupKitView success: \(templateRelativePath)", component: LogComponents.lynx)
            self.view.addSubview(kitView)
            kitView.snp.makeConstraints { make in
                make.leading.trailing.equalTo(view.safeAreaLayoutGuide)
                make.bottom.equalToSuperview()
                make.top.equalTo(self.statusBar.snp.bottom)
            }
        }
    }
    
    private func setupKitViewV2() {
        let bdxParams = BDXLynxKitParams()
        bdxParams.widthMode = .exact
        bdxParams.heightMode = .exact
        bdxParams.bundle = templateRelativePath
        bdxParams.initialProperties = initialProperties
        if let shareContextID {
            bdxParams.groupContext = shareContextID
        }
        let frame = calculateFrameForLynxView()
        if let kitView = LynxEnvManager.createLynxViewV2(frame: frame, params: bdxParams, hotfixLoadStrategy: hotfixLoadStrategy) {
            // bdx会设置默认的GlobalProps，这里往里面更新一些我们的
            kitView.configGlobalProps(self.globalProps)
            if let preLynxView = self.lynxView {
                preLynxView.removeFromSuperview()
                let unsendEvents = self.globalEventEmiter.drain()
                self.globalEventEmiter = GlobalEventEmiter(unsendEvents)
            }
            self.globalEventEmiter.setup(lynxView: kitView)
            self.lynxView = kitView
            registerHandlers(for: kitView)
            kitView.lifecycleDelegate = self
            kitView.load()
            DocsLogger.info("[lynx] setupKitView success: \(templateRelativePath)", component: LogComponents.lynx)
            self.view.addSubview(kitView)
            kitView.snp.makeConstraints { make in
                make.leading.trailing.equalTo(view.safeAreaLayoutGuide)
                make.bottom.equalToSuperview()
                make.top.equalTo(self.statusBar.snp.bottom)
            }
        }
    }
    
    private func calculateFrameForLynxView() -> CGRect {
        var frame = self.view.bounds
        frame.origin.y = self.statusBar.frame.maxY
        frame.size.height -= self.statusBar.frame.size.height
        return frame
    }
    
    private func setupDebugURL() {
        if let proxyIPAndPort = CCMKeyValue.globalUserDefault.string(forKey: UserDefaultKeys.lynxTemplateSourceURL) {
            self.debugUrl = "http://\(proxyIPAndPort)/\(LynxEnvManager.channel)/\(self.templateRelativePath)"
        }
    }

    private func registerHandlers(for lynxView: BDXLynxViewProtocol) {
        let eventHandlers: [BridgeHandler] = [
            PageOpenBridgeHandler(page: self),
            PageCloseBridgeHandler(page: self),
            DialogBridgeHandler(hostController: self),
            ToastBridgeHandler(hostController: self),
            NetStatusBridgeHandler(hostController: self)
        ] + customHandlers

        eventHandlers.forEach { (handler) in
            lynxView.registerHandler(handler.handler, forMethod: handler.methodName)
        }
        registerBizHandlers(for: lynxView)
    }

    // 供子类 override
    public func registerBizHandlers(for lynxView: BDXLynxViewProtocol) {}
    
    // MARK: BDXKitViewLifecycleProtocol
    public func view(_ view: BDXKitViewProtocol, didChangeIntrinsicContentSize size: CGSize) {
        DocsLogger.info("didChangeIntrinsicContentSize:\(size)", component: LogComponents.lynx)
    }
    public func viewDidStartLoading(_ view: BDXKitViewProtocol) {
        DocsLogger.info("viewDidStartLoading", component: LogComponents.lynx)
    }

    public func view(_ view: BDXKitViewProtocol, didStartFetchResourceWithURL url: String?) {
        DocsLogger.info("didStartFetchResourceWithURL", component: LogComponents.lynx)
    }

    public func view(_ view: BDXKitViewProtocol, didFetchedResource resource: BDXResourceProtocol?, error: Error?) {
        if let error = error {
            DocsLogger.error("didFetchedResource", error: error, component: LogComponents.lynx)
        }
    }
    
    open func viewDidFirstScreen(_ view: BDXKitViewProtocol) {
        DocsLogger.info("viewDidFirstScreen", component: LogComponents.lynx)
        // 本来应该在viewDidConstructJSRuntime生命周期方法里发送全局事件，
        // 但当前使用的BDX版本还不支持这个方法，暂时先在这个生命周期方法做
        globalEventEmiter.jsRuntimeDidReady()
    }
    
    public func view(_ view: BDXKitViewProtocol, didFinishLoadWithURL url: String?) {
        DocsLogger.info("didFinishLoadWithURL", component: LogComponents.lynx)
    }
    
    public func view(_ view: BDXKitViewProtocol, didLoadFailedWithUrl url: String?, error: Error?) {
        DocsLogger.error("didLoadFailedWithUrl", error: error, component: LogComponents.lynx)
    }
    
    public func view(_ view: BDXKitViewProtocol, didRecieveError error: Error?) {
        DocsLogger.error("didRecieveError", error: error, component: LogComponents.lynx)
    }
    
    // MARK: Theme
    private func isDarkMode() -> Bool {
        if #available(iOS 13.0, *) {
            return self.traitCollection.userInterfaceStyle == .dark
        }
        return false
    }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
                setupKitViewV2()
            }
        }
    }

    public func updateData(data: Any?) {
        guard let lynxView = lynxView else {
            return
        }

        lynxView.update(withData: data)
    }
}
