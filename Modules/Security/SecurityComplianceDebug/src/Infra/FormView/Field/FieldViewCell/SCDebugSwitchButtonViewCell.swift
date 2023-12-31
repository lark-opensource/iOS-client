//
//  SCDebugSwitchButtonViewCell.swift
//  SecurityComplianceDebug
//
//  Created by ByteDance on 2023/11/29.
//

import Foundation

class SCDebugSwitchButtonViewCell: UITableViewCell, SCDebugFieldViewCellProtocol {
    static let cellID = "SCDebugSwitchButtonViewCell"

    private let titleLabel = UILabel()
    private let switchButton = UISwitch()
    private(set) var model: SCDebugFieldViewModel?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        let containerView = UIView()
        contentView.addSubview(containerView)
        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(4)
        }
        containerView.addSubview(titleLabel)
        containerView.addSubview(switchButton)

        titleLabel.snp.makeConstraints {
            $0.left.top.bottom.equalToSuperview()
            $0.right.lessThanOrEqualTo(switchButton.snp.left).offset(-10)
        }

        switchButton.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.right.equalToSuperview()
        }
        switchButton.addTarget(self, action: #selector(switchButtonClicked(_:)), for: .valueChanged)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configModel(model: SCDebugFieldViewModel) {
        self.model = model
        titleLabel.text = model.key
        guard let value = model.value,
              let isSwitchOn = Bool(value) else { return }
        switchButton.isOn = isSwitchOn
    }

    @objc
    private func switchButtonClicked(_ sender: UISwitch) {
        model?.value = sender.isOn.stringValue
    }
}
