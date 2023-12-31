//
//  TrackUtils.swift
//  LarkContact
//
//  Created by Sylar on 2018/3/28.
//  Copyright © 2018年 Bytedance. All rights reserved.
//

import UserNotifications
import Foundation
import Homeric
import LKCommonsTracker
import LarkMessengerInterface
import LarkAccountInterface
import LarkModel
import LarkPerf
import LarkSnsShare
import RustPB
import AppReciableSDK
import LarkCore

final class Tracer {
    enum ContactBlockSource {
        case im
        case profile
    }
    enum ContactRelationType: String {
        case unknown = ""
        case inner = "internal"
        case external_nonfriend = "external_nonfriend"
        case external_friend = "external_friend"
        case namecard = "name_card"
    }

    enum SelectFromType: String {
        case orgStructure
        case externalContactList
        case search
    }

    static func trackEnterContactHome() {
        Tracker.post(TeaEvent(Homeric.CONTACT_HOME_VIEW, params: ["category": "Contact"]))
    }

    static func trackEnterContactBots() {
        Tracker.post(TeaEvent(Homeric.CONTACT_BOTS_VIEW, params: ["category": "Contact"]))
    }

    static func trackContactOnCall(id: String) {
        Tracker.post(TeaEvent(Homeric.CONTACT_ONCALL_ENTER, params: ["category": "Contact", "oncallid": id]))
    }

    static func trackEnterContactGroups() {
        Tracker.post(TeaEvent(Homeric.CONTACT_GROUPS_VIEW, params: ["category": "Contact"]))
    }
    static func trackClickEnterChat(groupId: String) {
        Tracker.post(TeaEvent(Homeric.CONTACT_GROUPS_GROUP_CLICK, params: ["group_id": groupId]))
    }
    static func trackClickGroupSegment(segment: String) {
        Tracker.post(TeaEvent(Homeric.CONTACT_GROUPS_CATEGORY_CLICK, params: ["location": segment]))
    }

    static func trackContactBlock(blockSource: ContactBlockSource, userID: String) {
        var source = ""
        switch blockSource {
        case .im:
            source = "im_block"
        case .profile:
            source = "profile_block"
        }
        Tracker.post(TeaEvent(Homeric.CONTACT_BLOCK,
                              params: ["source": source,
                                       "to_user_id": userID],
                              md5AllowList: ["to_user_id"]))
    }

    static func trackContactUnBlock(unblockSource: ContactBlockSource, userID: String) {
        var source = ""
        switch unblockSource {
        case .im:
            source = "im_unblock"
        case .profile:
            source = "profile_unblock"
        }
        Tracker.post(TeaEvent(Homeric.CONTACT_UNBLOCK,
                              params: ["source": source,
                                       "to_user_id": userID],
                              md5AllowList: ["to_user_id"]))
    }

    static func trackFailSearchThenInvite() {
        Tracker.post(TeaEvent(Homeric.APPLY_EXTERNAL_FRIEND_CLICK_FROM_SEARCH))
    }

    static func trackInviteEntrance() {
        Tracker.post(TeaEvent(Homeric.APPLY_EXTERNAL_FRIEND_CLICK))
    }

    static func trackInviteByPhone() {
        Tracker.post(TeaEvent(Homeric.APPLY_EXTERNAL_FRIEND_BY_PHONE))
    }

    static func trackInviteByEmail() {
        Tracker.post(TeaEvent(Homeric.APPLY_EXTERNAL_FRIEND_BY_EMAIL))
    }

    static func trackPushNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { setting in
            let isAuthorized = setting.authorizationStatus == .authorized ? "open" : "close"
            Tracker.post(TeaEvent("ttpush_push_notification_status", params: ["out_status": isAuthorized]))
        }
    }

    static func tarckContactEnter(type: String) {
        Tracker.post(TeaEvent(Homeric.CONTACT_ENTER, params: ["enter_type": type]))
    }

    static func tarckContactEduEnter() {
        Tracker.post(TeaEvent(Homeric.CORE_CONTACTS_CLICK_SCHOOL_PARENT_CONTACTS))
    }

    static func tarckContactEduNodeEnter(nodeDeep: Int) {
        Tracker.post(TeaEvent(Homeric.CORE_CONTACTS_CLICK_SCHOOL_PARENT_CONTACTS_NODE, params: ["node_deep": nodeDeep]))
    }

    static func tarckContactEduProfileEnter(userID: String, tagInfos: Set<RustPB.Contact_V1_EduRoleType>) {
        let userType: Int
        if tagInfos.contains(.student) {
            userType = 1
        } else if tagInfos.contains(.parent) {
            userType = 2
        } else {
            userType = 3
        }
        Tracker.post(TeaEvent(Homeric.CORE_CONTACTS_CLICK_SCHOOL_PARENT_CONTACTS_OPEN_PROFILE, params: ["to_user_id": userID.sha1(), "user_type": userType, "source": "school_parent_contacts"]))
    }

    static func tarckContactEduInvite() {
        Tracker.post(TeaEvent(Homeric.CORE_CONTACT_HOME_SCHOOL_CONTACT_INVITE_PARENTS_CLICK))
    }

    static func tarckCreateGroup(chatID: String, isCustom: Bool, isExternal: Bool, isPublic: Bool, modeType: String, count: Int) {
        func trackType() -> String {
            if isExternal {
                return "external"
            }
            return isPublic ? "public" : "private"
        }
        Tracker.post(TeaEvent(Homeric.GROUP_CREATE, params: ["chat_id": chatID,
                                                             "type": trackType(),
                                                             "mode": modeType,
                                                             "avatar": "default",
                                                             "members_number": count,
                                                             "group_name": isCustom ? "custom" : "default"]))
    }

    static func tarckGroupIsPublic(isPublic: Bool) {
        Tracker.post(TeaEvent(Homeric.GROUP_CREATE_MOBILE_NEXTPAGE_CLICK, params: ["group_type": isPublic ? "public" : "private"]))
    }

    static func trackCreateGroupConfirmed(
        isP2P: Bool,
        isExternal: Bool,
        isPublic: Bool,
        isThread: Bool,
        chatterNumbers: Int
    ) {
        var type = ""
        if isExternal {
            type = "external"
        } else {
            type = isPublic ? "public" : "private"
        }
        let mode = isThread ? "topic" : "classic"
        // PM要求打点的members_number必须得是初创群时的人数，在单聊建群的时候需要加上自己
        let params: [String: Any] = [
            "type": type,
            "mode": mode,
            "members_number": isP2P ? chatterNumbers + 1 : chatterNumbers
        ]

        if !isP2P, isExternal {
            // 群组加入外部成员生成新的外部群打点
            Tracker.post(TeaEvent(Homeric.CREATE_EXTERNAL_GROUP_FROM_EXISTING_CHAT, params: params))
        } else if isP2P {
            // 单聊建群打点
            Tracker.post(TeaEvent(Homeric.DIRECT_MESSAGE_TO_GROUP_CHAT_CONFIRMED, params: params))
        }
    }

    static func trackCreateGroupSelectMembers(_ type: SelectFromType) {
        Tracker.post(TeaEvent(Homeric.CREATE_GROUP_SELECT_MEMBERS, params: ["type": type.rawValue]))
    }

    static func trackSingleToGroupSelectMemberConfirm(_ count: Int, _ syncMessages: Bool) {
        let params = ["group_member_count": "\(count)",
            "sync_history": syncMessages ? "y" : "n",
            "type": "classic"]

        Tracker.post(TeaEvent(Homeric.SINGLE_TO_GROUP_SELECT_MEMBER_CONFIRM, params: params))
    }

    // 单聊确认建群
    static func trackSingleToGroupConfirm(syncMessage: Bool, selectedCount: Int, chatID: String) {
        Tracker.post(TeaEvent(Homeric.SINGLE_TO_GROUP_SELECT_MESSAGE_CONFIRM, params: ["msg_sync": syncMessage ? "true" : "false",
                                                                                       "msg_count": selectedCount,
                                                                                       "chat_id": chatID]))
    }

    // 创群成功
    static func trackCreateGroupSuccess(chat: Chat, from: CreateGroupFromWhere) {
        Tracker.post(TeaEvent(Homeric.IM_CHAT_CREATE_SUCCESS,
                              params: ["source": from.rawValue,
                                       "type": MessengerChatType.getTypeWithChat(chat).rawValue,
                                       "mode": MessengerChatMode.getTypeWithIsPublic(chat.isPublic).rawValue,
                                       "is_external": chat.isCrossTenant ? 1 : 0])
        )
    }

    static func imGroupMemberAddClickGroupMemberType(_ addMemberTypes: AddMemberType, chat: Chat) {
        switch addMemberTypes {
        case .contact:
            /// 在「添加群成员」页面，发生动作事件（74）
            var params: [AnyHashable: Any] = ["click": "group_member_add",
                                              "target": "im_group_member_add_view" ]
            params += IMTracker.Param.chat(chat)
            Tracker.post(TeaEvent(Homeric.IM_GROUP_MEMBER_ADD_CLICK, params: params))
        case .link:
            /// 在「添加群成员」页面，发生动作事件（75）
            var params: [AnyHashable: Any] = ["click": "group_link",
                                              "target": "im_group_link_view" ]
            params += IMTracker.Param.chat(chat)
            Tracker.post(TeaEvent(Homeric.IM_GROUP_MEMBER_ADD_CLICK, params: params))
        case .QRcode:
            /// 在「添加群成员」页面，发生动作事件（76）
            var params: [AnyHashable: Any] = ["click": "group_QR",
                                              "target": "im_group_QR_view" ]
            params += IMTracker.Param.chat(chat)
            Tracker.post(TeaEvent(Homeric.IM_GROUP_MEMBER_ADD_CLICK, params: params))
        }
    }

    /// 在「添加群成员」页面，发生动作事件（77）
    static func imGroupMemberAddClickCancel() {
        Tracker.post(TeaEvent(Homeric.IM_GROUP_MEMBER_ADD_CLICK, params: ["click": "cancel",
                                                                          "target": "im_chat_setting_view" ]))
    }

    // 添加群成员打点
    static func imChatSettingAddMemberClick(chatId: String,
                                            isAdmin: Bool,
                                            count: Int,
                                            isPublic: Bool,
                                            chatType: MessengerChatType,
                                            source: AddMemberSource) {
        let memberType = MessengerMemberType.getTypeWithIsAdmin(isAdmin)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_ADD_MEMBER_CLICK,
                              params: ["chat_id": chatId,
                                       "member_type": memberType.rawValue,
                                       "source": source.rawValue,
                                       "count": "\(count)",
                                       "type": chatType.rawValue,
                                       "mode": MessengerChatMode.getTypeWithIsPublic(isPublic).rawValue
                              ]))
    }
}

