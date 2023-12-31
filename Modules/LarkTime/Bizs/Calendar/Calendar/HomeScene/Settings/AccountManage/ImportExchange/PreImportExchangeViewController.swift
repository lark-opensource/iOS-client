//
//  PreImportExchangeViewController.swift
//  Calendar
//
//  Created by tuwenbo on 2022/8/9.
//

import Foundation
import UniverseDesignIcon
import UniverseDesignDialog
import UIKit
import SnapKit
import RxSwift
import RxRelay
import RxCocoa
import LarkUIKit
import CalendarFoundation
import UniverseDesignToast
import LKCommonsLogging
import LarkContainer

final class PreImportExchangeViewController: CalendarController, UserResolverWrapper {

    let userResolver: UserResolver

    private let viewModel: PreImportExchangeViewModel
    private let disposeBag = DisposeBag()
    private let logger = Logger.log(PreImportExchangeViewController.self, category: "calendar.PreImportExchangeViewController")

    // MARK: UI View
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        return stackView
    }()

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
        textField.layer.borderWidth = 0
        return textField
    }()

    private lazy var emailHintLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.colorfulRed
        label.text = BundleI18n.Calendar.Calendar_Ex_AddressInvalid
        label.font = UIFont.cd.regularFont(ofSize: 14)
        return label
    }()

    private lazy var nextButton: NewLoadingButton = {
        let button = NewLoadingButton()
        button.text = BundleI18n.Calendar.Calendar_Share_NextStep
        button.textColor = UIColor.ud.primaryOnPrimaryFill
        return button
    }()

    // MARK: LifeCycle
    init(userResolver: UserResolver, viewModel: PreImportExchangeViewModel) {
        self.userResolver = userResolver
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
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        emailTextField.becomeFirstResponder()
    }

    // MARK: Layout UI
    private func setupSubViews() {
        view.addSubview(stackView)
        stackView.spacing = 8
        stackView.addArrangedSubview(emailLabel)
        stackView.addArrangedSubview(emailTextField)
        stackView.addArrangedSubview(emailHintLabel)
        stackView.setCustomSpacing(4, after: emailTextField)
        view.addSubview(nextButton)
    }

    private func setupConstraints() {
        stackView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(18)
            make.leading.equalTo(16)
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

        nextButton.snp.makeConstraints { (make) in
            make.top.equalTo(stackView.snp.bottom).offset(4)
            make.leading.trailing.equalTo(stackView)
            make.height.equalTo(48)
        }
        nextButton.layer.cornerRadius = 10
    }

    // MARK: Bind
    private func bindViewModel() {
        viewModel.emailAddress.asObservable().bind(to: emailTextField.rx.text).disposed(by: disposeBag)
        emailTextField.rx.text.orEmpty.bind(to: viewModel.emailAddress).disposed(by: disposeBag)

        emailTextField.rx.controlEvent([.editingChanged])
            .asObservable()
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                self.emailHintLabel.alpha = 0
            }).disposed(by: disposeBag)

        viewModel.nextEnabled.bind(to: nextButton.rx.isEnabled).disposed(by: disposeBag)

        viewModel.discoveryResult
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] result in
                guard let `self` = self else { return }
                switch result {
                case .success(let success):
                    self.handleDiscoverySuccess(success)
                case .failure(let error):
                    self.handleDiscoveryError(error)
                }
            }).disposed(by: disposeBag)

        viewModel.nextLoading.subscribeForUI(onNext: {[weak self] loading in
            guard let self = self else { return }
            if loading {
                self.nextButton.buttonState = .loading
            } else {
                if self.nextButton.buttonState == .loading {
                    self.nextButton.buttonState = .normal
                }
            }
        }).disposed(by: disposeBag)
    }

    private func bindView() {
        nextButton.rx
            .controlEvent(.touchUpInside)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                self.viewModel.goNext()
            }).disposed(by: disposeBag)
    }

    // MARK: - Touch
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for case let view as NewInputTextField in stackView.arrangedSubviews {
            view.endEditing(true)
        }
    }
}

extension PreImportExchangeViewController {
    private func handleDiscoverySuccess(_ success: PreImportExchangeViewModel.DiscoveryExchangeAccountSuccess) {
        switch success {
        case .mayHaveOAuth(let exchangeAuthUrl):
            logger.info("discover success, mayHaveOAuth")
            let dialog = UDDialog()
            dialog.setContent(text: BundleI18n.Calendar.Calendar_Ex_PrivateVerSelect)
            dialog.addPrimaryButton(text: BundleI18n.Calendar.Calendar_Ex_OpenBrowser, dismissCompletion: {[weak self] in
                self?.logger.info("User click: Open web browser")
                self?.authenticateOnWeb(addr: exchangeAuthUrl)
            })
            dialog.addSecondaryButton(text: BundleI18n.Calendar.Calendar_Ex_ManualConfiguration, dismissCompletion: importExchangeAccount)
            dialog.addCancelButton()
            self.present(dialog, animated: true)
        case .noOAuth:
            logger.info("discover success, noOAuth")
            importExchangeAccount()
        }
    }

    private func handleDiscoveryError(_ error: PreImportExchangeViewModel.DiscoveryExchangeAccountError) {
        switch error {
        case .unknown:
            logger.warn("discover error, unknown")
            UDToast.showFailure(with: BundleI18n.Calendar.Calendar_G_NetworkError, on: self.view)
        case .emailInvalid:
            logger.warn("discover error, emailInvalid")
            emailHintLabel.alpha = 1
        }
    }

    private func authenticateOnWeb(addr: String) {
        if let url = URL(string: addr), !addr.isEmpty {
            UIApplication.shared.open(url, options: [:]) { [weak self] _ in
                guard let `self` = self else { return }
                self.backItemTapped()
            }
        } else {
            logger.error("Invalid auth Url!")
        }
    }

    private func importExchangeAccount() {
        logger.info("goto importExchangeAccount VC")
        let viewModel = ImportExchangeViewModel(userResolver: self.userResolver, defaultEmail: self.emailTextField.text ?? "") {[weak self] result in
            guard let `self` = self else { return }
            if case let .success = result {
                self.viewModel.resultCallback?(result)
            }
            self.backItemTapped()
        }
        let viewController = NewImportExchangeViewController(viewModel: viewModel)
        self.navigationController?.pushViewController(viewController, animated: true)
    }
}
