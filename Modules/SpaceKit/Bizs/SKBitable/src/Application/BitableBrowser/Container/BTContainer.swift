//
//  BTContainer.swift
//  SKBitable
//
//  Created by yinyuan on 2023/9/6.
//

import SKFoundation
import SKCommon
import LarkUIKit
import SKUIKit
import SKBrowser
import UniverseDesignTheme

class BTContainerPluginSet {
    static let statusBar = BTContainerStatusBarPlugin.self
    static let topContainer = BTContainerTopContainerPlugin.self
    static let mainContainer = BTContainerMainContainerPlugin.self
    static let baseHeaderContainer = BTContainerHeaderPlugin.self
    static let blockCatalogueContainer = BTContainerBlockCataloguePlugin.self
    static let viewContainer = BTContainerViewContainerPlugin.self
    static let viewCatalogueBanner = BTContainerViewCataloguePlugin.self
    static let toolBar = BTContainerToolBarPlugin.self
    static let browserView = BTContainerBrowserViewPlugin.self
    static let background = BTContainerBackgroundPlugin.self
    static let onboarding = BTContainerOnboardingPlugin.self
    static let loading = BTContainerLoadingPlugin.self
    static let fab = BTContainerFABPlugin.self
    static let nativeRender = BTContainerNativeRenderPlugin.self
}

protocol BTContainerDelegate: AnyObject {
    var browserViewController: BitableBrowserViewController? { get }
    
    func callFunction(_ function: DocsJSCallBack, params: [String: Any]?, completion: ((_ info: Any?, _ error: Error?) -> Void)?)
}

class BTContainer: NSObject {
    weak var delegate: BTContainerDelegate?
    
    var currentHeaderModel : BTShowHeaderModel? = nil

    var lastUpdateStatusTime: TimeInterval = 0
    // 需要做动画的状态变化，放到这里
    var status: BTContainerStatus = BTContainerStatus()
    // 不需要直接做动画的 Model 放到这里
    var model: BTContainerModel = BTContainerModel()
    var plugins: [String: BTContainerPlugin] = [:]

    init(delegate: BTContainerDelegate) {
        super.init()
        self.delegate = delegate
        delegate.browserViewController?.editor.browserViewLifeCycleEvent.addObserver(self)
    }
    
    func setupView(hostView: UIView) {
        DocsLogger.info("BTContainer.setupViewBegin")
        // 手动主动初始化的插件
        statusBarPlugin.setupView(hostView: hostView)
        topContainerPlugin.setupView(hostView: hostView)
        onboardingPlugin.setupView(hostView: hostView)
        mainContainerPlugin.setupView(hostView: hostView)
        backgroundPlugin.setupView(hostView: hostView)
        loadingPlugin.setupView(hostView: hostView)
        gesturePlugin?.setupView(hostView: hostView)
        if UserScopeNoChangeFG.YY.bitablePerfOpenInRecordShare, isIndRecord {
            indRecordPlugin.setupView(hostView: hostView)
		}
		if isAddRecord {
            addRecordPlugin.setupView(hostView: hostView)  // 主动触发加载 meta
        }
        
        // 初始化完成后，先默认执行一次 remakeConstraints
        remakeConstraints()
        
        // 初始化完成后，先默认执行一下 updateStatus
        updateStatus(status: status, animated: false)
        DocsLogger.info("BTContainer.setupViewEnd")
    }
}
