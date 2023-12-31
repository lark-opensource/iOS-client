//
//  TeamInputView.swift
//  LarkTeam
//
//  Created by JackZhao on 2021/7/18.
//
import UIKit
import Foundation
import LarkUIKit

final class TeamInputView: UIView {
    private let textMaxLength: Int
    let textField = BaseTextField(frame: .zero)
    var textFieldDidChangeHandler: ((UITextField) -> Void)?
    var text: String? {
        get { return self.textField.text }
        set {
            self.textField.text = newValue
            inputViewTextFieldDidChange(self.textField)
        }
    }
    let textCountLabel: UILabel = UILabel(frame: .zero)

    init(textMaxLength: Int) {
        self.textMaxLength = textMaxLength
        super.init(frame: .zero)
        self.backgroundColor = UIColor.ud.bgBody

        textField.exitOnReturn = true
        textField.textAlignment = .left
        textField.borderStyle = .none
        textField.clearButtonMode = .whileEditing
        textField.textColor = UIColor.ud.N900
        textField.backgroundColor = UIColor.ud.bgBody
        textField.font = UIFont.systemFont(ofSize: 16)
        textField.returnKeyType = .done
        textField.addTarget(self, action: #selector(inputViewTextFieldDidChange(_:)), for: .editingChanged)
        self.addSubview(textField)
        textField.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(15)
            make.right.equalToSuperview().offset(-7)
            make.top.equalToSuperview().offset(16)
            make.height.equalTo(20)
        }

        textCountLabel.font = .systemFont(ofSize: 12)
        self.addSubview(textCountLabel)
        textCountLabel.snp.makeConstraints { (make) in
            make.trailing.equalToSuperview().offset(-16)
            make.top.equalTo(textField.snp.bottom).offset(6)
            make.bottom.equalToSuperview().offset(-8)
        }
        let attr = NSAttributedString(string: "\(0)/\(textMaxLength)",
                                      attributes: [.foregroundColor: UIColor.ud.N500])
        textCountLabel.attributedText = attr

        self.lu.addTopBorder()
        self.lu.addBottomBorder()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func inputViewTextFieldDidChange(_ textField: UITextField) {
        let count = textField.text?.count ?? 0
        if count > textMaxLength {
            let attr = NSMutableAttributedString(string: "\(count)",
                                                 attributes: [.foregroundColor: UIColor.ud.colorfulRed])
            attr.append(NSAttributedString(string: "/\(textMaxLength)",
                                           attributes: [.foregroundColor: UIColor.ud.N500]))
            textCountLabel.attributedText = attr
        } else {
            let attr = NSAttributedString(string: "\(count)/\(textMaxLength)",
                                          attributes: [.foregroundColor: UIColor.ud.N500])
            textCountLabel.attributedText = attr
        }
        if let handler = self.textFieldDidChangeHandler {
            handler(textField)
        }
    }
}
