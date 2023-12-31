//
//  MailSignatureSettingViewController.swift
//  MailSDK
//
//  Created by majx on 2020/1/9.
//

import Foundation
import LarkUIKit
import EENavigator
import RxSwift
import WebKit
import FigmaKit

class MailSignatureSettingViewController: MailBaseViewController,
                                          MailSignatureSettingOptionViewDelegate,
                                          MailSignatureEditViewControllerDelegate,
                                          WKNavigationDelegate, WKScriptMessageHandler {
    private var optionViews: [MailSignatureSettingOptionView]?
    private weak var viewModel: MailSettingViewModel?
    private var accountId: String
    private var accountSetting: MailAccountSetting?
    private let disposeBag = DisposeBag()
    private let accountContext: MailAccountContext
    private lazy var weakSelf: WeakWKScriptMessageHandler = {
        return WeakWKScriptMessageHandler(self)
    }()

    enum SignatureOption {
        case none
        case mobile
        case pc
    }

    init(viewModel: MailSettingViewModel?, accountContext: MailAccountContext) {
        self.viewModel = viewModel
        self.accountContext = accountContext
        self.accountId = accountContext.accountID
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
        setupViews()
        setupViewModel()
    }

    func setupViewModel() {
        if viewModel == nil {
            viewModel = MailSettingViewModel(accountContext: accountContext)
        } else {
            reloadData()
        }
        self.viewModel?.refreshDriver.drive(onNext: { [weak self] () in
            guard let `self` = self else { return }
            self.reloadData()
        }).disposed(by: disposeBag)
    }

    override var navigationBarTintColor: UIColor {
        return UIColor.ud.bgFloatBase
    }

    func setupViews() {
        self.title = BundleI18n.MailSDK.Mail_Setting_EmailSignatureMobile
        view.backgroundColor = UIColor.ud.bgFloatBase
        view.addSubview(scrollView)
        scrollView.backgroundColor = UIColor.ud.bgFloatBase
        scrollView.bounces = true
        scrollView.alwaysBounceVertical = true
        scrollView.contentSize = CGSize(width: view.frame.size.width, height: view.frame.size.height)
        scrollView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.width.greaterThanOrEqualTo(view.snp.width)
            make.height.greaterThanOrEqualTo(view.snp.height)
        }
        optionViews = [noSignatureOptionView,
                       mobileSignatureOptionView,
                       pcSignatureOptionView]
        var prevOptionView: UIView?
        optionViews?.forEach({ [weak self](optionView) in
            guard let `self` = self else { return }
            contentView.addSubview(optionView)
            optionView.snp.makeConstraints { (make) in
                make.left.equalTo(16)
                make.right.equalTo(-16)
                make.top.equalTo(prevOptionView?.snp.bottom ?? 8)
                if prevOptionView == nil {
                    make.height.equalTo(48)
                }
            }
            let sep = UIView()
            sep.backgroundColor = UIColor.ud.lineDividerDefault
            if let optionView = prevOptionView {
                optionView.addSubview(sep)
                sep.snp.makeConstraints { make in
                    make.bottom.right.equalToSuperview()
                    make.left.equalTo(48)
                    make.height.equalTo(0.5)
                }
            }
            prevOptionView = optionView
        })
        if let pcSignaturePreview = pcSignatureOptionView.getConfig().detail as? MailPCSignaturePreview {
            pcSignaturePreview.webView.navigationDelegate = self
            pcSignaturePreview.webView.configuration.userContentController.add(weakSelf, name: "invoke")
        }
    }

    @objc
    func onClickPCSignature() {
        guard let pcSignature = self.accountSetting?.setting.pcSignature.text,
            !pcSignature.isEmpty else {
                return
        }
        let editVC = MailSignaturePreviewViewController(htmlStr: pcSignature, accountContext: accountContext)
        let editNav = LkNavigationController(rootViewController: editVC)
        editNav.navigationBar.isTranslucent = false
        editNav.navigationBar.shadowImage = UIImage()
        editNav.modalPresentationStyle = .fullScreen
        if #available(iOS 13.0, *) {
            editNav.modalPresentationStyle = .overCurrentContext
            navigator?.present(editNav, from: self)
        } else {
            navigator?.present(editNav, from: self)
        }
    }

    func reloadData() {
        /// update signature detail preview
        /// pc signature
        DispatchQueue.main.async {
            self.accountSetting = self.viewModel?.getAccountSetting(of: self.accountId)
            let setting = self.accountSetting?.setting

            if setting?.hasPcSignature ?? false {
                if let pcSignature = setting?.pcSignature {
                    self.pcSignatureOptionView.showPreview(true)
                    self.pcSignatureOptionView.update(signature: pcSignature.text)
                } else {
                    self.pcSignatureOptionView.showPreview(false)
                    self.pcSignatureOptionView.update(signature: "")
                }
            } else {
                self.pcSignatureOptionView.showPreview(false)
                self.pcSignatureOptionView.update(signature: "")
            }

            /// mobile signature
            if let signature = setting?.signature {
                self.mobileSignatureOptionView.update(signature: signature.text)
            }

            /// update selected option status
            if setting?.mobileUsePcSignature ?? false {
                self.updateSignatureOption(.pc)
            } else if setting?.signature.enabled ?? false {
                self.updateSignatureOption(.mobile)
            } else {
                self.updateSignatureOption(.none)
            }

            self.view.layoutIfNeeded()
        }
    }

    func updateSignatureOption(_ signature: SignatureOption) {
        pcSignatureOptionView.selected = signature == .pc
        mobileSignatureOptionView.selected = signature == .mobile
        noSignatureOptionView.selected = signature == .none
    }

    lazy var noSignatureOptionView: MailSignatureSettingOptionView = {
        let config = MailSignatureSettingOptionConfig(title: BundleI18n.MailSDK.Mail_Signature_OptionDisable, detail: nil)
        let optionView = MailSignatureSettingOptionView(config: config)
        optionView.delegate = self
        optionView.cellType = .none
        let rounded = UIBezierPath(roundedRect: CGRect(origin: .zero, size: CGSize(width: view.bounds.width - 32, height: 48)),
                                   byRoundingCorners: [.topLeft, .topRight],
                                   cornerRadii: CGSize(width: 10.0, height: 10.0))
        let shaper = CAShapeLayer()
        shaper.path = rounded.cgPath
        optionView.layer.mask = shaper
        return optionView
    }()

    lazy var mobileSignatureOptionView: MailSignatureSettingOptionView = {
        let detail = MailMobileSignaturePreview()
        detail.onClickBlock = { [weak self] in
            guard let `self` = self else { return }
            let editVC = MailSignatureEditViewController(viewModel: self.viewModel, accountContext: self.accountContext)
            let editNav = LkNavigationController(rootViewController: editVC)
            editNav.navigationBar.isTranslucent = false
            editNav.navigationBar.shadowImage = UIImage()
            editVC.delegate = self
            editNav.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen
            self.navigator?.present(editNav, from: self)
        }
        let config = MailSignatureSettingOptionConfig(title: BundleI18n.MailSDK.Mail_Signature_OptionUseMobile, detail: detail)
        let optionView = MailSignatureSettingOptionView(config: config)
        optionView.delegate = self
        optionView.cellType = .mobile
        return optionView
    }()

    lazy var pcSignatureOptionView: MailSignatureSettingOptionView = {
        let detail = MailPCSignaturePreview(provider: accountContext)
        let config = MailSignatureSettingOptionConfig(title: BundleI18n.MailSDK.Mail_Signature_OptionUsePC, detail: detail)
        let optionView = MailSignatureSettingOptionView(config: config)
        optionView.delegate = self
        optionView.cellType = .pc
        return optionView
    }()

    lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()

    lazy var contentView: UIView = {
        let view = UIView()
        return view
    }()

    // MARK: - MailSignatureSettingOptionViewDelegate {
    func didClickOption(view: MailSignatureSettingOptionView) {
        optionViews?.forEach({ (optionView) in
            optionView.selected = optionView == view
        })
        self.viewModel?.updateSignatureSwitch(view.cellType != .none, self.accountId)
        accountSetting?.updateSettings(.signature(.enable(!noSignatureOptionView.selected)),
                                       .signature(.mobileUsePcSignature(pcSignatureOptionView.selected)))
    }

    // MARK: - MailSignatureEditViewControllerDelegate {
    func updateSigText(text: String) {
        self.mobileSignatureOptionView.update(signature: text)
    }
    // MARK: - WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let script = MailSignaturePreviewScript.getContentHeight
        webView.evaluateJavaScript(script) { [weak self](value, error) in
            guard let `self` = self else { return }
            var webContentHeight: CGFloat = 0.0
            if let strValue = value as? String,
                let floatValue = NumberFormatter().number(from: strValue)?.floatValue {
                webContentHeight = CGFloat(floatValue)
            } else if let floatValue = value as? CGFloat {
                webContentHeight = floatValue
            }
            var contentHeight: CGFloat = 0
            if self.pcSignatureOptionView.config.showDetail {
                let height = webContentHeight
                let frame = webView.convert(webView.frame, to: self.view)
                let bottomSpace = self.view.frame.height - frame.origin.y - 16
                self.pcSignatureOptionView.update(newHeight: min(height, bottomSpace))
                let scrollContentHeight = max(frame.minY + bottomSpace, self.view.frame.size.height - Display.bottomSafeAreaHeight)
                self.scrollView.contentSize = CGSize(width: self.view.frame.size.width, height: scrollContentHeight)
                contentHeight = scrollContentHeight
            } else {
                let frame = self.pcSignatureOptionView.convert(self.pcSignatureOptionView.frame, to: self.view)
                let scrollContentHeight = max(frame.maxY, self.view.frame.size.height - 16)
                self.scrollView.contentSize = CGSize(width: self.view.frame.size.width, height: scrollContentHeight)
                contentHeight = scrollContentHeight
            }
            self.contentView.snp.remakeConstraints { (make) in
                make.top.equalToSuperview()
                make.left.equalToSuperview()
                make.width.equalToSuperview()
                make.height.greaterThanOrEqualTo(contentHeight)
            }
        }
    }
    // MARK: - WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController,
                                      didReceive message: WKScriptMessage) {
        guard let params = message.body as? [String: Any] else { return }
        guard let method = params["method"] as? String,
            params["args"] as? [String: Any] != nil else {
                return
        }
        if method == "clickSignature" {
            onClickPCSignature()
        }
    }
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        webView.reload()
    }
}
