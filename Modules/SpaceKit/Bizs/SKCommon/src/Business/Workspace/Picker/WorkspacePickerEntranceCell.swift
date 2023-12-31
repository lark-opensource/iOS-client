//
//  WorkspacePickerEntranceCell.swift
//  SKCommon
//
//  Created by Weston Wu on 2022/9/9.
//

import Foundation
import UniverseDesignColor
import SKResource

class WorkspacePickerEntranceCell: UITableViewCell {

    private lazy var iconView: UIImageView = {
        let view = UIImageView()
        return view
    }()

    var icon: UIImage? {
        get { iconView.image }
        set { iconView.image = newValue }
    }

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UDColor.textTitle
        label.font = .systemFont(ofSize: 16)
        return label
    }()

    var title: String? {
        get { titleLabel.text }
        set { titleLabel.text = newValue }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        contentView.backgroundColor = UDColor.bgBody
        contentView.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.width.height.equalTo(20)
            make.left.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(iconView.snp.centerY)
            make.left.equalTo(iconView.snp.right).offset(8)
            make.right.equalToSuperview().inset(24)
        }
    }
}

class WorkspacePickerFooterView: UITableViewHeaderFooterView {
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        contentView.backgroundColor = UDColor.bgBodyOverlay
    }
}

class WorkspacePickerEntranceSubHeaderView: UITableViewCell {
    private lazy var titleLabel = {
        let label = UILabel()
        label.text = BundleI18n.SKResource.LarkCCM_CM_Drive_Header
        label.textColor = UDColor.textCaption
        label.font = .systemFont(ofSize: 14)
        return label
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
        contentView.backgroundColor = UDColor.bgBody
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.left.equalToSuperview().inset(16)
            make.right.equalToSuperview().inset(24)
        }
    }
}
