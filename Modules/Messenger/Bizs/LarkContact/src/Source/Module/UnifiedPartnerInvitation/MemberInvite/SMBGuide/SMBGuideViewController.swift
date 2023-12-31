//
//  SMBGuideViewController.swift
//  LarkContact
//
//  Created by bytedance on 2022/4/11.
//

import Foundation
import UIKit
import WebKit
import LarkUIKit
import WebBrowser
import SnapKit
import UniverseDesignFont
import LarkWebViewContainer
import LKCommonsLogging
import LKCommonsTracker
import Homeric

final class SMBGuideViewController: UIViewController, WebBrowserNavigationProtocol {

    static private let logger = Logger.log(SMBGuideViewController.self,
                                           category: "LarkContact.SMBGuideViewController")
    private var timeoutTimer: Timer?
    var isTimeout: Bool = false
    public init(url: URL, isFullScreen: Bool = true) {
        self.url = url
        self.isFullScreen = isFullScreen
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    lazy var loadingView: SMBGuideLoadingView = SMBGuideLoadingView()

    lazy var loadFailView: SMBGuideLoadFailView = SMBGuideLoadFailView()

    private var url: URL
    private var isFullScreen: Bool

    lazy var webBrowser: WebBrowser = {
        let configuration = WebBrowserConfiguration(webBizType: .ug)
        let browser = WebBrowser(url: url, configuration: configuration)
        do {
            let loadItem = UGWebBrowserLoadItem(fallback: nil)
            loadItem.navigationDelegate = self
            try? browser.register(item: loadItem)
            let singleItem = UGSingleExtensionItem(browser: browser, stepInfo: nil)
            try? browser.register(singleItem: singleItem)
            try? browser.register(item: UniteRouterExtensionItem())
        } catch {
        }
        return browser
    }()

    deinit {
        if let timer = timeoutTimer, timer.isValid {
            timer.invalidate()
        }
        timeoutTimer = nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        // 启动超时计时器
        if timeoutTimer == nil {
            let timeoutTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(5.0), repeats: false, block: { [weak self] _ in
                guard let self = self else { return }
                self.isTimeout = true
                self.loadingView.isHidden = true
                self.webBrowser.view.isHidden = true
                self.loadFailView.isHidden = false
                Tracker.post(TeaEvent(Homeric.ONBOARDING_LOAD_FAILURE_VIEW))
            })
            RunLoop.main.add(timeoutTimer, forMode: .common)
            self.timeoutTimer = timeoutTimer
        }
        Tracker.post(TeaEvent(Homeric.ONBOARDING_LOADING_VIEW))
        loadingView.isHidden = false
        webBrowser.view.isHidden = true
        loadFailView.isHidden = true
    }

    private func setupUI() {
        view.backgroundColor = UIColor.ud.staticBlack40
        addChild(webBrowser)
        view.addSubview(webBrowser.view)
        view.addSubview(loadingView)
        view.addSubview(loadFailView)
        if isFullScreen {
            loadingView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        } else {
            loadingView.snp.makeConstraints { make in
                make.width.equalTo(303)
                make.height.equalTo(582)
                make.centerX.centerY.equalToSuperview()
            }
        }
        loadFailView.snp.makeConstraints { make in
            make.edges.equalTo(loadingView)
        }
        webBrowser.view.snp.makeConstraints { make in
            make.edges.equalTo(loadingView)
        }
        loadFailView.closeButtonClickEvent = { [weak self] in
            guard let self = self else { return }
            Tracker.post(TeaEvent(Homeric.ONBOARDING_LOAD_FAILURE_CLICK))
            self.dismiss(animated: true)
        }
        if !isFullScreen {
            loadingView.layer.cornerRadius = 8
            loadingView.clipsToBounds = true
            loadFailView.layer.cornerRadius = 8
            loadFailView.clipsToBounds = true
            webBrowser.view.layer.cornerRadius = 8
            webBrowser.view.clipsToBounds = true
        }
    }

    func browser(_ browser: WebBrowser, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        guard !isTimeout else { return }
        timeoutTimer?.invalidate()
        Self.logger.info("browser did fail provisional navigation with error: \(error)")
        Tracker.post(TeaEvent(Homeric.ONBOARDING_LOAD_FAILURE_VIEW))
        loadFailView.isHidden = false
        webBrowser.view.isHidden = true
        loadingView.isHidden = true
    }

    func browser(_ browser: WebBrowser, didFinish navigation: WKNavigation!) {
        guard !isTimeout else { return }
        timeoutTimer?.invalidate()
        Self.logger.info("browser load finish!")
        loadFailView.isHidden = true
        webBrowser.view.isHidden = false
        loadingView.isHidden = true
    }

    func browser(_ browser: WebBrowser, didFail navigation: WKNavigation!, withError error: Error) {
        guard !isTimeout else { return }
        timeoutTimer?.invalidate()
        Self.logger.info("browser did fail with error: \(error)")
        Tracker.post(TeaEvent(Homeric.ONBOARDING_LOAD_FAILURE_VIEW))
        loadFailView.isHidden = false
        webBrowser.view.isHidden = true
        loadingView.isHidden = true
    }
}
