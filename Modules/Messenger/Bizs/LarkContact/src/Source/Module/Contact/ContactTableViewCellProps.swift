//
//  ContactsTableView.swift
//  Lark
//
//  Created by 刘晚林 on 2017/1/20.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LarkModel
import LarkSDKInterface
import LarkTag
import LarkFeatureGating
import RustPB

struct ContactTableViewCellProps: ContactTableViewCellPropsProtocol {
    var name: String = ""
    var pinyinOfName: String = ""
    var avatarKey: String = ""
    var medalKey: String = ""
    var entityId: String = ""
    var avatar: UIImage?
    var description: String?
    var hasNext: Bool
    var hasRegister: Bool
    var isRobot: Bool
    var isLeader: Bool
    var leaderType: LeaderType
    var isExternal: Bool
    var isAdministrator: Bool
    var isSuperAdministrator: Bool
    var disableTags: [TagType]
    var checkStatus: ContactCheckBoxStaus
    var status: Chatter.Description?
    var profileFieldsDic: [String: [UserProfileField]]
    var user: Chatter?
    var timeString: String?
    var customTags: [Tag]?
    var isSpecialFocus: Bool = false
    var focusStatusList: [Chatter.FocusStatus] = []
    var targetPreview: Bool = false
    var tagData: Chatter.TagData?
    var contactInfo: ContactInfo?

    static var empty: ContactTableViewCellProps { .init(name: "", pinyinOfName: "", status: nil, profileFieldsDic: [:]) }

    init(name: String,
         pinyinOfName: String,
         avatarKey: String = "",
         entityId: String = "",
         description: String? = nil,
         avatar: UIImage? = nil,
         hasNext: Bool = false,
         hasRegister: Bool = true,
         isRobot: Bool = false,
         isLeader: Bool = false,
         leaderType: LeaderType = .subLeader,
         isExternal: Bool = false,
         isAdministrator: Bool = false,
         isSuperAdministrator: Bool = false,
         disableTags: [TagType] = [],
         checkStatus: ContactCheckBoxStaus = .invalid,
         status: Chatter.Description?,
         timeString: String? = nil,
         isSpecialFocus: Bool = false,
         profileFieldsDic: [String: [UserProfileField]],
         tagData: Chatter.TagData? = nil) {
        self.name = name
        self.pinyinOfName = pinyinOfName
        self.avatarKey = avatarKey
        self.entityId = entityId
        self.avatar = avatar
        self.description = description
        self.hasNext = hasNext
        self.hasRegister = hasRegister
        self.isRobot = isRobot
        self.isLeader = isLeader
        self.leaderType = leaderType
        self.isExternal = isExternal
        self.isAdministrator = isAdministrator
        self.isSuperAdministrator = isSuperAdministrator
        self.disableTags = disableTags
        self.checkStatus = checkStatus
        self.status = status
        self.timeString = timeString
        self.profileFieldsDic = profileFieldsDic
        self.isSpecialFocus = isSpecialFocus
        self.tagData = tagData
    }

    init(user: Chatter, description: String? = nil, isSupportAnotherName: Bool = false) {
        var contactName = user.localizedName
        if isSupportAnotherName && !user.nameWithAnotherName.isEmpty {
            contactName = user.nameWithAnotherName
        }
        if !user.alias.isEmpty {
            contactName = user.alias
        }
        self.name = contactName //displayName
        self.pinyinOfName = user.namePinyin //user.pinyinOfName
        self.avatarKey = user.avatarKey
        self.entityId = user.id
        self.hasNext = false
        if description == nil {
            self.description = ""   //user.department
        } else {
            self.description = description
        }
        self.user = user
        self.hasRegister = user.isRegistered //!user.status.contains(.unregister)
        self.isRobot = user.type == .bot
        self.isLeader = false
        self.leaderType = .subLeader
        self.isExternal = false
        self.isAdministrator = false
        self.isSuperAdministrator = false
        self.disableTags = []
        self.checkStatus = .invalid
        self.status = user.description_p
        self.profileFieldsDic = [:]
        self.isSpecialFocus = user.isSpecialFocus
        self.focusStatusList = user.focusStatusList
        self.tagData = user.tagData
    }