// MARK: - 查看选择组件 & 选择具体 Item https://bytedance.feishu.cn/sheets/shtcnjIB71cPVNkm1G2BNhTi4Df?sheet=RacGCs
extension Tracer {
    // 选择维度
    enum PickerItemSource: String {
        case bussinessOrg = "bussiness_org" /// 组织架构
        case externalContacts = "external_contacts" /// 外部联系人
        case academicOrg = "academic_org" /// 家校通迅录
        case myOwnedGroup = "groups_i_manage" /// 我管理的群
        case userGroup = "user_group" /// 用户组
    }

    // 查看选择组件场景
    enum PickerViewScene: String {
        case plus = "group_im_create_group" /// IM加号建群
        case p2p = "group_im_add_to_p2p_chat" /// IM单聊加人
        case group = "group_im_add_to_group_chat" /// IM群聊加人
        case forward = "group_im_create_group_from_forward" /// 转发时建群

    }

    static func trackPickerItemSelect(source: PickerItemSource, index: Int, depth: Int = 1) {
        Tracker.post(TeaEvent(Homeric.LARKW_PICKER_ITEM_CLICK,
                              params: ["source": source.rawValue,
                                       "order": index,
                                       "breadcrumb_depth": depth])
        )
    }

    static func trackOpenPickerView(_ scene: PickerViewScene) {
        Tracker.post(TeaEvent(Homeric.LARKW_PICKER_VIEW,
                              params: ["scenario": scene.rawValue])
        )
    }
}

// MARK: - Onboarding
extension Tracer {

    enum InviteType: String {
        case phone
        case email
    }

    enum InviteResult: Int {
        case success
        case existingAccount
        case badConnection
        case invalidInput
        case failed
    }

    static func trackInviteTenantViaLinkShow() {
        Tracker.post(TeaEvent(Homeric.INVITE_TENANT_VIA_LINK_VIEW))
    }

    static func trackInviteTenantViaQRCodeShow() {
        Tracker.post(TeaEvent(Homeric.INVITE_TENANT_VIA_QRCODE))
    }

    static func trackInviteTenantViaEmailShow() {
        Tracker.post(TeaEvent(Homeric.INVITE_TENANT_VIA_EMAIL_VIEW))
    }

    static func trackInviteTenantViaPhoneShow() {
        Tracker.post(TeaEvent(Homeric.INVITE_TENANT_VIA_PHONE_VIEW))
    }

    static func trackInviteTenantViaLinkCopied() {
        Tracker.post(TeaEvent(Homeric.INVITE_TENANT_VIA_LINK_COPY))
    }

    static func trackInviteTenantViaQRCodeSaved() {
        Tracker.post(TeaEvent(Homeric.INVITE_TENANT_VIA_QRCODE_SAVE))
    }

    static func trackInviteTenantRuleOpen() {
        Tracker.post(TeaEvent(Homeric.INVITE_TENANT_RULE_OPEN))
    }

    static func trackInvieTenantRuleClose() {
        Tracker.post(TeaEvent(Homeric.INVITE_TENANT_RULE_CLOSE))
    }

    static func trackInviteTenantClickNoTarget() {
        Tracker.post(TeaEvent(Homeric.INVITE_TENANT_CLICK_NONTARGET))
    }

    static func trackInviteTenantClickTarget() {
        Tracker.post(TeaEvent(Homeric.INVITE_TENANT_CLICK_TARGET))
    }

    static func trackInviteTenantClickInvite(type: InviteType, result: InviteResult) {
        Tracker.post(TeaEvent(Homeric.INVITE_TENANT_CLICK_SHARE, params: ["invite_type": type.rawValue, "toast_number": result.rawValue]))
    }

    /// 升级团队联系人 tab banner 展示
    static func trackGuideUpdateBannerShow() {
        Tracker.post(TeaEvent(Homeric.GUIDE_UPDATE_BANNER_SHOW))
    }

    /// 升级团队联系人 tab banner 展示
    static func trackGuideUpdateBannerClose() {
        Tracker.post(TeaEvent(Homeric.GUIDE_UPDATE_BANNER_CLOSE))
    }
}

// MARK: - InviteMember
extension Tracer {
    /// 移动端在建群流程中点击群类型进入详情页
    static func trackGoupType() {
        Tracker.post(TeaEvent(Homeric.GROUP_GROUPTYPE, category: "group"))
    }

    /// 移动端在建群流程中点击群类型进入详情页后点击取消按钮
    static func trackGoupTypeCancel() {
        Tracker.post(TeaEvent(Homeric.GROUP_GROUPTYPE_CANCEL, category: "group"))
    }

    /// 移动端在建群流程中点击群类型进入详情页后点击经典模式
    static func trackGoupTypeModeClassic() {
        Tracker.post(TeaEvent(Homeric.GROUP_GROUPTYPE_MODE_CLASSIC, category: "group"))
    }

    /// 移动端在建群流程中点击群类型进入详情页后点击经典模式
    static func trackGoupTypeModeTopic() {
        Tracker.post(TeaEvent(Homeric.GROUP_GROUPTYPE_MODE_TOPIC, category: "group"))
    }

    /// 移动端在建群流程中点击群类型进入详情页后点击阅后公开类型
    static func trackGoupTypePublic() {
        Tracker.post(TeaEvent(Homeric.GROUP_GROUPTYPE_TYPE_PUBLIC, category: "group"))
    }

    /// 移动端在建群流程中点击群类型进入详情页后点击阅后私密类型
    static func trackGoupTypePrivate() {
        Tracker.post(TeaEvent(Homeric.GROUP_GROUPTYPE_TYPE_PRIVATE, category: "group"))
    }

    /// 邀请成员_读取通讯录
    /// location: email,phone
    /// access: deny,approve,goto setting
    static func trackInviteMemberImportContact(location: String, access: String) {
        Tracker.post(TeaEvent(Homeric.INVITE_MEMBER_IMPORT_CONTACT, params: ["location": location, "access": access]))
    }

}

// MARK: - 统一邀请
extension Tracer {
    enum ShareMethod: String {
        case copyLink = "copy_link"
        case shareLink = "share_link"
        case saveQrcode = "save_qr_code"
        case shareQrcode = "share_qr_code"
    }

    enum ShareChannel: String {
        case wechat = "wechat"
        case qq = "qq"
        case weibo = "weibo"
        case system = "system"
        case inviteMessage = "invite_message"
        case inviteEmail = "invite_email"
        case none = ""

        static func transform(with shareItemType: LarkShareItemType) -> ShareChannel? {
            switch shareItemType {
            case .wechat:
                return .wechat
            case .weibo:
                return .weibo
            case .qq:
                return .qq
            case .more:
                return .system
            default:
                return nil
            }
        }
    }

    enum ShareType: String {
        case qrcode = "qr_code"
        case link = "link"
    }

    enum AddMemberSourceTab: String {
        case qrcode = "qrcode"
        case link = "link"
        case teamCode = "team_code"
    }

    enum ImportMemberScenes: String {
        case addMemberChannel = "add_member_channel"
        case addByPhone = "add_by_phone"
        case addByEmail = "add_by_email"
    }

    /// 邀请人_联系人tab入口点击
    /// entry_type: union=统一入口，internal = 直接跳转成员页，external = 直接跳转外部联系人页
    static func trackInvitePeopleContactsClick(entry_type: String) {
        Tracker.post(TeaEvent(Homeric.INVITE_PEOPLE_ENTRY_CONTACTS_CLICK, params: ["entry_type": entry_type]))
    }

    /// 保存二维码
    static func trackInvitePeopleExternalSaveQRCode(source: String) {
        Tracker.post(TeaEvent(Homeric.INVITE_PEOPLE_EXTERNAL_SAVE_QRCODE, params: ["source": source]))
    }

    /// 复制链接
    static func trackInvitePeopleExternalCopyLink(source: String) {
        Tracker.post(TeaEvent(Homeric.INVITE_PEOPLE_EXTERNAL_COPY_LINK, params: ["source": source]))
    }

    /// 查看隐私设置
    static func trackInvitePeopleExternalPrivacy(source: String) {
        Tracker.post(TeaEvent(Homeric.INVITE_PEOPLE_EXTERNAL_PRIVACY, params: ["source": source]))
    }

    /// 外部联系人搜索，无结果，点邀请，点发送
    /// result: 0 失败 1 成功
    /// changeTo: 修改了收件人，包括国家码 range: {0: 未修改; 1:修改}
    static func trackInvitePeopleExternalSearchInviteSend(result: String, changeTo: Int) {
        Tracker.post(TeaEvent(Homeric.INVITE_PEOPLE_EXTERNAL_SEARCH_INVITE_SEND, params: ["result": result, "change_to": changeTo]))
    }

    /// A1分流内外页面，邀请外部联系人入口展示
    static func trackInvitePeopleExternalCtaView() {
        Tracker.post(TeaEvent(Homeric.INVITE_PEOPLE_EXTERNAL_CTA_VIEW, params: [:]))
    }

    /// A1分流内外页面，帮助中心点击
    static func trackInvitePeopleHelpClick() {
        Tracker.post(TeaEvent(Homeric.INVITE_PEOPLE_HELP_CLICK, params: [:]))
    }

    /// 进入邀请外部联系人操作页, status: 是否因为隐私设置被遮罩，0 正常 1 被遮罩
    static func trackInvitePeopleExternalView(status: Int, source: String) {
        Tracker.post(TeaEvent(Homeric.INVITE_PEOPLE_EXTERNAL_VIEW, params: ["status": status, "source": source]))
    }

    /// A3，分享二维码
    /// method: 分享渠道 range: {system,wechat,qq,weibo}
    static func trackInvitePeopleExternalShareQrcode(method: String, source: String) {
        Tracker.post(TeaEvent(Homeric.INVITE_PEOPLE_EXTERNAL_SHARE_QRCODE, params: ["method": method, "source": source]))
    }

