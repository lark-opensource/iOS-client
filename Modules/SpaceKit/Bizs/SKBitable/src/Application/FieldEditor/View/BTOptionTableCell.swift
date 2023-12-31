//
//  BTOptionTableCell.swift
//  SKBitable
//
//  Created by zoujie on 2021/12/1.
//  


import Foundation
import UIKit
import SKResource
import UniverseDesignColor
import UniverseDesignInput
import UniverseDesignIcon
import UniverseDesignToast
import SKUIKit

public protocol BTOptionTableCellDelegate: BTFieldEditCellDelegate {
    func didClickColorView(optionID: String, colorView: UIView)
    func didChangeOptionName(optionID: String, optionName: String?)
    func didBeginEditOptionName(optionID: String, cell: BTOptionTableCell)
    func didEndEditOptionName(optionID: String, cell: BTOptionTableCell)
}

public final class BTOptionTableCell: BTFieldEditCell,
                                UITextFieldDelegate {

    weak var delegate: BTOptionTableCellDelegate?

    weak var hostVC: UIViewController?

    var optionID: String = ""

    private lazy var colorView = UIView().construct { it in
        it.layer.cornerRadius = 10
    }

    lazy var optionTextInputView = BTConditionalTextField().construct { it in
        it.font = .systemFont(ofSize: 16)
        it.textColor = UDColor.textTitle
        it.autocorrectionType = .no
        it.spellCheckingType = .no
        it.returnKeyType = .done
        it.delegate = self
        it.placeholder = BundleI18n.SKResource.Bitable_Field_AddAnOptionPlaceholder

        it.addTarget(self, action: #selector(optionNameDidChange), for: .editingChanged)
        it.addTarget(self, action: #selector(optionNameDidBeginEdit), for: .editingDidBegin)
        it.addTarget(self, action: #selector(optionNameDidEndEdit), for: .editingDidEnd)
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        leftView.addSubview(colorView)
        textInputWarpperView.addSubview(optionTextInputView)

        colorView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }

        optionTextInputView.snp.makeConstraints { make in
            make.height.equalTo(22)
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(4)
            make.right.equalToSuperview().inset(12)
        }


        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(clickColorView))
        colorView.addGestureRecognizer(tapGestureRecognizer)

        inpuTextView = optionTextInputView
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        if isNewItem, self.superview != nil {
            isNewItem = false
            DispatchQueue.main.async {
                self.optionTextInputView.becomeFirstResponder()
            }
        }
    }

    public func setUIConfig(color: UIColor, text: String?, editable: Bool, baseContext: BaseContext) {
        colorView.backgroundColor = color
        optionTextInputView.text = text
        optionTextInputView.textColor = editable ? UDColor.textTitle : UDColor.textDisabled
        optionTextInputView.baseContext = baseContext
        setUIConfig(deleteable: true, editable: editable)
    }

    @objc
    func clickColorView() {
        optionTextInputView.resignFirstResponder()
        delegate?.didClickColorView(optionID: optionID, colorView: self.colorView)
    }

    @objc
    override func longPress(_ sender: UILongPressGestureRecognizer) {
        super.longPress(sender)
        optionTextInputView.resignFirstResponder()
        delegate?.longPress(sender, cell: self)
    }

    @objc
    func optionNameDidChange() {
        delegate?.didChangeOptionName(optionID: optionID, optionName: optionTextInputView.text)
    }

    @objc
    func optionNameDidBeginEdit() {
        textViewIsEditing = true
        delegate?.didBeginEditOptionName(optionID: optionID, cell: self)
    }

    @objc
    func optionNameDidEndEdit() {
        textViewIsEditing = false
        delegate?.didEndEditOptionName(optionID: optionID, cell: self)
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        optionTextInputView.resignFirstResponder()
        return true
    }

    public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if !editable {
            UDToast.showWarning(with: BundleI18n.SKResource.Doc_Block_NotSupportEditInLandscape, on: hostVC?.view ?? self)
        }
        return editable
    }
}
