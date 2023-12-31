//
//  MailSettingAddSendAddressCell.swift
//  MailSDK
//
//  Created by raozhongtao on 2023/11/7.
//

import Foundation
import UIKit
import SnapKit
import LarkTag
import UniverseDesignIcon
import UniverseDesignFont
import UniverseDesignTag

protocol MailSettingAliasCellDelegate: AnyObject {
    func showAliasSettingIfNeeded(for address: MailAddress)

}

class MailSettingAliasAccountCell: MailSettingAccountBaseCell {
    weak var delegate: MailSettingAliasCellDelegate?
    lazy var defaultTag: UDTag = {
        let tagConfig: UDTagConfig.TextConfig = .init(textColor: UIColor.ud.udtokenTagTextSBlue, backgroundColor: UIColor.ud.udtokenTagBgBlue)
        let defaultTag = UDTag(text: BundleI18n.MailSDK.Mail_ManageSenders_Default_Text, textConfig: tagConfig)
        return defaultTag
    }()

    lazy var mailGroupTag: UDTag = {
        let tagConfig: UDTagConfig.TextConfig = .init(textColor: UIColor.ud.udtokenTagNeutralTextNormal, backgroundColor: UIColor.ud.udtokenTagNeutralBgNormal)
        let mailGroupTag = UDTag(text: BundleI18n.MailSDK.Mail_ManageSenders_MailingList_Text, textConfig: tagConfig)
        mailGroupTag.layer.cornerRadius = 4
        mailGroupTag.layer.masksToBounds = true
        return mailGroupTag
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        var params = SettingAccountBaseCellParams(hasAvatarView: false,
                                                  style: style,
                                                  reuseIdentifier: reuseIdentifier)
        super.init(params: params)
        self.showArrow = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func didClickCell() {
        guard let item = item as? MailSettingAliasAccountCellModel else { return }
        delegate?.showAliasSettingIfNeeded(for: item.address)
    }

    override func setCellInfo() {
        guard let item = item as? MailSettingAliasAccountCellModel else { return }
        titleLabel.text = item.address.mailDisplayName
        subTitleLabel.text = item.address.address
        var tags: [UDTag] = []
        if item.isMailGroup {
            tags.append(mailGroupTag)
        }
        if item.isDefault {
            tags.append(defaultTag)
        }
        setupTags(with: tags)
    }
}
