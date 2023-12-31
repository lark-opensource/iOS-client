//
//  ChatInfoMemberCellAndItem.swift
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
import LarkModel
import LarkFeatureGating

struct AvatarModel {
    var avatarKey: String
    var medalKey: String
}

// MARK: - 群成员 - item
struct ChatInfoMemberModel: CommonCellItemProtocol {
    var type: CommonCellItemType
    var cellIdentifier: String
    var style: SeparaterStyle
    var title: String
    var avatarModels: [AvatarModel]
    var chatUserCount: Int32?
    var memberIds: [String]
    var descriptionText: String
    var hasAccess: Bool
    var isShowMember: Bool
    var isShowDeleteButton: Bool
    var chat: Chat
    var tapHandler: ChatInfoTapHandler
    var addNewMember: ChatInfoTapHandler
    var selectedMember: (String) -> Void
    var deleteMember: ChatInfoTapHandler?
}

// MARK: - 群成员 - cell
final class ChatInfoMemberCell: ChatInfoCell {
    fileprivate var titleLabel: UILabel = .init()
    fileprivate var countLabel: UILabel = .init()
    fileprivate var membersView: NewChatInfoMemberView!
    private var maxWidth: CGFloat = UIScreen.main.bounds.width

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        countLabel = UILabel()
        countLabel.font = UIFont.systemFont(ofSize: 14)
        countLabel.textColor = UIColor.ud.textPlaceholder
        countLabel.textAlignment = .right
        contentView.addSubview(countLabel)

        titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 999), for: .horizontal)
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (maker) in
            maker.top.left.equalToSuperview().inset(UIEdgeInsets(top: 16, left: 16, bottom: 0, right: 0))
            maker.right.lessThanOrEqualTo(countLabel.snp.left).offset(-12)
            maker.height.equalTo(24)
        }

        membersView = NewChatInfoMemberView()
        contentView.addSubview(membersView)
        membersView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview().inset(UIEdgeInsets(top: 52, left: 0, bottom: 14, right: 0))
            maker.height.equalTo(32)
        }

        countLabel.snp.makeConstraints { (maker) in
            maker.centerY.equalTo(titleLabel)
            maker.right.equalTo(arrow.snp.left).offset(-8)
            maker.height.equalTo(20)
        }

        arrow.snp.remakeConstraints { (maker) in
            maker.centerY.equalTo(titleLabel)
            maker.right.equalToSuperview().offset(-16)
            maker.width.height.equalTo(12)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setCellInfo() {
        guard let item = item as? ChatInfoMemberModel else {
            assert(false, "\(self):item.Type error")
            return
        }

        titleLabel.text = item.title
        if let chatUserCount = item.chatUserCount {
            let countText = "\(chatUserCount)"
            countLabel.text = countText
            countLabel.isHidden = false
        } else {
            countLabel.isHidden = true
        }
        membersView.set(avatarModels: item.avatarModels,
                        memberIds: item.memberIds,
                        hasAccess: item.hasAccess,
                        width: self.maxWidth,
                        isShowDeleteButton: item.isShowDeleteButton)
        membersView.addNewMember = { [weak self] in
            if let `self` = self {
                ChatSettingTracker.infoMemberIMChatPinClickAddView(chat: item.chat)
                item.addNewMember(self)
            }
        }
        membersView.deleteMemberHandler = { [weak self] in
            if let `self` = self {
                ChatSettingTracker.infoMemberIMChatPinClickDelView(chat: item.chat)
                item.deleteMember?(self)
            }
        }
        membersView.selectedMemeber = item.selectedMember
        layoutSeparater(item.style)
    }

    override func updateAvailableMaxWidth(_ width: CGFloat) {
        self.maxWidth = width
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        if selected, let memberItem = item as? ChatInfoMemberModel {
            memberItem.tapHandler(self)
        }
        super.setSelected(selected, animated: animated)
    }
}

// MARK: - 群管理成员 - cell
final class ChatAdminMemberCell: ChatInfoCell {
    fileprivate var titleLabel: UILabel = .init()
    fileprivate var countLabel: UILabel = .init()
    fileprivate var membersView: NewChatInfoMemberView!
    private var maxWidth: CGFloat = 0

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        countLabel = UILabel()
        countLabel.font = UIFont.systemFont(ofSize: 14)
        countLabel.textColor = UIColor.ud.textPlaceholder
        countLabel.textAlignment = .right

        contentView.addSubview(countLabel)
        countLabel.snp.makeConstraints { (maker) in
            maker.right.equalTo(-31)
            maker.centerY.equalTo(arrow.snp.centerY)
            maker.height.equalTo(20)
        }

        titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 999), for: .horizontal)
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (maker) in
            maker.top.left.equalToSuperview().inset(UIEdgeInsets(top: 16, left: 16, bottom: 0, right: 0))
            maker.right.lessThanOrEqualTo(countLabel.snp.left).offset(-12)
            maker.height.equalTo(24)
        }

        membersView = NewChatInfoMemberView()
        contentView.addSubview(membersView)
        membersView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview().inset(UIEdgeInsets(top: 52, left: 0, bottom: 16, right: 0))
            maker.height.equalTo(32)
        }

        arrow.snp.remakeConstraints { (maker) in
            maker.centerY.equalTo(titleLabel)
            maker.right.equalToSuperview().offset(-16)
            maker.width.height.equalTo(12)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setCellInfo() {
        guard let item = item as? ChatAdminMemberModel else {
            assert(false, "\(self):item.Type error")
            return
        }

        titleLabel.text = item.title
        countLabel.text = item.descriptionText
        if item.isShowMember {
            membersView.snp.remakeConstraints { (maker) in
                maker.edges.equalToSuperview().inset(UIEdgeInsets(top: 52, left: 0, bottom: 16, right: 0))
                maker.height.equalTo(32)
            }
            membersView.set(avatarModels: item.avatarModels,
                            memberIds: item.memberIds,
                            hasAccess: item.hasAccess,
                            width: self.maxWidth,
                            isShowDeleteButton: item.isShowDeleteButton)
            membersView.addNewMember = { [weak self] in
                if let `self` = self {
                    item.addNewMember(self)
                }
            }
            membersView.deleteMemberHandler = { [weak self] in
                if let `self` = self {
                    item.deleteMember?(self)
                }
            }
            membersView.selectedMemeber = item.selectedMember
        } else {
            membersView.snp.remakeConstraints { (maker) in
                maker.edges.equalToSuperview().inset(UIEdgeInsets(top: 40, left: 0, bottom: 16, right: 0))
                maker.height.equalTo(0)
            }
        }

        layoutSeparater(item.style)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        if selected, let memberItem = item as? ChatInfoMemberModel {
            memberItem.tapHandler(self)
        }
        super.setSelected(selected, animated: animated)
    }

    override func updateAvailableMaxWidth(_ width: CGFloat) {
        self.maxWidth = width
    }
}

// 群管理员cell viewModel
typealias ChatAdminMemberModel = ChatInfoMemberModel
