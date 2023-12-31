//
//  ChatInfoDescriptionCellAndItem.swift
//  LarkChat
//
//  Created by kongkaikai on 2019/6/12.
//

import UIKit
import Foundation
import SnapKit
import LarkUIKit
import LarkCore
import RichLabel

// MARK: - Oncall 群描述 - item
struct ChatInfoDescriptionItem: CommonCellItemProtocol {
    var type: CommonCellItemType
    var cellIdentifier: String
    var style: SeparaterStyle
    var title: String
    var description: String
    var tapHandler: ChatInfoTapHandler
}

// MARK: - Oncall 群描述 - cell
final class ChatInfoDescriptionCell: ChatInfoCell {
    private var titleLabel: UILabel
    private var descriptionLabel: LKLabel

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        titleLabel = UILabel()
        descriptionLabel = LKLabel()

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(titleLabel)
        contentView.addSubview(descriptionLabel)

        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.snp.makeConstraints { (maker) in
            maker.left.top.right.equalToSuperview().inset(UIEdgeInsets(top: 12.5, left: 16, bottom: 0, right: 16))
        }

        descriptionLabel.font = UIFont.systemFont(ofSize: 14)
        descriptionLabel.textColor = UIColor.ud.textPlaceholder
        descriptionLabel.backgroundColor = UIColor.clear
        descriptionLabel.numberOfLines = 4
        descriptionLabel.delegate = self

        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: descriptionLabel.textColor ?? UIColor.ud.textTitle,
            .font: descriptionLabel.font ?? UIFont.systemFont(ofSize: UIFont.systemFontSize)
        ]
        descriptionLabel.outOfRangeText = NSMutableAttributedString(string: "\u{2026}", attributes: attributes)

        descriptionLabel.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview().inset(UIEdgeInsets(top: 37, left: 16, bottom: 12, right: 16))
        }

        arrow.snp.remakeConstraints { (make) in
            make.centerY.equalTo(titleLabel)
            make.right.equalToSuperview().offset(-16)
        }
        arrow.isHidden = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setCellInfo() {
        guard let descriptionItem = item as? ChatInfoDescriptionItem else {
            assert(false, "\(self):item.Type error")
            return
        }

        titleLabel.text = descriptionItem.title
        descriptionLabel.text = descriptionItem.description

        layoutSeparater(descriptionItem.style)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        if !arrow.isHidden, selected, let item = self.item as? ChatInfoDescriptionItem {
            item.tapHandler(self)
        }
        super.setSelected(selected, animated: animated)
    }

    override func updateAvailableMaxWidth(_ width: CGFloat) {
        super.updateAvailableMaxWidth(width)

        descriptionLabel.preferredMaxLayoutWidth = width - 32
        descriptionLabel.invalidateIntrinsicContentSize()
    }
}

extension ChatInfoDescriptionCell: LKLabelDelegate {
    func shouldShowMore(_ label: LKLabel, isShowMore: Bool) {
        self.arrow.isHidden = !isShowMore
        self.selectionStyle = isShowMore ? .default : .none
    }
}
