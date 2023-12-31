//
//  Tag.swift
//  LarkTag
//
//  Created by kongkaikai on 2018/12/4.
//

import Foundation
import UIKit
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignTag

public typealias TagInfo = (title: String?, image: UIImage?, style: Style)

public typealias Size = UDTag.Configuration.Size

private typealias I18n = BundleI18n.LarkTag

/// Tag
public struct Tag {
    public private(set) var title: String?
    public private(set) var image: UIImage?
    public private(set) var style: Style
    public private(set) var type: TagType
    public private(set) var size: Size = .mini

    /// 初始化方法，title & image 不可同时为空
    ///
    /// - Parameters:
    ///   - title: title
    ///   - image: image
    ///   - style: 样式
    ///   - type: Tag 类型
    public init(title: String?, image: UIImage? = nil, style: Style = .clear, type: TagType) {
        assert(title != nil || image != nil, "title && image 不能同时为nil")

        self.title = title
        self.image = image
        self.style = style
        self.type = type
    }
    /// 新增含有size属性的初始化方法
    public init(title: String?, image: UIImage? = nil, style: Style = .clear, type: TagType, size: Size) {
        assert(title != nil || image != nil, "title && image 不能同时为nil")

        self.title = title
        self.image = image
        self.style = style
        self.type = type
        self.size = size
    }

    /// 便捷初始化方法，使用 TagType， Style，其余使用默认值
    ///
    /// - Parameters:
    ///   - type: TagType
    ///   - style: Style?
    @inlinable
    public init(type: TagType, style: Style? = nil) {
        let info = Tag.defaultTagInfo(for: type)
        self.init(title: info.title, image: info.image, style: style ?? info.style, type: type)
    }
    /// 新增含有size属性的便捷初始化方法
    @inlinable
    public init(type: TagType, style: Style? = nil, size: Size) {
        let info = Tag.defaultTagInfo(for: type)
        self.init(title: info.title, image: info.image, style: style ?? info.style, type: type, size: size)
    }

