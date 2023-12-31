
//  LarkLiveViewController.swift
//  ByteView
//
//  Created by tuwenbo on 2021/1/24.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkUIKit
import LarkWebViewContainer
import EENavigator
import RxSwift
import MinutesFoundation
import LarkSnsShare
import UniverseDesignIcon
import UniverseDesignColor

class LarkLiveViewController: BaseUIViewController {
    let logger = Logger.live

    let bridgeName = "byteview_live_bridge"
    let disposeBag = DisposeBag()

    // 保存 observer，因为 observer 一旦被回收就无法接收到消息了，
    // 所以在这里保存，把 observer 的生命周期跟 viewcontroller 绑定
    var observers = [NSKeyValueObservation]()

    /// 初始化时设置的URL
    let firstLoadURL: URL

    /// 是否是从直播小窗返回创建的
    let isFloatToPage: Bool

    var currentMode = LiveMode.portrait

    private var webViewContainer: LiveWebViewContainer

    var webView: LarkWebView {
        return webViewContainer.webView
    }

    var url: URL {
        webViewContainer.url
    }

    var navigationBarIsHidden: Bool?
    
    // TODO hex color
   var colorDict: [ThemeColor: NavigationBarStyle] = [ThemeColor.default: .default, ThemeColor.light: .custom(UIColor.white, tintColor: UDColor.rgb(0x1F2329)), ThemeColor.dark: .custom(UDColor.rgb(0x1A1A1A), tintColor: UDColor.rgb(0xEBEBEB))]
    
    override var navigationBarStyle: NavigationBarStyle {
        return .default
    }
    
    private var liveID: String?

    init(url: URL, webViewContainer: LiveWebViewContainer, fromLink: Bool = true) {
        firstLoadURL = url
        self.webViewContainer = webViewContainer
        isFloatToPage = !fromLink

        super.init(nibName: nil, bundle: nil)

        self.webViewContainer.liveVC = self

        generateLiveID()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        logger.info("live view controller deinit")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        initBarButton()
        setupView()
        setTitle()
        setupTitleObservable()
        configNavigationBarStyle()
    }

    /// 当从小窗回来时,需要上报埋点
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationBarIsHidden = navigationController?.navigationBar.isHidden
        navigationController?.navigationBar.isHidden = false

        if webViewContainer.isLivingPlaying() && isFloatToPage {
            currentMode = UIApplication.shared.statusBarOrientation.isLandscape ? .landscape : .portrait
            LiveNativeTracks.trackModeChangeInLive(mode: currentMode.rawValue)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let navigationBarIsHidden = navigationBarIsHidden {
            navigationController?.navigationBar.isHidden = navigationBarIsHidden
        }
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        if parent == nil {
            checkPlayStatus()
        }
    }

