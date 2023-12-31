//
//  MailGroupInfoMemberCell.swift
//  LarkContact
//
//  Created by tefeng liu on 2021/10/20.
//

import UIKit
import Foundation

struct MailGroupInfoMemberModel: GroupInfoCellItem {
    var type: GroupInfoItemType {
        return .member
    }

    var title: String
    var memberItems: [MailGroupInfoMemberViewItem]
    var memberCount: Int
    var hasAccess: Bool
    var isShowDeleteButton: Bool
    var separaterStyle: SeparaterStyle
    var enterMemberList: MailGroupInfoTapHandler
    var tapHandler: MailGroupInfoTapHandler
    var addNewMember: MailGroupInfoTapHandler
    var selectedMember: (String) -> Void
    var deleteMember: MailGroupInfoTapHandler?
}

final class MailGroupInfoMemberCell: MailGroupInfoCell {
    fileprivate var titleLabel: UILabel = .init()
    fileprivate var countLabel: UILabel = .init()
    fileprivate var membersView: MailGroupInfoMemberView!
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

        membersView = MailGroupInfoMemberView()
        contentView.addSubview(membersView)

        titleLabel.snp.makeConstraints { (maker) in
            maker.top.left.equalToSuperview().inset(UIEdgeInsets(top: 16, left: 16, bottom: 0, right: 0))
            maker.right.lessThanOrEqualTo(countLabel.snp.left).offset(-12)
            maker.height.equalTo(24)
        }

        countLabel.snp.makeConstraints { (maker) in
            maker.right.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 32))
            maker.centerY.equalTo(titleLabel)
            maker.height.equalTo(20)
        }

        membersView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview().inset(UIEdgeInsets(top: 52, left: 0, bottom: 14, right: 0))
            maker.height.equalTo(32)
        }

        arrow.snp.remakeConstraints { (maker) in
            maker.centerY.equalTo(titleLabel)
            maker.right.equalToSuperview().offset(-16)
            maker.width.height.equalTo(12)
        }

        titleLabel.isUserInteractionEnabled = true
        titleLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didSelectEnterList)))
        arrow.isUserInteractionEnabled = true
        arrow.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didSelectEnterList)))
        countLabel.isUserInteractionEnabled = true
        countLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didSelectEnterList)))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setCellInfo() {
        guard let item = item as? MailGroupInfoMemberModel else {
            assert(false, "\(self):item.Type error")
            return
        }

        titleLabel.text = item.title
        let countText = "\(item.memberCount)"
        countLabel.text = countText
        membersView.set(memberItems: item.memberItems,
                        hasAccess: item.hasAccess,
                        width: maxWidth,
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
        layoutSeparater(item.separaterStyle)
    }

    override func updateAvailableMaxWidth(_ width: CGFloat) {
        self.maxWidth = width
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        if selected, let memberItem = item as? MailGroupInfoMemberModel {
            memberItem.tapHandler(self)
        }
        super.setSelected(selected, animated: animated)
    }

    @objc
    private func didSelectEnterList() {
        guard let item = item as? MailGroupInfoMemberModel else {
            assert(false, "\(self):item.Type error")
            return
        }
        item.enterMemberList(self)
    }
}
