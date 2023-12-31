//
//  CustomPasswordViewController.swift
//  SKCommon
//
//  Created by Weston Wu on 2023/11/28.
//

import Foundation
import SKUIKit
import UniverseDesignInput
import UniverseDesignToast
import UniverseDesignColor
import SKResource
import SKFoundation
import RxSwift
import RxCocoa

class CustomPasswordViewController: UIViewController {

    private let viewModel: CustomPasswordViewModel
    private let disposeBag = DisposeBag()

    private var ignoreShouldChangeEvent = false

    private lazy var backgroundControl: UIControl = {
        let view = UIControl()
        view.backgroundColor = .clear
        view.addTarget(self, action: #selector(onTouchBackground), for: .touchDown)
        return view
    }()

    private lazy var naviBar: PasswordNaviBar = {
        let view = PasswordNaviBar()
        return view
    }()

    private lazy var stackView: UIStackView = {
        let view = PassThroughStackView()
        view.axis = .vertical
        view.spacing = 4
        view.alignment = .fill
        view.distribution = .fill
        return view
    }()

    private lazy var headerView: PasswordHeaderView = {
        let view = PasswordHeaderView()
        return view
    }()

    private lazy var textField: UDTextField = {
        var config = UDTextFieldUIConfig(isShowBorder: true,
                                         clearButtonMode: .whileEditing,
                                         font: .systemFont(ofSize: 16))
        config.backgroundColor = UDColor.udtokenComponentOutlinedBg
        config.borderActivatedColor = UDColor.primaryContentDefault
        let textField = UDTextField(config: config)
        textField.placeholder = BundleI18n.SKResource.LarkCCM_CM_CustomPassword_EnterNew_Placeholder
        textField.delegate = self
        textField.input.addTarget(self, action: #selector(textFieldEditingChanged), for: .editingChanged)
        textField.input.autocapitalizationType = .none
        textField.input.autocorrectionType = .no
        textField.input.spellCheckingType = .no
        textField.input.keyboardType = .asciiCapable
        textField.input.returnKeyType = .done
        textField.input.textContentType = .password
        return textField
    }()

    private lazy var levelIndicatorView: PasswordLevelIndicatorView = {
        let view = PasswordLevelIndicatorView(levelModel: viewModel.levelModel, externalVisableDriver: viewModel.passDriver)
        return view
    }()

    private lazy var divider: UIView = {
        let container = UIView()
        let view = UIView()
        view.backgroundColor = UDColor.lineDividerDefault
        container.addSubview(view)
        view.snp.makeConstraints { make in
            make.height.equalTo(0.5)
            make.left.right.equalToSuperview()
            make.top.bottom.equalToSuperview().inset(8)
        }
        return container
    }()

    private lazy var tipsLabel: UILabel = {
        let label = UILabel()
        label.textColor = UDColor.textCaption
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 14)
        label.text = BundleI18n.SKResource.LarkCCM_CM_CustomPassword_AvoidPersonalInfoInAPassword_Desc

        return label
    }()

    private var hasAppeared = false
    // nil 表示用户 cancel
    var updateCallback: ((String?) -> Void)?
    private var callbackCalled = false
    private var tracker = CustomPasswordTracker()

    init(viewModel: CustomPasswordViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        if !callbackCalled {
            // 通知一个取消事件
            updateCallback?(nil)
            tracker.reportCancel()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupEvents()
        tracker.reportView()
    }

    private func setupUI() {
        view.backgroundColor = UDColor.bgBase

        view.addSubview(backgroundControl)
        backgroundControl.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        view.addSubview(naviBar)
        naviBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.right.equalToSuperview()
        }

        view.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.top.equalTo(naviBar.snp.bottom).offset(16)
            make.left.right.equalToSuperview().inset(16)
        }

        stackView.addArrangedSubview(headerView)
        stackView.setCustomSpacing(12, after: headerView)
        stackView.addArrangedSubview(textField)
        stackView.setCustomSpacing(12, after: textField)
        stackView.addArrangedSubview(levelIndicatorView)
        setupRequirementViews()
        stackView.addArrangedSubview(divider)
        stackView.addArrangedSubview(tipsLabel)
    }

    private func setupRequirementViews() {
        let subModels = viewModel.getSubModels()
        subModels.forEach { model in
            let view = PasswordRequirementView(viewModel: model)
            stackView.addArrangedSubview(view)
        }
    }

    private func setupEvents() {
        naviBar.cancelButton.rx.tap.asSignal().emit(onNext: { [weak self] in
            self?.dismiss(animated: true)
        })
        .disposed(by: disposeBag)

        naviBar.saveButton.rx.tap.asSignal().emit(onNext: { [weak self] in
            self?.didClickSave()
        })
        .disposed(by: disposeBag)

        headerView.randomButton.rx.tap.asSignal().emit(onNext: { [weak self] in
            self?.generateRandomPassword()
        })
        .disposed(by: disposeBag)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if hasAppeared { return }
        hasAppeared = true
        textField.becomeFirstResponder()
    }

