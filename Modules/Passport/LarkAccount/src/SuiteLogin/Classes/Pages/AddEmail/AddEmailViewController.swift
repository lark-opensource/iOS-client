//
//  AddEmailViewController.swift
//  LarkAccount
//
//  Created by Nix Wang on 2022/3/3.
//

import UIKit
import RxSwift
import SnapKit

class AddEmailViewController: BaseViewController {
    
    private lazy var mailTextField: V3FlatTextField = {
        let textfield = V3FlatTextField(type: .email)
        textfield.disableLabel = true
        textfield.textFieldFont = UIFont.systemFont(ofSize: 16)
        textfield.textFiled.returnKeyType = .done
        textfield.textFiled.clearButtonMode = .always
        textfield.delegate = self
        textfield.placeHolder = vm.addMailStepInfo.emailInput.placeholder
        return textfield
    }()
    
    lazy private var tipLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.numberOfLines = 0
        return label
    }()
    
    private let vm: AddEmailViewModel
    
    init(vm: AddEmailViewModel) {
        self.vm = vm
        super.init(viewModel: vm)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configInfo(vm.addMailStepInfo.title, detail: vm.addMailStepInfo.subtitle)
        tipLabel.attributedText = vm.addMailStepInfo.tip.html2Attributed(font: .systemFont(ofSize: 14), forgroundColor: UIColor.ud.textCaption)
        nextButton.setTitle(vm.addMailStepInfo.nextButton.text, for: .normal)
        
        centerInputView.addSubview(mailTextField)
        mailTextField.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(Common.Layout.itemSpace)
            make.height.equalTo(CL.fieldHeight)
            make.top.equalTo(centerInputView)
        }
        
        centerInputView.addSubview(tipLabel)
        tipLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(Common.Layout.itemSpace)
            make.top.equalTo(mailTextField.snp.bottom).offset(CL.bottomMargin)
            make.bottom.equalToSuperview()
        }
                
        if iPadUseCompactLayout {
            // iPad NextButton 跟随上面的元素
            moveBoddyView.addSubview(nextButton)
            nextButton.snp.makeConstraints { (make) in
                make.top.equalTo(centerInputView.snp.bottom).offset(CL.itemSpace * 2)
                make.top.equalTo(inputAdjustView.snp.bottom).offset(CL.itemSpace)
                make.left.right.equalToSuperview().inset(CL.itemSpace)
                make.height.equalTo(NextButton.Layout.nextButtonHeight48)
            }
        }
        
        nextButton.rx.tap.subscribe { [weak self] (_) in
            self?.logger.info("n_action_add_email_next")
            
            guard let self = self else { return }
            guard let mailAddress = self.mailTextField.text else { return }
            
            self.showLoading()
            self.vm.addMail(mailAddress)
                .subscribe(onError: { [weak self] (err) in
                    guard let self = self else { return }
                    self.stopLoading()
                    self.handle(err)
                }, onCompleted: { [weak self] in
                    self?.stopLoading()
                })
                .disposed(by: self.disposeBag)
        }.disposed(by: disposeBag)
        
        updateNextButton(mailTextField.text ?? "")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        mailTextField.becomeFirstResponder()
    }
    
    private func updateNextButton(_ emailAddress: String) {
        nextButton.isEnabled = NSPredicate(format: "SELF MATCHES %@", vm.inputConfig.emailRegex).evaluate(with: emailAddress)
    }

}

extension AddEmailViewController: V3FlatTextFieldDelegate {
    func textFieldShouldClear(_ textField: V3FlatTextField) -> Bool {
        nextButton.isEnabled = false
        return true
    }
    
    func textField(_ textField: V3FlatTextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        var text = textField.text ?? ""
        if let range = Range(range, in: text) {
            text.replaceSubrange(range, with: string)
            updateNextButton(text)
        }
        
        return true
    }
}
