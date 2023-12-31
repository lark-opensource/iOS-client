//
//  SearchUserTableViewCell.swift
//  LarkSearch
//
//  Created by ChalrieSu on 2018/5/10.
//  Copyright © 2018 liuwanlin. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import LarkCore
import LarkModel
import LarkUIKit
import LarkTag
import LarkMessengerInterface
import LarkAccountInterface
import LarkListItem
import LarkSDKInterface
import LarkSearchCore

final class SearchUserTableViewCell: UITableViewCell {
    private let _contentView = UIView()
    private let personInfoView = ListItem()

    override public var contentView: UIView {
        return self._contentView
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectedBackgroundView = SearchCellSelectedView()
        self.backgroundColor = UIColor.ud.bgBody

        self.addSubview(_contentView)
        _contentView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        contentView.addSubview(personInfoView)
        personInfoView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setContent(searchResult: SearchResultType,
                    searchText: String?,
                    currentTenantId: String,
                    hideCheckBox: Bool = false,
                    enableCheckBox: Bool = false,
                    isSelected: Bool = false,
                    currentUserType: PassportUserType) {
        if hideCheckBox {
            personInfoView.checkBox.isHidden = true
        } else {
            personInfoView.checkBox.isHidden = false
            personInfoView.checkBox.isEnabled = enableCheckBox
            personInfoView.checkBox.isSelected = isSelected
        }

        personInfoView.avatarView.setAvatarByIdentifier(searchResult.id, avatarKey: searchResult.avatarKey,
                                                        avatarViewParams: .init(sizeType: .size(personInfoView.avatarSize)))
        personInfoView.nameLabel.attributedText = searchResult.title

        if !searchResult.summary.string.isEmpty {
            personInfoView.infoLabel.attributedText = searchResult.summary
            personInfoView.infoLabel.isHidden = false
        } else {
            personInfoView.infoLabel.isHidden = true
        }

        switch searchResult.meta {
        case .chatter(let meta):
            personInfoView.statusLabel.isHidden = false
            personInfoView.setDescription(NSAttributedString(string: meta.description_p), descriptionType: ListItem.DescriptionType(rawValue: meta.descriptionFlag.rawValue))
            var tagTyps: [TagType] = []
            if meta.type == .bot, !meta.withBotTag.isEmpty {
                tagTyps.append(.robot)
            }
            if meta.hasWorkStatus,
                meta.workStatus.status == .onLeave,
                meta.tenantID == currentTenantId {
                tagTyps.append(.onLeave)
            }
            if meta.tenantID != currentTenantId {
                if case .standard = currentUserType {
                    tagTyps.append(.external)
                }
            }
            if !meta.isRegistered {
                tagTyps.append(.unregistered)
            }

            personInfoView.nameTag.setTags(tagTyps)
            personInfoView.nameTag.isHidden = tagTyps.isEmpty

        case .chat(let meta):
            personInfoView.statusLabel.isHidden = true
            personInfoView.additionalIcon.isHidden = true
            var tagTyps: [TagType] = []
            if meta.isCrossWithKa {
                if case .standard = currentUserType {
                    tagTyps.append(.connect)
                }
            } else if meta.isCrossTenant {
                if case .standard = currentUserType {
                    tagTyps.append(.external)
                }
            }
            personInfoView.nameTag.setTags(tagTyps)
            personInfoView.nameTag.isHidden = tagTyps.isEmpty

        default:
            personInfoView.statusLabel.isHidden = true
            personInfoView.additionalIcon.isHidden = true
            personInfoView.nameTag.isHidden = true
        }
    }
}