    /// A4，分享链接
    /// method: 分享渠道 range: {system,wechat,qq,weibo}
    static func trackInvitePeopleExternalShareLink(method: String, source: String) {
        Tracker.post(TeaEvent(Homeric.INVITE_PEOPLE_EXTERNAL_SHARE_LINK, params: ["method": method, "source": source]))
    }

    /// A4，切换至二维码
    static func trackInvitePeopleExternalSwitchtoQrcode(source: String) {
        Tracker.post(TeaEvent(Homeric.INVITE_PEOPLE_EXTERNAL_SWITCHTO_QRCODE, params: ["source": source]))
    }

    /// A3，切换至链接
    static func trackInvitePeopleExternalSwitchtoLink(source: String) {
        Tracker.post(TeaEvent(Homeric.INVITE_PEOPLE_EXTERNAL_SWITCHTO_LINK, params: ["source": source]))
    }

    /// A3，读取通讯录
    /// access: 获取权限结果
    static func trackInvitePeopleExternalImport(access: String, source: String) {
        Tracker.post(TeaEvent(Homeric.INVITE_PEOPLE_EXTERNAL_IMPORT, params: ["access": access, "source": source]))
    }

    /// A3，读取通讯录，右侧字母导航
    static func trackInvitePeopleExternalImportIndex(source: String) {
        Tracker.post(TeaEvent(Homeric.INVITE_PEOPLE_EXTERNAL_IMPORT_INDEX, params: ["source": source]))
    }

    /// A3，读取通讯录，某号码有结果，点添加
    static func trackInvitePeopleExternalImportAdd(source: String) {
        Tracker.post(TeaEvent(Homeric.INVITE_PEOPLE_EXTERNAL_IMPORT_ADD, params: ["source": source]))
    }

    /// A3，读取通讯录，某号码无结果，点邀请，发送前的预览页
    static func trackInvitePeopleExternalImportInviteView(source: String) {
        Tracker.post(TeaEvent(Homeric.INVITE_PEOPLE_EXTERNAL_IMPORT_INVITE_VIEW, params: ["source": source]))
    }

    /// A3，读取通讯录，无结果，点邀请，点取消
    /// changeTo: 修改了收件人，包括国家码 range: {0: 未修改; 1:修改}
    static func trackInvitePeopleExternalImportInviteCancel(changeTo: Int) {
        Tracker.post(TeaEvent(Homeric.INVITE_PEOPLE_EXTERNAL_IMPORT_INVITE_CANCEL, params: ["change_to": changeTo]))
    }

    /// A3，读取通讯录，无结果，点邀请，点发送
    /// result: 发送结果 range: {0：失败；1：成功}
    /// changeTo: 修改了收件人，包括国家码 range: {0: 未修改; 1:修改}
    static func trackInvitePeopleExternalImportInviteSend(result: String, changeTo: Int) {
        Tracker.post(TeaEvent(Homeric.INVITE_PEOPLE_EXTERNAL_IMPORT_INVITE_SEND, params: ["result": result, "change_to": changeTo]))
    }

    /// A3，搜索
    /// result: 可查到的身份个数
    static func trackInvitePeopleExternalSearch(result: Int, source: String) {
        Tracker.post(TeaEvent(Homeric.INVITE_PEOPLE_EXTERNAL_SEARCH, params: ["result": result, "source": source]))
    }

    /// A3，搜索，无结果，点邀请，点取消
    /// changeTo: 修改了收件人，包括国家码 range: {0: 未修改; 1:修改}
    static func trackInvitePeopleExternalSearchInviteCancel(changeTo: Int) {
        Tracker.post(TeaEvent(Homeric.INVITE_PEOPLE_EXTERNAL_SEARCH_INVITE_CANCEL, params: [:]))
    }

    /// 搜索，无结果，点邀请
    static func trackInvitePeopleExternalSearchNomatchInvite(source: String) {
        Tracker.post(TeaEvent(Homeric.INVITE_PEOPLE_EXTERNAL_SEARCH_NOMATCH_INVITE, params: ["source": source]))
    }

    // 首次添加引导展示
    static func trackInvitePeopleExternalGuideView(source: String) {
        Tracker.post(TeaEvent(Homeric.INVITE_PEOPLE_EXTERNAL_GUIDE_VIEW, params: ["source": source]))
    }

    // 首次添加引导点击开始添加
    static func trackInvitePeopleExternalGuideClick(source: String) {
        Tracker.post(TeaEvent(Homeric.INVITE_PEOPLE_EXTERNAL_GUIDE_CLICK, params: ["source": source]))
    }

    // 首次添加引导点击关闭按钮
    static func trackInvitePeopleExternalGuideClose(source: String) {
        Tracker.post(TeaEvent(Homeric.INVITE_PEOPLE_EXTERNAL_GUIDE_CLOSE, params: ["source": source]))
    }

    // 点击我的二维码
    static func trackInvitePeopleExternalQrcodeClick(source: String) {
        Tracker.post(TeaEvent(Homeric.INVITE_PEOPLE_EXTERNAL_QRCODE_CLICK, params: ["source": source]))
    }

    // 点击扫一扫
    static func trackInvitePeopleExternalScanQRCodeClick(source: String) {
        Tracker.post(TeaEvent(Homeric.INVITE_PEOPLE_EXTERNAL_SCAN_QRCODE_CLICK, params: ["source": source]))
    }

    // 搜索，有结果，点击进入 profile
    static func trackInvitePeopleExternalSearchAdd(source: String) {
        Tracker.post(TeaEvent(Homeric.INVITE_PEOPLE_EXTERNAL_SEARCH_ADD, params: ["source": source]))
    }

    // 我的二维码页面展示
    static func trackInvitePeopleExternalQrcodeShow(source: String) {
        Tracker.post(TeaEvent(Homeric.INVITE_PEOPLE_EXTERNAL_QRCODE_SHOW, params: ["source": source]))
    }

    /// 进入统一邀请入口分流页
    static func trackInvitationEnterChooseShow() {
        Tracker.post(TeaEvent(Homeric.INVITATION_ENTER_CHOOSE_SHOW, params: [:]))
    }

    /// 分流页选择邀请外部联系人
    static func trackInvitationChooseExternalClick() {
        Tracker.post(TeaEvent(Homeric.INVITATION_CHOOSE_EXTERNAL_CLICK, params: [:]))
    }

    /// 分流页选择添加成员
    static func trackInvitationChooseInternalClick() {
        Tracker.post(TeaEvent(Homeric.INVITATION_CHOOSE_INTERNAL_CLICK, params: [:]))
    }

    /// 进入添加成员页
    /// source: 参数含义待填 range: {onboarding_guide,}
    static func trackAddMemberSendShow(source: MemberInviteSourceScenes) {
        Tracker.post(TeaEvent(Homeric.ADD_MEMBER_SEND_SHOW, params: ["source": source.toString()]))
    }

    /// 添加成员页点击添加成员按钮
    /// source: 参数含义待填 range: {onboarding_guide,}
    static func trackAddMemberSendClick(source: MemberInviteSourceScenes) {
        Tracker.post(TeaEvent(Homeric.ADD_MEMBER_SEND_CLICK, params: ["source": source.toString()]))
    }

    /// 添加成员页进入手机号输入页
    /// source: 参数含义待填 range: {onboarding_guide,}
    static func trackAddMemberInputPhone(source: MemberInviteSourceScenes) {
        Tracker.post(TeaEvent(Homeric.ADD_MEMBER_INPUT_PHONE, params: ["source": source.toString()]))
    }

    /// 添加成员页进入邮箱输入页
    /// source: 参数含义待填 range: {onboarding_guide,}
    static func trackAddMemberInputEmail(source: MemberInviteSourceScenes) {
        Tracker.post(TeaEvent(Homeric.ADD_MEMBER_INPUT_EMAIL, params: ["source": source.toString()]))
    }

    /// 添加成员页进入姓名输入框
    /// source: 参数含义待填 range: {onboarding_guide,}
    static func trackAddMemberInputName(source: MemberInviteSourceScenes) {
        Tracker.post(TeaEvent(Homeric.ADD_MEMBER_INPUT_NAME, params: ["source": source.toString()]))
    }

    /// 进入通讯录导入页
    /// source: 参数含义待填 range: {onboarding_guide,}
    static func trackImportContactsChooseShow(source: MemberInviteSourceScenes) {
        Tracker.post(TeaEvent(Homeric.IMPORT_CONTACTS_CHOOSE_SHOW, params: ["source": source.toString()]))
    }

    /// 添加成员页点击链接邀请
    /// source: 参数含义待填 range: {onboarding_guide,}
    static func trackAddMemberLinkInviteClick(source: MemberInviteSourceScenes) {
        Tracker.post(TeaEvent(Homeric.ADD_MEMBER_LINK_INVITE_CLICK, params: ["source": source.toString()]))
    }

    /// 添加成员页点击二维码邀请
    /// source: 参数含义待填 range: {onboarding_guide,}
    static func trackAddMemberQrcodeInviteClick(source: MemberInviteSourceScenes) {
        Tracker.post(TeaEvent(Homeric.ADD_MEMBER_QRCODE_INVITE_CLICK, params: ["source": source.toString()]))
    }

    /// 添加成员页切换为邮箱添加
    /// source: 参数含义待填 range: {onboarding_guide,}
    static func trackAddMemberSwitchToEmailClick(source: MemberInviteSourceScenes) {
        Tracker.post(TeaEvent(Homeric.ADD_MEMBER_SWITCH_TO_EMAIL_CLICK, params: ["source": source.toString()]))
    }

    /// 添加成员页切换为手机号添加
    /// source: 参数含义待填 range: {onboarding_guide,}
    static func trackAddMemberSwitchToPhoneClick(source: MemberInviteSourceScenes) {
        Tracker.post(TeaEvent(Homeric.ADD_MEMBER_SWITCH_TO_PHONE_CLICK, params: ["source": source.toString()]))
    }

    /// 进入链接邀请页
    /// source: 参数含义待填 range: {onboarding_guide,}
    static func trackAddMemberLinkInviteShow(source: MemberInviteSourceScenes) {
        Tracker.post(TeaEvent(Homeric.ADD_MEMBER_LINK_INVITE_SHOW, params: ["source": source.toString()]))
    }

