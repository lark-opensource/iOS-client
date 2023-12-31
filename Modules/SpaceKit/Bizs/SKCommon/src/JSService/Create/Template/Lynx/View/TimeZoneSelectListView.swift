//
//  TimeZoneSelectListView.swift
//  SKCommon
//
//  Created by zengsenyuan on 2022/6/2.
//  



import ServerPB
import BDXLynxKit
import BDXServiceCenter
import BDXBridgeKit
import SKFoundation
import EENavigator
import SKResource
import UniverseDesignTheme
import LarkLocalizations
import LarkTraitCollection
import RxSwift
import SwiftyJSON
import SKInfra


public final class TimeZoneSelectListView: UIView {
    
    var lynxView: LynxEnvManager.LynxView?
    
    var didPressBack: (() -> Void)?
    var didFinishSelect: (() -> Void)?
    var didClickItem: ((String) -> Void)?
    
    private var templateRelativePath: String {
        "pages/bitable-time-zone-select-page/time-zone-list/template.js"
    }
    
    private var debugUrl: String?
    
    private var templateLoadParams: LynxTemplateLoader.Params = .default
    
    private(set) public var globalEventEmiter = GlobalEventEmiter()
    
    private let initialProperties: [String: Any]
    
    var id: String?
    
    private var isIpadAndNoSplit: Bool = false
    
    private var globalProps: [String: Any] {
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
        props["isFeishuBrand"] = DomainConfig.envInfo.isFeishuBrand ? "true" : "false"
        props["domain"] = DomainConfig.helpCenterDomain
        return props
    }
    
    private var lastSendSize: CGSize?
    
    private var model: BrowserModelConfig
    
    private let disposeBag = DisposeBag()
    
    public convenience init(frame: CGRect,
                            timeZone: String,
                            timeZoneList: [[String: Any]],
                            model: BrowserModelConfig,
                            isIpadAndNoSplit: Bool = false) {
        var initialProperties = [String: Any]()
        initialProperties["timeZone"] = timeZone
        initialProperties["initDatas"] = timeZoneList
        initialProperties["isIPad"] = isIpadAndNoSplit
        self.init(frame: frame, initialProperties: initialProperties, model: model)
        self.isIpadAndNoSplit = isIpadAndNoSplit
    }
    
