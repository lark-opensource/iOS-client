//
//  MyAINameSettingCell.swift
//  LarkAI
//
//  Created by Hayden on 2023/5/29.
//

import UIKit
import LarkUIKit
import UniverseDesignIcon
import UniverseDesignFont

final class MyAINameSettingCell: BaseSettingCell {

    func setName(_ name: String?) {
        detailLabel.text = name
    }

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.textColor = UIColor.ud.textTitle
        label.numberOfLines = 1
        label.font = Cons.titleFont
        label.text = BundleI18n.LarkAI.MyAI_IM_AISettings_Name_Tab
        return label
    }()

    private let detailLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .right
        label.textColor = UIColor.ud.textPlaceholder
        label.numberOfLines = 1
        label.font = Cons.detailFont
        return label
    }()

    private let arrowImageView: UIImageView = {
        let arrowView = UIImageView()
        arrowView.image = UDIcon.getIconByKey(.rightOutlined).ud.withTintColor(UIColor.ud.iconN3)
        return arrowView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(titleLabel)
        contentView.addSubview(detailLabel)
        contentView.addSubview(arrowImageView)

        let titleWidth = (titleLabel.text ?? "").getWidth(font: Cons.titleFont)
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(Cons.hMargin)
            make.width.equalTo(titleWidth + Cons.innerSpacing)
        }
        detailLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalTo(arrowImageView.snp.leading).offset(-Cons.innerSpacing)
            make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing)
        }
        arrowImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.width.height.equalTo(Cons.iconSize)
            make.right.equalTo(-Cons.hMargin)
        }

        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        detailLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    enum Cons {
        static var hMargin: CGFloat { 16 }
        static var innerSpacing: CGFloat { 4 }
        static var iconSize: CGFloat { 16 }
        static var titleFont: UIFont { UIFont.ud.body0(.fixed) }
        static var detailFont: UIFont { UIFont.ud.body2(.fixed) }
    }
}