    /// 进入二维码邀请页
    /// source: 参数含义待填 range: {onboarding_guide,}
    static func trackAddMemberQrcodeInviteShow(source: MemberInviteSourceScenes) {
        Tracker.post(TeaEvent(Homeric.ADD_MEMBER_QRCODE_INVITE_SHOW, params: ["source": source.toString()]))
    }

    /// 链接邀请页点击复制按钮
    /// source: 参数含义待填 range: {onboarding_guide,}
    static func trackAddMemberLinkInviteCopyClick(source: MemberInviteSourceScenes) {
        Tracker.post(TeaEvent(Homeric.ADD_MEMBER_LINK_INVITE_COPY_CLICK, params: ["source": source.toString()]))
    }

    /// 链接邀请页点击分享按钮
    /// source: 参数含义待填 range: {onboarding_guide,}
    static func trackAddMemberLinkInviteShareClick(source: MemberInviteSourceScenes, method: String) {
        Tracker.post(TeaEvent(Homeric.ADD_MEMBER_LINK_INVITE_SHARE_CLICK, params: ["source": source.toString(), "method": method]))
    }

    /// 二维码邀请页点击保存按钮
    /// source: 参数含义待填 range: {onboarding_guide,}
    static func trackAddMemberQrcodeInviteSaveClick(source: MemberInviteSourceScenes) {
        Tracker.post(TeaEvent(Homeric.ADD_MEMBER_QRCODE_INVITE_SAVE_CLICK, params: ["source": source.toString()]))
    }

    /// 二维码邀请页点击分享按钮
    /// source: 参数含义待填 range: {onboarding_guide,}
    static func trackAddMemberQrcodeInviteShareClick(source: MemberInviteSourceScenes, method: String) {
        Tracker.post(TeaEvent(Homeric.ADD_MEMBER_QRCODE_INVITE_SHARE_CLICK, params: ["source": source.toString(), "method": method]))
    }

    /// 邀请页点击二维码和链接切换
    /// source: 参数含义待填 range: {onboarding_guide,}
    static func trackAddMemberSwitchLinkQrcodeClick(source: MemberInviteSourceScenes) {
        Tracker.post(TeaEvent(Homeric.ADD_MEMBER_SWITCH_LINK_QRCODE_CLICK, params: ["source": source.toString()]))
    }

    /// 邀请页点击刷新按钮
    /// source: 参数含义待填 range: {onboarding_guide,}
    static func trackAddMemberInviteRefreshClick(source: MemberInviteSourceScenes, sourceTab: AddMemberSourceTab) {
        Tracker.post(TeaEvent(Homeric.ADD_MEMBER_INVITE_REFRESH_CLICK, params: ["source": source.toString(), "add_member_tab": sourceTab.rawValue]))
    }

    /// 邀请页点击刷新弹窗中的确认按钮
    /// source: 参数含义待填 range: {onboarding_guide,}
    static func trackAddMemberInviteRefreshConfirmClick(source: MemberInviteSourceScenes) {
        Tracker.post(TeaEvent(Homeric.ADD_MEMBER_INVITE_REFRESH_CONFIRM_CLICK, params: ["source": source.toString()]))
    }

    /// 邀请页点击刷新弹窗中的取消按钮
    /// source: 参数含义待填 range: {onboarding_guide,}
    static func trackAddMemberInviteRefreshCancelClick(source: MemberInviteSourceScenes) {
        Tracker.post(TeaEvent(Homeric.ADD_MEMBER_INVITE_REFRESH_CANCEL_CLICK, params: ["source": source.toString()]))
    }

    /// 添加成功弹窗展示
    /// source: 参数含义待填 range: {onboarding_guide,}
    static func trackAddMemberInviteSuccessDialogShow(source: MemberInviteSourceScenes) {
        Tracker.post(TeaEvent(Homeric.ADD_MEMBER_INVITE_SUCCESS_DIALOG_SHOW, params: ["source": source.toString()]))
    }

    /// 添加成功弹窗中点击完成按钮
    /// source: 参数含义待填 range: {onboarding_guide,}
    static func trackAddMemberInviteSuccessDialogDoneClick(source: MemberInviteSourceScenes) {
        Tracker.post(TeaEvent(Homeric.ADD_MEMBER_INVITE_SUCCESS_DIALOG_DONE_CLICK, params: ["source": source.toString()]))
    }

    /// 添加成功弹窗中点击添加更多按钮
    /// source: 参数含义待填 range: {onboarding_guide,}
    static func trackAddMemberInviteSuccessDialogMoreClick(source: MemberInviteSourceScenes) {
        Tracker.post(TeaEvent(Homeric.ADD_MEMBER_INVITE_SUCCESS_DIALOG_MORE_CLICK, params: ["source": source.toString()]))
    }

    /// 添加后待审批提示弹窗展示
    /// source: 参数含义待填 range: {onboarding_guide,}
    static func trackAddMemberInviteApproveDialogShow(source: MemberInviteSourceScenes) {
        Tracker.post(TeaEvent(Homeric.ADD_MEMBER_INVITE_APPROVE_DIALOG_SHOW, params: ["source": source.toString()]))
    }

    /// 添加后待审批提示弹窗中点击完成按钮
    /// source: 参数含义待填 range: {onboarding_guide,}
    static func trackAddMemberInviteApproveDialogDoneClick(source: MemberInviteSourceScenes) {
        Tracker.post(TeaEvent(Homeric.ADD_MEMBER_INVITE_APPROVE_DIALOG_DONE_CLICK, params: ["source": source.toString()]))
    }

    /// 添加后待审批提示弹窗中点击添加更多按钮
    /// source: 参数含义待填 range: {onboarding_guide,}
    static func trackAddMemberInviteApproveDialogMoreClick(source: MemberInviteSourceScenes) {
        Tracker.post(TeaEvent(Homeric.ADD_MEMBER_INVITE_APPROVE_DIALOG_MORE_CLICK, params: ["source": source.toString()]))
    }

    /// 添加成员页点击返回按钮
    /// source: 参数含义待填 range: {onboarding_guide,}
    static func trackAddMemberGoBackClick(source: MemberInviteSourceScenes) {
        Tracker.post(TeaEvent(Homeric.ADD_MEMBER_GO_BACK_CLICK, params: ["source": source.toString()]))
    }

    /// 链接/二维码邀请页点击返回按钮
    /// source: 参数含义待填 range: {onboarding_guide,}
    static func trackAddMemberLinkQrcodeInviteGoBackClick(source: MemberInviteSourceScenes) {
        Tracker.post(TeaEvent(Homeric.ADD_MEMBER_LINK_QRCODE_INVITE_GO_BACK_CLICK, params: ["source": source.toString()]))
    }

    /// 新用户引导_提示个人使用转为团队使用_转团队
    /// trigger: 提示出现的场景。添加成员：addmember
    static func trackGuideUpdateDialogClick() {
        Tracker.post(TeaEvent(Homeric.GUIDE_UPDATE_DIALOG_CLICK, params: [
            "trigger": "addmember",
            "path": "user_guide" /*路径，其他取值情况在Onboarding*/
        ]))
    }

    /// 新用户引导_提示个人使用转为团队使用_展示
    /// trigger: 提示出现的场景。添加成员：addmember
    static func trackGuideUpdateDialogShow() {
        Tracker.post(TeaEvent(Homeric.GUIDE_UPDATE_DIALOG_SHOW, params: [
            "trigger": "addmember",
            "path": "addmember"
        ]))
    }

    /// 新用户引导_提示个人使用转为团队使用_维持个人
    /// trigger: 提示出现的场景。添加成员：addmember
    static func trackGuideUpdateDialogSkip() {
        Tracker.post(TeaEvent(Homeric.GUIDE_UPDATE_DIALOG_SKIP, params: ["trigger": "addmember"]))
    }

    /// 添加成员分流页展示
    /// source: 暂无业务描述
    static func trackAddMemberChannelShow(source: MemberInviteSourceScenes) {
        Tracker.post(TeaEvent(Homeric.ADD_MEMBER_CHANNEL_SHOW, params: ["source": source.toString()]))
    }

    /// 添加成员分流页点击手机号添加
    /// source: 暂无业务描述
    static func trackAddMemberAddByPhoneClick(source: MemberInviteSourceScenes) {
        Tracker.post(TeaEvent(Homeric.ADD_MEMBER_ADD_BY_PHONE_CLICK, params: ["source": source.toString()]))
    }

    /// 添加成员分流页点击邮箱添加
    /// source: 暂无业务描述
    static func trackAddMemberAddByEmailClick(source: MemberInviteSourceScenes) {
        Tracker.post(TeaEvent(Homeric.ADD_MEMBER_ADD_BY_EMAIL_CLICK, params: ["source": source.toString()]))
    }

    /// 添加成员分流页点击邮箱/手机号添加
    /// source: 暂无业务描述
    static func trackAddMemberAddByPhoneOrEmailClick(source: MemberInviteSourceScenes) {
        Tracker.post(TeaEvent(Homeric.ADD_MEMBER_ADD_BY_PHONE_OR_EMAIL_CLICK, params: ["source": source.toString()]))
    }

    /// 添加成员分流页点击微信邀请
    /// source: 暂无业务描述
    /// result: 是否发送邀请，是：邀请发送完成，否：邀请未发送
    static func trackAddMemberWechatInviteClick(source: MemberInviteSourceScenes, result: String) {
        Tracker.post(TeaEvent(Homeric.ADD_MEMBER_WECHAT_INVITE_CLICK, params: ["source": source.toString()]))
    }

    /// 添加成员分流页点击查看团队码
    /// source: 暂无业务描述
    static func trackAddMemberViewTeamCodeClick(source: MemberInviteSourceScenes) {
        Tracker.post(TeaEvent(Homeric.ADD_MEMBER_VIEW_TEAM_CODE_CLICK, params: ["source": source.toString()]))
    }

    /// 添加成员 飞书内邀请
    static func trackAddMemberLarkInviteClick(source: MemberInviteSourceScenes) {
        Tracker.post(TeaEvent(Homeric.ADD_MEMBER_LARK_INVITE_CLICK, params: ["source": source.toString()]))
    }

