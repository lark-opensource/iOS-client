//
//  MailSignaturePreviewLabel.swift
//  MailSDK
//
//  Created by majx on 2020/1/9.
//

import Foundation
import LarkUIKit
import WebKit
import UniverseDesignIcon
import UniverseDesignFont

protocol MailSignatureSettingDetail {
    var selected: Bool { get set }
    var signature: String { get set }
    var contentView: UIView { get }
    var contentHeight: CGFloat { get }
    func updateHeight(newHeight: CGFloat) -> CGFloat
}

extension MailSignatureSettingDetail {
    var selected: Bool { return false }
    var contentView: UIView { return UIView() }
    var contentHeight: CGFloat { return 0 }

    func separatorOn(_ view: UIView) -> UIView {
        let tag = 999
        if let separator = view.viewWithTag(tag) {
            return separator
        } else {
            let separator = UIView()
            separator.backgroundColor = .clear // UIColor.ud.lineDividerDefault
            separator.tag = tag
            separator.isHidden = true
            view.addSubview(separator)
            separator.snp.makeConstraints { (make) in
                make.left.top.equalTo(0)
                make.right.equalToSuperview().offset(16)
                make.height.equalTo(1.0 / UIScreen.main.scale)
            }
            return separator
        }
    }

    func updateHeight(newHeight: CGFloat) -> CGFloat {
        return contentHeight
    }
}

// MARK: - MobileSignaturePreview
class MailMobileSignaturePreview: MailSignatureSettingDetail {
    var onClickBlock: (() -> Void)?

    var selected: Bool = false

    var signature: String = "" {
        didSet {
            textLabel.text = _signatureText
        }
    }

    var contentView: UIView {
        return _contentView
    }

    var contentHeight: CGFloat {
        let minHeight: CGFloat = 32
        let newSize = textLabel.sizeThatFits(CGSize(width: _contentView.bounds.width - 24,
                                                   height: CGFloat.greatestFiniteMagnitude))
        return max(newSize.height, minHeight)
    }

    private var _signatureText: String {
        return signature.isEmpty ? BundleI18n.MailSDK.Mail_Signature_Null : signature
    }

    lazy var _contentView: UIView = {
        let view = UIView()
        view.addSubview(textLabel)
        view.addSubview(editIcon)
        textLabel.snp.makeConstraints { (make) in
            make.left.top.equalTo(0)
            make.width.lessThanOrEqualToSuperview().offset(-24)
            make.centerY.equalToSuperview()
        }
        editIcon.snp.makeConstraints { (make) in
            make.right.equalTo(0)
            make.width.height.equalTo(16)
            make.centerY.equalTo(textLabel)
        }
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(onClick))
        view.addGestureRecognizer(tapRecognizer)
        return view
    }()

    @objc
    func onClick() {
        onClickBlock?()
    }

    lazy var textLabel: UILabel = {
        let textLabel = UILabel()
        textLabel.font = UIFont.systemFont(ofSize: 14)
        textLabel.numberOfLines = 8
        textLabel.lineBreakMode = .byTruncatingTail
        textLabel.textAlignment = .justified
        /// default show placeholder
        textLabel.textColor = UIColor.ud.textPlaceholder
        textLabel.text = BundleI18n.MailSDK.Mail_Signature_Null
        textLabel.accessibilityIdentifier = MailAccessibilityIdentifierKey.SettingSignatureTextLabelKey
        return textLabel
    }()

    lazy var editIcon: UIImageView = {
        let icon = UIImageView()
        icon.image = UDIcon.editOutlined.withRenderingMode(.alwaysTemplate)
        icon.tintColor = UIColor.ud.iconN2
        return icon
    }()
}

// MARK: - PCSignaturePreview
class MailPCSignaturePreview: MailSignatureSettingDetail {
    var selected: Bool = false {
        didSet {}
    }

    var signature: String = "" {
        didSet {
            _webView.loadHTMLString(signature, baseURL: nil)
            _webView.isHidden = signature.isEmpty
            textLabel.isHidden = !_webView.isHidden
        }
    }

    lazy var textLabel: UILabel = {
        let textLabel = UILabel()
        textLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        textLabel.numberOfLines = 8
        textLabel.lineBreakMode = .byTruncatingTail
        textLabel.textAlignment = .justified
        /// default show placeholder
        textLabel.textColor = UIColor.ud.textPlaceholder
        textLabel.text = BundleI18n.MailSDK.Mail_Signature_Null
        textLabel.accessibilityIdentifier = MailAccessibilityIdentifierKey.SettingSignatureTextLabelKey
        return textLabel
    }()

    var contentView: UIView {
        return _contentView
    }

    var _contentHeight: CGFloat = 28
    var contentHeight: CGFloat {
        return _contentHeight
    }

    func updateHeight(newHeight: CGFloat) -> CGFloat {
        if newHeight != _contentHeight {
            _contentHeight = newHeight
        }
        return _contentHeight
    }

    var webView: MailNewBaseWebView {
        return _webView
    }

    lazy var _contentView: UIView = {
        let view = UIView()
        view.addSubview(_webView)
        _webView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(separatorOn(view).snp.bottom)
        }
        view.addSubview(textLabel)
        view.backgroundColor = UIColor.ud.bgFloat
        textLabel.snp.makeConstraints { (make) in
            make.left.equalTo(0)
            make.width.lessThanOrEqualToSuperview().offset(-24)
            make.centerY.equalToSuperview()
        }
        _webView.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        _webView.layer.borderWidth = 1.0
        _webView.layer.cornerRadius = 6.0
        _webView.clipsToBounds = true
        _webView.scrollView.contentInset = UIEdgeInsets(top: 4, left: 8, bottom: 0, right: 8)
        return view
    }()

    lazy var _webView: MailNewBaseWebView = {
        /// this script use to scale signature in mobile
        /// add onclick event & close contenteditable
        let script = MailSignaturePreviewScript.mobileScalable + MailSignaturePreviewScript.closeEditableAndAddClick
        let wkUScript = WKUserScript(source: script, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        let wkUController = WKUserContentController()
        wkUController.addUserScript(wkUScript)
        let wkWebConfig = WKWebViewConfiguration()
        wkWebConfig.userContentController = wkUController
        let webView = MailWebViewSchemeManager.makeDefaultNewWebView(config: wkWebConfig, provider: provider)
        webView.loadHTMLString("", baseURL: nil)
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.scrollView.showsVerticalScrollIndicator = false
        return webView
    }()

    private var provider: MailSharedServicesProvider?

    init(provider: MailSharedServicesProvider?) {
        self.provider = provider
    }
}
