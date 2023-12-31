//
//  EmptyContactCell.swift
//  LarkContact
//
//  Created by lichen on 2018/9/11.
//

import UIKit
import Foundation
import SnapKit

final class EmptyContactCell: UITableViewCell {
    let titleLabel: UILabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.backgroundColor = UIColor.ud.bgBase

        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.textColor = UIColor.ud.N500
        titleLabel.text = BundleI18n.LarkContact.Lark_Legacy_NoContacts

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (maker) in
            maker.center.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
