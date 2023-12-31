//
//  SetSpareCredentialViewController.swift
//  LarkAccount
//
//  Created by au on 2022/6/2.
//

import Homeric
import LarkUIKit
import RxCocoa
import RxSwift
import SnapKit
import UIKit

/// 设置备用验证方式
class SetSpareCredentialViewController: BaseViewController {
    
    let vm: SetSpareCredentialViewModel
    
    lazy var loginInputView: LoginInputView = {
        let config = LoginInputViewConfig(
            canChangeMethod: vm.canChangeMethod,
            defaultMethod: vm.method.value,
            topCountryList: vm.topCountryList,
            allowRegionList: vm.allowRegionList,
            blockRegionList: vm.blockRegionList,
            emailRegex: vm.emailRegex,
            credentialInputList: vm.credentialInputList
        )
        return LoginInputView(delegate: self, config: config)
    }()
    
    init(vm: SetSpareCredentialViewModel) {
        self.vm = vm
        super.init(viewModel: vm)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupInputView()
        updateViewLocale()
        setupSwitchLoginMethodHandler()
        setupNextButtonClickHandler()
        checkButtonDisable()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        let params = SuiteLoginTracker.makeCommonViewParams(flowType: vm.flowType)
        SuiteLoginTracker.track(TrackConst.passportBackupVerifySettingView, params: params)
        logger.info("n_page_set_spare_credential")
    }
    
    func handleNextStep() {
        logger.info("n_action_set_spare_credential_handle_next_step")
        view.endEditing(true)
        updateCredentialAndName()
        showLoading()
        vm.clickNextButton()
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                let backupType = self.vm.method.value == .phoneNumber ? "phone" : "mail"
                let params = SuiteLoginTracker.makeCommonClickParams(flowType: self.vm.flowType,
                                                                     click: "next", 
                                                                     target: TrackConst.passportVerifyCodeView,
                                                                     data: ["backup_type": backupType])
                SuiteLoginTracker.track(TrackConst.passportClickTrackBackupVerifySetting, params: params)
                self.stopLoading()
            }, onError: { [weak self] error in
                self?.handle(error)
            })
            .disposed(by: disposeBag)
    }
    
    private func updateViewLocale() {
        nextButton.setTitle(vm.nextButtonTitle, for: .normal)
        loginInputView.updateViewLocale()
        loginInputView.updateMobileRegion(regionCode: vm.credentialRegionCode.value)
        configTopInfo(vm.title, detail: vm.subtitle.html2Attributed(font: UIFont.systemFont(ofSize: 14), forgroundColor: UIColor.ud.textTitle))
    }
    
    private func updateCredentialAndName() {
        vm.credentialPhone.accept(loginInputView.phoneTextField.text ?? "")
        vm.credentialRegionCode.accept(loginInputView.phoneTextField.labelText ?? "")
        vm.credentialEmail.accept(loginInputView.emailTextField.currentText ?? "")
    }
    
    private func setupInputView() {
        centerInputView.addSubview(loginInputView)
        loginInputView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(Common.Layout.itemSpace)
            make.top.equalToSuperview()
            make.bottom.equalToSuperview().inset(CL.fieldBottom)
        }
        loginInputView.checkTextFieldFocus()
    }
    
    private func setupNextButtonClickHandler() {
        nextButton.rx
            .tap
            .subscribe { [weak self] _ in
                guard let self = self else { return }
                self.handleNextStep()
            }
            .disposed(by: disposeBag)
    }
    
    private func setupSwitchLoginMethodHandler() {
        vm.method
            .observeOn(MainScheduler.instance)
            .skip(1) // 忽略初始化的信号
            .subscribe(onNext: { [weak self] loginMethod in
                guard let self = self else { return }
                self.logger.info("n_action_set_spare_credential_change_cp_type", additionalData: ["type": "\(loginMethod)"])
                self.loginInputView.checkTextFieldFocus()
                self.checkButtonDisable()
            })
            .disposed(by: disposeBag)
    }
    
    private func checkButtonDisable() {
        nextButton.isEnabled = loginInputView.checkButtonDisable()
        stopLoading()
    }

}

extension SetSpareCredentialViewController: LoginInputSegmentViewDelegateProtocol {
    func mobileCodeSelectClick() {
        
    }
    
    func selectedMobileCode(_ mobileCode: MobileCode) {
        vm.credentialRegionCode.accept(mobileCode.code)
    }
    
    func needUpdateButton(enable: Bool) {
        nextButton.isEnabled = enable
    }
    
    func inputMethodChange(method: SuiteLoginMethod) {
        let click = method == .phoneNumber ? "switch_to_phone" : "switch_to_mail"
        let params = SuiteLoginTracker.makeCommonClickParams(flowType: vm.flowType, click: click, target: TrackConst.passportVerifyCodeView)
        SuiteLoginTracker.track(TrackConst.passportClickTrackBackupVerifySetting, params: params)
        
        vm.method.accept(method)
    }
    
    func didTapReturnButton() {
        guard loginInputView.checkButtonDisable() else { return }
        handleNextStep()
    }
}
