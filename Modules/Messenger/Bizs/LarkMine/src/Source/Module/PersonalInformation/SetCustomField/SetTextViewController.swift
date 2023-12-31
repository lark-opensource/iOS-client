//
//  SetTextViewController.swift
//  LarkMine
//
//  Created by ByteDance on 2023/1/3.
//

import Foundation
import LarkUIKit
import RxSwift
import EENavigator
import UniverseDesignToast
import Reachability
import LarkSDKInterface
import UniverseDesignInput
import UIKit
import LarkRustClient

/// 设置用户名字
final class SetTextViewController: BaseUIViewController {
    private let viewModel: SetTextViewModel

    private let maxInputLength: Int = 100

    private lazy var textField: UDTextField = {
        let textField = UDTextField()
        textField.config.isShowBorder = true
        textField.config.clearButtonMode = .whileEditing
        textField.placeholder = BundleI18n.LarkMine.Lark_Core_PersonalInformationEnterContent_Placeholder
        return textField
    }()

    init(viewModel: SetTextViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = self.viewModel.pageTitle
        /// 添加内容视图
        self.view.addSubview(textField)
        textField.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(14)
            make.left.equalTo(16)
            make.right.equalTo(-16)
        }
        self.textField.config.backgroundColor = UIColor.ud.udtokenComponentOutlinedBg
        self.textField.text = self.viewModel.text
        textField.input.addTarget(self, action: #selector(textFieldDidChange(textField:)), for: .editingChanged)
        /// 设置导航栏按钮
        let sendBarButtonItem = LKBarButtonItem(title: BundleI18n.LarkMine.Lark_Setting_NameSave)
        sendBarButtonItem.setBtnColor(color: UIColor.ud.colorfulBlue)
        sendBarButtonItem.setProperty(font: LKBarButtonItem.FontStyle.medium.font, alignment: .center)
        sendBarButtonItem.addTarget(self, action: #selector(saveAction), for: .touchUpInside)
        self.navigationItem.rightBarButtonItem = sendBarButtonItem
        addCancelItem()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.textField.becomeFirstResponder()
    }

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    @objc
    func saveAction() {
        guard let window = self.view.window else { return }
        self.textField.endEditing(true)
        let text = textField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        if text == viewModel.text {
            self.dismiss(animated: true)
            return
        }
        UDToast.showLoading(on: window)
        self.viewModel.savePersonalInfo(text: text).observeOn(MainScheduler.instance)
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
        // 中文特殊处理且存在高亮文本情况不做处理
        let lang = UIApplication.shared.textInputMode?.primaryLanguage
        if lang == "zh-Hans",
           let range = textField.markedTextRange,
           let position = textField.position(from: range.start, offset: 0) {
        } else if str.count > maxInputLength {
            textField.text = str.substring(to: maxInputLength)
        }
    }
}
