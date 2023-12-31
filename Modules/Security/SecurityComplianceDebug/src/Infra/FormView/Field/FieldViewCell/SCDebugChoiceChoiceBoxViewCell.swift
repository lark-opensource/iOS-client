//
//  SCDebugChoiceChoiceBoxViewCell.swift
//  SecurityComplianceDebug
//
//  Created by ByteDance on 2023/11/29.
//

import Foundation
import EENavigator
import UniverseDesignDialog
import UniverseDesignIcon

class SCDebugChoiceBoxViewCell: UITableViewCell, SCDebugFieldViewCellProtocol {
    static let cellID = "SCDebugChoiceBoxViewCell"
    private let titleLabel = UILabel()
    private let inputField = SCDebugCellTextField()
    private let choiceButton: UIButton = {
        let choiceButton = UIButton()
        let icon = UDIcon.getIconByKey(.moreRoundOutlined).ud.withTintColor(.systemBlue)
        choiceButton.setImage(icon, for: .normal)
        return choiceButton
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
        containerView.addSubview(choiceButton)

        titleLabel.snp.makeConstraints {
            $0.left.top.bottom.equalToSuperview()
            $0.width.equalTo(100)
        }

        inputField.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.left.equalTo(titleLabel.snp.right).offset(10)
            $0.right.equalTo(choiceButton.snp.left).offset(-10)
        }
        inputField.delegate = self

        choiceButton.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.right.equalToSuperview()
            $0.width.equalTo(25)
        }
        choiceButton.addTarget(self, action: #selector(choiceButtonClicked(_:)), for: .touchUpInside)
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
    private func choiceButtonClicked(_ sender: UIButton) {
        guard let choiceList = model?.choiceList else { return }
        guard let fromVC = Navigator.shared.mainSceneWindow?.fromViewController else { return }
        let dialog = UIAlertController.generateChoiceDialog(choiceList: choiceList,
                                                            getChoiceName: { $0 },
                                                            complete: { [weak self] choice in
            self?.model?.value = choice
            self?.inputField.text = choice
        })
        Navigator.shared.present(dialog, from: fromVC)
    }
}

extension SCDebugChoiceBoxViewCell: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let text = textField.text,
           !text.isEmpty {
            model?.showDialogIfValueIsInvalid()
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
