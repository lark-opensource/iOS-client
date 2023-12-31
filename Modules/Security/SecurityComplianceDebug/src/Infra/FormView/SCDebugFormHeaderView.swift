//
//  SCDebugFormHeaderView.swift
//  SecurityComplianceDebug
//
//  Created by ByteDance on 2023/11/29.
//

import Foundation
import UniverseDesignIcon
import SnapKit

class SCDebugFormHeaderView: UITableViewHeaderFooterView {
    var handleAddButtonClicked: (() -> Void)?

    let titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.textColor = .gray
        titleLabel.textAlignment = .left
        titleLabel.font = .systemFont(ofSize: 12)
        return titleLabel
    }()

    let addButton: UIButton = {
        let button = UIButton()
        let icon = UDIcon.getIconByKey(.moreAddOutlined).ud.withTintColor(.systemBlue)
        button.setImage(icon, for: .normal)
        return button
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        let containerView = UIView()
        contentView.addSubview(containerView)
        containerView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.left.right.equalToSuperview().inset(4)
        }
        containerView.addSubview(titleLabel)
        containerView.addSubview(addButton)

        titleLabel.snp.makeConstraints {
            $0.top.bottom.left.equalToSuperview()
            $0.right.lessThanOrEqualTo(addButton.snp.left)
        }
        addButton.snp.makeConstraints {
            $0.top.bottom.right.equalToSuperview()
            $0.width.equalTo(45)
        }
        addButton.addTarget(self, action: #selector(addButtonClicked(_:)), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateUI(text: String, isButtonHidden: Bool) {
        titleLabel.text = text
        addButton.isHidden = isButtonHidden
    }

    @objc
    func addButtonClicked(_ sender: UIButton) {
        handleAddButtonClicked?()
    }
}
