//
//  MineAccountDetailViewCell.swift
//  LarkMine
//
//  Created by liuwanlin on 2018/8/2.
//

import UIKit
import Foundation
import LarkUIKit
import UniverseDesignIcon

final class MinePersonalInformationDetailViewCell: BaseSettingCell {
    private let titleLabel = UILabel()
    private let detailLabel = UILabel()
    private let detailIconView = UIImageView()
    private let arrowImageView = UIImageView()
    private let linkIconView = UIImageView()
    private var linkURL: String?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.detailLabel.textAlignment = .right
        self.detailLabel.textColor = UIColor.ud.textPlaceholder
        self.detailLabel.font = UIFont.systemFont(ofSize: 14)
        self.contentView.addSubview(self.detailLabel)

        self.titleLabel.textAlignment = .left
        self.titleLabel.textColor = UIColor.ud.textTitle
        self.titleLabel.font = UIFont.systemFont(ofSize: 16)
        self.titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            make.height.equalTo(52)
            make.left.equalToSuperview().offset(12)
            make.right.lessThanOrEqualTo(detailLabel.snp.left).offset(-12)
            make.width.lessThanOrEqualTo(self.frame.width * 0.6).priority(.required)
        }

        self.arrowImageView.image = UDIcon.getIconByKey(.rightOutlined).ud.withTintColor(UIColor.ud.iconN3)
        self.contentView.addSubview(self.arrowImageView)
        self.arrowImageView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
            make.right.equalTo(-12)
        }

        self.contentView.addSubview(self.detailIconView)
        self.detailIconView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
            make.trailing.equalTo(self.arrowImageView.snp.leading).offset(-4)
        }

        self.linkIconView.image = UDIcon.getIconByKey(.linkCopyOutlined).ud.withTintColor(UIColor.ud.iconN3)
        self.contentView.addSubview(self.linkIconView)
        self.linkIconView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
            make.right.equalTo(self.detailLabel.snp.left).offset(-4)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(title: String, detail: String, detailIcon: UIImage? = nil, showArrow: Bool, showLink: Bool = false) {
        self.titleLabel.text = title
        self.arrowImageView.isHidden = !showArrow
        self.detailLabel.snp.remakeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalTo(showArrow ? self.arrowImageView.snp.left : -12)
        }
        let offset = showLink ? -32 : -12
        self.titleLabel.snp.updateConstraints { make in
            make.right.lessThanOrEqualTo(detailLabel.snp.left).offset(offset)
        }
        let attri: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.ud.textPlaceholder
        ]
        self.detailLabel.attributedText = NSAttributedString(string: detail, attributes: attri)
        self.detailIconView.isHidden = detailIcon == nil
        self.detailIconView.image = detailIcon
        self.linkIconView.isHidden = !showLink
    }
}
