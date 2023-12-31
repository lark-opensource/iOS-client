//
//  Interface.swift
//  LarkBizTag
//
//  Created by 白镜吾 on 2022/11/22.
//

import UIKit
import Foundation
import LarkTag

/// Tag 结构
public struct TagDataItem: TagElement {
    /// 标签文案
    public private(set) var text: String?
    /// 标签图案
    public private(set) var image: UIImage?
    /// 标签类型
    public private(set) var tagType: TagType
    /// 标签文字 / 图片颜色
    public private(set) var frontColor: UIColor?
    /// 标签背景颜色
    public private(set) var backColor: UIColor?
    /// 端上下发的标签优先顺序，暂时不用，默认为 0 ，可传入 tagType.rawValue 备用
    public private(set) var priority: Int

    public var tag: LarkTag.Tag {
        return Tag(title: text,
                   image: image,
                   style: Style(textColor: frontColor ?? Tag.defaultTagInfo(for: type).style.textColor,
                                backColor: backColor ?? Tag.defaultTagInfo(for: type).style.backColor),
                   type: tagType.convert())
    }

    public var type: LarkTag.TagType {
        return tagType.convert()
    }

    public init(text: String? = nil,
                image: UIImage? = nil,
                tagType: TagType,
                frontColor: UIColor? = nil,
                backColor: UIColor? = nil,
                priority: Int = 0) {
        self.text = text
        self.image = image
        self.tagType = tagType
        self.frontColor = frontColor
        self.backColor = backColor
        self.priority = priority
    }
}

public enum TagType: Int, Comparable, CaseIterable {
    public static func < (lhs: TagType, rhs: TagType) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }

    /// 星标联系人(特别关注) PM要求最先展示
    case specialFocus

    /// 密盾聊
    case isPrivateMode

    /// 互通
    case connect

    /// 外部 B2B 关联企业
    case relation

    /// 外部 企业名称
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

    // MARK: - 自定义标签

    /// 自定义文本类型
    case customTitleTag = 10000

    /// 自定义图片类型
    case customIconTag

    /// 自定义图片文本类型
    case customIconTextTag

    /// 未知标签
    case unKnown

    /// 将 LarkBizTag 定义的 TagType 转换为 LarkTag 中的 TagType
    public func convert() -> LarkTag.TagType {
        switch self {
            /// 星标联系人(特别关注) PM要求最先展示
        case .specialFocus: return .specialFocus

            /// 密盾聊
        case .isPrivateMode: return .isPrivateMode

            /// 互通
        case .connect: return .connect

            /// 外部 B2B 关联企业
        case .relation: return .relation

            /// 外部 企业名称
        case .organization: return .organization

            /// 外部
        case .external: return .external

            /// 免打扰，用在除密聊chat头部以外的地方
        case .doNotDisturb: return .doNotDisturb

            /// 密聊免打扰，只用在密聊chat头部
        case .cryptoDoNotDisturb: return .cryptoDoNotDisturb

            /// 未注册
        case .unregistered: return .unregistered

            /// 已离职
        case .deactivated: return .deactivated

            /// 账号冻结/暂停
        case .isFrozen: return .isFrozen

            /// 请假
        case .onLeave: return .onLeave

            /// 值班号
        case .oncall: return .oncall

            /// 密聊
        case .crypto: return .crypto

            /// 密聊chat中的加密icon
        case .secretCrypto: return .secretCrypto

            /// 团队Secret群icon
        case .teamSecretGroup: return .teamSecretGroup

            /// 租户超级管理员（组织架构界面显示）
        case .tenantSuperAdmin: return .tenantSuperAdmin

            /// 租户管理员（组织架构界面显示）
        case .tenantAdmin: return .tenantAdmin

            /// 企业负责人
        case .enterpriseSupervisor: return .enterpriseSupervisor

            /// 主负责人
        case .mainSupervisor: return .mainSupervisor

            /// 负责人
        case .supervisor: return .supervisor

            /// 群主
        case .groupOwner: return .groupOwner

            /// 群管理员
        case .groupAdmin: return .groupAdmin

            /// 部门
        case .team: return .team

            /// 全员
        case .allStaff: return .allStaff

            /// 新版本
        case .newVersion: return .newVersion

            /// 未读
        case .unread: return .unread

            /// 应用
        case .app: return .app

            /// 机器人
        case .robot: return .robot

            /// “#”
        case .thread: return .thread

            /// 已读
        case .read: return .read

            /// 公开群
        case .public: return .public

            /// 官方服务台
        case .officialOncall: return .officialOncall

            /// 服务台“用户”
        case .oncallUser: return .oncallUser

            /// 服务台“客服”
        case .oncallAgent: return .oncallAgent

            /// 群分享历史：已失效
        case .shareDeactivated: return .shareDeactivated

            /// helpdesk offline
        case .oncallOffline: return .oncallOffline

            /// 超大群
        case .superChat: return .superChat

            /// 团队负责人
        case .teamOwner: return .teamOwner

            /// 团队管理员
        case .teamAdmin: return .teamAdmin

            /// 团队成员
        case .teamMember: return .teamMember

            // MARK: - 下面是日历相关的

            /// 日程外部（灰色）
        case .calendarExternalGrey: return .calendarExternalGrey

            /// 日程组织者
        case .calendarOrganizer: return .calendarOrganizer

            /// 日程创建者
        case .calendarCreator: return .calendarCreator

            /// 日程不参与
        case .calendarNotAttend: return .calendarNotAttend

            /// 日程可选参加
        case .calendarOptionalAttend: return .calendarOptionalAttend

            /// 日程有冲突
        case .calendarConflict: return .calendarConflict

            /// 日程30天内有冲突
        case .calendarConflictInMonth: return .calendarConflictInMonth

            /// 日程当前地点
        case .calendarCurrentLocation: return .calendarCurrentLocation
            /// 租户标签
        case .tenantTag: return .tenantTag
            /// 自定义文本类型
        case .customTitleTag: return .customTitleTag

            /// 自定义图片类型
        case .customIconTag: return .customIconTag

        case .customIconTextTag: return .customIconTextTag

            /// 未知标签，兼容 SDK 逻辑用，实际不应该展示
        case .unKnown: return .unKnown
        }
    }

    /// TagType 生成对应的 TagDataItem
    /// 优先级目前以 Messenger 场景中的为准，以 rawValue 次序作为优先级顺序
    /// 后续迭代：不同业务的维护自己的优先级顺序，区分业务。
    func transform() -> TagDataItem {
        let tagInfo = Tag.defaultTagInfo(for: self.convert())
        let tagItem = TagDataItem(text: tagInfo.title,
                                  image: tagInfo.image,
                                  tagType: self,
                                  frontColor: tagInfo.style.textColor,
                                  backColor: tagInfo.style.backColor,
                                  priority: self.rawValue)
        return tagItem
    }
}

struct Helper {
    static func execInMainThread(block: @escaping () -> Void) {
        if Thread.current.isMainThread {
            block()
        } else {
            DispatchQueue.main.async {
                block()
            }
        }
    }
}
