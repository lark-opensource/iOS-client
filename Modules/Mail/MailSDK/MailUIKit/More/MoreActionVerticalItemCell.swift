//
//  MoreActionVerticalManageCell.swift
//  MailSDK
//
//  Created by zhaoxiongbin on 2020/8/9.
//

import Foundation
import LarkInteraction

class MoreActionVerticalItemCell: UITableViewCell {
    private let iconImageView = UIImageView()
    private let nameLabel = UILabel()
    private let bottomLineView = UIView()

    private static let offset: CGFloat = 12
    private static let topOffset: CGFloat = 13
    private static let minLabelHeight: CGFloat = 22
    private static let iconSize = CGSize(width: 20, height: 20)
    private static let labelFont = UIFont.systemFont(ofSize: 16)

    static func cellHeightFor(title: String, cellWidth: CGFloat) -> CGFloat {
        let textWidth = cellWidth - MoreActionVerticalItemCell.iconSize.width - 3 * MoreActionVerticalItemCell.offset
        let titleHeight = (title as NSString).boundingRect(with: CGSize(width: textWidth, height: CGFloat.greatestFiniteMagnitude),
                                                           options: .usesLineFragmentOrigin,
                                                           attributes: [.font: MoreActionVerticalItemCell.labelFont],
                                                           context: nil).height
        let labelHeight = min(ceil(MoreActionVerticalItemCell.labelFont.lineHeight * 2), ceil(titleHeight))
        return labelHeight + 2 * MoreActionVerticalItemCell.topOffset
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupSubviews()
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        contentView.backgroundColor = highlighted ? UIColor.ud.fillHover : UIColor.ud.bgFloat
    }

    func updateBottomLine(isHidden: Bool) {
        bottomLineView.isHidden = isHidden
    }

    private func setupSubviews() {
        selectionStyle = .none
        nameLabel.font = MoreActionVerticalItemCell.labelFont
        nameLabel.backgroundColor = .clear
        nameLabel.textColor = UIColor.ud.textTitle
        nameLabel.numberOfLines = 2
        iconImageView.tintColor = UIColor.ud.iconN1
        bottomLineView.backgroundColor = UIColor.ud.lineDividerDefault
        backgroundColor = UIColor.ud.bgFloat

        contentView.addSubview(iconImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(bottomLineView)

        iconImageView.snp.makeConstraints { (make) in
            make.left.equalTo(MoreActionVerticalItemCell.offset)
            make.centerY.equalToSuperview()
            make.size.equalTo(MoreActionVerticalItemCell.iconSize)
        }
        nameLabel.snp.makeConstraints { (make) in
            make.left.equalTo(iconImageView.snp.right).offset(MoreActionVerticalItemCell.offset)
            make.right.equalTo(-MoreActionVerticalItemCell.offset)
            make.top.equalToSuperview().offset(MoreActionVerticalItemCell.topOffset)
            make.bottom.equalToSuperview().offset(-MoreActionVerticalItemCell.topOffset)
            make.height.greaterThanOrEqualTo(MoreActionVerticalItemCell.minLabelHeight)
        }
        bottomLineView.snp.makeConstraints { (make) in
            make.left.equalTo(nameLabel)
            make.bottom.right.equalToSuperview()
            make.height.equalTo(0.5)
        }
        if #available(iOS 13.4, *) {
            let pointer = PointerInteraction(
                style: PointerStyle(
                effect: .hover()
                )
            )
            self.addLKInteraction(pointer)
        }
    }

    func setup(title: String, icon: UIImage, disable: Bool, tintColor: UIColor?) {
        nameLabel.text = title
        iconImageView.image = icon
        if disable {
            nameLabel.textColor = UIColor.ud.textDisabled
            iconImageView.image = icon.ud.withTintColor(UIColor.ud.iconDisabled)
        } else {
            nameLabel.textColor = UIColor.ud.textTitle
            if let iconTintColor = tintColor {
                iconImageView.image = icon.ud.withTintColor(iconTintColor)
            } else {
                iconImageView.image = icon
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
