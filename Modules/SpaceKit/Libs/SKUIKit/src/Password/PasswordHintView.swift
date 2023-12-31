//
//  DrivePasswordView.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2019/12/10.
//  

import UIKit
import SnapKit
import UniverseDesignToast
import RxCocoa
import RxSwift
import SKResource
import UniverseDesignColor
import UniverseDesignEmpty
import UniverseDesignInput

public final class PasswordHintView: UIView {
    public enum Mode {
        case compact // 紧凑
        case normal  // 正常
    }
    
    public var mode: Mode = .normal {
        didSet {
            if oldValue != mode {
                updateUILayout()
            }
        }
    }
    private var iconSize: CGFloat {
        return mode == .normal ? 120 : 75
    }
    private var iconLabelMargin: CGFloat {
        return mode == .normal ? 20 : 8
    }
    private var sumbmitHeight: CGFloat {
        return mode == .normal ? 36 : 0
    }
    private var submitTop: CGFloat {
        return mode == .normal ? 12 : 0
    }
    private var titleFontSize: CGFloat {
        return mode == .normal ? 16 : 14
    }
    private let disposeBag = DisposeBag()

    private lazy var container: UIView = {
        let view = UIView()
        return view
    }()

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = true
        return scrollView
    }()

    private let lockImageView: UIImageView = {
        let imageView = UIImageView(image: UDEmptyType.noAccess.defaultImage())
        imageView.backgroundColor = .clear
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let promptLabel: UILabel = {
        let label = UILabel()
        label.textColor = UDColor.textTitle
        label.font = UIFont.ct.systemRegular(ofSize: 16)
        label.textAlignment = .center
        label.text = BundleI18n.SKResource.Drive_Drive_FileNeedPassword
        return label
    }()

    private let passwordField: UDTextField = {
        var config = UDTextFieldUIConfig()
        let textField = UDTextField()
        config.textColor = UDColor.textTitle
        config.font = UIFont.ct.systemRegular(ofSize: 14)
        config.minimumFontSize = 14
        config.textAlignment = .center
        config.isShowBorder = true
        config.textMargins = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        config.borderColor = UIColor.ud.N400.withAlphaComponent(0.5)

        textField.config = config
        textField.input.textContentType = .password
        textField.input.returnKeyType = .go
        textField.input.isSecureTextEntry = true

        textField.layer.cornerRadius = 4
        let placeHolderAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.ud.N500,
            .font: UIFont.ct.systemRegular(ofSize: 14)
        ]
        let attributedPlaceholder = NSAttributedString(string: BundleI18n.SKResource.Drive_Drive_PasswordPlaceHolder,
                                                       attributes: placeHolderAttributes)
        textField.input.attributedPlaceholder = attributedPlaceholder
        return textField
    }()

    private let submitButton: UIButton = {
        let button = UIButton()
        button.setTitle(BundleI18n.SKResource.Doc_Facade_Confirm, for: .normal)
        button.setTitleColor(UDColor.primaryOnPrimaryFill, for: .normal)
        button.backgroundColor = UIColor.ud.B200
        button.layer.cornerRadius = 6
        button.isEnabled = false
        return button
    }()

    /// 处理用户输入的密码的闭包
    public var passwordHandler: ((String) -> Void)?

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        addObserver()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = UDColor.bgBody
        addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        scrollView.addSubview(container)
        container.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalToSuperview().offset(-56).priority(999)
            make.width.lessThanOrEqualTo(320)
        }
        container.addSubview(lockImageView)
        lockImageView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.height.equalTo(iconSize)
        }

        container.addSubview(promptLabel)
        promptLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(lockImageView.snp.bottom).offset(iconLabelMargin)
        }

        container.addSubview(passwordField)
        passwordField.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(promptLabel.snp.bottom).offset(iconLabelMargin)
            make.width.equalTo(240)
            make.height.equalTo(36)
        }
        passwordField.delegate = self
        passwordField.input.rx.text.asDriver().drive(onNext: { [weak self] (password) in
            guard let self = self else { return }
            guard let password = password else {
                self.submitButton.backgroundColor = UIColor.ud.N400
                return
            }
            if password.isEmpty {
                self.submitButton.backgroundColor = UIColor.ud.N400
                self.submitButton.isEnabled = false
            } else {
                self.submitButton.backgroundColor = UIColor.ud.colorfulBlue
                self.submitButton.isEnabled = true
            }
        }).disposed(by: disposeBag)

        container.addSubview(submitButton)
        submitButton.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(passwordField.snp.bottom).offset(12)
            make.width.equalTo(240)
            make.height.equalTo(36)
            make.bottom.equalToSuperview()
        }
        submitButton.rx.tap.subscribe(onNext: { [weak self] _ in
            guard let self = self, let password = self.passwordField.text else { return }
            self.passwordHandler?(password)
        }).disposed(by: disposeBag)

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapBackground))
        addGestureRecognizer(tapGestureRecognizer)
    }

    @objc
    private func tapBackground() {
        passwordField.endEditing(false)
    }

    private func addObserver() {
        NotificationCenter.default.rx.notification(UIResponder.keyboardWillShowNotification)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] notification in
                self?.keyboardWillShow(notification: notification)
            })
            .disposed(by: disposeBag)

        NotificationCenter.default.rx.notification(UIResponder.keyboardWillHideNotification)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] notification in
                self?.keyboardWillHide(notification: notification)
            })
            .disposed(by: disposeBag)
    }

    func keyboardWillShow(notification: Notification) {
        guard let userInfo = notification.userInfo,
            let keyboardSize = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let maxY = container.convert(container.bounds, to: window).maxY
        let offsetY = keyboardSize.origin.y - maxY
        if offsetY < 0 {
            scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: scrollView.contentOffset.y - offsetY), animated: true)
        }
    }

    func keyboardWillHide(notification: Notification) {
        scrollView.setContentOffset(CGPoint.zero, animated: true)
    }
    
    private func updateUILayout() {
        lockImageView.snp.updateConstraints { make in
            make.width.height.equalTo(iconSize)
        }
        promptLabel.snp.updateConstraints { make in
            make.top.equalTo(lockImageView.snp.bottom).offset(iconLabelMargin)
        }
        passwordField.snp.updateConstraints { make in
            make.top.equalTo(promptLabel.snp.bottom).offset(iconLabelMargin)
            make.width.equalTo(240)
            make.height.equalTo(36)
        }
        submitButton.snp.updateConstraints { make in
            make.height.equalTo(sumbmitHeight)
            make.top.equalTo(passwordField.snp.bottom).offset(submitTop)

        }
        submitButton.isHidden = (mode == .compact)
        self.setNeedsLayout()
        self.layoutIfNeeded()
        promptLabel.font = UIFont.ct.systemRegular(ofSize: titleFontSize)
    }
}

extension PasswordHintView {

    /// 提示密码错误
    public func showPasswordError() {
        UDToast.showTips(with: BundleI18n.SKResource.Doc_Permission_PasswordError, on: window ?? self)
        passwordField.becomeFirstResponder()
    }

    /// 支持外部设置UI
    public func configUI(promptLabelText: String) {
        self.promptLabel.text = promptLabelText
    }
}

extension PasswordHintView: UDTextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let password = textField.text else { return false }
        passwordHandler?(password)
        return false
    }
}
