//
//  ModelExtension.swift
//  LarkContact
//
//  Created by tefeng liu on 2021/11/4.
//

import Foundation
import RustPB
import UniverseDesignIcon
import LarkTag
import UIKit

// MARK: Email_Client_V1_MailGroupManager
extension Email_Client_V1_MailGroupManager: GroupInfoMemberItem {
    var itemId: String {
        return String(userID)
    }

    var itemAvatarKey: String {
        return avatar
    }

    var itemName: String {
        return displayName
    }

    var itemTags: [Tag]? {
        return MailGroupHelper.createTag(status: self.status, external: false)
    }
}

extension Email_Client_V1_MailGroupManager: MailGroupInfoMemberViewItem {
    var avatarId: String {
        return String(userID)
    }

    var avatarImage: UIImage? {
        if avatarKey.isEmpty {
            return MailGroupHelper.generateAvatarImage(withNameString: String(itemName.prefix(2)).uppercased())
        }
        return nil
    }
}

extension Email_Client_V1_MailGroupManager: MailSelectedCollectionItem {
    var id: String {
        return String(userID)
    }

    var avatarKey: String {
        return avatar
    }

    var isChatter: Bool {
        return true
    }
}

extension Email_Client_V1_MailGroupMember: GroupInfoMemberItem {
    var itemId: String {
        return memberID == 0 ? mailAddress : String(memberID)
    }

    var itemAvatarKey: String {
        return avatar
    }

    var itemName: String {
        return name.isEmpty ? mailAddress : name
    }

    var itemTags: [Tag]? {
        if memberType == .dynamicUserGroup {
            return MailGroupHelper.createTag(memberType: memberType)
        }
        return MailGroupHelper.createTag(status: self.status, external: memberType == .externalContact)
    }
}

extension Email_Client_V1_MailGroupMember: MailSelectedCollectionItem {
    var id: String {
        return memberID == 0 ? mailAddress : String(memberID)
    }

    var avatarKey: String {
        return avatar
    }

    var isChatter: Bool {
        var isChatter = false
        switch memberType {
        case .groupUser, .contact, .externalContact:
            isChatter = true
        @unknown default: break
        }
        return isChatter
    }
}

// MARK: UI适配
extension Email_Client_V1_MailGroupMember: MailGroupInfoMemberViewItem {
    var avatarId: String {
        return String(memberID)
    }

    var avatarImage: UIImage? {
        if memberType == .department {
            return MailGroupHelper.generateAvatarImage(withIcon: UDIcon.organizationOutlined)
        } else if memberType == .sharedAccount {
            return MailGroupHelper.generateAvatarImage(withIcon: UDIcon.mailOutlined)
        } else if memberType == .mailingList {
            return MailGroupHelper.generateAvatarImage(withIcon: UDIcon.allmailOutlined)
        } else if memberType == .userGroup || memberType == .dynamicUserGroup {
            return MailGroupHelper.generateAvatarImage(withIcon: UDIcon.groupOutlined, bgColor: UIColor.ud.purple)
        } else if avatarKey.isEmpty {
            return MailGroupHelper.generateAvatarImage(withNameString: String(itemName.prefix(2)).uppercased())
        }
        return nil
    }
}

// MARK: Email_Client_V1_MailGroupPermissionMember
extension Email_Client_V1_MailGroupPermissionMember: GroupInfoMemberItem {
    var itemId: String {
        return String(memberID)
    }

    var itemAvatarKey: String {
        return avatar
    }

    var itemName: String {
        return displayName
    }

    var itemTags: [Tag]? {
        if memberType == .dynamicUserGroup {
            return MailGroupHelper.createTag(memberType: memberType)
        }
        return MailGroupHelper.createTag(status: self.status, external: memberType == .externalContact)
    }
}

extension Email_Client_V1_MailGroupPermissionMember: MailGroupInfoMemberViewItem {
    var avatarKey: String {
        return avatar
    }

    var avatarId: String {
        return String(memberID)
    }

    var avatarImage: UIImage? {
        if memberType == .department {
            return MailGroupHelper.generateAvatarImage(withIcon: UDIcon.organizationOutlined)
        } else if memberType == .sharedAccount {
            return MailGroupHelper.generateAvatarImage(withIcon: UDIcon.mailOutlined)
        } else if memberType == .mailingList {
            return MailGroupHelper.generateAvatarImage(withIcon: UDIcon.allmailOutlined)
        } else if memberType == .userGroup || memberType == .dynamicUserGroup {
            return MailGroupHelper.generateAvatarImage(withIcon: UDIcon.groupOutlined, bgColor: UIColor.ud.purple)
        } else if avatarKey.isEmpty {
            return MailGroupHelper.generateAvatarImage(withNameString: String(itemName.prefix(2)).uppercased())
        }
        return nil
    }
}

enum MailGroupReqError: Int {
    case noPermission = 250_401
    case other = 987_654_321 // 客户端自己定的
}
