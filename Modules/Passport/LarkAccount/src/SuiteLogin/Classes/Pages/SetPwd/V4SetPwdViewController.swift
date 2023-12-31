//
//  V4SetPwdViewController.swift
//  LarkAccount
//
//  Created by dengbo on 2021/6/7.
//

import UIKit
import RxSwift
import Homeric
import LarkPerf
import UniverseDesignToast

protocol V4SetPwdProtocol {
    var title: String { get }
    var subtitle: String { get }
    var password: String { get set }
    var pageName: String? { get }
    var placeHolder: String { get }
    var confirmPlaceholder: String { get }
    var strengthDescription: String { get }
    var nextTitle: String { get }
    var doubleConfirm: Bool { get }
    var canSkip: Bool { get }
    var canBack: Bool { get }
    var skipTips: String { get }
    var pwdErrorToast: String { get }
    var flowType: String? { get }

    func setPwd() -> Observable<Void>
    func skipSetPwd() -> Observable<Void>
    func isValidPassword(_ pwd: String) -> Bool
    func checkPassword(_ pwd: String) -> PasswordStrength
}

typealias V4SetPwdVM = V3ViewModel & V4SetPwdProtocol

class V4SetPwdViewController: BaseViewController {

    private var vm: V4SetPwdVM
    private var firstPwd: String = ""
    private var secondPwd: String = ""
    private let stackView = UIStackView()
    
    init(vm: V4SetPwdVM) {
        self.vm = vm
        super.init(viewModel: vm)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var passwordField: ALPasswordTextField = {
        let field = ALPasswordTextField(
            placeholder: vm.placeHolder,
            textChangeBlock: { [weak self] (value) in
                guard let self = self else { return }
                self.firstPwd = value ?? ""
                self.updateBtn()
                self.updatePasswordChecker()
            },
            returnBtnClickedBlock: { [weak self] _ in
                guard let self = self else { return }
                if self.vm.doubleConfirm {
                    self.confirmField.becomeFirstResponder()
                } else {
                    if self.nextButton.isEnabled {
                        self.setPwd()
                    }
                }
            },
            autoBecomeFirstResponder: false
        )
        
        field.endEditingBlock = { [weak self] _ in
            guard let self = self else { return }
            self.updatePasswordChecker()
        }
        field.returnKeyType = vm.doubleConfirm ? .next : .done
        field.snp.makeConstraints { (make) in
            make.height.equalTo(CL.fieldHeight)
        }
        return field
    }()
    
    private lazy var passwordCheckerView: PasswordCheckerView = {
        let checkerView = PasswordCheckerView()
        checkerView.strengthDescription = vm.strengthDescription
        return checkerView
    }()

    private lazy var confirmField: ALPasswordTextField = {
        let field = ALPasswordTextField(
            placeholder: vm.confirmPlaceholder,
            textChangeBlock: { [weak self] value in
                guard let self = self else { return }
                self.secondPwd = value ?? ""
                self.updateBtn()
                self.updatePasswordChecker()
            },
            returnBtnClickedBlock: { [weak self] _ in
                guard let self = self else { return }
                if self.nextButton.isEnabled {
                    self.setPwd()
                }
            },
            autoBecomeFirstResponder: false
        )
        field.returnKeyType = .done
        field.endEditingBlock = { [weak self] _ in
            guard let self = self else { return }
            self.updatePasswordChecker()
        }
        field.snp.makeConstraints { (make) in
            make.height.equalTo(CL.fieldHeight)
        }
        return field
    }()
    
    private lazy var confirmCheckerView: PasswordCheckerView = {
        let checkerView = PasswordCheckerView()
        checkerView.strengthDescription = vm.strengthDescription
        return checkerView
    }()

    private lazy var skipButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(vm.skipTips, for: .normal)
        button.setTitleColor(UIColor.ud.colorfulBlue, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16.0, weight: .medium)
        button.titleLabel?.textAlignment = .center
        button.rx.tap.subscribe(onNext: { [weak self] () in
            guard let self = self else { return }
            self.logger.info("n_action_set_pwd_later")
            let params = SuiteLoginTracker.makeCommonClickParams(flowType: self.vm.stepInfo.flowType ?? "", click: "later_set", target: TrackConst.passportSuccessCreateTeamView)
            SuiteLoginTracker.track(Homeric.PASSPORT_PWD_SETTING_CLICK, params: params)
            self.skipSetPwd()
        }).disposed(by: disposeBag)
        return button
    }()

    private lazy var closeButton = { UIButton(type: .custom) }()

