//
//  ImageEditAddTextViewController.swift
//  LarkUIKitDemo
//
//  Created by SuPeng on 12/10/18.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LarkUIKit

final class ImageEditAddTextViewController: BaseUIViewController, UITextViewDelegate {
    var cancelEditBlock: ((ImageEditAddTextViewController) -> Void)?
    var finishEditBlock: ((ImageEditAddTextViewController, ImageEditText) -> Void)?

    private let backButton = UIButton()
    private let finishButton = UIButton()
    private let textView = UITextView()
    private let colorPanel: ImageEditColorPanel

    init(editText: ImageEditText) {
        colorPanel = ImageEditColorPanel(originColor: editText.color)
        textView.text = editText.text
        super.init(nibName: nil, bundle: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        textView.becomeFirstResponder()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }

        view.backgroundColor = UIColor.black.withAlphaComponent(0.6)

        backButton.setTitle(BundleI18n.LarkImageEditor.Lark_Legacy_Back, for: .normal)
        backButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        backButton.setTitleColor(UIColor.ud.N00, for: .normal)
        backButton.addTarget(self, action: #selector(backButtonDidClick), for: .touchUpInside)
        view.addSubview(backButton)
        backButton.snp.makeConstraints { (make) in
            make.left.equalTo(24)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(10)
        }

        finishButton.setTitle(BundleI18n.LarkImageEditor.Lark_Legacy_Finish, for: .normal)
        finishButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        finishButton.setTitleColor(UIColor.ud.colorfulBlue, for: .normal)
        finishButton.addTarget(self, action: #selector(finishButtonDidClick), for: .touchUpInside)
        view.addSubview(finishButton)
        finishButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(backButton.snp.centerY)
            make.right.equalToSuperview().offset(-24)
        }

        colorPanel.delegate = self
        colorPanel.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 40)
        textView.inputAccessoryView = colorPanel
        textView.font = UIFont.systemFont(ofSize: 21)
        textView.textColor = colorPanel.currentColor.color()
        textView.tintColor = colorPanel.currentColor.color()
        textView.returnKeyType = .done
        textView.delegate = self
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        view.addSubview(textView)
        textView.snp.makeConstraints { (make) in
            make.left.equalTo(24)
            make.top.equalTo(backButton.snp.bottom).offset(21)
            make.right.equalToSuperview().offset(-24)
        }
    }

    @objc
    private func backButtonDidClick() {
        textView.resignFirstResponder()
        cancelEditBlock?(self)
    }

    @objc
    private func finishButtonDidClick() {
        textView.resignFirstResponder()
        finishEditBlock?(self, ImageEditText(text: textView.text, color: colorPanel.currentColor))
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            finishEditBlock?(self, ImageEditText(text: textView.text, color: colorPanel.currentColor))
            return false
        }
        return true
    }
}

extension ImageEditAddTextViewController: ImageEditColorPanelDelegate {
    func colorPanel(_ colorPanel: ImageEditColorPanel, didSelect color: ColorPanelType) {
        textView.textColor = colorPanel.currentColor.color()
        textView.tintColor = colorPanel.currentColor.color()
    }
}