    /// 添加成员 飞书内邀请结果
    /// - Parameter userCount: 邀请单聊数量
    /// - Parameter groupCount: 邀请群组数量
    static func trackAddMemberLarkInviteShareClick(source: MemberInviteSourceScenes, userCount: Int, groupCount: Int) {
        Tracker.post(
            TeaEvent(Homeric.ADD_MEMBER_LARK_FORWARD,
                     params: ["source": source.toString(), "user_count": "\(userCount)", "group_count": "\(groupCount)"])
        )
    }

    /// 进入团队码查看页面
    /// source: 暂无业务描述
    static func trackAddMemberTeamCodeShow(source: MemberInviteSourceScenes) {
        Tracker.post(TeaEvent(Homeric.ADD_MEMBER_TEAM_CODE_SHOW, params: ["source": source.toString()]))
    }

    /// 团队码页面点击复制团队码
    /// source: 暂无业务描述
    static func trackAddMemberTeamCodeCopyClick(source: MemberInviteSourceScenes) {
        Tracker.post(TeaEvent(Homeric.ADD_MEMBER_TEAM_CODE_COPY_CLICK, params: ["source": source.toString()]))
    }

    /// 团队码页面点击分享团队码
    /// source: 暂无业务描述
    static func trackAddMemberTeamCodeShareClick(source: MemberInviteSourceScenes, method: String) {
        Tracker.post(TeaEvent(Homeric.ADD_MEMBER_TEAM_CODE_SHARE_CLICK, params: ["source": source.toString(), "method": method]))
    }

    /// 团队码页面点击查看使用说明
    /// source: 暂无业务描述
    static func trackAddMemberTeamCodeManualClick(source: MemberInviteSourceScenes) {
        Tracker.post(TeaEvent(Homeric.ADD_MEMBER_TEAM_CODE_MANUAL_CLICK, params: ["source": source.toString()]))
    }

    /// 新用户引导_添加成员页面展示
    static func trackOnboardingGuideAddmemberShow() {
        Tracker.post(TeaEvent(Homeric.ONBOARDING_GUIDE_ADDMEMBER_SHOW))
    }

    /// 新用户引导_添加成员页面点击保存
    static func trackOnboardingGuideAddmemberSave() {
        Tracker.post(TeaEvent(Homeric.ONBOARDING_GUIDE_ADDMEMBER_SAVE))
    }

    /// 新用户引导_添加成员页面点击分享
    static func trackOnboardingGuideAddmemberShare() {
        Tracker.post(TeaEvent(Homeric.ONBOARDING_GUIDE_ADDMEMBER_SHARE))
    }

    /// 新用户引导_添加成员页面邀请更多
    static func trackOnboardingGuideAddmemberInviteMore() {
        Tracker.post(TeaEvent(Homeric.ONBOARDING_GUIDE_ADDMEMBER_INVITEMORE))
    }

    /// 新用户引导_添加成员页面分享成功点击下一步
    static func trackOnboardingGuideAddmemberInviteNext() {
        Tracker.post(TeaEvent(Homeric.ONBOARDING_GUIDE_ADDMEMBER_NEXT))
    }

    /// 联系人入口展示  0：无奖  1：有奖
    static func trackReferContactView(rewardNewTenant: Int) {
        Tracker.post(TeaEvent(Homeric.REFER_TENANT_CONTACT_VIEW, params: ["reward_new_tenant": rewardNewTenant]))
    }

    /// 联系人入口点击  0：无奖  1：有奖
    static func trackReferContactClick(rewardNewTenant: Int) {
        Tracker.post(TeaEvent(Homeric.REFER_TENANT_CONTACT_CLICK, params: ["reward_new_tenant": rewardNewTenant]))
    }

    /// 统一邀请分流页展示 0：无奖  1：有奖
    static func trackInvitePeopleMemberCTAView(rewardNewTenant: Int) {
        Tracker.post(TeaEvent(Homeric.INVITE_PEOPLE_MEMBER_CTA_VIEW, params: ["reward_new_tenant": rewardNewTenant]))
    }

    /// 统一邀请分流页点击 0：无奖  1：有奖
    static func trackInvitePeopleMemberCTAClick(rewardNewTenant: Int) {
        Tracker.post(TeaEvent(Homeric.INVITE_PEOPLE_MEMBER_CTA_CLICK, params: ["reward_new_tenant": rewardNewTenant]))
    }

    /// 团队码分享 - 分享面板微信按钮点击
    static func trackJoinTeamWechatClick() {
        Tracker.post(TeaEvent(Homeric.JOINTEAM_WECHATE_CLICK, params: [:]))
    }

    /// 通讯录 - 发送按钮点击
    static func trackMembersBatchSendClick() {
        Tracker.post(TeaEvent(Homeric.MEMBERSBATCH_SEND_CLICK, params: [:]))
    }

    /// 通讯录 - 选中某条联系方式
    static func trackMembersBatchChooseClick() {
        Tracker.post(TeaEvent(Homeric.MEMBERSBATCH_CHOOSE_CLICK, params: [:]))
    }

    /// 取消选中某条联系方式
    static func trackMembersBatchChooseClickCancel() {
        Tracker.post(TeaEvent(Homeric.MEMBERSBATCH_CHOOSE_CLICK_CANCEL, params: [:]))
    }

    /// 格式校验弹窗的展示
    static func trackMembersBatchFormatFeedbackDialogShow() {
        Tracker.post(TeaEvent(Homeric.MEMBERSBATCH_FORMAT_FEEDBACK_DIALOG_SHOW, params: [:]))
    }

    /// 格式校验弹窗继续按钮点击
    static func trackMembersBatchFormatDialogContinueClick() {
        Tracker.post(TeaEvent(Homeric.MEMBERSBATCH_FORMAT_DIALOG_CONTINUE_CLICK, params: [:]))
    }

    /// 格式校验弹窗取消按钮点击
    static func trackMembersBatchFormatDialogCancelClick() {
        Tracker.post(TeaEvent(Homeric.MEMBERSBATCH_FORMAT_DIALOG_CANCEL_CLICK, params: [:]))
    }

    /// 发送结果反馈弹窗展示
    static func trackMembersBatchFeedbackDialogShow(result: String) {
        Tracker.post(TeaEvent(Homeric.MEMBERSBATCH_FEEDBACK_DIALOG_SHOW, params: ["result": result]))
    }

    /// 发送结果确认按钮点击
    static func trackMembersBatchFeedbackDialogConfirmClick() {
        Tracker.post(TeaEvent(Homeric.MEMBERSBATCH_FEEDBACK_DIALOG_CONFIRM_CLICK, params: [:]))
    }

    /// 邀请成员点击“从通讯录导入”
    static func trackAddMemberContactBatchInviteClick(scenes: ImportMemberScenes) {
        Tracker.post(TeaEvent(Homeric.ADD_MEMBER_CONTACTBATCH_INVITE_CLICK, params: ["scenes": scenes.rawValue]))
    }

    /// 分享加好友 H5 链接
    static func trackInvitePeopleH5Share(method: ShareMethod,
                                         channel: ShareChannel,
                                         uniqueId: String,
                                         type: ShareType) {
        Tracker.post(TeaEvent(Homeric.INVITE_PEOPLE_H5_SHARE, params: ["method": method.rawValue,
                                                                       "channel": channel.rawValue,
                                                                       "unique_id": uniqueId,
                                                                       "type": type.rawValue,
                                                                       "platform": "ios"]))
    }

    // 点击成员邀请分流页右上角帮助
    static func trackAddMemmberHelpClick(source: MemberInviteSourceScenes) {
        Tracker.post(TeaEvent(Homeric.ADD_MEMBER_HELP_CLICK, params: ["source": source.toString()]))
    }

    // 个人升级团队引导，用户可以跳过
    static func trackAddMemberSkip(source: MemberInviteSourceScenes) {
        Tracker.post(TeaEvent(Homeric.ADD_MEMBER_SKIP, params: ["source": source.toString()]))
    }
}

// MARK: - Edu Tea
extension Tracer {
    enum EduInviteChannel: Int {
        case wechat = 1
        case qrcode = 2
        case link = 3
        case inapp = 4
    }
    enum EduNoDirectionalType: Int {
        case qrcode = 1
        case link = 2
    }
    enum EduCTAButtonType: Int {
        case other = 1
        case share = 2
    }

    // “邀请家长”页点击：未激活家长
    static func trackEduDidClickInactiveParentEntry() {
        Tracker.post(TeaEvent(Homeric.CORE_CONTACT_HOME_SCHOOL_CONTACT_INACTIVATED_CLICK, params: [:]))
    }

    // 点击邀请更多家长的不同类型
    static func trackEduInviteInactiveParent(by inviteChannel: EduInviteChannel) {
        Tracker.post(TeaEvent(Homeric.CORE_CONTACT_HOME_SCHOOL_CONTACT_INVITE_MORE_PARENTS_CLICK, params: ["invite_type": inviteChannel.rawValue]))
    }

    // 二维码/链接邀请页点击复制分享、保存分享
    static func trackEduClickCTA(by type: EduNoDirectionalType, and ctaButtonType: EduCTAButtonType) {
        Tracker.post(TeaEvent(Homeric.CORE_CONTACT_HOME_SCHOOL_CONTACT_QR_LINK_INVITE, params: ["invite_source": type.rawValue, "b_name": ctaButtonType.rawValue]))
    }

    // B2B 关联组织 - 进入邀请页
    static func trackBindInviteStart(source: AssociationInviteSource, isAdmin: Bool) {
        Tracker.post(TeaEvent("im_bind_invite_start", params: ["source": source.rawValue, "usertype": isAdmin ? "admin" : "member"]))
    }

    // B2B 关联组织 - 分享转发，打开最近会话页
    static func trackMessageForwardSingleClick() {
        Tracker.post(TeaEvent("message_forward_single_click", params: ["from_source": "bind_invite"]))
    }

    // B2B 关联组织 - 点击确认转发
    static func trackBindInviteComfirmTransmitClick() {
        Tracker.post(TeaEvent("bind_invite_comfirm_transmit_click", params: [:]))
    }
}

