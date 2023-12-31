//
//  ChatInfoShareCellAndItem.swift
//  Lark
//
//  Created by K3 on 2018/8/9.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import LarkUIKit
import LarkCore
import LarkBadge

// MARK: - 分享群 - item
struct ChatInfoShareModel: CommonCellItemProtocol {
    var type: CommonCellItemType
    var cellIdentifier: String
    var style: SeparaterStyle
    var title: String
    var badgePath: Path?
    var showBadge: Bool
    var arrowSize: CGSize
    var tapHandler: ChatInfoTapHandler

    init(type: CommonCellItemType,
         cellIdentifier: String,
         style: SeparaterStyle,
         title: String,
         badgePath: Path? = nil,
         showBadge: Bool = false,
         arrowSize: CGSize = CGSize(width: 12, height: 12),
         tapHandler: @escaping ChatInfoTapHandler) {
        self.type = type
        self.cellIdentifier = cellIdentifier
        self.style = style
        self.title = title
        self.arrowSize = arrowSize
        self.badgePath = badgePath
        self.showBadge = showBadge
        self.tapHandler = tapHandler
    }
}

// MARK: - 分享群 - cell
final class ChatInfoShareCell: ChatInfoCell {
    private var titleLabel: UILabel
    struct Config {
        static let titleLabelHeight: CGFloat = 22
        static let titleLeftMarigin: CGFloat = 16
        static let titleVerticalMarigin: CGFloat = 13
        static let cellHight: CGFloat = titleLabelHeight + titleVerticalMarigin * 2
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        titleLabel = UILabel()

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(titleLabel)
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.snp.makeConstraints { (maker) in
            maker.height.equalTo(Config.titleLabelHeight)
            maker.top.equalTo(Config.titleVerticalMarigin)
            maker.left.equalTo(Config.titleLeftMarigin)
            maker.bottom.equalTo(-Config.titleVerticalMarigin)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setCellInfo() {
        guard let shareItem = item as? ChatInfoShareModel else {
            assert(false, "\(self):item.Type error")
            return
        }

        titleLabel.text = shareItem.title

        titleLabel.badge.removeAllObserver()
        if let path = shareItem.badgePath {
            titleLabel.badge.observe(for: path)
            titleLabel.badge?.isHidden = !shareItem.showBadge
            if shareItem.showBadge {
                BadgeManager.setBadge(path, type: .dot(.pin))
                titleLabel.badge.set(type: .dot(.pin))
                titleLabel.badge.set(offset: CGPoint(x: 11, y: 10))
            } else {
                BadgeManager.clearBadge(path)
            }
        } else {
            titleLabel.badge?.isHidden = true
        }
        arrow.snp.updateConstraints { make in
            make.width.equalTo(shareItem.arrowSize.width)
            make.height.equalTo(shareItem.arrowSize.height)
        }

        layoutSeparater(shareItem.style)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        if selected, let shareItem = self.item as? ChatInfoShareModel {
            shareItem.tapHandler(self)
        }
        super.setSelected(selected, animated: animated)
    }
}

// MARK: - 群管理 - item
typealias ChatInfoSettingModel = ChatInfoShareModel

// MARK: - 群管理 - cell
typealias ChatInfoSettingCell = ChatInfoShareCell
