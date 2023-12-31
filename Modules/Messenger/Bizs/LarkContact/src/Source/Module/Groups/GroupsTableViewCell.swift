//
//  GroupsTableViewCell.swift
//  Lark
//
//  Created by 刘晚林 on 2016/12/23.
//  Copyright © 2016年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LarkModel
import LarkUIKit
import LarkCore
import LarkTag
import LarkAccountInterface
import LarkMessengerInterface
import LarkListItem
import LarkSearchCore
import LarkBizTag

final class GroupsTableViewCell: UITableViewCell {

    private let personInfoView = ListItem()
    let countLabel = UILabel()

    // chat自定义标签
    lazy var chatTagBuilder = ChatTagViewBuilder()
    lazy var chatTagView: TagWrapperView = {
        let tagView = chatTagBuilder.build()
        tagView.isHidden = true
        return tagView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.backgroundColor = UIColor.ud.bgBody
        personInfoView.backgroundColor = .clear
        contentView.addSubview(personInfoView)
        personInfoView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        personInfoView.checkBox.isHidden = true
        personInfoView.statusLabel.isHidden = true
        personInfoView.additionalIcon.isHidden = true
        personInfoView.nameTag.isHidden = true

        personInfoView.splitNameLabel(additional: countLabel)
        countLabel.textColor = UIColor.ud.textPlaceholder

        setupBackgroundViews(highlightOn: true)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setContent(
        _ model: LarkModel.Chat,
        currentTenantId: String,
        withSearchText searchText: String = "",
        currentUserType: AccountUserType
    ) {
        let name = model.name
        if !searchText.isEmpty {
            personInfoView.nameLabel.attributedText = name.lu.stringWithHighlight(
                highlightText: searchText,
                highlightColor: UIColor.ud.colorfulBlue,
                normalColor: UIColor.ud.textTitle)
        } else {
            personInfoView.nameLabel.text = name
        }
        countLabel.text = "(\(model.userCount))"
        if model.isUserCountVisible == false {
            countLabel.text = nil
        }

        personInfoView.bottomSeperator.isHidden = true
        personInfoView.infoLabel.isHidden = model.description.isEmpty
        personInfoView.infoLabel.text = model.description
        personInfoView.avatarView.setAvatarByIdentifier(model.id, avatarKey: model.avatarKey,
                                                        avatarViewParams: .init(sizeType: .size(personInfoView.avatarSize)))

        chatTagBuilder.reset(with: [])
            .isOfficial(model.tags.contains(.official))
            .isConnect(model.isCrossWithKa)
            .isPublic(model.isPublic)
            .isTeam(model.isDepartment)
            .isAllStaff(model.isTenant)
            .isCrypto(model.isCrypto)
            .addTags(with: model.tagData?.transform() ?? [])
            .refresh()
        chatTagView.isHidden = chatTagBuilder.isDisplayedEmpty()
        personInfoView.setNameTag(chatTagView)
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        setBackViewColor(highlighted ? UIColor.ud.fillHover : UIColor.ud.bgBody)
    }
}