// MARK: - Profile改造打点
extension Tracer {
    /// 查看Profile页时，所返回部门字段值超过多少字符
    static func trackDepartmentTotalChart(number: Int) {
        Tracker.post(TeaEvent(Homeric.PROFILE_DETAIL_DEPARTMENTS_TOOLONG_TOTAL, params: ["char_length": number]))
    }

    /// 点击“⌄”展开查看完整部门名
    static func trackDepartmentShowMore(click: String, charLength: Int, rowNumbers: Int) {
        Tracker.post(TeaEvent(Homeric.PROFILE_DETAIL_DEPARTMENT_NAME_SHOW_MORE, params: ["click_area": click,
                                                                                         "department_char_length": charLength,
                                                                                         "char_overflow_row_numbers": rowNumbers]))
    }

    /// 在Profile页内点击“查看更多”按钮
    static func trackDepartmentMoreClick() {
        Tracker.post(TeaEvent(Homeric.PROFILE_DETAIL_MORE_CLICK, params: [:]))
    }

    /// 用户点击扫一扫
    static func trackScan(source: String) {
        Tracker.post(TeaEvent(Homeric.SCAN_QRCODE_CONTACTS, params: ["origination": "invite_external_contacts_scan",
                                                                     "source": source
        ]))
    }

    /// 用户点击邀请隐私设置
    static func trackEnterPrivacySetting(from: String) {
        Tracker.post(TeaEvent(Homeric.VISITED_PRIVACY_SETTING, params: ["origination": from]))
    }

    /// 用户跳转到「邀请外部联系人」页
    static func trackExternalInvite(_ from: String) {
        Tracker.post(TeaEvent(Homeric.INVITE_EXTERNAL_CONTACTS_ATTEMPT, params: ["origination": from]))
    }

    // 用户点击头像的次数
    static func trackPicture() {
        Tracker.post(TeaEvent(Homeric.PROFILE_PICTURE, params: [:]))
    }

    // 移动端profile右上角三个点
    static func trackThreepoints() {
        Tracker.post(TeaEvent(Homeric.PROFILE_THREEPOINTS, params: [:]))
    }

    // 用户在CTA点击离职用户的查看历史消息的次数
    static func trackViewHistoryChat() {
        Tracker.post(TeaEvent(Homeric.PROFILE_VIEWHISTORYCHAT, params: [:]))
    }

    // 在Profile页点击手机号字段区域
    static func trackPhoneAreaClick() {
        Tracker.post(TeaEvent(Homeric.PROFILE_PHONE_AREA, params: [:]))
    }

    // 在Profile页手机号字段区域点击"显示"
    static func trackPhoneShowButtonClick() {
        Tracker.post(TeaEvent(Homeric.PROFILE_PHONE_SHOW, params: [:]))
    }

    // 在Profile页点击手机号区域出现的弹窗的"拨打"
    static func trackPhoneAreaActionSureCallClick() {
        Tracker.post(TeaEvent(Homeric.PROFILE_PHONE_ACTION_CALL, params: [:]))
    }

    // 单向好友-点击Profile页底部添加联系人
    static func trackAddContactInProfile() {
        Tracker.post(TeaEvent(Homeric.PROFILE_ADD_EXTERNALCONTACTS_CLICK, params: [:]))
    }

    // profile页资料设置-点击确定删除联系人
    static func trackDeleteContactInProfileSetting() {
        Tracker.post(TeaEvent(Homeric.PROFILE_DELETE_EXTERNALCONTACTS_CLICK, params: [:]))
    }

    // profile页资料设置-点击举报
    static func trackReportInProfileSetting() {
        Tracker.post(TeaEvent(Homeric.PROFILE_REPORT_CLICK, params: [:]))
    }

    static private func convertSouceTypeToStr(sourceType: RustPB.Basic_V1_ContactSource) -> String {
        var sourceStr = "others"
        if sourceType == .chat {
            sourceStr = "chat"
        } else if sourceType == .vc {
            sourceStr = "vc"
        } else if sourceType == .docs {
            sourceStr = "docs"
        } else if sourceType == .email {
            sourceStr = "email"
        } else if sourceType == .calendar {
            sourceStr = "event"
        } else if sourceType == .link {
            sourceStr = "link"
        } else if sourceType == .nameCard {
            sourceStr = "namecard"
        } else if sourceType == .searchPhone {
            sourceStr = "search_phone"
        } else if sourceType == .searchEmail {
            sourceStr = "search_email"
        } else if sourceType == .searchContact {
            sourceStr = "contacts"
        } else if sourceType == .community {
            sourceStr = "community"
        } else if sourceType == .contactcards {
            sourceStr = "contactcards"
        }
        return sourceStr
    }

}

// MARK: - 新版Profile埋点
extension Tracer {

    /// Profile 页头像图片的点击次数
    static func tarckProfileAvatarTap() {
        Tracker.post(TeaEvent(Homeric.PROFILE_PICTURE, params: [:]))
    }

    /// 通过 profile 页添加好友
    static func tarckProfileAddFriend(sourceType: RustPB.Basic_V1_ContactSource, userID: String) {
        let source = self.convertSouceTypeToStr(sourceType: sourceType)
        Tracker.post(TeaEvent(Homeric.PROFILE_ADD, params: ["source": source,
                                                            "to_user_id": userID]))
    }

    /// 统计在 profile 页面内同意好友申请的情况
    static func trackAcceptFriendRequest(isAuth: Bool, hasAuth: Bool) {
        Tracker.post(
            TeaEvent(
                Homeric.PROFILE_AGREE_FRIEND_REQUEST,
                params: ["verification": hasAuth,
                         "is_verified": isAuth])
        )

    }

    /// 统计 profile 内 cta 按钮被点击的次数
    static func tarckProfileCTATap(type: String) {
        Tracker.post(TeaEvent(Homeric.PROFILE_CTA_CLICK, params: ["type": type]))
    }

    /// 统计 profile 内各个入口被点击的次数
    static func tarckProfileFieldTap(type: String) {
        Tracker.post(TeaEvent(Homeric.PROFILE_ENTRY_CLICK, params: ["type": type]))
    }

    /// 统计“点点点 ”按钮的点击情况
    static func tarckProfileMoreTap() {
        Tracker.post(TeaEvent(Homeric.PROFILE_MORE_CLICK, params: [:]))
    }

    /// 统计“点点点”里隐藏按钮的点击情况
    static func tarckProfileMoreButtonTap(type: String) {
        Tracker.post(TeaEvent(Homeric.PROFILE_MORE_BTN_CLICK, params: ["type": type]))
    }

    /// Profile 备注功能的使用情况
    static func tarckProfileAliasTap() {
        Tracker.post(TeaEvent(Homeric.PROFILE_EDIT_ALIAS, params: [:]))
    }
}

// MARK: - 小组
extension Tracer {
    enum CreateFrom: String {
        case chat
        case community
    }

    /// 创建小组
    static func trackCreateChannel(from: CreateFrom) {
        Tracker.post(
            TeaEvent(
                Homeric.CONNECT_CREATE_CHANNEL,
                params: ["source": from.rawValue]
            )
        )
    }
}

// MARK: - 面对面建群
extension Tracer {
    /// 创建群组页面进入
    static func faceToFaceCreateChat() {
        Tracker.post(TeaEvent(Homeric.FACE_TO_FACE_CREATE_GROUP_CHAT, params: [:]))
    }
    /// 创建群组页面进入后加群
    static func faceToFaceEnterChat() {
        Tracker.post(TeaEvent(Homeric.FACE_TO_FACE_ENTER_GROUP_CHAT, params: [:]))
    }
    /// 外部联系人页面进入
    static func contactFaceToFaceCreateChat() {
        Tracker.post(TeaEvent(Homeric.CONTACT_FACE_TO_FACE_CREATE_GROUP_CHAT, params: [:]))
    }
    /// 外部联系人页面进入后加群
    static func contactFaceToFaceEnterChat() {
        Tracker.post(TeaEvent(Homeric.CONTACT_FACE_TO_FACE_ENTER_GROUP_CHAT, params: [:]))
    }
    /// 通过面对面建群成功创建新群聊
    static func faceToFaceNewCreateChat(chatId: String) {
        Tracker.post(TeaEvent(Homeric.FACE_TO_FACE_GROUP_CHAT_NEW_CREATED,
                              params: ["face_to_face_group_id": chatId]))
    }
}

// MARK: - 通讯录-组织架构
extension Tracer {
    /// 组织架构页面-浏览
    static func contactOrganizationView() {
        Tracker.post(TeaEvent(Homeric.CONTACT_ORGANIZATION_VIEW, params: [:]))
    }
    /// 组织架构页面-点击
    static func contactOrganizationClick(departmentLevel: Int, departmentID: String, userID: String) {
        Tracker.post(TeaEvent(Homeric.CONTACT_ORGANIZATION_CLICK,
                              params: ["level": departmentLevel,
                                       "department_id": departmentID,
                                       "user_id": userID],
                              md5AllowList: ["department_id", "user_id"]))
    }
    /// 联系人点击面包屑按钮
    static func contactOrganizationBreadcrumbsClick() {
        Tracker.post(TeaEvent(Homeric.CONTACT_ORGANIZATION_BREADCRUMBS_CLICK, params: [:]))
    }
    /// 点击更多部门按钮
    static func contactOrganizationMoreDepartmentsClick() {
        Tracker.post(TeaEvent(Homeric.CONTACT_ORGANIZATION_MORE_CLICK, params: [:]))
    }
    /// 点击企业管理页面
    static func contactOrganizationManagementClick(source: String) {
        Tracker.post(TeaEvent(Homeric.MADMIN_PV, params: ["source": source]))
    }
    /// 点击通讯录首页外漏部门
    static func contactOrganizationHomeDepartmentsClick() {
        Tracker.post(TeaEvent(Homeric.CONTACT_ORGANIZATION_HOME_CLICK, params: [:]))
    }
    /// 组织架构页面点击部门管理
    static func contactArchitectureClick(click: String, target: String) {
        Tracker.post(TeaEvent(Homeric.IM_CONTACT_ARCHITECTURE_CLICK,
                              params: ["click": click,
                                       "target": target]))
    }
}

