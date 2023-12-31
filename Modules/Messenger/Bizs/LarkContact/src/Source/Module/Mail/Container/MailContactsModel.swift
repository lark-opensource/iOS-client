//
//  MailContactsModel.swift
//  LarkContact
//
//  Created by tefeng liu on 2021/8/24.
//

import UIKit
import Foundation
import LarkSDKInterface
import LarkSearchCore
import LarkTag
import UniverseDesignIcon

// 每一个具体的cell viewModel
extension NameCardInfo: MailContactsItemCellViewModel {
    var title: String {
        return name
    }

    var subTitle: String {
        return email
    }

    var customAvatar: UIImage? {
        return nil
    }

    var tag: Tag? {
        return Tag(title: BundleI18n.LarkContact.Lark_Contacts_EmailContacts,
                   image: nil, style: .blue, type: .customTitleTag)
    }

    var entityId: String {
        return namecardId
    }

}

extension NameCardInfo: SelectedOptionInfoConvertable {
    public func asSelectedOptionInfo() -> SelectedOptionInfo {
        return self
    }
}

extension NameCardInfo: SelectedOptionInfo {
    /// avatar identifier for option, return "" to mean invalid
    public var avaterIdentifier: String {
        return namecardId
    }
}

// MailSharedAccount
extension MailSharedEmailAccount: SelectedOptionInfoConvertable {
    public func asSelectedOptionInfo() -> SelectedOptionInfo {
        return self
    }
}

extension MailSharedEmailAccount: MailContactsItemCellViewModel {
    public var avatarKey: String {
        ""
    }

    var tag: Tag? {
        return nil
    }

    var title: String {
        return emailName
    }

    var subTitle: String {
        return emailAddress
    }

    var entityId: String {
        return String(userID)
    }

    var customAvatar: UIImage? {
        let img = UDIcon.getIconByKey(.mailOutlined, size: CGSize(width: 48, height: 48))
        return MailGroupHelper.generateAvatarImage(withIcon: img)
    }
}

extension MailSharedEmailAccount: SelectedOptionInfo {
    public var avaterIdentifier: String {
        String(userID)
    }

    public var name: String {
        return emailName
    }

    public var backupImage: UIImage? {
        let img = UDIcon.getIconByKey(.mailOutlined, size: CGSize(width: 48, height: 48))
        return MailGroupHelper.generateAvatarImage(withIcon: img)
    }
}
