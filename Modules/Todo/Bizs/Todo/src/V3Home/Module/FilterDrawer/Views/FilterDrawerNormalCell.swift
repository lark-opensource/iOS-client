//
//  FilterDrawerCell.swift
//  Todo
//
//  Created by baiyantao on 2022/8/17.
//

import Foundation
import LarkUIKit
import UIKit
import UniverseDesignIcon
import UniverseDesignFont

struct FilterDrawerNormalCellData {
    var containerGuid: String

    var icon: UIImage
    var title: String
    var countText: String?
    var isSelected: Bool = false
}

extension FilterDrawerNormalCellData {
    func backgroundColor(_ highlighted: Bool) -> UIColor {
        if isSelected {
            return UIColor.ud.primaryFillSolid01
        }
        return highlighted ? UIColor.ud.fillHover : UIColor.ud.bgBody
    }
}

final class FilterDrawerNormalCell: UITableViewCell {

    var viewData: FilterDrawerNormalCellData? {
        didSet {
            guard let data = viewData else { return }
            iconView.image = data.icon.ud.withTintColor(
                data.isSelected ? UIColor.ud.textLinkHover : UIColor.ud.iconN2
            )
            titleLabel.text = data.title
            countLabel.text = data.countText

            titleLabel.font = data.isSelected ? UDFont.systemFont(ofSize: 16, weight: .semibold) : UDFont.systemFont(ofSize: 16)
            titleLabel.textColor = data.isSelected ? UIColor.ud.primaryContentDefault : UIColor.ud.textTitle
            countLabel.textColor = data.isSelected ? UIColor.ud.primaryContentDefault : UIColor.ud.textCaption
        }
    }

    private lazy var iconView = UIImageView()
    private lazy var titleLabel = UILabel()
    private lazy var countLabel = initCountLabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setupBackgroundViews(highlightOn: true)
        setBackViewLayout(UIEdgeInsets(top: 1, left: 16, bottom: 1, right: 16), 6)

        let containerView = UIView()
        contentView.addSubview(containerView)
        containerView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.left.equalToSuperview().offset(8)
            $0.right.equalToSuperview().offset(-8)
        }

        containerView.addSubview(iconView)
        iconView.snp.makeConstraints {
            $0.width.height.equalTo(20)
            $0.centerY.equalToSuperview()
            $0.left.equalToSuperview().offset(16)
        }

        containerView.addSubview(countLabel)
        countLabel.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.right.equalToSuperview().offset(-16)
        }

        containerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.left.equalTo(iconView.snp.right).offset(12)
            $0.right.lessThanOrEqualTo(countLabel.snp.left).offset(-8)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        setBackViewColor(viewData?.backgroundColor(highlighted) ?? UIColor.ud.bgBody)
    }

    private func initCountLabel() -> UILabel {
        let label = UILabel()
        label.font = UDFont.systemFont(ofSize: 14)
        return label
    }
}