// MARK: - 单向联系人
extension Tracer {
    static private func applyCollaborationSceneStr(_ source: AddContactApplicationSource?) -> String {
        var resultStr = ""
        guard let source = source else {
            return resultStr
        }
        switch source {
        case .urgent:
            resultStr = "Buzz"
        case .videoCall:
            resultStr = "VC"
        case .calendar:
            resultStr = "calendar"
        case .groupAddMember:
            resultStr = "add_member"
        case .createGroup:
            resultStr = "new_group"
        case .voiceCall:
            resultStr = "voice_call"
        case .phoneCall:
            resultStr = "phonecall"
        case .profileCall:
            resultStr = "profile_call"
        default:
            return resultStr
        }
        return resultStr
    }

    /// 展示引导授权弹窗
    static func trackShowApplyCollaborationAlert(
        source: AddContactApplicationSource?,
        number: Int
    ) {
        Tracker.post(
            TeaEvent(
                Homeric.GUIDE_AUTHORIZE_COLLABORATION_WINDOW,
                params: ["source": applyCollaborationSceneStr(source), "default_number": number]
            )
        )
    }

    /// 发送好友申请
    static func trackBusinessToAddContactSend(
        type: AddContactBusinessType,
        toUserIds: [String]
    ) {
        Tracker.post(
            TeaEvent(
                Homeric.AUTHORIZE_COLLABORATION_REQUEST,
                params: ["scene": type.rawValue,
                         "to_user_ids": toUserIds],
                md5AllowList: ["to_user_ids"]
            )
        )
    }

    static func trackProfileAddSourceType(_ sourceType: RustPB.Basic_V1_ContactSource,
                                          userID: String?,
                                          token: String?,
                                          isAuth: Bool?,
                                          hasAuth: Bool?) {
        var value = ""
        if let userID = userID {
            value = userID
        } else if let token = token {
            value = token
        }

        Tracker.post(
            TeaEvent(
                Homeric.PROFILE_ADD,
                params: ["source": self.convertSouceTypeToStr(sourceType: sourceType),
                         "to_user_id": value,
                         "is_verified": isAuth ?? false,
                         "verification": hasAuth ?? false],
                md5AllowList: ["to_user_id"]
            )
        )
    }

    // MARK: Onboarding 推荐联系人

    /// Onboarding阶段点击邀请通讯录加入飞书按钮
    static func trackOnboardingSystemInvite() {
        Tracker.post(TeaEvent(Homeric.ONBOARDING_SYSTEM_INVITE, params: ["category": "Contact"]))
    }
    /// Onboarding阶段打开添加联系人的引导页面
    static func trackOnbardingAddContactShow() {
        Tracker.post(TeaEvent(Homeric.ONBOARDING_ADDCONTACT_SHOW, params: ["category": "Contact"]))
    }
    /// 在添加联系人的引导页面点击跳过
    static func trackOnbardingAddContactSkip() {
        Tracker.post(TeaEvent(Homeric.ONBOARDING_ADDCONTACT_SKIP, params: ["category": "Contact"]))
    }
    /// 在添加联系人的引导页面点击确定
    static func trackOnbardingAddContactConfirm() {
        Tracker.post(TeaEvent(Homeric.ONBOARDING_ADDCONTACT_CONFIRM, params: ["category": "Contact"]))
    }
    /// Onboarding 推荐联系人流程中，获取推荐用户数量
    static func trackOnbardingFetchRecUserCount(count: Int) {
        Tracker.post(SlardarEvent(name: Homeric.CONTACT_OPT_ONBOARDING_FETCH_REC_USER_COUNT, metric: ["count": count], category: [:], extra: [:]))
    }
    /// Onboarding 推荐联系人流程中，上报前用户实际勾选的推荐人数量
    static func trackOnbardingCNUploadUserCount(count: Int) {
        Tracker.post(SlardarEvent(name: Homeric.ONEWAY_CONTACT_ONBOARDING_CN_UPLOAD_USER_COUNT, metric: ["count": count], category: [:], extra: [:]))
    }
    /// Onboarding 推荐联系人流程中，用户勾选完推荐人， 发起 request
    static func trackStartOnbardingCNUploadTimingMs() {
        ClientPerf.shared.startSlardarEvent(service: Homeric.CONTACT_OPT_ONBOARDING_FETCH_REC_USER_TIMING_MS)
    }
    /// Onboarding 推荐联系人流程中，用户勾选完推荐人， 到页面渲染结束的
    static func trackEndOnbardingCNUploadTimingMs() {
        ClientPerf.shared.endSlardarEvent(service: Homeric.CONTACT_OPT_ONBOARDING_FETCH_REC_USER_TIMING_MS)
    }
    /// Onboarding 推荐联系人流程中，用户勾选并点击添加推荐人，返回 success
    static func trackOnbardingCNUploadSuccess() {
        Tracker.post(SlardarEvent(name: Homeric.ONEWAY_CONTACT_ONBOARDING_CN_UPLOAD_SUCCESS, metric: [:], category: [:], extra: [:]))
    }
    /// Onboarding 推荐联系人流程中，获取推荐用户失败
    static func trackOnbardingCNUploadFail(errorCode: Int32, errorMsg: String) {
        Tracker.post(SlardarEvent(name: Homeric.CONTACT_OPT_ONBOARDING_FETCH_REC_USER_ERROR, metric: [:], category: ["errorCode": errorCode], extra: ["error": errorMsg]))
        AppReciableSDK.shared.error(params: ErrorParams(biz: .UserGrowth,
                                                        scene: .OnBoarding,
                                                        event: .contactOptLocalFetch,
                                                        errorType: .Other,
                                                        errorLevel: .Fatal,
                                                        errorCode: Int(errorCode),
                                                        userAction: nil,
                                                        page: nil,
                                                        errorMessage: errorMsg))
    }
    // Onboarding 获取推荐用户Start
    static func trackOnbardingFetchRecUserStart() -> DisposedKey {
        return AppReciableSDK.shared.start(biz: .UserGrowth,
                                           scene: .OnBoarding,
                                           event: .contactOptLocalFetch,
                                           page: nil)
    }
    // Onboarding 获取推荐用户End
    static func trackOnbardingFetchRecUserEnd(disposeKey: DisposedKey) {
        AppReciableSDK.shared.end(key: disposeKey)
    }

    // MARK: 定时上报本地通讯录 cps

    /// 同一user下距离上一次上报的时间间隔 (min)
    static func trackUploadIntervalMin(intervalMin: Int) {
        Tracker.post(SlardarEvent(name: Homeric.ONEWAY_CONTACT_UPLOAD_INTERVAL_MIN,
                                  metric: ["intervalMin": intervalMin], category: [:], extra: [:]))
    }

    // MARK: 通讯录列表(仅 mobile)

    /// 读取到的 cp 数量 (email + phonenumber)，在所有校验、过滤、限制后的数量
    static func trackFetchCPTotalCountHandled(count: Int) {
        Tracker.post(SlardarEvent(name: Homeric.ONEWAY_CONTACT_CP_AVAILABLE_TOTAL_COUNT,
                                  metric: [:], category: ["count": count], extra: [:]))
    }
    /// 读取到的 email 数量，在所有校验、过滤、限制后的数量
    static func trackFetchEmailCountHandled(count: Int) {
        Tracker.post(SlardarEvent(name: Homeric.ONEWAY_CONTACT_CP_AVAILABLE_EMAIL_COUNT,
                                  metric: [:], category: ["count": count], extra: [:]))
    }
    /// 读取到的 phonenumber 数量，在所有校验、过滤、限制后的数量
    static func trackFetchPhoneCountHandled(count: Int) {
        Tracker.post(SlardarEvent(name: Homeric.ONEWAY_CONTACT_CP_AVAILABLE_PHONE_COUNT,
                                  metric: [:], category: ["count": count], extra: [:]))
    }
    /// 拉取通讯录列表，返回 failure，带上 errorMsg
    static func trackFetchContactListFail(errorCode: Int32, errorMsg: String) {
        Tracker.post(SlardarEvent(name: Homeric.CONTACT_OPT_CONTACT_LIST_FETCH_FAIL,
                                  metric: [:], category: ["errorCode": errorCode], extra: ["error": errorMsg]))
    }
    /// 从发起 request time cost (ms)
    static func trackStartContactListFetchTimingMs() {
        ClientPerf.shared.startSlardarEvent(service: Homeric.CONTACT_OPT_CONTACT_LIST_TIMING_MS)
    }
    /// 页面渲染完毕的 time cost (ms)
    static func trackEndContactListFetchTimingMs(availableCpCount: Int, availableUserCount: Int) {
        ClientPerf.shared.endSlardarEvent(service: Homeric.CONTACT_OPT_CONTACT_LIST_TIMING_MS,
                                          params: ["availableCpCount": "\(availableCpCount)",
                                            "availableUserCount": "\(availableUserCount)"])
    }
    /// 从添加手机联系人进入通讯录页面
    static func trackAddressbookEnter() {
        Tracker.post(TeaEvent(Homeric.ADDRESSBOOK_ENTER, params: ["category": "Contact"]))
    }
    /// 通讯录-点击正在使用飞书tab
    static func trackAddressbookUsingClick() {
        Tracker.post(TeaEvent(Homeric.ADDRESSBOOK_USINGLARK_CLICK, params: ["category": "Contact"]))
    }
    /// 通讯录-点击邀请使用飞书tab
    static func trackAddressbookUnusingClick() {
        Tracker.post(TeaEvent(Homeric.ADDRESSBOOK_UNUSINGLARK_CLICK, params: ["category": "Contact"]))
    }
    /// 通讯录-点击搜索
    static func trackAddressbookSearchClick() {
        Tracker.post(TeaEvent(Homeric.ADDRESSBOOK_SEARCH_CLICK, params: ["category": "Contact"]))
    }
    /// 通讯录-点击正在使用飞书tab-点击添加
    static func trackAddressbookAdd() {
        Tracker.post(TeaEvent(Homeric.ADDRESSBOOK_USINGLARK_ADD_CLICK, params: ["category": "Contact"]))
    }
    /// 通讯录-点击正在使用飞书tab-点击邀请
    static func trackAddressbookInvite() {
        Tracker.post(TeaEvent(Homeric.ADDRESSBOOK_USINGLARK_INVITE_CLICK, params: ["category": "Contact"]))
    }
    /// 通讯录页面，用户未授权通讯录时，在顶部展示引导打开通讯刘的Banner
    static func trackAddressbookBannerShow() {
        Tracker.post(TeaEvent(Homeric.ADDRESS_GUIDE_BANNER_SHOW, params: ["category": "Contact"]))
    }
    /// 通讯录页面，用户未授权通讯录时，在顶部点击引导打开通讯刘的Banner
    static func trackAddressbookBannerClick() {
        Tracker.post(TeaEvent(Homeric.ADDRESS_GUIDE_BANNER_CLICK, params: ["category": "Contact"]))
    }