    // swiftlint:disable cyclomatic_complexity function_body_length
    public static func defaultTagInfo(for type: TagType) -> TagInfo {
        switch type {
        case .team:
            return (I18n.Lark_Status_TeamTag, nil, .blue)

        case .isPrivateMode:
            return (nil,
                    UDIcon.getIconByKey(
                        .safeFilled,
                        iconColor: UIColor.ud.udtokenTagNeutralTextNormal,
                        size: CGSize(width: 12, height: 12)
                    ),
                    Style(textColor: UIColor.clear,
                          backColor: UIColor.ud.udtokenTagNeutralBgNormal & UIColor.ud.udtokenTagNeutralBgSolid))

        case .allStaff:
            return (I18n.Lark_Status_AllStaffTag, nil, .blue)

        case .groupOwner:
            return (I18n.Lark_Status_AdminTag, nil, .blue)

        case .groupAdmin:
            return (I18n.Lark_Group_GroupAdministratorLabel, nil, .adminColor)

        case .tenantSuperAdmin:
            return (I18n.Lark_Core_SuperAdministratorLable, nil, .purple)

        case .tenantAdmin:
            return (I18n.Lark_Core_RegularAdministratorLable, nil, .blue)

        case .enterpriseSupervisor:
            return (I18n.Lark_Status_OrganizationSupervisor, nil, .blue)

        case .mainSupervisor:
            return (I18n.Lark_Status_SupervisorMain, nil, .blue)

        case .supervisor:
            return (I18n.Lark_Status_SupervisorTag, nil, .blue)

        case .external:
            return (I18n.Lark_Status_ExternalTag, nil, .blue)

        case .connect:
            return (I18n.Lark_Group_ConnectGroupLabel, nil, .blue)

        case .doNotDisturb:
            return (nil, BundleResources.LarkTag.do_not_disturb, .clear)

        case .cryptoDoNotDisturb:
            return (nil,
                    UDIcon.getIconByKey(
                        .alertsOffFilled,
                        iconColor: UIColor.ud.staticBlack.withAlphaComponent(0.7),
                        size: CGSize(width: 12, height: 12)
                    ),
                    .clear)

        case .newVersion:
            return (nil, Resources.LarkTag.newVersion, .clear)

        case .onLeave:
            return (I18n.Lark_Status_OnLeaveTag, nil, .red)

        case .deactivated:
            return (I18n.Lark_Status_DeactivatedTag, nil, .darkGrey)

        case .unread:
            return (I18n.Lark_Status_TagUnread, nil, .unreadColor)

        case .unregistered:
            return (I18n.Lark_Status_TagUnregistered, nil, .lightGrey)

        case .crypto:
            return (nil, BundleResources.LarkTag.crypto, .clear)

        case .secretCrypto:
            return (nil,
                    UDIcon.getIconByKey(
                        .lockChatFilled,
                        iconColor: UIColor.ud.staticBlack.withAlphaComponent(0.7),
                        size: CGSize(width: 12, height: 12)
                    ),
                    .clear)

        case .teamSecretGroup:
            return (nil,
                    UDIcon.getIconByKey(
                        .lockOutlined,
                        iconColor: UIColor.ud.iconN2,
                        size: CGSize(width: 14, height: 14)
                    ),
                    .clear)

        case .app:
            return (I18n.Lark_Search_AppLabel, nil, .blue)

        case .robot:
            return (I18n.Lark_Status_BotTag, nil, .yellow)

        case .thread:
            return (nil, BundleResources.LarkTag.thread, .clear)

        case .read:
            return (I18n.Lark_Legacy_ReadStatus, nil, .readColor)

        case .public:
            return (I18n.Lark_Group_CreateGroup_TypeSwitch_Public, nil, .blue)

        case .officialOncall:
            return (I18n.Lark_Chat_OfficialTag, nil, .blue)

        case .oncallUser:
            return (I18n.Lark_HelpDesk_UserIcon, nil, .blue)

        case .oncallAgent:
            return (I18n.Lark_HelpDesk_AgentIcon, nil, .red)

        case .oncall:
            return (nil, BundleResources.LarkTag.service, .clear)

        case .oncallOffline:
            return (nil, BundleResources.LarkTag.oncall_offline, .clear)

        case .shareDeactivated:
            return (I18n.Lark_Group_InvitationDeactivated, nil, .darkGrey)

        case .calendarOrganizer:
            return (I18n.Lark_Legacy_TagCalendarOrganizer, nil, .blue)

        case .calendarCreator:
            return (I18n.Lark_Legacy_TagCalendarCreator, nil, .blue)

        case .calendarExternalGrey:
            return (I18n.Lark_Legacy_TagExternal, nil, .white)

        case .calendarNotAttend:
            return (I18n.Lark_Legacy_TagCalendarNotAttend, nil, .lightGrey)

        case .calendarOptionalAttend:
            return (I18n.Lark_Legacy_TagCalendarOptionalAttend, nil, .lightGrey)

        case .calendarConflict:
            return (I18n.Lark_Legacy_TagCalendarConfliect, nil, .red)

        case .calendarConflictInMonth:
            return (I18n.Lark_Legacy_TagCalendarConfliectInMonth, nil, .red)

        case .calendarCurrentLocation:
            return (I18n.Lark_Legacy_TagCalendarCurrentLocation, nil, .blue)

        case .teamOwner:
            return (I18n.Project_T_AllMembersRightHere, nil, .blue)

        case .teamAdmin:
            return (I18n.Project_T_AdministratorRoleHere, nil, .orange)

        case .teamMember:
            return (I18n.Project_T_MembersRole, nil, .red)

        case .specialFocus:
            return (nil, BundleResources.LarkTag.special_focus_icon, .clear)
        case .isFrozen:
            return (I18n.Lark_Profile_AccountPausedLabel, nil, .red)
        case .superChat:
            return (I18n.Lark_Supergroups_Supergroup, nil, .blue)
        case .customTitleTag, .customIconTag, .customIconTextTag:
            assert(false, "指定类型没有默认的Tag实现")
            return (nil, nil, .clear)
        case .unKnown:
            assert(false, "This Tag Is Not Exist")
            return (nil, nil, .clear)
        case .organization:
            return (I18n.Lark_Status_ExternalTag, nil, .blue)
        case .relation:
            return (I18n.Lark_Status_ExternalTag, nil, .blue)
        case .tenantTag:
            return (nil, nil, .indigo)
        }
        // swiftlint:enable cyclomatic_complexity function_body_length
    }
}
