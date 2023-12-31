//
//  AddContactSearchTableViewCell.swift
//  LarkContact
//
//  Created by ChalrieSu on 2018/9/14.
//

import Foundation
import UIKit
import LarkUIKit

final class AddContactSearchTableViewCell: UITableViewCell {

    private let inviteIcon = UIImageView()
    private let searchLabel = UILabel()
    private let searchContentLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(inviteIcon)
        inviteIcon.image = Resources.invite_search_contacts
        inviteIcon.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 20, height: 20))
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }

        contentView.addSubview(searchLabel)
        searchLabel.font = UIFont.systemFont(ofSize: 14)
        searchLabel.textColor = UIColor.ud.N900
        searchLabel.text = BundleI18n.LarkContact.Lark_Legacy_Search + ":"
        searchLabel.snp.makeConstraints { (make) in
            make.left.equalTo(inviteIcon.snp.right).offset(6)
            make.centerY.equalToSuperview()
        }

        contentView.addSubview(searchContentLabel)
        searchContentLabel.font = UIFont.systemFont(ofSize: 14)
        searchContentLabel.textColor = UIColor.ud.colorfulBlue
        searchContentLabel.snp.makeConstraints { (make) in
            make.left.equalTo(searchLabel.snp.right)
            make.centerY.equalToSuperview()
            make.right.lessThanOrEqualToSuperview().offset(-20)
        }

        contentView.lu.addBottomBorder(color: UIColor.ud.commonTableSeparatorColor)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setSearchText(_ text: String?) {
        searchContentLabel.text = text
    }
}
