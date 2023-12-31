//
//  SCDebugCustomizedValueOnlyViewCell.swift
//  SecurityComplianceDebug
//
//  Created by ByteDance on 2023/11/29.
//

import Foundation
import EENavigator
import UniverseDesignDialog

class SCDebugCustomizedValueOnlyViewCell: UITableViewCell, SCDebugFieldViewCellProtocol {
    static let cellID = "SCDebugCustomizedValueOnlyViewCell"
    private let valueField = SCDebugCellTextField()
    private let changeValueTypeButton: UIButton = {
        let button = UIButton()
        button.setTitleColor(.systemBlue, for: .normal)
        button.layer.borderColor = UIColor.systemBlue.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 5
        return button
    }()
    private(set) var model: SCDebugFieldViewModel?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        let containerView = UIView()
        contentView.addSubview(containerView)
        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(4)
        }

        containerView.addSubview(valueField)
        containerView.addSubview(changeValueTypeButton)

        valueField.snp.makeConstraints {
            $0.top.bottom.left.equalToSuperview()
            $0.right.equalTo(changeValueTypeButton.snp.left).offset(-5)
        }
        valueField.placeholder = "Value"
        valueField.delegate = self

        changeValueTypeButton.snp.makeConstraints {
            $0.top.bottom.right.equalToSuperview()
            $0.width.equalTo(60)
        }
        changeValueTypeButton.addTarget(self, action: #selector(changeValueTypeButtonClicked(_:)), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configModel(model: SCDebugFieldViewModel) {
        self.model = model
        valueField.text = model.value
        changeValueTypeButton.setTitle(model.valueType.rawValue, for: .normal)
    }

    @objc
    private func changeValueTypeButtonClicked(_ sender: UIButton) {
        guard let fromVC = Navigator.shared.mainSceneWindow?.fromViewController else { return }
        let dialog = UIAlertController.generateChoiceDialog(choiceList: SCDebugFieldViewModel.ValueType.allCases,
                                          getChoiceName: { $0.rawValue },
                                          complete: { [weak self] choice in
            self?.model?.valueType = choice
            self?.changeValueTypeButton.setTitle(choice.rawValue, for: .normal)
        })
        Navigator.shared.present(dialog, from: fromVC)
    }
}

extension SCDebugCustomizedValueOnlyViewCell: UITextFieldDelegate {
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
