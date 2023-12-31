//
//  NewImportExchangeViewController.swift
//  Calendar
//
//  跟 ImportExchangeViewController 的区别只是 UI 不同。
//  PM 要求是在 FG 为关的情况下，新老版本显示相同，待 FG 下线后，替换 ImportExchangeViewController
//
//  Created by tuwenbo on 2022/8/15.

import UniverseDesignIcon
import UIKit
import SnapKit
import RxSwift
import RxRelay
import RxCocoa
import LarkUIKit
import CalendarFoundation
import UniverseDesignToast
import UniverseDesignNotice
import LKCommonsLogging

final class NewImportExchangeViewController: CalendarController {

    private let viewModel: ImportExchangeViewModel
    private let disposeBag = DisposeBag()
    private let logger = Logger.log(NewImportExchangeViewController.self, category: "calendar.NewImportExchangeViewController")

    // MARK: - Life Cycle
    init(viewModel: ImportExchangeViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.bgFloatBase
        title = BundleI18n.Calendar.Calendar_Sync_AddExchangeCalendarButton
        self.navigationController?.navigationBar.barTintColor = UIColor.ud.bgFloatBase
        (self.navigationController as? LkNavigationController)?.update(style: .custom(UIColor.ud.bgFloatBase))
        addBackItem()

        setupSubViews()
        setupConstraints()
        bindViewModel()
        bindView()

        // 目的是获取SettingExtension里面的数据，没有rxshared的写法
        SettingService.shared().prepare { }
    }

    // MARK: - Layout UI
    private func setupSubViews() {
        view.addSubview(stackView)
        stackView.spacing = 16

        stackView.addArrangedSubview(noticeView)

        emailView.spacing = 8
        emailView.addArrangedSubview(emailLabel)
        emailView.addArrangedSubview(emailTextField)
        emailView.addArrangedSubview(emailHintLabel)
        emailView.setCustomSpacing(4, after: emailTextField)
        stackView.addArrangedSubview(emailView)

        stackView.setCustomSpacing(0, after: emailView)

        passwordView.spacing = 8
        passwordView.addArrangedSubview(passwordLabel)
        passwordView.addArrangedSubview(passwordTextField)
        passwordView.addArrangedSubview(passwordHintLabel)
        passwordView.setCustomSpacing(4, after: passwordTextField)
        stackView.addArrangedSubview(passwordView)

        stackView.setCustomSpacing(0, after: passwordView)

        serverUrlView.spacing = 8
        serverUrlView.addArrangedSubview(serverUrlLabel)
        serverUrlView.addArrangedSubview(serverUrlTextField)
        passwordView.setCustomSpacing(4, after: passwordTextField)
        stackView.addArrangedSubview(serverUrlView)

        view.addSubview(loginButton)
        view.addSubview(hintLabel)
        view.addSubview(helpLinkLabel)
    }

    private func setupConstraints() {
        stackView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(16)
            make.leading.equalTo(16)
        }

