//
//  SCDebugPasteButtonViewCell.swift
//  SecurityComplianceDebug
//
//  Created by ByteDance on 2023/11/29.
//

import Foundation
import UniverseDesignIcon

class SCDebugPasteButtonViewCell: UITableViewCell, SCDebugFieldViewCellProtocol {
    static let cellID = "SCDebugPasteButtonViewCell"
    private let titleLabel = UILabel()
    private let inputField = SCDebugCellTextField()
    private let pasteButton: UIButton = {
        let pasteButton = UIButton()
        let icon = UDIcon.getIconByKey(.pasteOutlined).ud.withTintColor(.systemBlue)
        pasteButton.setImage(icon, for: .normal)
        pasteButton.setTitleColor(.systemBlue, for: .normal)
        return pasteButton
    }()

    private(set) var model: SCDebugFieldViewModel?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        let containerView = UIView()
        contentView.addSubview(containerView)
        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(4)
        }

        containerView.addSubview(titleLabel)
        containerView.addSubview(inputField)
        containerView.addSubview(pasteButton)
        titleLabel.snp.makeConstraints {
            $0.left.top.bottom.equalToSuperview()
            $0.width.equalTo(100)
        }

        inputField.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.left.equalTo(titleLabel.snp.right).offset(10)
            $0.right.equalTo(pasteButton.snp.left).offset(-10)
        }
        inputField.delegate = self

        pasteButton.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.right.equalToSuperview()
            $0.width.equalTo(25)
        }
        pasteButton.addTarget(self, action: #selector(pasteToField(_:)), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configModel(model: SCDebugFieldViewModel) {
        self.model = model
        titleLabel.text = model.key
        inputField.text = model.value
        inputField.placeholder = model.placeholder
    }


    @objc
    private func pasteToField(_ button: UIButton) {
        guard let text = UIPasteboard.general.string else { return }
        model?.value = text
        inputField.text = text
        model?.showDialogIfValueIsInvalid()
    }
}

extension SCDebugPasteButtonViewCell: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let text = textField.text else { return }
        model?.value = text
        model?.showDialogIfValueIsInvalid()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
