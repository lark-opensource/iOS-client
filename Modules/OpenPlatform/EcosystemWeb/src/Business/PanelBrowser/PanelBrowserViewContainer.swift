//
//  PanelBrowserViewContainer.swift
//  EcosystemWeb
//
//  Created by jiangzhongping on 2022/9/8.
//

import LarkUIKit
import LKCommonsLogging
import WebBrowser
import Swinject
import LarkContainer
import UniverseDesignProgressView
import LarkSetting

public final class PanelBrowserViewContainer: BaseUIViewController, UIGestureRecognizerDelegate {
        
    static let logger = Logger.log(PanelBrowserViewContainer.self, category: "PanelBrowserViewContainer")

    private var viewModel: PanelBrowserViewModel?
    private var panelStyle = PanelBrowserStyle.high
            
    private var containerHeight = 0.0
    private var contentViewController: UIViewController?
    private var rightGestureOffsetY = 0.0
    private var currentProgress = 0.0
    
    private var titleObservation: NSKeyValueObservation?
    private var canGoBackObservation: NSKeyValueObservation?
    private var estimatedProgressObservation: NSKeyValueObservation?
    
    private let transitionDelegate = PanelBrowserTransitionDelegate()
    
    private let resolver: Resolver
    
    private var handler: PanelBrowserServiceProtocol?
    
    private lazy var customNavigationBar: PanelBrowserNavigationBar = {
        let navigationBar = PanelBrowserNavigationBar()
        navigationBar.backBtn.addTarget(self, action: #selector(goBackAction), for: .touchUpInside)
        navigationBar.closeBtn.addTarget(self, action: #selector(closeAction), for: .touchUpInside)
        return navigationBar
    }()
    
    public lazy var progressView: UDProgressView = {
        let progressView = UDProgressView()
        progressView.isHidden = true
        return progressView
    }()

    private lazy var rightSlidePanGesture: UIPanGestureRecognizer = {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleRightSlideAction(gesture:)))
        panGesture.maximumNumberOfTouches = 1
        panGesture.delegate = self
        return panGesture
    }()
    
