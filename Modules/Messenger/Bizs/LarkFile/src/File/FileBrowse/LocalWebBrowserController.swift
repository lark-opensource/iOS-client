//
//  LocalWebBrowserController.swift
//  Lark
//
//  Created by linlin on 2017/4/18.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LarkUIKit
import WebBrowser
import LarkMessengerInterface
import SuiteAppConfig
import LarkCore
import WebKit
import LarkFeatureGating
import LarkWebViewContainer

class LocalWebBrowserController: LoadingWebViewController {

    public var webView: WKWebView

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    override var shouldAutorotate: Bool {
        return true
    }

    init(appConfigService: AppConfigService, showLoadingFirstLoad: Bool = true) {
        let larkWebViewConfig = LarkWebViewConfigBuilder().build(
            bizType: .unknown,
            isAutoSyncCookie: appConfigService.feature(for: .sso).isOn,
            secLinkEnable: false,
            performanceTimingEnable: true,
            vConsoleEnable: false
        )
        webView = LarkWebView(frame: .zero, config: larkWebViewConfig, parentTrace: nil)

        super.init(showLoadingFirstLoad: showLoadingFirstLoad)
        webView.navigationDelegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.webView.frame = self.view.bounds
        self.view.addSubview(self.webView)
        self.webView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        self.webView.isUserInteractionEnabled = true
        self.webView.backgroundColor = UIColor.clear
        self.webView.isOpaque = false

        self.view.backgroundColor = UIColor.ud.commonBackgroundColor.nonDynamic
    }
}
