//
//  V3SetNameViewController.swift
//  SuiteLogin
//
//  Created by quyiming on 2020/1/1.
//

import Foundation
import RxSwift
import SnapKit
import Homeric
import UIKit
import UniverseDesignToast

class V3SetNameViewController: BaseViewController {

    private var nameTextFields = [V3FlatTextField]()

    private let vm: V3SetNameViewModel

    private lazy var optInCheckbox: V3Checkbox = {
        let checkbox = V3Checkbox(iconSize: CL.checkBoxSize)
        checkbox.hitTestEdgeInsets = CL.checkBoxInsets
        checkbox.rx
            .controlEvent(UIControl.Event.valueChanged)
            .subscribe { _ in }
            .disposed(by: disposeBag)
        return checkbox
    }()

    private lazy var optInLabel: LinkClickableLabel = {
        let label = LinkClickableLabel.default(with: self)
        label.textContainerInset = .zero
        label.textContainer.lineFragmentPadding = 0
        return label
    }()

    init(vm: V3SetNameViewModel) {
        self.vm = vm
        super.init(viewModel: vm)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        nextButton.setTitle(vm.nextButtonText, for: .normal)
        configTopInfo(vm.title, detail: vm.subtitle)

        let stackView = UIStackView()
        stackView.axis = .vertical

        for inputInfo in vm.nameInputs {
            if let labelText = inputInfo.label, labelText.count > 0 {
                let label = makeNameLabel(text: labelText)
                stackView.addArrangedSubview(label)
                stackView.setCustomSpacing(8, after: label)
            }

            let textField = makeNameTextField(inputInfo: inputInfo)
            textField.snp.makeConstraints { make in
                make.height.equalTo(CL.fieldHeight)
            }
            stackView.addArrangedSubview(textField)
            stackView.setCustomSpacing(16, after: textField)
            nameTextFields.append(textField)
        }
        nameTextFields.last?.textFiled.returnKeyType = .done

        self.logger.info("n_action_set_name_show_opt_in", additionalData: ["show_opt_in": vm.showOptIn])
        if vm.showOptIn {
            let optInWrapper = UIView()


            let attributedText = NSAttributedString.tip(str: vm.optTitle, color: UIColor.ud.N500, font: .systemFont(ofSize: 14.0), aligment: .left)
            optInLabel.attributedText = attributedText
            optInWrapper.addSubview(optInLabel)
            optInWrapper.addSubview(optInCheckbox)

            optInCheckbox.snp.remakeConstraints { make in
                make.size.equalTo(CL.checkBoxSize)
                make.leading.equalToSuperview()
                make.bottom.equalTo(optInLabel.snp.firstBaseline).offset(CL.checkBoxYOffset)
            }

            optInLabel.snp.remakeConstraints { make in
                make.leading.equalTo(optInCheckbox.snp.trailing).offset(CL.processTipTopSpace)
                make.top.trailing.bottom.equalToSuperview()
            }
            stackView.addArrangedSubview(optInWrapper)

            // 这个 view 会盖在 centerInputView 上，影响点击
            switchButtonContainer.isHidden = true
        }

        centerInputView.addSubview(stackView)
        stackView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(Common.Layout.itemSpace)
            make.top.equalToSuperview()
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
            guard let self = self else { return }
            self.logger.info("click set name")
            SuiteLoginTracker.track(Homeric.SET_NAME_CLICK_NEXT, params: [TrackConst.setNameType: self.vm.setNameInfo.flowType])
            let params = SuiteLoginTracker.makeCommonClickParams(flowType: self.vm.setNameInfo.flowType ?? "", click: "next", target: "none")
            SuiteLoginTracker.track(Homeric.PASSPORT_USER_NAME_SETTING_CLICK, params: params)

            switch self.validateInput() {
            case .valid:
                break
            case .empty:
                return
            case .containsSeparator:
                UDToast.showFailure(with: I18N.Lark_Passport_SetUpAccount_CannotHaveSpecialCharactersInName_Toast, on: self.view)
                return
            }

            self.showLoading()
            self.updateFieldValueToVM()
            self.vm
                .setName(name: self.inputUserName, optIn: self.optInCheckbox.isSelected)
                .subscribe(onError: { [weak self] (err) in
                    guard let self = self else { return }
                    self.stopLoading()
                    self.handle(err)
                }, onCompleted: { [weak self] in
                    self?.stopLoading()
                })
                .disposed(by: self.disposeBag)
        }.disposed(by: disposeBag)