    private func didClickSave() {
        textField.resignFirstResponder()
        let isShowingWarning = viewModel.showingWarning
        let password = textField.text ?? ""
        viewModel.commit(password: password)
        guard viewModel.pass else {
            if isShowingWarning {
                UDToast.showFailure(with: BundleI18n.SKResource.LarkCCM_CM_CustomPassword_PasswordDoesntMeetRequirements_Toast,
                                    on: view.window ?? view)
            }
            return
        }
        UDToast.showLoading(with: BundleI18n.SKResource.LarkCCM_CM_CustomPassword_Saving_Toast,
                            on: view.window ?? view,
                            disableUserInteraction: true)
        viewModel.save(password: password).subscribe { [weak self] in
            guard let self else { return }
            UDToast.showSuccess(with: BundleI18n.SKResource.LarkCCM_CM_CustomPassword_PasswordChanged_Toast,
                                on: self.view.window ?? self.view)
            self.updateCallback?(password)
            self.callbackCalled = true
            self.tracker.reportSave(result: .success)
            self.dismiss(animated: true)
        } onError: { [weak self] error in
            DocsLogger.error("save password failed", error: error)
            guard let self else { return }
            guard DocsNetStateMonitor.shared.isReachable else {
                UDToast.showFailure(with: BundleI18n.SKResource.Doc_Facade_NetworkInterrutedRetry,
                                    on: self.view.window ?? self.view)
                return
            }
            guard let docsError = error as? DocsNetworkError else {
                UDToast.showFailure(with: BundleI18n.SKResource.LarkCCM_CM_CustomPassword_SaveFailed_Toast,
                                    on: self.view.window ?? self.view)
                self.tracker.reportSave(result: .otherFailed(code: -1))
                return
            }
            switch docsError.code {
            // 文档已关闭加密链接分享，无法保存
            case .customPasswordError:
                UDToast.showFailure(with: BundleI18n.SKResource.LarkCCM_CM_CustomPassword_DocsTurnedOffSharingViaLink_Toast,
                                    on: self.view.window ?? self.view)
                self.tracker.reportSave(result: .otherFailed(code: docsError.code.rawValue))
            // 密码过于简单
            case .saveDocsPasswordFailed:
                UDToast.showFailure(with: BundleI18n.SKResource.LarkCCM_CM_CustomPassword_PasswordTooWeak_Toast,
                                    on: self.view.window ?? self.view)
                self.tracker.reportSave(result: .weakPassword)
            default:
                UDToast.showFailure(with: BundleI18n.SKResource.LarkCCM_CM_CustomPassword_SaveFailed_Toast,
                                    on: self.view.window ?? self.view)
                self.tracker.reportSave(result: .otherFailed(code: docsError.code.rawValue))
            }
        }
        .disposed(by: disposeBag)
    }

    private func generateRandomPassword() {
        textField.resignFirstResponder()
        UDToast.showDefaultLoading(on: view.window ?? view)
        viewModel.getRandomPassword()
            .subscribe { [weak self] password in
                guard let self else { return }
                UDToast.removeToast(on: self.view.window ?? self.view)
                self.textField.text = password
                self.viewModel.commit(password: password)
                self.tracker.reportGeneratedRandomPassword()
            } onError: { [weak self] error in
                guard let self else { return }
                DocsLogger.error("get random password failed", error: error)
                if DocsNetStateMonitor.shared.isReachable {
                    UDToast.showFailure(with: BundleI18n.SKResource.LarkCCM_CM_CustomPassword_GenerationFailed_Toast,
                                        on: self.view.window ?? self.view)
                } else {
                    UDToast.showFailure(with: BundleI18n.SKResource.Doc_Facade_NetworkInterrutedRetry,
                                        on: self.view.window ?? self.view)
                }

            }
        .disposed(by: disposeBag)
    }

    @objc
    private func onTouchBackground() {
        textField.resignFirstResponder()
        let password = textField.text ?? ""
        viewModel.commit(password: password)
    }
}

extension CustomPasswordViewController: UDTextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        let password = textField.text ?? ""
        viewModel.commit(password: password)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if ignoreShouldChangeEvent { return true }
        let characterSet = CharacterSet.whitespacesAndNewlines
        // 如果 string 包含空白字符、换行符，不允许输入
        if string.unicodeScalars.contains(where: { characterSet.contains($0) }) {
            var newString = string
            newString.unicodeScalars.removeAll(where: characterSet.contains)
            // 自动化测试遇到 setText 后重复触发 shouldChange 事件导致 crash，尝试加个 flag 绕过这个问题
            ignoreShouldChangeEvent = true
            if let currentString = textField.text as? NSString {
                textField.text = currentString.replacingCharacters(in: range, with: newString)
            } else {
                textField.text = newString
            }
            ignoreShouldChangeEvent = false
            return false
        }
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        didClickSave()
        return false
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        viewModel.reset()
        return true
    }

    @objc
    private func textFieldEditingChanged() {
        let text = textField.text ?? ""
        if text.isEmpty {
            viewModel.reset()
        } else {
            viewModel.edit(password: text)
        }
        tracker.reportEdit()
    }
}
