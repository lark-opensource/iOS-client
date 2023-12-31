//
//  DefaultChatNavigationBarTagsGenerator.swift
//  LarkMessageCore
//
//  Created by zc09v on 2022/3/15.
//

import UIKit
import LarkBizTag
import Foundation
import LarkModel
import LarkAccountInterface
import LarkTag
import UniverseDesignColor
import LarkMessengerInterface
import RustPB

public class DefaultChatNavigationBarTagsGenerator: ChatNavigationBarTagsGenerator {
    public override func getTitleTagTypes(chat: Chat, userType: PassportUserType) -> [TagDataItem] {
        let isDark = self.isDarkStyle
        let style = isDark ? Style.secretColor : nil
        var tagDataItems: [TagDataItem] = []
        var tagTypes: [LarkTag.Tag] = []

        if chat.isPrivateMode {
            tagTypes.append(
                Tag(type: .isPrivateMode,
                    style: Style(
                        textColor: UIColor.clear,
                        backColor: UIColor.ud.N200 & UIColor.ud.N700
                    )
                )
            )
        }

        if self.forceShowAllStaffTag {
            let info = Tag.defaultTagInfo(for: .allStaff)
            return [TagDataItem(text: info.title,
                               image: info.image,
                               tagType: .allStaff,
                               frontColor: style?.textColor,
                               backColor: style?.backColor)]
        }

        /// 如果是单聊 && 对方处于勿扰模式，则添加勿扰icon
        if chat.type == .p2P,
            let chatter = chat.chatter,
            self.serverNTPTimeService?
                .afterThatServerTime(time: chatter.doNotDisturbEndTime) ?? false {
            if isDark {
                tagTypes.append(
                    Tag(
                        type: .cryptoDoNotDisturb,
                        style: Style(
                            textColor: UIColor.clear,
                            backColor: UIColor.ud.udtokenTagNeutralBgSolid
                        )
                    )
                )
            } else {
                tagTypes.append(Tag(type: .doNotDisturb))
            }
        }

        // 单聊展示暂停使用, 如果已经离职不再展示该标签
        if chat.type == .p2P,
           let chatter = chat.chatter,
           !chatter.isResigned,
           chatter.isFrozen {
            tagTypes.append(Tag(type: .isFrozen, style: style))
        }

        // 这里如果包含了暂停使用的标签 不在展示请假的标签
        if chat.type == .p2P,
            let chatter = chat.chatter,
            chatter.tenantId == currentTenantId,
            chatter.workStatus.status == .onLeave,
            !(tagTypes.contains { $0.type == .isFrozen }) {
            tagTypes.append(Tag(type: .onLeave, style: style))
        }

        if chat.isDepartment {
            tagTypes.append(Tag(type: .team, style: style))
        }
        if chat.isTenant {
            tagTypes.append(Tag(type: .allStaff, style: style))
        }
        // 如果是官方OnCall群，则不显示robot、oncall和external，只显示"官方"
        if chat.isOfficialOncall || chat.tags.contains(.official) {
            tagTypes.append(Tag(type: .officialOncall, style: style))
        } else {
            if chat.chatter?.type == .bot, !(chat.chatter?.withBotTag.isEmpty ?? true) {
                tagTypes.append(Tag(type: .robot, style: style))
            }
            if !chat.oncallId.isEmpty {
                if chat.isOfflineOncall {
                    tagTypes.append(Tag(type: .oncallOffline, style: style))
                } else {
                    tagTypes.append(Tag(type: .oncall, style: style))
                }
            }
            if chat.isCrossWithKa {
                UserStyle.on(.connectTag, userType: userType).apply(on: {
                    tagTypes.append(Tag(type: .connect, style: style))
                }, off: {})
            } else if chat.tagData?.tagDataItems.isEmpty == false {
                chat.tagData?.tagDataItems.forEach { item in
                    let isExternal = item.respTagType == .relationTagExternal
                    var customBackColor: UIColor?
                    if isExternal {
                        let darkTextColor = UIColor.ud.udtokenTagNeutralTextInverse & UIColor.ud.udtokenTagTextSBlue
                        let darkBackColor = UIColor.ud.functionInfoFillHover & UIColor.ud.udtokenTagBgBlue
                        customBackColor = isDark ? darkBackColor : style?.backColor
                        if let color = self.getCustomBackgroundColorFor(item: item, isDark: isDark) {
                            customBackColor = color
                        }
                        tagDataItems.append(TagDataItem(tagType: .external,
                                                        frontColor: isDark ? darkTextColor : style?.textColor,
                                                        backColor: customBackColor,
                                                        priority: Int(item.priority)
                        ))
                    } else {
                        customBackColor = style?.backColor
                        if let color = self.getCustomBackgroundColorFor(item: item, isDark: isDark) {
                            customBackColor = color
                        }
                        let tagDataItem = LarkBizTag.TagDataItem(text: item.textVal,
                                                                 tagType: item.respTagType.transform(),
                                                                 frontColor: style?.textColor,
                                                                 backColor: customBackColor,
                                                                 priority: Int(item.priority))
                        tagDataItems.append(tagDataItem)
                    }
                }
            } else if chat.isPublic {
                tagTypes.append(Tag(type: .public, style: style))
            }
        }

        if chat.isSuper {
            tagTypes.append(Tag(type: .superChat, style: style))
        }
        tagDataItems.append(contentsOf: tagTypes.map({ tag in
            let info = Tag.defaultTagInfo(for: tag.type)
            return TagDataItem(text: info.title,
                               image: info.image,
                               tagType: tag.type.convert(),
                               frontColor: tag.style.textColor,
                               backColor: tag.style.backColor)
        }))

        return tagDataItems
    }

    func getCustomBackgroundColorFor(item: RustPB.Basic_V1_TagData.TagDataItem, isDark: Bool) -> UIColor? { nil }
}

extension LarkTag.TagType {
    /// 将 LarkTag 定义的 TagType 转换为 LarkBizTag 中的 TagType
    public func convert() -> LarkBizTag.TagType {
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
            /// 自定义图片文字类型
        case .customIconTextTag: return .customIconTextTag
            /// 未知标签，兼容 SDK 逻辑用，实际不应该展示
        case .unKnown: return .unKnown
        }
    }
}
