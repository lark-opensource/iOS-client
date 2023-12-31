//
//  BTOptionTableCell.swift
//  SKBitable
//
//  Created by zoujie on 2021/12/1.
//  


import Foundation
import UIKit
import RxSwift
import SKResource
import UniverseDesignColor
import UniverseDesignInput
import UniverseDesignIcon
import UniverseDesignToast
import SKUIKit
import SKCommon

public protocol BTAutoNumberTableCellDelegate: BTFieldEditCellDelegate {
    func didClickNoticeButton(id: String,
                              noticeButton: UIView,
                              cell: BTAutoNumberTableCell)
    func didClickExpandButton(id: String, expandButton: UIView)
    func didChangeRuleValue(id: String, value: String?)
    func didBeginEditRuleValue(id: String, cell: BTAutoNumberTableCell)
    func didEndEditRuleValue(id: String, cell: BTAutoNumberTableCell)
}

public final class BTAutoNumberTableCell: BTFieldEditCell,
                                    UITextFieldDelegate {

    weak var delegate: BTAutoNumberTableCellDelegate?

    weak var hostVC: UIViewController?

    var cellType: BTAutoNumberRuleType = .systemNumber

    var disposeBag = DisposeBag()

    var id: String = ""

    lazy var notiveButton = UIButton().construct { it in
        it.backgroundColor = .clear
        it.setImage(UDIcon.getIconByKey(.maybeOutlined, iconColor: UDColor.iconN3, size: CGSize(width: 16, height: 16)), for: [.normal, .highlighted])
        it.addTarget(self, action: #selector(clickNoticeButton), for: .touchUpInside)
    }

    lazy var ruleNameLabel = UILabel().construct { it in
        it.textColor = UDColor.textTitle
        it.font = UIFont.systemFont(ofSize: 16)
    }

    lazy var systemNumberUnitLabel = UILabel().construct { it in
        it.textColor = UDColor.textCaption
        it.font = UIFont.systemFont(ofSize: 16)
    }

    lazy var expandButton = UIButton().construct { it in
        it.backgroundColor = .clear
        it.setImage(UDIcon.getIconByKey(.downBoldOutlined, iconColor: UDColor.iconN1, size: CGSize(width: 16, height: 16)), for: [.normal, .highlighted])
        it.addTarget(self, action: #selector(clickExpandButton), for: .touchUpInside)
    }

    lazy var ruleValueInputView = BTConditionalTextField().construct { it in
        it.font = .systemFont(ofSize: 16)
        it.textColor = UDColor.textTitle
        it.autocorrectionType = .no
        it.spellCheckingType = .no
        it.returnKeyType = .done
        it.delegate = self
        it.placeholder = BundleI18n.SKResource.Bitable_Option_PleaseEnter

        it.addTarget(self, action: #selector(nameDidChange), for: .editingChanged)
        it.addTarget(self, action: #selector(nameDidBeginEdit), for: .editingDidBegin)
        it.addTarget(self, action: #selector(nameDidEndEdit), for: .editingDidEnd)
    }

    lazy var stepperView = DocsStepperView(minValue: 1, maxValue: 9)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        leftView.addSubview(ruleNameLabel)

        textInputWarpperView.addSubview(ruleValueInputView)
        textInputWarpperView.addSubview(expandButton)

        container.addSubview(stepperView)
        container.addSubview(systemNumberUnitLabel)
        container.addSubview(notiveButton)

        ruleNameLabel.snp.makeConstraints { make in
            make.width.equalTo(0)
            make.height.equalTo(20)
            make.centerY.equalTo(dragView)
            make.left.right.equalToSuperview()
        }

        notiveButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
            make.left.equalTo(systemNumberUnitLabel.snp.right).offset(6)
        }

        ruleValueInputView.snp.makeConstraints { make in
            make.height.equalTo(22)
            make.centerY.equalToSuperview()
            make.left.equalToSuperview()
            make.right.lessThanOrEqualToSuperview().offset(-20)
        }

        expandButton.snp.makeConstraints { make in
            make.width.height.equalTo(12)
            make.centerY.equalToSuperview()
            make.left.equalTo(ruleValueInputView.snp.right).offset(8)
        }

        systemNumberUnitLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.height.equalTo(22)
            make.left.equalTo(stepperView.snp.right).offset(8)
        }

        stepperView.snp.makeConstraints { make in
            make.width.equalTo(110)
            make.height.equalTo(32)
            make.centerY.equalToSuperview()
            make.left.equalTo(leftView.snp.right).offset(16)
        }

        inpuTextView = ruleValueInputView
        stepperView.shouldShowPartingLine(show: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        if isNewItem, self.superview != nil {
            isNewItem = false
            DispatchQueue.main.async {
                self.ruleValueInputView.becomeFirstResponder()
            }
        }
    }

    public func setUIConfig(type: BTAutoNumberRuleType,
                            text: String,
                            name: String,
                            editable: Bool,
                            hasError: Bool,
                            baseContext: BaseContext
    ) {
        cellType = type
        
        ruleValueInputView.baseContext = baseContext

        disposeBag = DisposeBag()
        self.hasError = hasError

        if let gesture = textInputWarpperView.gestureRecognizers?.first as? UITapGestureRecognizer {
            textInputWarpperView.removeGestureRecognizer(gesture)
        }

        switch type {
        case .systemNumber:
            notiveButton.isHidden = false
            stepperView.isHidden = false
            systemNumberUnitLabel.isHidden = false
            textInputWarpperView.isHidden = true
            stepperView.setInitValue(vaule: Int(text) ?? 1)
            systemNumberUnitLabel.text = BundleI18n.SKResource.Bitable_Field_DigitMobileVer(Int(text) ?? 1)
            stepperView.valuePubish.subscribe(onNext: { [weak self] v in
                guard let self = self else { return }
                self.delegate?.didChangeRuleValue(id: self.id, value: String(v))
            }).disposed(by: disposeBag)
        case .fixedText:
            notiveButton.isHidden = true
            stepperView.isHidden = true
            systemNumberUnitLabel.isHidden = true
            textInputWarpperView.isHidden = false
            expandButton.isHidden = true
            ruleValueInputView.text = text
            ruleValueInputView.snp.remakeConstraints { make in
                make.height.equalTo(22)
                make.centerY.equalToSuperview()
                make.left.right.equalToSuperview()
            }
        case .createdTime:
            notiveButton.isHidden = true
            stepperView.isHidden = true
            systemNumberUnitLabel.isHidden = true
            textInputWarpperView.isHidden = false
            expandButton.isHidden = false
            ruleValueInputView.text = text
            ruleValueInputView.snp.remakeConstraints { make in
                make.height.equalTo(22)
                make.centerY.equalToSuperview()
                make.left.equalToSuperview()
                make.right.lessThanOrEqualToSuperview().offset(-20)
            }

            let recognizer = UITapGestureRecognizer()
            recognizer.addTarget(self, action: #selector(clickExpandButton))
            textInputWarpperView.addGestureRecognizer(recognizer)
        }

        ruleNameLabel.text = name
        ruleNameLabel.sizeToFit()
        ruleNameLabel.snp.updateConstraints { make in
            make.width.equalTo(ruleNameLabel.bounds.width)
        }

        ruleValueInputView.textColor = (editable || type == .createdTime) ? UDColor.textTitle : UDColor.textDisabled

        setUIConfig(deleteable: type != .systemNumber,
                    editable: editable || type == .createdTime)
        showErrorLabel(show: hasError, text: type == .fixedText ? BundleI18n.SKResource.Bitable_Field_AutoIdReachCharacterLimit(18) : "")
    }

    @objc
    func clickNoticeButton() {
        ruleValueInputView.resignFirstResponder()
        delegate?.didClickNoticeButton(id: id,
                                       noticeButton: self.notiveButton,
                                       cell: self)
    }

    @objc
    func clickExpandButton() {
        delegate?.didClickExpandButton(id: id, expandButton: self.expandButton)
        delegate?.didBeginEditRuleValue(id: id, cell: self)
    }

    @objc
    override func longPress(_ sender: UILongPressGestureRecognizer) {
        super.longPress(sender)
        ruleValueInputView.resignFirstResponder()
        delegate?.longPress(sender, cell: self)
    }

    @objc
    func nameDidChange() {
        delegate?.didChangeRuleValue(id: id, value: ruleValueInputView.text)
    }

    @objc
    func nameDidBeginEdit() {
        textViewIsEditing = true
        delegate?.didBeginEditRuleValue(id: id, cell: self)
    }

    @objc
    func nameDidEndEdit() {
        textViewIsEditing = false
        delegate?.didEndEditRuleValue(id: id, cell: self)
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        ruleValueInputView.resignFirstResponder()
        return true
    }

    public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if !editable {
            UDToast.showWarning(with: BundleI18n.SKResource.Doc_Block_NotSupportEditInLandscape, on: hostVC?.view ?? self)
        }

        if cellType == .createdTime {
            clickExpandButton()
            return false
        }

        return editable
    }

    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = ruleValueInputView.text else { return false }

        let textLength = text.utf16.count + string.utf16.count - range.length
        hasError = false
        switch cellType {
        case .fixedText:
            if textLength > 18 {
                hasError = true
            }
        default:
            break
        }

        delegate?.didChangeValue(id: id, cell: self)
        return true
    }
}
