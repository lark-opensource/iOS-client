//
//  GroupSettingApproveCellAndItem.swift
//  LarkChat
//
//  Created by KKK on 2019/4/26.
//

import Foundation
import UIKit
import SnapKit
import LarkUIKit
import LarkCore
import LarkBadge

// MARK: - 入群申请 - item
struct GroupSettingApproveItem: GroupSettingItemProtocol {
    var type: CommonCellItemType
    var cellIdentifier: String
    var style: SeparaterStyle
    var title: String
    var detail: String
    var status: String?
    var cellEnable = true
    var badgePath: Path?
    var showBadge: Bool = false
    var tapHandler: ChatInfoTapHandler
}

// MARK: - 入群申请 - cell
final class GroupSettingApproveCell: GroupSettingCell {
    private var statusLabel = UILabel()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(statusLabel)

        defaultLayoutArrow()
        statusLabel.textColor = UIColor.ud.textPlaceholder
        statusLabel.font = UIFont.systemFont(ofSize: 14)
        statusLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        statusLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalTo(-32)
            make.left.greaterThanOrEqualTo(titleLabel.snp.right).offset(5)
        }

        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel.numberOfLines = 0
        titleLabel.snp.makeConstraints { (maker) in
            maker.top.equalTo(15)
            maker.left.equalTo(16)
        }

        detailLabel.numberOfLines = 2
        detailLabel.snp.makeConstraints { (maker) in
            maker.top.equalTo(37)
            maker.left.equalTo(16)
            maker.right.lessThanOrEqualTo(statusLabel.snp.left).offset(-6)
            maker.bottom.equalTo(-13)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setCellInfo() {
        guard let item = item as? GroupSettingApproveItem else {
            assert(false, "\(self):item.Type error")
            return
        }
        titleLabel.alpha = item.cellEnable ? 1 : 0.4
        detailLabel.alpha = item.cellEnable ? 1 : 0.4
        statusLabel.alpha = item.cellEnable ? 1 : 0.4
        titleLabel.text = item.title
        if item.detail.isEmpty {
            titleLabel.snp.remakeConstraints { (maker) in
                maker.top.equalTo(15)
                maker.left.equalTo(16)
                maker.bottom.equalTo(-15)
            }
            detailLabel.snp.removeConstraints()
        } else {
            titleLabel.snp.remakeConstraints { (maker) in
                maker.top.equalTo(15)
                maker.left.equalTo(16)
            }
            detailLabel.snp.remakeConstraints { (maker) in
                maker.top.equalTo(titleLabel.snp.bottom).offset(5)
                maker.left.equalTo(16)
                maker.right.lessThanOrEqualTo(statusLabel.snp.left).offset(-6)
                maker.bottom.equalTo(-13)
            }
        }
        detailLabel.text = item.detail
        statusLabel.text = item.status

        titleLabel.badge.removeAllObserver()
        if let path = item.badgePath {
            titleLabel.badge.observe(for: path)
            if item.showBadge {
                BadgeManager.setBadge(path, type: .dot(.pin))
                titleLabel.badge.set(type: .dot(.pin))
                titleLabel.badge.set(offset: CGPoint(x: 11, y: 10))
            } else {
                BadgeManager.clearBadge(path)
            }
            titleLabel.uiBadge.badgeView?.isHidden = !item.showBadge
        } else {
            titleLabel.uiBadge.badgeView?.isHidden = true
        }

        layoutSeparater(item.style)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        if selected, let item = item as? GroupSettingApproveItem, item.cellEnable {
            item.tapHandler(self)
        }
        super.setSelected(selected, animated: animated)
    }
}
