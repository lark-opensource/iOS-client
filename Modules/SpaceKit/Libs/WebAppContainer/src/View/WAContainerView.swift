//
//  WAContainerView.swift
//  WebAppContainer
//
//  Created by lijuyou on 2023/11/14.
//

import Foundation
import LarkUIKit
import WebKit
import SnapKit
import LarkWebViewContainer
import LKCommonsLogging
import LarkContainer
import SKUIKit


class WAContainerView: UIView {
    static let logger = Logger.log(WAContainerView.self, category: WALogger.TAG)
    let webview: WAWebView
    let viewModel: WAContainerViewModel
    var identifier: String { "wa_\(ObjectIdentifier(self))" }
    //preload
    var usedCount = 0//使用次数
    let createTime = WAPerformanceTiming.getTimeStamp()
    var inPool: Bool = false {
        didSet {
            Self.logger.info("update inPool:\(inPool) for \(self.identifier)", tag: LogTag.open.rawValue)
        }
    }
    
    init(frame: CGRect, config: WebAppConfig, userResolver: UserResolver) {
        self.webview = ContainerCreator.createWebView(config: config)
        self.viewModel = WAContainerViewModel(config: config, webView: self.webview, userResolver: userResolver)
        self.viewModel.timing.createWebView = self.createTime
        super.init(frame: frame)
        Self.logger.info("new a WAContainerView \(self.identifier)", tag: LogTag.open.rawValue)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        Self.logger.info("WAContainerView deinit for \(self.identifier) ", tag: LogTag.open.rawValue)
    }
    
    func setup() {
        self.addSubview(webview)
        if self.viewModel.config.webviewConfig?.keyboardLayout == .adjustResize {
            webview.snp.makeConstraints { (make) in
                make.left.right.top.equalToSuperview()
                make.bottom.equalTo(self.skKeyboardLayoutGuide.snp.top)
            }
        } else {
            webview.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        }
    }
    
    func attachToVC(_ vc: WAContainerViewController) {
        Self.logger.info("attachToVC for \(self.identifier)")
        self.viewModel.attachToVC(vc)
    }
    
    func dettachFromVC() {
        let isReadyForReuse = self.viewModel.isReadyForReuse //在viewModel dettach前拿到状态
        Self.logger.info("dettachFromVC for \(self.identifier)")
        self.viewModel.dettachFromVC()
        
        //只要没ready 或 出现错误
        if let preloader = try? self.viewModel.userResolver.resolve(assert: WAContainerPreloader.self) {
            if isReadyForReuse {
                Self.logger.info("dettachFromVC, push back To Pool", tag: LogTag.open.rawValue)
                preloader.pool.pushToPool(self)
            } else {
                Self.logger.info("dettachFromVC, remove cache container because not ready", tag: LogTag.open.rawValue)
                preloader.pool.removeItem(for: self.viewModel.config.appName)
            }
        }
       
    }
}
