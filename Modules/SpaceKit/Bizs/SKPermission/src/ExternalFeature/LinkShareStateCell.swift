//
//  LinkShareStateCell.swift
//  SKPermission
//
//  Created by Weston Wu on 2023/12/12.
//

import Foundation
import UniverseDesignIcon
import UniverseDesignColor
import LarkOpenSetting
import LarkSettingUI
import SnapKit

class LinkShareStateCellProp: CellProp, CellClickable {
    var onClick: ClickHandler?
    var title: String
    var detail: String

    init(title: String,
         detail: String,
         cellIdentifier: String = LinkShareStateCell.reuseIdentifier,
         separatorLineStyle: CellSeparatorLineStyle = .normal,
         selectionStyle: CellSelectionStyle = .normal,
         id: String? = nil,
         onClick: ClickHandler? = nil) {
        self.title = title
        self.detail = detail
        self.onClick = onClick
        super.init(cellIdentifier: cellIdentifier,
                   separatorLineStyle: separatorLineStyle,
                   selectionStyle: selectionStyle,
                   id: id)
    }
}

// 链接分享设置 Cell 的布局样式与 Setting 的默认效果不一致，这里基于 NormalCell 简化布局后实现
class LinkShareStateCell: BaseCell {

    private let titleLabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = UDColor.textTitle
        label.numberOfLines = 0
        label.setContentHuggingPriority(.defaultHigh, for: .vertical)
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }()

    private let detailLabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UDColor.textPlaceholder
        label.numberOfLines = 0
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        label.setContentHuggingPriority(.defaultLow, for: .vertical)
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let iconView = {
        let view = UIImageView()
        let size = CGSize(width: 16, height: 16)
        view.image = UDIcon.getIconByKey(.rightOutlined, iconColor: UDColor.iconN3, size: size)
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // nolint: duplicated_code
    private func setupUI() {
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(16)
            make.top.bottom.equalToSuperview().inset(12)
            make.height.greaterThanOrEqualTo(20)
            make.width.lessThanOrEqualTo(180)
        }

        contentView.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
        }
        contentView.addSubview(detailLabel)
        detailLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalTo(iconView.snp.left).offset(-4)
            make.height.equalTo(titleLabel)
            make.left.greaterThanOrEqualTo(titleLabel.snp.right).offset(24)
        }
    }
    // enable-lint: duplicated_code

    private func updateTitleMaxWidth() {
        guard let traitCollection = window?.traitCollection else { return }
        let maxWidth: CGFloat
        switch traitCollection.horizontalSizeClass {
        case .unspecified:
            maxWidth = 180
        case .compact:
            maxWidth = 180
        case .regular:
            maxWidth = 280
        }
        titleLabel.snp.updateConstraints { make in
            make.width.lessThanOrEqualTo(maxWidth)
        }
    }

    override func update(_ info: CellProp) {
        super.update(info)
        guard let info = info as? LinkShareStateCellProp else { return }
        titleLabel.setFigmaText(info.title)
        detailLabel.setFigmaText(info.detail)
        detailLabel.lineBreakMode = .byTruncatingTail
    }
}
