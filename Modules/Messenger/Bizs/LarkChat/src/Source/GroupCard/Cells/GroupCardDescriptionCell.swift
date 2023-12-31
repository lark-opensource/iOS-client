//
//  GroupCardDescriptionCell.swift
//  Lark
//
//  Created by chengzhipeng-bytedance on 2017/10/20.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LarkUIKit

final class GroupCardBaseCell: UITableViewCell {
    private(set) var titleLabel = UILabel()
    private(set) var subTitleLabel = UILabel()
    private var subLabelHandler: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectedBackgroundView = BaseCellSelectView()

        backgroundColor = UIColor.ud.bgBody
        contentView.backgroundColor = UIColor.ud.bgBody

        titleLabel.textColor = UIColor.ud.N900
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        titleLabel.textAlignment = .left
        self.contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(22)
            make.left.equalTo(16)
            make.bottom.equalTo(-22)
        }
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        subTitleLabel.textColor = UIColor.ud.N500
        subTitleLabel.textAlignment = .left
        subTitleLabel.numberOfLines = 0
        self.contentView.addSubview(subTitleLabel)
        subTitleLabel.snp.makeConstraints { (make) in
            make.left.greaterThanOrEqualTo(titleLabel.snp.right).offset(20)
            make.top.equalTo(22)
            make.bottom.equalTo(-22)
            make.right.equalTo(-16)
        }
        subTitleLabel.isUserInteractionEnabled = true
        subTitleLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(subLabelTapped)))

        self.lu.addBottomBorder(leading: 16, trailing: -16)
    }

    @objc
    func subLabelTapped() {
        self.subLabelHandler?()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func set(titleLabelText: String,
             subTitleAttributedText: NSAttributedString,
             subLabelHandler: (() -> Void)? = nil) {
        self.titleLabel.text = titleLabelText
        self.subTitleLabel.attributedText = subTitleAttributedText
        self.subLabelHandler = subLabelHandler
    }
}
