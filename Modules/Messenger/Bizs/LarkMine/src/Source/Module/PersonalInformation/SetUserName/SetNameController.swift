//
//  SetNameController.swift
//  LarkMine
//
//  Created by 李勇 on 2019/9/23.
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

/// 设置用户名字
final class SetNameController: BaseUIViewController {
    private let viewModel: SetNameViewModel
    private let reachability = Reachability()
    private let disposeBag = DisposeBag()
    private let maxInputLength = 64

    private lazy var textField: UDTextField = {
        let textField = UDTextField()
        textField.config.isShowBorder = true
        textField.config.clearButtonMode = .whileEditing
        textField.config.backgroundColor = UIColor.ud.udtokenComponentOutlinedBg
        textField.placeholder = BundleI18n.LarkMine.Lark_Core_PersonalInformationEnterContent_Placeholder
        return textField
    }()

    init(viewModel: SetNameViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = self.viewModel.title
        /// 添加内容视图
        self.view.addSubview(textField)
        textField.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(14)
            make.left.equalTo(16)
            make.right.equalTo(-16)
        }
        self.textField.placeholder = self.viewModel.placeholderTitle
        self.textField.text = self.viewModel.oldName
        self.textField.input.addTarget(self, action: #selector(textFieldDidChange(textField:)), for: .editingChanged)
        /// 设置导航栏按钮
        let sendBarButtonItem = LKBarButtonItem(title: BundleI18n.LarkMine.Lark_Setting_NameSave)
        sendBarButtonItem.setBtnColor(color: UIColor.ud.colorfulBlue)
        sendBarButtonItem.setProperty(font: LKBarButtonItem.FontStyle.medium.font, alignment: .center)
        sendBarButtonItem.addTarget(self, action: #selector(tabbarAction), for: .touchUpInside)
        self.navigationItem.rightBarButtonItem = sendBarButtonItem
        /// 实时监听网络状态
        try? self.reachability?.startNotifier()
        addCancelItem()
        self.viewModel.trackView()
    }

    override func closeBtnTapped() {
        self.viewModel.trackCancleBtnClick(name: self.textField.text)
        super.closeBtnTapped()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.textField.becomeFirstResponder()
    }

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    @objc
    func tabbarAction() {
        guard let window = self.view.window else { return }

        guard let nameString = self.textField.text else {
            self.viewModel.trackSaveBtnClick(name: self.textField.text, success: false)
            return
        }

        var trimString = nameString.trimmingCharacters(in: .whitespaces)
        /// 设置姓名不能为空
        if !self.viewModel.nameEmptyEnable && trimString.isEmpty {
            self.viewModel.trackSaveBtnClick(name: self.textField.text, success: false)
            UDToast.showTips(with: BundleI18n.LarkMine.Lark_Setting_NameNoneRemind, on: window)
            return
        }

        self.textField.endEditing(true)
        /// 先判断一下网络是否可用
        if let reachability = self.reachability, !reachability.isReachable {
            self.viewModel.trackSaveBtnClick(name: self.textField.text, success: false)
            UDToast.showFailure(with: BundleI18n.LarkMine.Lark_Setting_NameNetworkError, on: window)
            return
        }

        UDToast.showLoading(on: window)
        self.viewModel.setUserName(name: trimString).observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self, weak window] (_) in
                guard let window = window else { return }
                UDToast.removeToast(on: window)
                guard let `self` = self else { return }
                self.viewModel.trackSaveBtnClick(name: self.textField.text, success: true)
                self.dismiss(animated: true)
            }, onError: { [weak window, weak self] (error) in
                guard let window = window else { return }
                UDToast.removeToast(on: window)
                guard let `self` = self else { return }
                self.viewModel.trackSaveBtnClick(name: self.textField.text, success: false)
                var errorMessage = BundleI18n.LarkMine.Lark_Setting_NameGeneralError
                if let error = error.underlyingError as? APIError {
                    switch error.type {
                    // 没权限改用户名字
                    case .forbidSetName(let message):
                        errorMessage = message
                    // 名字审查不通过
                    case .sensitiveUserName(let message):
                        errorMessage = message
                    // 网络错误
                    case .networkIsNotAvailable:
                        errorMessage = BundleI18n.LarkMine.Lark_Setting_NameNetworkError
                    // 其他错误
                    case .unknownBusinessError(let message):
                        errorMessage = message
                    default: break
                    }
                }
                UDToast.showTips(with: errorMessage, on: window)
            }).disposed(by: self.disposeBag)
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
