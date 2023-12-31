//
//  ToolBarListCell.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/6/8.
//

import UIKit
import SnapKit
import UniverseDesignIcon

class ToolBarListCell: UITableViewCell {
    static let badgeSize: CGFloat = 8
    static let textBadgeFontSize: CGFloat = 12
    static let textBadgeFontWeight = UIFont.Weight.medium
    static let titleFontSize: CGFloat = 14
    static let titleFontWeight = UIFont.Weight.regular

    var item: ToolBarItem?

    override func prepareForReuse() {
        super.prepareForReuse()
        item?.removeListener(self)
    }

    private let badgeContainerView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.alignment = .center
        return view
    }()

    private let badgeView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.colorfulRed
        view.layer.cornerRadius = 3
        view.clipsToBounds = true
        view.isHidden = true
        return view
    }()

    private lazy var textBadgeLabel: BVLabel = {
        let label = BVLabel()
        label.textColor = UIColor.ud.udtokenTagTextSYellow
        label.layer.cornerRadius = 4
        label.layer.masksToBounds = true
        label.backgroundColor = UIColor.ud.udtokenTagBgYellow
        label.textAlignment = .center
        label.textContainerInset = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 4)
        label.isHidden = true
        label.font = .systemFont(ofSize: Self.textBadgeFontSize, weight: Self.textBadgeFontWeight)
        return label
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = .systemFont(ofSize: Self.titleFontSize, weight: Self.titleFontWeight)
        return label
    }()

    private let iconView = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(item: ToolBarItem) {
        self.item = item
        item.addListener(self)
        updateViews()
    }

    private func setupSubviews() {
        backgroundColor = .clear
        let highlightedView = UIView()
        highlightedView.backgroundColor = UIColor.ud.fillHover
        highlightedView.layer.masksToBounds = true
        highlightedView.layer.cornerRadius = 6
        selectedBackgroundView = highlightedView

        contentView.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(ToolBarItemLayout.listIconSize)
        }
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(iconView.snp.right).offset(12)
            make.centerY.equalToSuperview()
            make.height.equalTo(20)
        }
        contentView.addSubview(badgeContainerView)
        badgeContainerView.snp.makeConstraints { make in
            make.left.equalTo(titleLabel.snp.right).offset(6)
            make.right.lessThanOrEqualToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
        badgeContainerView.addArrangedSubview(badgeView)
        badgeView.snp.makeConstraints { make in
            make.size.equalTo(Self.badgeSize)
        }
        badgeContainerView.addArrangedSubview(textBadgeLabel)
        textBadgeLabel.snp.makeConstraints { make in
            make.height.equalTo(18)
        }
    }

    private func updateViews() {
        guard let item = item else { return }
        iconView.image = ToolBarImageCache.image(for: item, location: .padlist)
        // 参会人标题特化
        if let participantItem = item as? ToolBarParticipantsItem {
            titleLabel.text = participantItem.listTitle
        } else {
            titleLabel.text = item.title
        }
        isUserInteractionEnabled = item.isEnabled
        titleLabel.textColor = item.isEnabled ? UIColor.ud.textTitle : UIColor.ud.textDisabled

        badgeView.isHiddenInStackView = true
        textBadgeLabel.isHiddenInStackView = true
        switch item.badgeType {
        case .dot:
            badgeView.isHiddenInStackView = false
        case .text(let text):
            textBadgeLabel.text = text
            textBadgeLabel.isHiddenInStackView = false
        default:
            break
        }
        badgeContainerView.snp.updateConstraints { make in
            make.left.equalTo(titleLabel.snp.right).offset(item.badgeType == .none ? 0 : 6)
        }
        lastTitleColor = item.titleColor
        updateGradientTitleLabel()
    }

    var lastTitleColor: ToolBarColorType = .none
    var lastBounds: CGRect = .zero

    override func layoutSubviews() {
        super.layoutSubviews()
        selectedBackgroundView?.frame =  bounds.insetBy(dx: 4, dy: 0)
        if bounds != lastBounds {
            lastBounds = bounds
            updateGradientTitleLabel()
        }
    }

    private func updateGradientTitleLabel() {
        guard let item = item else { return }
        let titleColor = lastTitleColor
        if let validTitleColor = titleColor.toRealColor(titleLabel.bounds) {
            titleLabel.textColor = validTitleColor
        } else {
            titleLabel.textColor = item.isEnabled ? UIColor.ud.textTitle : UIColor.ud.textDisabled
        }
    }
}

extension ToolBarListCell: ToolBarItemDelegate {
    func toolbarItemDidChange(_ item: ToolBarItem) {
        guard item.itemType == self.item?.itemType else { return }
        updateViews()
    }
}
