//
//  V3RecoverAccountBankViewController.swift
//  SuiteLogin
//
//  Created by tangyunfei.tyf on 2020/7/21.
//

import Foundation
import RxSwift
import LarkAlertController
import Homeric

class V3RecoverAccountBankViewController: BaseViewController {

    private let vm: V3RecoverAccountBankViewModel

    lazy var bankCardTextField: V3FlatTextField = {
        let textfield = V3FlatTextField(type: .default)
        textfield.delegate = self
        textfield.disableLabel = true
        textfield.textFieldFont = UIFont.systemFont(ofSize: 17)
        textfield.textFiled.returnKeyType = .done
        textfield.textFiled.keyboardType = .numberPad
        textfield.attributedPlaceholder = NSAttributedString(
            string: BundleI18n.suiteLogin.Lark_Login_RecoverAccountBankVerifyNumberPlaceholder,
            attributes: [
                .font: UIFont.systemFont(ofSize: 17),
                .foregroundColor: UIColor.ud.textPlaceholder
        ])
        return textfield
    }()

    lazy var mobileTextField: V3FlatTextField = {
        let textfield = V3FlatTextField(type: .default)
        textfield.delegate = self
        textfield.disableLabel = true
        textfield.textFieldFont = UIFont.systemFont(ofSize: 17)
        textfield.textFiled.returnKeyType = .done
        textfield.textFiled.keyboardType = .numberPad
        textfield.attributedPlaceholder = NSAttributedString(
            string: BundleI18n.suiteLogin.Lark_Login_RecoverAccountBankVerifyPhonePlaceholder,
            attributes: [
                .font: UIFont.systemFont(ofSize: 17),
                .foregroundColor: UIColor.ud.textPlaceholder
        ])
        return textfield
    }()

    init(vm: V3RecoverAccountBankViewModel) {
        self.vm = vm
        super.init(viewModel: vm)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupUI()
        self.setupNextButtonClickHandler()
    }

    func checkBtnDisable() {
        nextButton.isEnabled = self.vm.isNextButtonEnabled()
    }

    func setupUI() {
        configTopInfo(vm.title, detail: vm.subTitleInAttributedString)

        centerInputView.addSubview(bankCardTextField)
        bankCardTextField.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(Common.Layout.itemSpace)
            make.height.equalTo(CL.fieldHeight)
            make.top.equalTo(centerInputView)
        }

        centerInputView.addSubview(mobileTextField)
        mobileTextField.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(Common.Layout.itemSpace)
            make.height.equalTo(CL.fieldHeight)
            make.top.equalTo(bankCardTextField.snp.bottom).offset(Common.Layout.itemSpace)
            make.bottom.equalToSuperview()
        }

        NotificationCenter.default
        .rx.notification(UITextField.textDidChangeNotification)
        .subscribe(onNext: { [weak self] (_) in
            self?.refreshViewModel()
            self?.checkBtnDisable()
        }).disposed(by: disposeBag)

        nextButton.setTitle(I18N.Lark_Login_V3_NextStep, for: .normal)
    }

    func setupNextButtonClickHandler() {
        nextButton.rx.tap.subscribe { [unowned self] (_) in
            self.onNextStepClicked()
        }.disposed(by: disposeBag)
    }

    private func onNextStepClicked() {
        SuiteLoginTracker.track("bankcard_verify_next")
        self.showLoading()
        self.vm.onNextButtonClicked().subscribe(onNext: { [weak self] in
            self?.stopLoading()
            SuiteLoginTracker.track(Homeric.BANKCARD_VERIFY_RESULT, params: [
                "from": self?.vm.from.rawValue ?? "",
                "result": "success"
            ])
        }, onError: { [weak self] (err) in
            self?.handle(err)
            SuiteLoginTracker.track(Homeric.BANKCARD_VERIFY_RESULT, params: [
                "from": self?.vm.from.rawValue ?? "",
                "result": "fail"
            ])
        }).disposed(by: self.disposeBag)
    }

    private func refreshViewModel() {
        self.vm.bankCardNumber = bankCardTextField.text
        self.vm.mobileNumber = mobileTextField.text
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        bankCardTextField.becomeFirstResponder()
    }
}

extension V3RecoverAccountBankViewController: V3FlatTextFieldDelegate {
    func textFieldShouldReturn(_ textField: V3FlatTextField) -> Bool {
        if self.vm.isNextButtonEnabled() {
            self.onNextStepClicked()
        }
        return true
    }
}
