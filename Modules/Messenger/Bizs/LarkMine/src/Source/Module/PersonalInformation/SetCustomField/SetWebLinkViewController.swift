//
//  SetWebLinkViewController.swift
//  LarkMine
//
//  Created by ByteDance on 2022/12/30.
//

import UIKit
import Foundation
import LarkUIKit
import SnapKit
import RxSwift
import UniverseDesignColor
import UniverseDesignInput
import UniverseDesignToast
import LarkRustClient
import LarkSDKInterface

class SetWebLinkViewController: BaseUIViewController {

    private let viewModel: SetWebLinkViewModel

    init(viewModel: SetWebLinkViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var titleTextField: UDTextField = {
        let textField = UDTextField()
        textField.config.isShowBorder = true
        textField.config.isShowTitle = true
        textField.title = BundleI18n.LarkMine.Lark_Core_PersonalInformationWebTitle_Title
        textField.placeholder = BundleI18n.LarkMine.Lark_Core_PersonalInformationWebTitle_Placeholder
        textField.config.clearButtonMode = .whileEditing
        textField.config.backgroundColor = UIColor.ud.udtokenComponentOutlinedBg
        return textField
    }()

    private lazy var linkTextField: UDTextField = {
        let textField = UDTextField()
        textField.config.isShowBorder = true
        textField.config.isShowTitle = true
        textField.title = BundleI18n.LarkMine.Lark_Core_PersonalInformationWebAddress_Title
        textField.placeholder = BundleI18n.LarkMine.Lark_Core_PersonalInformationWebAddress_Placeholder
        textField.config.clearButtonMode = .whileEditing
        textField.config.backgroundColor = UIColor.ud.udtokenComponentOutlinedBg
        return textField
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = viewModel.pageTitle
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.distribution = .fillEqually
        self.view.addSubview(stackView)
        stackView.addArrangedSubview(titleTextField)
        stackView.addArrangedSubview(linkTextField)
        stackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.left.equalTo(16)
            make.right.equalTo(-16)
        }
        titleTextField.text = viewModel.text
        titleTextField.input.addTarget(self, action: #selector(textFieldDidChange(textField:)), for: .editingChanged)
        titleTextField.becomeFirstResponder()
        linkTextField.text = viewModel.link
        linkTextField.input.addTarget(self, action: #selector(textFieldDidChange(textField:)), for: .editingChanged)
        /// 设置导航栏按钮
        let saveButtonItem = LKBarButtonItem(title: BundleI18n.LarkMine.Lark_Setting_NameSave)
        saveButtonItem.setBtnColor(color: UIColor.ud.colorfulBlue)
        saveButtonItem.setProperty(font: LKBarButtonItem.FontStyle.medium.font, alignment: .center)
        saveButtonItem.addTarget(self, action: #selector(saveBtnDidClick), for: .touchUpInside)
        self.navigationItem.rightBarButtonItem = saveButtonItem
        self.addCancelItem()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.titleTextField.becomeFirstResponder()
    }

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    @objc
    func saveBtnDidClick() {
        guard let window = self.view.window else { return }
        self.titleTextField.endEditing(true)
        self.linkTextField.endEditing(true)
        let title = titleTextField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        let link = linkTextField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        // 保存校验
        if !title.isEmpty && link.isEmpty {
            linkTextField.config.errorMessege = BundleI18n.LarkMine.Lark_Core_PersonalInformationWebAddressEmpty_Error
            linkTextField.setStatus(.error)
            return
        }
        if title.isEmpty && !link.isEmpty {
            titleTextField.config.errorMessege = BundleI18n.LarkMine.Lark_Core_PersonalInformationWebTitleEmpty_Error
            titleTextField.setStatus(.error)
            return
        }
        guard viewModel.isLegalLink(link: link) else { return }
        if title == viewModel.text && link == viewModel.link {
            self.dismiss(animated: true)
            return
        }
        UDToast.showLoading(on: window)
        self.viewModel.savePersonalInfo(text: title, link: link).observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
            guard let self = self, let window = self.view.window else { return }
            UDToast.removeToast(on: window)
            self.dismiss(animated: true)
        }, onError: { [weak self] error in
            guard let self = self, let window = self.view.window else { return }
            UDToast.removeToast(on: window)
            if let error = error.underlyingError as? APIError {
                UDToast.showFailure(with: error.displayMessage, on: window)
            }
        })
    }

    @objc
    func textFieldDidChange(textField: UITextField) {
        guard let str = textField.text else { return }
        // 链接
        if textField == linkTextField.input {
            linkTextField.config.errorMessege = BundleI18n.LarkMine.Lark_Core_PersonalInformationInvalidWebAddress_Error
            if viewModel.isLegalLink(link: str) {
                linkTextField.setStatus(.normal)
            } else {
                linkTextField.setStatus(.error)
            }
        } else {
            // 标题
            // 中文特殊处理且存在高亮文本情况不做处理
            let maxInputLength = 40
            let lang = UIApplication.shared.textInputMode?.primaryLanguage
            if lang == "zh-Hans",
               let range = textField.markedTextRange,
               let position = textField.position(from: range.start, offset: 0) {
            } else if str.count > maxInputLength {
                textField.text = str.substring(to: maxInputLength)
            }
            titleTextField.setStatus(.normal)
        }
    }
}
