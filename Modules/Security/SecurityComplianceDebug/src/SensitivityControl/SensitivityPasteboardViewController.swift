//
//  SensitivityPasteboardViewController.swift
//  SecurityComplianceDebug
//
//  Created by yifan on 2023/1/5.
//

import Foundation
import LarkEMM
import LarkSensitivityControl
import SnapKit
import WebKit
import UniverseDesignButton
import UniverseDesignToast
import PDFKit

final class SensitivityPasteboardViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let textField: UITextField = {
        let field = UITextField(frame: .zero)
        field.borderStyle = UITextField.BorderStyle.roundedRect
        field.keyboardType = UIKeyboardType.asciiCapable
        field.placeholder = "测试UITextField控件"
        return field
    }()

    private let textFieldFree: UITextField = {
        let field = UITextField(frame: .zero)
        field.borderStyle = UITextField.BorderStyle.roundedRect
        field.keyboardType = UIKeyboardType.asciiCapable
        field.placeholder = "测试被豁免的UITextField控件"
        field.shouldImmunity = true
        return field
    }()

    private let textView: UITextView = {
        let textView = UITextView(frame: .zero)
        textView.keyboardType = .asciiCapable
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 4
        textView.text = "测试UITextView控件"
        textView.font = UIFont.systemFont(ofSize: 18)
        return textView
    }()

    private let webView: WKWebView = {
        let webView = WKWebView(frame: .zero)
        webView.layer.borderWidth = 1
        if let url = URL(string: "https://www.baidu.com") {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        return webView
    }()

    private let webLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.text = "测试WKWebView控件"
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }()

    private let pdfView: PDFView = {
        let pdfView = PDFView()
        pdfView.layer.borderWidth = 1
        return pdfView
    }()

    private let pdfLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.text = "测试PDFView控件"
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }()

    private let freeButton: UDButton = {
        let button = UDButton(UDButtonUIConifg.primaryBlue)
        button.titleLabel?.font = UIFont.ud.title4
        button.setTitle("系统剪贴板豁免能力", for: .normal)
        return button
    }()

    private let pasteBoardButton: UDButton = {
        let button = UDButton(UDButtonUIConifg.primaryBlue)
        button.titleLabel?.font = UIFont.ud.title4
        button.setTitle("系统剪贴板粘贴保护能力", for: .normal)
        return button
    }()

    private let checkButton: UDButton = {
        let button = UDButton(UDButtonUIConifg.primaryBlue)
        button.titleLabel?.font = UIFont.ud.title4
        button.setTitle("查看当前剪贴板内容", for: .normal)
        return button
    }()

    private let protectWebView: WKWebView = {
        let webView = WKWebView(frame: .zero)
        webView.pointId = "123456765sfgggafesdefr"
        webView.layer.borderWidth = 1
        if let url = URL(string: "https://www.baidu.com") {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        return webView
    }()

    private let protectWebLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.text = "测试单一文档粘贴保护"
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }()

    private let systemButton: UDButton = {
        let button = UDButton(UDButtonUIConifg.primaryBlue)
        button.titleLabel?.font = UIFont.ud.title4
        button.setTitle("裸调剪贴板内容", for: .normal)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        addButtonActions()
        view.backgroundColor = UIColor.ud.bgBody
        scrollView.showsVerticalScrollIndicator = true
        scrollView.isScrollEnabled = true
        scrollView.isUserInteractionEnabled = true

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(textField)
        contentView.addSubview(textFieldFree)
        contentView.addSubview(textView)
        contentView.addSubview(webView)
        webView.addSubview(webLabel)
        contentView.addSubview(pdfView)
        pdfView.addSubview(pdfLabel)
        contentView.addSubview(freeButton)
        contentView.addSubview(pasteBoardButton)
        contentView.addSubview(checkButton)
        contentView.addSubview(protectWebView)
        protectWebView.addSubview(protectWebLabel)
        contentView.addSubview(systemButton)

        guard let url = URL(string: "https://discrete.openmathbooks.org/pdfs/dmoi-tablet.pdf") else {
            return
        }
        DispatchQueue.global().async {
            let document = PDFDocument(url: url)
            DispatchQueue.main.async {
                self.pdfView.document = document
            }
        }

        setConstraints()
    }

    func addButtonActions() {
        freeButton.addTarget(self, action: #selector(clickFreeButton), for: .touchUpInside)
        pasteBoardButton.addTarget(self, action: #selector(clickPasteBoardButton), for: .touchUpInside)
        checkButton.addTarget(self, action: #selector(clickCheckButton), for: .touchUpInside)
        systemButton.addTarget(self, action: #selector(clickSystemButton), for: .touchUpInside)
    }
    @objc
    private func clickFreeButton() {
        let config = PasteboardConfig(token: Token(kTokenAvoidInterceptIdentifier), scene: nil, pointId: nil, shouldImmunity: true)
        SCPasteboard.general(config).string = "系统剪贴板豁免能力"
    }

    @objc
    private func clickPasteBoardButton() {
        let config = PasteboardConfig(token: Token(kTokenAvoidInterceptIdentifier), scene: nil, pointId: nil, shouldImmunity: false)
        SCPasteboard.general(config).string = "系统剪贴板粘贴保护能力"
    }

    @objc
    private func clickCheckButton() {
        let config = PasteboardConfig(token: Token(kTokenAvoidInterceptIdentifier), scene: nil, pointId: nil, shouldImmunity: false)
        let toastConfig = UDToastConfig(toastType: .info, text: SCPasteboard.general(config).string ?? "没有内容", operation: nil)
        UDToast.showToast(with: toastConfig, on: view)
    }

    @objc
    private func clickSystemButton() {
        let config = UDToastConfig(toastType: .info, text: UIPasteboard.general.string ?? "没有内容", operation: nil)
        UDToast.showToast(with: config, on: view)
    }

    private func setConstraints() {
        scrollView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(85)
            $0.left.right.bottom.equalToSuperview()
        }

        contentView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.left.right.equalTo(view) // 垂直滚动，确定宽度
        }

        webView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.left.equalToSuperview().offset(16)
            $0.right.equalToSuperview().offset(-16)
            $0.height.equalTo(150)
        }

        webLabel.snp.makeConstraints {
            $0.top.left.equalToSuperview()
            $0.height.equalTo(30)
        }

        textField.snp.makeConstraints {
            $0.top.equalTo(webView.snp.bottom).offset(6)
            $0.left.equalToSuperview().offset(16)
            $0.right.equalToSuperview().offset(-16)
            $0.height.equalTo(40)
        }

        textFieldFree.snp.makeConstraints {
            $0.top.equalTo(textField.snp.bottom).offset(6)
            $0.left.equalToSuperview().offset(16)
            $0.right.equalToSuperview().offset(-16)
            $0.height.equalTo(40)
        }

        textView.snp.makeConstraints {
            $0.top.equalTo(textFieldFree.snp.bottom).offset(6)
            $0.left.equalToSuperview().offset(16)
            $0.right.equalToSuperview().offset(-16)
            $0.height.equalTo(40)
        }

        protectWebView.snp.makeConstraints {
            $0.top.equalTo(textView.snp.bottom).offset(6)
            $0.left.equalToSuperview().offset(16)
            $0.right.equalToSuperview().offset(-16)
            $0.height.equalTo(150)
        }

        protectWebLabel.snp.makeConstraints {
            $0.top.left.equalToSuperview()
            $0.height.equalTo(30)
        }

        pdfView.snp.makeConstraints {
            $0.top.equalTo(protectWebView.snp.bottom).offset(6)
            $0.left.equalToSuperview().offset(16)
            $0.right.equalToSuperview().offset(-16)
            $0.height.equalTo(150)
        }

        pdfLabel.snp.makeConstraints {
            $0.top.left.equalToSuperview()
            $0.height.equalTo(30)
        }

        freeButton.snp.makeConstraints {
            $0.top.equalTo(pdfView.snp.bottom).offset(6)
            $0.left.equalToSuperview().offset(16)
            $0.right.equalToSuperview().offset(-16)
            $0.height.equalTo(40)
        }

        pasteBoardButton.snp.makeConstraints {
            $0.top.equalTo(freeButton.snp.bottom).offset(6)
            $0.left.equalToSuperview().offset(16)
            $0.right.equalToSuperview().offset(-16)
            $0.height.equalTo(40)
        }

        checkButton.snp.makeConstraints {
            $0.top.equalTo(pasteBoardButton.snp.bottom).offset(6)
            $0.left.equalToSuperview().offset(16)
            $0.right.equalToSuperview().offset(-16)
            $0.height.equalTo(40)
        }

        systemButton.snp.makeConstraints {
            $0.top.equalTo(checkButton.snp.bottom).offset(6)
            $0.left.equalToSuperview().offset(16)
            $0.right.bottom.equalToSuperview().offset(-16)
            $0.height.equalTo(40)
        }
    }
}
