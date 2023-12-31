//
//  WorkspacePickerRecentCell.swift
//  SKCommon
//
//  Created by Weston Wu on 2022/9/28.
//

import Foundation
import UniverseDesignColor
import UniverseDesignTag
import SnapKit
import SKResource
import LarkContainer

class WorkspacePickerRecentCell: UITableViewCell {

    private lazy var iconView: UIImageView = {
        let view = UIImageView()
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UDColor.textTitle
        label.font = .systemFont(ofSize: 16)
        return label
    }()

    private lazy var externalTag: UDTag = {
        let config = UDTag.Configuration.text(BundleI18n.SKResource.Doc_Widget_External,
                                              tagSize: .mini,
                                              colorScheme: .blue)
        let tag = UDTag(withText: BundleI18n.SKResource.Doc_Widget_External)
        tag.updateConfiguration(config)
        return tag
    }()

    private lazy var titleStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 2
        view.alignment = .leading
        return view
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
        contentView.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.width.height.equalTo(20)
            make.left.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }

        contentView.addSubview(titleStackView)
        titleStackView.snp.makeConstraints { make in
            make.left.equalTo(iconView.snp.right).offset(8)
            make.right.equalToSuperview().inset(24)
            make.centerY.equalToSuperview()
        }

        titleStackView.addArrangedSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.lessThanOrEqualToSuperview()
            make.height.equalTo(22)
        }

        titleStackView.addSubview(externalTag)
        externalTag.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.left.equalTo(titleLabel.snp.right).offset(4)
            make.right.lessThanOrEqualToSuperview()
        }
        externalTag.setContentCompressionResistancePriority(.required, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    func update(entry: WorkspacePickerUIRepresentable) {
        titleLabel.text = entry.displayTitle
        iconView.di.setDocsImage(iconInfo: entry.iconInfo ?? "",
                                 token: entry.objToken,
                                 type: entry.docsType,
                                 shape: .SQUARE,
                                 container: entry.container,
                                 userResolver: Container.shared.getCurrentUserResolver())
        externalTag.isHidden = !entry.shouldShowExternalTag
    }
}

class WorkspacePickerRecentHeaderView: UITableViewHeaderFooterView {
    private lazy var titleLabel = {
        let label = UILabel()
        label.text = BundleI18n.SKResource.LarkCCM_Wiki_Location_RecentlyUsed
        label.textColor = UDColor.textCaption
        label.font = .systemFont(ofSize: 14)
        return label
    }()
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
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
