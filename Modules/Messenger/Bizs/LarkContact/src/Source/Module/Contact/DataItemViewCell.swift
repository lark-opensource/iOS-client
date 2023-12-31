//
//  ContactItemViewCell.swift
//  LarkContact
//
//  Created by 李晨 on 2019/9/5.
//

import Foundation
import LarkUIKit
import SnapKit
import LarkModel
import LarkCore
import LarkTag
import UIKit

final class DataItemViewCell: UITableViewCell {

    var iconView: UIImageView = UIImageView()
    private let iconSize: CGFloat = 20
    private var titleLabel: UILabel = UILabel()
    private var badgeStackView: UIStackView = UIStackView()
    private var badageLabel: PaddingUILabel = PaddingUILabel()
    private lazy var arrowIcon: UIImageView = {
        let arrowIcon = UIImageView(image: Resources.dark_right_arrow)
        arrowIcon.setContentCompressionResistancePriority(.required, for: .horizontal)
        arrowIcon.setContentHuggingPriority(.required, for: .horizontal)
        return arrowIcon
    }()
    var dataItem: DataOfRow? {
        didSet {
            self.iconView.image = dataItem?.icon
            if dataItem?.isCircleIcon == true {
                self.iconView.layer.cornerRadius = iconSize / 2
                self.iconView.layer.masksToBounds = true
            } else {
                self.iconView.layer.cornerRadius = 0
                self.iconView.layer.masksToBounds = false
            }

            self.titleLabel.text = dataItem?.title
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.backgroundColor = UIColor.ud.bgBody

        setupBackgroundViews(highlightOn: true)
        setBackViewLayout(UIEdgeInsets(top: 3.0, left: 6.0, bottom: 3.0, right: 6.0), nil)

        contentView.addSubview(iconView)
        iconView.contentMode = .scaleToFill
        iconView.snp.makeConstraints { (make) in
            make.width.height.equalTo(iconSize)
            make.centerY.equalToSuperview()
            make.left.equalTo(16)
        }

        contentView.addSubview(titleLabel)
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.numberOfLines = 1
        titleLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalTo(52)
            make.right.lessThanOrEqualToSuperview()
        }

        // arrow
        contentView.addSubview(self.arrowIcon)
        self.arrowIcon.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-21)
            make.centerY.equalToSuperview()
        }

        // badage
        badageLabel.layer.cornerRadius = 8
        badageLabel.layer.masksToBounds = true
        badageLabel.paddingLeft = 4
        badageLabel.paddingRight = 4
        badageLabel.font = UIFont.systemFont(ofSize: 12)
        badageLabel.textColor = UIColor.ud.primaryOnPrimaryFill
        badageLabel.textAlignment = .center
        badageLabel.color = UIColor.ud.colorfulRed

        badgeStackView.axis = .horizontal
        badgeStackView.alignment = .fill
        badgeStackView.spacing = 6
        badgeStackView.distribution = .fillEqually
        badgeStackView.addArrangedSubview(badageLabel)
        contentView.addSubview(badgeStackView)
        badgeStackView.snp.makeConstraints { (make) in
            make.right.equalTo(arrowIcon.snp.left).offset(-10)
            make.centerY.equalToSuperview()
        }
        badageLabel.snp.makeConstraints { (make) in
            make.width.greaterThanOrEqualTo(16).priority(999)
            make.height.equalTo(16)
        }

        badgeStackView.isHidden = true
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        // 每次cell复用时，重置状态
        badgeStackView.isHidden = true
        self.badageLabel.text = nil
    }

    required  init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateBadge(isHidden: Bool, badge: Int) {
        self.badgeStackView.isHidden = isHidden
        self.badageLabel.text = String(badge)
    }

    func setArrowIcon(hide: Bool) {
        arrowIcon.isHidden = hide
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        setBackViewColor(highlighted ? UIColor.ud.fillHover : UIColor.ud.bgBody)
    }
}
