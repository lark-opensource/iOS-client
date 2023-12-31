//
//  MailAccountDetailCell.swift
//  LarkContact
//
//  Created by Quanze Gao on 2022/4/18.
//

import Foundation
import UIKit

final class MailAccountDetailCell: UITableViewCell {
    private let separator = UIView()
    private let titleLabel: UILabel = UILabel()
    private let iconView: UIImageView = UIImageView()
    private let arrowIcon: UIImageView = UIImageView(image: Resources.dark_right_arrow)

    func config(icon: UIImage, title: String, needSeparator: Bool) {
        iconView.image = icon
        titleLabel.text = title
        separator.isHidden = !needSeparator
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.backgroundColor = UIColor.ud.bgBody

        setupBackgroundViews(highlightOn: true)
        setBackViewLayout(UIEdgeInsets(top: 3.0, left: 6.0, bottom: 3.0, right: 6.0), nil)

        contentView.addSubview(iconView)
        iconView.contentMode = .scaleToFill
        iconView.tintColor = UIColor.ud.primaryContentDefault
        iconView.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.width.height.equalTo(20)
            make.centerY.equalToSuperview()
        }

        contentView.addSubview(titleLabel)
        titleLabel.font = .systemFont(ofSize: 16)
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.numberOfLines = 1
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(48)
            make.centerY.equalToSuperview()
            make.right.lessThanOrEqualToSuperview()
        }

        contentView.addSubview(self.arrowIcon)
        arrowIcon.setContentHuggingPriority(.required, for: .horizontal)
        arrowIcon.setContentCompressionResistancePriority(.required, for: .horizontal)
        arrowIcon.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-21)
        }

        contentView.addSubview(self.separator)
        separator.backgroundColor = .ud.lineDividerDefault
        separator.snp.makeConstraints { (make) in
            make.right.bottom.equalToSuperview()
            make.left.equalToSuperview().inset(16)
            make.height.equalTo(0.6)
        }
    }

    required  init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        setBackViewColor(highlighted ? UIColor.ud.fillHover : UIColor.ud.bgBody)
    }
}
