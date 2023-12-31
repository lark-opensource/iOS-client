//
//  SpaceLynxBannerView.swift
//  SKCommon
//
//  Created by 曾浩泓 on 2021/10/6.
//  


import UIKit
import UGBanner
import ServerPB
import BDXLynxKit
import BDXServiceCenter
import BDXBridgeKit
import SKFoundation
import SnapKit
import EENavigator
import SKResource
import UniverseDesignTheme
import LarkTraitCollection
import RxSwift

public protocol SpaceLynxBannerViewDelegate: AnyObject {
    func bannerView(_ view: SpaceLynxBannerView, didChangeIntrinsicContentHeight height: CGFloat)
    func bannerViewDidClick(_ view: SpaceLynxBannerView, params: [String: Any]?)
    func bannerViewDidShow(_ view: SpaceLynxBannerView)
    func bannerViewDidClickClose(_ view: SpaceLynxBannerView)
}

public final class SpaceLynxBannerView: UIView {
    private var lynxView: LynxEnvManager.LynxView?
    private weak var delegate: SpaceLynxBannerViewDelegate?
    private let initialProperties: [String: Any]
    private let bag = DisposeBag()
    
    public convenience init(frame: CGRect, bannerInfo: UGBanner.BannerInfo, delegate: SpaceLynxBannerViewDelegate?) {
        var initialProperties = [String: Any]()
        initialProperties["text"] = bannerInfo.bannerName
        initialProperties["isInit"] = true
        initialProperties["data"] = bannerInfo.toDictionary()
        self.init(frame: frame, initialProperties: initialProperties, delegate: delegate)
    }
    public init(frame: CGRect, initialProperties: [String: Any], delegate: SpaceLynxBannerViewDelegate?) {
        self.initialProperties = initialProperties
        super.init(frame: frame)
        self.delegate = delegate
        LynxEnvManager.setupLynx()
        setupKitViewV2()
        observeThemeChange()
    }
        
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        guard let lynxView = lynxView else {
            return
        }
        let preWidth = lynxView.frame.size.width
        lynxView.frame = self.bounds
        if abs(preWidth - lynxView.frame.size.width) > 0.1 {
            lynxView.triggerLayout()
        }
    }
    
    private func fetchData() {
        let params = LynxTemplateLoader.Params.default
        LynxTemplateLoader.shared.register(with: params)
        LynxTemplateLoader.shared.fetchTemplate(
            at: "pages/banner/template.js",
            bizId: params.bizId,
            channel: params.channel
        ) { [weak self] data in
            guard let self = self, let data = data else {
                return
            }
            self.setupKitView(templateData: data)
        }
    }
    
    func setupKitView(templateData: Data) {
        let params = BDXLynxKitParams()
        params.sourceUrl = ""
        params.widthMode = .exact
        params.heightMode = .undefined
        params.initialProperties = initialProperties
        params.globalProps = globalProps()
        params.templateData = templateData
        
        let frame = self.bounds
        if let kitView = LynxEnvManager.createLynxView(frame: frame, params: params) {
            if self.lynxView != nil {
                self.lynxView?.removeFromSuperview()
            }
            
            self.lynxView = kitView
            registerHandlers(for: kitView)
            kitView.lifecycleDelegate = self
            kitView.load()
            
            self.addSubview(kitView)
        }
        
    }
    
    private func setupKitViewV2() {
        let bdxParams = BDXLynxKitParams()
        bdxParams.widthMode = .exact
        bdxParams.heightMode = .undefined
        bdxParams.bundle = "pages/banner/template.js"
        bdxParams.initialProperties = initialProperties
        bdxParams.globalProps = globalProps()
        let frame = self.bounds
        if let kitView = LynxEnvManager.createLynxViewV2(frame: frame, params: bdxParams, hotfixLoadStrategy: .localFirstOrWaitRemote) {
            if self.lynxView != nil {
                self.lynxView?.removeFromSuperview()
            }
            
            self.lynxView = kitView
            registerHandlers(for: kitView)
            kitView.lifecycleDelegate = self
            kitView.load()
            
            self.addSubview(kitView)
        }
    }
    
    private func globalProps() -> [String: Any] {
        var props: [String: Any] = [:]
        props["appIsDebug"] = "true"
        props["containerId"] = "space_banner_\(unsafeBitCast(self, to: Int.self)))"
        props["brightness"] = isDarkMode() ? "dark" : "light"
        return props
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
                }).disposed(by: bag)
        }
    }
    private func isDarkMode() -> Bool {
        guard #available(iOS 13.0, *) else {
            return false
        }
        return UIColor.docs.isCurrentDarkMode
    }
    
    private func registerHandlers(for lynxView: BDXLynxViewProtocol) {
        let containerEventHandler: BDXLynxBridgeHandler = { [weak self] (container, name, params, callback) in
            guard let self = self, let delegate = self.delegate else {
                callback(BDXBridgeStatusCode.succeeded.rawValue, nil)
                return
            }
            guard let eventName = params?["eventName"] as? String else {
                callback(BDXBridgeStatusCode.failed.rawValue, nil)
                return
            }
            switch eventName {
            case "onClick":
                let paramMap = params?["params"] as? [String: Any]
                delegate.bannerViewDidClick(self, params: paramMap)
            case "onShow":
                delegate.bannerViewDidShow(self)
            case "closeContainer":
                delegate.bannerViewDidClickClose(self)
            default:
                break
            }
            callback(BDXBridgeStatusCode.succeeded.rawValue, nil)
        }
        lynxView.registerHandler(containerEventHandler, forMethod: "ccm.sendContainerEvent")
    }
}

extension SpaceLynxBannerView: BDXKitViewLifecycleProtocol {
    public func view(_ view: BDXKitViewProtocol, didChangeIntrinsicContentSize size: CGSize) {
        DocsLogger.info("didChangeIntrinsicContentSize:\(size)")
        if var frameOfLynxView = self.lynxView?.frame {
            frameOfLynxView.size.height = size.height
            self.lynxView?.frame = frameOfLynxView
        }
        delegate?.bannerView(self, didChangeIntrinsicContentHeight: size.height)
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
