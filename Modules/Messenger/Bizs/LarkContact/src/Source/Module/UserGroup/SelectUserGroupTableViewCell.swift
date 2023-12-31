//
//  SelectUserGroupTableViewCell.swift
//  LarkContact
//
//  Created by ByteDance on 2023/4/17.
//

import UIKit
import Foundation
import LarkUIKit
import LarkListItem
import LarkTag
import LarkBizTag
import LarkAccountInterface
import LarkSDKInterface

protocol SelectUserGroupsCellPropsProtocol {
    var item: SelectVisibleUserGroup { get }
    var checkStatus: ContactCheckBoxStaus { get }
}

struct SelectUserGroupsCellProps: SelectUserGroupsCellPropsProtocol {
    let item: SelectVisibleUserGroup
    let checkStatus: ContactCheckBoxStaus
}

final class SelectUserGroupTableViewCell: UITableViewCell {
    private lazy var groupInfoView: ListItem = {
        let groupInfoView = ListItem()
        groupInfoView.statusLabel.isHidden = true
        groupInfoView.avatarView.image = BundleResources.LarkContact.UserGroup.user_group
        return groupInfoView
    }()

    lazy var chatTagBuilder: ChatTagViewBuilder = ChatTagViewBuilder()
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
    }

    fileprivate var props: SelectUserGroupsCellPropsProtocol? {
        didSet {
            guard let props = self.props else { return }
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

            groupInfoView.nameLabel.text = "\(props.item.name)"
            switch props.item.groupType {
            case .normal:
                chatTagBuilder.reset(with: [])
                    .refresh()
                chatTagView.isHidden = true
            case .dynamic:
                let tagText = BundleI18n.LarkContact.Lark_IM_Picker_DynamicUserGroups_Label
                let frontColor = UIColor.ud.udtokenTagTextPurple
                let backColor = UIColor.ud.udtokenTagBgPurple
                chatTagBuilder.reset(with: [])
                    .addTag(with: TagDataItem(text: tagText, tagType: .customTitleTag, frontColor: frontColor, backColor: backColor))
                    .refresh()
                chatTagView.isHidden = false
                groupInfoView.setNameTag(chatTagView)
            @unknown default:
                assertionFailure("unknow type")
            }
        }
    }

    private func updateCheckBox(selected: Bool, enabled: Bool) {
        self.selectionStyle = enabled ? .default : .none
        groupInfoView.checkBox.isEnabled = enabled
        groupInfoView.checkBox.isSelected = selected
    }

    func setProps(_ props: SelectUserGroupsCellPropsProtocol) {
       self.props = props
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        setBackViewColor(highlighted ? UIColor.ud.fillHover : UIColor.ud.bgBody)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