        noticeView.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.height.greaterThanOrEqualTo(40)
        }
        noticeView.isHidden = true

        emailView.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
        }

        emailLabel.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(22)
        }
        emailTextField.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(48)
        }

        emailTextField.layer.cornerRadius = 10

        emailHintLabel.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(20)
        }
        emailHintLabel.alpha = 0

        passwordView.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
        }

        passwordLabel.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(22)
        }

        passwordTextField.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(48)
        }
        passwordTextField.layer.cornerRadius = 10
        if #available(iOS 12.0, *) {
            passwordTextField.textContentType = .oneTimeCode
        }

        // 暂时没用到
        passwordHintLabel.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(20)
        }
        passwordHintLabel.alpha = 0

        serverUrlView.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
        }

        serverUrlLabel.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(22)
        }

        serverUrlTextField.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(48)
        }
        serverUrlTextField.layer.cornerRadius = 10

        loginButton.snp.makeConstraints { (make) in
            make.top.equalTo(stackView.snp.bottom).offset(32)
            make.leading.trailing.equalTo(stackView)
            make.height.equalTo(48)
        }
        loginButton.layer.cornerRadius = 10

        hintLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(stackView)
            make.trailing.lessThanOrEqualTo(stackView)
            make.top.equalTo(stackView.snp.bottom).offset(4)
        }
        hintLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        hintLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

        helpLinkLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(hintLabel)
            make.trailing.lessThanOrEqualTo(stackView)
        }
        helpLinkLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        helpLinkLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

    }

    // MARK: - Bind
    private func bindViewModel() {

        // email、password、serverurl和vm双向绑定
        viewModel.emailAddress.asObservable().bind(to: emailTextField.rx.text).disposed(by: disposeBag)
        emailTextField.rx.text.orEmpty.bind(to: viewModel.emailAddress).disposed(by: disposeBag)

        viewModel.password.asObservable().bind(to: passwordTextField.rx.text).disposed(by: disposeBag)
        passwordTextField.rx.text.orEmpty.bind(to: viewModel.password).disposed(by: disposeBag)

        viewModel.serverUrl.asObservable().bind(to: serverUrlTextField.rx.text).disposed(by: disposeBag)
        serverUrlTextField.rx.text.orEmpty.bind(to: viewModel.serverUrl).disposed(by: disposeBag)

        viewModel.loginEnabled.bind(to: loginButton.rx.isEnabled).disposed(by: disposeBag)

        emailTextField.rx.controlEvent([.editingChanged])
            .asObservable()
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                self.emailHintLabel.alpha = 0
            }).disposed(by: disposeBag)

        serverUrlTextField.rx.controlEvent([.editingChanged])
            .asObservable()
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                self.hintLabel.isHidden = true
                self.helpLinkLabel.isHidden = true
            }).disposed(by: disposeBag)

        viewModel.loginResult
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] result in
                guard let `self` = self else { return }
                switch result {
                case let .success(success):
                    self.handleLoginSuccess(success)
                case let .failure(error):
                    self.handleLoginError(error)
                }
            }).disposed(by: disposeBag)

        viewModel.loginLoading.subscribeForUI(onNext: { [weak self] loading in
            guard let self = self else { return }
            if loading {
                self.loginButton.buttonState = .loading
            } else {
                if self.loginButton.buttonState == .loading {
                    self.loginButton.buttonState = .normal
                }
            }
        }).disposed(by: disposeBag)
    }

    private func bindView() {
        passwordToggleButton.rx.tap.subscribe(onNext: { [weak self] _ in
            guard let `self` = self else { return }
            self.hidePassword(hide: !self.passwordTextField.isSecureTextEntry)
        }).disposed(by: disposeBag)
        passwordTextField.rightView = passwordToggleButton
        passwordTextField.rightViewMode = .always

        loginButton.rx
            .controlEvent(.touchUpInside)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                self.viewModel.login()
            }).disposed(by: disposeBag)

        helpLinkLabel.isUserInteractionEnabled = true
        helpLinkLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(gotoHelpUrl)))
    }

    private func hidePassword(hide: Bool) {
        self.passwordTextField.isSecureTextEntry = hide
        // 为了方便的改变按钮图标，设密码显示时，切换按钮为选中态
        self.passwordToggleButton.isSelected = !hide
    }

    // MARK: - Touch
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for case let subview as UIStackView in stackView.arrangedSubviews {
            for case let view as NewInputTextField in subview.arrangedSubviews {
                view.endEditing(true)
            }
        }
    }

    private func getVerticalStackView() -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.isLayoutMarginsRelativeArrangement = true
        return stackView
    }

    // MARK: - View Lazy load
    private lazy var emailView = getVerticalStackView()

    private lazy var emailLabel: UILabel = {
        let label = UILabel()
        let attributedText = NSMutableAttributedString(string: BundleI18n.Calendar.Calendar_Ex_MailAddress,
                                                       attributes: [.foregroundColor: UIColor.ud.N900,
                                                                    .font: UIFont.cd.regularFont(ofSize: 14)])
        attributedText.append(NSAttributedString(string: "*", attributes: [.foregroundColor: UIColor.ud.colorfulRed,
                                                                           .font: UIFont.cd.regularFont(ofSize: 14)]))
        label.attributedText = attributedText
        return label
    }()

    private lazy var emailTextField: NewInputTextField = {
        let textField = NewInputTextField(frame: .zero)
        textField.placeholder = BundleI18n.Calendar.Calendar_Ex_PleaseEnter
        textField.backgroundColor = UIColor.ud.bgFloat
        textField.keyboardType = .asciiCapable
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        return textField
    }()

    private lazy var emailHintLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.colorfulRed
        label.text = BundleI18n.Calendar.Calendar_Ex_AddressInvalid
        label.font = UIFont.cd.regularFont(ofSize: 14)
        return label
    }()

    private lazy var passwordView = getVerticalStackView()

    private lazy var passwordLabel: UILabel = {
        let label = UILabel()
        let attributedText = NSMutableAttributedString(string: BundleI18n.Calendar.Calendar_Common_Password,
                                                       attributes: [.foregroundColor: UIColor.ud.N900,
                                                                    .font: UIFont.cd.regularFont(ofSize: 14)])
        attributedText.append(NSAttributedString(string: "*", attributes: [.foregroundColor: UIColor.ud.colorfulRed,
                                                                           .font: UIFont.cd.regularFont(ofSize: 14)]))
        label.attributedText = attributedText
        label.font = UIFont.cd.regularFont(ofSize: 14)
        return label
    }()

    private lazy var passwordTextField: NewInputTextField = {
        let textField = NewInputTextField(frame: .zero)
        textField.placeholder = BundleI18n.Calendar.Calendar_Ex_PleaseEnter
        textField.backgroundColor = UIColor.ud.bgFloat
        textField.contentInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 20)
        textField.keyboardType = .asciiCapable
        textField.isSecureTextEntry = true
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.clearsOnBeginEditing = false
        return textField
    }()

    private lazy var passwordHintLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.colorfulRed
        label.text = BundleI18n.Calendar.Calendar_Ex_AddressInvalid
        label.font = UIFont.cd.regularFont(ofSize: 14)
        return label
    }()

    private lazy var passwordToggleButton: UIButton = {
        let button = UIButton(type: .custom)
        button.frame = CGRect(x: 0, y: 0, width: 16, height: 16)
        button.setImage(UDIcon.getIconByKey(.invisibleOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.N600), for: .normal)
        button.setImage(UDIcon.getIconByKey(.visibleOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.N600), for: .selected)
        return button
    }()

    private lazy var serverUrlView = getVerticalStackView()

    private lazy var serverUrlLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.Calendar.Calendar_Common_ServerAddress
        label.textColor = UIColor.ud.N900
        label.font = UIFont.cd.regularFont(ofSize: 14)
        return label
    }()

    private lazy var serverUrlTextField: NewInputTextField = {
        let textField = NewInputTextField(frame: .zero)
        textField.placeholder = BundleI18n.Calendar.Calendar_Ex_PleaseEnter
        textField.backgroundColor = UIColor.ud.bgFloat
        textField.keyboardType = .asciiCapable
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        return textField
    }()

    private lazy var loginButton: NewLoadingButton = {
        let button = NewLoadingButton()
        button.text = BundleI18n.Calendar.Calendar_Common_Login
        button.textColor = UIColor.ud.primaryOnPrimaryFill
        return button
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        return stackView
    }()

    // 和下面的 helpLinkLabel 仅用作 serverurl 出错时报错
    private lazy var hintLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.cd.regularFont(ofSize: 14)
        label.textColor = UIColor.ud.colorfulRed
        return label
    }()

    private lazy var helpLinkLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.cd.regularFont(ofSize: 14)
        label.textColor = UIColor.ud.B700
        label.text = BundleI18n.Calendar.Calendar_Sync_HowToFindURL
        label.isHidden = true
        return label
    }()

    private lazy var noticeView: UDNotice = {
        let config = UDNoticeUIConfig(type: .info, attributedText: NSAttributedString())
        let noticeView = UDNotice(config: config)
        noticeView.delegate = self
        noticeView.layer.cornerRadius = 4
        return noticeView
    }()
}

