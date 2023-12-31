//
//  NameCardEditPhoneCell.swift
//  LarkContact
//
//  Created by 夏汝震 on 2021/4/19.
//

import Foundation
import UIKit
import UniverseDesignIcon
import UniverseDesignInput
import UniverseDesignColor
import LarkFeatureGating

final class NameCardEditPhoneCell: UITableViewCell, UITextFieldDelegate, NameCardEditCellProtocol {
    static let identifier: String = "NameCardEditPhoneCell"

    weak var delegate: NameCardEditCellDelegate?

    private var phoneContainerView = UIView()

    private var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = .systemFont(ofSize: 14)
        return label
    }()

    private var regionCodeBgView: UIView = {
        let view = UIView()
        return view
    }()

    private var regionCodeLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = .systemFont(ofSize: 16)
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal) // 抗拉伸
        return label
    }()

    private var regionCodeImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .ud.iconN2
        imageView.image = UDIcon.downBoldOutlined.withRenderingMode(.alwaysTemplate)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private var lineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.textPlaceholder
        return view
    }()

    private var textField: UDTextField = {
        var config = UDTextFieldUIConfig(isShowBorder: false,
                                         textColor: UIColor.ud.textTitle,
                                         font: .systemFont(ofSize: 16))
        let textField = UDTextField(config: config)
        textField.input.returnKeyType = .done
        textField.input.keyboardType = .phonePad
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

    var cellVM: NameCardEditPhoneViewModel?

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
            make.trailing.equalToSuperview().offset(-16)
        }

        contentView.addSubview(phoneContainerView)
        phoneContainerView.snp.makeConstraints { (make) in
            make.leading.trailing.equalTo(titleLabel)
            make.height.equalTo(24)
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
        }

        textField.input.delegate = self
        textField.input.addTarget(self, action: #selector(textDidChange(_:)), for: .editingChanged)

        phoneContainerView.addSubview(textField)
        textField.snp.makeConstraints { (make) in
            make.leading.trailing.centerY.equalToSuperview()
        }

        textField.addSubview(placeHolder)
        placeHolder.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.leading.equalToSuperview()
        }

        contentView.addSubview(errorDesc)
        errorDesc.snp.makeConstraints { (make) in
            make.leading.trailing.equalTo(titleLabel)
            make.top.equalTo(phoneContainerView.snp.bottom).offset(8)
            make.bottom.equalToSuperview().offset(-6)
        }
    }

    func setCellViewModel(_ cellVM: NameCardEditItemViewModel) {
        guard let vm = cellVM as? NameCardEditPhoneViewModel else { return }
        self.cellVM = vm
        titleLabel.text = vm.title
        regionCodeLabel.text = vm.districtNumber
        textField.text = vm.fullPhoneNumber
        errorDesc.text = vm.errorDesc
        placeHolder.isHidden = textField.text?.isEmpty == false

    }

    @objc
    func showCodeView() {
        delegate?.tapCountryCodeView()
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        delegate?.becomeFirstResponser(textField, cellVM)
        return true
    }

    @objc
    func textDidChange(_ textField: UITextField) {
        guard let vm = cellVM else { return }
        defer {
            cellVM?.updateFullPhoneNumber(textField.text)
            placeHolder.isHidden = textField.text?.isEmpty == false
        }
        guard let text = textField.text else { return }
        let cursorPostion = textField.offset(from: textField.endOfDocument, to: textField.selectedTextRange?.end ?? textField.endOfDocument)
        let numberText = phoneNumber(text)
        textField.text = String(numberText.prefix(vm.maxCharLength))
        // 粘贴后光标停留在正确位置
        if let targetPostion = textField.position(from: textField.endOfDocument, offset: cursorPostion) {
            DispatchQueue.main.async {
                textField.selectedTextRange = textField.textRange(from: targetPostion, to: targetPostion)
            }
        }
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        delegate?.textDidChange(cellVM)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    private func pureNumber(_ text: String) -> String {
        return text.components(separatedBy:
                     CharacterSet.decimalDigits.inverted).joined(separator: "")
    }

    private func phoneNumber(_ text: String) -> String {
        let charSet = "0123456789+*#"
        return text.filter { (char) -> Bool in
            return charSet.contains(char)
        }
    }
}
