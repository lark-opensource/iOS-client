//
//  SearchBarView.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/5/10.
//

import Foundation
import UniverseDesignColor
import UniverseDesignIcon

final class SearchBarView: UIView, UITextFieldDelegate {
    lazy var textContentView: UIView = {
        let contentView = UIView()
        contentView.layer.cornerRadius = 6
        contentView.backgroundColor = UIColor.ud.udtokenInputBgDisabled
        contentView.clipsToBounds = true
        return contentView
    }()

    lazy var textField: UITextField = {
        let textField = UITextField()
        textField.textColor = UIColor.ud.textTitle
        textField.returnKeyType = .search
        textField.enablesReturnKeyAutomatically = true
        textField.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        return textField
    }()

    lazy var clearButton: UIButton = {
        let clearButton = UIButton(type: .custom)
        clearButton.setImage(UDIcon.getIconByKey(.closeFilled, iconColor: .ud.iconN3, size: CGSize(width: 16, height: 16)), for: .normal)
        clearButton.isHidden = true
        clearButton.setContentHuggingPriority(UILayoutPriority.defaultHigh, for: .horizontal)
        clearButton.setContentCompressionResistancePriority(UILayoutPriority.defaultHigh, for: .horizontal)
        clearButton.addTarget(self, action: #selector(didClickClear(_:)), for: .touchUpInside)
        return clearButton
    }()

    lazy var cancelButton: UIButton = {
        let cancelButton = UIButton(type: .custom)
        cancelButton.isHidden = true
        cancelButton.alpha = 0
        cancelButton.setTitle(I18n.View_G_CancelButton, for: .normal)
        cancelButton.setTitleColor(UIColor.ud.primaryPri500, for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        cancelButton.setContentHuggingPriority(.required, for: .horizontal)
        cancelButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        cancelButton.addTarget(self, action: #selector(didClickCancel(_:)), for: .touchUpInside)
        return cancelButton
    }()

    lazy var searchIconView: UIImageView = UIImageView(image: UDIcon.getIconByKey(.searchOutlined, iconColor: .ud.iconN3, size: CGSize(width: 16, height: 16)))

    var textDidChange: ((String) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(textContentView)
        addSubview(cancelButton)

        textContentView.addSubview(searchIconView)
        textContentView.addSubview(textField)
        textContentView.addSubview(clearButton)

        textContentView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(38)
            make.centerY.equalToSuperview()
        }

        cancelButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }

        searchIconView.snp.makeConstraints { make in
            make.width.height.equalTo(16)
            make.left.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
        }

        clearButton.snp.makeConstraints { make in
            make.height.equalToSuperview()
            make.width.equalTo(clearButton.snp.height)
            make.centerY.right.equalToSuperview()
        }

        textField.snp.makeConstraints { make in
            make.left.equalTo(searchIconView.snp.right).offset(8)
            make.top.bottom.equalToSuperview()
            make.right.equalTo(clearButton.snp.left).offset(-8)
        }

        textField.delegate = self
        textField.attributedPlaceholder = NSAttributedString(string: I18n.View_M_Search, config: .bodyAssist, textColor: .ud.textCaption)
        textField.addTarget(self, action: #selector(didChangeEditing(_:)), for: .editingChanged)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func didChangeEditing(_ sender: Any) {
        if textField.markedTextRange == nil {
            handleTextChanged(textField.text ?? "")
        }
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        showCancelButton()
        return true
    }

    private func showCancelButton() {
        self.cancelButton.isHidden = false
        self.textContentView.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.height.equalTo(38)
            make.centerY.equalToSuperview()
            make.right.equalTo(self.cancelButton.snp.left).offset(-8)
        }
        UIView.animate(withDuration: 0.25) {
            self.cancelButton.alpha = 1
            self.layoutIfNeeded()
        }
    }

    private func hideCancelButton() {
        self.textContentView.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.height.equalTo(38)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-16)
        }
        UIView.animate(withDuration: 0.25, animations: {
            self.cancelButton.alpha = 0
            self.layoutIfNeeded()
        }, completion: { _ in
            self.cancelButton.isHidden = true
        })
    }

    private func handleTextChanged(_ text: String) {
        self.textDidChange?(text)
        self.clearButton.isHidden = text.isEmpty
    }

    @objc private func didClickClear(_ b: Any) {
        self.textField.text = nil
        self.textField.becomeFirstResponder()
        handleTextChanged("")
    }

    @objc private func didClickCancel(_ b: Any) {
        self.reset()
    }

    func reset() {
        self.textField.text = nil
        self.textField.resignFirstResponder()
        self.clearButton.isHidden = true
        hideCancelButton()
    }
}
