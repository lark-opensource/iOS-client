//
//  SearchItemPickerTableViewCell.swift
//  LarkSearch
//
//  Created by SuPeng on 4/24/19.
//

import Foundation
import UIKit
import SnapKit
import LarkUIKit
import LarkModel
import LarkTag
import LarkCore
import LarkAccountInterface
import LarkMessengerInterface
import LarkListItem
import LarkSDKInterface
import LarkSearchFilter
import LarkSearchCore

public enum SearchChatPickerSelectMode {
    case single
    case multi
}

final class SearchChatPickerTableViewCell: UITableViewCell {
    let personInfoView = ListItem()
    let countLabel = UILabel()

    var checkbox: LKCheckbox {
        return personInfoView.checkBox
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectedBackgroundView = SearchCellSelectedView()
        self.backgroundColor = UIColor.ud.bgBody

        personInfoView.statusLabel.isHidden = true
        contentView.addSubview(personInfoView)
        personInfoView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        personInfoView.splitNameLabel(additional: countLabel)
        countLabel.textColor = UIColor.ud.textPlaceholder
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        let frame = self.contentView.frame.inset(by: UIEdgeInsets(top: 1, left: 6, bottom: 1, right: 6))
        self.selectedBackgroundView?.frame = frame
        self.selectedBackgroundView?.layer.cornerRadius = 8
    }

    func set(item: SearchChatPickerItem,
             isSelected: Bool,
             selectModel: SearchChatPickerSelectMode,
             currentAccount: User) {
        checkbox.isHidden = (selectModel == .single)
        checkbox.isSelected = isSelected
        countLabel.text = nil

        var isCrossTenant = false
        var isCrossWithKa = false
        switch item.extraInfo {
        case .chat(let displayName, let description, let chatIsCrossTenant, let chatIsCrossWithKa, let userCount):
            personInfoView.avatarView.setAvatarByIdentifier(item.avatarID, avatarKey: item.avatarKey,
                                                            avatarViewParams: .init(sizeType: .size(personInfoView.avatarSize)))
            personInfoView.nameLabel.text = displayName
            personInfoView.infoLabel.text = description
            personInfoView.infoLabel.isHidden = description.isEmpty

            isCrossTenant = chatIsCrossTenant
            isCrossWithKa = chatIsCrossWithKa

            if userCount > 0 {
                countLabel.text = "(\(userCount))"
            }
        case .searchResult(let metaInfo, let subtitle, let title, _):
            personInfoView.avatarView.setAvatarByIdentifier(item.avatarID, avatarKey: item.avatarKey,
                                                            avatarViewParams: .init(sizeType: .size(personInfoView.avatarSize)))
            personInfoView.nameLabel.attributedText = title
            personInfoView.infoLabel.text = subtitle.string
            personInfoView.infoLabel.isHidden = subtitle.string.isEmpty

            switch metaInfo {
            case .chatter(let tenantID):
                if tenantID != currentAccount.tenant.tenantID {
                    isCrossTenant = true
                }
            case .chat(let chatIsCrossTenant, let chatIsCrossWithKa, let userCountText):
                isCrossTenant = chatIsCrossTenant
                isCrossWithKa = chatIsCrossWithKa
                countLabel.text = userCountText
            }
        }

        var tagTypes: [TagType] = []
        if isCrossWithKa {
            if currentAccount.type == .standard {
                tagTypes.append(.connect)
            }
        } else if isCrossTenant {
            if currentAccount.type == .standard {
                tagTypes.append(.external)
            }
        }
        self.personInfoView.nameTag.setTags(tagTypes)
        self.personInfoView.nameTag.isHidden = tagTypes.isEmpty
    }
}