extension NewImportExchangeViewController {
    private func handleLoginSuccess(_ success: ImportExchangeViewModel.LoginSuccess) {
        logger.info("login Success: \(success)")
        let targetView: UIView = self.view.window ?? self.view
        switch success {
        case .bindSuccess: UDToast.showSuccess(with: BundleI18n.Calendar.Calendar_EmailGuest_AccountAddedSuccessfully, on: targetView)
        case .alreadyBinded: UDToast.showSuccess(with: BundleI18n.Calendar.Calendar_Common_AccountAlreadyExists, on: targetView)
        }
        self.backItemTapped()
        self.viewModel.resultCallback?(.success(()))
    }

    private func handleLoginError(_ error: ImportExchangeViewModel.LoginError) {
        logger.warn("login error: \(error)")
        noticeView.isHidden = true
        hintLabel.isHidden = true
        helpLinkLabel.isHidden = true
        switch error {
        case .serverUrlNotConnectable:
            // 通用错误，展示在顶部
            noticeView.isHidden = false
            let text = BundleI18n.Calendar.Calendar_Ex_BadAddressPassword
            var config = UDNoticeUIConfig(type: .error, attributedText: NSAttributedString(string: text))
            noticeView.updateConfigAndRefreshUI(config)
        case .userNotAuthorized:
            // 通用错误，展示在顶部
            noticeView.isHidden = false
            let text = BundleI18n.Calendar.Calendar_Ex_WrongAddressPassword
            var config = UDNoticeUIConfig(type: .error, attributedText: NSAttributedString(string: text))
            noticeView.updateConfigAndRefreshUI(config)
        case .unknown:
            // 通用错误，展示在顶部
            noticeView.isHidden = false
            let text = BundleI18n.Calendar.Calendar_Sync_FailToVerifyEmailAndPassword
            var config = UDNoticeUIConfig(type: .error, attributedText: NSAttributedString(string: text))
            noticeView.updateConfigAndRefreshUI(config)
        case .forbidden:
            // 通用错误，展示在顶部
            noticeView.isHidden = false
            let content = BundleI18n.Calendar.Calendar_External_UnableAddCuzMSFTSecurityPolicy1
            let actionText = BundleI18n.Calendar.Calendar_External_UnableAddCuzMSFTSecurityPolicy2
            var config = UDNoticeUIConfig(type: .error, attributedText: NSAttributedString(string: content))
            config.leadingButtonText = actionText
            noticeView.updateConfigAndRefreshUI(config)
        case .emailInvalid:
            emailHintLabel.alpha = 1
            emailHintLabel.text = BundleI18n.Calendar.Calendar_Ex_AddressInvalid
          case .serverUrlNotExist:
            hintLabel.isHidden = false
            helpLinkLabel.isHidden = false
            hintLabel.text = BundleI18n.Calendar.Calendar_Sync_AddServerURLMobile
            helpLinkLabel.text = BundleI18n.Calendar.Calendar_Sync_HowToFindURL
          }
      }

    @objc
    private func gotoHelpUrl() {
        if let url = viewModel.helpUrl {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UDToast.showFailure(with: BundleI18n.Calendar.Calendar_Sync_FailedToRedirect, on: self.view)
        }
    }
}

extension NewImportExchangeViewController: UDNoticeDelegate {

    func handleLeadingButtonEvent(_ button: UIButton) {
        logger.info("handleLeadingButtonEvent")
        gotoHelpUrl()
    }

    func handleTrailingButtonEvent(_ button: UIButton) {
        logger.info("handleTrailingButtonEvent")
    }

    func handleTextButtonEvent(URL: URL, characterRange: NSRange) {
        logger.info("handleTextButtonEvent")
    }

}
