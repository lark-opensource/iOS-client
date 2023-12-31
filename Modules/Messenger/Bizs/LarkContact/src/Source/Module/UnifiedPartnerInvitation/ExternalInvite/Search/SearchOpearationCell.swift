//
//  SearchOpearationCell.swift
//  LarkContact
//
//  Created by shizhengyu on 2019/9/24.
//

import UIKit
import Foundation
import LarkUIKit
import LarkModel

final class SearchOpearationCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        layoutPageSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bindWithSearchContent(content: String) {
        titleLabel.attributedText = getAtrributeText(prefix: BundleI18n.LarkContact.Lark_UserGrowth_InvitePeopleSearchCTA,
                                                     message: content)
    }

    private func layoutPageSubviews() {
        contentView.backgroundColor = UIColor.ud.N00
        contentView.addSubview(iconView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(bottomLine)
        iconView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(iconView.snp.right).offset(12)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-12)
            make.top.equalToSuperview()
        }
        bottomLine.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview()
            make.height.equalTo(1)
        }
    }

    private lazy var iconView: UIImageView = {
        let view = UIImageView()
        view.image = Resources.add_contact_icon
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.N900
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 16)
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private lazy var bottomLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgBody
        return view
    }()

    private func getAtrributeText(prefix: String, message: String) -> NSAttributedString {
        let prefix_attrs: [NSAttributedString.Key: Any] =
            [.font: UIFont.systemFont(ofSize: 16),
             .foregroundColor: UIColor.ud.colorfulBlue]
        let message_attrs: [NSAttributedString.Key: Any] =
            [.font: UIFont.systemFont(ofSize: 16),
             .foregroundColor: UIColor.ud.N900]
        let final = NSMutableAttributedString(string: "\(prefix)\(message)")
        final.addAttributes(prefix_attrs, range: NSRange(location: 0, length: prefix.count))
        final.addAttributes(message_attrs, range: NSRange(location: prefix.count, length: message.count))
        return final
    }
}
