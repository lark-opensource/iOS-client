//
//  V3SetInputCredentialViewController.swift
//  SuiteLogin
//
//  Created by tangyunfei.tyf on 2020/7/21.
//

import Foundation
import RxSwift
import LarkAlertController
import Homeric

class V3SetInputCredentialViewController: BaseViewController {

    private let vm: V3SetInputCredentialViewModel

    lazy var mobileTextField: V3FlatTextField = {
        let textfield = V3FlatTextField(type: .default)
        textfield.disableLabel = true
        textfield.textFieldFont = UIFont.systemFont(ofSize: 17)
        textfield.textFiled.returnKeyType = .done
        textfield.textFiled.keyboardType = .phonePad
        textfield.attributedPlaceholder = NSAttributedString(
            string: BundleI18n.suiteLogin.Lark_Login_RecoverAccountNewPhoneNumberPlaceholder,
            attributes: [
                .font: UIFont.systemFont(ofSize: 17),
                .foregroundColor: UIColor.ud.textPlaceholder
        ])
        return textfield
    }()

    init(vm: V3SetInputCredentialViewModel) {
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

        logger.info("n_page_old_new_credential_start")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        mobileTextField.becomeFirstResponder()
    }

    func checkBtnDisable() {
        nextButton.isEnabled = self.vm.isNextButtonEnabled()
    }

    func setupUI() {
        configTopInfo(vm.title, detail: vm.subTitleInAttributedString)

        centerInputView.addSubview(mobileTextField)
        mobileTextField.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(Common.Layout.itemSpace)
            make.height.equalTo(CL.fieldHeight)
            make.top.equalTo(centerInputView)
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

            self.logger.info("n_action_old_new_credential_next")
            self.logger.info("n_action_old_new_credential_next_req")
            self.showLoading()
            self.vm.onNextButtonClicked().subscribe(onNext: { [weak self] in
                self?.stopLoading()
                self?.logger.info("n_action_old_new_credential_succ")
                SuiteLoginTracker.track(Homeric.SET_PHONE_NUMBER_NEXT, params: [
                    "from": self?.vm.from.rawValue ?? "",
                    "result": "success"
                ])
            }, onError: { [weak self] (err) in
                self?.logger.error("n_action_old_new_credential_fail", error: err)
                self?.handle(err)
                SuiteLoginTracker.track(Homeric.SET_PHONE_NUMBER_NEXT, params: [
                    "from": self?.vm.from.rawValue ?? "",
                    "result": "fail"
                ])
            }).disposed(by: self.disposeBag)
        }.disposed(by: disposeBag)
    }

    private func refreshViewModel() {
        self.vm.mobileNumber = mobileTextField.text
    }
}
