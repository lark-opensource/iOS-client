//
//  GroupCardOuterCell.swift
//  LarkChat
//
//  Created by kongkaikai on 2020/2/27.
//

import Foundation
import UIKit

final class GroupCardOuterCell: UITableViewCell {
    private let iconImageView = UIImageView()
    private let tipsLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.backgroundColor = UIColor.ud.O100

        contentView.addSubview(iconImageView)
        contentView.addSubview(tipsLabel)

        iconImageView.image = Resources.not_in_organization_icon
        iconImageView.snp.makeConstraints {
            $0.top.left.width.height.equalTo(16)
        }

        tipsLabel.numberOfLines = 0
        tipsLabel.font = .systemFont(ofSize: 14, weight: .medium)
        tipsLabel.textColor = UIColor.ud.colorfulOrange
        tipsLabel.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 14, left: 44, bottom: 14, right: 16))
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setTips(_ tips: String) {
        self.tipsLabel.text = tips
    }
}
