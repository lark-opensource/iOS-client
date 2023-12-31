//
//  InviteSendField.swift
//  LarkContact
//
//  Created by shizhengyu on 2019/11/5.
//

import Foundation
import UIKit
import SnapKit

enum InviteFieldState {
    case valid
    case invalid
}

protocol InviteSendFieldDelegate: UITextFieldDelegate {
    func fieldStateDidChange(field: InviteSendField, state: InviteFieldState)
    func fieldContentDidChange(field: InviteSendField, content: String)
}

final class InviteSendField: UIView {
    private let viewModel: ExternalInviteSendViewModel
    private weak var delegate: InviteSendFieldDelegate?
    var fieldState: InviteFieldState = .valid {
        didSet {
            field.isHidden = fieldState == .invalid
            invalidLabel.isHidden = fieldState == .valid
        }
    }

    init(viewModel: ExternalInviteSendViewModel, delegate: InviteSendFieldDelegate) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        layoutPageSubviews()
        NotificationCenter.default.addObserver(self, selector: #selector(textDidChange), name: UITextField.textDidChangeNotification, object: nil)
        field.delegate = delegate
        self.delegate = delegate
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var text: String? {
        get {
            return field.text
        }
        set {
            invalidLabel.text = newValue
            if field.text != newValue {
                field.text = newValue
            }
        }
    }

    @discardableResult
    override func becomeFirstResponder() -> Bool {
        field.becomeFirstResponder()
    }

    @discardableResult
    override func resignFirstResponder() -> Bool {
        field.resignFirstResponder()
    }

    override var isFirstResponder: Bool {
        self.field.isFirstResponder
    }

    private lazy var field: UITextField = {
        let field = UITextField()
        field.borderStyle = .none
        field.textColor = UIColor.ud.N900
        field.font = UIFont.systemFont(ofSize: 16)
        field.textAlignment = .left
        field.returnKeyType = .send
        field.isHidden = false
        return field
    }()

    private lazy var invalidLabel: InsetsLabel = {
        let label = InsetsLabel(frame: .zero, insets: UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8))
        label.backgroundColor = UIColor.ud.R100
        label.textColor = UIColor.ud.colorfulRed
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 16)
        label.numberOfLines = 1
        label.layer.cornerRadius = 11.0
        label.layer.masksToBounds = true
        label.isUserInteractionEnabled = true
        label.isHidden = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapInvalidLabel))
        label.addGestureRecognizer(tap)
        return label
    }()

    @objc
    func tapInvalidLabel() {
        fieldState = .valid
        field.becomeFirstResponder()
    }

    @objc
    func textDidChange() {
        invalidLabel.text = field.text
        delegate?.fieldContentDidChange(field: self, content: field.text ?? "")
    }
}

private extension InviteSendField {
    private func layoutPageSubviews() {
        addSubview(field)
        addSubview(invalidLabel)
        field.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(12)
            make.right.top.bottom.equalToSuperview()
        }
        invalidLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(4)
            make.height.equalTo(24)
            make.centerY.equalToSuperview()
        }
    }
}
