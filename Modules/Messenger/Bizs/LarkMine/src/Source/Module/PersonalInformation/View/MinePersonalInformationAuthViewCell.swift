//
//  MinePersonalInformationAuthViewCell.swift
//  LarkMine
//
//  Created by Hayden Wang on 2021/8/23.
//

import Foundation
import UIKit
import LarkCore
import LarkUIKit
import UniverseDesignIcon

final class MinePersonalInformationAuthViewCell: BaseSettingCell {
    private lazy var detailContainer: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 4
        stack.alignment = .center
        return stack
    }()
    private let titleLabel = UILabel()
    private let detailLabel = UILabel()
    private let authView = AuthTagView()
    private let arrowImageView = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.detailLabel.textAlignment = .right
        self.detailLabel.textColor = UIColor.ud.textPlaceholder
        self.detailLabel.font = UIFont.systemFont(ofSize: 14)

        self.titleLabel.textAlignment = .left
        self.titleLabel.textColor = UIColor.ud.textTitle
        self.titleLabel.font = UIFont.systemFont(ofSize: 16)
        self.titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            make.height.equalTo(52)
            make.leading.equalToSuperview().offset(12)
        }

        self.arrowImageView.image = UDIcon.getIconByKey(.rightOutlined).ud.withTintColor(UIColor.ud.iconN3)

        contentView.addSubview(detailContainer)
        detailContainer.addArrangedSubview(detailLabel)
        detailContainer.addArrangedSubview(authView)
        detailContainer.addArrangedSubview(arrowImageView)
        detailLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        authView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        detailContainer.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.height.equalTo(18)
            make.trailing.equalToSuperview().offset(-12)
            make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(12)
        }
        arrowImageView.snp.makeConstraints { (make) in
            make.width.height.equalTo(16)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(title: String, detail: String, hasAuth: Bool, isAuth: Bool, showArrow: Bool) {
        self.titleLabel.text = title
        let attri: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.ud.textPlaceholder
        ]
        self.detailLabel.attributedText = NSAttributedString(string: detail, attributes: attri)
        self.authView.setState(hasAuth: hasAuth, isAuth: isAuth)
        self.arrowImageView.isHidden = !showArrow
    }
}
