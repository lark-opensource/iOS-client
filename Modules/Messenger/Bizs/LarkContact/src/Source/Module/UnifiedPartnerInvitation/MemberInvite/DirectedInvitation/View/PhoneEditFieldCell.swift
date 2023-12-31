//
//  PhoneEditFieldCell.swift
//  LarkContact
//
//  Created by SlientCat on 2019/6/9.
//

import Foundation
import UIKit
import LarkUIKit
import RxSwift
import SnapKit

final class PhoneEditFieldCell: UITableViewCell, FieldCellAbstractable {
    let disposeBag = DisposeBag()
    lazy var countryCodeLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.textAlignment = NSTextAlignment.left
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textTitle
        label.isUserInteractionEnabled = true

        let tap = UITapGestureRecognizer()
        tap.rx.event.subscribe(onNext: { [weak self] (_) in
            guard let self else { return }
            self.viewModel.switchCountryCodeSubject.onNext((self.viewModel))
        })
        .disposed(by: disposeBag)
        label.addGestureRecognizer(tap)

        return label
    }()
    lazy var arrowView: UIImageView = {
        let imageView = UIImageView(frame: CGRect.zero)
        imageView.image = Resources.arrow_down_country_code
        return imageView
    }()
    lazy var editField: UITextField = {
        let field = UITextField(frame: CGRect.zero)
        field.borderStyle = .none
        field.clearButtonMode = .whileEditing
        field.adjustsFontSizeToFitWidth = true
        field.textAlignment = NSTextAlignment.left
        field.textColor = UIColor.ud.textTitle
        field.font = UIFont.systemFont(ofSize: 16)
        field.attributedPlaceholder = NSAttributedString(string: BundleI18n.LarkContact.Lark_Invitation_AddMembersHintInputPhone,
                                                         attributes: [.foregroundColor: UIColor.ud.textPlaceholder,
                                                                      .font: UIFont.systemFont(ofSize: 16)])
        field.keyboardType = .numberPad
        field.addTarget(self, action: #selector(changeFocus(field:)), for: .editingDidBegin)
        field.addTarget(self, action: #selector(changeFocus(field:)), for: .editingDidEnd)
        field.addTarget(self, action: #selector(valueChanged(field:)), for: .editingChanged)

        return field
    }()
    lazy var bottomLine: UIView = {
        let line = UIView(frame: CGRect.zero)
        line.backgroundColor = UIColor.ud.lineBorderCard
        return line
    }()
    private var viewModel: PhoneFieldViewModel! {
        didSet {
            editField.text = viewModel.contentSubject.value
            editField.delegate = viewModel
            countryCodeLabel.text = viewModel.countryCodeSubject.value
            countryCodeLabel.textColor = viewModel.canEditCountryCode ? UIColor.ud.textTitle : UIColor.ud.textDisabled
            countryCodeLabel.isUserInteractionEnabled = viewModel.canEditCountryCode
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
        guard let viewModel: PhoneFieldViewModel = viewModel as? PhoneFieldViewModel else { return }
        self.viewModel = viewModel
    }

    func beActive() {
        editField.becomeFirstResponder()
    }

    @objc
    private func changeFocus(field: UITextField) {
        if field.isFirstResponder {
            bottomLine.backgroundColor = UIColor.ud.primaryContentDefault
        } else {
            bottomLine.backgroundColor = UIColor.ud.lineBorderCard
        }
    }

    @objc
    private func valueChanged(field: UITextField) {
        viewModel.contentSubject.accept(field.text ?? "")
    }

    private func layoutPageSubviews() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        contentView.addSubview(countryCodeLabel)
        contentView.addSubview(arrowView)
        contentView.addSubview(editField)
        contentView.addSubview(bottomLine)

        countryCodeLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(24)
            make.right.equalTo(arrowView.snp.left)
            make.top.equalToSuperview().offset(8)
            make.bottom.equalToSuperview().offset(-8)
        }
        arrowView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.width.height.equalTo(12)
            make.left.equalToSuperview().offset(65)
        }
        editField.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(8)
            make.bottom.equalToSuperview().offset(-8)
            make.left.equalTo(arrowView.snp.right).offset(12)
            make.right.equalToSuperview().offset(-24)
        }
        bottomLine.snp.makeConstraints { (make) in
            make.top.equalTo(editField.snp.bottom)
            make.left.equalTo(countryCodeLabel)
            make.right.equalTo(editField)
            make.height.equalTo(1)
        }
    }
}