    public init(frame: CGRect, initialProperties: [String: Any], model: BrowserModelConfig) {
        self.initialProperties = initialProperties
        self.model = model
        super.init(frame: frame)
        setupDebugURL()
        LynxEnvManager.setupLynx()
        setupKitViewV2()
        observeThemeChange()
    }
        
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        notifySizeChangeIfNeed(type: .width)
    }
    
    enum SizeChangeJudgeType {
        case height
        case width
        case heightOrWidth
    }
    
    func notifySizeChangeIfNeed(type: SizeChangeJudgeType) {
        let preSize = lastSendSize ?? .zero
        let size = self.bounds.size
        
        var needChangeSize: Bool = false
        switch type {
        case .height:
            needChangeSize = abs(preSize.height - size.height) > 0.1
        case .width:
            needChangeSize = abs(preSize.width - size.width) > 0.1
        case .heightOrWidth:
            needChangeSize = abs(preSize.height - size.height) > 0.1 ||
                abs(preSize.width - size.width) > 0.1
        }
        if needChangeSize {
            let event = GlobalEventEmiter.Event(
                name: "ccm-pagesize-change",
                params: ["pageWidth": size.width, "pageHeight": size.height]
            )
            self.globalEventEmiter.send(event: event, needCache: true)
            self.lynxView?.frame = self.bounds
            lynxView?.triggerLayout()
            lastSendSize = size
            debugPrint("TimeZoneSelectListView frame: \(self.frame)")
        }
    }
    
    private func setupDebugURL() {
        if let proxyIPAndPort = CCMKeyValue.globalUserDefault.string(forKey: UserDefaultKeys.lynxTemplateSourceURL) {
            self.debugUrl = "http://\(proxyIPAndPort)/\(LynxEnvManager.channel)/\(self.templateRelativePath)"
        }
    }
    
    private func fetchLynxTemplate() {
        let bdxParams = BDXLynxKitParams()
        bdxParams.widthMode = .exact
        bdxParams.heightMode = .exact
        bdxParams.initialProperties = initialProperties
        var isDebug = false
        if let debugUrl = debugUrl, !debugUrl.isEmpty {
            isDebug = true
            bdxParams.sourceUrl = debugUrl
        }
        if isDebug {
            self.setupKitView(params: bdxParams)
        } else {
            LynxTemplateLoader.shared.register(with: self.templateLoadParams)
            LynxTemplateLoader.shared.fetchTemplate(at: templateRelativePath,
                                                    bizId: self.templateLoadParams.bizId,
                                                    channel: self.templateLoadParams.channel,
                                                    completion: { [weak self] data in
                guard let self = self, let data = data else {
                    return
                }
                bdxParams.sourceUrl = ""
                bdxParams.templateData = data
                self.setupKitView(params: bdxParams)
            })
        }
    }
    
    private func setupKitView(params: BDXLynxKitParams) {
        let frame = self.bounds
        if let kitView = LynxEnvManager.createLynxView(frame: frame, params: params) {
            if self.lynxView != nil {
                self.lynxView?.removeFromSuperview()
                self.globalEventEmiter = GlobalEventEmiter()
            }
            self.globalEventEmiter.setup(lynxView: kitView)
            kitView.configGlobalProps(self.globalProps)
            self.lynxView = kitView
            registerHandlers(for: kitView)
            kitView.lifecycleDelegate = self
            kitView.load()
            self.addSubview(kitView)
            kitView.frame = frame
        }
    }
    
    private func setupKitViewV2() {
        let bdxParams = BDXLynxKitParams()
        bdxParams.widthMode = .exact
        bdxParams.heightMode = .exact
        bdxParams.bundle = templateRelativePath
        bdxParams.initialProperties = initialProperties
        bdxParams.globalProps = globalProps
        let frame = self.bounds
        if let kitView = LynxEnvManager.createLynxViewV2(frame: frame, params: bdxParams) {
            if self.lynxView != nil {
                self.lynxView?.removeFromSuperview()
                self.globalEventEmiter = GlobalEventEmiter()
            }
            self.globalEventEmiter.setup(lynxView: kitView)
            kitView.configGlobalProps(self.globalProps)
            self.lynxView = kitView
            registerHandlers(for: kitView)
            kitView.lifecycleDelegate = self
            kitView.load()
            self.addSubview(kitView)
            kitView.frame = frame
        }
    }
    
    private func observeThemeChange() {
        if #available(iOS 13.0, *) {
            RootTraitCollection.observer
                .observeRootTraitCollectionDidChange(for: self)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: {[weak self] change in
                    guard change.new.userInterfaceStyle != change.old.userInterfaceStyle,
                          let self = self, self.lynxView != nil else { return }
                    self.setupKitViewV2()
                }).disposed(by: disposeBag)
        }
    }
    
    private func isDarkMode() -> Bool {
        if #available(iOS 13.0, *) {
            return self.traitCollection.userInterfaceStyle == .dark
        }
        return false
    }
    
    private func registerHandlers(for lynxView: BDXLynxViewProtocol) {
        let jsBridageHandler = LynxJSBridgeHandler(model: model)
        let dragPanelhandler = DragPanelHandler { [weak self] (type, _) in
            guard let self = self else { return }
            switch type {
            case .show: break
            case .close:
                self.didPressBack?()
            }
        }
        let timeZoneListHander = TimeZoneListHandler {[weak self] type in
            switch type {
            case .finish:
                self?.didFinishSelect?()
            }
        }
        
        let containerHandler = ContainerEventHandler {[weak self] event, params in
            switch event {
            case .onClick:
                if let paramsJSONString = params["params"] as? String {
                    let paramsJSON = JSON(parseJSON: paramsJSONString)
                    let formate = paramsJSON["formate"].stringValue
                    self?.didClickItem?("(\(formate))")
                }
            default: break
            }
        }
        
        lynxView.registerHandler(jsBridageHandler.handler, forMethod: jsBridageHandler.methodName)
        lynxView.registerHandler(dragPanelhandler.handler, forMethod: dragPanelhandler.methodName)
        lynxView.registerHandler(timeZoneListHander.handler, forMethod: timeZoneListHander.methodName)
        lynxView.registerHandler(containerHandler.handler, forMethod: containerHandler.methodName)
    }
    
    class TimeZoneListHandler: BridgeHandler {
        enum ActionType: String {
            case finish
        }
        
        let methodName = "ccm.TimeZoneList"
        var handler: BDXLynxBridgeHandler
        
        init(callbackHandler: ((ActionType) -> Void)? = nil) {
            handler = {(_, _, params, callback) in
                guard let typeValue = params?["type"] as? String, let type = ActionType(rawValue: typeValue)  else {
                    DocsLogger.error("registerCCMTimeZoneListHandler fail params is wrong")
                    callback(BDXBridgeStatusCode.failed.rawValue, nil)
                    return
                }
                DocsLogger.info("registerTimeZoneListHandler success type: \(typeValue)")
                callbackHandler?(type)
                callback(BDXBridgeStatusCode.succeeded.rawValue, nil)
            }
        }
    }
}

extension TimeZoneSelectListView: BDXKitViewLifecycleProtocol {
    
    public func view(_ view: BDXKitViewProtocol, didChangeIntrinsicContentSize size: CGSize) {
        DocsLogger.info("didChangeIntrinsicContentSize:\(size)")
    }
    
    public func viewDidStartLoading(_ view: BDXKitViewProtocol) {
        DocsLogger.info("viewDidStartLoading")
    }

    public func view(_ view: BDXKitViewProtocol, didStartFetchResourceWithURL url: String?) {
        DocsLogger.info("didStartFetchResourceWithURL")
    }

    public func view(_ view: BDXKitViewProtocol, didFetchedResource resource: BDXResourceProtocol?, error: Error?) {
        if let error = error {
            DocsLogger.error("didFetchedResource", error: error)
        }
    }
    
    public func viewDidFirstScreen(_ view: BDXKitViewProtocol) {
        DocsLogger.info("viewDidFirstScreen")
        globalEventEmiter.jsRuntimeDidReady()
    }
    
    public func view(_ view: BDXKitViewProtocol, didFinishLoadWithURL url: String?) {
        DocsLogger.info("didFinishLoadWithURL")
    }
    
    public func view(_ view: BDXKitViewProtocol, didLoadFailedWithUrl url: String?, error: Error?) {
        DocsLogger.error("didLoadFailedWithUrl", error: error)
    }
    
    public func view(_ view: BDXKitViewProtocol, didRecieveError error: Error?) {
        DocsLogger.error("didRecieveError", error: error)
    }
}
