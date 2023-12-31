//
//  MailMessageListTemplateRender+native.swift
//  MailSDK
//
//  Created by tefeng liu on 2020/11/7.
//

import Foundation
import RustPB

extension MailMessageListTemplateRender {
    func replaceForFromNativeAvatar(userid: String,
                                    name: String,
                                    address: String,
                                    userType: Email_Client_V1_Address.LarkEntityType,
                                    tenantId: String,
                                    avatar: String = "",
                                    isFeedCard: Bool = false,
                                    isMe: Bool) -> String {
        // 邮件组不展示个人头像，不传LarkID
        var avatarKey = MailModelManager.shared.getAvatarKey(userid: userid)
        if !isFeedCard || isMe {
            avatarKey = MailModelManager.shared.getAvatarKey(userid: userid)
        } else {
            avatarKey = avatar
        }
        return replaceFor(template: template.sectionMessageListNativeAvatar, patternHandler: { (keyword) -> String? in
            switch keyword {
            case "entity_id":
                return userid
            case "avatar_key":
                return avatarKey
            case "name":
                return name
            case "address":
                return address
            case "user_type":
                return String(userType.rawValue)
            case "tenant_id":
                return tenantId
            default:
                return ""
            }
        })
    }
}
