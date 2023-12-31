//
//  V3SetPwdViewController.swift
//  SuiteLogin
//
//  Created by Yiming Qu on 2019/12/6.
//

import UIKit
import RxSwift
import Homeric
import LarkPerf
import UniverseDesignToast

protocol V3SetPwdProtocol {
    var title: String { get }
    var subtitle: String { get }
    var password: String { get set }
    var pageName: String? { get }
    var placeHolder: String { get }
    var nextTitle: String { get }
    var doubleConfirm: Bool { get }

    func setPwd() -> Observable<Void>
}

extension V3SetPwdProtocol {
    var nextTitle: String {
        I18N.Lark_Login_V3_NextStep
    }
}

typealias SetPwdViewModel = V3ViewModel & V3SetPwdProtocol

class V3SetPwdViewController: BaseViewController {

    private var vm: SetPwdViewModel
    private var firstPwd: String = ""
    private var secondPwd: String = ""

    init(vm: SetPwdViewModel) {
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
        field.returnKeyType = vm.doubleConfirm ? .next : .done
        return field
    }()

    private lazy var confirmField: ALPasswordTextField = {
        let field = ALPasswordTextField(
            placeholder: I18N.Lark_Passport_ReEnterNewPSHintPC,
            textChangeBlock: { [weak self] value in
                guard let self = self else { return }
                self.secondPwd = value ?? ""
                self.updateBtn()
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
        return field
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        configInfo(vm.title, detail: vm.subtitle)

        centerInputView.addSubview(passwordField)
        passwordField.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.height.equalTo(CL.fieldHeight)
            make.right.left.equalToSuperview().inset(CL.itemSpace)
            if !vm.doubleConfirm {
                make.bottom.lessThanOrEqualToSuperview().inset(CL.itemSpace)
            }
        }

        if vm.doubleConfirm {
            centerInputView.addSubview(confirmField)
            confirmField.snp.makeConstraints { (make) in
                make.top.equalTo(passwordField.snp.bottom).offset(CL.itemSpace)
                make.height.equalTo(CL.fieldHeight)
                make.right.left.equalToSuperview().inset(CL.itemSpace)
                make.bottom.lessThanOrEqualToSuperview().inset(CL.itemSpace)
            }
        }

        nextButton.setTitle(vm.nextTitle, for: .normal)

        nextButton.rx.tap.subscribe(onNext: { [weak self] () in
            guard let self = self else { return }
            self.logger.info("verify next button click")
            self.setPwd()
        }).disposed(by: disposeBag)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        beginEdit()
        if let page = vm.pageName {
            SuiteLoginTracker.track(page)
        }
    }

    func setPwd() {
        if vm.doubleConfirm && firstPwd != secondPwd {
            clearInput()
            UDToast.showToast(with: UDToastConfig(toastType: .error, text: I18N.Lark_Passport_PSWordNotSameToastPC, operation: nil), on: self.view)
            return
        }

        showLoading()
        vm.setPwd().observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.stopLoading()
            }, onError: { [weak self] error in
                guard let self = self else { return }
                self.stopLoading()
                self.handle(error)
                self.clearInput()
                // showloading 会end edit
                self.beginEdit()
            }).disposed(by: disposeBag)
    }

    func clearInput() {
        self.passwordField.textFieldView.text = ""
        self.confirmField.textFieldView.text = ""
        self.passwordField.textFieldView.sendActions(for: UIControl.Event.editingChanged)
        self.confirmField.textFieldView.sendActions(for: UIControl.Event.editingChanged)
        self.nextButton.isEnabled = false
    }

    func beginEdit() {
        passwordField.becomeFirstResponder()
    }

    func updateBtn() {
        self.vm.password = firstPwd

        if vm.doubleConfirm {
            self.nextButton.isEnabled = !firstPwd.isEmpty && !secondPwd.isEmpty
        } else {
            self.nextButton.isEnabled = !firstPwd.isEmpty
        }
    }

    override func needSwitchButton() -> Bool { false }
}
