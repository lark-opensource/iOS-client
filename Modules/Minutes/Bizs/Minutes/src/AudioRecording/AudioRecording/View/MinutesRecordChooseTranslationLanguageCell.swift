//
//  MinutesRecordChooseTranslationLanguageCell.swift
//  Minutes
//
//  Created by panzaofeng on 2021/5/27.
//

import UIKit

class MinutesRecordChooseTranslationLanguageCell: UITableViewCell {
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.backgroundColor = UIColor.ud.bgFloat

        contentView.addSubview(titleLabel)

        titleLabel.snp.makeConstraints { (maker) in
            maker.left.equalToSuperview().offset(16)
            maker.right.equalToSuperview().offset(-12)
            maker.height.equalTo(20)
            maker.centerY.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
