//
//  SKLynxPanelController.swift
//  SKCommon
//
//  Created by Weston Wu on 2022/11/11.
//

import Foundation
import SKUIKit
import SKFoundation
import BDXLynxKit
import BDXBridgeKit
import BDXServiceCenter
import LarkLocalizations
import RxSwift
import SKInfra

open class SKLynxPanelController: SKPanelController, BDXKitViewLifecycleProtocol {
    private(set) public var lynxView: LynxEnvManager.LynxView?
    private(set) public var globalEventEmitter = GlobalEventEmiter()

    private var templateLoadParams: LynxTemplateLoader.Params = .default
    private var debugURL: String?
    private let disposeBag = DisposeBag()

    open var containerID: String?
    open var templateRelativePath: String
    open var hotfixLoadStrategy: LynxGeckoLoadStrategy = .localFirstNotWaitRemote
    open var initialProperties: [String: Any]
    open var customHandlers: [BridgeHandler] = []
    open var shareContextID: String?
    // 首屏预估大小
    open var estimateHeight: Double?

    open var globalProps: [String: Any] {
        var props: [String: Any] = [:]
        #if DEBUG
        props["appIsDebug"] = "true"
        #else
        props["appIsDebug"] = "false"
        #endif
        props["containerId"] = "\(containerID ?? "")_\(unsafeBitCast(self, to: Int.self))"
        props["brightness"] = isDarkMode ? "dark" : "light"
        let languageID = LanguageManager.currentLanguage.identifier
        props["language"] = languageID.replacingOccurrences(of: "_", with: "-")
        props["isUSPackage"] = DomainConfig.envInfo.isFeishuPackage ? "false" : "true"
        props["shareContextID"] = shareContextID
        props["isFeishuBrand"] = DomainConfig.envInfo.isFeishuBrand ? "true" : "false"
        props["domain"] = DomainConfig.helpCenterDomain
        return props
    }

