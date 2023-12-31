//
//  CustomAlertViewController.swift
//  LarkUIKit
//
//  Created by 武嘉晟 on 2019/6/14.
//

import Foundation
import UIKit
import SnapKit
import LarkExtensions
import UniverseDesignColor

@available(*, deprecated, message: "Parse use LarkAlertController")
open class CustomAlertViewController: UIViewController {

    /// 左边按钮点击回调
    public var leftBtnCallBack: (() -> Void)?
    /// 右边按钮点击回调
    public var rightBtnCallBack: (() -> Void)?

    /// 背景标签
    private lazy var wrapperView: UIView = {
        let wpView = UIView()
        wpView.layer.cornerRadius = 6
        wpView.layer.masksToBounds = true
        wpView.backgroundColor = UIColor.ud.bgBody
        view.addSubview(wpView)
        return wpView
    }()

    /// 标题标签
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = self.alertTitle
        label.font = UIFont.boldSystemFont(ofSize: 17)
        label.textColor = UIColor.ud.textTitle
        label.textAlignment = .center
        label.numberOfLines = 0
        wrapperView.addSubview(label)
        return label
    }()

    /// msg视图
    private lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.text = self.alertMessage
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textPlaceholder
        label.numberOfLines = 0
        label.textAlignment = .center
        wrapperView.addSubview(label)
        return label
    }()

    private let alertTitle: String
    private let alertMessage: String
    private let leftBtnText: String
    private let rightBtnText: String

    private let borderColor = UIColor.ud.lineBorderCard

    public init(title: String = "", body: String = "", leftBtnText: String? = nil, rightBtnText: String? = nil) {
        self.alertTitle = title
        self.alertMessage = body
        self.leftBtnText = leftBtnText ?? BundleI18n.AlertController.Lark_Legacy_Cancel
        self.rightBtnText = rightBtnText ?? BundleI18n.AlertController.Lark_Legacy_Sure
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .custom
        self.modalTransitionStyle = .crossDissolve
    }

    public init(title: String = "",
                body: String = "",
                confrimText: String,
                confrimCallBack: (() -> Void)? = nil) {
        self.alertTitle = title
        self.alertMessage = body
        self.leftBtnText = ""
        self.rightBtnText = confrimText
        self.rightBtnCallBack = confrimCallBack
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .custom
        self.modalTransitionStyle = .crossDissolve
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        initView()
    }

    func initView() {
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        /// 约束设置
        wrapperView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.left.equalToSuperview().offset(36).priority(.medium)
            make.right.equalToSuperview().offset(-36).priority(.medium)
            make.width.lessThanOrEqualTo(320).priority(.required)
        }

        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(20)
            make.right.equalTo(-20)
            make.centerX.equalToSuperview()
            make.top.equalTo(24)
        }

        messageLabel.snp.makeConstraints { (make) in
            if self.alertTitle.isEmpty {
                make.top.equalTo(24)
            } else {
                make.top.equalTo(titleLabel.snp.bottom).offset(10)
            }
            make.left.equalTo(20)
            make.right.equalTo(-20)
            make.centerX.equalToSuperview()
        }

        if leftBtnText.isEmpty {
            setupConfirmLabel(confirmLabel())
        } else {
            setupConfirmLabel(confirmLabel(), cancelLabel: cancleLabel())
        }
        //当内容多行时，文本要左对齐
        self.view.layoutIfNeeded()
        //基于文本内容，及messageLabel的width,看是否能填充满一行的宽度
        let actualWidth = self.messageLabel.systemLayoutSizeFitting(.zero).width
        if actualWidth < messageLabel.frame.size.width {
            messageLabel.textAlignment = .center
        } else {
            messageLabel.textAlignment = .left
        }
    }

    /// 设置一个label
    private func setupConfirmLabel(_ label: UILabel) {
        label.lu.addTopBorder(color: self.borderColor)
        wrapperView.addSubview(label)
        label.snp.makeConstraints { (make) in
            if self.alertMessage.isEmpty {
                make.top.equalTo(titleLabel.snp.bottom).offset(24)
            } else {
                make.top.equalTo(messageLabel.snp.bottom).offset(24)
            }
            make.right.bottom.equalToSuperview()
            make.width.equalToSuperview()
            make.height.greaterThanOrEqualTo(50)
        }
    }

    /// 设置两个Label
    private func setupConfirmLabel(_ confirmLabel: UILabel, cancelLabel: UILabel) {
        confirmLabel.lu.addTopBorder(color: self.borderColor)
        confirmLabel.lu.addleftBorder(color: self.borderColor)
        wrapperView.addSubview(confirmLabel)
        confirmLabel.snp.makeConstraints { (make) in
            if self.alertMessage.isEmpty {
                make.top.equalTo(titleLabel.snp.bottom).offset(24)
            } else {
                make.top.equalTo(messageLabel.snp.bottom).offset(24)
            }
            make.right.bottom.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.5)
            make.height.greaterThanOrEqualTo(50)
        }

        cancelLabel.lu.addRightBorder(color: self.borderColor)
        cancelLabel.lu.addTopBorder(color: self.borderColor)
        wrapperView.addSubview(cancelLabel)
        cancelLabel.snp.makeConstraints { (make) in
            make.top.equalTo(confirmLabel)
            make.left.bottom.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.5)
            make.height.greaterThanOrEqualTo(50)
        }
    }

    /// 右边的label
    private func confirmLabel() -> UILabel {
        let label = UILabel()
        label.text = rightBtnText
        label.textAlignment = .center
        label.textColor = UIColor.ud.primaryContentDefault
        label.font = UIFont.systemFont(ofSize: 17)
        label.numberOfLines = 0
        label.isUserInteractionEnabled = true
        let ges = UITapGestureRecognizer(target: self, action: #selector(settingLabelTapped))
        label.addGestureRecognizer(ges)
        return label
    }

    /// 左边的label
    private func cancleLabel() -> UILabel {
        let label = UILabel()
        label.text = leftBtnText
        label.textAlignment = .center
        label.textColor = UIColor.ud.color(33, 33, 33)
        label.font = UIFont.systemFont(ofSize: 17)
        label.numberOfLines = 0
        label.isUserInteractionEnabled = true
        let ges = UITapGestureRecognizer(target: self, action: #selector(cancelLabelTapped))
        label.addGestureRecognizer(ges)
        return label
    }

    @objc
    func settingLabelTapped() {
        dismiss(animated: false, completion: rightBtnCallBack)
    }

    @objc
    func cancelLabelTapped() {
        dismiss(animated: false, completion: leftBtnCallBack)
    }
}
