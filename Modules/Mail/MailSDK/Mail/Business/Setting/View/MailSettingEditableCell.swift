//
//  MailSettingEditableCell.swift
//  MailSDK
//
//  Created by Raozhongtao on 2023/11/26.
//

import Foundation
import LarkUIKit
import EENavigator
import UniverseDesignIcon
import UniverseDesignFont
import UniverseDesignInput

protocol MailSettingEditableCellDelegate: UDTextFieldDelegate {
    func handleEditingChange(sender: UITextField)
}

class MailSettingEditableCell: UITableViewCell, UDTextFieldDelegate {
    public weak var delegate: MailSettingEditableCellDelegate? {
        didSet {
            aliasTextField.delegate = delegate
        }
    }
    var item: MailSettingItemProtocol? {
        didSet {
            setCellInfo()
        }
    }
    private var accountId: String?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    var aliasTextField: UDTextField = {
        var config = UDTextFieldUIConfig(isShowBorder: false,
                                         clearButtonMode: .whileEditing,
                                         textColor: UIColor.ud.textTitle,
                                         font: UIFont.systemFont(ofSize: 16.0, weight: .regular))

        config.contentMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 12)
        let textField = UDTextField(config: config)
        textField.tintColor = UIColor.ud.functionInfoContentDefault
        textField.input.clearButtonMode = .whileEditing
        textField.input.addTarget(self, action: #selector(handleEditingChange(sender:)), for: .editingChanged)
        textField.layer.cornerRadius = 10
        textField.layer.masksToBounds = true
        return textField
     }()

    private func setupViews() {
        aliasTextField.backgroundColor = UIColor.ud.bgFloat
        self.contentView.addSubview(aliasTextField)
        aliasTextField.snp.makeConstraints { (make) in
            make.height.equalTo(48)
            make.edges.equalToSuperview()
        }
        aliasTextField.becomeFirstResponder()
    }

    private func setCellInfo() {
        guard let item = item as? MailSettingEditableModel else {
            return
        }
        aliasTextField.placeholder = item.placeHolder
        aliasTextField.text = item.alias
        accountId = item.accountId
        aliasTextField.becomeFirstResponder()
    }

    @objc
    func handleEditingChange(sender: UITextField) {
        delegate?.handleEditingChange(sender: sender)
    }
}