    override func viewDidLoad() {
        super.viewDidLoad()
        configInfo(vm.title, detail: vm.subtitle)
        
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.addArrangedSubview(passwordField)
        stackView.addArrangedSubview(passwordCheckerView)
        stackView.setCustomSpacing(CL.itemSpace, after: passwordCheckerView)
        if vm.doubleConfirm {
            stackView.addArrangedSubview(confirmField)
            stackView.addArrangedSubview(confirmCheckerView)
        }
        
        centerInputView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.right.left.equalToSuperview().inset(CL.itemSpace)
            make.bottom.lessThanOrEqualToSuperview().inset(CL.itemSpace)
        }

        nextButton.setTitle(vm.nextTitle, for: .normal)
    
        nextButton.rx.tap.subscribe(onNext: { [weak self] () in
            guard let self = self else { return }
            self.logger.info("n_action_set_pwd_next", method: .local)
            let params = SuiteLoginTracker.makeCommonClickParams(flowType: self.vm.stepInfo.flowType ?? "", click: "next", target: TrackConst.passportSuccessCreateTeamView)
            SuiteLoginTracker.track(Homeric.PASSPORT_PWD_SETTING_CLICK, params: params)
            self.setPwd()
        }).disposed(by: disposeBag)
        
        updatePasswordChecker()

