//
//  NameCardEditCell.swift
//  LarkContact
//
//  Created by 夏汝震 on 2021/4/13.
//

import Foundation
import UIKit
import SnapKit
import UniverseDesignInput
import UniverseDesignIcon

protocol NameCardEditCellProtocol: UITableViewCell {
    func setCellViewModel(_ cellVM: NameCardEditItemViewModel)
    var delegate: NameCardEditCellDelegate? { get set }
    static var identifier: String { get }
}

extension NameCardEditCellProtocol {
    func setCellViewModel(_ cellVM: NameCardEditItemViewModel) {}
    static var identifier: String { return "" }
}

protocol NameCardEditCellDelegate: AnyObject {
    func becomeFirstResponser(_ focusedInputView: UIView, _ cellVM: NameCardEditItemViewModel?)
    func textDidChange(_ cellVM: NameCardEditItemViewModel?)
    func tapCountryCodeView()
    func tapSelectAccount()
}

extension NameCardEditCellDelegate {
    func becomeFirstResponser(_ focusedInputView: UIView, _ cellVM: NameCardEditItemViewModel?) {}
    func textDidChange(_ cellVM: NameCardEditItemViewModel?) {}
    func tapCountryCodeView() {}
    func tapSelectAccount() {}
}

final class NameCardEditCell: UITableViewCell, UITextFieldDelegate, NameCardEditCellProtocol {
    static let identifier: String = "NameCardEditCell"
    weak var delegate: NameCardEditCellDelegate?

    private var titleLabel: UILabel = {
        let label = UILabel()
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        label.textColor = UIColor.ud.textTitle
        label.font = .systemFont(ofSize: 14)
        return label
    }()

    private var strongReminderLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.functionDangerContentDefault
        label.font = .systemFont(ofSize: 14)
        label.text = "*"
        return label
    }()

    private(set) var textField: UDTextField = {
        var config = UDTextFieldUIConfig(isShowBorder: false,
                                         textColor: UIColor.ud.textTitle,
                                         font: .systemFont(ofSize: 16))
        let textField = UDTextField(config: config)
        textField.input.returnKeyType = .done
        return textField
    }()

    private var placeHolder: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.text = BundleI18n.LarkContact.Lark_Contacts_ContactCardPleaseEnter
        label.font = .systemFont(ofSize: 16)
        label.contentMode = .top
        return label
    }()

    private var errorDesc: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.functionDangerContentDefault
        label.font = .systemFont(ofSize: 14)
        label.numberOfLines = 0
        return label
    }()

    private let selectAccountTapAreaView = UIView(frame: .zero)
    private let arrowIcon: UIImageView = UIImageView(image: UDIcon.downBoldOutlined.withRenderingMode(.alwaysTemplate))
    private var textFieldTrailingConstraint: Constraint?

    var cellVM: NameCardEditItemViewModel?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        self.selectionStyle = .none
        contentView.backgroundColor = UIColor.ud.bgBody

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(14)
            make.leading.equalToSuperview().offset(16)
        }

        contentView.addSubview(strongReminderLabel)
        strongReminderLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(titleLabel.snp.trailing).offset(2)
            make.centerY.equalTo(titleLabel).offset(1)
            make.trailing.equalToSuperview().offset(-16)
        }

        textField.input.addTarget(self, action: #selector(textDidChange(_:)), for: .editingChanged)
        textField.input.delegate = self
        contentView.addSubview(textField)
        textField.snp.makeConstraints { (make) in
            make.leading.equalTo(titleLabel)
            self.textFieldTrailingConstraint = make.trailing.equalToSuperview().offset(-16).constraint
            make.height.equalTo(22)
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
        }

        textField.addSubview(placeHolder)
        placeHolder.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.leading.equalTo(titleLabel.snp.leading)
        }

        contentView.addSubview(errorDesc)
        errorDesc.snp.makeConstraints { (make) in
            make.leading.trailing.equalTo(textField)
            make.top.equalTo(textField.snp.bottom).offset(8)
            make.bottom.equalToSuperview().offset(-6)
        }

        selectAccountTapAreaView.backgroundColor = .clear
        let tap = UITapGestureRecognizer()
        selectAccountTapAreaView.addGestureRecognizer(tap)
        tap.rx.event
            .filter({ $0.state == .ended })
            .subscribe { [weak self] _ in
                self?.delegate?.tapSelectAccount()
            }
        contentView.addSubview(selectAccountTapAreaView)
        selectAccountTapAreaView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }

        arrowIcon.tintColor = .ud.iconN2
        contentView.addSubview(arrowIcon)
        arrowIcon.contentMode = .scaleAspectFit
        arrowIcon.snp.makeConstraints { (make) in
            make.width.equalTo(12)
            make.centerY.equalTo(textField.snp.centerY)
            make.right.equalToSuperview().offset(-21)
        }
    }

    func setCellViewModel(_ cellVM: NameCardEditItemViewModel) {
        self.cellVM = cellVM
        strongReminderLabel.isHidden = !cellVM.isShowStrongReminder
        titleLabel.text = cellVM.title
        textField.text = cellVM.content
        arrowIcon.isHidden = cellVM.type != .account || !cellVM.isSelectable
        selectAccountTapAreaView.isHidden = arrowIcon.isHidden
        textField.isUserInteractionEnabled = cellVM.type != .account
        errorDesc.text = cellVM.errorDesc
        if cellVM.type == .account {
            textFieldTrailingConstraint?.update(inset: 30)
            placeHolder.text = BundleI18n.LarkContact.Mail_ThirdClient_PleaseSelect
        } else {
            textFieldTrailingConstraint?.update(inset: 16)
            placeHolder.text = BundleI18n.LarkContact.Lark_Contacts_ContactCardPleaseEnter
        }
        placeHolder.isHidden = textField.text?.isEmpty == false
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        delegate?.becomeFirstResponser(textField, cellVM)
        return true
    }

    @objc
    func textDidChange(_ textField: UITextField) {
        guard let vm = cellVM else { return }
        defer {
            cellVM?.updateContent(textField.text)
            // 名字列变更需要实时更新保存按钮状态
            if vm.type == .name {
                delegate?.textDidChange(cellVM)
            }
            placeHolder.isHidden = textField.text?.isEmpty == false
        }
        guard let text = textField.text else { return }
        if text.count > vm.maxCharLength {
            textField.text = String(text.prefix(vm.maxCharLength))
        }
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        delegate?.textDidChange(cellVM)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
