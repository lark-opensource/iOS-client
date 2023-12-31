//
//  PassportWebViewController.swift
//  LarkAccount
//
//  Created by quyiming on 2020/10/24.
//

import UIKit
import SnapKit
import LarkUIKit
import WebKit
import RxSwift

class PassportWebViewController: BaseUIViewController, WKNavigationDelegate, WKUIDelegate {

    var url: URL

    init(url: URL) {
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        view.addSubview(webView)
        webView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        view.addSubview(webProgressView)
        load()
    }

    private let disposeBag = DisposeBag()

    lazy var webView: WKWebView = {
        let wv = WKWebView(frame: .zero, configuration: .init())
        wv.navigationDelegate = self
        wv.uiDelegate = self
        wv.rx.observe(Double.self, "estimatedProgress").subscribe(onNext: { [weak self] (value) in
            if let progress = value {
                self?.webProgressView.setProgress(progress, animated: true)
            }
        }).disposed(by: disposeBag)

        wv.rx.observe(Bool.self, "canGoBack", options: .new)
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] (value) in
            if let canGoBack = value {
                self?.checkAndUpdateUrl()
                self?.checkAndUpdateLeftItems()
            }

        }).disposed(by: disposeBag)
        wv.rx.observe(String.self, "title", options: .new)
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] (value) in
            if let title = value {
                self?.update(title: title)
            }
        }).disposed(by: disposeBag)
        return wv
    }()

    private func checkAndUpdateUrl() {
        if let url = webView.url {
            self.url = url
        }
    }

    // MARK: load

    private lazy var webProgressView: WebViewProgressView = {
       let pv = WebViewProgressView()
        pv.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 2)
        pv.progressBarColor = UIColor.ud.primaryContentDefault.ud.lighter(by: 30)
        pv.autoresizingMask = .flexibleWidth
        return pv
    }()

    private lazy var failView: UIView = {
        let view = LoadFailPlaceholderView(frame: CGRect.zero)
        view.backgroundColor = UIColor.ud.bgLogin

        let tap = UITapGestureRecognizer()
        tap.rx.event.asDriver().drive(onNext: { [weak self] _ in self?.failViewTap() })
            .disposed(by: disposeBag)
        view.addGestureRecognizer(tap)

        return view
    }()

    private func load() {
        removeFailView()
        webView.load(URLRequest(url: url))
        self.removeFailView()
    }

    private func showFailView() {
        view.addSubview(failView)
        failView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    private func removeFailView() {
        failView.removeFromSuperview()
    }

    private func failViewTap() {
        load()
    }

    private func handleError(_ error: Error) {
        showFailView()
        webProgressView.setProgress(0, animated: true)
    }

    // MARK: left items

    private lazy var backItem: UIBarButtonItem = {
        let backItem = LKBarButtonItem(image: LarkUIKit.Resources.navigation_back_light)
        backItem.button.addTarget(
            self,
            action: #selector(backItemTapped),
            for: .touchUpInside
        )
        return backItem
    }()

    private lazy var closeItem: UIBarButtonItem = {
        let closeItem = LKBarButtonItem(image: BundleResources.UDIconResources.closeOutlined)
        closeItem.button.addTarget(
            self,
            action: #selector(closeItemTapped),
            for: .touchUpInside
        )
        return closeItem
    }()

    private func checkAndUpdateLeftItems() {
        var items: [UIBarButtonItem] = []
        if needShowBackItem() {
            items.append(backItem)
        }

        if needShowCloseItem() {
            items.append(closeItem)
        }
        if items.isEmpty {
            // 添加空占位 item, iPad 上会出现 title 偏移问题
            items.append(UIBarButtonItem(customView: UIView()))
        }
        self.navigationItem.setLeftBarButtonItems(
            items,
            animated: false
        )
    }

    private func needShowBackItem() -> Bool {
        if webView.canGoBack { return true }
        return hasBackPage
    }
    private func needShowCloseItem() -> Bool {
        return webView.canGoBack || isRootOfPresentedNavigation()
    }

    private func isRootOfPresentedNavigation() -> Bool {
        let root = self.navigationController?.viewControllers.first
        return root == self && self.presentingViewController != nil
    }

    @objc
    override func backItemTapped() {
        if webView.canGoBack {
            webView.goBack()
        } else {
            super.backItemTapped()
        }
    }

    @objc
    private func closeItemTapped() {
        if isRootOfPresentedNavigation() {
            self.dismiss(animated: true) {
                self.closeCallback?()
            }
        } else {
            self.closeCallback?()
            self.navigationController?.popViewController(animated: true)
        }
    }

    // MARK: title

    private func update(title: String?) {
        self.titleString = URL.decodeURI(string: title ?? "")
    }

    // MARK: WKNavigationDelegate

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handleError(error)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handleError(error)
    }

    // MARK: WKUIDelegate
    // this handles target=_blank links by opening them in the same view
    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
}