        PassportMonitor.flush(PassportMonitorMetaStep.setPasswordEnter,
                eventName: ProbeConst.monitorEventName,
                categoryValueMap: [ProbeConst.flowType: vm.flowType],
                context: vm.context)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        beginEdit()
        if let page = vm.pageName {
            SuiteLoginTracker.track(page)
        }
        let params = SuiteLoginTracker.makeCommonViewParams(flowType: vm.stepInfo.flowType ?? "")
        SuiteLoginTracker.track(Homeric.PASSPORT_PWD_SETTING_VIEW, params: params)
        logger.info("n_page_set_pwd_start", method: .local)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addCloseButton()
        addSkipButtonIfNeeded()
        hideBackBtnIfNeeded()
    }

    func addCloseButton() {
        guard vm.canSkip else { return }
        
        setBackBtnHidden(true)

        guard closeButton.superview == nil else { return }
        closeButton.setImage(BundleResources.UDIconResources.closeOutlined, for: .normal)
        closeButton.rx.controlEvent(.touchUpInside).observeOn(MainScheduler.instance).subscribe { [weak self] (_) in
            guard let self = self else { return }
            let params = SuiteLoginTracker.makeCommonClickParams(flowType: self.vm.stepInfo.flowType ?? "", click: "close", target: TrackConst.passportSuccessCreateTeamView)
            SuiteLoginTracker.track(Homeric.PASSPORT_PWD_SETTING_CLICK, params: params)
            self.logger.info("close button click")
            self.skipSetPwd()
        }.disposed(by: self.disposeBag)
        view.addSubview(closeButton)
        closeButton.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(CL.itemSpace)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(CL.backButtonTopSpace)
            make.size.equalTo(CGSize(width: BaseLayout.backHeight, height: BaseLayout.backHeight))
        }
    }

    func addSkipButtonIfNeeded() {
        guard vm.canSkip else { return }

        view.addSubview(skipButton)
        skipButton.snp.makeConstraints { (make) in
            make.right.equalToSuperview().inset(CL.itemSpace)
            let navigationBarHeight = self.navigationController?.navigationBar.frame.size.height ?? 0
            var offset = (navigationBarHeight - BaseLayout.backHeight) / 2
            if offset < 0 || !hasBackPage {
                offset = CL.backButtonTopSpace
            }
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(offset)
            make.height.equalTo(BaseLayout.backHeight)
        }
    }
    
    func hideBackBtnIfNeeded() {
        if !vm.canSkip && !vm.canBack { //不能跳过的话, 也不能返回
            setBackBtnHidden(true)
            if #available(iOS 13.0, *), self.isInFormSheet {
                self.isModalInPresentation = true
            }
        }
    }

    override func clickBackOrClose(isBack: Bool) {
        PassportMonitor.flush(PassportMonitorMetaStep.setPasswordCancel,
                              eventName: ProbeConst.monitorEventName,
                              categoryValueMap: [ProbeConst.flowType: vm.flowType],
                              context: vm.context)
        super.clickBackOrClose(isBack: isBack)
    }

    func setPwd() {
        view.endEditing(true)
        
        if vm.doubleConfirm && firstPwd != secondPwd {
            return
        }

        if !vm.isValidPassword(firstPwd) && !vm.pwdErrorToast.isEmpty {
            UDToast.showFailure(with: vm.pwdErrorToast, on: self.view)
            return
        }
        PassportMonitor.flush(PassportMonitorMetaStep.startSetPasswordCommit,
                              eventName: ProbeConst.monitorEventName,
                              categoryValueMap: [ProbeConst.flowType: self.vm.flowType],
                              context: self.vm.context)
        let startTime = Date()
        showLoading()
        vm.setPwd().observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.stopLoading()
                PassportMonitor.monitor(PassportMonitorMetaStep.setPasswordCommitResult,
                                              eventName: ProbeConst.monitorEventName,
                                              categoryValueMap: [ProbeConst.flowType: self.vm.flowType,
                                                                 ProbeConst.duration: Int(Date().timeIntervalSince(startTime) * 1000)],
                                              context: self.vm.context)
                .setResultTypeSuccess()
                .flush()
            }, onError: { [weak self] error in
                guard let self = self else { return }
                self.stopLoading()
                self.handle(error)
                self.clearInput()
                // showloading 会end edit
                self.beginEdit()
                PassportMonitor.monitor(PassportMonitorMetaStep.setPasswordCommitResult,
                                              eventName: ProbeConst.monitorEventName,
                                              categoryValueMap: [ProbeConst.flowType: self.vm.flowType],
                                              context: self.vm.context)
                .setResultTypeFail()
                .setPassportErrorParams(error: error)
                .flush()
            }).disposed(by: disposeBag)
    }
    
    func updatePasswordChecker() {
        // Password checker
        let pwd = passwordField.textFieldView.text ?? ""
        if pwd.isEmpty || (passwordField.textFieldView.isFirstResponder && !vm.isValidPassword(pwd)) {
            passwordCheckerView.isHidden = true
            stackView.setCustomSpacing(CL.itemSpace, after: self.passwordField)
        } else {
            passwordCheckerView.isHidden = false
            passwordCheckerView.strength = vm.checkPassword(pwd)
            stackView.setCustomSpacing(4, after: self.passwordField)
        }
        
        // Confirm checker
        if vm.doubleConfirm {
            confirmCheckerView.isHidden = true
            if !confirmField.textFieldView.isFirstResponder,
               let password = passwordField.textFieldView.text,
               let confirm = confirmField.textFieldView.text {
                if vm.isValidPassword(password) && !confirm.isEmpty && password != confirm {
                    confirmCheckerView.isHidden = false
                    confirmCheckerView.strength = .invalid(I18N.Lark_Passportweb_DoubleCheckFail)
                }
            }
        }
    }

    func skipSetPwd() {
        PassportMonitor.flush(PassportMonitorMetaStep.startSetPasswordSkip,
                              eventName: ProbeConst.monitorEventName,
                              categoryValueMap: [ProbeConst.flowType: self.vm.flowType],
                              context: self.vm.context)
        let startTime = Date()
        showLoading()
        vm.skipSetPwd().observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.stopLoading()
                PassportMonitor.monitor(PassportMonitorMetaStep.setPasswordSkipResult,
                                              eventName: ProbeConst.monitorEventName,
                                              categoryValueMap: [ProbeConst.flowType: self.vm.flowType,
                                                                 ProbeConst.duration: Int(Date().timeIntervalSince(startTime) * 1000)],
                                              context: self.vm.context)
                .setResultTypeSuccess()
                .flush()
            }, onError: { [weak self] error in
                guard let self = self else { return }
                self.stopLoading()
                self.handle(error)
                self.clearInput()
                // showloading 会end edit
                self.beginEdit()
                PassportMonitor.monitor(PassportMonitorMetaStep.setPasswordSkipResult,
                                              eventName: ProbeConst.monitorEventName,
                                              categoryValueMap: [ProbeConst.flowType: self.vm.flowType],
                                              context: self.vm.context)
                .setResultTypeFail()
                .setPassportErrorParams(error: error)
                .flush()
            }).disposed(by: disposeBag)
    }

    func clearInput() {
        self.passwordField.textFieldView.text = ""
        self.confirmField.textFieldView.text = ""
        self.passwordField.textFieldView.sendActions(for: UIControl.Event.editingChanged)
        self.passwordField.textFieldView.becomeFirstResponder()
        self.confirmField.textFieldView.sendActions(for: UIControl.Event.editingChanged)
        self.nextButton.isEnabled = false
    }

    func beginEdit() {
        passwordField.becomeFirstResponder()
    }

    func updateBtn() {
        self.vm.password = firstPwd

        let passwordValid = vm.isValidPassword(firstPwd)
        
        if vm.doubleConfirm {
            self.nextButton.isEnabled = passwordValid && !secondPwd.isEmpty
        } else {
            self.nextButton.isEnabled = passwordValid
        }
    }

    override func needSwitchButton() -> Bool { false }
}