    private lazy var maskBgView: UIView = {
        let maskBgView = UIView(frame: UIScreen.main.bounds)
        maskBgView.backgroundColor = UIColor.ud.bgMask
        let tapGesture = UITapGestureRecognizer(target: self, action:  #selector(closeAction))
        maskBgView.addGestureRecognizer(tapGesture)
        maskBgView.isHidden = true
        return maskBgView
    }()
    
    private lazy var aboutInfoView: PanelBrowserAppInfoView = {
        let aboutInfoView = PanelBrowserAppInfoView()
        aboutInfoView.isHidden = true
        let tapGes = UITapGestureRecognizer(target: self, action: #selector(onAboutInfoViewClicked))
        aboutInfoView.addGestureRecognizer(tapGes)
        return aboutInfoView
    }()
    
    private lazy var mainContentView: UIView = {
        let mainContentView = UIView()
        mainContentView.backgroundColor = UIColor.clear
        return mainContentView
    }()
            
    public init(contentViewController: UIViewController,
         style: PanelBrowserStyle,
         appId: String = "",
         resolver: Resolver) {
        self.resolver = resolver
        super.init(nibName: nil, bundle: nil)
        self.view.backgroundColor = UIColor.clear
        self.modalPresentationStyle = .overFullScreen
        self.view.addGestureRecognizer(self.rightSlidePanGesture)
        self.isNavigationBarHidden = true
        self.panelStyle = style
        self.containerHeight = style.styleHeight
        self.handler = try? self.resolver.resolve(assert: PanelBrowserServiceProtocol.self)
        if (!appId.isEmpty) { //appId不为空才创建viewModel
            self.viewModel = PanelBrowserViewModel(appId: appId, resolver: resolver, delegte: self)
        }
        self.setupViews(contentViewController)
        self.setupContentViewController(contentViewController)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    //仅支持竖屏&不旋转
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    public override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }
    
    public override var shouldAutorotate: Bool {
        return false
    }

    private func setupViews(_ contentViewController: UIViewController) {
        
        self.view.addSubview(maskBgView)
        self.view.addSubview(self.mainContentView)
        self.mainContentView.addSubview(self.customNavigationBar)
        self.mainContentView.addSubview(self.progressView)
        self.view.addSubview(self.aboutInfoView)

        let aboutMaxWidth = UIScreen.main.bounds.size.width <= 320 ? 288 : 312
        self.aboutInfoView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.bottom.equalTo(self.mainContentView.snp.top).offset(-6)
            make.height.equalTo(28)
            make.width.lessThanOrEqualTo(aboutMaxWidth)
        }
        
        self.customNavigationBar.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(48)
        }
    
        self.progressView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(self.customNavigationBar.snp.bottom)
        }
        self.updateBackgroundColor()
        self.setupMainContentView()
    }

    private func setupMainContentView() {
        
        self.mainContentView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(UIScreen.main.bounds.size.height - self.containerHeight)
            make.leading.trailing.bottom.equalToSuperview()
        }
    
        let contentSize = CGSize(width: UIScreen.main.bounds.size.width, height: self.containerHeight)
        let bounds = CGRect(x: 0, y: 0, width: contentSize.width, height: contentSize.height)
        //特殊处理
        let maskPath = UIBezierPath(roundedRect:bounds, byRoundingCorners:[.topLeft, .topRight], cornerRadii: CGSize(width: 8.0, height: 8.0));
        let maskLayer = CAShapeLayer()
        maskLayer.path = maskPath.cgPath
        self.mainContentView.layer.mask = maskLayer
    }
    
    public func showMaskBgView(_ show: Bool) {
        self.maskBgView.isHidden = !show
    }
    
    private func setupContentViewController(_ contentViewController: UIViewController) {
        self.contentViewController = contentViewController
        self.addChild(contentViewController)
        self.mainContentView.addSubview(contentViewController.view)
        contentViewController.view.snp.makeConstraints { make in
            make.top.equalTo(self.customNavigationBar.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        contentViewController.didMove(toParent: self)
        
        if let browser = contentViewController as? WebBrowser {
            browser.viewMode = "panel"
            browser.viewRatio = self.panelStyle.rawValue
            titleObservation = browser.webview.observe(
                    \.title,
                    options: [.old, .new],
                    changeHandler: { [weak self] (webView, change) in
                    guard let `self` = self else { return }
                    Self.logger.info("webview title changed from {\(change.oldValue)} to {\(change.newValue)}")
                    var title = ""
                    if let newTitle = change.newValue, let t = newTitle {
                        title = t
                    }
                    self.customNavigationBar.setNavigationTitle(title)
                }
            )

            canGoBackObservation = browser.webview.observe(
                    \.canGoBack,
                    options: [.old, .new],
                    changeHandler: { [weak self] (webView, change) in
                    guard let `self` = self else { return }
                    Self.logger.info("canGoBack state change from \(change.oldValue) to \(change.newValue)")
                    self.customNavigationBar.showBackBtn(change.newValue ?? false)
                }
            )
            
            estimatedProgressObservation = browser.webview.observe(
                    \.estimatedProgress,
                    options: [.old, .new]
                ) { [weak self] (webView, change) in
                    guard let `self` = self, let progress = change.newValue else { return }
                    Self.logger.info("estimated progress changed from \(change.oldValue) to \(progress)")
                    self.changeProgressView(with: CGFloat(progress))
                }
        }
    }
    
    @objc
    private func onAboutInfoViewClicked() {
        let appId = self.viewModel?.appId ?? ""
        if !appId.isEmpty {
            self.handler?.openAboutH5Page(appId: appId)
        } else {
            Self.logger.info("aboutInfo clicked error, because appId is empty")
        }
    }
    
    @objc
    private func closeAction() {
        self.hide(completion: nil)
    }
    
    @objc
    private func handleRightSlideAction(gesture: UIPanGestureRecognizer) {
        var progress = gesture.translation(in: self.view).x / self.view.bounds.size.width
        progress = min(1.0, max(0.0, progress))
        Self.logger.info("handle right slide, gesture.state:\(gesture.state), progress:\(progress)")
        switch(gesture.state) {
        case .began:
            self.rightGestureOffsetY = 0
        case .changed:
            let offsetY = UIScreen.main.bounds.size.height * progress
            self.mainContentView.snp.updateConstraints { make in
                make.top.equalToSuperview().offset(UIScreen.main.bounds.size.height - self.containerHeight + offsetY)
            }
            self.rightGestureOffsetY = offsetY
        case .ended, .cancelled:
            let velocity = gesture.velocity(in: self.view).x
            if progress > 0.25 || velocity >= 80 {
                self.hide()
            } else {
                self.mainContentView.snp.updateConstraints { make in
                    make.top.equalToSuperview().offset(UIScreen.main.bounds.size.height - self.containerHeight)
                }
                self.rightGestureOffsetY = 0
            }
        case .possible, .failed: fallthrough
        @unknown default:
            break
        }
    }
    
    @objc
    private func goBackAction() {
        if let browser = contentViewController as? WebBrowser {
            browser.webview.goBack()
        }
    }
    
    // 监听键盘出现，调整偏移
    @objc private func keyboardWillShow(notification: Notification) {
        if self.panelStyle != PanelBrowserStyle.low {
            return
        }
        //只处理StyleConst.low的情形
        guard let keyboardFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as AnyObject).cgRectValue else {
            return
        }
        
        let offsetY = min(UIScreen.main.bounds.height - keyboardFrame.height, ceil(UIScreen.main.bounds.height * 0.14))
        UIView.animate(withDuration: 0.25) {
            self.mainContentView.snp.updateConstraints { make in
                make.top.equalToSuperview().offset(offsetY)
            }
            self.view.layoutIfNeeded()
        }
    }
    /// 监听键盘收起
    @objc private func keyboardWillHide(notification: Notification) {
        if self.panelStyle != PanelBrowserStyle.low {
            return
        }
        
        UIView.animate(withDuration: 0.25) {
            self.mainContentView.snp.updateConstraints { make in
                make.top.equalToSuperview().offset(UIScreen.main.bounds.size.height - self.containerHeight)
            }
            self.view.layoutIfNeeded()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func changeProgressView(with value: CGFloat) {
        var newValue = value
        if self.enableStrategyUpdate() {
            if (newValue < self.currentProgress) {
                newValue = self.currentProgress //新值小于currentProgress，继续使用currentProgress
            } else {
                self.currentProgress = newValue //新值大于等于currentProgress，更新currentProgress
            }
        }
        progressView.setProgress(newValue, animated: false)
        if newValue > 0 && newValue < 1 {
            if progressView.isHidden {
                progressView.isHidden = false
            }
            return
        }
        let hidden = newValue >= 1
        progressView.isHidden = hidden
    }
    
    private func enableStrategyUpdate() -> Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.webbrowser.process.strategyupdate.enable"))// user:global
    }
        
    private func updateBackgroundColor() {
        self.mainContentView.backgroundColor = UIColor.white
        self.view.backgroundColor = UIColor.clear
    }
    
    public func show(from viewController: UIViewController?, completion: (() -> Void)? = nil) {
        guard let fromViewController = viewController else {
            return
        }
        
        let panelBrowserNavVC = LkNavigationController(rootViewController:self)
        panelBrowserNavVC.modalPresentationStyle = .custom
        panelBrowserNavVC.modalPresentationCapturesStatusBarAppearance = true;
        panelBrowserNavVC.transitioningDelegate = self.transitionDelegate
        if (self.enableStrategyUpdate()) {
            Self.logger.info("webview ready to load URL, fake progress changed to 0.5")
            self.progressView.layoutIfNeeded()
            self.changeProgressView(with: 0.5)
        }
        fromViewController.present(panelBrowserNavVC, animated: true, completion: completion)
    }
    
    public func hide(completion: (() -> Void)? = nil) {
        self.dismiss(animated: true, completion: completion)
    }
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        ///处理webview侧滑返回和页面右滑返回的冲突
        if (gestureRecognizer == self.rightSlidePanGesture) {
            if let browser = self.contentViewController as? WebBrowser, browser.webview.canGoBack {
                return false
            }
            return true
        }
        return true
    }
}

extension PanelBrowserViewContainer: PanelBrowserViewModelDelegate {
    func updateAppInfo(appInfo: PanelBrowserAppInfo?) {
        if let theAppInfo = appInfo, theAppInfo.appName.count > 0, theAppInfo.appAvatar.count > 0 {
            self.aboutInfoView.isHidden = false
            self.aboutInfoView.updateViews(appName: theAppInfo.appName, appIconURLString: theAppInfo.appAvatar, appId: theAppInfo.appId)
        } else {
            self.aboutInfoView.isHidden = true
        }
    }
}