    /// 当interface orientation变化时,需要上报埋点
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { [weak self] (_) in
            guard let self = self else { return }

            if self.webViewContainer.isLivingPlaying() {
                let newMode: LiveMode = UIApplication.shared.statusBarOrientation.isLandscape ? .landscape : .portrait
                if self.currentMode != newMode {
                    self.currentMode = newMode
                    LiveNativeTracks.trackModeChangeInLive(mode: self.currentMode.rawValue)
                }
            }
        }
    }

    func setupView() {
        self.view.addSubview(webViewContainer)
        webViewContainer.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    /// 判断当前是否有直播
    func isLivingInPage() -> Bool {
        return webViewContainer.isLivingInPage()
    }

    override func backItemTapped() {
        if UIApplication.shared.statusBarOrientation.isLandscape {
            rotateCurrentViewController()
        } else {
            if webViewContainer.webView.canGoBack {
                webViewContainer.webView.goBack()
            } else {
                super.backItemTapped()
            }
        }
    }

    private func rotateCurrentViewController(with orientation: UIInterfaceOrientation = .portrait) {
        UIDevice.current.setValue(orientation.rawValue, forKey: "orientation")
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }

    func initBarButton() {
        let moreButtonItem = LKBarButtonItem(image: UDIcon.moreOutlined)
        moreButtonItem.button.rx.tap.asDriver().drive(onNext: { [weak self] _ in
            guard let self = self else { return }
            self.logger.info("more button tapped")
            LiveNativeTracks.trackClickMore(isPortrait: UIApplication.shared.statusBarOrientation.isPortrait, isLiving: self.isLivingInPage())
            self.showWebExtension()
        }).disposed(by: disposeBag)
        navigationItem.setRightBarButton(moreButtonItem, animated: true)
    }

    func showWebExtension() {
        let items: [WebExtensionItem] = [
            WebExtensionItem(name: BundleI18n.LarkLive.Common_G_FromView_ShareToChat, image: BundleResources.LarkLive.webSendChat, clickCallback: { [weak self] in
                self?.logger.info("menu item click share")
                LiveNativeTracks.trackClickShare(isPortrait: UIApplication.shared.statusBarOrientation.isPortrait, isLiving: self?.isLivingInPage() ?? false )
                    self?.shareText(self?.url.absoluteString ?? "")
            }),
            WebExtensionItem(name: BundleI18n.LarkLive.Common_G_FromView_CopyLink, image: BundleResources.LarkLive.webCopyLink, clickCallback: { [weak self] in
                self?.logger.info("menu item click copy")
                LiveNativeTracks.trackClickCopyLink(isPortrait: UIApplication.shared.statusBarOrientation.isPortrait, isLiving: self?.isLivingInPage() ?? false)
                UIPasteboard.general.string = self?.url.absoluteString
                LiveToast.showSuccess(with: BundleI18n.LarkLive.Common_G_FromView_LinkCopied)
            }),
            WebExtensionItem(name: BundleI18n.LarkLive.Common_G_FromView_Refresh, image: BundleResources.LarkLive.webRefresh, clickCallback: { [weak self] in
                guard let self = self else { return }
                self.logger.info("menu item click refresh")

                LiveNativeTracks.trackClickReload(isPortrait: UIApplication.shared.statusBarOrientation.isPortrait, isLiving: self.isLivingInPage())
                
                self.configNavigationBarStyle()
                self.webView.load(URLRequest(url: self.url))
            })
        ]
        let webExtensionController = WebExtensionController(items: items)
        webExtensionController.modalPresentationStyle = .overCurrentContext
        present(webExtensionController, animated: false, completion: {
            webExtensionController.show()
        })
    }

    func setTitle() {
        let observer = webView.observe(\.title, options: .new) {[weak self] webview, _ in
            guard let self = self else { return }
            let title = webview.title ?? ""
            self.setTitle(title)
        }
        observers.append(observer)
    }

    /// 导航栏title跟着document.title走
    private func setupTitleObservable() {
        self.titleString = LarkLiveManager.shared.title ?? ""

        //  一定要使用 WKWebView.title 否则会崩溃
        let titlePath = NSExpression(forKeyPath: \WKWebView.title).keyPath
        webView
            .rx
            .observe(
                String.self,
                titlePath,
                options: .new
            )
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] value in
                self?.logger.info("webview title changed with {\(value)}")
                //  和chrome，Safari，微信 完全对齐，不做额外处理，完全按照业务方的名称来
                self?.setTitle(value ?? "")
            })
            .disposed(by: disposeBag)
    }

    private func setTitle(_ title: String) {
        self.titleString = title
        self.logger.info("got webview title: \(title)")

        LarkLiveManager.shared.title = title
    }

    private func checkPlayStatus() {
        webViewContainer.checkPlayStatus()
    }

    private func shareText(_ text: String) {
        if text.isEmpty {
            return
        }

        let from = Navigator.shared.mainSceneTopMost
        if #available(iOS 13.0, *) {
            LarkLiveManager.shared.pushOrPresentShareContentBody(text: text, from: from, style: self.overrideUserInterfaceStyle.rawValue)
        } else {
            LarkLiveManager.shared.pushOrPresentShareContentBody(text: text, from: from, style: 0)
        }
    }
    
    func convert36HexStrToDecimal(hexstring: String) -> String? {
        let str36 = hexstring
        if let decimal: Int = Int(str36, radix: 36) {
            let stringDecimal = String(decimal, radix: 10)
            return stringDecimal
        }
        return nil
    }

    func generateLiveID() {
        let components = self.url.pathComponents
        if components.count >= 3 {
            let liveId36 = components[2]
            if let liveId = convert36HexStrToDecimal(hexstring: liveId36), liveId.isEmpty == false {
                self.liveID = liveId
                self.webViewContainer.realLiveId = liveId
            }
        } else {
           logger.info("LarkLiveViewController live id string error")
        }
    }

    func configNavigationBarStyle() {
//        guard let url = self.url.host , let liveId = self.liveID else { return }
//        LiveNetService.getThemeColor(host: "https://\(url)" , liveID: liveId) { [weak self] result in
//            guard let self = self else { return }
//            switch result {
//            case .success(let theme):
//                if let value = theme?.themeColor, let style = self.colorDict[value] {
//                    (self.navigationController as? LkNavigationController)?.update(style: style)
//                } else {
//                    (self.navigationController as? LkNavigationController)?.update(style: .default)
//                }
//            case .error(let error):
//                print("\(error)")
//            }
//        }
    }
}