        NotificationCenter.default
            .rx.notification(UITextField.textDidChangeNotification)
            .subscribe(onNext: { [weak self] (_) in
                self?.checkBtnDisable()
            }).disposed(by: disposeBag)

        checkBtnDisable()
        PassportMonitor.flush(PassportMonitorMetaStep.setNameEnter,
                eventName: ProbeConst.monitorEventName,
                categoryValueMap: [ProbeConst.flowType: vm.setNameInfo.flowType],
                context: vm.context)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        _ = nameTextFields.first?.textFiled.becomeFirstResponder()
        if let pn = pageName() {
            SuiteLoginTracker.track(
                pn,
                params: [
                    TrackConst.setNameType: vm.setNameInfo.flowType,
                    TrackConst.path: vm.trackPath
                ]
            )
        }
        let params = SuiteLoginTracker.makeCommonViewParams(flowType: vm.setNameInfo.flowType ?? "")
        SuiteLoginTracker.track(Homeric.PASSPORT_USER_NAME_SETTING_VIEW, params: params)
        self.logger.info("n_page_set_name")
    }

    override func clickBackOrClose(isBack: Bool) {
        PassportMonitor.flush(PassportMonitorMetaStep.setNameCancel,
                eventName: ProbeConst.monitorEventName,
                categoryValueMap: [ProbeConst.flowType: vm.setNameInfo.flowType],
                context: vm.context)
        super.clickBackOrClose(isBack: isBack)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if vm.showOptIn && iPadUseCompactLayout {
            let height = optInLabel.frame.height + CL.itemSpace
            nextButton.snp.updateConstraints { (make) in
                make.top.equalTo(centerInputView.snp.bottom).offset(CL.itemSpace * 2 + height)
                make.top.equalTo(inputAdjustView.snp.bottom).offset(CL.itemSpace + height)
            }
        }
    }

    func checkBtnDisable() {
        nextButton.isEnabled = inputNotEmpty()
    }

    override func pageName() -> String? {
        return Homeric.ENTER_SET_NAME
    }

    var inputUserName: String {
        let separator = vm.setNameInfo.nameSeparator ?? " "

        return nameTextFields
            .map { $0.currentText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "" }
            .reduce("") {
                $0
                + ($0.isEmpty ? "" : separator)
                + $1.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func inputNotEmpty() -> Bool {
        for nameTextField in nameTextFields {
            if nameTextField.currentText?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true {
                return false
            }
        }
        return true
    }

    func validateInput() -> NameValidateResult {
        for nameTextField in nameTextFields {
            guard let name = nameTextField.currentText, !name.isEmpty else {
                return .empty
            }

            guard let separator = vm.setNameInfo.nameSeparator, !separator.isEmpty else {
                continue
            }

            if name.contains(separator) {
                return .containsSeparator
            }

        }
        return .valid
    }

    func updateFieldValueToVM() {
        if !inputUserName.isEmpty {
            vm.userName = inputUserName
        }
    }

    override func needBottmBtnView() -> Bool {
        !iPadUseCompactLayout
    }

    private func makeNameLabel(text: String) -> UILabel {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.text = text
        return label
    }

    private func makeNameTextField(inputInfo: InputInfo) -> V3FlatTextField {
        let textField = V3FlatTextField(type: .default)
        textField.disableLabel = true
        textField.textFieldFont = UIFont.systemFont(ofSize: 17)
        textField.textFiled.returnKeyType = .next
        textField.textFiled.text = inputInfo.prefill

        if vm.isSingleInput {
            if let placeholder = PassportConf.shared.nameTextFieldPlaceholderProvider?() {
                textField.placeHolder = placeholder
            } else {
                textField.placeHolder = vm.placeholderName
            }
        } else {
            textField.placeHolder = inputInfo.placeholder ?? I18N.Lark_Login_V3_Set_Name_Hint
        }
        textField.textFiled.delegate = self
        return textField
    }
}

enum NameValidateResult {
    case valid
    case empty
    case containsSeparator
}

extension V3SetNameViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        for i in 0..<nameTextFields.count {
            if textField == nameTextFields[i].textFiled && i + 1 < nameTextFields.count {
                nameTextFields[i + 1].textFiled.becomeFirstResponder()
                return true
            }
        }

        nameTextFields.last?.textFiled.resignFirstResponder()
        return true
    }
}
