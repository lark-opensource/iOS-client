//
//  MailProfileCellItem.swift
//  LarkContact
//
//  Created by tefeng liu on 2021/12/29.
//

import Foundation
import LarkUIKit
import LarkLocalizations
import LarkSDKInterface
import UIKit
import LarkContainer

enum MailProfileCellType {
    case normal
    case phone
    case link

    var cellIdentifier: String {
        switch self {
        case .normal:
            return MailProfileNormalCell.lu.reuseIdentifier
        case .phone:
            return MailProfilePhoneCell.lu.reuseIdentifier
        case .link:
            return MailProfileLinkCell.lu.reuseIdentifier
        }
    }
}

protocol MailProfileCellItem {
    var type: MailProfileCellType { get }

    var fieldKey: String { get set }

    var title: String { get }

    var subTitle: String { get }

    func handleClick(fromVC: UIViewController?, resolver: UserResolver)

    func handleLongPress(fromVC: UIViewController?)

    static func creatItemByField(_ field: NewUserProfile.Field) -> MailProfileCellItem?

    static func setI18NVal(_ i18Names: I18nVal, field: String) -> String
}

extension MailProfileCellItem {
    static func setI18NVal(_ i18Names: I18nVal, field: String) -> String {
        switch field {
        case "KEY_GROUP":
            return BundleI18n.LarkContact.Lark_Contacts_ContactCardTag
        case "KEY_TITLE":
            return BundleI18n.LarkContact.Lark_Contacts_ContactCardRole
        case "KEY_EXTRA":
            return BundleI18n.LarkContact.Lark_Contacts_ContactCardNotes
        case "KEY_EMAIL":
            return BundleI18n.LarkContact.Lark_Contacts_ContactCardEmail
        case "KEY_PHONE":
            return BundleI18n.LarkContact.Lark_Contacts_ContactCardMobile
        default:
            return i18Names.defaultVal
        }
    }
}
