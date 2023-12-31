//
//  MobileCodeSelectCell.swift
//  LarkLogin
//
//  Created by 姚启灏 on 2019/1/8.
//

import Foundation
import UIKit
import SnapKit

final class MobileCodeSelectCell: UITableViewCell {
    let nameLabel = UILabel()
    let mobileCodeLabel = UILabel()
    let bottomSeperator = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.contentView.addSubview(nameLabel)
        self.contentView.addSubview(mobileCodeLabel)
        self.contentView.addSubview(bottomSeperator)

        nameLabel.textColor = UIColor.ud.textTitle
        mobileCodeLabel.textColor = UIColor.ud.textTitle

        nameLabel.font = UIFont.systemFont(ofSize: 16)
        nameLabel.adjustsFontSizeToFitWidth = true
        nameLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(13)
            make.bottom.equalToSuperview().offset(-13)
        }
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        mobileCodeLabel.snp.makeConstraints { (make) in
            make.left.equalTo(nameLabel.snp.right).offset(12.5)
            make.right.lessThanOrEqualToSuperview()
            make.top.bottom.equalTo(nameLabel)
        }
        mobileCodeLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

        bottomSeperator.backgroundColor = UIColor.ud.lineDividerDefault
        bottomSeperator.snp.makeConstraints { (make) in
            make.left.equalTo(nameLabel.snp.left)
            make.height.equalTo(1 / UIScreen.main.scale)
            make.bottom.equalToSuperview()
            make.right.equalToSuperview()
        }
    }

    func setCell(name: String, code: String) {
        self.nameLabel.text = name
        self.mobileCodeLabel.text = code
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
