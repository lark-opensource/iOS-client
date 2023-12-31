//
//  BaseInputViewController.swift
//  LarkContact
//
//  Created by 姚启灏 on 2018/10/31.
//

import UIKit
import Foundation
import LarkModel
import LarkUIKit
import RxSwift
import LKCommonsLogging

 final class SetAliasViewController: BaseUIViewController, UITextFieldDelegate {

    lazy var baseInputView: BaseInputVCTextField = {
        let baseInputView = BaseInputVCTextField()
        baseInputView.textAlignment = .left
        baseInputView.font = UIFont.systemFont(ofSize: 16)
        baseInputView.textColor = UIColor.ud.N900
        baseInputView.clearButtonMode = .whileEditing
        baseInputView.delegate = self
        return baseInputView
    }()

    let wrapperView = UIView()

    var tabbarBlock: ((_ text: String) -> Void)?
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.addSubview(wrapperView)
        self.view.backgroundColor = UIColor.ud.bgBase
        wrapperView.addSubview(baseInputView)

        wrapperView.backgroundColor = UIColor.ud.bgBody
        wrapperView.layer.borderColor = UIColor.ud.N300.cgColor
        wrapperView.layer.borderWidth = 0.5

        wrapperView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(8)
            make.left.right.equalToSuperview()
        }

        baseInputView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(15)
            make.bottom.equalToSuperview().offset(-15)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
        }
    }

     override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        baseInputView.becomeFirstResponder()
    }

     func setConfiguration(title: String = "",
                                 tabTitle: String = "",
                                 inputText: String = "",
                                 tabbarBlock: ((_ text: String) -> Void)? = nil,
                                 textLimitCount: Int = 32) {
        self.title = title
        let sendBarButtonItem = LKBarButtonItem(title: (tabTitle.isEmpty ? BundleI18n.LarkContact.Lark_Legacy_Save : tabTitle))
        sendBarButtonItem.setBtnColor(color: UIColor.ud.colorfulBlue)
        sendBarButtonItem.setProperty(font: LKBarButtonItem.FontStyle.medium.font, alignment: .center)
        sendBarButtonItem.addTarget(self, action: #selector(tabbarAction), for: .touchUpInside)
        self.navigationItem.rightBarButtonItem = sendBarButtonItem
        self.tabbarBlock = tabbarBlock
        self.baseInputView.text = inputText
        self.baseInputView.maxLength = textLimitCount
    }

    @objc
    func tabbarAction() {
        self.tabbarBlock?(self.baseInputView.text ?? "")
        Tracer.tarckProfileAliasTap()
    }
    // MARK: - UITextFieldDelegate
     func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.becomeFirstResponder()
    }

     func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
    }
}

final class BaseInputVCTextField: BaseTextField {
    override func clearButtonRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(x: bounds.origin.x + bounds.size.width - 16,
                      y: (bounds.size.height - 16) / 2,
                      width: 16,
                      height: 16)
    }
}
