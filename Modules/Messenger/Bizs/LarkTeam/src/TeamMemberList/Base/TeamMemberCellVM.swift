//
//  TeamMemberCellVM.swift
//  LarkTeam
//
//  Created by 夏汝震 on 2021/12/15.
//

import Foundation
import RustPB
import RxSwift
import RxCocoa
import LarkModel
import EENavigator
import LarkContainer
import LKCommonsLogging
import LarkSDKInterface
import UniverseDesignToast
import UniverseDesignDialog
import LarkMessengerInterface
import LarkListItem
import LarkTag

struct TeamMemberCellVM: TeamMemberItem {
    let itemId: String
    let itemAvatarKey: String
    let itemName: String
    let realName: String
    var itemDescription: String?
    let itemTags: [Tag]?
    var itemCellClass: AnyClass
    var isSelectedable: Bool = true

    var order: Int64
    let memberMeta: Basic_V1_TeamMemberMeta?
    var isChatter: Bool = false
    let chatInfo: Basic_V1_TeamMemberChatInfo
    let chatterInfo: Basic_V1_TeamMemberChatterInfo
    let userResolver: LarkContainer.UserResolver

    init(memberID: Int64,
         chatInfo: Basic_V1_TeamMemberChatInfo,
         chatterInfo: Basic_V1_TeamMemberChatterInfo,
         orderedWeight: Int64 = 0,
         metaType: Basic_V1_TeamMemberInfo.MetaType,
         itemDescription: String? = nil,
         itemCellClass: AnyClass,
         userResolver: LarkContainer.UserResolver) {
        self.itemCellClass = itemCellClass
        self.itemId = String(memberID)
        self.order = orderedWeight
        self.chatInfo = chatInfo
        self.chatterInfo = chatterInfo
        self.itemDescription = itemDescription
        self.userResolver = userResolver
        switch metaType {
        case .chatter:
            self.itemAvatarKey = chatterInfo.chatter.avatarKey
            self.itemName = chatterInfo.chatter.name
            self.realName = chatterInfo.chatter.name
            self.memberMeta = chatterInfo.meta
            let result = chatterInfo.meta.userRoles.compactMap { role -> TagType? in
                switch role.roleType {
                case .owner:
                    return .teamOwner
                case .admin:
                    return .teamAdmin
                case .unknown:
                    return nil
                @unknown default:
                    return nil
                }
                return nil
            }
            self.isChatter = true
            self.itemTags = result.map({ Tag(type: $0) })
        case .chat:
            let chat = chatInfo.chat
            self.itemAvatarKey = chat.avatarKey
            //2. 对于自己所在的群，可查看群成员数量；否则将不展示群成员数量
            if chatInfo.operatorInChat {
                self.itemName = BundleI18n.LarkTeam.Project_T_GroupNameVariables(chat.name, chatInfo.count)
                // 若有群成员退出团队，仍在团队的群成员视角下：
                if chatInfo.hasLeaveChatter_p {
                    self.itemDescription = BundleI18n.LarkTeam.Project_T_MembersLeftTeam
                }
            } else {
                self.itemName = chat.name
            }
            self.realName = chat.name
            self.memberMeta = nil
            self.itemTags = []
        case .unknown:
            self.itemAvatarKey = ""
            self.itemName = ""
            self.realName = ""
            self.memberMeta = nil
            self.itemTags = []
        }
    }
}
