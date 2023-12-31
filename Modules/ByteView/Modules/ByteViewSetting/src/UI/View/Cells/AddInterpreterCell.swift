//
//  AddInterpreterCell.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/3/5.
//

import Foundation
import UniverseDesignIcon
import UniverseDesignColor
import ByteViewUI

extension SettingCellType {
    static let addInterpreterCell = SettingCellType("addInterpreterCell", cellType: AddInterpreterCell.self, supportSelection: true)
}

final class AddInterpreterCell: BaseSettingCell {
    static let maxChannelInfosCount = 10
    let titleLabel = UILabel()

    lazy var infoLabel: PaddingLabel = {
        let label = PaddingLabel()
        label.textAlignment = .center
        label.textColor = .ud.udtokenTagTextSYellow
        label.font = UIFont.systemFont(ofSize: 12)
        label.backgroundColor = .ud.udtokenTagBgYellow
        label.layer.cornerRadius = 4
        label.layer.masksToBounds = true
        label.isHidden = true
        label.textInsets = UIEdgeInsets(top: 0.0, left: 4.0, bottom: 0.0, right: 4.0)
        return label
    }()

    override func setupViews() {
        super.setupViews()
        self.selectionStyle = .default
        backgroundView?.backgroundColor = .ud.bgFloat
        selectedBackgroundView?.backgroundColor = .ud.fillPressed

        let image = UDIcon.getIconByKey(.addOutlined, iconColor: .ud.primaryContentDefault, size: CGSize(width: 16, height: 16))
        let iconView = UIImageView(image: image)
        contentView.addSubview(titleLabel)
        contentView.addSubview(iconView)
        contentView.addSubview(infoLabel)

        iconView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.width.height.equalTo(16)
            make.centerY.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(iconView.snp.right).offset(4)
            make.top.bottom.equalToSuperview().inset(12)
            make.height.equalTo(24)
            make.right.lessThanOrEqualToSuperview().offset(-16)
        }

        infoLabel.snp.makeConstraints { make in
            make.left.equalTo(titleLabel.snp.right).offset(8)
            make.height.equalTo(18)
            make.centerY.equalToSuperview()
        }
    }

    override func config(for row: SettingDisplayRow, indexPath: IndexPath) {
        super.config(for: row, indexPath: indexPath)
        titleLabel.attributedText = NSAttributedString(string: row.title, config: cellStyle.titleStyleConfig, textColor: .ud.primaryContentDefault)
        if let show = row.data["showInfo"] as? Bool, show == true {
            self.infoLabel.text = I18n.View_Paid_Tag
            self.infoLabel.isHidden = false
        } else {
            self.infoLabel.isHidden = true
        }
    }
}