    // MARK: 新的联系人(仅 mobile)

    /// 联系人tab-新的联系人有badge展示
    static func trackNewContactBadgeShow() {
        Tracker.post(TeaEvent(Homeric.CONTACT_NEWCONTACT_BADGE_SHOW, params: ["category": "Contact"]))
    }
    /// 联系人tab-点击有badge展示的"新的联系人"
    static func trackNewContactBadgeShowClick() {
        Tracker.post(TeaEvent(Homeric.CONTACT_NEWCONTACT_BADGE_SHOW_CLICK, params: ["category": "Contact"]))
    }
    /// 新的联系人-点击添加按钮
    static func trackNewContactAddClick() {
        Tracker.post(TeaEvent(Homeric.NEWCONTACT_ADD_CLICK, params: ["category": "Contact"]))
    }

    /// 新的联系人-拉取新的好友请求列表失败
    static func trackNewContactApplicationsFetchFail(errorCode: Int32, errorMsg: String) {
        Tracker.post(SlardarEvent(name: Homeric.CONTACT_OPT_CONTACT_APPLICATIONS_FETCH_FAIL,
                                  metric: [:], category: ["errorCode": errorCode], extra: ["error": errorMsg]))
    }

    /// 新的联系人-发起 request
    static func trackStartContactApplicationsTimingms() {
        ClientPerf.shared.startSlardarEvent(service: Homeric.CONTACT_OPT_CONTACT_APPLICATIONS_FETCH_TIMING_MS)
    }
    /// 新的联系人-页面渲染完毕
    static func trackEndContactApplicationsTimingms() {
        ClientPerf.shared.endSlardarEvent(service: Homeric.CONTACT_OPT_CONTACT_APPLICATIONS_FETCH_TIMING_MS)
    }

    /// 同意好友申请，返回 success
    static func trackContactApproveFriendSuccess() {
        Tracker.post(SlardarEvent(name: Homeric.CONTACT_OPT_APPROVE_FRIEND_REQUEST_SUCCESS,
                                  metric: [:], category: [:], extra: [:]))
    }
    /// 同意好友申请，返回 failure，带上 errorMsg
    static func trackContactApproveFriendFail(errorCode: Int32, errorMsg: String) {
        Tracker.post(SlardarEvent(name: Homeric.CONTACT_OPT_APPROVE_FRIEND_REQUEST_FAIL,
                                  metric: [:], category: ["errorCode": errorCode], extra: ["error": errorMsg]))
    }

    // MARK: 外部联系人

    /// 拉取新的联系人列表，返回 failure，带上 errorMsg
    static func trackFetchExternalFailed(errorCode: Int32, errorMsg: String) {
        Tracker.post(SlardarEvent(name: Homeric.CONTACT_OPT_EXTERNAL_FETCH_FAIL,
                                  metric: [:], category: ["errorCode": errorCode], extra: ["error": errorMsg]))
        AppReciableSDK.shared.error(params: ErrorParams(biz: .UserGrowth,
                                                        scene: .UGCenter,
                                                        event: .contactOptExternalFetch,
                                                        errorType: .Other,
                                                        errorLevel: .Exception,
                                                        errorCode: Int(errorCode),
                                                        userAction: nil,
                                                        page: nil,
                                                        errorMessage: errorMsg))
    }
    /// 从发起 request time cost (ms)
    static func trackStartExternalFetchTimingMs() {
        ClientPerf.shared.startSlardarEvent(service: Homeric.CONTACT_OPT_EXTERNAL_FETCH_TIMING_MS)
    }
    /// 页面渲染完毕的 time cost (ms)
    static func trackEndExternalFetchTimingMs() {
        ClientPerf.shared.endSlardarEvent(service: Homeric.CONTACT_OPT_EXTERNAL_FETCH_TIMING_MS)
    }
    /// 获取外部联系人用户Start
    static func trackStartAppReciableExternalFetchTimingMs() -> DisposedKey {
        return AppReciableSDK.shared.start(biz: .UserGrowth,
                                           scene: .UGCenter,
                                           event: .contactOptExternalFetch,
                                           page: nil)
    }
    /// 获取外部联系人用户End
    static func trackEndAppReciableExternalFetchTimingMs(disposeKey: DisposedKey) {
        AppReciableSDK.shared.end(key: disposeKey)
    }
    /// 一次展示的所有 user 数量
    static func trackFetchExternalUserCount(count: Int) {
        Tracker.post(SlardarEvent(name: Homeric.CONTACT_OPT_EXTERNAL_USER_COUNT,
                                  metric: ["count": "\(count)"], category: [:], extra: [:]))
    }
    /// 用户删除外部联系人，返回 success
    static func trackDeleteExternalSuccess() {
        Tracker.post(SlardarEvent(name: Homeric.CONTACT_OPT_EXTERNAL_DELETE_SUCCESS,
                                  metric: [:], category: [:], extra: [:]))
    }
    /// 用户删除外部联系人，start
    static func trackStartAppReciableDeleteExternal() -> DisposedKey {
        return AppReciableSDK.shared.start(biz: .UserGrowth,
                                           scene: .UGCenter,
                                           event: .contactOptExternalDel,
                                           page: nil)
    }
    /// 用户删除外部联系人，end
    static func trackEndAppReciableDeleteExternal(disposeKey: DisposedKey) {
        AppReciableSDK.shared.end(key: disposeKey)
    }
    /// 用户删除外部联系人，返回 failure，带上 errorMsg
    static func trackDeleteExternalFailed(errorCode: Int32, errorMsg: String) {
        Tracker.post(SlardarEvent(name: Homeric.CONTACT_OPT_EXTERNAL_DELETE_FAIL,
                                  metric: [:], category: ["errorCode": errorCode], extra: ["error": errorMsg]))
        AppReciableSDK.shared.error(params: ErrorParams(biz: .UserGrowth,
                                                        scene: .UGCenter,
                                                        event: .contactOptExternalDel,
                                                        errorType: .Other,
                                                        errorLevel: .Fatal,
                                                        errorCode: Int(errorCode),
                                                        userAction: nil,
                                                        page: nil,
                                                        errorMessage: errorMsg))
    }

    /// 外部联系人页面-浏览次数
    static func trackExternalShow() {
        Tracker.post(SlardarEvent(name: Homeric.CONTACT_EXTERNAL_VIEW,
                                  metric: [:], category: [:], extra: [:]))
    }

    /// 外部联系人页面-点击字母定位按钮
    static func trackExternalLetterClick() {
        Tracker.post(SlardarEvent(name: Homeric.CONTACT_EXTERNAL_LETTER_CLICK,
                                  metric: [:], category: [:], extra: [:]))
    }

    /// 新的联系人页面-浏览
    static func trackContactNewContactShow() {
        Tracker.post(SlardarEvent(name: Homeric.CONTACT_NEWCONTACT_VIEW,
                                  metric: [:], category: [:], extra: [:]))
    }

    /// 新的联系人页面-点击同意按钮
    static func trackContactNewContactAgreeClick(userID: String) {
        Tracker.post(SlardarEvent(name: Homeric.CONTACT_NEWCONTACT_AGREE_CLICK,
                                  metric: [:], category: ["user_id": userID], extra: [:]))
    }

    /// 进入引导页面AB实验埋点
    static func trackOnboardingGuideABTest(isABTest: Bool, versionId: Int32) {
        Tracker.post(TeaEvent("onboarding_team_guide_ab_test_status_server",
                              params:
                                [
                                    "is_ab_test": isABTest ? "true" : "false",
                                    "ab_version_id": "\(versionId)"
                                ]))
    }

    /// 展示创建团队引导弹窗
    static func trackOnboardingTeamCreateGuideView() {
        Tracker.post(TeaEvent(Homeric.ONBOARDING_TEAM_CREATE_JOIN_GUIDE_VIEW))
    }

    /// 引导页面点击事件
    static func trackOnboardingTeamCreateGuideViewClick(clickEvent: String, target: String) {
        Tracker.post(TeaEvent(Homeric.ONBOARDING_TEAM_CREATE_JOIN_GUIDE_CLICK, params: ["click": clickEvent, "target": target]))
    }

    /// 引导跳过提示弹窗
    static func trackOnboardingTeamCreateGuideSkipView() {
        Tracker.post(TeaEvent(Homeric.ONBOARDING_TEAM_CREATE_JOIN_GUIDE_SKIP_VIEW))
    }

    /// 引导跳过提示弹窗点击事件
    static func trackOnboardingTeamCreateGuideSkipViewClick(clickEvent: String, target: String) {
        Tracker.post(TeaEvent(Homeric.ONBOARDING_TEAM_CREATE_JOIN_GUIDE_SKIP_CLICK, params: ["click": clickEvent, "target": target]))
    }

    /// 展示二维码引导邀请成员
    static func trackTeamQrcodeAddMemberGuideView() {
        Tracker.post(TeaEvent(Homeric.ONBOARDING_TEAM_ADDMEMBER_GUIDE_VIEW))
    }

    /// 二维码引导邀请成员点击
    static func trackTeamQrcodeAddMemberGuideViewClick(clickEvent: String, target: String) {
        Tracker.post(TeaEvent(Homeric.ONBOARDING_TEAM_ADDMEMBER_GUIDE_CLICK, params: ["click": clickEvent, "target": target]))
    }

    /// LDR 展示
    static func trackLDRGuideView(keys: [String]) {
        Tracker.post(TeaEvent(Homeric.ONBOARDING_OPERATING_ACTIVITIES_VIEW, params: ["key": keys]))
    }

    /// LDR 页面点击事件
    static func trackLDRGuideViewClick(clickEvent: String, keys: [String]) {
        Tracker.post(TeaEvent(Homeric.ONBOARDING_OPERATING_ACTIVITIES_CLICK,
                              params: ["click": clickEvent, "key": keys, "target": "none"]))
    }
}
