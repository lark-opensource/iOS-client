//
//  Type.swift
//  LarkTag
//
//  Created by Kongkaikai on 2019/6/16.
//

import Foundation

/// 关于顺序：
/// 互通>外部>请假/未注册>值班号／密聊／负责人／群主(admin)
/// [参考地址](https://docs.bytedance.net/doc/APVvcoelDuQRHz1CfeBjFd)
///
/// Tag的类型
public enum TagType: Int, Comparable, CaseIterable {
    public static func < (lhs: TagType, rhs: TagType) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }

    /// 星标联系人(特别关注) PM要求最先展示
    case specialFocus

    /// 密盾聊
    case isPrivateMode

    /// 互通
    case connect = 2

    /// B2B 关联企业
    case relation

    /// 企业名称标签
    case organization

    /// 外部
    case external

    /// 免打扰，用在除密聊chat头部以外的地方
    case doNotDisturb

    /// 密聊免打扰，只用在密聊chat头部
    case cryptoDoNotDisturb

    /// 未注册
    case unregistered

    /// 已离职
    case deactivated

    /// 账号冻结/暂停
    case isFrozen

    /// 请假
    case onLeave

    /// 值班号
    case oncall

    /// 密聊
    case crypto

    /// 密聊chat中的加密icon
    case secretCrypto

    /// 团队Secret群icon
    case teamSecretGroup

    /// 租户超级管理员（组织架构界面显示）
    case tenantSuperAdmin

    /// 租户管理员（组织架构界面显示）
    case tenantAdmin

    /// 企业负责人
    case enterpriseSupervisor

    /// 主负责人
    case mainSupervisor

    /// 负责人
    case supervisor

    /// 群主
    case groupOwner

    /// 群管理员
    case groupAdmin

    /// 部门
    case team

    /// 全员
    case allStaff

    /// 新版本
    case newVersion

    /// 未读
    case unread

    /// 应用
    case app

    /// 机器人
    case robot

    /// “#”
    case thread

    /// 已读
    case read

    /// 公开群
    case `public`

    /// 官方服务台
    case officialOncall

    /// 服务台“用户”
    case oncallUser

    /// 服务台“客服”
    case oncallAgent

    /// 群分享历史：已失效
    case shareDeactivated

    /// helpdesk offline
    case oncallOffline

    /// 超大群
    case superChat

    /// 团队负责人
    case teamOwner

    /// 团队管理员
    case teamAdmin

    /// 团队成员
    case teamMember

    // MARK: - 下面是日历相关的

    /// 日程外部（灰色）
    case calendarExternalGrey = 1001

    /// 日程组织者
    case calendarOrganizer

    /// 日程创建者
    case calendarCreator

    /// 日程不参与
    case calendarNotAttend

    /// 日程可选参加
    case calendarOptionalAttend

    /// 日程有冲突
    case calendarConflict

    /// 日程30天内有冲突
    case calendarConflictInMonth

    /// 日程当前地点
    case calendarCurrentLocation

    /// 租户标签
    case tenantTag

    /// 自定义文本类型
    case customTitleTag = 10000

    /// 自定义图片类型
    case customIconTag

    /// 自定义图片文本类型
    case customIconTextTag

    /// 未知标签，兼容 SDK 逻辑用，实际不应该展示
    case unKnown

    /// 文本类型的 Tag
    public static var titleTypes: [TagType] {
        return [
            .external,
            .connect,
            .relation,
            .unregistered,
            .team,
            .allStaff,
            .groupOwner,
            .groupAdmin,
            .tenantSuperAdmin,
            .tenantAdmin,
            .enterpriseSupervisor,
            .mainSupervisor,
            .supervisor,
            .deactivated,
            .isFrozen,
            .onLeave,
            .unread,
            .app,
            .robot,
            .read,
            .calendarExternalGrey,
            .calendarOrganizer,
            .calendarCreator,
            .calendarNotAttend,
            .calendarOptionalAttend,
            .calendarConflict,
            .calendarConflictInMonth,
            .calendarCurrentLocation,
            .tenantTag,
            .customTitleTag,
            .public,
            .officialOncall,
            .oncallUser,
            .oncallAgent,
            .shareDeactivated,
            .superChat,
            .teamOwner,
            .teamAdmin,
            .teamMember,
            .organization
        ]
    }

    /// 图片类型的 Tag
    static var iconTypes: [TagType] {
        return [
            .specialFocus,
            .doNotDisturb,
            .newVersion,
            .crypto,
            .oncall,
            .oncallOffline,
            .thread,
            .customIconTag
        ]
    }

    /// 图片文本类型的 Tag
    static var iconTextTypes: [TagType] {
        return [
            .customIconTextTag
        ]
    }

    /// 适配 UDIcon 类型的 Tag
    static var udIconTypes: [TagType] {
        return [
            .cryptoDoNotDisturb,
            .secretCrypto,
            .isPrivateMode
        ]
    }
}
