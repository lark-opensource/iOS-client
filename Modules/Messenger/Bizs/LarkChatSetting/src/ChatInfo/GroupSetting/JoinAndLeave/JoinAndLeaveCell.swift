//
//  JoinAndLeaveCell.swift
//  LarkChat
//
//  Created by kongkaikai on 2019/10/12.
//

import UIKit
import Foundation
import LarkButton
import LarkCore
import LarkUIKit
import RichLabel
import SnapKit
import LarkBizAvatar

private let tableHorizontalMargin: CGFloat = 20
private let detailLabelMaxAvailableWidthDelta: CGFloat = 76 + 16 + tableHorizontalMargin * 2

final class JoinAndLeaveCell: BaseSettingCell {
    private let avatarView = BizAvatar()
    private let avatarSize: CGFloat = 42
    private let nameLabel = UILabel()
    private let timeLabel = UILabel()
    private let detail = LKLabel()
    private var boderLine = UIView()

    var onTapChatter: ((_ chatterID: String) -> Void)?

    var maxAvailableWidth: CGFloat {
        get {
            return detail.preferredMaxLayoutWidth + detailLabelMaxAvailableWidthDelta
        }
        set {
            detail.preferredMaxLayoutWidth = newValue - detailLabelMaxAvailableWidthDelta
        }
    }

    var item: JoinAndLeaveItem? {
        didSet {
            updateUI()
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.addSubview(avatarView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(timeLabel)
        contentView.addSubview(detail)

        avatarView.lu.addTapGestureRecognizer(action: #selector(showPersonCard), target: self, touchNumber: 1)
        avatarView.snp.makeConstraints {
            $0.width.height.equalTo(avatarSize)
            $0.top.left.equalTo(16)
        }

        nameLabel.textColor = UIColor.ud.N900
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.isUserInteractionEnabled = true
        nameLabel.font = UIFont.systemFont(ofSize: 16)
        nameLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        nameLabel.lu.addTapGestureRecognizer(action: #selector(showPersonCard), target: self, touchNumber: 1)
        nameLabel.snp.makeConstraints {
            $0.top.equalTo(16)
            $0.left.equalTo(76)
            $0.height.equalTo(22)
            $0.right.lessThanOrEqualTo(timeLabel.snp.left).inset(5)
        }

        timeLabel.textColor = UIColor.ud.N500
        timeLabel.font = UIFont.systemFont(ofSize: 12)
        timeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        timeLabel.snp.makeConstraints {
            $0.centerY.equalTo(nameLabel)
            $0.right.equalTo(-16)
        }

        detail.backgroundColor = UIColor.clear

        // ipad safe
        detail.preferredMaxLayoutWidth = UIScreen.main.bounds.width - detailLabelMaxAvailableWidthDelta
        detail.numberOfLines = 3

        detail.linkAttributes = [
            .foregroundColor: UIColor.ud.textLinkNormal
        ]

        detail.activeLinkAttributes = [
            LKBackgroundColorAttributeName: UIColor.clear
        ]

        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: detail.textColor ?? UIColor.ud.textTitle,
            .font: detail.font ?? .systemFont(ofSize: UIFont.systemFontSize)
        ]
        detail.outOfRangeText = NSMutableAttributedString(string: "\u{2026}", attributes: attributes)

        detail.snp.makeConstraints {
            $0.top.equalTo(43)
            $0.left.equalTo(76)
            $0.right.bottom.equalTo(-16)
        }

        boderLine = contentView.lu.addBottomBorder(leading: 76, color: UIColor.ud.commonTableSeparatorColor)
        selectedBackgroundView = BaseCellSelectView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    @objc
    private func showPersonCard() {
        if let chatterID = item?.chatterID {
            onTapChatter?(chatterID)
        }
    }

    private func updateUI() {
        guard let item = self.item else { return }

        avatarView.setAvatarByIdentifier(item.chatterID, avatarKey: item.avatarKey, avatarViewParams: .init(sizeType: .size(avatarSize)))
        nameLabel.text = item.name
        timeLabel.text = item.time

        detail.removeLKTextLink()
        item.textLinks?.forEach { detail.addLKTextLink(link: $0) }
        detail.attributedText = item.content
        boderLine.isHidden = !item.isShowBoaderLine
    }
}
