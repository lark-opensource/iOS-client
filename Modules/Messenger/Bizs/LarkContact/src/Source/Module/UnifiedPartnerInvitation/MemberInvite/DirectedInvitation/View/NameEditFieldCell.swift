//
//  NameEditFieldCell.swift
//  LarkContact
//
//  Created by shizhengyu on 2019/12/11.
//

import Foundation
import UIKit
import LarkUIKit
import RxSwift
import SnapKit

final class NameEditFieldCell: UITableViewCell, FieldCellAbstractable {
    lazy var editField: UITextField = {
        let field = UITextField(frame: CGRect.zero)
        field.borderStyle = .none
        field.clearButtonMode = .whileEditing
        field.adjustsFontSizeToFitWidth = true
        field.textAlignment = NSTextAlignment.left
        field.textColor = UIColor.ud.N900
        field.font = UIFont.systemFont(ofSize: 16)
        field.attributedPlaceholder = NSAttributedString(string: BundleI18n.LarkContact.Lark_Invitation_AddMembersHintInputName,
                                                              attributes: [.foregroundColor: UIColor.ud.color(156, 162, 169),
                                                                           .font: UIFont.systemFont(ofSize: 16)])
        field.returnKeyType = .done
        field.addTarget(self, action: #selector(changeFocus(field:)), for: .editingDidBegin)
        field.addTarget(self, action: #selector(changeFocus(field:)), for: .editingDidEnd)
        field.addTarget(self, action: #selector(valueChanged(field:)), for: .editingChanged)
        return field
    }()
    lazy var bottomLine: UIView = {
        let line = UIView(frame: CGRect.zero)
        line.backgroundColor = UIColor.ud.N300
        return line
    }()
    private var viewModel: NameFieldViewModel! {
        didSet {
            editField.text = viewModel.contentSubject.value
            editField.delegate = viewModel
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        layoutPageSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// FieldCellAbstractable
    func bindWithViewModel(viewModel: FieldViewModelAbstractable) {
        guard let viewModel: NameFieldViewModel = viewModel as? NameFieldViewModel else { return }
        self.viewModel = viewModel
    }

    func beActive() {
        editField.becomeFirstResponder()
    }

    @objc
    private func changeFocus(field: UITextField) {
        if field.isFirstResponder {
            bottomLine.backgroundColor = UIColor.ud.colorfulBlue
        } else {
            bottomLine.backgroundColor = UIColor.ud.N300
        }
    }

    @objc
    private func valueChanged(field: UITextField) {
        viewModel.contentSubject.accept(field.text ?? "")
    }

    private func layoutPageSubviews() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        contentView.addSubview(editField)
        contentView.addSubview(bottomLine)

        editField.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(8)
            make.bottom.equalToSuperview().offset(-8)
            make.left.equalToSuperview().offset(24)
            make.right.equalToSuperview().offset(-24)
        }
        bottomLine.snp.makeConstraints { (make) in
            make.top.equalTo(editField.snp.bottom)
            make.left.right.equalTo(editField)
            make.height.equalTo(1)
        }
    }
}
