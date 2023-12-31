//
//  RegionPickerTableViewCell.swift
//  LarkAccount
//
//  Created by au on 2022/8/2.
//

import SnapKit
import UIKit

class RegionPickerTableViewCell: UITableViewCell {
    let nameLabel = UILabel()
    let mobileCodeLabel = UILabel()
    let bottomSeparator = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(nameLabel)
        contentView.addSubview(mobileCodeLabel)
        contentView.addSubview(bottomSeparator)

        nameLabel.textColor = UIColor.ud.textTitle
        mobileCodeLabel.textColor = UIColor.ud.textTitle

        nameLabel.font = UIFont.systemFont(ofSize: 16)
        nameLabel.adjustsFontSizeToFitWidth = true
        nameLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        mobileCodeLabel.snp.makeConstraints { (make) in
            make.left.equalTo(nameLabel.snp.right).offset(12.5)
            make.right.lessThanOrEqualToSuperview()
            make.top.bottom.equalTo(nameLabel)
        }
        mobileCodeLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

        bottomSeparator.backgroundColor = UIColor.ud.lineDividerDefault
        bottomSeparator.snp.makeConstraints { (make) in
            make.left.equalTo(nameLabel.snp.left)
            make.height.equalTo(1 / UIScreen.main.scale)
            make.bottom.equalToSuperview()
            make.right.equalToSuperview()
        }
    }

    func setCell(name: String) {
        nameLabel.text = name
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class RegionPickerHeaderView: UITableViewHeaderFooterView {
    
    var name: String? {
        didSet {
            nameLabel.text = name
        }
    }
    
    private let nameLabel = UILabel()
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = UIColor.ud.bgBodyOverlay // N50
        contentView.addSubview(nameLabel)
        nameLabel.font = UIFont.systemFont(ofSize: 14)
        nameLabel.textColor = UIColor.ud.N500
        nameLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
