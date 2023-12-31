//
//  SetQueryNumberController.swift
//  LarkContact
//
//  Created by 李勇 on 2019/5/1.
//

import Foundation
import LarkUIKit
import RxSwift
import UniverseDesignToast
import UIKit

/// 员工电话号码查询次数设置
final class SetQueryNumberController: BaseUIViewController, UITextFieldDelegate {
    /// 次数输入框
    private var numberTextField: UITextField!
    private var isFinishButtonHidden: Bool = true {
        didSet {
            guard isFinishButtonHidden != oldValue else { return }
            if isFinishButtonHidden {
                self.navigationItem.rightBarButtonItem = nil
            } else {
                self.navigationItem.rightBarButtonItem = self.finishButton
            }
        }
    }

    /// 导航右边完成按钮
    private(set) lazy var finishButton: UIBarButtonItem = {
        let btnItem = LKBarButtonItem(title: BundleI18n.LarkContact.Lark_Legacy_ApplicationPhoneCallTimeSetSave)
        btnItem.setProperty(font: LKBarButtonItem.FontStyle.medium.font, alignment: .right)
        btnItem.button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        btnItem.button.setTitleColor(UIColor.ud.textDisabled, for: .disabled)
        btnItem.button.addTarget(self, action: #selector(didClickFinishButton), for: .touchUpInside)
        return btnItem
    }()

    /// 编辑按钮
    private var editNumberButotn: UIButton!
    /// 清除按钮
    private var clearNumberButotn: UIButton!
    /// 次数输入错误提示标签
    private var footerLabel: UILabel = .init()

    private let viewModel: SetQueryNumberViewModel
    private let disposeBag = DisposeBag()

    init(viewModel: SetQueryNumberViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.ud.bgBase
        /// 创建导航头部
        self.createNavigationBar()
        /// 创建内容视图
        self.createBottomView()
        /// 异步查询一次
        self.viewModel.fetchPhoneQueryQuota()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (quota, limit) in
                guard let `self` = self else { return }
                self.viewModel.maxLimit = limit
                self.numberTextField.text = "\(quota)"
                self.numberTextField.becomeFirstResponder()
            }).disposed(by: self.disposeBag)
    }

    /// 创建内容视图
    private func createBottomView() {
        /// 底部加个滚动视图
        let bottomScrollView: UIScrollView = UIScrollView()
        bottomScrollView.backgroundColor = UIColor.ud.bgBase
        bottomScrollView.keyboardDismissMode = .onDrag
        bottomScrollView.showsVerticalScrollIndicator = false
        bottomScrollView.showsHorizontalScrollIndicator = false
        bottomScrollView.contentInsetAdjustmentBehavior = .never

        self.view.addSubview(bottomScrollView)
        bottomScrollView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        let containerView: UIView = UIView()
        bottomScrollView.addSubview(containerView)
        containerView.snp.makeConstraints { (make) in
            make.width.equalTo(bottomScrollView)
            make.height.equalTo(bottomScrollView).offset(1)
            make.edges.equalToSuperview()
        }

        /// header label
        let headerLabel: UILabel = UILabel()
        headerLabel.textColor = UIColor.ud.textPlaceholder
        headerLabel.font = UIFont.systemFont(ofSize: 14)
        headerLabel.text = BundleI18n.LarkContact.Lark_Legacy_ApplicationPhoneCallTimeSetPageSubTitle
        headerLabel.numberOfLines = 0
        containerView.addSubview(headerLabel)
        headerLabel.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.right.lessThanOrEqualTo(-16)
            make.top.equalTo(12)
        }

        /// 查询次数
        let centerQueryView: UIView = UIView()
        centerQueryView.backgroundColor = UIColor.ud.bgBody
        containerView.addSubview(centerQueryView)
        centerQueryView.snp.makeConstraints { (make) in
            make.height.equalTo(48)
            make.top.equalTo(headerLabel.snp.bottom).offset(4)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }
        do {
            /// label
            let label: UILabel = UILabel()
            label.textColor = UIColor.ud.textTitle
            label.text = BundleI18n.LarkContact.Lark_Legacy_ApplicationPhoneCallTimeSetPageText
            label.setContentCompressionResistancePriority(.required, for: .horizontal)
            label.font = UIFont.systemFont(ofSize: 16)
            centerQueryView.addSubview(label)
            let width = label.text?.getWidth(font: label.font) ?? 0
            label.snp.makeConstraints { (make) in
                make.centerY.equalToSuperview()
                make.left.equalTo(16)
                make.width.equalTo(width)
            }

            /// textfield
            self.numberTextField = UITextField()
            self.numberTextField.textAlignment = .left
            self.numberTextField.font = UIFont.systemFont(ofSize: 16)
            self.numberTextField.textColor = UIColor.ud.textTitle
            self.numberTextField.clearButtonMode = .never
            self.numberTextField.delegate = self
            self.numberTextField.keyboardType = .numberPad
            self.numberTextField.placeholder = BundleI18n.LarkContact.Lark_Legacy_ApplicationPhoneCallTimeSetPageBackground
            self.numberTextField.text = "\(self.viewModel.todayQuota)"
            NotificationCenter.default.addObserver(self, selector: #selector(textFieldContentDidChange), name: UITextField.textDidChangeNotification, object: self.numberTextField)
            centerQueryView.addSubview(self.numberTextField)
            self.numberTextField.snp.makeConstraints { (make) in
                make.left.equalTo(label.snp.right).offset(16)
                make.right.equalTo(-35)
                make.height.equalTo(35)
                make.centerY.equalToSuperview()
            }

            /// icon
            self.editNumberButotn = UIButton(type: .custom)
            self.editNumberButotn.setImage(Resources.begin_edit_number_icon, for: .normal)
            centerQueryView.addSubview(self.editNumberButotn)
            self.editNumberButotn.snp.makeConstraints { (make) in
                make.right.equalTo(-16)
                make.height.width.equalTo(16)
                make.centerY.equalToSuperview()
            }
            self.editNumberButotn.rx.tap.subscribe(onNext: { [weak self] () in
                guard let `self` = self else { return }
                self.numberTextField.becomeFirstResponder()
            }).disposed(by: self.disposeBag)

            /// clear
            self.clearNumberButotn = UIButton(type: .custom)
            self.clearNumberButotn.setImage(Resources.clear_number_icon, for: .normal)
            centerQueryView.addSubview(self.clearNumberButotn)
            self.clearNumberButotn.isHidden = true
            self.clearNumberButotn.snp.makeConstraints { (make) in
                make.right.equalTo(-16)
                make.height.width.equalTo(16)
                make.centerY.equalToSuperview()
            }
            self.clearNumberButotn.rx.tap.subscribe(onNext: { [weak self] () in
                guard let `self` = self else { return }
                self.numberTextField.text = ""
            }).disposed(by: self.disposeBag)
        }

        /// footer
        self.footerLabel = UILabel()
        self.footerLabel.text = BundleI18n.LarkContact.Lark_Legacy_ApplicationPhoneCallTimeSetPageMsg(self.viewModel.maxLimit)
        self.footerLabel.font = UIFont.systemFont(ofSize: 14)
        self.footerLabel.textColor = UIColor.ud.textPlaceholder
        self.footerLabel.numberOfLines = 0
        containerView.addSubview(self.footerLabel)
        self.footerLabel.snp.makeConstraints { (make) in
            make.top.equalTo(centerQueryView.snp.bottom).offset(4)
            make.left.equalTo(16)
            make.right.lessThanOrEqualTo(-16)
        }
    }

    /// 创建导航头部
    private func createNavigationBar() {
        self.title = BundleI18n.LarkContact.Lark_Legacy_ApplicationPhoneCallTimeSetPageTitle
        self.addCloseItem()
        self.isFinishButtonHidden = true
    }

    @objc
    override func closeBtnTapped() {
        self.numberTextField.resignFirstResponder()
        self.dismiss(animated: true, completion: nil)
    }

    @objc
    func didClickFinishButton() {
        self.numberTextField.resignFirstResponder()
        if let quota = self.numberTextField.text {
            self.viewModel.requestQueryNumber(quota: quota)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (_) in
                    guard let `self` = self else { return }
                    if let window = self.view.window {
                        UDToast.showSuccess(with: BundleI18n.LarkContact.Lark_Legacy_SaveSuccess, on: window)
                    }
                    self.dismiss(animated: true, completion: nil)
                }, onError: { [weak self] error in
                    if let window = self?.view.window {
                        UDToast.showFailure(
                            with: BundleI18n.LarkContact.Lark_Legacy_SaveFail,
                            on: window,
                            error: error
                        )
                    }
                }).disposed(by: self.disposeBag)
        }
    }

    @objc
    private func textFieldContentDidChange(notification: NSNotification) {
        self.isFinishButtonHidden = false
        /// 对于空字符串，需要特殊处理
        guard let content = self.numberTextField.text, !content.isEmpty else {
            self.finishButton.isEnabled = false
            self.footerLabel.text = BundleI18n.LarkContact.Lark_Legacy_ApplicationPhoneCallTimeSetPageMsg(self.viewModel.maxLimit)
            self.footerLabel.textColor = UIColor.ud.textPlaceholder
            return
        }

        /// 设置footer label
        let number: Int = Int(content) ?? 0
        if number > self.viewModel.maxLimit {
            self.finishButton.isEnabled = false
            self.footerLabel.text = BundleI18n.LarkContact.Lark_Legacy_ApplicationPhoneCallTimeSetErrorMsg(self.viewModel.maxLimit)
            self.footerLabel.textColor = UIColor.ud.R400
        } else {
            self.finishButton.isEnabled = true
            self.footerLabel.text = BundleI18n.LarkContact.Lark_Legacy_ApplicationPhoneCallTimeSetPageMsg(self.viewModel.maxLimit)
            self.footerLabel.textColor = UIColor.ud.textPlaceholder
        }
    }
    // MARK: - UITextFieldDelegate
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.editNumberButotn.isHidden = true
        self.clearNumberButotn.isHidden = false
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        self.editNumberButotn.isHidden = false
        self.clearNumberButotn.isHidden = true
    }
}
