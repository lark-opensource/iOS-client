//
//  SelectableGroupsTableViewCell.swift
//  LarkContact
//
//  Created by 赵家琛 on 2021/1/31.
//

import UIKit
import Foundation
import LarkUIKit
import LarkModel
import LarkListItem
import LarkAccountInterface
import LarkMessengerInterface
import LarkTag
import LarkBizTag

protocol SelectableGroupsCellPropsProtocol {
    var chat: Chat { get }
    var currentUserType: AccountUserType { get }
    var checkStatus: ContactCheckBoxStaus { get }
    var targetPreview: Bool { get }
    var isEnable: Bool { get }
}

struct SelectableGroupsCellProps: SelectableGroupsCellPropsProtocol {
    let chat: Chat
    let currentUserType: AccountUserType
    let checkStatus: ContactCheckBoxStaus
    let targetPreview: Bool
    let isEnable: Bool
}

final class SelectableGroupsTableViewCell: UITableViewCell {
    private lazy var groupInfoView: ListItem = {
        let groupInfoView = ListItem()
        groupInfoView.bottomSeperator.isHidden = true
        groupInfoView.infoLabel.isHidden = true
        groupInfoView.nameTag.isHidden = true
        groupInfoView.additionalIcon.isHidden = true
        groupInfoView.textContentView.spacing = 4
        groupInfoView.statusLabel.setUIConfig(StatusLabel.UIConfig(font: UIFont.systemFont(ofSize: 16)))
        groupInfoView.statusLabel.descriptionView.setContentCompressionResistancePriority(.required, for: .horizontal)
        groupInfoView.statusLabel.descriptionView.setContentHuggingPriority(.required, for: .horizontal)
        groupInfoView.statusLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        groupInfoView.statusLabel.setContentHuggingPriority(.required, for: .horizontal)
        groupInfoView.backgroundColor = .clear
        return groupInfoView
    }()
    public lazy var targetInfo: UIButton = {
        let targetInfo = UIButton(type: .custom)
        targetInfo.setImage(Resources.target_info, for: .normal)
        targetInfo.hitTestEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        return targetInfo
    }()

    var chatTagBuilder: ChatTagViewBuilder = ChatTagViewBuilder()

    lazy var chatTagView: TagWrapperView = {
        let tagView = chatTagBuilder.build()
        tagView.isHidden = true
        return tagView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.backgroundColor = UIColor.ud.bgBody
        contentView.backgroundColor = .clear
        setupBackgroundViews(highlightOn: true)

        contentView.addSubview(groupInfoView)
        groupInfoView.snp.makeConstraints { (make) in
            make.left.top.bottom.equalToSuperview()
            make.right.lessThanOrEqualToSuperview()
        }

        groupInfoView.bottomSeperator.snp.remakeConstraints { (make) in
            make.leading.equalTo(groupInfoView.nameLabel.snp.leading)
            make.height.equalTo(1 / UIScreen.main.scale)
            make.bottom.equalToSuperview()
            make.trailing.equalTo(self.snp.trailing)
        }
        contentView.addSubview(targetInfo)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate var props: SelectableGroupsCellPropsProtocol? {
        didSet {
            guard let props = self.props else { return }
            groupInfoView.alpha = props.isEnable ? 1 : 0.5
            switch props.checkStatus {
            case .invalid:
                groupInfoView.checkBox.isHidden = true
            case .selected:
                groupInfoView.checkBox.isHidden = false
                updateCheckBox(selected: true, enabled: true)
            case .unselected:
                groupInfoView.checkBox.isHidden = false
                updateCheckBox(selected: false, enabled: true)
            case .defaultSelected:
                groupInfoView.checkBox.isHidden = false
                self.updateCheckBox(selected: true, enabled: false)
            case .disableToSelect:
                groupInfoView.checkBox.isHidden = false
                self.updateCheckBox(selected: false, enabled: false)
            }

            let chat = props.chat
            groupInfoView.nameLabel.text = "\(chat.name)"
            groupInfoView.infoLabel.isHidden = chat.description.isEmpty
            groupInfoView.infoLabel.text = chat.description
            var countString: NSAttributedString? = NSAttributedString(string: "(\(chat.userCount))")
            if chat.isUserCountVisible == false {
                countString = nil
            }
            groupInfoView.statusLabel.set(
                description: countString,
                descriptionIcon: nil,
                showIcon: false
            )
            groupInfoView.avatarView.setAvatarByIdentifier(chat.id, avatarKey: chat.avatarKey)

            chatTagBuilder.reset(with: [])
                .isOfficial(chat.tags.contains(.official))
                .isConnect(chat.isCrossWithKa)
                .isPublic(chat.isPublic)
                .isTeam(chat.isDepartment)
                .isAllStaff(chat.isTenant)
                .isCrypto(chat.isCrypto)
                .isPrivateMode(chat.isPrivateMode)
                .addTags(with: chat.tagData?.transform() ?? [])
                .refresh()
            chatTagView.isHidden = chatTagBuilder.isDisplayedEmpty()
            groupInfoView.setNameTag(chatTagView)

            if props.targetPreview {
                targetInfo.isHidden = false
                groupInfoView.snp.remakeConstraints { (make) in
                    make.leading.top.bottom.equalToSuperview()
                    make.trailing.equalToSuperview().offset(-Self.Layout.personInfoMargin)
                }
                targetInfo.snp.makeConstraints { (make) in
                    make.leading.equalTo(groupInfoView.snp.trailing).offset(8)
                    make.trailing.equalToSuperview().offset(-Self.Layout.targetInfoMargin)
                    make.centerY.equalToSuperview()
                }
            } else {
                targetInfo.isHidden = true
                groupInfoView.snp.makeConstraints { (make) in
                    make.left.top.bottom.equalToSuperview()
                    make.right.lessThanOrEqualToSuperview()
                }
            }
        }
    }

    private func updateCheckBox(selected: Bool, enabled: Bool) {
        self.selectionStyle = enabled ? .default : .none
        groupInfoView.checkBox.isEnabled = enabled
        groupInfoView.checkBox.isSelected = selected
    }

    func setProps(_ props: SelectableGroupsCellPropsProtocol) {
       self.props = props
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        setBackViewColor(highlighted ? UIColor.ud.fillHover : UIColor.ud.bgBody)
    }
}

extension SelectableGroupsTableViewCell {
    final class Layout {
        //根据UI设计图而来
        static let infoIconWidth: CGFloat = 20
        static let personInfoMargin: CGFloat = 8 + 20 + 16
        static let targetInfoMargin: CGFloat = 16
    }
}
