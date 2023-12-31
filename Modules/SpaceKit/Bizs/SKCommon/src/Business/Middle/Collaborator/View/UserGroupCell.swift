//
//  UserGroupCell.swift
//  SKCommon
//
//  Created by Weston Wu on 2022/1/11.
//

import Foundation
import UIKit
import SnapKit
import UniverseDesignCheckBox
import UniverseDesignIcon
import UniverseDesignColor
import SKResource

struct UserGroupItem {
    let groupID: String
    let name: String
    var selectType: SelectType
    var isExist: Bool
}

class UserGroupCell: UITableViewCell {
    private lazy var checkbox: UDCheckBox = {
        let checkbox = UDCheckBox(boxType: .multiple)
        // checkbox 本身不响应点击，而是整个 cell 响应
        checkbox.isUserInteractionEnabled = false
        return checkbox
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = UDColor.textTitle
        return label
    }()

    private lazy var iconView: UIImageView = {
        let view = UIImageView()
        view.image = BundleResources.SKResource.Common.Collaborator.icon_usergroup
        return view
    }()

    private lazy var separator: UIView = {
        let v = UIView()
        v.backgroundColor = UDColor.lineDividerDefault
        return v
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        contentView.addSubview(checkbox)
        checkbox.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.width.height.equalTo(18)
            make.centerY.equalToSuperview()
        }

        contentView.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.left.equalTo(checkbox.snp.right).offset(12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }
        iconView.layer.cornerRadius = 20
        iconView.clipsToBounds = true

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalTo(iconView.snp.right).offset(16)
            make.right.equalToSuperview().inset(16)
        }

        contentView.addSubview(separator)
        separator.snp.makeConstraints { (make) in
            make.left.equalTo(iconView.snp.left)
            make.right.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        checkbox.isHidden = false
        checkbox.isEnabled = true
        checkbox.isSelected = false
    }

    func update(item: UserGroupItem) {
        if item.selectType == .disable {
            titleLabel.alpha = 0.3
        } else {
            titleLabel.alpha = 1
        }
        titleLabel.text = item.name

        switch item.selectType {
        case .none:
            checkbox.isHidden = true
        case .blue:
            checkbox.isSelected = true
        case .gray:
            checkbox.isSelected = false
        case .hasSelected:
            checkbox.isSelected = true
            checkbox.isEnabled = false
        case .disable:
            checkbox.isEnabled = false
            checkbox.isSelected = false
        }
    }
}
