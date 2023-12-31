//
//  MailSignaturePreviewViewController.swift
//  MailSDK
//
//  Created by majx on 2020/1/21.
//

import Foundation
import LarkUIKit
import EENavigator
import WebKit

class MailSignaturePreviewViewController: MailBaseViewController {
    private var htmlStr = ""
    private let accountContext: MailAccountContext
    
    init(htmlStr: String, accountContext: MailAccountContext) {
        self.htmlStr = htmlStr
        self.accountContext = accountContext
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var serviceProvider: MailSharedServicesProvider? {
        accountContext
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(webView)
        webView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        webView.loadHTMLString(htmlStr, baseURL: nil)
    }
    


    lazy var webView: MailNewBaseWebView = {
        /// this script use to scale signature in mobile
        /// close contenteditable
        let script = MailSignaturePreviewScript.mobileScalable + MailSignaturePreviewScript.closeEditable + MailSignaturePreviewScript.darkModeJS
        let wkUScript = WKUserScript(source: script, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        let wkUController = WKUserContentController()
        wkUController.addUserScript(wkUScript)
        let wkWebConfig = WKWebViewConfiguration()
        wkWebConfig.userContentController = wkUController
        let webView = MailWebViewSchemeManager.makeDefaultNewWebView(config: wkWebConfig, provider: accountContext)
        webView.loadHTMLString("", baseURL: nil)
        return webView
    }()
}
