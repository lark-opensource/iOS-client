//
//  PickerUserGroupEntityConfig.swift
//  LarkModel
//
//  Created by Yuri on 2023/5/29.
//

import Foundation

public extension PickerConfig {
    enum UserGroupVisibilityType: Int, Codable {
        /// 未知场景，强制要求业务显式传入具体业务
        case unknown = 0
        /// 云文档
        case ccm = 1
        /// 日历
        case calendar = 2
        /// 服务台
        case helpDesk = 3
        /// 审批
        case approval = 4
        /// 订阅号
        case subscriptions = 5
        /// OKR
        case okr = 6
        /// 开放平台
        case openPlatform = 7
        /// 词典
        case dictionary = 8
        /// 工作台
        case appCenter = 9
    }

    public enum UserGroupCategory: Int, Codable {
        case all
        case assign
        case dynamic
    }

    struct UserGroupEntityConfig: UserGroupEntityConfigType, Codable {
        /// 静态用户组userGroup、动态用户组 dynamicUserGroup
        public var type: SearchEntityType = .userGroup
        public var nameSpace: String = "admin"
        public var category: UserGroupCategory = .all
        /// 场景可见性
        public var userGroupVisibilityType: UserGroupVisibilityType?
        public init(nameSpace: String = "admin",
                    category: UserGroupCategory = .all,
                    userGroupVisibilityType: UserGroupVisibilityType? = nil) {
            self.nameSpace = nameSpace
            self.category = category
            self.userGroupVisibilityType = userGroupVisibilityType
        }
    }
}
