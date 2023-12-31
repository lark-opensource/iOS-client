//
//  LarkInterface+UserStyleSwitch.swift
//  LarkMessengerInterface
//
//  Created by Jiayun Huang on 2019/12/14.
//

import Foundation
import LarkAccountInterface

public typealias StyleSwitchHandler = () -> Void

public enum UserStyle: Int, CaseIterable {

    // 互通标签
    case connectTag
    // 外部标签
    case externalTag
    // 部门标签
    case departmentTag
    // 请假标签
    case onleaveTag
    // 密聊标签
    case secretChatTag
    // 全员标签
    case allStaffTag
    // 公开群标签
    case publicTag

    // 通讯录外部联系人
    case externalContactList
    // 通讯录组织架构
    case departmentStructureContactList
    // 通讯录机器人
    case robotContactList

    // 群是否可被分享的设置
    case groupShareSettings
    // 群分享
    case groupShare
    // 群分享历史
    case groupShareHistory
    // 创建公开群开关
    case createPublicGroupSetting

    // 创建群组时：standard账号显示组织架构，其他显示好友列表
//    case createGroupInviteList

    // Help desk入口
    case helpDesk

    static public func on(_ userStyle: UserStyle, userType: PassportUserType) -> UserStyleApplier {
        return UserStyleApplier(userType: userType, userStyle: userStyle)
    }
}

extension UserStyle {
    static let applyConfigs: [UserStyle: UserTypeStyleApplyHandler] = [
        .connectTag: UserStyleApplyConfig.apply(standard: .on, others: .off),
        .externalTag: UserStyleApplyConfig.apply(standard: .on, others: .off),
        .departmentTag: UserStyleApplyConfig.apply(standard: .on, others: .off),
        .onleaveTag: UserStyleApplyConfig.apply(standard: .on, others: .off),
        .secretChatTag: UserStyleApplyConfig.apply(standard: .on, others: .off),
        .allStaffTag: UserStyleApplyConfig.apply(standard: .on, others: .off),
        .publicTag: UserStyleApplyConfig.apply(standard: .on, others: .off),
        .externalContactList: UserStyleApplyConfig.apply(standard: .on, others: .off),
        .departmentStructureContactList: UserStyleApplyConfig.apply(standard: .on, others: .off),
        .robotContactList: UserStyleApplyConfig.apply(standard: .on, others: .off),
        .groupShareSettings: UserStyleApplyConfig.apply(standard: .on, others: .off),
        .groupShare: UserStyleApplyConfig.apply(standard: .on, others: .off),
        .groupShareHistory: UserStyleApplyConfig.apply(standard: .on, others: .off),
        .createPublicGroupSetting: UserStyleApplyConfig.apply(standard: .on, others: .off),
        .helpDesk: UserStyleApplyConfig.apply(standard: .on, others: .off)
    ]
}

public struct UserStyleApplier {
    private var userType: PassportUserType

    private var userStyle: UserStyle

    init(userType: PassportUserType, userStyle: UserStyle) {
        self.userType = userType
        self.userStyle = userStyle
    }

    public func apply(on: StyleSwitchHandler? = nil, off: StyleSwitchHandler? = nil) {
        let handler: UserTypeStyleApplyHandler? = UserStyle.applyConfigs[userStyle]
        let applyOn = handler?(userType) == UserStyleApplyConfig.on
        let applyOff = handler?(userType) == UserStyleApplyConfig.off

        assert(applyOn && on != nil || !applyOn, "Check your style configs.")
        assert(applyOff && off != nil || !applyOff, "Check your style configs.")

        if applyOn {
            on?()
        }
        if applyOff {
            off?()
        }
    }
}