    init(contactInfo: ContactInfo, isSupportAnotherName: Bool = false) {
        var contactName = contactInfo.userName
        if isSupportAnotherName && !contactInfo.nameWithAnotherName.isEmpty {
            contactName = contactInfo.nameWithAnotherName
        }
        if !contactInfo.alias.isEmpty {
            contactName = contactInfo.alias
        }
        var status = Chatter.Description()
        status.text = contactInfo.description_p
        // Server接口没有type字段，取默认值
        status.type = .onDefault
        let tenantName = Self.fetchSecurityTenantName(contactInfo: contactInfo)
        self.name = contactName //displayName
        self.pinyinOfName = contactInfo.namePy //user.pinyinOfName
        self.avatarKey = contactInfo.avatarKey
        self.entityId = contactInfo.userID
        self.hasNext = false
        self.description = tenantName
        self.hasRegister = true
        self.isRobot = false
        self.isLeader = false
        self.leaderType = .subLeader
        self.isExternal = false
        self.isAdministrator = false
        self.isSuperAdministrator = false
        self.disableTags = []
        self.checkStatus = .invalid
        self.status = status
        self.profileFieldsDic = [:]
        self.isSpecialFocus = contactInfo.isSpecialFocus
        self.tagData = nil
        self.contactInfo = contactInfo
    }

    init(nameCardInfo: NameCardInfo) {
        let contactName = nameCardInfo.name
        var status = Chatter.Description()
        // Server接口没有type字段，取默认值
        status.type = .onDefault

        self.name = contactName //displayName
        self.avatarKey = nameCardInfo.avatarKey
        self.entityId = nameCardInfo.namecardId
        self.hasNext = false
        self.description = nameCardInfo.companyName
        self.hasRegister = true
        self.isRobot = false
        self.isLeader = false
        self.leaderType = .subLeader
        self.isExternal = false
        self.isAdministrator = false
        self.isSuperAdministrator = false
        self.disableTags = []
        self.checkStatus = .invalid
        self.status = status
        self.profileFieldsDic = [:]
        self.tagData = nil
    }

    init(nameCardCellViewModel: NameCardListCellViewModel) {
//        let contactName = entityId.name
        var status = Chatter.Description()
        // Server接口没有type字段，取默认值
        status.type = .onDefault

        self.name = nameCardCellViewModel.displayTitle //displayName
        self.avatarKey = nameCardCellViewModel.avatarKey
        self.entityId = nameCardCellViewModel.entityId
        self.avatar = nameCardCellViewModel.avatarImage
        self.hasNext = false
        self.description = nameCardCellViewModel.displaySubTitle
        self.customTags = nameCardCellViewModel.itemTags
        self.hasRegister = true
        self.isRobot = false
        self.isLeader = false
        self.leaderType = .subLeader
        self.isExternal = false
        self.isAdministrator = false
        self.isSuperAdministrator = false
        self.disableTags = []
        self.checkStatus = .invalid
        self.status = status
        self.profileFieldsDic = [:]
        self.tagData = nil
    }

    init(oncall: Oncall) {
        self.name = oncall.name
        self.pinyinOfName = "" //oncall.namePinyin
        self.avatarKey = oncall.avatar.key
        self.entityId = oncall.id
        self.description = oncall.description
        self.hasNext = false
        self.hasRegister = true
        self.isRobot = false
        self.isLeader = false
        self.leaderType = .subLeader
        self.isExternal = false
        self.isAdministrator = false
        self.isSuperAdministrator = false
        self.disableTags = []
        self.checkStatus = .invalid
        self.profileFieldsDic = [:]
        self.tagData = nil
    }

    private static func fetchSecurityTenantName(contactInfo: ContactInfo) -> String {
        let tenantName = contactInfo.tenantName
        switch contactInfo.tenantNameStatus {
        case .notFriend, .visible:
            return contactInfo.tenantName
        case .hide:
            return BundleI18n.LarkContact.Lark_IM_Profile_UserHideOrgInfo_Placeholder
        case .unknown:
            break
        @unknown default:
            break
        }
        return tenantName
    }
}
