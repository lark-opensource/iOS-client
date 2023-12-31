//
//  BaseSearchInChatTableViewCell.swift
//  LarkSearch
//
//  Created by zc09v on 2018/8/23.
//

import Foundation
import UIKit
import LarkModel
import LarkCore
import LarkUIKit
import LarkBizAvatar
import LarkSDKInterface
import LarkSearchCore

protocol BaseSearchInChatTableViewCellProtocol: UITableViewCell {
    func update(viewModel: SearchInChatCellViewModel, currentSearchText: String)
}

class BaseSearchInChatTableViewCell: UITableViewCell, BaseSearchInChatTableViewCellProtocol {
    private(set) var viewModel: SearchInChatCellViewModel?
    let avatarSize: CGFloat = 48
    let avatarView: BizAvatar
    let titleLabel: UILabel
    let subtitleLabel: UILabel
    let textWarrperView: UIView

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        avatarView = BizAvatar()
        avatarView.avatar.ud.setMaskView()
        titleLabel = UILabel()
        subtitleLabel = UILabel()
        textWarrperView = UIView()
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        let layoutGuide = UILayoutGuide()
        contentView.addLayoutGuide(layoutGuide)
        layoutGuide.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            make.height.equalTo(67).priority(.high)
        }

        selectedBackgroundView = SearchCellSelectedView()
        self.backgroundColor = UIColor.ud.bgBody

        self.contentView.addSubview(avatarView)
        avatarView.snp.makeConstraints({ make in
            make.size.equalTo(CGSize(width: avatarSize, height: avatarSize))
            make.left.equalTo(16)
            make.centerY.equalToSuperview()
        })

        self.contentView.addSubview(textWarrperView)
        textWarrperView.snp.makeConstraints { (make) in
            make.left.equalTo(self.avatarView.snp.right).offset(12)
            make.centerY.equalTo(avatarView)
            make.right.equalToSuperview().offset(-16)
        }

        textWarrperView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints({ make in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.lessThanOrEqualToSuperview()
        })
        titleLabel.setContentCompressionResistancePriority(UILayoutPriority.defaultLow, for: NSLayoutConstraint.Axis.horizontal)
        textWarrperView.addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints({ make in
            make.left.equalToSuperview()
            make.top.equalTo(self.titleLabel.snp.bottom).offset(7)
            make.bottom.equalToSuperview()
            make.right.lessThanOrEqualToSuperview()
        })
        subtitleLabel.setContentCompressionResistancePriority(UILayoutPriority.defaultLow, for: NSLayoutConstraint.Axis.horizontal)
    }

    func update(viewModel: SearchInChatCellViewModel, currentSearchText: String) {
        self.viewModel = viewModel
        if viewModel.enableDocCustomAvatar {
            avatarView.setMiniIcon(viewModel.data?.meta?.miniIcon)
        } else {
            avatarView.setMiniIcon(nil)
        }
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        updateCellStyle(animated: animated)
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        updateCellStyle(animated: animated)
    }

    override func layoutSubviews() {
        let frame = self.contentView.frame.inset(by: UIEdgeInsets(top: 1, left: 6, bottom: 1, right: 6))
        self.selectedBackgroundView?.frame = frame
        self.selectedBackgroundView?.layer.cornerRadius = 8
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
