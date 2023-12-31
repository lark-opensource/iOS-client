//
//  BTAiExtensionGuideViewController.swift
//  SKBitable
//
//  Created by qiyongka on 2023/8/21.
//

import UIKit
import SKUIKit
import EENavigator
import SnapKit
import SKResource
import SKFoundation
import UniverseDesignCheckBox
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignInput
import UniverseDesignFont
import UniverseDesignActionPanel
import UniverseDesignToast
import UniverseDesignDialog
import UniverseDesignNotice
import LarkWebViewContainer

class BTAiExtensionGuideViewController: UIViewController {
    
    lazy var maskView = UIView()
    
    let contentView = UIView()
    
    weak var delegate: BTDataService?
    
    lazy var protocolInformation = UITextView()
    
    lazy var webViewController = UIViewController()
    
    // 用于服务条款显示的webview
    lazy var webView = LarkWebView(frame: .zero, config: webViewConfig)
    
    let webViewConfig = LarkWebViewConfigBuilder().build(
        bizType: LarkWebViewBizType("BitableAi"),
        isAutoSyncCookie: false,
        secLinkEnable: false,
        performanceTimingEnable: true,
        vConsoleEnable: false
    )
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpForContentView()
        loadAnimation()
        initWebView()
    }
    
    // 从URL返回时，将 navigationBar 隐藏
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        self.navigationController?.navigationBar.isHidden = true
    }
    
    func setUpForContentView() {
        let closeButton = UIButton()
        closeButton.setImage(UDIcon.closeSmallOutlined, for: .normal)
        contentView.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(16)
            make.top.equalToSuperview().inset(13)
            make.width.height.equalTo(24)
        }
        closeButton.addTarget(self, action: #selector(dismissGuideView), for: .touchUpInside)
        
        let headerView: UILabel = {
            let label = UILabel()
            label.font = UIFont.systemFont(ofSize: 20, weight: .regular)
            label.textAlignment = .center
            label.text = BundleI18n.SKResource.Bitable_BaseAI_Onboarding_GenerateFields_Title
            label.textColor = UDColor.B700
            return label
        }()

        contentView.addSubview(headerView)
        headerView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(60)
            make.height.equalTo(28)
            make.width.equalToSuperview()
            make.centerX.equalToSuperview()
        }
        
        let textView = UIStackView()
        contentView.addSubview(textView)
        textView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(32)
            make.height.equalTo(224)
            make.width.equalTo(340)
            make.centerX.equalToSuperview()
        }
        
        let firstText = setTextView(icon: UDIcon.editDiscriptionOutlined.ud.withTintColor(UDColor.B500),
                                    titleString: BundleI18n.SKResource.Bitable_BaseAI_Onboarding_EasySummary_SubTitle,
                                    contentString: BundleI18n.SKResource.Bitable_BaseAI_Onboarding_EasySummary_Desc)
        textView.addSubview(firstText)
        firstText.snp.makeConstraints { make in
            make.height.equalTo(48)
            make.left.right.top.equalToSuperview()
        }
        
        let secondText = setTextView(icon: UDIcon.editOutlined.ud.withTintColor(UDColor.B500),
                                     titleString: BundleI18n.SKResource.Bitable_BaseAI_Onboarding_CompleteInfo_SubTitle,
                                     contentString: BundleI18n.SKResource.Bitable_BaseAI_Onboarding_CompleteInfo_Desc)
        textView.addSubview(secondText)
        secondText.snp.makeConstraints { make in
            make.height.equalTo(48)
            make.top.equalTo(firstText.snp.bottom).offset(30)
            make.left.right.equalToSuperview()
        }
        
        let thirdText = setTextView(icon: UDIcon.markOutlined.ud.withTintColor(UDColor.B500),
                                    titleString: BundleI18n.SKResource.Bitable_BaseAI_Onboarding_Annotate_SubTitle,
                                    contentString: BundleI18n.SKResource.Bitable_BaseAI_Onboarding_Annotate_Desc)
        textView.addSubview(thirdText)
        thirdText.snp.makeConstraints { make in
            make.height.equalTo(48)
            make.top.equalTo(secondText.snp.bottom).offset(30)
            make.left.right.equalToSuperview()
        }
        
        let tryButton = UIButton(type: .system).construct { it in
            it.titleLabel?.font = UIFont.systemFont(ofSize: 16)
            it.layer.masksToBounds = true
            it.layer.cornerRadius = 8
            it.setTitleColor(UDColor.primaryOnPrimaryFill, for: .normal)
            it.setTitle(BundleI18n.SKResource.Bitable_BaseAI_Onboarding_TryNow_Button, for: .normal)
            it.backgroundColor = UDColor.primaryContentDefault
            it.addTarget(self, action: #selector(goToAiPrompt), for: .touchUpInside)
        }

        contentView.addSubview(tryButton)
        tryButton.snp.makeConstraints { make in
            make.top.equalTo(textView.snp.bottom).offset(30)
            make.height.equalTo(48)
            make.width.equalTo(344)
            make.centerX.equalToSuperview()
        }
        
        protocolInformation = UITextView().construct { it in
            guard let linkURL = URL(string: BundleI18n.SKResource.Bitable_BaseAI_Onboarding_TermsOfServiceLink) else {
                DocsLogger.btError("Error: URL Unwrapping error, can not go to target URL")
                return
            }
            
            it.backgroundColor = .clear
            it.font = UIFont.systemFont(ofSize: 12, weight: .light)
            it.textAlignment = .center

            let linkString = BundleI18n.SKResource.Bitable_BaseAI_Onboarding_TermsOfService_Text
            let style = NSMutableParagraphStyle()
            style.alignment = .center
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UDColor.textCaption,
                .font: UDFont.systemFont(ofSize: 12, weight: .regular),
                .paragraphStyle: style
            ]
            
            let string = BundleI18n.SKResource.Bitable_BaseAI_Onboarding_AgreeNote_Desc(linkString)
            let attrStr = NSMutableAttributedString(string: string, attributes: attributes)
            
            let linkRange = (string as NSString).range(of: linkString)
            if linkRange.location != NSNotFound {
                attrStr.addAttributes(
                    [.foregroundColor: UDColor.textLinkNormal,
                     .link: linkURL],
                    range: linkRange
                )
            }
            attrStr.append(NSMutableAttributedString(string: BundleI18n.SKResource.Bitable_BaseAI_Onboarding_ReadNotice_Desc, attributes: attributes))
            it.attributedText = attrStr
            it.delegate = self
        }
        // 设置其他属性
        protocolInformation.isEditable = false
        protocolInformation.isSelectable = true
        protocolInformation.dataDetectorTypes = .link
        protocolInformation.isScrollEnabled = false
        
        contentView.addSubview(protocolInformation)
        protocolInformation.snp.makeConstraints { make in
            make.top.equalTo(tryButton.snp.bottom).offset(24)
            make.height.equalTo(84)
            make.width.equalTo(343)
            make.centerX.equalToSuperview()
        }
    }

    @objc
    func loadAnimation() {
        let width = min (self.view.frame.width, 580)
        let height = self.view.frame.height
        
        maskView.frame = CGRect(x: 0, y: 0, width: width, height: height)
        maskView.backgroundColor = .clear
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissGuideView))
        maskView.addGestureRecognizer(tapGesture)
        if SKDisplay.phone {
            self.view.addSubview(maskView)
        }
        
        contentView.frame = CGRect(x: 0, y: height, width: width, height: 575)
        contentView.backgroundColor = UDColor.bgBody
        contentView.layer.cornerRadius = 10
        self.view.addSubview(contentView)
        
        
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.3) {
                self.maskView.backgroundColor = UDColor.bgMask
                if SKDisplay.phone {
                    self.contentView.frame = CGRect(x: 0, y: height - 575, width: width, height: 575)
                } else {
                    self.contentView.frame = CGRect(x: 0, y: 0, width: width, height: 575)
                }
            }
        }
    }
    
    @objc
    func dismissGuideView() {
        let width = self.view.frame.width
        let height = self.view.frame.height
        UIView.animate(withDuration: 0.2) {
            self.contentView.frame = CGRect(x: 0, y: height, width: width, height: 575)
        }
        contentView.removeFromSuperview()
        if SKDisplay.phone {
            maskView.removeFromSuperview()
        }
        DispatchQueue.main.async {
            self.dismiss(animated: false)
        }
    }
    
    @objc
    func goToAiPrompt() {
        // 通知前端关闭, 关闭OnBoarding，打开AI 配置面板
        self.delegate?.openAiPrompt()
        self.dismissGuideView()
    }
    
    func setTextView(icon: UIImage, titleString: String, contentString: String) -> UIView {
        let horizontalStack = UIStackView()
        horizontalStack.axis = .horizontal
        
        let verticalStack = UIStackView()
        verticalStack.axis = .vertical
        
        let title = UILabel()
        title.text = titleString
        title.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        title.textColor = UDColor.titleColor

        let content = UILabel()
        content.text = contentString
        content.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        content.textColor = UDColor.textCaption
        
        verticalStack.addSubview(title)
        verticalStack.addSubview(content)
        
        title.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(20)
        }
        
        content.snp.makeConstraints { make in
            make.top.equalTo(title.snp.bottom)
            make.bottom.left.right.equalToSuperview()
            make.height.equalTo(20)
        }
        
        let iconWrapperView = UIView()
        let icon = UIImageView(image: icon)
        iconWrapperView.addSubview(icon)
        icon.snp.makeConstraints { make in
            make.left.top.equalToSuperview()
            make.width.height.equalTo(20)
        }
        
        horizontalStack.addSubview(iconWrapperView)
        iconWrapperView.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            make.width.height.equalTo(40)
        }
        
        horizontalStack.addSubview(verticalStack)
        verticalStack.snp.makeConstraints { make in
            make.right.top.bottom.equalToSuperview()
            make.left.equalTo(iconWrapperView.snp.right)
        }
        return horizontalStack
    }
    
    func initWebView() {
        
        guard let linkURL = URL(string: BundleI18n.SKResource.Bitable_BaseAI_Onboarding_TermsOfServiceLink) else {
            DocsLogger.btError("Error: URL Unwrapping error, can not go to target URL")
            return
        }

        let request = URLRequest(url: linkURL)
        webView.load(request)
        webView.scrollView.isScrollEnabled = true
        
        webViewController.view.addSubview(webView)
        webView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func showWebView() {
        navigationController?.pushViewController(webViewController, animated: true)
        navigationController?.navigationBar.isHidden = false
    }
    
}

extension BTAiExtensionGuideViewController: UITextViewDelegate {
    
    // 处理链接点击,打开服务条款页面
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if SKDisplay.pad {
            /// 临时做法：初始化 VC的时候就开始加载URL，当需要打开URL时，直接在VC上 push URL
            /// 做法原因：和主端 @罗干通 沟通过，iPad端至少要到7.5版本才会有在 VC 上直接push URL的功能，我们目前只能通过这种push webView的方式打开服务条款
            self.showWebView()
            return false
        }
        
        /// iphone 走这里直接 push URL
        Navigator.shared.push(URL, from: self)
        self.navigationController?.navigationBar.isHidden = false
        
        // 返回 false，以阻止 UITextView 执行默认的操作，比如打开链接
        return false
    }
}

extension BTAiExtensionGuideViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) { }
}