    private var isDarkMode: Bool {
        if #available(iOS 13.0, *) {
            return traitCollection.userInterfaceStyle == .dark
        }
        return false
    }

    var supportOrientations: UIInterfaceOrientationMask = .portrait

    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if SKDisplay.pad {
            return [.all]
        }
        return supportOrientations
    }

    public init(templateRelativePath: String, initialProperties: [String: Any] = [:]) {
        self.templateRelativePath = templateRelativePath
        self.initialProperties = initialProperties
        super.init(nibName: nil, bundle: nil)
    }

    public convenience init(config: SKLynxConfig) {
        let cardPath = config.cardPath
        self.init(templateRelativePath: cardPath, initialProperties: config.initialProperties ?? [:])
        shareContextID = config.shareContextID
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
    }

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let lynxView, lynxView.frame.isEmpty {
            containerView.layoutIfNeeded()
        }
        lynxView?.triggerLayout()
    }

    open override func setupUI() {
        super.setupUI()
        LynxEnvManager.setupLynx()
        setupLynxView()
    }

    private func setupLynxView() {
        let bdxParams = BDXLynxKitParams()
        bdxParams.widthMode = .exact
        bdxParams.heightMode = .undefined
        bdxParams.bundle = templateRelativePath
        bdxParams.initialProperties = initialProperties
        if let shareContextID {
            bdxParams.groupContext = shareContextID
        }
        guard let lynxView = LynxEnvManager.createLynxViewV2(frame: .zero, params: bdxParams, hotfixLoadStrategy: hotfixLoadStrategy) else {
            spaceAssertionFailure("create lynx view failed")
            return
        }
        containerView.addSubview(lynxView)
        lynxView.snp.makeConstraints { make in
            // 底部延伸到了 safeArea 之下，在 lynx 内自行决定适配规则
            make.leading.trailing.equalTo(self.view.safeAreaLayoutGuide)
            make.top.bottom.equalToSuperview()
            make.height.equalTo(estimateHeight ?? 0)
        }
        lynxView.configGlobalProps(globalProps)
        if let previousView = self.lynxView {
            previousView.removeFromSuperview()
            let unsendEvents = globalEventEmitter.drain()
            globalEventEmitter = GlobalEventEmiter(unsendEvents)
        }
        globalEventEmitter.setup(lynxView: lynxView)
        self.lynxView = lynxView
        setupHandlers(lynxView: lynxView)
        lynxView.lifecycleDelegate = self
        lynxView.load()
        DocsLogger.info("[lynx] setupKitView success: \(templateRelativePath) in Panel Container", component: LogComponents.lynx)
    }

    private func setupHandlers(lynxView: BDXLynxViewProtocol) {
        let eventHandlers: [BridgeHandler] = [
            PageOpenBridgeHandler(page: self),
            PageCloseBridgeHandler(page: self),
            DialogBridgeHandler(hostController: self),
            ToastBridgeHandler(hostController: self),
            NetStatusBridgeHandler(hostController: self)
        ] + customHandlers

        eventHandlers.forEach { handler in
            lynxView.registerHandler(handler.handler, forMethod: handler.methodName)
        }

        setupBizHandlers(for: lynxView)
    }

    open func setupBizHandlers(for lynxView: BDXLynxViewProtocol) {}

    // MARK: - BDXKitViewLifecycleProtocol
    open func view(_ view: BDXKitViewProtocol, didChangeIntrinsicContentSize size: CGSize) {
        DocsLogger.info("didChangeIntrinsicContentSize:\(size)", component: LogComponents.lynx)
        var contentSize = size
        contentSize.width = size.width == 0 ? 320 : size.width
        if size.height == 0 { return }
        guard preferredContentSize != contentSize else { return }
        preferredContentSize = contentSize
        if let lynxView {
            lynxView.snp.remakeConstraints { make in
                make.leading.trailing.equalTo(self.view.safeAreaLayoutGuide)
                make.top.bottom.equalToSuperview()
                make.height.equalTo(size.height)
            }
        }
    }

    open override func adjustsPreferredContentSize() {
        var compressSize = UIView.layoutFittingCompressedSize
        let width: CGFloat = isFormSheet ? 575 : 375
        compressSize.width = width
        var preferredSize = containerView.systemLayoutSizeFitting(compressSize)
        // 默认宽度 width
        preferredSize.width = width
        preferredContentSize = preferredSize
    }

    open func viewDidStartLoading(_ view: BDXKitViewProtocol) {
        DocsLogger.info("viewDidStartLoading", component: LogComponents.lynx)
    }

    open func view(_ view: BDXKitViewProtocol, didStartFetchResourceWithURL url: String?) {
        DocsLogger.info("didStartFetchResourceWithURL", component: LogComponents.lynx)
    }

    open func view(_ view: BDXKitViewProtocol, didFetchedResource resource: BDXResourceProtocol?, error: Error?) {
        DocsLogger.info("didFetchedResource", error: error, component: LogComponents.lynx)
    }

    open func viewDidFirstScreen(_ view: BDXKitViewProtocol) {
        DocsLogger.info("viewDidFirstScreen", component: LogComponents.lynx)
        // 本来应该在viewDidConstructJSRuntime生命周期方法里发送全局事件，
        // 但当前使用的BDX版本还不支持这个方法，暂时先在这个生命周期方法做
        globalEventEmitter.jsRuntimeDidReady()
    }

    open func view(_ view: BDXKitViewProtocol, didFinishLoadWithURL url: String?) {
        DocsLogger.info("didFinishLoadWithURL", component: LogComponents.lynx)
    }

    open func view(_ view: BDXKitViewProtocol, didLoadFailedWithUrl url: String?, error: Error?) {
        DocsLogger.error("didLoadFailedWithUrl", error: error, component: LogComponents.lynx)
    }

    open func view(_ view: BDXKitViewProtocol, didRecieveError error: Error?) {
        DocsLogger.error("didRecieveError", error: error, component: LogComponents.lynx)
    }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
                setupLynxView()
            }
        }
    }

    public func update(data: Any?) {
        guard let lynxView else { return }
        lynxView.update(withData: data)
    }
}

extension SKLynxPanelController: SKLynxGlobalEventHandler {
    public func requestSend(event: GlobalEventEmiter.Event) {
        globalEventEmitter.send(event: event)
    }
}
